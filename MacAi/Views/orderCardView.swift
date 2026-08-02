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

    var body: some View {
        VStack(spacing: 20) {

            // MARK: Green checkmark
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            // MARK: Title
            VStack(spacing: 4) {
                Text("Order Confirmed! 🎉")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.3))
                Text("Thank you for your order!")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            // MARK: Order Number card
            VStack(spacing: 6) {
                Text("Order Number")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                Text(confirmation.orderNumber)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

            // MARK: Order Summary card
            VStack(alignment: .leading, spacing: 10) {
                Text("Order Summary")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)

                Divider()

                HStack {
                    Text("Total Paid")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text(confirmation.totalPrice)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .padding(20)
        .background(Color(red: 0.93, green: 0.98, blue: 0.93))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    orderCardView(
        confirmation: OrderConfirmationData(
            orderNumber: "#627",
            totalPrice: "$12.97",
            status: "Completed",
            timestamp: "July 8, 2026 at 3:00:00 PM UTC+5:30"
        )
    )
    .padding()
}
