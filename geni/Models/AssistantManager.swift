import Foundation
import SwiftUI
import OpenAI

@Observable
class AssistantManager {
    private let client: OpenAIClient
    var isGenerating = false
    var currentOutput = ""
    var cancelled = false
    var currentModel: Model = .gpt4_o
    
    init(client: OpenAIClient) {
        self.client = client
    }
    
    func updateModel(_ model: Model) {
        currentModel = model
    }
    
    func generate(thread: Thread, prompt: String, assistantId: String) async throws -> String {
        await MainActor.run {
            isGenerating = true
            currentOutput = ""
            cancelled = false
        }
        
        defer {
            Task { @MainActor in
                isGenerating = false
            }
        }
        
        do {
            // Get all messages from the thread and add the new prompt
            var messages = thread.sortedMessages
            messages.append(Message(role: .user, content: prompt))
            
            // Use streaming response with current model
            let stream = client.streamMessage(messages, model: currentModel)
            var fullResponse = ""
            
            for try await chunk in stream {
                if cancelled {
                    return await MainActor.run { currentOutput }
                }
                
                fullResponse += chunk
                await MainActor.run {
                    currentOutput = fullResponse
                }
            }
            
            return fullResponse
            
        } catch {
            print("OpenAI error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func stop() {
        Task { @MainActor in
            cancelled = true
        }
    }
} 


