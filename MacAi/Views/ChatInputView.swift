//
//  ChatInputView.swift
//  Arch
//
//  Created by saeed on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI
import UIKit

struct ChatInputView: View {

    @Binding var text: String
    var onSend: () -> Void

    @StateObject private var speechManager = SpeechRecognizerManager()
    @State private var isHoldingMic: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var micStartFailed: Bool = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            // Listening banner
            if isHoldingMic {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .foregroundColor(.red)
                    Text(speechManager.transcribedText.isEmpty ? "Listening... release to send" : speechManager.transcribedText)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if micStartFailed {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("Couldn't start listening — try again")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack {
                TextField("Type your order...", text: $text)
                    .padding(12)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(20)

                // Mic button — hold to record, release to send
                Image(systemName: isHoldingMic ? "waveform.circle.fill" : "mic.fill")
                    .foregroundColor(.white)
                    .padding()
                    .background(isHoldingMic ? Color.red : Color(hex: "#D7262B"))
                    .clipShape(Circle())
                    .scaleEffect(isHoldingMic ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isHoldingMic)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                guard !isHoldingMic else { return }
                                if speechManager.isAuthorized {
                                    micStartFailed = false
                                    speechManager.transcribedText = ""
                                    if speechManager.startTranscribing() {
                                        isHoldingMic = true
                                    } else {
                                        micStartFailed = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            micStartFailed = false
                                        }
                                    }
                                } else if speechManager.isPermissionDenied {
                                    showPermissionAlert = true
                                } else {
                                    speechManager.refreshPermissionStatus()
                                }
                            }
                            .onEnded { _ in
                                guard isHoldingMic else { return }
                                isHoldingMic = false
                                speechManager.stopTranscribing()
                                // Wait briefly for final transcription result
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    let spoken = speechManager.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !spoken.isEmpty {
                                        text = spoken
                                        speechManager.transcribedText = ""
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            onSend()
                                            text = ""
                                        }
                                    }
                                }
                            }
                    )

                // Send button
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "#D7262B"))
                        .clipShape(Circle())
                }
            }
            .padding()
        }
        .alert("Microphone Access Needed", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Voice ordering needs Microphone and Speech Recognition access. Enable both for this app in Settings.")
        }
    }
}
