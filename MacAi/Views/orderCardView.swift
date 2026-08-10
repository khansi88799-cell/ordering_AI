//
//  orderCardView.swift
//  Arch
//
//  Created by saeed on 08/07/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI

struct orderCardView: View {

    var confirmation: OrderConfirmationData

    private let headerGreen = LinearGradient(
        colors: [Color(red: 0.16, green: 0.60, blue: 0.32), Color(red: 0.09, green: 0.42, blue: 0.22)],
        startPoint: .top,
        endPoint: .bottom
    )
    private let sectionLabelGreen = Color(red: 0.09, green: 0.45, blue: 0.24)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(sectionLabelGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Order Confirmed!")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                    Text("Order ID: #\(confirmation.orderNumber)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(16)
            .background(headerGreen)

            Divider()

            // MARK: Order Items
            VStack(alignment: .leading, spacing: 8) {
                Text("ORDER ITEMS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(sectionLabelGreen)
                    .tracking(0.5)

                ForEach(confirmation.items) { item in
                    Text("•  \(item.name) × \(item.quantity)")
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                }
            }
            .padding(16)

            // MARK: Payment
            if confirmation.paymentBrand != nil || confirmation.paymentLast4 != nil {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("PAYMENT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(sectionLabelGreen)
                        .tracking(0.5)

                    if let brand = confirmation.paymentBrand, let last4 = confirmation.paymentLast4 {
                        HStack {
                            Text("Card")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(brand) ending \(last4)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }

                    HStack {
                        Text("Paid")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(confirmation.totalPrice)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(sectionLabelGreen)
                    }
                }
                .padding(16)
            }

            // MARK: Delivery
            if let eta = confirmation.eta {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("DELIVERY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(sectionLabelGreen)
                        .tracking(0.5)

                    HStack {
                        Text("ETA")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(eta)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(sectionLabelGreen)
                    }
                }
                .padding(16)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    orderCardView(
        confirmation: OrderConfirmationData(
            orderNumber: "MCD567890",
            totalPrice: "$12.97",
            status: "Completed",
            timestamp: "July 8, 2026 at 3:00:00 PM UTC+5:30",
            items: [
                CartLineItem(productID: "P001", name: "Peri Peri Fries", price: "$5.00", productPrice: 5.0, quantity: 1),
                CartLineItem(productID: "P002", name: "Coke", price: "$2.50", productPrice: 2.5, quantity: 1)
            ],
            paymentBrand: "Visa",
            paymentLast4: "1234",
            eta: "25-30 minutes"
        )
    )
    .padding()
}
