//
//  QuoteService.swift
//  ABCD
//

import Foundation

enum QuoteServiceError: Error {
    case invalidResponse
    case emptyResponse
    case fallbackMissing
}

final class QuoteService {
    private let session: URLSession
    private let endpoint = URL(string: "https://zenquotes.io/api/random")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchQuote() async throws -> Quote {
        do {
            let (data, response) = try await session.data(from: endpoint)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw QuoteServiceError.invalidResponse
            }

            let decoded = try JSONDecoder().decode([ZenQuoteDTO].self, from: data)
            guard let first = decoded.first else {
                throw QuoteServiceError.emptyResponse
            }

            return Quote(content: first.q, author: first.a)
        } catch {
            return try loadFallbackQuote()
        }
    }

    private func loadFallbackQuote() throws -> Quote {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json") else {
            throw QuoteServiceError.fallbackMissing
        }

        let data = try Data(contentsOf: url)
        let fallbackQuotes = try JSONDecoder().decode([Quote].self, from: data)
        guard !fallbackQuotes.isEmpty else {
            throw QuoteServiceError.emptyResponse
        }

        return fallbackQuotes.randomElement() ?? fallbackQuotes[0]
    }
}
