//
//  ChatAPIModels.swift
//  Arch
//
//  Created by saeed on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//  Codable models for the new single chat API.
//

import Foundation

// MARK: - Request

struct ChatAPIRequest: Encodable {
    let userId: String
    let input: String
}

// MARK: - Response Envelope

/// Top-level response: { "type": "...", "data": [...], "message": "..." }
/// `data`'s shape depends on `type`, so we decode it manually based on the
/// discriminator instead of using a single Codable `data` property.
struct ChatAPIResponse: Decodable {
    let type: ChatResponseType
    let message: String
    let recommendationData: [APIProduct]
    let cartData: APICart?
    let orderData: APIOrder?
    let traceId: String?

    private enum CodingKeys: String, CodingKey {
        case type, data, message
        case traceId = "trace_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ChatResponseType.self, forKey: .type)
        self.type = type
        self.message = try container.decode(String.self, forKey: .message)
        self.traceId = try container.decodeIfPresent(String.self, forKey: .traceId)

        switch type {
        case .recommendation:
            recommendationData = try container.decodeIfPresent([APIProduct].self, forKey: .data) ?? []
            cartData = nil
            orderData = nil
        case .cart:
            let wrapped = try container.decodeIfPresent([APICart].self, forKey: .data) ?? []
            cartData = wrapped.first
            recommendationData = []
            orderData = nil
        case .order:
            let wrapped = try container.decodeIfPresent([APIOrder].self, forKey: .data) ?? []
            orderData = wrapped.first
            recommendationData = []
            cartData = nil
        }
    }
}

enum ChatResponseType: String, Decodable {
    case recommendation = "RECOMMENDATION"
    case cart = "CART"
    case order = "ORDER"
}

// MARK: - Product
// Used both for RECOMMENDATION's top-level `data` array and for
// CART's nested `recommendations` array ("you might also like").

struct APIProduct: Decodable {
    let productID: String
    let productImage: String?
    let productName: String
    let productSubtitle: String?
    let productSize: String?
    let productCategory: String?
    let productQuantity: Int?
    let productEarnPoints: Int?
    let productPrice: APIProductPrice
}

struct APIProductPrice: Decodable {
    let price: Double?
    let discountedPrice: Double?
    let currency: String
}

// MARK: - Cart

struct APICart: Decodable {
    let itemCount: Int
    let currency: String
    let items: [APICartItem]
    let summary: [APISummaryLine]
    let recommendations: [APIProduct]
}

/// NOTE: quantity/price are NUMBERS in the CART payload
/// (unlike ORDER items below, where they're strings).
struct APICartItem: Decodable {
    let productID: String
    let productName: String
    let quantity: Int
    let price: Double
}

struct APISummaryLine: Decodable {
    let label: String
    let amount: Double
}

// MARK: - Order

struct APIOrder: Decodable {
    let title: String
    let orderID: String
    let status: String
    let totalPrice: String
    let receiptTimestamp: String
    let items: [APIOrderItem]
    let paymentBrand: String?
    let paymentLast4: String?
    let paymentType: String?
    /// Only present on the final "Order Confirmed" response, e.g. "25-30 minutes".
    let eta: String?
}

/// NOTE: the key is `productId` (lowercase d) here, unlike `productID`
/// everywhere else in the API — and quantity/price are STRINGS.
struct APIOrderItem: Decodable {
    let productId: String
    let productName: String
    let quantity: String
    let price: String
}
