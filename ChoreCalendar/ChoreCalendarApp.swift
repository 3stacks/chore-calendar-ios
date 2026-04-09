import SwiftUI

@main
struct ChoreCalendarApp: App {
    @State private var shoppingStore = ShoppingStore()
    @State private var mealPlanStore = MealPlanStore()
    @State private var recipeStore = RecipeStore()
    @State private var userStore = UserStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                ShoppingTab()
                    .tabItem {
                        Label("Shopping", systemImage: "cart")
                    }

                MealsTab()
                    .tabItem {
                        Label("Meals", systemImage: "fork.knife")
                    }
            }
            .environment(shoppingStore)
            .environment(mealPlanStore)
            .environment(recipeStore)
            .environment(userStore)
        }
    }
}
