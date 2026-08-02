//
//  QuickActionsView.swift
//  Arch
//
//  Created by Rahul Gupta on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI

struct QuickActionsView: View {
    
    let items = ["Desserts", "Chicken", "View Cart"]
    @ObservedObject var viewModel: ChatViewModel
    var onTap: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(items, id: \.self) { item in
                QuickActionButton(
                    title: item,
                    isSelected: viewModel.inputText == item
                ) {
                    onTap(item)
                }
                
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}


struct QuickActionButton: View {
    let title: String
    let isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected
                              ? Color(hex: "#D7262B").opacity(0.2)
                              : Color(.systemGray6))
                )
            
                .overlay(
                    Capsule()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
    }
}
