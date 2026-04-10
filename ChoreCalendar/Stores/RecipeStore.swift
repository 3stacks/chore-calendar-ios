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

    func createRecipe(body: [String: Any]) async -> Int? {
        error = nil
        do {
            let id = try await RecipesAPI.createRecipe(body: body)
            await loadRecipes()
            return id
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func updateRecipe(id: Int, body: [String: Any]) async -> Bool {
        error = nil
        do {
            try await RecipesAPI.updateRecipe(id: id, body: body)
            await loadRecipes()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func deleteRecipe(id: Int) async {
        error = nil
        recipes.removeAll { $0.id == id }
        do {
            try await RecipesAPI.deleteRecipe(id: id)
        } catch {
            self.error = error.localizedDescription
            await loadRecipes()
        }
    }
}
