import Foundation
import CryptoKit
import Observation
import Security

@Observable
@MainActor
final class AuthFlowModel {
    enum Stage: Equatable {
        case signIn
        case needsProfile(identityToken: String)
        case needsPasswordLink(identityToken: String)
    }

    private(set) var stage: Stage = .signIn
    var isLoading = false
    var errorMessage: String?

    /// The raw nonce handed to the Apple request; its SHA-256 hash is what
    /// actually goes on the `ASAuthorizationAppleIDRequest`.
    private(set) var currentNonce: String?

    private let auth: AuthService

    init(auth: AuthService = .shared) {
        self.auth = auth
    }

    func makeNonce() -> String {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        return Self.sha256(nonce)
    }

    func handleAppleIdentityToken(_ identityToken: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let outcome = try await auth.signInWithApple(identityToken: identityToken)
            switch outcome {
            case .signedIn:
                break // AuthService.isSignedIn flips; RootView reacts to that.
            case .needsProfile(let token):
                stage = .needsProfile(identityToken: token)
            case .needsPasswordLink(let token):
                stage = .needsPasswordLink(identityToken: token)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitProfile(identityToken: String, username: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await auth.completeAppleProfile(identityToken: identityToken, username: username, displayName: displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitPassword(identityToken: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await auth.linkApplePassword(identityToken: identityToken, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancel() {
        stage = .signIn
        errorMessage = nil
    }

    // MARK: - Nonce helpers (Apple's recommended replay-protection pattern)

    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            precondition(status == errSecSuccess, "Unable to generate secure random bytes")

            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
