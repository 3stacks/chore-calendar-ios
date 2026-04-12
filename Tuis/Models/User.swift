import Foundation

struct User: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var name: String
    var color: String
    var createdAt: String?
}
