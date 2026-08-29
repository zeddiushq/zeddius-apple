import Foundation

struct DailyCheckin: Codable, Hashable, Identifiable {
    let id: UUID
    let date: Date
    let tomorrowFocus: String?
    let closedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, date
        case tomorrowFocus = "tomorrow_focus"
        case closedAt = "closed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// A true create-or-replace upsert, not a COALESCE PATCH — matches the
/// server's POST /daily-checkins semantics (mirrors run_sessions' upsert).
struct UpsertDailyCheckinRequest: Encodable {
    /// "YYYY-MM-DD" — see APICoding.dateOnlyString.
    let date: String
    let tomorrowFocus: String?

    enum CodingKeys: String, CodingKey {
        case date
        case tomorrowFocus = "tomorrow_focus"
    }
}
