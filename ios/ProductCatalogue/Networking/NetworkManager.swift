import Foundation

protocol NetworkManaging {
    func send<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response
}

/// Owns URLSession, HTTP validation, decoding, and transport error translation.
final class NetworkManager: NetworkManaging {
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
            #if DEBUG
            if let host = baseURL.host, ["localhost", "127.0.0.1", "::1"].contains(host),
               let urlError = error as? URLError,
               [.cannotConnectToHost, .cannotFindHost, .timedOut].contains(urlError.code) {
                throw APIError.connectionFailed("The local catalogue server is not responding. Start the backend on the same Mac as your simulator, then tap Try again. On a physical iPhone, configure your Mac’s LAN address instead of localhost.")
            }
            #endif
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
