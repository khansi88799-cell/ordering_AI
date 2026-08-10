//
//  ChatMessage.swift
//  Arch
//
//  Created by saeed on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//
//

import Foundation

// MARK: - Order Confirmation Data (built client-side; API never returns an order number)
struct OrderConfirmationData {
    let orderNumber: String
    let totalPrice: String
    let status: String
    let timestamp: String
    let items: [CartLineItem]
    let paymentBrand: String?
    let paymentLast4: String?
    let eta: String?
}

enum MessageType {

    case text(String)
    case products([OrderProduct])
    case cart(CartDetail)
    case orderSummary(CartDetail)
    case paymentDetails(APIOrder)
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
    var senderName: String = "McDonald's Assistant"
}
