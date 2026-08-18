import Foundation

struct User: Codable, Hashable, Identifiable {
    let id: UUID
    let email: String
    let username: String
    let displayName: String
    let onboardingComplete: Bool
    let timezone: String
    let emailVerifiedAt: Date?
    let heightCm: Double?
    let birthdate: Date?
    let targetCalories: Int?
    let targetProteinG: Int?
    let targetSleepHours: Double?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, username
        case displayName = "display_name"
        case onboardingComplete = "onboarding_complete"
        case timezone
        case emailVerifiedAt = "email_verified_at"
        case heightCm = "height_cm"
        case birthdate
        case targetCalories = "target_calories"
        case targetProteinG = "target_protein_g"
        case targetSleepHours = "target_sleep_hours"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}
