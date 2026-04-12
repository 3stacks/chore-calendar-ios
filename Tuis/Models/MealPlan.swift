import Foundation

struct MealPlanEntry: Codable, Identifiable, Sendable {
    let id: Int
    var date: String
    var recipeId: Int?
    var servingsMultiplier: Double?
    var customMeal: String?
    var notes: String?
    var createdAt: String?
    var recipeName: String?
    var recipePrepTime: Int?
    var recipeCookTime: Int?
    var recipeImageUrl: String?

    var displayName: String { recipeName ?? customMeal ?? "" }
    var totalTime: Int? {
        guard let p = recipePrepTime, let c = recipeCookTime else { return nil }
        return p + c
    }
}

struct MealDetail: Codable, Sendable {
    let id: Int
    var date: String
    var recipeId: Int?
    var servingsMultiplier: Double?
    var customMeal: String?
    var notes: String?
    var recipe: Recipe?
}

struct AggregatedIngredientsResponse: Codable, Sendable {
    var ingredients: [AggregatedIngredient]
    var onList: [String]
}

struct AggregatedIngredient: Codable, Identifiable, Sendable {
    var name: String
    var amount: Double?
    var unit: String?
    var displayQuantity: String
    var id: String { name }
}
