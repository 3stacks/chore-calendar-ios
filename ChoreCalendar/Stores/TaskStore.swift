import Foundation
import Observation

@Observable
final class TaskStore {

    // MARK: - State

    var tasks: [ChoreTask] = []
    var isLoading = false
    var error: String?

    var filterArea: String?
    var filterFrequency: String?
    var searchQuery = ""

    var filteredTasks: [ChoreTask] {
        var result = tasks

        if let area = filterArea, !area.isEmpty {
            result = result.filter { $0.area == area }
        }

        if let frequency = filterFrequency, !frequency.isEmpty {
            result = result.filter { $0.frequency == frequency }
        }

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }

        return result
    }

    var tasksByStatus: [(status: TaskStatus, tasks: [ChoreTask])] {
        let grouped = Dictionary(grouping: filteredTasks, by: \.status)
        return TaskStatus.allCases.compactMap { status in
            guard let items = grouped[status], !items.isEmpty else { return nil }
            return (status, items)
        }
    }

    var areas: [String] {
        Array(Set(tasks.map(\.area))).sorted()
    }

    // MARK: - Actions

    func loadTasks() async {
        isLoading = true
        error = nil
        do {
            tasks = try await TasksAPI.fetchTasks()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func createTask(body: [String: Any]) async -> Int? {
        error = nil
        do {
            let id = try await TasksAPI.createTask(body: body)
            await loadTasks()
            return id
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func updateTask(id: Int, body: [String: Any]) async -> Bool {
        error = nil
        do {
            try await TasksAPI.updateTask(id: id, body: body)
            await loadTasks()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func deleteTask(id: Int) async {
        error = nil
        tasks.removeAll { $0.id == id }
        do {
            try await TasksAPI.deleteTask(id: id)
        } catch {
            self.error = error.localizedDescription
            await loadTasks()
        }
    }

    func completeTask(id: Int, completedBy: Int? = nil) async {
        error = nil
        do {
            try await TasksAPI.completeTask(id: id, completedBy: completedBy)
            HapticManager.success()
            await loadTasks()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
    }

    func snoozeTask(id: Int, duration: SnoozeDuration) async {
        error = nil
        do {
            try await TasksAPI.snoozeTask(id: id, duration: duration.rawValue)
            HapticManager.success()
            await loadTasks()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
    }
}
