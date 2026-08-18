//
//  StaticAudioPlayer.swift
//  Arch
//
//  Created by saeed on 14/08/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import Foundation
import AVFoundation

final class StaticAudioPlayer: NSObject {

    static let shared = StaticAudioPlayer()

    private var player: AVAudioPlayer?

    private override init() {}

    func play(resourceName: String, fallbackText: String) {
        guard let url = Self.locate(resourceName) else {
            print("[StaticAudioPlayer] \(resourceName) not bundled — falling back to local voice.")
            SpeechSynthesizerManager.shared.speak(fallbackText)
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            player = newPlayer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self, self.player === newPlayer else { return }
                newPlayer.play()
            }
        } catch {
            print("[StaticAudioPlayer] Failed to play \(resourceName): \(error.localizedDescription) — falling back to local voice.")
            SpeechSynthesizerManager.shared.speak(fallbackText)
        }
    }

    /// Stops playback immediately — called when the mic is grabbed or the
    /// user mutes voice replies, same as AudioStreamPlayer/SpeechSynthesizerManager.
    func stop() {
        player?.stop()
        player = nil
    }

    private static func locate(_ resourceName: String) -> URL? {
        for ext in ["m4a", "mp3", "wav", "caf"] {
            if let url = Bundle.main.url(forResource: resourceName, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}

extension StaticAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
    }
}
