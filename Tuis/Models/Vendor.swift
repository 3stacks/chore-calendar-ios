import Foundation

struct Vendor: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var name: String
    var category: String?
    var phone: String?
    var email: String?
    var website: String?
    var notes: String?
    var rating: Int?
    var createdAt: String?
    var updatedAt: String?
}

struct VendorDetail: Codable, Sendable {
    let id: Int
    var name: String
    var category: String?
    var phone: String?
    var email: String?
    var website: String?
    var notes: String?
    var rating: Int?
    var createdAt: String?
    var updatedAt: String?
    var jobHistory: [JobRecord]?
}

struct JobRecord: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var taskId: Int
    var taskName: String
    var completedAt: String
    var cost: String?
}

enum VendorCategory: String, CaseIterable, Sendable {
    case plumber = "Plumber"
    case electrician = "Electrician"
    case hvac = "HVAC"
    case applianceRepair = "Appliance Repair"
    case landscaping = "Landscaping"
    case cleaning = "Cleaning"
    case general = "General"
    case other = "Other"
}
