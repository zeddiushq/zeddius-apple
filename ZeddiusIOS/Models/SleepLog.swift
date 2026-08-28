import Foundation

struct SleepLog: Codable, Hashable, Identifiable {
    let id: UUID
    let date: Date
    let bedTime: Date
    let wakeTime: Date
    let durationMinutes: Int
    let qualityScore: Int?
    let deepMinutes: Int?
    let remMinutes: Int?
    let coreMinutes: Int?
    let awakeMinutes: Int?
    let source: String
    let sourceUuid: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case bedTime = "bed_time"
        case wakeTime = "wake_time"
        case durationMinutes = "duration_minutes"
        case qualityScore = "quality_score"
        case deepMinutes = "deep_minutes"
        case remMinutes = "rem_minutes"
        case coreMinutes = "core_minutes"
        case awakeMinutes = "awake_minutes"
        case source
        case sourceUuid = "source_uuid"
        case createdAt = "created_at"
    }
}

struct CreateSleepLogRequest: Encodable {
    /// "YYYY-MM-DD" — see `APICoding.dateOnlyString`.
    let date: String
    let bedTime: Date
    let wakeTime: Date
    let qualityScore: Int?

    enum CodingKeys: String, CodingKey {
        case date
        case bedTime = "bed_time"
        case wakeTime = "wake_time"
        case qualityScore = "quality_score"
    }
}
