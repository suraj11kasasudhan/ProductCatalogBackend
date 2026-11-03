import Foundation

protocol NetworkManaging {
    func send<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response
}

/// Owns URLSession, HTTP validation, decoding, and transport error translation.
final class NetworkManager: NetworkManaging {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            // Allow the hosted free-tier service time to wake after inactivity.
            configuration.timeoutIntervalForRequest = 75
            configuration.timeoutIntervalForResource = 90
            self.session = URLSession(configuration: configuration)
        }
    }

    func send<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        try Task.checkCancellation()
        let request = try endpoint.request(baseURL: baseURL)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled { throw CancellationError() }
            throw APIError.transport(error, baseURL: baseURL)
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.rejection(status: http.statusCode, data: data)
        }
        do { return try JSONDecoder().decode(Response.self, from: data) }
        catch { throw APIError.invalidData }
    }
}
