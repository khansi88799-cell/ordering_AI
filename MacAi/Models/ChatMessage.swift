//
//  ChatMessage.swift
//  Arch
//
//  Created by Rahul Gupta on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import Foundation

// MARK: - Order Confirmation Data (mapped from KMM OrderConfirmation)
struct OrderConfirmationData {
    let orderNumber: String   // maps to OrderConfirmation.title
    let totalPrice: String    // maps to OrderConfirmation.totalPrice
    let status: String        // maps to OrderConfirmation.status
    let timestamp: String     // maps to OrderConfirmation.receiptTimestamp
}

enum MessageType {
    
    case text(String)
    case products(OrderProduct)
    case cart(CartDetail)
    case orderSummary(CartDetail)
    case orderConfirmed(OrderConfirmationData)
}

enum Sender {
    case user
    case bot
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let type: MessageType
    let time: String
    let sender: Sender
}
