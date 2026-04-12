import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var selectedMultiplier: Double = 1.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.title.weight(.bold))

                    if let description = recipe.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        if let prep = recipe.prepTime {
                            timePill(label: "Prep", minutes: prep)
                        }
                        if let cook = recipe.cookTime {
                            timePill(label: "Cook", minutes: cook)
                        }
                        if let total = recipe.totalTime {
                            timePill(label: "Total", minutes: total)
                        }
                    }
                }

                Divider()

                // Scale selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scale")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([0.25, 0.5, 1.0, 1.25, 1.5, 2.0], id: \.self) { scale in
                                scaleChip(scale: scale)
                            }
                        }
                    }

                    if let servings = recipe.servings {
                        let scaled = Double(servings) * selectedMultiplier
                        let display = scaled == Double(Int(scaled)) ? "\(Int(scaled))" : String(format: "%.1f", scaled)
                        Text("\(display) servings")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.blue)
                            .contentTransition(.numericText())
                            .animation(.easeInOut, value: selectedMultiplier)
                    }
                }

                // Ingredients
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    Divider()
                    ingredientsList(ingredients: ingredients)
                }

                // Instructions
                if let instructions = recipe.instructions, !instructions.isEmpty {
                    Divider()
                    instructionsSection(instructions: instructions)
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Ingredients

    private func ingredientsList(ingredients: [RecipeIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)

            let sections = groupedIngredients(ingredients)
            ForEach(Array(sections.keys.sorted(by: { lhs, rhs in
                if lhs == nil { return true }
                if rhs == nil { return false }
                return (lhs ?? "") < (rhs ?? "")
            })), id: \.self) { section in
                if let sectionName = section, !sectionName.isEmpty {
                    Text(sectionName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                ForEach(sections[section] ?? [], id: \.id) { ingredient in
                    ingredientRow(ingredient)
                }
            }
        }
    }

    private func ingredientRow(_ ingredient: RecipeIngredient) -> some View {
        HStack(spacing: 8) {
            if let amount = ingredient.amount, let unitStr = ingredient.unit,
               let unit = IngredientUnit(rawValue: unitStr) {
                let scaled = IngredientFormatter.scaleAmount(
                    amount: amount,
                    unit: unit,
                    multiplier: selectedMultiplier
                )
                let display = IngredientFormatter.formatIngredient(
                    amount: scaled.amount,
                    unit: scaled.unit
                )
                Text(display)
                    .font(.body.weight(.medium))
                    .frame(minWidth: 60, alignment: .trailing)
                    .contentTransition(.numericText())
                    .animation(.easeInOut, value: selectedMultiplier)
            } else if let qty = ingredient.quantity, !qty.isEmpty {
                Text(qty)
                    .font(.body.weight(.medium))
                    .frame(minWidth: 60, alignment: .trailing)
            } else {
                Text("")
                    .frame(minWidth: 60, alignment: .trailing)
            }

            Text(ingredient.name)
                .font(.body)

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func groupedIngredients(_ ingredients: [RecipeIngredient]) -> [String?: [RecipeIngredient]] {
        Dictionary(grouping: ingredients.sorted(by: {
            ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0)
        }), by: { $0.section })
    }

    // MARK: - Instructions

    private func instructionsSection(instructions: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)

            let steps = instructions
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(.blue, in: Circle())

                    let cleanStep = step.replacingOccurrences(
                        of: #"^\d+[\.\)]\s*"#,
                        with: "",
                        options: .regularExpression
                    )
                    Text(cleanStep)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Components

    private func timePill(label: String, minutes: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(minutes)m")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
    }

    private func scaleChip(scale: Double) -> some View {
        Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedMultiplier = scale
            }
        } label: {
            Text(formatScale(scale))
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedMultiplier == scale ? Color.blue : Color(.systemGray5),
                    in: Capsule()
                )
                .foregroundStyle(selectedMultiplier == scale ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func formatScale(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return "\(Int(value))x"
        }
        return String(format: "%.2gx", value)
    }
}
