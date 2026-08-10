//
//  RecommendedProductsCard.swift
//
//
//  Created by saeed on 4/08/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI

struct RecommendedProductsCard: View {

    var products: [OrderProduct]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#D7262B"))
                        .frame(width: 36, height: 36)
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Recommended for You")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    Text("\(products.count) \(products.count == 1 ? "item" : "items")")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 14)

            // MARK: Product Rows
            ForEach(Array(products.enumerated()), id: \.offset) { index, product in
                ProductCardView(product: product)
                if index < products.count - 1 {
                    Divider().padding(.vertical, 8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    RecommendedProductsCard(products: [
        OrderProduct(productID: "P015", name: "Big Mac", description: "Burger", price: "$5.99", productPrice: 5.99, image: "BigMac", isPopular: true),
        OrderProduct(productID: "P020", name: "McChicken", description: "Burger", price: "$3.49", productPrice: 3.49, image: "", isPopular: false)
    ])
    .padding()
}
