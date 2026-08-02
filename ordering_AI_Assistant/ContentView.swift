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
        VStack {
            Text("Hello, Welcome to the AI Orders")
            Button("Get Started") {
                navigateToChatWindow()
            }
            .buttonStyle(.borderedProminent)
        }
        .fullScreenCover(isPresented: $isShowingChat) {
            OrderChatView()
        }
    }
    
    func navigateToChatWindow() {
        isShowingChat = true
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
