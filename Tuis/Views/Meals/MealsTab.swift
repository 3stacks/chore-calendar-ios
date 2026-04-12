import SwiftUI

struct MealsTab: View {
    @State private var mealStore = MealPlanStore()
    @State private var recipeStore = RecipeStore()
    @State private var showIngredients = false

    var body: some View {
        NavigationStack {
            WeekView(mealStore: mealStore, recipeStore: recipeStore)
                .navigationTitle("Meals")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showIngredients = true
                        } label: {
                            Label("Shopping List", systemImage: "cart")
                        }
                    }
                }
                .sheet(isPresented: $showIngredients) {
                    IngredientsListView(mealStore: mealStore)
                }
        }
    }
}

#Preview {
    MealsTab()
}
