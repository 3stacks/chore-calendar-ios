import Foundation
import Observation

@Observable
final class ApplianceStore {

    // MARK: - State

    var appliances: [Appliance] = []
    var currentDetail: ApplianceDetail?
    var isLoading = false
    var isLoadingDetail = false
    var error: String?
    var searchQuery = ""

    var filteredAppliances: [Appliance] {
        guard !searchQuery.isEmpty else { return appliances }
        let query = searchQuery.lowercased()
        return appliances.filter {
            $0.name.lowercased().contains(query) ||
            ($0.brand?.lowercased().contains(query) ?? false) ||
            ($0.model?.lowercased().contains(query) ?? false)
        }
    }

    var locations: [String] {
        Array(Set(appliances.compactMap(\.location))).sorted()
    }

    // MARK: - Actions

    func loadAppliances() async {
        isLoading = true
        error = nil
        do {
            appliances = try await AppliancesAPI.fetchAppliances()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadDetail(id: Int) async {
        isLoadingDetail = true
        error = nil
        do {
            currentDetail = try await AppliancesAPI.fetchApplianceDetail(id: id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingDetail = false
    }

    func createAppliance(body: [String: Any]) async -> Int? {
        error = nil
        do {
            let id = try await AppliancesAPI.createAppliance(body: body)
            await loadAppliances()
            return id
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func updateAppliance(id: Int, body: [String: Any]) async -> Bool {
        error = nil
        do {
            try await AppliancesAPI.updateAppliance(id: id, body: body)
            await loadAppliances()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func deleteAppliance(id: Int) async {
        error = nil
        appliances.removeAll { $0.id == id }
        do {
            try await AppliancesAPI.deleteAppliance(id: id)
        } catch {
            self.error = error.localizedDescription
            await loadAppliances()
        }
    }
}
