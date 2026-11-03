import Foundation

protocol CatalogueServing {
    func featured() async throws -> [Product]
    func categories() async throws -> [String]
    func search(query: String) async throws -> [Product]
    func category(_ name: String) async throws -> [ProductSection]
    func product(id: Int) async throws -> Product
    func enquire(_ enquiry: EnquiryRequest) async throws -> Confirmation
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case rejected(status: Int, message: String)
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The catalogue is not configured. Please contact support."
        case .invalidResponse, .invalidData: return "The server returned an unexpected response. Please try again."
        case .rejected(_, let message): return message
        case .unavailable: return "Cannot reach the catalogue. Check your connection and try again."
        }
    }
}

final class CatalogueAPI: CatalogueServing {
    private struct ProductsResponse: Decodable { let products: [Product] }
    private struct CategoriesResponse: Decodable { let categories: [String] }
    private struct ProductResponse: Decodable { let product: Product }
    private struct CategoryResponse: Decodable { let featured: [Product]; let products: [Product] }
    private struct ErrorResponse: Decodable {
        struct Detail: Decodable { let message: String }
        let error: Detail
    }

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 15
            configuration.timeoutIntervalForResource = 30
            self.session = URLSession(configuration: configuration)
        }
    }

    func featured() async throws -> [Product] {
        let response: ProductsResponse = try await send(path: ["products", "featured"])
        return response.products
    }

    func categories() async throws -> [String] {
        let response: CategoriesResponse = try await send(path: ["categories"])
        return response.categories
    }

    func search(query: String) async throws -> [Product] {
        let response: ProductsResponse = try await send(path: ["products"], query: [URLQueryItem(name: "q", value: query)])
        return response.products
    }

    func category(_ name: String) async throws -> [ProductSection] {
        let response: CategoryResponse = try await send(path: ["categories", name, "products"])
        return [
            ProductSection(title: "Featured", products: response.featured),
            ProductSection(title: "More products", products: response.products),
        ].filter { !$0.products.isEmpty }
    }

    func product(id: Int) async throws -> Product {
        let response: ProductResponse = try await send(path: ["products", String(id)])
        return response.product
    }

    func enquire(_ enquiry: EnquiryRequest) async throws -> Confirmation {
        try await send(path: ["enquiries"], body: JSONEncoder().encode(enquiry))
    }

    private func send<Response: Decodable>(path: [String], query: [URLQueryItem] = [], body: Data? = nil) async throws -> Response {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { throw APIError.invalidURL }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let segments = try path.map { segment -> String in
            guard let encoded = segment.addingPercentEncoding(withAllowedCharacters: allowed) else { throw APIError.invalidURL }
            return encoded
        }
        var basePath = components.percentEncodedPath
        while basePath.hasSuffix("/") { basePath.removeLast() }
        components.percentEncodedPath = basePath + "/" + segments.joined(separator: "/")
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = body == nil ? "GET" : "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled { throw CancellationError() }
            throw APIError.unavailable
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error.message
                ?? "The request could not be completed. Please try again."
            throw APIError.rejected(status: http.statusCode, message: message)
        }
        do { return try JSONDecoder().decode(Response.self, from: data) }
        catch { throw APIError.invalidData }
    }
}
