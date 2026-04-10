import Foundation
import Observation

@Observable
final class UserStore {

    // MARK: - State

    var users: [User] = []
    var currentUser: User?
    var isLoading = false
    var error: String?

    // MARK: - Actions

    func loadUsers() async {
        isLoading = true
        error = nil
        do {
            let fetched: [User] = try await APIClient.get(path: "/api/users")
            users = fetched
            if currentUser == nil, let first = fetched.first {
                currentUser = first
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func createUser(name: String, color: String = "#3b82f6") async -> Int? {
        error = nil
        do {
            let body = ["name": name, "color": color]
            let response: CreateUserResponse = try await APIClient.post(path: "/api/users", body: body)
            await loadUsers()
            return response.id
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func updateUser(id: Int, name: String, color: String) async -> Bool {
        error = nil
        do {
            let body = ["name": name, "color": color]
            try await APIClient.put(path: "/api/users/\(id)", body: body)
            await loadUsers()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func deleteUser(id: Int) async {
        error = nil
        users.removeAll { $0.id == id }
        do {
            try await APIClient.delete(path: "/api/users/\(id)")
        } catch {
            self.error = error.localizedDescription
            await loadUsers()
        }
    }
}

private struct CreateUserResponse: Decodable {
    let id: Int
}
