import Foundation

enum QuotesAPI {

    static func fetchQuotes(status: String? = nil) async throws -> [Quote] {
        var queryItems: [URLQueryItem] = []
        if let status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        return try await APIClient.get(
            path: "/api/quotes",
            queryItems: queryItems.isEmpty ? nil : queryItems
        )
    }

    static func fetchQuote(id: Int) async throws -> Quote {
        try await APIClient.get(path: "/api/quotes/\(id)")
    }

    static func createQuote(body: [String: Any]) async throws -> Int {
        let response: CreateResponse = try await APIClient.post(
            path: "/api/quotes",
            body: DictionaryBody(values: body)
        )
        return response.id
    }

    static func updateQuote(id: Int, body: [String: Any]) async throws {
        try await APIClient.put(path: "/api/quotes/\(id)", body: DictionaryBody(values: body))
    }

    static func deleteQuote(id: Int) async throws {
        try await APIClient.delete(path: "/api/quotes/\(id)")
    }

    static func fetchBudget() async throws -> BudgetInfo {
        try await APIClient.get(path: "/api/quotes/budget")
    }
}

private struct CreateResponse: Decodable {
    let id: Int
}
