import Foundation

struct ChoreTask: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var name: String
    var area: String
    var frequency: String
    var assignedDay: String?
    var season: String?
    var notes: String?
    var extendedNotes: String?
    var assignedTo: Int?
    var applianceId: Int?
    var lastCompleted: String?
    var nextDue: String?
    var createdAt: String?
    var updatedAt: String?

    var status: TaskStatus {
        guard frequency != "adhoc" else { return .adhoc }
        guard let dueString = nextDue,
              let dueDate = Self.dateFormatter.date(from: dueString) else {
            return .future
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)

        if due < today { return .overdue }
        if due == today { return .today }

        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today)!
        if due <= weekFromNow { return .upcoming }
        return .future
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

enum TaskStatus: String, CaseIterable, Sendable {
    case overdue, today, upcoming, future, adhoc

    var label: String {
        switch self {
        case .overdue: "Overdue"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .future: "Future"
        case .adhoc: "Ad-hoc"
        }
    }

    var color: String {
        switch self {
        case .overdue: "red"
        case .today: "blue"
        case .upcoming: "orange"
        case .future: "gray"
        case .adhoc: "purple"
        }
    }
}

enum TaskArea: String, CaseIterable, Sendable {
    case kitchen = "Kitchen"
    case bathroom = "Bathroom"
    case bedroom = "Bedroom"
    case livingRoom = "Living Room"
    case laundry = "Laundry"
    case outdoor = "Outdoor"
    case garden = "Garden"
    case garage = "Garage"
    case general = "General"
    case office = "Office"
}

enum TaskFrequency: String, CaseIterable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case biWeekly = "bi-weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case biAnnually = "bi-annually"
    case annual = "annual"
    case adhoc = "adhoc"

    var label: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .biWeekly: "Bi-weekly"
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .biAnnually: "Bi-annually"
        case .annual: "Annual"
        case .adhoc: "Ad-hoc"
        }
    }
}

enum SnoozeDuration: String, CaseIterable, Sendable {
    case oneDay = "1day"
    case threeDays = "3days"
    case oneWeek = "1week"
    case twoWeeks = "2weeks"

    var label: String {
        switch self {
        case .oneDay: "1 Day"
        case .threeDays: "3 Days"
        case .oneWeek: "1 Week"
        case .twoWeeks: "2 Weeks"
        }
    }
}
