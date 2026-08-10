//
//  ChatAPIService.swift
//  Arch
//
//  Created by saeed on 4/08/26.
//  Copyright © 2026 McDonald's. All rights reserved.
//

import Foundation

enum ChatAPIError: LocalizedError {
    case invalidResponse
    case http(Int)
    case decodingFailed(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Received an invalid response from the server."
        case .http(let code): return "Server returned status code \(code)."
        case .decodingFailed: return "Failed to parse the server response."
        case .network(let error): return error.localizedDescription
        }
    }
}

final class ChatAPIService {

    static let shared = ChatAPIService()

    private let endpoint = URL(string: "https://mcd-chatbot-api-186503175274.asia-south1.run.app/api/chat")!
    private let session: URLSession
    private let userId: String

    init(session: URLSession = .shared, userId: String = "U001") {
        self.session = session
        self.userId = userId
    }

    func send(input: String, completion: @escaping (Result<ChatAPIResponse, ChatAPIError>) -> Void) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        do {
            request.httpBody = try JSONEncoder().encode(ChatAPIRequest(userId: userId, input: input))
        } catch {
            completion(.failure(.decodingFailed(error)))
            return
        }

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.network(error)))
                return
            }
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                completion(.failure(.http(http.statusCode)))
                return
            }
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(ChatAPIResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
}
