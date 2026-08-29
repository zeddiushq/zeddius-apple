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
    @OptionalDecimalString var targetWeightKg: Decimal?
    @OptionalTimeString var targetWakeTime: Date?
    @OptionalTimeString var targetBedTime: Date?
    let targetWeeklyRuns: Int?
    let targetWeeklyLifts: Int?
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
        case targetWeightKg = "target_weight_kg"
        case targetWakeTime = "target_wake_time"
        case targetBedTime = "target_bed_time"
        case targetWeeklyRuns = "target_weekly_runs"
        case targetWeeklyLifts = "target_weekly_lifts"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Every field is "leave unchanged if omitted" — the server's PATCH /users/me
/// COALESCEs on the SQL side, same convention as every other PATCH in this
/// app. Only set the field(s) actually being changed.
struct UpdateUserRequest: Encodable {
    var targetCalories: Int?
    var targetProteinG: Int?
    @OptionalDecimalString var targetWeightKg: Decimal?
    @OptionalTimeString var targetWakeTime: Date?
    @OptionalTimeString var targetBedTime: Date?
    var targetWeeklyRuns: Int?
    var targetWeeklyLifts: Int?

    enum CodingKeys: String, CodingKey {
        case targetCalories = "target_calories"
        case targetProteinG = "target_protein_g"
        case targetWeightKg = "target_weight_kg"
        case targetWakeTime = "target_wake_time"
        case targetBedTime = "target_bed_time"
        case targetWeeklyRuns = "target_weekly_runs"
        case targetWeeklyLifts = "target_weekly_lifts"
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
