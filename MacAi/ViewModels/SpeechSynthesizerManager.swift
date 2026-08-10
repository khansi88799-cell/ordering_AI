//
//  SpeechSynthesizerManager.swift
//  Arch
//
//  Created by saeed on 4/08/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import Foundation
import AVFoundation
import Combine

final class SpeechSynthesizerManager: NSObject, ObservableObject {

    static let shared = SpeechSynthesizerManager()

    @Published var isSpeaking: Bool = false

    private var synthesizer = AVSpeechSynthesizer()
    private var watchdogWorkItem: DispatchWorkItem?

    override init() {
        super.init()
        synthesizer.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: rawType) == .ended else { return }
        DispatchQueue.main.async { [weak self] in
            self?.resetSynthesizer()
        }
    }

    private func resetSynthesizer() {
        watchdogWorkItem?.cancel()
        synthesizer.delegate = nil
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        isSpeaking = false
    }

    /// Speaks the given text aloud. Safe to call repeatedly — a new
    /// utterance interrupts whatever is currently speaking.
    func speak(_ text: String, language: String = "en-US") {
        guard !text.isEmpty else { return }
        speak(text, language: language, isRetry: false)
    }

    private func speak(_ text: String, language: String, isRetry: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session for speech: \(error.localizedDescription)")
        }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let voice = Self.bestAvailableVoice(for: language)
        let sentences = Self.splitIntoSentences(text)
        for (index, sentence) in sentences.enumerated() {
            let utterance = AVSpeechUtterance(string: sentence)
            utterance.voice = voice
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
            utterance.pitchMultiplier = 1.0
            utterance.postUtteranceDelay = index < sentences.count - 1 ? 0.12 : 0.0
            synthesizer.speak(utterance)
        }
        watchdogWorkItem?.cancel()
        guard !isRetry else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isSpeaking else { return }
            print("Speech synthesizer appears stuck — resetting and retrying once.")
            self.resetSynthesizer()
            self.speak(text, language: language, isRetry: true)
        }
        watchdogWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }

    func stopSpeaking() {
        watchdogWorkItem?.cancel()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    /// iOS ships a robotic-sounding "default"-quality voice for every
    /// language out of the box; "enhanced"/"premium" quality voices exist
    /// for most languages but are opt-in downloads (Settings >
    /// Accessibility > Spoken Content > Voices). Prefer one if the user
    /// already has it installed — this is the single biggest lever for
    /// less robotic speech available without a third-party TTS service.
    private static func bestAvailableVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
        if #available(iOS 16.0, *), let premium = candidates.first(where: { $0.quality == .premium }) {
            return premium
        }
        if let enhanced = candidates.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        return AVSpeechSynthesisVoice(language: language)
    }

    /// Foundation's built-in sentence tokenizer — no third-party dependency.
    private static func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { substring, _, _, _ in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty {
                sentences.append(sentence)
            }
        }
        return sentences.isEmpty ? [text] : sentences
    }
}

extension SpeechSynthesizerManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
