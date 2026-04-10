import SwiftUI

@main
struct ChoreCalendarApp: App {
    @State private var shoppingStore = ShoppingStore()
    @State private var mealPlanStore = MealPlanStore()
    @State private var recipeStore = RecipeStore()
    @State private var userStore = UserStore()
    @State private var taskStore = TaskStore()
    @State private var applianceStore = ApplianceStore()
    @State private var vendorStore = VendorStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                TasksTab()
                    .tabItem {
                        Label("Chores", systemImage: "checklist")
                    }

                MealsTab()
                    .tabItem {
                        Label("Meals", systemImage: "fork.knife")
                    }

                ShoppingTab()
                    .tabItem {
                        Label("Shopping", systemImage: "cart")
                    }

                RecipesTab()
                    .tabItem {
                        Label("Recipes", systemImage: "book")
                    }

                AppliancesTab()
                    .tabItem {
                        Label("Appliances", systemImage: "washer")
                    }

                VendorsTab()
                    .tabItem {
                        Label("Vendors", systemImage: "person.crop.rectangle.stack")
                    }

                SettingsTab()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .environment(shoppingStore)
            .environment(mealPlanStore)
            .environment(recipeStore)
            .environment(userStore)
            .environment(taskStore)
            .environment(applianceStore)
            .environment(vendorStore)
        }
    }
}
