import SwiftUI

struct ShoppingListDetailView: View {
    @Bindable var store: ShoppingStore
    let listId: Int

    @State private var showClearAlert = false

    private var uncheckedItems: [ShoppingItem] {
        store.currentList?.items.filter { !$0.isChecked } ?? []
    }

    private var checkedItems: [ShoppingItem] {
        store.currentList?.items.filter(\.isChecked) ?? []
    }

    private var listColor: Color {
        guard let hex = store.currentList?.color else { return .blue }
        return Color(hex: hex)
    }

    var body: some View {
        VStack(spacing: 0) {
            AddItemView(store: store)
                .padding(.horizontal)
                .padding(.vertical, 8)

            if store.isLoadingDetail && store.currentList == nil {
                Spacer()
                ProgressView()
                Spacer()
            } else if store.currentList != nil {
                List {
                    if !uncheckedItems.isEmpty {
                        Section {
                            ForEach(uncheckedItems) { item in
                                ShoppingItemRow(item: item, accentColor: listColor) {
                                    store.toggleItem(item)
                                    HapticManager.selection()
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await store.deleteItem(id: item.id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text("Items (\(uncheckedItems.count))")
                        }
                    }

                    if !checkedItems.isEmpty {
                        Section {
                            ForEach(checkedItems) { item in
                                ShoppingItemRow(item: item, accentColor: listColor) {
                                    store.toggleItem(item)
                                    HapticManager.selection()
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await store.deleteItem(id: item.id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text("Completed (\(checkedItems.count))")
                        }
                    }

                    if uncheckedItems.isEmpty && checkedItems.isEmpty {
                        EmptyStateView(
                            icon: "cart.badge.plus",
                            title: "No items yet",
                            subtitle: "Use the field above to add items"
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.insetGrouped)
                .animation(.default, value: store.currentList?.items.map(\.id))
                .animation(.default, value: store.currentList?.items.map(\.isChecked))
            }
        }
        .navigationTitle(store.currentList?.name ?? "List")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showClearAlert = true
                } label: {
                    Label("Clear Checked", systemImage: "checkmark.circle.badge.xmark")
                }
                .disabled(checkedItems.isEmpty)
            }
        }
        .alert("Clear Checked Items?", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    await store.clearChecked()
                    HapticManager.success()
                }
            }
        } message: {
            Text("This will remove \(checkedItems.count) completed item\(checkedItems.count == 1 ? "" : "s").")
        }
        .refreshable {
            await store.loadListDetail(id: listId)
        }
        .task {
            await store.loadListDetail(id: listId)
        }
    }
}
