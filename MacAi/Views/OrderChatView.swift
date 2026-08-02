//
//  OrderChatView.swift
//  Arch
//
//  Created by Rahul Gupta on 24/06/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import SwiftUI

struct OrderChatView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatViewModel(screenId: "chat view")
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack(spacing: 0) {
                    if viewModel.isError {
                        errorView
                    } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack {
                                ForEach(viewModel.messages) { msg in
                                    ChatBubbleView(viewModel: viewModel, message: msg)
                                        .id(msg.id)
                                        .padding(.top, 5)
                                }
                                
                                if viewModel.isTyping {
                                    TypingMessageView(viewModel: viewModel)
                                        .padding(.bottom, 5)
                                        .id("typing")
                                }
                                
                            }
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            if let last = viewModel.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: viewModel.isTyping) { isTyping in
                            if isTyping {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                    
                    Divider()
                    
                    QuickActionsView(viewModel: viewModel) { selected in
                        viewModel.handleQuickAction(selected)
                    }
                    
                    Divider()
                    
                    ChatInputView(
                        text: $viewModel.inputText,
                        onSend: viewModel.sendMessage
                    )
                }
            }
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .renderingMode(.original)
                        }
                    }
                    
                    // Center title
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 6) {
                            Text("McDonald's")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#D7262B"))
                        }
                    }
                    // Right side icons
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        
                        Button(action: {
                            print("Cart tapped")
                        }) {
                            Image(systemName: "cart")
                        }
                        
                        Button(action: {
                            print("Profile tapped")
                        }) {
                            Image(systemName: "person")
                        }
                    }
                }
                .toolbarBackground(Color.clear, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    /// error view
    var errorView: some View {
        VStack() {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("something went wrong, please try again later")
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
      }
    }
}

#Preview {
    OrderChatView()
}
