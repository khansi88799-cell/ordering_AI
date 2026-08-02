//
//  ProductCardView.swift
//  Arch
//
//  Created by Rahul Gupta on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI

struct ProductCardView: View {

    var product: OrderProduct
    var onAdd: (Int) -> Void       // called with new quantity on Add / +
    var onRemove: (Int) -> Void    // called with new quantity on −

    @State private var counter: Int = 0

    var body: some View {
        HStack {

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
                    .frame(width: 110, height: 110)
                    .clipped()
                    .cornerRadius(12)
                } else {
                    Image(product.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipped()
                        .cornerRadius(12)
                }

                if product.isPopular {
                    Text("Popular")
                        .font(.caption)
                        .padding(6)
                        .background(Color(hex: "#D7262B"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.headline)

                Text(product.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                HStack {
                    Text(product.price)
                        .foregroundColor(Color(hex: "#D7262B"))
                        .bold()

                    Spacer()

                    if counter == 0 {
                        Button(action: {
                            counter = 1
                            onAdd(counter)
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color(hex: "#D7262B"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    } else {
                        quantityCounterButton
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    var quantityCounterButton: some View {
        HStack(spacing: 12) {
            Button(action: {
                if counter > 0 {
                    counter -= 1
                    onRemove(counter)
                }
            }) {
                Image(systemName: "minus")
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#D7262B"))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }

            Text("\(counter)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(minWidth: 20)

            Button(action: {
                counter += 1
                onAdd(counter)
            }) {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#D7262B"))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
