import Foundation
import Observation

@Observable
final class ShoppingStore {

    // MARK: - State

    var lists: [ShoppingList] = []
    var currentList: ShoppingListDetail?
    var suggestions: [String] = []
    var isLoadingLists = false
    var isLoadingDetail = false
    var error: String?

    // MARK: - Lists

    func loadLists() async {
        isLoadingLists = true
        error = nil
        do {
            lists = try await ShoppingAPI.fetchLists()
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingLists = false
    }

    func loadListDetail(id: Int) async {
        isLoadingDetail = true
        error = nil
        do {
            currentList = try await ShoppingAPI.fetchListDetail(id: id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingDetail = false
    }

    @discardableResult
    func createList(name: String, color: String) async -> Int? {
        error = nil
        do {
            let id = try await ShoppingAPI.createList(name: name, color: color)
            await loadLists()
            return id
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func deleteList(id: Int) async {
        error = nil
        lists.removeAll { $0.id == id }
        do {
            try await ShoppingAPI.deleteList(id: id)
        } catch {
            self.error = error.localizedDescription
            await loadLists()
        }
    }

    // MARK: - Items

    func addItem(name: String, quantity: String? = nil, addedBy: Int? = nil) async {
        guard let list = currentList else { return }
        error = nil

        // Optimistic: insert a temporary item at the top
        let tempId = -(Int.random(in: 1...999_999))
        let tempItem = ShoppingItem(
            id: tempId,
            listId: list.id,
            name: name,
            quantity: quantity,
            checked: false,
            sortOrder: 0,
            addedBy: addedBy,
            createdAt: nil
        )
        currentList?.items.insert(tempItem, at: 0)

        do {
            let realId = try await ShoppingAPI.createItem(
                listId: list.id,
                name: name,
                quantity: quantity,
                addedBy: addedBy
            )
            // Replace temp item with real id
            if let idx = currentList?.items.firstIndex(where: { $0.id == tempId }) {
                currentList?.items[idx] = ShoppingItem(
                    id: realId,
                    listId: list.id,
                    name: name,
                    quantity: quantity,
                    checked: false,
                    sortOrder: 0,
                    addedBy: addedBy,
                    createdAt: nil
                )
            }
            // Update list item counts
            if let listIdx = lists.firstIndex(where: { $0.id == list.id }) {
                lists[listIdx].itemCount = (lists[listIdx].itemCount ?? 0) + 1
            }
        } catch {
            // Remove temp item on failure
            currentList?.items.removeAll { $0.id == tempId }
            self.error = error.localizedDescription
        }
    }

    func toggleItem(_ item: ShoppingItem) {
        guard let listIdx = currentList?.items.firstIndex(where: { $0.id == item.id }) else { return }

        let newChecked = !item.isChecked

        // Optimistic toggle
        currentList?.items[listIdx].checked = newChecked

        Task {
            do {
                try await ShoppingAPI.updateItem(id: item.id, body: ["checked": newChecked])
                // Update parent list counts
                if let list = currentList,
                   let parentIdx = lists.firstIndex(where: { $0.id == list.id }) {
                    let checkedCount = list.items.filter(\.isChecked).count
                    lists[parentIdx].checkedCount = checkedCount
                }
            } catch {
                // Revert on failure
                if let idx = currentList?.items.firstIndex(where: { $0.id == item.id }) {
                    currentList?.items[idx].checked = !newChecked
                }
                self.error = error.localizedDescription
            }
        }
    }

    func deleteItem(id: Int) async {
        let removed = currentList?.items.first { $0.id == id }
        currentList?.items.removeAll { $0.id == id }

        do {
            try await ShoppingAPI.deleteItem(id: id)
            if let list = currentList,
               let parentIdx = lists.firstIndex(where: { $0.id == list.id }) {
                lists[parentIdx].itemCount = (lists[parentIdx].itemCount ?? 1) - 1
                if removed?.isChecked == true {
                    lists[parentIdx].checkedCount = (lists[parentIdx].checkedCount ?? 1) - 1
                }
            }
        } catch {
            if let removed {
                currentList?.items.append(removed)
            }
            self.error = error.localizedDescription
        }
    }

    func clearChecked() async {
        guard let list = currentList else { return }
        let checkedItems = list.items.filter(\.isChecked)
        currentList?.items.removeAll(where: \.isChecked)

        do {
            _ = try await ShoppingAPI.clearChecked(listId: list.id)
            if let parentIdx = lists.firstIndex(where: { $0.id == list.id }) {
                lists[parentIdx].checkedCount = 0
                lists[parentIdx].itemCount = (lists[parentIdx].itemCount ?? checkedItems.count) - checkedItems.count
            }
        } catch {
            currentList?.items.append(contentsOf: checkedItems)
            self.error = error.localizedDescription
        }
    }

    // MARK: - Suggestions

    private var suggestionTask: Task<Void, Never>?

    func updateSuggestions(query: String) {
        suggestionTask?.cancel()

        guard query.count >= 2 else {
            suggestions = []
            return
        }

        suggestionTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                let results = try await ShoppingAPI.fetchSuggestions(query: query)
                guard !Task.isCancelled else { return }
                suggestions = results
            } catch {
                if !Task.isCancelled {
                    suggestions = []
                }
            }
        }
    }

    func clearSuggestions() {
        suggestionTask?.cancel()
        suggestions = []
    }
}
