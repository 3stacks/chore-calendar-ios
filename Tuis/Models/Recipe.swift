import Foundation

struct Recipe: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var name: String
    var description: String?
    var instructions: String?
    var prepTime: Int?
    var cookTime: Int?
    var servings: Int?
    var imageUrl: String?
    var createdAt: String?
    var updatedAt: String?
    var ingredients: [RecipeIngredient]?

    var totalTime: Int? {
        guard let p = prepTime, let c = cookTime else { return nil }
        return p + c
    }
}

struct RecipeIngredient: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var recipeId: Int
    var name: String
    var quantity: String?
    var amount: Double?
    var unit: String?
    var section: String?
    var sortOrder: Int?
}
