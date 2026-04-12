import Foundation

enum APIConfig {
    static var baseURL: String {
        if let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"], !envURL.isEmpty {
            return envURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !plistURL.isEmpty {
            return plistURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        fatalError("API_BASE_URL not set. Create Config.xcconfig from Config.xcconfig.example")
    }

    static let timeoutInterval: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60
}
