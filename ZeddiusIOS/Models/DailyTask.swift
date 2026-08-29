import Foundation

struct DailyTask: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let recurrence: String // "daily" | "weekly"
    let targetCountPerWeek: Int?
    let active: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, recurrence
        case targetCountPerWeek = "target_count_per_week"
        case active
        case createdAt = "created_at"
    }
}

struct CreateTaskRequest: Encodable {
    let title: String
    let recurrence: String
    let targetCountPerWeek: Int?

    enum CodingKeys: String, CodingKey {
        case title, recurrence
        case targetCountPerWeek = "target_count_per_week"
    }
}

/// Every field is "leave unchanged if omitted" — the server's PATCH
/// /tasks/:id COALESCEs on the SQL side, same convention as every other
/// PATCH in this app.
struct UpdateTaskRequest: Encodable {
    var title: String?
    var recurrence: String?
    var targetCountPerWeek: Int?
    var active: Bool?

    enum CodingKeys: String, CodingKey {
        case title, recurrence
        case targetCountPerWeek = "target_count_per_week"
        case active
    }
}

/// A raw completion row — no "today"/"this week" state is computed
/// server-side. The client fetches a date range and buckets it itself.
struct TaskCompletion: Codable, Hashable {
    let taskId: UUID
    let completedDate: Date

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case completedDate = "completed_date"
    }
}

struct CompleteTaskRequest: Encodable {
    /// "YYYY-MM-DD" — see APICoding.dateOnlyString.
    let completedDate: String

    enum CodingKeys: String, CodingKey {
        case completedDate = "completed_date"
    }
}
