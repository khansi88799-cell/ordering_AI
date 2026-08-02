//
//  PromoProductCardView.swift
//  Arch
//
//  Created by saeed on 27/07/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI
import AgenticOrdeingKMM

struct PromoProductCardView: View {

    let props: ProductProps
    var onAccept: (() -> Void)? = nil

    private let yellow = Color(red: 1.0, green: 0.78, blue: 0.17)   // #FFC72C
    private let darkYellow = Color(red: 0.48, green: 0.32, blue: 0.0) // #7A5200
    private let orange = Color(red: 1.0, green: 0.34, blue: 0.13)    // #FF5722
    private let cardBg = Color(red: 0.97, green: 0.96, blue: 0.93)   // #F8F5EE

    var body: some View {
        ZStack(alignment: .topLeading) {

            // MARK: Main Card
            HStack(alignment: .center, spacing: 0) {

                // Product Image
                AsyncImage(url: URL(string: fixedImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.leading, 8)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Text + Price + Button
                VStack(alignment: .leading, spacing: 4) {
                    Text(props.productName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)

                    if let subtitle = props.productSubtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer().frame(height: 6)

                    HStack(alignment: .center, spacing: 8) {
                        // Strikethrough original price
                        let originalPrice = props.productPrice.price?.doubleValue ?? 0.0
                        Text("\(props.productPrice.currency)\(String(format: "%.2f", originalPrice))")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .strikethrough(true, color: .gray)

                        // Discounted price
                        let discounted = props.productPrice.discountedPrice?.doubleValue ?? originalPrice
                        Text("\(props.productPrice.currency)\(String(format: "%.2f", discounted))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(orange)

                        Spacer()

                        // Accept Button
                        Button(action: { onAccept?() }) {
                            Text("Accept")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(yellow)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.leading, 10)
                .padding(.trailing, 12)
                .padding(.vertical, 12)
            }
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(yellow, lineWidth: 2)
            )
            .padding(.top, 12) // space for badge overlap

            // MARK: Offer Badge (top-left overlay)
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 13))
                    .foregroundColor(darkYellow)
                Text("Offer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(darkYellow)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(yellow)
            .clipShape(Capsule())
            .offset(x: 10, y: 0) // sits on top-left corner of card
        }
    }

    // Mirror Android URL fix
    private var fixedImageURL: String {
        (props.productImage ?? "").replacingOccurrences(
            of: "https://storage.cloud.google.com/",
            with: "https://storage.googleapis.com/"
        )
    }
}

#Preview {
    VStack {
        Text("PromoProductCardView Preview")
            .font(.headline)
            .padding()
        Text("(Requires real ProductProps from KMM)")
            .font(.caption)
            .foregroundColor(.gray)
    }
    .padding()
}
