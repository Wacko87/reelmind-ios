import Foundation

public enum ReelMindError: LocalizedError, Sendable {
    case serverNotConfigured
    case invalidURL
    case unauthorized
    case invalidResponse(statusCode: Int)
    case serverError(message: String)
    case decodingError(message: String)
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .serverNotConfigured:
            return "Please configure your ReelMind server URL in the Settings tab."
        case .invalidURL:
            return "The server URL provided is invalid."
        case .unauthorized:
            return "Authentication failed. Please verify your PIN / token in Settings."
        case .invalidResponse(let statusCode):
            return "Server returned an unexpected HTTP status: \(statusCode)."
        case .serverError(let message):
            return message
        case .decodingError(let message):
            return "Failed to parse server response: \(message)"
        case .networkUnavailable:
            return "Network connection unavailable. Please check your connectivity."
        }
    }
}
