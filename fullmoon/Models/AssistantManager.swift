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
    
    func createOpenAIThread() async throws -> String {
        let thread = try await client.createThread()
        return thread.id
    }
    
    func generate(thread: Thread, prompt: String, assistantId: String) async throws -> String {
        guard !assistantId.isEmpty else {
            throw OpenAIError.noAssistantID
        }
        
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
            // Create OpenAI thread if needed
            if thread.openAIThreadId == nil {
                thread.openAIThreadId = try await createOpenAIThread()
            }
            
            guard let openAIThreadId = thread.openAIThreadId else {
                throw OpenAIError.invalidResponse
            }
            
            // Add message to thread
            _ = try await client.addMessage(threadId: openAIThreadId, content: prompt)
            
            // Run the assistant
            let run = try await client.runAssistant(threadId: openAIThreadId, assistantId: assistantId)
            
            // Poll for completion
            var runStatus = run
            while runStatus.status != "completed" && !cancelled {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                runStatus = try await client.getRun(threadId: openAIThreadId, runId: run.id)
                
                if runStatus.status == "failed" {
                    throw OpenAIError.apiError("Assistant run failed")
                }
            }
            
            if cancelled {
                return await MainActor.run { currentOutput }
            }
            
            // Get messages
            let messages = try await client.getMessages(threadId: openAIThreadId)
            
            // Get the assistant's response (latest message)
            guard let response = messages.data.first,
                  let content = response.content.first?.text.value else {
                throw OpenAIError.invalidResponse
            }
            
            await MainActor.run {
                currentOutput = content
            }
            return content
            
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


