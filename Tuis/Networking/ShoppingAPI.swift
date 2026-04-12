import Foundation

enum ShoppingAPI {

    static func fetchLists() async throws -> [ShoppingList] {
        try await APIClient.get(path: "/api/shopping/lists")
    }

    static func fetchListDetail(id: Int) async throws -> ShoppingListDetail {
        try await APIClient.get(path: "/api/shopping/lists/\(id)")
    }

    static func createList(name: String, color: String) async throws -> Int {
        let body = ["name": name, "color": color]
        let response: CreateResponse = try await APIClient.post(path: "/api/shopping/lists", body: body)
        return response.id
    }

    static func updateList(id: Int, body: [String: Any]) async throws {
        try await APIClient.put(path: "/api/shopping/lists/\(id)", body: DictionaryBody(values: body))
    }

    static func deleteList(id: Int) async throws {
        try await APIClient.delete(path: "/api/shopping/lists/\(id)")
    }

    static func createItem(
        listId: Int,
        name: String,
        quantity: String? = nil,
        addedBy: Int? = nil
    ) async throws -> Int {
        var dict: [String: Any] = ["listId": listId, "name": name]
        if let quantity { dict["quantity"] = quantity }
        if let addedBy { dict["addedBy"] = addedBy }
        let response: CreateResponse = try await APIClient.post(
            path: "/api/shopping/items",
            body: DictionaryBody(values: dict)
        )
        return response.id
    }

    static func updateItem(id: Int, body: [String: Any]) async throws {
        try await APIClient.put(path: "/api/shopping/items/\(id)", body: DictionaryBody(values: body))
    }

    static func deleteItem(id: Int) async throws {
        try await APIClient.delete(path: "/api/shopping/items/\(id)")
    }

    static func clearChecked(listId: Int) async throws -> Int {
        let body: [String: Any] = ["listId": listId]
        let response: ClearCheckedResponse = try await APIClient.post(
            path: "/api/shopping/items/clear",
            body: DictionaryBody(values: body)
        )
        return response.deleted
    }

    static func fetchSuggestions(query: String) async throws -> [String] {
        try await APIClient.get(
            path: "/api/shopping/suggestions",
            queryItems: [URLQueryItem(name: "q", value: query)]
        )
    }
}

// MARK: - Response Types

private struct CreateResponse: Decodable {
    let id: Int
}

private struct ClearCheckedResponse: Decodable {
    let deleted: Int
}
