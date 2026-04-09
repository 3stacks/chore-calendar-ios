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
}
