import SwiftUI

struct RecipePickerView: View {
    let date: Date
    @Bindable var recipeStore: RecipeStore
    let onSelect: (_ recipeId: Int, _ multiplier: Double) -> Void
    let onCustomMeal: (_ name: String, _ notes: String?) -> Void
    let onDismiss: () -> Void

    enum Mode {
        case recipeList
        case confirm(Recipe)
        case customMeal
    }

    @State private var mode: Mode = .recipeList
    @State private var searchText = ""
    @State private var selectedMultiplier: Double = 1.0

    // Custom meal fields
    @State private var customName = ""
    @State private var customNotes = ""

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.locale = Locale(identifier: "en_AU")
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .recipeList:
                    recipeListView
                case .confirm(let recipe):
                    confirmView(recipe: recipe)
                case .customMeal:
                    customMealView
                }
            }
            .navigationTitle("Add Meal for \(dateTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .task {
            await recipeStore.loadRecipes()
        }
    }

    // MARK: - Mode 1: Recipe List

    private var recipeListView: some View {
        List {
            Section {
                Button {
                    withAnimation { mode = .customMeal }
                } label: {
                    Label("Quick Entry", systemImage: "pencil.line")
                }
            }

            Section {
                if recipeStore.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if filteredRecipes.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(filteredRecipes) { recipe in
                        Button {
                            selectedMultiplier = 1.0
                            withAnimation { mode = .confirm(recipe) }
                        } label: {
                            RecipeRowView(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Recipes")
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes")
        .onChange(of: searchText) { _, newValue in
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                await recipeStore.loadRecipes(query: newValue.isEmpty ? nil : newValue)
            }
        }
    }

    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipeStore.recipes
        }
        return recipeStore.recipes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Mode 2: Confirm with Scaling

    private func confirmView(recipe: Recipe) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Back button
                HStack {
                    Button {
                        withAnimation { mode = .recipeList }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back to recipes")
                        }
                        .font(.subheadline)
                    }
                    Spacer()
                }

                // Recipe card
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }

                    Text(recipe.name)
                        .font(.title2.weight(.bold))

                    if let description = recipe.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if let totalTime = recipe.totalTime {
                        Label("\(totalTime) min", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Scale selector
                VStack(spacing: 12) {
                    Text("Scale")
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { scale in
                            scaleButton(scale: scale)
                        }
                    }

                    if let servings = recipe.servings {
                        let scaled = Int(Double(servings) * selectedMultiplier)
                        Text("\(scaled) servings")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.blue)
                            .contentTransition(.numericText())
                            .animation(.easeInOut, value: selectedMultiplier)
                    }
                }

                // Add button
                Button {
                    HapticManager.medium()
                    onSelect(recipe.id, selectedMultiplier)
                } label: {
                    Text(addButtonLabel)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
    }

    private func scaleButton(scale: Double) -> some View {
        Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedMultiplier = scale
            }
        } label: {
            Text(formatScale(scale))
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    selectedMultiplier == scale ? Color.blue : Color(.systemGray5),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .foregroundStyle(selectedMultiplier == scale ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var addButtonLabel: String {
        if selectedMultiplier == 1.0 {
            return "Add to Plan"
        }
        return "Add to Plan (\(formatScale(selectedMultiplier)))"
    }

    // MARK: - Mode 3: Custom Meal

    private var customMealView: some View {
        Form {
            Section {
                Button {
                    withAnimation { mode = .recipeList }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back to recipes")
                    }
                    .font(.subheadline)
                }
            }

            Section("Meal Name") {
                TextField("e.g. Takeout pizza", text: $customName)
            }

            Section("Notes (Optional)") {
                TextField("Any notes...", text: $customNotes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button {
                    HapticManager.medium()
                    onCustomMeal(customName, customNotes.isEmpty ? nil : customNotes)
                } label: {
                    Text("Add to Plan")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Helpers

    private func formatScale(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return "\(Int(value))x"
        }
        return String(format: "%.1fx", value)
    }
}

// MARK: - Recipe Row

private struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.name)
                .font(.body.weight(.medium))

            if let description = recipe.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                if let totalTime = recipe.totalTime {
                    Label("\(totalTime) min", systemImage: "clock")
                }
                if let servings = recipe.servings {
                    Label("\(servings) serves", systemImage: "person.2")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
