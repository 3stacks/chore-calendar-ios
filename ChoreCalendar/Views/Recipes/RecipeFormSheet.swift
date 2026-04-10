import SwiftUI

struct RecipeFormSheet: View {
    @Bindable var store: RecipeStore
    @Binding var isPresented: Bool
    var editingRecipe: Recipe?

    @State private var name = ""
    @State private var description = ""
    @State private var instructions = ""
    @State private var prepTime = ""
    @State private var cookTime = ""
    @State private var servings = ""
    @State private var ingredients: [IngredientEntry] = []
    @State private var isSaving = false

    private var isEditing: Bool { editingRecipe != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    TextField("Recipe name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Timing & Servings") {
                    HStack {
                        TextField("Prep (min)", text: $prepTime)
                            .keyboardType(.numberPad)
                        TextField("Cook (min)", text: $cookTime)
                            .keyboardType(.numberPad)
                    }
                    TextField("Servings", text: $servings)
                        .keyboardType(.numberPad)
                }

                Section {
                    ForEach($ingredients) { $entry in
                        HStack {
                            TextField("Amount", text: $entry.amount)
                                .frame(width: 60)
                                .keyboardType(.decimalPad)
                            TextField("Unit", text: $entry.unit)
                                .frame(width: 50)
                            TextField("Ingredient name", text: $entry.name)
                        }
                    }
                    .onDelete { indices in
                        ingredients.remove(atOffsets: indices)
                    }

                    Button {
                        ingredients.append(IngredientEntry())
                    } label: {
                        Label("Add Ingredient", systemImage: "plus")
                    }
                } header: {
                    Text("Ingredients")
                }

                Section("Instructions") {
                    TextField("One step per line", text: $instructions, axis: .vertical)
                        .lineLimit(5...15)
                }
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let recipe = editingRecipe {
                    name = recipe.name
                    description = recipe.description ?? ""
                    instructions = recipe.instructions ?? ""
                    prepTime = recipe.prepTime.map(String.init) ?? ""
                    cookTime = recipe.cookTime.map(String.init) ?? ""
                    servings = recipe.servings.map(String.init) ?? ""
                    ingredients = recipe.ingredients?.map { ing in
                        IngredientEntry(
                            name: ing.name,
                            amount: ing.amount.map { String(format: "%g", $0) } ?? "",
                            unit: ing.unit ?? "",
                            section: ing.section ?? ""
                        )
                    } ?? []
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSaving = true

        var body: [String: Any] = ["name": trimmed]
        if !description.isEmpty { body["description"] = description }
        if !instructions.isEmpty { body["instructions"] = instructions }
        if let prep = Int(prepTime) { body["prepTime"] = prep }
        if let cook = Int(cookTime) { body["cookTime"] = cook }
        if let srv = Int(servings) { body["servings"] = srv }

        let ingredientDicts: [[String: Any]] = ingredients
            .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            .enumerated()
            .map { index, entry in
                var dict: [String: Any] = ["name": entry.name.trimmingCharacters(in: .whitespaces)]
                if let amt = Double(entry.amount) { dict["amount"] = amt }
                if !entry.unit.isEmpty { dict["unit"] = entry.unit }
                if !entry.section.isEmpty { dict["section"] = entry.section }
                dict["sortOrder"] = index
                return dict
            }
        if !ingredientDicts.isEmpty { body["ingredients"] = ingredientDicts }

        Task {
            if let recipe = editingRecipe {
                let success = await store.updateRecipe(id: recipe.id, body: body)
                isSaving = false
                if success {
                    HapticManager.success()
                    isPresented = false
                } else {
                    HapticManager.error()
                }
            } else {
                let result = await store.createRecipe(body: body)
                isSaving = false
                if result != nil {
                    HapticManager.success()
                    isPresented = false
                } else {
                    HapticManager.error()
                }
            }
        }
    }
}

// MARK: - Ingredient Entry

private struct IngredientEntry: Identifiable {
    let id = UUID()
    var name = ""
    var amount = ""
    var unit = ""
    var section = ""
}
