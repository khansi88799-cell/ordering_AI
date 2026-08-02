//
//  ChatViewModel.swift
//  Arch
//
//  Created by Rahul Gupta on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI
import AgenticOrdeingKMM
import Combine

class ChatViewModel: ObservableObject {

    // MARK: - Published State
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var components: [SDUIComponent] = []
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var isError: Bool = false
    @Published var isConfirmedTapped: Bool = false
    @Published var isProceedToPayTapped: Bool = false
    @Published var loadingMsgString: String? = "loading"

    private let orchestrator: AgentOrchestrator
    private let observer: ScreenStateObserver
    private var didHydrateInitialMessages = false
    /// Stores the full ViewCartComponent from the last loadCart response
    private var pendingViewCartProps: ViewCartProps? = nil

    /// Stores recommendations from the last ViewCartComponent response
    private var pendingRecommendations: [ProductProps] = []

    /// Suppresses ScreenStateObserver side-effects during loadCart / OrderSummery calls
    /// since those APIs handle their own response in the completion handler.
    private var suppressObserver = false
    
    /// Indicates we are waiting for a ViewCartComponent from the observer
    private var waitingForCart = false

    // MARK: - Cart State
    /// Tracks all products added to cart: [productID: (product, quantity)]
    private var cartItems: [String: (product: OrderProduct, quantity: Int)] = [:]

    init(screenId: String) {
        orchestrator = SharedModule.shared.provideOrchestrator()
        observer = ScreenStateObserver(orchestrator: orchestrator)

        // Observe KMM state changes
        observer.observe { [weak self] state in
            self?.apply(state: state)
        }

        // Show initial welcome message
        initalBoatMsg()
    }

    deinit {
        observer.dispose()
    }

    // MARK: - Initial Bot Message
    func initalBoatMsg() {
        appendBotText("Hello! Welcome to McDonald's. How can I assist you today?")
    }

    // MARK: - State Handler
    private func apply(state: ScreenState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let ready = state as? ScreenStateReady {
                // During loadCart suppression — capture full ViewCartComponent props
                if self.suppressObserver {
                    for component in ready.components {
                        if let viewCartComponent = component as? ViewCartComponent {
                            self.pendingViewCartProps = viewCartComponent.props
                            self.pendingRecommendations = Array(viewCartComponent.props.recommendations)
                        }
                    }
                    return
                }
                self.components = ready.components
                self.errorMessage = nil
                self.isError = false
                self.isLoading = false
                self.isTyping = false
                self.renderComponents(ready.components)
            } else if state is ScreenStateError {
                // Only show error for loadScreen calls, not cart/order calls
                self.isLoading = false
                self.isTyping = false
                // Do NOT set isError = true here — let the view decide based on messages being empty
            } else {
                self.isLoading = true
            }
        }
    }

    // MARK: - Render Components (mirrors Android RenderComponent)
    func renderComponents(_ components: [SDUIComponent]) {
        for component in components {
            renderComponent(component)
        }
    }

    private func renderComponent(_ component: SDUIComponent) {
        if let message = component as? MessageComponent {
            if let label = message.label, !label.isEmpty {
                appendBotText(label)
            }
        } else if let productCard = component as? ProductCard {
            appendProduct(mapProductProps(productCard.props))
        } else if let orderSummery = component as? OrderSummeryComponent {
            let confirmation = OrderConfirmationData(
                orderNumber: orderSummery.props.title,
                totalPrice: orderSummery.props.totalPrice,
                status: orderSummery.props.status,
                timestamp: orderSummery.props.receiptTimestamp
            )
            appendOrderConfirmed(confirmation)
        } else if let contentSection = component as? ContentSection {
            renderComponents(contentSection.components)
        } else if let footerSection = component as? FooterSection {
            renderComponents(footerSection.components)
        } else if let listComponent = component as? ListComponent {
            renderComponents(listComponent.props.items)
        } else if component is QuickActions {
            return
        }
    }

    // MARK: - Load Screen with User Input (called for every user message except "view cart")
    func loadScreenWithUserInput(_ userInput: String) {
        isTyping = true
        orchestrator.loadScreen(userId: "U001", input: userInput) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.isTyping = false
                    self.errorMessage = error.localizedDescription
                    self.appendBotText("Sorry, something went wrong. Please try again.")
                }
                // On success: ScreenStateObserver fires → apply(state:) → renderComponents
            }
        }
    }

    // MARK: - Map ProductProps → OrderProduct
    private func mapProductProps(_ props: ProductProps) -> OrderProduct {
        let priceString = formatProductPrice(props)
        let priceDouble: Double = {
            if let discounted = props.productPrice.discountedPrice { return discounted.doubleValue }
            if let base = props.productPrice.price { return base.doubleValue }
            return 0.0
        }()
        let isPopular = props.highlight?.boolValue ?? false
        let description = props.productSubtitle ?? props.productCategory ?? ""
        let fixedImageUrl = props.productImage?
            .replacingOccurrences(
                of: "https://storage.cloud.google.com/",
                with: "https://storage.googleapis.com/"
            ) ?? ""
        return OrderProduct(
            productID: props.productID,
            name: props.productName,
            description: description,
            price: priceString,
            productPrice: priceDouble,
            image: fixedImageUrl,
            isPopular: isPopular
        )
    }

    private func formatProductPrice(_ productPrice: ProductProps) -> String {
        let currency = productPrice.productPrice.currency
        if let discounted = productPrice.productPrice.discountedPrice {
            return "\(currency)\(String(format: "%.2f", discounted.doubleValue))"
        }
        if let base = productPrice.productPrice.price {
            return "\(currency)\(String(format: "%.2f", base.doubleValue))"
        }
        return ""
    }

    // MARK: - Actions
    func handleQuickAction(_ text: String) {
        inputText == text ? sendMessage() : (inputText = text)
    }

    func sendMessage() {
        guard !inputText.isEmpty else { return }

        let text = inputText
        inputText = ""

        appendUserText(text)

        // "View Cart" → call loadCart API with the full accumulated cart
        if text.lowercased().contains("view cart") {
            loadingMsgString = "Generating your cart. Please wait"
            isTyping = true
            isError = false
            errorMessage = nil
            guard !cartItems.isEmpty else {
                appendBotText("Your cart is empty. Add some items first!")
                isTyping = false
                return
            }
            let cartProducts = cartItems.values.map { item in
                CartProductRequest(
                    productID: item.product.productID,
                    productName: item.product.name,
                    productQuantity: Int32(item.quantity),
                    productPrice: item.product.productPrice
                )
            }
            let input = buildCartInput(cartProducts: Array(cartProducts))
            suppressObserver = true
            orchestrator.loadCart(userId: "U001", input: input) { [weak self] error in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    guard let self = self else { return }
                    self.suppressObserver = false
                    self.isTyping = false
                    self.isError = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.appendBotText("Failed to load cart. Please try again.")
                    } else {
                        self.appendBotText("Here's your current cart:")
                        let cart = self.buildCartDetailFromAPIResponse()
                        self.pendingViewCartProps = nil
                        self.pendingRecommendations = []
                        self.appendCart(cart)
                    }
                }
            }
            return
        }

        // All other user text → call loadScreen API with user input
        loadScreenWithUserInput(text)
    }

    // MARK: - Cart Management
    func updateCart(product: OrderProduct, quantity: Int) {
        if quantity <= 0 {
            cartItems.removeValue(forKey: product.productID)
        } else {
            cartItems[product.productID] = (product, quantity)
        }
        print("cartItems: \(cartItems.mapValues { "\($0.product.name) x\($0.quantity)" })")
    }

    /// Builds CartDetail from the actual API ViewCartComponent response
    private func buildCartDetailFromAPIResponse() -> CartDetail {
        guard let props = pendingViewCartProps else {
            // Fallback to local cartItems if no API response captured
            let lineItems = cartItems.values.map { entry in
                CartLineItem(
                    productID: entry.product.productID,
                    name: entry.product.name,
                    price: entry.product.price,
                    productPrice: entry.product.productPrice,
                    quantity: entry.quantity
                )
            }.sorted { $0.name < $1.name }
            var fallback = CartDetail(items: lineItems)
            fallback.recommendations = pendingRecommendations
            return fallback
        }
        let currency = props.currency
        let lineItems = props.items.map { item in
            CartLineItem(
                productID: item.productID,
                name: item.productName,
                price: "\(currency)\(String(format: "%.2f", item.price))",
                productPrice: item.price,
                quantity: Int(item.quantity)
            )
        }
        let summaryLines = props.summary.map { line in
            CartSummaryItem(label: line.label, amount: line.amount, currency: currency)
        }
        var cart = CartDetail(items: lineItems)
        cart.summaryLines = summaryLines
        cart.recommendations = Array(props.recommendations)
        cart.currency = currency
        return cart
    }

    /// Called when user taps "Accept" on a promo card inside the cart bubble.
    /// Adds the promo product to the current cart response and recalculates summary.
    func addPromoToCart(props: ProductProps) {
        let discountedPrice = props.productPrice.discountedPrice?.doubleValue ?? props.productPrice.price?.doubleValue ?? 0.0
        let currency = props.productPrice.currency

        // Find the last cart message to update
        guard let lastCartIndex = messages.indices.last(where: {
            if case .cart = messages[$0].type { return true }
            return false
        }), case .cart(let currentCart) = messages[lastCartIndex].type else {
            appendBotText("Could not find your cart. Please type 'view cart' again.")
            return
        }

        // Build promo CartLineItem
        let promoLineItem = CartLineItem(
            productID: props.productID,
            name: props.productName,
            price: "\(currency)\(String(format: "%.2f", discountedPrice))",
            productPrice: discountedPrice,
            quantity: 1
        )

        // Use addingPromo to get updated cart with recalculated summary
        let updatedCart = currentCart.addingPromo(product: promoLineItem)
        appendBotText("\(props.productName) added to your cart! 🎉")
        appendCart(updatedCart)
    }

    func addToCart(product: OrderProduct) {
        updateCart(product: product, quantity: (cartItems[product.productID]?.quantity ?? 0) + 1)
    }

    // MARK: - Cart Input Builder
    private func buildCartInput(cartProducts: [CartProductRequest]) -> String {
        let items = cartProducts.map { product in
            "{\"productID\":\"\(product.productID)\",\"productName\":\"\(product.productName)\",\"productQuantity\":\(product.productQuantity),\"productPrice\":\(product.productPrice)}"
        }.joined(separator: ",")
        return "{\"userId\":\"U001\",\"productDetails\":[\(items)]}"
    }

    // MARK: - Message Builders
    private func appendUserText(_ text: String) {
        messages.append(ChatMessage(type: .text(text), time: currentTime(), sender: .user))
    }

    func appendBotText(_ text: String) {
        messages.append(ChatMessage(type: .text(text), time: currentTime(), sender: .bot))
    }

    private func appendProduct(_ product: OrderProduct) {
        messages.append(ChatMessage(type: .products(product), time: currentTime(), sender: .bot))
    }

    private func appendCart(_ cart: CartDetail) {
        messages.append(ChatMessage(type: .cart(cart), time: currentTime(), sender: .bot))
    }

    func appendOrderSummary(_ cart: CartDetail) {
        isConfirmedTapped = true
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.isTyping = false
            self.isConfirmedTapped = false
            self.appendBotText("Here is your order summary 🧾")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                self.messages.append(ChatMessage(type: .orderSummary(cart), time: self.currentTime(), sender: .bot))
            }
        }
    }
    
    // MARK: - Loading Message
    var loadingMessage: String {
        if isProceedToPayTapped {
            return "Reviewing your payment information and confirming your order..."
        } else if isConfirmedTapped {
            return "Generating your order summary. Please wait..."
        } else if loadingMsgString == "Generating your cart. Please wait" {
            return "Generating your cart. Please wait..."
        }
        return "Please wait..."
    }

    // MARK: - Place Order via KMM OrderSummery API
    func callOrderSummery(cart: CartDetail) {
        isTyping = true
        isError = false
        errorMessage = nil
        isProceedToPayTapped = true

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy 'at' h:mm:ss a 'UTC'+5:30"
        formatter.locale = Locale(identifier: "en_US")
        let timestamp = formatter.string(from: Date())

        let totalPrice = cart.total
        let status = "Completed"

        let cartProducts = cartItems.values.map { item in
            CartProductRequest(
                productID: item.product.productID,
                productName: item.product.name,
                productQuantity: Int32(item.quantity),
                productPrice: item.product.productPrice
            )
        }
        let input = buildCartInput(cartProducts: Array(cartProducts))

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.suppressObserver = true
            self.orchestrator.OrderSummery(
                userId: "U001",
                totalPrice: totalPrice,
                status: status,
                receiptTimestamp: timestamp,
                input: input
            ) { [weak self] error in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    guard let self = self else { return }
                    self.suppressObserver = false
                    self.isTyping = false
                    self.isError = false
                    self.isProceedToPayTapped = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.appendBotText("Failed to place order. Please try again.")
                        return
                    }
                    let orderNumber = "ORD-\(Int.random(in: 100000...999999))"
                    let confirmation = OrderConfirmationData(
                        orderNumber: orderNumber,
                        totalPrice: totalPrice,
                        status: status,
                        timestamp: timestamp
                    )
                    self.appendBotText("Your order has been placed successfully! 🎉")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                        self?.appendOrderConfirmed(confirmation)
                    }
                }
            }
        }
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
