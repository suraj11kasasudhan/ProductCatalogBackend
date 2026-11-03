import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case rejected(status: Int, message: String)
    case connectionFailed(String)
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The catalogue is not configured. Please contact support."
        case .invalidResponse, .invalidData: return "The server returned an unexpected response. Please try again."
        case .rejected(_, let message): return message
        case .connectionFailed(let message): return message
        case .unavailable: return "Cannot reach the catalogue. Check your connection and try again."
        }
    }

    static func rejection(status: Int, data: Data) -> APIError {
        struct Envelope: Decodable {
            struct Detail: Decodable { let message: String }
            let error: Detail
        }
        let message = (try? JSONDecoder().decode(Envelope.self, from: data))?.error.message
            ?? "The request could not be completed. Please try again."
        return .rejected(status: status, message: message)
    }

    static func transport(_ error: Error, baseURL: URL) -> APIError {
        #if DEBUG
        if let host = baseURL.host, ["localhost", "127.0.0.1", "::1"].contains(host),
           let urlError = error as? URLError,
           [.cannotConnectToHost, .cannotFindHost, .timedOut].contains(urlError.code) {
            return .connectionFailed("The local catalogue server is not responding. Start the backend on the same Mac as your simulator, then tap Try again. On a physical iPhone, configure your Mac’s LAN address instead of localhost.")
        }
        #endif
        return .unavailable
    }
}
