import Foundation

struct APIConfiguration {
    let baseURL: URL

    static func load() throws -> APIConfiguration {
        var value = Bundle.main.object(forInfoDictionaryKey: "CatalogueAPIBaseURL") as? String
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["CATALOGUE_API_BASE_URL"] {
            value = override
        }
        #endif
        guard let value, let url = URL(string: value),
              let host = url.host, !host.isEmpty, let scheme = url.scheme,
              ["http", "https"].contains(scheme),
              url.query == nil, url.fragment == nil,
              url.user == nil, url.password == nil else {
            throw APIError.invalidURL
        }
        #if !DEBUG
        guard url.scheme == "https", !host.hasSuffix(".invalid") else {
            throw APIError.invalidURL
        }
        #endif
        return APIConfiguration(baseURL: url)
    }
}
