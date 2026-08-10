//
//  PaymentDetailsCard.swift
//  Arch
//
//  Created by saeed on 4/08/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI

struct PaymentDetailsCard: View {

    var order: APIOrder

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
                    Text(order.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    Text(order.status)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 14)

            // MARK: Payment method
            if let brand = order.paymentBrand, let last4 = order.paymentLast4 {
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundColor(.gray)
                    Text("\(brand) ending \(last4)")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.vertical, 6)
                Divider().padding(.bottom, 10)
            }

            // MARK: Total
            HStack {
                Text("Amount to be Charged")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Text(order.totalPrice.hasPrefix("$") ? order.totalPrice : "$\(order.totalPrice)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.red)
            }
            .padding(.vertical, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    PaymentDetailsCard(
        order: APIOrder(
            title: "Payment Details",
            orderID: "",
            status: "Awaiting Payment Authorization",
            totalPrice: "16.79",
            receiptTimestamp: "August 05, 2026 at 09:46:11 AM UTC+0:00",
            items: [],
            paymentBrand: "Visa",
            paymentLast4: "1234",
            paymentType: "card",
            eta: nil
        )
    )
    .padding()
}
