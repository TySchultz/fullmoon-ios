import Foundation
import SwiftUI

@Observable
class AssistantManager {
    private let client: OpenAIClient
    var isGenerating = false
    var currentOutput = ""
    var cancelled = false
    
    init(client: OpenAIClient) {
        self.client = client
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
            
            // Send to OpenAI
            let response = try await client.sendMessage(messages)
            
            if cancelled {
                return await MainActor.run { currentOutput }
            }
            
            await MainActor.run {
                currentOutput = response
            }
            return response
            
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


