import Foundation

enum APIClient {

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeoutInterval
        config.timeoutIntervalForResource = APIConfig.resourceTimeout
        return URLSession(configuration: config)
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    // MARK: - Public Methods

    static func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try buildRequest(method: "GET", path: path, queryItems: queryItems)
        return try await execute(request)
    }

    static func post<T: Decodable>(
        path: String,
        body: (any Encodable)? = nil
    ) async throws -> T {
        let request = try buildRequest(method: "POST", path: path, body: body)
        return try await execute(request)
    }

    static func put(
        path: String,
        body: (any Encodable)? = nil
    ) async throws {
        let request = try buildRequest(method: "PUT", path: path, body: body)
        try await executeVoid(request)
    }

    static func delete(path: String) async throws {
        let request = try buildRequest(method: "DELETE", path: path)
        try await executeVoid(request)
    }

    // MARK: - Internal

    private static func buildRequest(
        method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil
    ) throws -> URLRequest {
        let urlString = "\(APIConfig.baseURL)\(path)"
        guard var components = URLComponents(string: urlString) else {
            throw APIError.invalidURL
        }

        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private static func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private static func executeVoid(_ request: URLRequest) async throws {
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
    }

    private static func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
    }

    private static func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(
                NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            )
        }

        let statusCode = httpResponse.statusCode

        guard (200...299).contains(statusCode) else {
            if statusCode == 404 {
                throw APIError.notFound
            }

            let message = try? JSONDecoder().decode(ErrorResponse.self, from: data).error

            if statusCode >= 500 {
                throw APIError.serverError
            }

            throw APIError.httpError(statusCode: statusCode, message: message)
        }
    }
}

// MARK: - Helper Types

private struct ErrorResponse: Decodable {
    let error: String?
}

/// A wrapper for encoding raw dictionary bodies via JSONSerialization.
struct DictionaryBody: Encodable {
    let values: [String: Any]

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = try JSONSerialization.data(withJSONObject: values)
        let wrapper = try JSONDecoder().decode(AnyCodable.self, from: data)
        try container.encode(wrapper)
    }
}

/// Minimal type-erased Codable for dictionary serialization.
struct AnyCodable: Codable {
    let value: Any

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let dict as [String: Any]:
            let codableDict = dict.mapValues { AnyCodable(value: $0) }
            try container.encode(codableDict)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable(value: $0) }
            try container.encode(codableArray)
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: encoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }

    init(value: Any) {
        self.value = value
    }
}
