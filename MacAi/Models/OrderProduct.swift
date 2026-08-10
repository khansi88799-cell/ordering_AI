//
//  OrderProduct.swift
//  Arch
//
// Created by saeed on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import Foundation

struct OrderProduct: Identifiable {
    let id = UUID()
    let productID: String
    let name: String
    let description: String
    let price: String
    let productPrice: Double
    let image: String
    let isPopular: Bool
}

struct CartLineItem: Identifiable {
    let id = UUID()
    let productID: String
    let name: String
    let price: String       // formatted e.g. "$3.49"
    let productPrice: Double
    let quantity: Int
}

struct CartSummaryItem: Identifiable {
    let id = UUID()
    let label: String       // "Total", "Tax", "Subtotal"
    let amount: Double
    let currency: String
    var formatted: String { "\(currency)\(String(format: "%.2f", amount))" }
}

struct CartDetail: Identifiable {
    let id = UUID()
    let items: [CartLineItem]
    var summaryLines: [CartSummaryItem] = []
    var recommendations: [APIProduct] = []
    var currency: String = "$"

    var productCount: Int { items.count }

    // Use Subtotal from API summary if available, else calculate
    var total: String {
        if let subtotal = summaryLines.first(where: { $0.label.lowercased() == "subtotal" }) {
            return subtotal.formatted
        }
        let sum = items.reduce(0.0) { $0 + ($1.productPrice * Double($1.quantity)) }
        return "\(currency)\(String(format: "%.2f", sum))"
    }

    // Legacy helpers
    var name: String { items.first?.name ?? "" }
    var price: String { items.first?.price ?? "" }
    var quantity: String { "\(items.first?.quantity ?? 0)" }
}
