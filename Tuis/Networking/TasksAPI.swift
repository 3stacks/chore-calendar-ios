import Foundation

enum TasksAPI {

    static func fetchTasks() async throws -> [ChoreTask] {
        try await APIClient.get(path: "/api/tasks")
    }

    static func fetchTask(id: Int) async throws -> ChoreTask {
        try await APIClient.get(path: "/api/tasks/\(id)")
    }

    static func createTask(body: [String: Any]) async throws -> Int {
        let response: CreateResponse = try await APIClient.post(
            path: "/api/tasks",
            body: DictionaryBody(values: body)
        )
        return response.id
    }

    static func updateTask(id: Int, body: [String: Any]) async throws {
        try await APIClient.put(path: "/api/tasks/\(id)", body: DictionaryBody(values: body))
    }

    static func deleteTask(id: Int) async throws {
        try await APIClient.delete(path: "/api/tasks/\(id)")
    }

    static func completeTask(id: Int, completedBy: Int? = nil) async throws {
        var body: [String: Any] = [:]
        if let completedBy { body["completedBy"] = completedBy }
        let _: SuccessResponse = try await APIClient.post(
            path: "/api/tasks/\(id)/complete",
            body: DictionaryBody(values: body)
        )
    }

    static func snoozeTask(id: Int, duration: String) async throws {
        let body: [String: Any] = ["duration": duration]
        let _: SuccessResponse = try await APIClient.post(
            path: "/api/tasks/\(id)/snooze",
            body: DictionaryBody(values: body)
        )
    }
}

// MARK: - Response Types

private struct CreateResponse: Decodable {
    let id: Int
}

private struct SuccessResponse: Decodable {
    let success: Bool
}
