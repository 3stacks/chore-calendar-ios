import SwiftUI

struct IngredientsListView: View {
    let mealStore: MealPlanStore

    @State private var response: AggregatedIngredientsResponse?
    @State private var isLoading = true
    @State private var error: String?
    @State private var addingToList = false
    @Environment(\.dismiss) private var dismiss

    private var onListSet: Set<String> {
        Set(response?.onList ?? [])
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading ingredients...")
                } else if let error {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if let ingredients = response?.ingredients, !ingredients.isEmpty {
                    ingredientsList(ingredients)
                } else {
                    ContentUnavailableView(
                        "No Ingredients",
                        systemImage: "cart",
                        description: Text("No meals planned for this week.")
                    )
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await loadIngredients()
        }
    }

    // MARK: - Ingredients List

    private func ingredientsList(_ ingredients: [AggregatedIngredient]) -> some View {
        List {
            Section {
                ForEach(ingredients) { ingredient in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ingredient.name)
                                .font(.body)
                            if !ingredient.displayQuantity.isEmpty {
                                Text(ingredient.displayQuantity)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if onListSet.contains(ingredient.name.lowercased()) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            } header: {
                Text("\(ingredients.count) ingredients for \(mealStore.weekLabel)")
            }

            let missingCount = ingredients.filter { !onListSet.contains($0.name.lowercased()) }.count
            if missingCount > 0 {
                Section {
                    Button {
                        Task { await addMissingToShoppingList(ingredients: ingredients) }
                    } label: {
                        HStack {
                            Spacer()
                            if addingToList {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Add \(missingCount) Missing to Shopping List")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(addingToList)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadIngredients() async {
        isLoading = true
        error = nil
        do {
            response = try await MealsAPI.fetchIngredients(
                start: mealStore.weekStartString,
                end: mealStore.weekEndString
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func addMissingToShoppingList(ingredients: [AggregatedIngredient]) async {
        addingToList = true
        do {
            // Get first shopping list or create one
            let lists = try await ShoppingAPI.fetchLists()
            let listId: Int
            if let first = lists.first {
                listId = first.id
            } else {
                listId = try await ShoppingAPI.createList(name: "Groceries", color: "#4CAF50")
            }

            // Add missing ingredients
            for ingredient in ingredients where !onListSet.contains(ingredient.name.lowercased()) {
                let qty = ingredient.displayQuantity.isEmpty ? nil : ingredient.displayQuantity
                _ = try await ShoppingAPI.createItem(listId: listId, name: ingredient.name, quantity: qty)
            }

            HapticManager.success()
            // Reload to update checkmarks
            await loadIngredients()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
        addingToList = false
    }
}
