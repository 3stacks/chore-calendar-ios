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
}
