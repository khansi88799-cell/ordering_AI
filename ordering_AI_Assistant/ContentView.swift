//
//  ContentView.swift
//  ordering_AI_Assistant
//
//  Created by saeed on 02/08/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var isShowingChat = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            GoldenArchesLogo()
                .frame(width: 120, height: 120)

            Text("Hello! Welcome to McDonald Food agent")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#D7262B"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                navigateToChatWindow()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#D7262B"))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#FFF8E7").ignoresSafeArea())
        .fullScreenCover(isPresented: $isShowingChat) {
            OrderChatView()
        }
    }

    func navigateToChatWindow() {
        isShowingChat = true
    }

}

private struct GoldenArchesLogo: View {
    var body: some View {
        Image("M_logo")
            .resizable()
            .scaledToFit()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
