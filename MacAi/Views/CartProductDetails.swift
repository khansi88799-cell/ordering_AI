//
//  CartProductDetails.swift
//  Arch
//
//  Created by saeed on 03/07/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI
import AgenticOrdeingKMM

// MARK: - View

struct CartProductDetails: View {

    var cart: CartDetail
    var onConfirmed: (() -> Void)? = nil
    var onAccept: ((ProductProps) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Header — always visible
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 36, height: 36)
                    Image(systemName: "cart.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Your Cart")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    Text("\(cart.productCount) \(cart.productCount == 1 ? "item" : "items")")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 14)

            // MARK: All Line Items
            ForEach(cart.items) { item in
                HStack {
                    Text("\(item.quantity)x \(item.name)")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    Spacer()
                    let itemTotal = item.productPrice * Double(item.quantity)
                    let currency = item.price.prefix(1)
                    Text("\(currency)\(String(format: "%.2f", itemTotal))")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                .padding(.vertical, 5)
            }

            Divider()
                .padding(.vertical, 10)

            // MARK: Summary Lines from API (Total, Tax, Subtotal)
            if !cart.summaryLines.isEmpty {
                ForEach(cart.summaryLines) { line in
                    let isSubtotal = line.label.lowercased() == "subtotal"
                    HStack {
                        Text(line.label)
                            .font(.system(size: isSubtotal ? 15 : 14, weight: isSubtotal ? .bold : .regular))
                            .foregroundColor(isSubtotal ? .black : .gray)
                        Spacer()
                        Text(line.formatted)
                            .font(.system(size: isSubtotal ? 15 : 14, weight: isSubtotal ? .bold : .regular))
                            .foregroundColor(isSubtotal ? .green : .gray)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                // Fallback if no summary from API
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text(cart.total)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
            }

            Spacer().frame(height: 12)

            // MARK: Recommendations / Promo Cards
            Divider().padding(.vertical, 8)
            Text("You might also like")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.bottom, 4)
            if !cart.recommendations.isEmpty {
                ForEach(Array(cart.recommendations.enumerated()), id: \.offset) { _, props in
                    PromoProductCardView(props: props) {
                        onAccept?(props)
                    }
                    .padding(.bottom, 6)
                }
            }
            /*else {
                // Default promo products when recommendations are empty
                ForEach(promoProducts, id: \Root.productID) { item in
                    DefaultPromoCardView(item: item)
                        .padding(.bottom, 6)
                }
            }*/
            Spacer().frame(height: 8)

            // MARK: Confirm Button
            Button(action: { onConfirmed?() }) {
                HStack {
                    Spacer()
                    Text("Confirmed")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.green)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(red: 0.91, green: 0.97, blue: 0.91))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Order Summary Card

struct OrderSummaryCard: View {

    var cart: CartDetail
    var onProceedToPay: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 36, height: 36)
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Order Summary")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    Text("\(cart.productCount) \(cart.productCount == 1 ? "item" : "items")")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 14)

            // MARK: All Line Items
            ForEach(cart.items) { item in
                HStack {
                    Text("\(item.quantity)x \(item.name)")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    Spacer()
                    let itemTotal = item.productPrice * Double(item.quantity)
                    let currency = item.price.prefix(1)
                    Text("\(currency)\(String(format: "%.2f", itemTotal))")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                .padding(.vertical, 5)
            }

            Divider()
                .padding(.vertical, 10)

            // MARK: Summary Lines from API (Total, Tax, Subtotal)
            if !cart.summaryLines.isEmpty {
                ForEach(cart.summaryLines) { line in
                    let isSubtotal = line.label.lowercased() == "subtotal"
                    HStack {
                        Text(line.label)
                            .font(.system(size: isSubtotal ? 15 : 14, weight: isSubtotal ? .bold : .regular))
                            .foregroundColor(isSubtotal ? .black : .gray)
                        Spacer()
                        Text(line.formatted)
                            .font(.system(size: isSubtotal ? 15 : 14, weight: isSubtotal ? .bold : .regular))
                            .foregroundColor(isSubtotal ? .red : .gray)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text(cart.total)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.vertical, 4)
            }

            Spacer().frame(height: 16)

            // MARK: Proceed to Pay Button
            Button(action: { onProceedToPay?() }) {
                HStack {
                    Spacer()
                    Text("Proceed to Pay")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.red)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    CartProductDetails(
        cart: CartDetail(items: [
            CartLineItem(productID: "P001", name: "Vanilla Shake", price: "$3.49", productPrice: 3.49, quantity: 2),
            CartLineItem(productID: "P002", name: "Big Mac", price: "$5.99", productPrice: 5.99, quantity: 1)
        ])
    )
    .padding()
}

// MARK: - Order Summary Preview

#Preview("Order Summary") {
    OrderSummaryCard(
        cart: CartDetail(items: [
            CartLineItem(productID: "P001", name: "Vanilla Shake", price: "$3.49", productPrice: 3.49, quantity: 2),
            CartLineItem(productID: "P002", name: "Big Mac", price: "$5.99", productPrice: 5.99, quantity: 1)
        ])
    )
    .padding()
}
