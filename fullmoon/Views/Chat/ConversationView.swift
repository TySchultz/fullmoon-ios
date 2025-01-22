//
//  ConversationView.swift
//  fullmoon
//
//  Created by Xavier on 16/12/2024.
//

import MarkdownUI
import SwiftUI

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            Markdown(message.content)
                .textSelection(.enabled)
                .if(message.role == .user) { view in
                    view
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(platformBackgroundColor)
                    .mask(RoundedRectangle(cornerRadius: 24))
                   
                }
                .padding(message.role == .user ? .leading : .trailing, 48)
            if message.role == .assistant { Spacer() }
        }
    }

    let platformBackgroundColor: Color = {
        return Color(UIColor.secondarySystemBackground)
    }()
}

struct ConversationView: View {
    @Environment(AssistantManager.self) var assistant
    @EnvironmentObject var appManager: AppManager
    let thread: Thread
    let generatingThreadID: UUID?

    @State private var scrollID: String?
    @State private var scrollInterrupted = false

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(thread.sortedMessages) { message in
                        MessageView(message: message)
                            .padding()
                            .id(message.id.uuidString)
                    }

                    if assistant.isGenerating {
                        if assistant.currentOutput.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                            .id("progress")
                        } else if thread.id == generatingThreadID {
                            MessageView(message: Message(role: .assistant, content: assistant.currentOutput + " 🌕"))
                                .padding()
                                .id("output")
                                .onAppear {
                                    scrollInterrupted = false
                                }
                        }
                    }

                    Rectangle()
                        .fill(.clear)
                        .frame(height: 1)
                        .id("bottom")
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: assistant.currentOutput) { _, _ in
                if !scrollInterrupted {
                    scrollView.scrollTo("bottom")
                }
                appManager.playHaptic()
            }
            .onChange(of: scrollID) { old, new in
                if assistant.isGenerating {
                    scrollInterrupted = true
                }
            }
        }
        .defaultScrollAnchor(.bottom)
        #if os(iOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
    }
}

