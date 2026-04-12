import Foundation

enum AppliancesAPI {

    static func fetchAppliances(search: String? = nil, location: String? = nil) async throws -> [Appliance] {
        var queryItems: [URLQueryItem] = []
        if let search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        return try await APIClient.get(
            path: "/api/appliances",
            queryItems: queryItems.isEmpty ? nil : queryItems
        )
    }

    static func fetchApplianceDetail(id: Int) async throws -> ApplianceDetail {
        try await APIClient.get(path: "/api/appliances/\(id)")
    }

    static func createAppliance(body: [String: Any]) async throws -> Int {
        let response: CreateResponse = try await APIClient.post(
            path: "/api/appliances",
            body: DictionaryBody(values: body)
        )
        return response.id
    }

    static func updateAppliance(id: Int, body: [String: Any]) async throws {
        try await APIClient.put(path: "/api/appliances/\(id)", body: DictionaryBody(values: body))
    }

    static func deleteAppliance(id: Int) async throws {
        try await APIClient.delete(path: "/api/appliances/\(id)")
    }
}

private struct CreateResponse: Decodable {
    let id: Int
}
