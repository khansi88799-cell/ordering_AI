//
//  ChatBubbleView.swift
//  Arch
//
//  Created by saeed on 4/08/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI

struct ChatBubbleView: View {
    
    @ObservedObject var viewModel: ChatViewModel
    var message: ChatMessage
    
    var body: some View {
        
        HStack(alignment: .top) {
            if message.sender == .bot {
                VStack(alignment: .leading, spacing: 4) {
                    // Top row (Avatar + Name)
                    if case .text = message.type {
                        HStack {
                            Image("mAssistance")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                            
                            Text(message.senderName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#D7262B"))
                        }
                    }
                    messageContent
                }
                Spacer()
            }
            if message.sender == .user {
                Spacer()
                messageContent
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var messageContent: some View {
        switch message.type {
        case .text(let text):
            VStack(alignment: .leading) {
                Text(text)
                    .foregroundColor(message.sender == .user ? .white : .black)
                
                Text(message.time)
                    .font(.caption2)
                    .foregroundColor(
                        message.sender == .user
                        ? Color.white.opacity(0.8)
                        : Color.gray
                    )
                    .padding(.top, 3)
            }
            .padding()
            .background(
                message.sender == .user
                ? Color(hex: "#D7262B")
                : Color.gray.opacity(0.15)
            )
            .cornerRadius(16)
        case .products(let products):
            RecommendedProductsCard(products: products)
        case .cart(let cart):
            CartProductDetails(cart: cart)
        case .orderSummary(let cart):
            OrderSummaryCard(cart: cart)
        case .paymentDetails(let order):
            PaymentDetailsCard(order: order)
        case .orderConfirmed(let confirmation):
            orderCardView(confirmation: confirmation)
        }
    }
}
