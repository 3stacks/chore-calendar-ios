import SwiftUI

struct RecipeListView: View {
    @Bindable var store: RecipeStore

    @State private var searchText = ""

    var body: some View {
        Group {
            if store.recipes.isEmpty && !store.isLoading {
                EmptyStateView(
                    icon: "book",
                    title: "No recipes yet",
                    subtitle: "Add recipes to build your collection"
                )
            } else {
                List {
                    ForEach(store.recipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeRow(recipe: recipe)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await store.deleteRecipe(id: recipe.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes")
        .onChange(of: searchText) { _, newValue in
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                await store.loadRecipes(query: newValue.isEmpty ? nil : newValue)
            }
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeManageView(store: store, recipeId: recipe.id)
        }
        .refreshable {
            await store.loadRecipes()
        }
        .task {
            if store.recipes.isEmpty {
                await store.loadRecipes()
            }
        }
    }
}

// MARK: - Recipe Row

private struct RecipeRow: View {
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
                if let total = recipe.totalTime {
                    Label("\(total)m", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let servings = recipe.servings {
                    Label("\(servings) servings", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Recipe Manage View (Detail + Edit + Delete)

struct RecipeManageView: View {
    @Bindable var store: RecipeStore
    let recipeId: Int

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let recipe = store.selectedRecipe {
                RecipeDetailView(recipe: recipe)
            } else if store.isLoadingDetail {
                ProgressView()
            } else {
                EmptyStateView(icon: "book", title: "Recipe not found")
            }
        }
        .toolbar {
            if store.selectedRecipe != nil {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let recipe = store.selectedRecipe {
                RecipeFormSheet(store: store, isPresented: $showEditSheet, editingRecipe: recipe)
            }
        }
        .alert("Delete Recipe?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await store.deleteRecipe(id: recipeId)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this recipe.")
        }
        .task {
            await store.loadRecipeDetail(id: recipeId)
        }
    }
}
