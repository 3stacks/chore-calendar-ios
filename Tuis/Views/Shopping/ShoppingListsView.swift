import SwiftUI

struct ShoppingListsView: View {
    @Bindable var store: ShoppingStore

    var body: some View {
        Group {
            if store.lists.isEmpty && !store.isLoadingLists {
                EmptyStateView(
                    icon: "cart",
                    title: "No shopping lists yet",
                    subtitle: "Create a list to get started"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.lists) { list in
                            NavigationLink(value: list) {
                                ShoppingListCard(list: list)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await store.deleteList(id: list.id) }
                                } label: {
                                    Label("Delete List", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationDestination(for: ShoppingList.self) { list in
            ShoppingListDetailView(store: store, listId: list.id)
        }
        .refreshable {
            await store.loadLists()
        }
        .task {
            if store.lists.isEmpty {
                await store.loadLists()
            }
        }
    }
}

// MARK: - List Card

private struct ShoppingListCard: View {
    let list: ShoppingList

    private var listColor: Color {
        guard let hex = list.color else { return .blue }
        return Color(hex: hex)
    }

    private var totalCount: Int { list.itemCount ?? 0 }
    private var checkedCount: Int { list.checkedCount ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Color bar
            listColor
                .frame(height: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(list.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(checkedCount)/\(totalCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if totalCount > 0 {
                    ProgressView(value: Double(checkedCount), total: Double(totalCount))
                        .tint(listColor)
                }
            }
            .padding(12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
