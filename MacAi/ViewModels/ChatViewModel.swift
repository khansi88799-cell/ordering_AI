//
//  ChatViewModel.swift
//  Arch
//
// Created by saeed on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI
import Combine

class ChatViewModel: ObservableObject {

    // MARK: - Agent Names
    static let recommendationAgentName = "Recommendation Agent"
    static let cartAgentName = "Cart Agent"
    static let orderAgentName = "Order Agent"

    // MARK: - Published State
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isError: Bool = false
    /// Toggle to mute/unmute the bot speaking its replies aloud.
    @Published var isVoiceReplyEnabled: Bool = true
    private let apiService: ChatAPIService
    private let speechSynthesizer = SpeechSynthesizerManager.shared
    private var audioWebSocket: ChatAudioWebSocket?
    private var lastOrderSnapshot: APIOrder?

    init(screenId: String, apiService: ChatAPIService = .shared) {
        self.apiService = apiService
        audioWebSocket = ChatAudioWebSocket(userId: "U001")
        audioWebSocket?.connect()
        initalBoatMsg()
    }

    deinit {
        audioWebSocket?.disconnect()
    }

    // MARK: - Initial Bot Message
    func initalBoatMsg() {
        let greeting = "Hi! I'm your Mcdonald Food Agent. Describe your perfect meal in your own words."
        appendBotText(greeting)
        guard isVoiceReplyEnabled else { return }
        StaticAudioPlayer.shared.play(resourceName: "greeting", fallbackText: greeting)
    }

    // MARK: - User-Facing Actions
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        appendUserText(text)
        callChatAPI(input: text)
    }

    func toggleVoiceReply() {
        isVoiceReplyEnabled.toggle()
        AudioStreamPlayer.shared.isMuted = !isVoiceReplyEnabled
        if !isVoiceReplyEnabled {
            speechSynthesizer.stopSpeaking()
            AudioStreamPlayer.shared.stop()
            StaticAudioPlayer.shared.stop()
        }
    }

    // MARK: - Networking
    private func callChatAPI(input: String) {
        isTyping = true
        errorMessage = nil
        apiService.send(input: input) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isTyping = false
                switch result {
                case .success(let response):
                    self.handle(response)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    let errorText = "Sorry, something went wrong. Please try again."
                    self.appendBotText(errorText)
                    if self.isVoiceReplyEnabled {
                        StaticAudioPlayer.shared.play(resourceName: "network_error", fallbackText: errorText)
                    }
                }
            }
        }
    }

    // MARK: - Response Handling
    private func handle(_ response: ChatAPIResponse) {
        AudioStreamPlayer.shared.fallbackText = response.message
        AudioStreamPlayer.shared.expectedTraceId = response.traceId

        switch response.type {
        case .recommendation:
            let popularID = topEarnPointsProductID(in: response.recommendationData)
            let products = response.recommendationData.map { mapAPIProduct($0, popularID: popularID) }
            if !products.isEmpty {
                appendProducts(products)
            }
            appendBotText(response.message, agentName: Self.recommendationAgentName)

        case .cart:
            if let apiCart = response.cartData {
                appendCart(mapAPICart(apiCart))
            }
            appendBotText(response.message, agentName: Self.cartAgentName)

        case .order:
            handleOrder(response)
        }
    }

    private func handleOrder(_ response: ChatAPIResponse) {
        guard let order = response.orderData else {
            finalizeOrder(message: response.message)
            return
        }
        if order.title == "Payment Details" {
            lastOrderSnapshot = order
            messages.append(ChatMessage(type: .paymentDetails(order), time: currentTime(), sender: .bot))
            appendBotText(response.message, agentName: Self.orderAgentName)
            return
        }
        if !order.orderID.isEmpty {
            finalizeOrder(message: response.message, order: order)
            return
        }
        lastOrderSnapshot = order
        messages.append(ChatMessage(type: .orderSummary(cartDetail(fromOrder: order)), time: currentTime(), sender: .bot))
        appendBotText(response.message, agentName: Self.orderAgentName)
    }

    private func finalizeOrder(message: String, order: APIOrder? = nil) {
        let source = order ?? lastOrderSnapshot
        let realOrderID = (source?.orderID).flatMap { $0.isEmpty ? nil : $0 }
        let orderNumber = realOrderID.map { String($0.prefix(8)).uppercased() } ?? "ORD-\(Int.random(in: 100000...999999))"
        let confirmation = OrderConfirmationData(
            orderNumber: orderNumber,
            totalPrice: formattedPrice(source?.totalPrice ?? ""),
            status: "Completed",
            timestamp: source?.receiptTimestamp ?? currentTime(),
            items: source.map { cartDetail(fromOrder: $0).items } ?? [],
            paymentBrand: order?.paymentBrand ?? lastOrderSnapshot?.paymentBrand,
            paymentLast4: order?.paymentLast4 ?? lastOrderSnapshot?.paymentLast4,
            eta: order?.eta ?? lastOrderSnapshot?.eta
        )
        appendOrderConfirmed(confirmation)
        appendBotText(message, agentName: Self.orderAgentName)
        lastOrderSnapshot = nil
        clearCartOnServer()
    }

    private func clearCartOnServer() {
        apiService.send(input: "clear cart") { _ in }
    }

    // MARK: - Mapping: API models -> UI models
    private func topEarnPointsProductID(in products: [APIProduct]) -> String? {
        products.max(by: { ($0.productEarnPoints ?? 0) < ($1.productEarnPoints ?? 0) })?.productID
    }

    private func mapAPIProduct(_ props: APIProduct, popularID: String?) -> OrderProduct {
        let currency = props.productPrice.currency
        let priceValue = props.productPrice.discountedPrice ?? props.productPrice.price ?? 0
        let priceString = "\(currency)\(String(format: "%.2f", priceValue))"
        let fixedImage = (props.productImage ?? "")
            .replacingOccurrences(of: "https://storage.cloud.google.com/", with: "https://storage.googleapis.com/")
        return OrderProduct(
            productID: props.productID,
            name: props.productName,
            description: props.productSubtitle ?? props.productCategory ?? "",
            price: priceString,
            productPrice: priceValue,
            image: fixedImage,
            isPopular: props.productID == popularID
        )
    }

    private func mapAPICart(_ apiCart: APICart) -> CartDetail {
        let lineItems = apiCart.items.map { item in
            CartLineItem(
                productID: item.productID,
                name: item.productName,
                price: "\(apiCart.currency)\(String(format: "%.2f", item.price))",
                productPrice: item.price,
                quantity: item.quantity
            )
        }
        var cart = CartDetail(items: lineItems)
        let lines = apiCart.summary.map {
            CartSummaryItem(label: $0.label, amount: $0.amount, currency: apiCart.currency)
        }
        cart.summaryLines = lines.sorted { Self.summaryLineOrder($0.label) < Self.summaryLineOrder($1.label) }
        cart.recommendations = apiCart.recommendations
        cart.currency = apiCart.currency
        return cart
    }

    private static func summaryLineOrder(_ label: String) -> Int {
        switch label.lowercased() {
        case "subtotal": return 0
        case "tax": return 1
        case "total": return 2
        default: return 3
        }
    }

    private func cartDetail(fromOrder order: APIOrder) -> CartDetail {
        let lineItems = order.items.map { item -> CartLineItem in
            let price = Double(item.price) ?? 0
            let qty = Int(item.quantity) ?? 0
            return CartLineItem(
                productID: item.productId,
                name: item.productName,
                price: formattedPrice(item.price),
                productPrice: price,
                quantity: qty
            )
        }
        var cart = CartDetail(items: lineItems)
        let total = Double(order.totalPrice) ?? lineItems.reduce(0) { $0 + $1.productPrice * Double($1.quantity) }
        cart.summaryLines = [CartSummaryItem(label: "Total", amount: total, currency: "$")]
        return cart
    }

    private func formattedPrice(_ raw: String) -> String {
        raw.hasPrefix("$") ? raw : "$\(raw)"
    }

    // MARK: - Loading Message
    let loadingMessage = "Thinking"

    // MARK: - Message Builders
    private func appendUserText(_ text: String) {
        messages.append(ChatMessage(type: .text(text), time: currentTime(), sender: .user))
    }

    func appendBotText(_ text: String, agentName: String = "Main Agent") {
        messages.append(ChatMessage(type: .text(text), time: currentTime(), sender: .bot, senderName: agentName))
    }

    private func appendProducts(_ products: [OrderProduct]) {
        messages.append(ChatMessage(type: .products(products), time: currentTime(), sender: .bot))
    }

    private func appendCart(_ cart: CartDetail) {
        messages.append(ChatMessage(type: .cart(cart), time: currentTime(), sender: .bot))
    }

    private func appendOrderConfirmed(_ confirmation: OrderConfirmationData) {
        messages.append(ChatMessage(type: .orderConfirmed(confirmation), time: currentTime(), sender: .bot))
    }

    // MARK: - Helpers
    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: Date())
    }
}
