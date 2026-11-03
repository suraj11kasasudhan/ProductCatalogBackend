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
}

