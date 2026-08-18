import Foundation
import Observation

@Observable
@MainActor
final class AuthService {
    static let shared = AuthService()

    enum AppleSignInOutcome {
        case signedIn(User)
        case needsProfile(identityToken: String)
        case needsPasswordLink(identityToken: String)
    }

    private(set) var isSignedIn: Bool
    private(set) var currentUser: User?
    /// Set right after any sign-in/register whose `user.email_verified_at` is nil,
    /// and as a fallback whenever `APIClient` sees a 403 from a `VerifiedUser` route
    /// (covers the cold-launch case where `currentUser` hasn't been fetched yet).
    private(set) var needsEmailVerification = false

    private let baseURL = URL(string: "https://api.dev.zeddius.com/v1")!
    private let session = URLSession.shared

    private init() {
        isSignedIn = KeychainService.get(.accessToken) != nil
    }

    func signInWithApple(identityToken: String) async throws -> AppleSignInOutcome {
        let request = try makeRequest(path: "/auth/oauth/apple", method: "POST", body: AppleAuthRequest(identityToken: identityToken))
        let (data, response) = try await send(request)

        switch response.statusCode {
        case 200:
            let auth = try decode(AuthResponse.self, from: data)
            store(auth)
            return .signedIn(auth.user)
        case 204:
            return .needsProfile(identityToken: identityToken)
        case 409:
            return .needsPasswordLink(identityToken: identityToken)
        case 401:
            throw try serverError(from: data, status: response.statusCode)
        default:
            throw try serverError(from: data, status: response.statusCode)
        }
    }

    func completeAppleProfile(identityToken: String, username: String, displayName: String) async throws -> User {
        let body = AppleCompleteRequest(identityToken: identityToken, username: username, displayName: displayName)
        let request = try makeRequest(path: "/auth/oauth/apple/complete", method: "POST", body: body)
        let (data, response) = try await send(request)
        guard response.statusCode == 200 || response.statusCode == 201 else {
            throw try serverError(from: data, status: response.statusCode)
        }
        let auth = try decode(AuthResponse.self, from: data)
        store(auth)
        return auth.user
    }

    func register(email: String, username: String, displayName: String, password: String) async throws -> User {
        let body = RegisterRequest(email: email, username: username, displayName: displayName, password: password)
        let request = try makeRequest(path: "/auth/register", method: "POST", body: body)
        let (data, response) = try await send(request)
        guard response.statusCode == 201 else {
            throw try serverError(from: data, status: response.statusCode)
        }
        let auth = try decode(AuthResponse.self, from: data)
        store(auth)
        return auth.user
    }

    func login(email: String, password: String) async throws -> User {
        let body = LoginRequest(email: email, password: password)
        let request = try makeRequest(path: "/auth/login", method: "POST", body: body)
        let (data, response) = try await send(request)
        guard response.statusCode == 200 else {
            throw try serverError(from: data, status: response.statusCode)
        }
        let auth = try decode(AuthResponse.self, from: data)
        store(auth)
        return auth.user
    }

    func verifyEmail(code: String) async throws -> User {
        let request = try makeAuthenticatedRequest(path: "/auth/verify-email", method: "POST", body: VerifyEmailRequest(code: code))
        let (data, response) = try await send(request)
        guard response.statusCode == 200 else {
            throw try serverError(from: data, status: response.statusCode)
        }
        let auth = try decode(AuthResponse.self, from: data)
        store(auth)
        return auth.user
    }

    func resendVerificationCode() async throws {
        let request = try makeAuthenticatedRequest(path: "/auth/resend-verification", method: "POST")
        let (data, response) = try await send(request)
        guard response.statusCode == 204 else {
            throw try serverError(from: data, status: response.statusCode)
        }
    }

    /// Fallback path for the cold-launch case described on `needsEmailVerification`.
    func markNeedsEmailVerification() {
        needsEmailVerification = true
    }

    func linkApplePassword(identityToken: String, password: String) async throws -> User {
        let body = AppleLinkRequest(identityToken: identityToken, password: password)
        let request = try makeRequest(path: "/auth/oauth/apple/link", method: "POST", body: body)
        let (data, response) = try await send(request)
        guard response.statusCode == 200 else {
            throw try serverError(from: data, status: response.statusCode)
        }
        let auth = try decode(AuthResponse.self, from: data)
        store(auth)
        return auth.user
    }

    /// Rotates the token pair. Called by `APIClient` on a 401; not for direct use elsewhere.
    func refreshAccessToken() async throws -> String {
        guard let refreshToken = KeychainService.get(.refreshToken) else {
            signOut()
            throw APIError.unauthorized
        }
        let request = try makeRequest(path: "/auth/refresh", method: "POST", body: RefreshRequest(refreshToken: refreshToken))
        let (data, response) = try await send(request)
        guard response.statusCode == 200 else {
            signOut()
            throw APIError.unauthorized
        }
        let auth = try decode(AuthResponse.self, from: data)
        store(auth)
        return auth.accessToken
    }

    func signOut() {
        KeychainService.clearAll()
        currentUser = nil
        isSignedIn = false
        needsEmailVerification = false
    }

    /// Best-effort server-side revoke; clears the local session regardless of outcome.
    func signOutRemotely() async {
        if let accessToken = KeychainService.get(.accessToken) {
            var request = URLRequest(url: baseURL.appendingPathComponent("/auth/logout"))
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            _ = try? await session.data(for: request)
        }
        signOut()
    }

    // MARK: - Private helpers

    private func store(_ auth: AuthResponse) {
        KeychainService.set(auth.accessToken, for: .accessToken)
        KeychainService.set(auth.refreshToken, for: .refreshToken)
        currentUser = auth.user
        isSignedIn = true
        needsEmailVerification = auth.user.emailVerifiedAt == nil
    }

    private func makeRequest(path: String, method: String, body: some Encodable) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try APICoding.encoder.encode(body)
        return request
    }

    private func makeAuthenticatedRequest(path: String, method: String) throws -> URLRequest {
        guard let accessToken = KeychainService.get(.accessToken) else {
            throw APIError.unauthorized
        }
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func makeAuthenticatedRequest(path: String, method: String, body: some Encodable) throws -> URLRequest {
        var request = try makeAuthenticatedRequest(path: path, method: method)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try APICoding.encoder.encode(body)
        return request
    }

    private func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
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

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try APICoding.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func serverError(from data: Data, status: Int) throws -> APIError {
        if let decoded = try? APICoding.decoder.decode(ErrorResponse.self, from: data) {
            return .server(code: decoded.error.code, message: decoded.error.message, status: status)
        }
        return .invalidResponse
    }
}
