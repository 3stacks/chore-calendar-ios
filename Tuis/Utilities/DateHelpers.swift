import Foundation

enum DateHelpers {

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: "en_AU")
        return f
    }()

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "en_AU")
        return f
    }()

    private static let displayDateYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = Locale(identifier: "en_AU")
        return f
    }()

    private static var mondayCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        cal.locale = Locale(identifier: "en_AU")
        return cal
    }()

    /// Returns the Monday of the week containing the given date.
    static func startOfWeek(containing date: Date) -> Date {
        let cal = mondayCalendar
        var start = date
        var interval: TimeInterval = 0
        _ = cal.dateInterval(of: .weekOfYear, start: &start, interval: &interval, for: date)
        return cal.startOfDay(for: start)
    }

    /// Returns 7 consecutive dates starting from the given date.
    static func datesInWeek(startingFrom start: Date) -> [Date] {
        let cal = mondayCalendar
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    /// Formats a date as "yyyy-MM-dd".
    static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Formats a date as a short day name, e.g. "Mon".
    static func displayDayString(from date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// Formats a date as "7 Apr".
    static func displayDateString(from date: Date) -> String {
        displayDateFormatter.string(from: date)
    }

    /// Formats a week range like "7 Apr - 13 Apr 2026".
    static func weekRangeString(start: Date, end: Date) -> String {
        let startStr = displayDateFormatter.string(from: start)
        let endStr = displayDateYearFormatter.string(from: end)
        return "\(startStr) - \(endStr)"
    }

    /// Returns true if the given date is today.
    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Parses a "yyyy-MM-dd" string into a Date.
    static func date(from string: String) -> Date? {
        dateFormatter.date(from: string)
    }
}
