import Foundation
import Observation

@Observable
final class QuoteStore {

    // MARK: - State

    var quotes: [Quote] = []
    var budget: BudgetInfo?
    var isLoading = false
    var error: String?
    var filterStatus: String?

    var filteredQuotes: [Quote] {
        guard let status = filterStatus, !status.isEmpty else { return quotes }
        return quotes.filter { $0.status == status }
    }

    var pendingTotal: Double {
        quotes.filter { $0.status == "pending" }.reduce(0) { $0 + $1.total }
    }

    // MARK: - Actions

    func loadQuotes() async {
        isLoading = true
        error = nil
        do {
            quotes = try await QuotesAPI.fetchQuotes()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadBudget() async {
        do {
            budget = try await QuotesAPI.fetchBudget()
        } catch {
            // Budget is optional — don't surface errors
        }
    }

    func createQuote(body: [String: Any]) async -> Int? {
        error = nil
        do {
            let id = try await QuotesAPI.createQuote(body: body)
            await loadQuotes()
            return id
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func updateQuote(id: Int, body: [String: Any]) async -> Bool {
        error = nil
        do {
            try await QuotesAPI.updateQuote(id: id, body: body)
            await loadQuotes()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func deleteQuote(id: Int) async {
        error = nil
        quotes.removeAll { $0.id == id }
        do {
            try await QuotesAPI.deleteQuote(id: id)
        } catch {
            self.error = error.localizedDescription
            await loadQuotes()
        }
    }

    func updateStatus(id: Int, status: String) async {
        error = nil
        do {
            try await QuotesAPI.updateQuote(id: id, body: ["status": status])
            HapticManager.success()
            await loadQuotes()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
    }
}
