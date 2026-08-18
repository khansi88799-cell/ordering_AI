//
//  ChatAudioWebSocket.swift
//  Arch
//
//  Created by saeed on 14/08/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import Foundation

final class ChatAudioWebSocket {

    private let url: URL
    private let session = URLSession(configuration: .default)
    private var task: URLSessionWebSocketTask?
    private var isDisconnecting = false
    private var reconnectAttempt = 0
    private var reconnectWorkItem: DispatchWorkItem?
    private let maxReconnectDelay: TimeInterval = 30
    private var pingTimer: Timer?
    private let pingInterval: TimeInterval = 20

    init(userId: String) {
        self.url = URL(string: "wss://mcd-chatbot-api-186503175274.asia-south1.run.app/ws/audio/\(userId)")!
    }

    func connect() {
        isDisconnecting = false
        reconnectAttempt = 0
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        openSocket()
    }

    func disconnect() {
        isDisconnecting = true
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        stopPing()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        AudioStreamPlayer.shared.stop()
    }

    private func openSocket() {
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        listen()
        startPing()
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                self.reconnectAttempt = 0
                switch message {
                case .string(let text):
                    self.handle(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handle(text)
                    }
                @unknown default:
                    break
                }
                self.listen()
            case .failure(let error):
                print("[ChatAudioWebSocket] Receive error: \(error.localizedDescription)")
                self.scheduleReconnect()
            }
        }
    }

    private func scheduleReconnect() {
        guard !isDisconnecting else { return }
        stopPing()
        task?.cancel()
        task = nil
        reconnectWorkItem?.cancel()

        let delay = min(maxReconnectDelay, pow(2.0, Double(reconnectAttempt)))
        reconnectAttempt += 1
        print("[ChatAudioWebSocket] Reconnecting in \(delay)s (attempt \(reconnectAttempt))")

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isDisconnecting else { return }
            self.openSocket()
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func startPing() {
        stopPing()
        let timer = Timer(timeInterval: pingInterval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
        RunLoop.main.add(timer, forMode: .common)
        pingTimer = timer
    }

    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPing() {
        task?.sendPing { [weak self] error in
            guard let self = self, let error = error else { return }
            print("[ChatAudioWebSocket] Ping failed: \(error.localizedDescription)")
            self.scheduleReconnect()
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String,
              let traceId = json["trace_id"] as? String else { return }

        switch type {
        case "audio_start":
            let format = json["format"] as? [String: Any]
            let sampleRate = (format?["sampleRate"] as? NSNumber)?.doubleValue ?? 24000
            let channels = (format?["channels"] as? NSNumber)?.uint32Value ?? 1
            AudioStreamPlayer.shared.startNewSession(traceId: traceId, sampleRate: sampleRate, channels: channels)

        case "audio_chunk":
            if let payload = json["payload"] as? String {
                let seq = (json["seq"] as? NSNumber)?.intValue
                AudioStreamPlayer.shared.playChunk(traceId: traceId, seq: seq, base64Payload: payload)
            }

        case "audio_end":
            let totalChunks = (json["total_chunks"] as? NSNumber)?.intValue
            AudioStreamPlayer.shared.sessionEnded(traceId: traceId, totalChunks: totalChunks)

        case "audio_error":
            print("[ChatAudioWebSocket] audio_error for trace_id: \(traceId)")
            AudioStreamPlayer.shared.audioErrorReceived(traceId: traceId)

        default:
            break
        }
    }
}
