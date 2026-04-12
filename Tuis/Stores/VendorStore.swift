import Foundation
import Observation

@Observable
final class VendorStore {

    // MARK: - State

    var vendors: [Vendor] = []
    var currentDetail: VendorDetail?
    var isLoading = false
    var isLoadingDetail = false
    var error: String?
    var searchQuery = ""
    var filterCategory: String?

    var filteredVendors: [Vendor] {
        var result = vendors

        if let category = filterCategory, !category.isEmpty {
            result = result.filter { $0.category == category }
        }

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                ($0.notes?.lowercased().contains(query) ?? false)
            }
        }

        return result
    }

    // MARK: - Actions

    func loadVendors() async {
        isLoading = true
        error = nil
        do {
            vendors = try await VendorsAPI.fetchVendors()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadDetail(id: Int) async {
        isLoadingDetail = true
        error = nil
        do {
            currentDetail = try await VendorsAPI.fetchVendorDetail(id: id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingDetail = false
    }

    func createVendor(body: [String: Any]) async -> Int? {
        error = nil
        do {
            let id = try await VendorsAPI.createVendor(body: body)
            await loadVendors()
            return id
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func updateVendor(id: Int, body: [String: Any]) async -> Bool {
        error = nil
        do {
            try await VendorsAPI.updateVendor(id: id, body: body)
            await loadVendors()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func deleteVendor(id: Int) async {
        error = nil
        vendors.removeAll { $0.id == id }
        do {
            try await VendorsAPI.deleteVendor(id: id)
        } catch {
            self.error = error.localizedDescription
            await loadVendors()
        }
    }
}
