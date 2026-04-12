import Foundation
import Observation

@Observable
final class MealPlanStore {

    // MARK: - State

    var entries: [String: MealPlanEntry] = [:]
    var weekStart: Date = DateHelpers.startOfWeek(containing: Date())
    var isLoading = false
    var error: String?

    // MARK: - Computed

    var weekDates: [Date] { DateHelpers.datesInWeek(startingFrom: weekStart) }

    var isCurrentWeek: Bool {
        DateHelpers.startOfWeek(containing: Date()) == weekStart
    }

    var weekLabel: String {
        guard let last = weekDates.last else { return "" }
        return DateHelpers.weekRangeString(start: weekStart, end: last)
    }

    var weekStartString: String { DateHelpers.dateString(from: weekStart) }

    var weekEndString: String {
        guard let last = weekDates.last else { return weekStartString }
        return DateHelpers.dateString(from: last)
    }

    func entry(for date: Date) -> MealPlanEntry? {
        entries[DateHelpers.dateString(from: date)]
    }

    // MARK: - Actions

    func loadCurrentWeek() async {
        isLoading = true
        error = nil
        do {
            let meals = try await MealsAPI.fetchMeals(start: weekStartString, end: weekEndString)
            var map: [String: MealPlanEntry] = [:]
            for meal in meals {
                map[meal.date] = meal
            }
            entries = map
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func previousWeek() {
        guard let prev = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { return }
        weekStart = prev
    }

    func nextWeek() {
        guard let next = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { return }
        weekStart = next
    }

    func goToToday() {
        weekStart = DateHelpers.startOfWeek(containing: Date())
    }

    func upsertMeal(
        date: String,
        recipeId: Int? = nil,
        customMeal: String? = nil,
        notes: String? = nil,
        multiplier: Double = 1.0
    ) async {
        do {
            try await MealsAPI.upsertMeal(
                date: date,
                recipeId: recipeId,
                customMeal: customMeal,
                notes: notes,
                servingsMultiplier: multiplier
            )
            HapticManager.success()
            await loadCurrentWeek()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
    }

    func deleteMeal(date: String) async {
        do {
            try await MealsAPI.deleteMeal(date: date)
            entries.removeValue(forKey: date)
            HapticManager.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
    }
}
