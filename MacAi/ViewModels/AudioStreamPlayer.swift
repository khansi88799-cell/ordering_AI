//
//  AudioStreamPlayer.swift
//  Arch
//
//  Created by saeed on 14/08/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import Foundation
import AVFoundation

final class AudioStreamPlayer {

    static let shared = AudioStreamPlayer()

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    private(set) var activeTraceId: String?
    private var audioFormat: AVAudioFormat?

   
    var expectedTraceId: String? {
        didSet {
            turnRenderedAt = Date()
            scheduleNoAudioFallback()
        }
    }

    
    var fallbackText: String?

    /// When true, incoming audio is discarded entirely (voice reply muted).
    var isMuted: Bool = false {
        didSet { if isMuted { noAudioFallbackTimer?.invalidate() } }
    }

    private var noAudioFallbackTimer: Timer?
    private let noAudioFallbackTimeout: TimeInterval = 12
    private var fallbackAnnouncedTraceId: String?

    // MARK: - Latency logging
    private var turnRenderedAt: Date?
    private var audioStartReceivedAt: Date?
    private var hasLoggedFirstChunkForCurrentSession = false
    private var lastReceivedSeq: Int?
    private var totalReceivedBytesForSession: Int = 0

    private init() {
        audioEngine.attach(playerNode)
    }

    private func scheduleNoAudioFallback() {
        noAudioFallbackTimer?.invalidate()
        fallbackAnnouncedTraceId = nil
        guard let expectedTraceId, !isMuted else { return }
        let timer = Timer(timeInterval: noAudioFallbackTimeout, repeats: false) { [weak self] _ in
            self?.handleNoAudioTimeout(traceId: expectedTraceId)
        }
        RunLoop.main.add(timer, forMode: .common)
        noAudioFallbackTimer = timer
    }

    private func handleNoAudioTimeout(traceId: String) {
        guard traceId == expectedTraceId, activeTraceId != traceId else { return }
        print("[AudioStreamPlayer] No audio_start for trace=\(traceId) within \(noAudioFallbackTimeout)s — falling back to local voice.")
        fallbackAnnouncedTraceId = traceId
        if let fallbackText, !fallbackText.isEmpty {
            SpeechSynthesizerManager.shared.speak(fallbackText)
        }
    }

    /// Call when an "audio_start" event arrives.
    func startNewSession(traceId: String, sampleRate: Double, channels: UInt32) {
        guard traceId == expectedTraceId else {
            print("[AudioStreamPlayer] Ignoring audio_start for unexpected trace_id: \(traceId)")
            return
        }
        guard traceId != fallbackAnnouncedTraceId else {
            print("[AudioStreamPlayer] Ignoring late audio_start for trace=\(traceId) — the local voice already announced this turn.")
            return
        }
        let isContinuation = traceId == activeTraceId
        if isContinuation {
            print("[AudioStreamPlayer] trace=\(traceId) additional audio_start for the same trace — treating as a continuation, not resetting playback.")
        }

        if let turnRenderedAt, !isContinuation {
            let textToAudioStart = Date().timeIntervalSince(turnRenderedAt)
            print(String(format: "[VoiceLatency] trace=%@ text-visible → audio_start: %.2fs", traceId, textToAudioStart))
        }
        if !isContinuation {
            audioStartReceivedAt = Date()
        }
        hasLoggedFirstChunkForCurrentSession = false
        if !isContinuation {
            lastReceivedSeq = nil
            totalReceivedBytesForSession = 0
        }
        if let fallbackText, !isContinuation {
            print("[AudioStreamPlayer] trace=\(traceId) message is \(fallbackText.count) chars: \"\(fallbackText)\"")
        }
        guard !isContinuation else { return }
        noAudioFallbackTimer?.invalidate()
        activeTraceId = nil
        playerNode.stop()
        guard !isMuted else { return }
        activeTraceId = traceId
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[AudioStreamPlayer] Failed to configure audio session: \(error.localizedDescription)")
        }
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: true
        ) else {
            print("[AudioStreamPlayer] Failed to create AVAudioFormat (sampleRate=\(sampleRate), channels=\(channels))")
            return
        }
        let formatChanged: Bool
        if let existing = audioFormat {
            formatChanged = existing.sampleRate != format.sampleRate || existing.channelCount != format.channelCount
        } else {
            formatChanged = true
        }
        audioFormat = format
        if formatChanged {
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        }
        do {
            if !audioEngine.isRunning {
                try audioEngine.start()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.playerNode.play()
                }
            } else {
                playerNode.play()
            }
        } catch {
            print("[AudioStreamPlayer] Engine start error: \(error.localizedDescription)")
        }
    }

    /// Call for each "audio_chunk" event.
    func playChunk(traceId: String, seq: Int?, base64Payload: String) {
        guard !isMuted,
              traceId == activeTraceId,
              let format = audioFormat,
              let pcmData = Data(base64Encoded: base64Payload) else { return }
        if let seq {
            if let lastReceivedSeq, seq != lastReceivedSeq + 1 {
                print("[AudioStreamPlayer] trace=\(traceId) seq gap: expected \(lastReceivedSeq + 1), got \(seq) — a chunk may have been dropped.")
            }
            lastReceivedSeq = seq
        }
        totalReceivedBytesForSession += pcmData.count
        if !hasLoggedFirstChunkForCurrentSession {
            hasLoggedFirstChunkForCurrentSession = true
            if let audioStartReceivedAt {
                let audioStartToFirstChunk = Date().timeIntervalSince(audioStartReceivedAt)
                print(String(format: "[VoiceLatency] trace=%@ audio_start → first chunk scheduled: %.3fs", traceId, audioStartToFirstChunk))
            }
            if let turnRenderedAt {
                let totalPerceived = Date().timeIntervalSince(turnRenderedAt)
                print(String(format: "[VoiceLatency] trace=%@ TOTAL text-visible → first audible chunk: %.2fs", traceId, totalPerceived))
            }
        }

        let bytesPerFrame = format.streamDescription.pointee.mBytesPerFrame
        guard bytesPerFrame > 0 else { return }
        let frameCount = UInt32(pcmData.count) / bytesPerFrame
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        pcmData.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress,
                  let channelData = buffer.int16ChannelData?[0] else { return }
            memcpy(channelData, baseAddress, pcmData.count)
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }

    /// Call when an "audio_end" event arrives — purely informational,
    /// logs how long the backend took to finish streaming this turn.
    func sessionEnded(traceId: String, totalChunks: Int?) {
        guard traceId == activeTraceId, let audioStartReceivedAt else { return }
        let streamDuration = Date().timeIntervalSince(audioStartReceivedAt)
        if let totalChunks {
            print(String(format: "[VoiceLatency] trace=%@ audio_end: %d chunks streamed over %.2fs", traceId, totalChunks, streamDuration))
        } else {
            print(String(format: "[VoiceLatency] trace=%@ audio_end: stream finished after %.2fs", traceId, streamDuration))
        }
        if let format = audioFormat {
            let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
            if bytesPerFrame > 0 {
                let receivedSeconds = Double(totalReceivedBytesForSession / bytesPerFrame) / format.sampleRate
                let charCount = fallbackText?.count ?? 0
                let expectedSeconds = Double(charCount) / 15.0
                print(String(format: "[AudioStreamPlayer] trace=%@ received %.2fs of audio for a %d-char message (~%.2fs expected).", traceId, receivedSeconds, charCount, expectedSeconds))
                if expectedSeconds > 1, receivedSeconds < expectedSeconds * 0.6 {
                    print("[AudioStreamPlayer] trace=\(traceId) received audio looks too short for the message length — check the backend's TTS generation for this trace_id.")
                }
            }
        }
    }

    func audioErrorReceived(traceId: String) {
        guard traceId == expectedTraceId else { return }
        print("[AudioStreamPlayer] audio_error for trace=\(traceId) — falling back to local voice.")
        fallbackAnnouncedTraceId = traceId
        stop()
        if let fallbackText, !fallbackText.isEmpty {
            SpeechSynthesizerManager.shared.speak(fallbackText)
        }
    }

    func stop() {
        noAudioFallbackTimer?.invalidate()
        activeTraceId = nil
        playerNode.stop()
        audioEngine.stop()
    }
}
