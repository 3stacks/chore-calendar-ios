import Foundation

enum RecipesAPI {

    static func fetchRecipes(query: String? = nil) async throws -> [Recipe] {
        var queryItems: [URLQueryItem]?
        if let query, !query.isEmpty {
            queryItems = [URLQueryItem(name: "q", value: query)]
        }
        return try await APIClient.get(path: "/api/recipes", queryItems: queryItems)
    }

    static func fetchRecipeDetail(id: Int) async throws -> Recipe {
        try await APIClient.get(path: "/api/recipes/\(id)")
    }

    static func createRecipe(body: [String: Any]) async throws -> Int {
        let response: CreateResponse = try await APIClient.post(
            path: "/api/recipes",
            body: DictionaryBody(values: body)
        )
        return response.id
    }

    static func updateRecipe(id: Int, body: [String: Any]) async throws {
        try await APIClient.put(path: "/api/recipes/\(id)", body: DictionaryBody(values: body))
    }

    static func deleteRecipe(id: Int) async throws {
        try await APIClient.delete(path: "/api/recipes/\(id)")
    }
}

private struct CreateResponse: Decodable {
    let id: Int
}
