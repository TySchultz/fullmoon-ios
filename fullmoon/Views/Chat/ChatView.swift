//
//  ChatView.swift
//  fullmoon
//
//  Created by Jordan Singer on 12/3/24.
//

import MarkdownUI
import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(\.modelContext) var modelContext
    @Binding var currentThread: Thread?
    @Environment(AssistantManager.self) var assistant
    @Namespace var bottomID
    @State var showModelPicker = false
    @State var prompt = ""
    @FocusState.Binding var isPromptFocused: Bool
    @Binding var showChats: Bool
    @Binding var showSettings: Bool
    
    @State private var generatingThreadID: UUID?
    @State private var errorMessage: String?
    @State private var showError = false

    var isPromptEmpty: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    let platformBackgroundColor = Color(UIColor.secondarySystemBackground)

    var chatInput: some View {
        HStack(alignment: .bottom, spacing: 0) {
            TextField("message", text: $prompt, axis: .vertical)
                .focused($isPromptFocused)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 48)
                .onSubmit {
                    isPromptFocused = true
                    generate()
                }

            if assistant.isGenerating {
                stopButton
            } else {
                generateButton
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(platformBackgroundColor)
        )
    }

    var modelPickerButton: some View {
        Button {
            appManager.playHaptic()
            showModelPicker.toggle()
        } label: {
            Group {
                Image(systemName: "chevron.up")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16)
                    .tint(.primary)
            }
            .frame(width: 48, height: 48)
            .background(
                Circle()
                    .fill(platformBackgroundColor)
            )
        }
    }

    var generateButton: some View {
        Button {
            generate()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
        .disabled(isPromptEmpty)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }

    var stopButton: some View {
        Button {
            assistant.stop()
        } label: {
            Image(systemName: "stop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
        .disabled(assistant.cancelled)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }

    var chatTitle: String {
        if let currentThread = currentThread {
            if let firstMessage = currentThread.sortedMessages.first {
                return firstMessage.content
            }
        }

        return "chat"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let currentThread = currentThread {
                    ConversationView(thread: currentThread, generatingThreadID: generatingThreadID)
                } else {
                    Spacer()
                    Image(systemName: appManager.getMoonPhaseIcon())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.quaternary)
                    Spacer()
                }

                HStack(alignment: .bottom) {
                    modelPickerButton
                    chatInput
                }
                .padding()
            }
            .navigationTitle(chatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showModelPicker) {
                NavigationStack {
                    ModelsSettingsView()
                        .environment(assistant)
                }
                .presentationDragIndicator(.visible)
                .if(appManager.userInterfaceIdiom == .phone) { view in
                    view.presentationDetents([.fraction(0.4)])
                }
            }
            .toolbar {
                if appManager.userInterfaceIdiom == .phone {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            appManager.playHaptic()
                            showChats.toggle()
                        }) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
    }

    private func generate() {
        if !isPromptEmpty {
            if currentThread == nil {
                let newThread = Thread()
                currentThread = newThread
                modelContext.insert(newThread)
                try? modelContext.save()
            }
            
            if let currentThread = currentThread {
                Task { @MainActor in
                    generatingThreadID = currentThread.id
                    let message = prompt
                    prompt = ""
                    appManager.playHaptic()
                    sendMessage(Message(role: .user, content: message, thread: currentThread))
                    isPromptFocused = true
                    
                    do {
                        let output = try await assistant.generate(
                            thread: currentThread,
                            prompt: message,
                            assistantId: appManager.openAIAssistantId
                        )
                        sendMessage(Message(role: .assistant, content: output, thread: currentThread))
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                    
                    generatingThreadID = nil
                }
            }
        }
    }

    private func sendMessage(_ message: Message) {
        Task { @MainActor in
            appManager.playHaptic()
            modelContext.insert(message)
            try? modelContext.save()
        }
    }
}

#Preview {
    @FocusState var isPromptFocused: Bool
    ChatView(currentThread: .constant(nil), isPromptFocused: $isPromptFocused, showChats: .constant(false), showSettings: .constant(false))
}
