import Foundation

struct RunSession: Codable, Hashable {
    let id: UUID
    let workoutId: UUID
    @DecimalString var distanceMeters: Decimal
    let durationSeconds: Int
    let avgPaceSecondsPerKm: Int?
    let avgHeartRate: Int?
    let maxHeartRate: Int?
    @OptionalDecimalString var elevationGainMeters: Decimal?

    enum CodingKeys: String, CodingKey {
        case id
        case workoutId = "workout_id"
        case distanceMeters = "distance_meters"
        case durationSeconds = "duration_seconds"
        case avgPaceSecondsPerKm = "avg_pace_seconds_per_km"
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case elevationGainMeters = "elevation_gain_meters"
    }
}

/// No `avgPaceSecondsPerKm` — the API always computes it server-side from
/// distance/duration, matching `CreateRunSessionRequest` on the Rust side.
struct CreateRunSessionRequest: Encodable {
    @DecimalString var distanceMeters: Decimal
    let durationSeconds: Int
    let avgHeartRate: Int?
    let maxHeartRate: Int?
    @OptionalDecimalString var elevationGainMeters: Decimal?

    enum CodingKeys: String, CodingKey {
        case distanceMeters = "distance_meters"
        case durationSeconds = "duration_seconds"
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case elevationGainMeters = "elevation_gain_meters"
    }
}
