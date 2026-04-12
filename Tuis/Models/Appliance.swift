import Foundation

struct Appliance: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var name: String
    var location: String?
    var brand: String?
    var model: String?
    var purchaseDate: String?
    var warrantyExpiry: String?
    var manualUrl: String?
    var warrantyDocUrl: String?
    var notes: String?
    var createdAt: String?
    var updatedAt: String?

    var isWarrantyActive: Bool {
        guard let expiryString = warrantyExpiry,
              let expiry = Self.dateFormatter.date(from: expiryString) else {
            return false
        }
        return expiry > Date()
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

struct ApplianceDetail: Codable, Sendable {
    let id: Int
    var name: String
    var location: String?
    var brand: String?
    var model: String?
    var purchaseDate: String?
    var warrantyExpiry: String?
    var manualUrl: String?
    var warrantyDocUrl: String?
    var notes: String?
    var createdAt: String?
    var updatedAt: String?
    var tasks: [ChoreTask]?
    var serviceHistory: [ServiceRecord]?
}

struct ServiceRecord: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var taskId: Int
    var taskName: String
    var completedAt: String
    var vendorId: Int?
    var cost: String?
}
