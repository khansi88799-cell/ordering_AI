//
//  TypingMessageView.swift
//  SwiftUI-Concept
//
//  Created by saeed on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI

struct TypingMessageView: View {
    @ObservedObject var viewModel: ChatViewModel

    @State private var phase = 0

    var body: some View {
        HStack(alignment: .center, spacing: 8) {

            Image("mAssistance")
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .clipShape(Circle())

            HStack(spacing: 6) {
                Text(viewModel.loadingMessage)
                    .font(.system(size: 14))
                
                Circle()
                    .frame(width: 5, height: 5)
                    .opacity(phase == 0 ? 1 : 0.3)

                Circle()
                    .frame(width: 5, height: 5)
                    .opacity(phase == 1 ? 1 : 0.3)

                Circle()
                    .frame(width: 5, height: 5)
                    .opacity(phase == 2 ? 1 : 0.3)
            }
            .foregroundColor(.gray)
            .padding(.vertical, 8)

            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}
