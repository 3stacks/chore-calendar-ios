import Foundation

enum MealsAPI {

    static func fetchMeals(start: String, end: String) async throws -> [MealPlanEntry] {
        try await APIClient.get(
            path: "/api/meals",
            queryItems: [
                URLQueryItem(name: "start", value: start),
                URLQueryItem(name: "end", value: end),
            ]
        )
    }

    static func fetchMealDetail(date: String) async throws -> MealDetail? {
        do {
            return try await APIClient.get(path: "/api/meals/\(date)") as MealDetail
        } catch APIError.notFound {
            return nil
        }
    }

    static func upsertMeal(
        date: String,
        recipeId: Int? = nil,
        customMeal: String? = nil,
        notes: String? = nil,
        servingsMultiplier: Double? = nil
    ) async throws {
        var dict: [String: Any] = ["date": date]
        if let recipeId { dict["recipeId"] = recipeId }
        if let customMeal { dict["customMeal"] = customMeal }
        if let notes { dict["notes"] = notes }
        if let servingsMultiplier { dict["servingsMultiplier"] = servingsMultiplier }
        try await APIClient.put(path: "/api/meals/\(date)", body: DictionaryBody(values: dict))
    }

    static func deleteMeal(date: String) async throws {
        try await APIClient.delete(path: "/api/meals/\(date)")
    }

    static func fetchIngredients(start: String, end: String) async throws -> AggregatedIngredientsResponse {
        try await APIClient.get(
            path: "/api/meals/ingredients",
            queryItems: [
                URLQueryItem(name: "start", value: start),
                URLQueryItem(name: "end", value: end),
            ]
        )
    }
}
