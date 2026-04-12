import SwiftUI

struct RecipesTab: View {
    @State private var recipeStore = RecipeStore()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            RecipeListView(store: recipeStore)
                .navigationTitle("Recipes")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingCreateSheet) {
                    RecipeFormSheet(store: recipeStore, isPresented: $showingCreateSheet)
                }
        }
    }
}

#Preview {
    RecipesTab()
}
