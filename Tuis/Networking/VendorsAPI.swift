import Foundation

enum VendorsAPI {

    static func fetchVendors(search: String? = nil, category: String? = nil) async throws -> [Vendor] {
        var queryItems: [URLQueryItem] = []
        if let search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        return try await APIClient.get(
            path: "/api/vendors",
            queryItems: queryItems.isEmpty ? nil : queryItems
        )
    }

    static func fetchVendorDetail(id: Int) async throws -> VendorDetail {
        try await APIClient.get(path: "/api/vendors/\(id)")
    }

    static func createVendor(body: [String: Any]) async throws -> Int {
        let response: CreateResponse = try await APIClient.post(
            path: "/api/vendors",
            body: DictionaryBody(values: body)
        )
        return response.id
    }

    static func updateVendor(id: Int, body: [String: Any]) async throws {
        try await APIClient.put(path: "/api/vendors/\(id)", body: DictionaryBody(values: body))
    }

    static func deleteVendor(id: Int) async throws {
        try await APIClient.delete(path: "/api/vendors/\(id)")
    }
}

private struct CreateResponse: Decodable {
    let id: Int
}
