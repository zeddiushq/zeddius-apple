import Foundation

enum APIError: Error, LocalizedError {
    case server(code: String, message: String, status: Int)
    case unauthorized
    case decoding(Error)
    case network(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .server(_, let message, _):
            return message
        case .unauthorized:
            return "You've been signed out. Please sign in again."
        case .decoding:
            return "Received an unexpected response from the server."
        case .network(let error):
            return error.localizedDescription
        case .invalidResponse:
            return "Received an unexpected response from the server."
        }
    }
}
