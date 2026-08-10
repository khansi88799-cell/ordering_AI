//
//  OrderChatView.swift
//  Arch
//
//  Created by saeed on 24/06/26.
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
                    .background(Color(hex: "#FAF9F6"))

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
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "#000000"))
                        }
                    }
                    
                    // Center title
                    ToolbarItem(placement: .principal) {
                        Image("myMcdLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 32)
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
