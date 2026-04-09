import Foundation
import Observation

@Observable
final class RecipeStore {

    // MARK: - State

    var recipes: [Recipe] = []
    var selectedRecipe: Recipe?
    var searchQuery = ""
    var isLoading = false
    var isLoadingDetail = false
    var error: String?

    // MARK: - Actions

    func loadRecipes(query: String? = nil) async {
        isLoading = true
        error = nil
        do {
            recipes = try await RecipesAPI.fetchRecipes(query: query)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadRecipeDetail(id: Int) async {
        isLoadingDetail = true
        do {
            selectedRecipe = try await RecipesAPI.fetchRecipeDetail(id: id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingDetail = false
    }
}
