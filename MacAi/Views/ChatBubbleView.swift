//
//  ChatBubbleView.swift
//  Arch
//
//  Created by Rahul Gupta on 24/06/26.
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
                            
                            Text("McDonald's Assistant")
                                .font(.caption)
                                .foregroundColor(.gray)
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
        case .products(let product):
            VStack(alignment: .leading, spacing: 12) {
                ProductCardView(
                    product: product,
                    onAdd: { newQty in
                        viewModel.updateCart(product: product, quantity: newQty)
                    },
                    onRemove: { newQty in
                        viewModel.updateCart(product: product, quantity: newQty)
                    }
                )
            }
            .padding(.vertical, 5)
        case .cart(let cart):
            CartProductDetails(
                cart: cart,
                onConfirmed: {
                    viewModel.isConfirmedTapped = true
                    viewModel.appendOrderSummary(cart)
                },
                onAccept: { props in
                    viewModel.addPromoToCart(props: props)
                }
            )
        case .orderSummary(let cart):
            OrderSummaryCard(cart: cart, onProceedToPay: {
                viewModel.isProceedToPayTapped = true
                viewModel.callOrderSummery(cart: cart)
                //orderCardView(confirmation: confirmation)
            })
        case .orderConfirmed(let confirmation):
            orderCardView(confirmation: confirmation)
        }
    }
}
