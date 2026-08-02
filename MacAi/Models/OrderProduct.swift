//
//  OrderProduct.swift
//  Arch
//
//  Created by Rahul Gupta on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import AgenticOrdeingKMM

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
    var recommendations: [ProductProps] = []
    //var promoProducts: [OrderProduct] = []
    var currency: String = "$"

    var productCount: Int { items.count }
    
    var promoProducts  = [
        OrderProduct(productID: "111",
                     name: "Big Mac",
                        description: "Two all‑beef patties, special sauce, lettuce, cheese",
                        price: "$5.99",
                        productPrice: 5.9,
                        image: "burger",
                        isPopular: true),

        OrderProduct(productID: "111",
                     name: "Medium Fries",
                        description: "World famous crispy golden fries",
                        price: "$2.99",
                     productPrice: 5.9,
                        image: "fries",
                        isPopular: false),

        OrderProduct(productID: "111",
                     name: "Coca‑Cola",
                        description: "Refreshing Coca‑Cola soft drink",
                        price: "$1.99",
                     productPrice: 5.9,
                        image: "coke",
                        isPopular: false)
            ]

    // Use Subtotal from API summary if available, else calculate
    var total: String {
        if let subtotal = summaryLines.first(where: { $0.label.lowercased() == "subtotal" }) {
            return subtotal.formatted
        }
        let sum = items.reduce(0.0) { $0 + ($1.productPrice * Double($1.quantity)) }
        return "\(currency)\(String(format: "%.2f", sum))"
    }

    // Recalculate summary after adding a promo product
    func addingPromo(product: CartLineItem) -> CartDetail {
        var newItems = items
        if let idx = newItems.firstIndex(where: { $0.productID == product.productID }) {
            let existing = newItems[idx]
            newItems[idx] = CartLineItem(
                productID: existing.productID,
                name: existing.name,
                price: existing.price,
                productPrice: existing.productPrice,
                quantity: existing.quantity + 1
            )
        } else {
            newItems.append(product)
        }
        // Recalculate summary lines
        let newSubtotal = newItems.reduce(0.0) { $0 + ($1.productPrice * Double($1.quantity)) }
        let taxLine = summaryLines.first(where: { $0.label.lowercased() == "tax" })
        let taxAmount = taxLine?.amount ?? 0.0
        let newTotal = newSubtotal + taxAmount
        let newSummary = [
            CartSummaryItem(label: "Total",    amount: newTotal,    currency: currency),
            CartSummaryItem(label: "Tax",      amount: taxAmount,   currency: currency),
            CartSummaryItem(label: "Subtotal", amount: newSubtotal, currency: currency)
        ]
        var updated = CartDetail(items: newItems)
        updated.summaryLines = newSummary
        updated.recommendations = recommendations  // carry over [ProductProps]
        updated.currency = currency
        return updated
    }

    // Legacy helpers
    var name: String { items.first?.name ?? "" }
    var price: String { items.first?.price ?? "" }
    var quantity: String { "\(items.first?.quantity ?? 0)" }
}
