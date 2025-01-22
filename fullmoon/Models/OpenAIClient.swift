import Foundation

enum OpenAIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case invalidData
    case apiError(String)
    case noAssistantID
    
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
        case .noAssistantID:
            return "No Assistant ID configured"
        }
    }
}

class OpenAIClient {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    private func makeRequest<T: Codable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        // Handle error responses
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw OpenAIError.apiError(errorResponse.error.message)
            }
            throw OpenAIError.apiError("Status code: \(httpResponse.statusCode)")
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "none")")
            throw OpenAIError.invalidData
        }
    }
    
    // Create an assistant
    func createAssistant(name: String, model: String, instructions: String) async throws -> Assistant {
        let body = try JSONEncoder().encode([
            "name": name,
            "model": model,
            "instructions": instructions
        ])
        
        return try await makeRequest("/assistants", method: "POST", body: body)
    }
    
    // Create a thread
    func createThread() async throws -> OpenAIThread {
        return try await makeRequest("/threads", method: "POST")
    }
    
    // Add a message to a thread
    func addMessage(threadId: String, content: String) async throws -> OpenAIMessage {
        let body = try JSONEncoder().encode([
            "role": "user",
            "content": content
        ])
        
        return try await makeRequest("/threads/\(threadId)/messages", method: "POST", body: body)
    }
    
    // Run the assistant
    func runAssistant(threadId: String, assistantId: String) async throws -> Run {
        let body = try JSONEncoder().encode([
            "assistant_id": assistantId
        ])
        
        return try await makeRequest("/threads/\(threadId)/runs", method: "POST", body: body)
    }
    
    // Get run status
    func getRun(threadId: String, runId: String) async throws -> Run {
        return try await makeRequest("/threads/\(threadId)/runs/\(runId)")
    }
    
    // Get messages
    func getMessages(threadId: String) async throws -> MessageList {
        return try await makeRequest("/threads/\(threadId)/messages")
    }
}

// Response models
struct Assistant: Codable {
    let id: String
    let name: String
    let model: String
    let instructions: String
}

struct OpenAIThread: Codable {
    let id: String
}

struct OpenAIMessage: Codable {
    let id: String
    let role: String
    let content: [MessageContent]
}

struct MessageContent: Codable {
    let type: String
    let text: TextContent
}

struct TextContent: Codable {
    let value: String
}

struct MessageList: Codable {
    let data: [OpenAIMessage]
}

struct Run: Codable {
    let id: String
    let status: String
}

// Add error response model
struct APIErrorResponse: Codable {
    struct ErrorDetail: Codable {
        let message: String
        let type: String?
        let code: String?
    }
    let error: ErrorDetail
} 
