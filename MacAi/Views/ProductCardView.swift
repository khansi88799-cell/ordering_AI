//
//  ProductCardView.swift
//  Arch
//
//  Created by saeed on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI

struct ProductCardView: View {

    var product: OrderProduct

    private let rowHeight: CGFloat = 88

    var body: some View {
        HStack(spacing: 12) {

            ZStack(alignment: .topLeading) {
                if let url = URL(string: product.image), !product.image.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: rowHeight, height: rowHeight)
                    .clipped()
                    .cornerRadius(12)
                } else {
                    Image(product.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: rowHeight, height: rowHeight)
                        .clipped()
                        .cornerRadius(12)
                }

                if product.isPopular {
                    Text("Popular")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#D7262B"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Text(product.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(product.price)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#D7262B"))
            }
            .frame(height: rowHeight, alignment: .top)

            Spacer(minLength: 0)
        }
        .frame(height: rowHeight)
    }
}
