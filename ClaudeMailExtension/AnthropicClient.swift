//
//  AnthropicClient.swift
//  ClaudeMailAssistant
//
//  Created by Jan Niklas Sikorra on 13.11.24.
//

import Foundation

class AnthropicClient {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(_ content: String) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "claude-3-opus-20240229",
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": content]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (json?["content"] as? String) ?? ""
    }
}
