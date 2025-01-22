import Foundation
import OpenAI

enum OpenAIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case invalidData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

class OpenAIClient {
    private let client: OpenAI
    
    init(apiKey: String) {
        self.client = OpenAI(apiToken: apiKey)
    }
    
//    // Non-streaming version
//    func sendMessage(_ messages: [Message], model: String = "gpt-4-turbo-preview") async throws -> String {
//        let chatMessages = messages.compactMap { message in
//            if let role = ChatQuery.ChatCompletionMessageParam.Role(rawValue: message.role.rawValue) {
//                return ChatQuery.ChatCompletionMessageParam(
//                    role: role,
//                    content: String(message.content)
//                )
//            }
//            return nil
//        }
//        
//        let query = ChatQuery(
//            messages: chatMessages,
//            model: .gpt4_o
//        )
//        
//        do {
//            let result = try await client.chats(query: query)
//            guard let choice = result.choices.first,
//                  let content = choice.message.content else {
//                throw OpenAIError.invalidResponse
//            }
//            return content
//        } catch {
//            if let apiError = error as? OpenAIError {
//                throw apiError
//            }
//            throw OpenAIError.requestFailed(error)
//        }
//    }
    
    // Streaming version
    func streamMessage(_ messages: [Message], model: Model = .gpt4_o) -> AsyncThrowingStream<String, Error> {
        let chatMessages = messages.compactMap { message in
            if let role = ChatQuery.ChatCompletionMessageParam.Role(rawValue: message.role.rawValue) {
                return ChatQuery.ChatCompletionMessageParam(
                    role: role,
                    content: String(message.content)
                )
            }
            return nil
        }
        
        let query = ChatQuery(
            messages: chatMessages,
            model: model
        )
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await result in client.chatsStream(query: query) {
                        if let content = result.choices.first?.delta.content {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    if let apiError = error as? OpenAIError {
                        continuation.finish(throwing: apiError)
                    } else {
                        continuation.finish(throwing: OpenAIError.requestFailed(error))
                    }
                }
            }
        }
    }
}

// Chat completion models
struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
}

struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        let index: Int
        let message: ChatMessage
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// Error response model
struct APIErrorResponse: Codable {
    struct ErrorDetail: Codable {
        let message: String
        let type: String?
        let code: String?
    }
    let error: ErrorDetail
} 
