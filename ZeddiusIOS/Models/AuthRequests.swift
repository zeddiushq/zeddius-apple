import Foundation

struct AppleAuthRequest: Encodable {
    let identityToken: String

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
    }
}

struct AppleCompleteRequest: Encodable {
    let identityToken: String
    let username: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case username
        case displayName = "display_name"
    }
}

struct AppleLinkRequest: Encodable {
    let identityToken: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case password
    }
}

struct RegisterRequest: Encodable {
    let email: String
    let username: String
    let displayName: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case email, username, password
        case displayName = "display_name"
    }
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct VerifyEmailRequest: Encodable {
    let code: String
}

struct RefreshRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct ErrorResponse: Decodable {
    let error: ErrorDetail
}

struct ErrorDetail: Decodable {
    let code: String
    let message: String
}
