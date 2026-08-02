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
   // var objectWillChange: ObservableObjectPublisher
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    @Published var isAuthorized: Bool = false

    init() {
        self.requestPermissions { [weak self] granted in
            self?.isAuthorized = granted
        }
    }

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    if #available(iOS 17.0, *) {
                        AVAudioApplication.requestRecordPermission { granted in
                            DispatchQueue.main.async { completion(granted) }
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                default:
                    completion(false)
                }
            }
        }
    }

    func startTranscribing() {
        stopTranscribing()
        transcribedText = ""

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else { return }

        recognitionRequest.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
        }

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
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async { self.isListening = true }
        } catch {
            print("Audio engine couldn't start: \(error.localizedDescription)")
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
