import Foundation

struct ShoppingList: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var name: String
    var color: String?
    var sortOrder: Int?
    var createdAt: String?
    var updatedAt: String?
    var itemCount: Int?
    var checkedCount: Int?
}

struct ShoppingItem: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var listId: Int
    var name: String
    var quantity: String?
    var checked: Bool?
    var sortOrder: Int?
    var addedBy: Int?
    var createdAt: String?

    var isChecked: Bool { checked ?? false }
}

struct ShoppingListDetail: Codable, Identifiable, Sendable {
    let id: Int
    var name: String
    var color: String?
    var sortOrder: Int?
    var createdAt: String?
    var updatedAt: String?
    var items: [ShoppingItem]
}
