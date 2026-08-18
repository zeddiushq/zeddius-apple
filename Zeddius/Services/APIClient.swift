import Foundation

@Observable
@MainActor
final class APIClient {
    private let baseURL = URL(string: "https://api.dev.zeddius.com/v1")!
    private let session = URLSession.shared
    private let auth: AuthService

    init(auth: AuthService = .shared) {
        self.auth = auth
    }

    func getMe() async throws -> User {
        try await request("GET", path: "/users/me")
    }

    func getWeightLogs() async throws -> [WeightLog] {
        let logs: [WeightLog] = try await request("GET", path: "/weight-logs")
        return logs.sorted { $0.recordedAt > $1.recordedAt }
    }

    func createWeightLog(_ body: CreateWeightLogRequest) async throws -> WeightLog {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("POST", path: "/weight-logs", body: encoded, retrying: true)
    }

    func deleteWeightLog(id: UUID) async throws {
        try await requestNoContent("DELETE", path: "/weight-logs/\(id.uuidString)", body: nil, retrying: true)
    }

    // MARK: - Core request handling

    private func request<T: Decodable>(_ method: String, path: String) async throws -> T {
        try await requestDecoded(method, path: path, body: nil, retrying: true)
    }

    /// Every retry re-runs from here with the same encoded body, so a 401 on a
    /// POST/PATCH doesn't silently retry as a bodyless request.
    private func requestDecoded<T: Decodable>(_ method: String, path: String, body: Data?, retrying: Bool) async throws -> T {
        let (data, response) = try await perform(method: method, path: path, body: body)

        if response.statusCode == 401, retrying {
            _ = try await auth.refreshAccessToken()
            return try await requestDecoded(method, path: path, body: body, retrying: false)
        }

        if response.statusCode == 403 {
            auth.markNeedsEmailVerification()
        }
        guard (200...299).contains(response.statusCode) else {
            throw try serverError(from: data, status: response.statusCode)
        }

        do {
            return try APICoding.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func requestNoContent(_ method: String, path: String, body: Data?, retrying: Bool) async throws {
        let (data, response) = try await perform(method: method, path: path, body: body)

        if response.statusCode == 401, retrying {
            _ = try await auth.refreshAccessToken()
            return try await requestNoContent(method, path: path, body: body, retrying: false)
        }

        guard (200...299).contains(response.statusCode) else {
            throw try serverError(from: data, status: response.statusCode)
        }
    }

    private func perform(method: String, path: String, body: Data?) async throws -> (Data, HTTPURLResponse) {
        guard let accessToken = KeychainService.get(.accessToken) else {
            throw APIError.unauthorized
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            return (data, http)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error)
        }
    }

    private func serverError(from data: Data, status: Int) throws -> APIError {
        if let decoded = try? APICoding.decoder.decode(ErrorResponse.self, from: data) {
            return .server(code: decoded.error.code, message: decoded.error.message, status: status)
        }
        return .invalidResponse
    }
}
