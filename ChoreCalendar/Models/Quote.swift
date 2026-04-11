import Foundation

struct Quote: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var vendorId: Int?
    var description: String
    var total: Double
    var labour: Double?
    var materials: Double?
    var other: Double?
    var status: String
    var receivedDate: String?
    var notes: String?
    var createdAt: String?
    var updatedAt: String?
    var vendorName: String?
    var vendorCategory: String?
}

enum QuoteStatus: String, CaseIterable, Sendable {
    case pending, accepted, rejected, archived

    var label: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }

    var color: String {
        switch self {
        case .pending: "orange"
        case .accepted: "green"
        case .rejected: "red"
        case .archived: "gray"
        }
    }
}

struct BudgetInfo: Codable, Sendable {
    let found: Bool
    let budgeted: Double
    let spent: Double
    let remaining: Double
    let categoryName: String?
}
