//
//  SpeechRecognizerManager.swift
//  Arch
//
//  Created by saeed on 15/07/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognizerManager: ObservableObject {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var isPermissionDenied: Bool = false

    init() {
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch authStatus {
                case .authorized:
                    if #available(iOS 17.0, *) {
                        AVAudioApplication.requestRecordPermission { granted in
                            DispatchQueue.main.async {
                                self.isAuthorized = granted
                                self.isPermissionDenied = !granted
                            }
                        }
                    } else {
                        // Pre-iOS 17: speech authorization also covers mic access.
                        self.isAuthorized = true
                        self.isPermissionDenied = false
                    }
                default:
                    self.isAuthorized = false
                    self.isPermissionDenied = true
                }
            }
        }
    }

    /// Starts capturing + transcribing. Returns whether it actually
    /// started — callers shouldn't show a "listening" UI on the strength
    @discardableResult
    func startTranscribing() -> Bool {
        guard isAuthorized else {
            print("Speech/microphone permission not granted yet — ignoring mic tap.")
            return false
        }
        stopTranscribing()
        transcribedText = ""
        SpeechSynthesizerManager.shared.stopSpeaking()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            return false
        }
        audioEngine.reset()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            self.recognitionRequest = nil
            return false
        }
        recognitionRequest.shouldReportPartialResults = true
        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self.stopTranscribing()
                }
            }
        }
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            print("Invalid audio input format (sampleRate: \(recordingFormat.sampleRate)) — aborting mic capture.")
            self.recognitionRequest = nil
            recognitionTask?.cancel()
            recognitionTask = nil
            return false
        }
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async { self.isListening = true }
            return true
        } catch {
            print("Audio engine couldn't start: \(error.localizedDescription)")
            inputNode.removeTap(onBus: 0)
            self.recognitionRequest = nil
            recognitionTask?.cancel()
            recognitionTask = nil
            return false
        }
    }

    func stopTranscribing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        DispatchQueue.main.async { self.isListening = false }
    }
}
