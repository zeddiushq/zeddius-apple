import Foundation

struct Workout: Codable, Hashable, Identifiable {
    let id: UUID
    let type: String
    let startedAt: Date
    let endedAt: Date?
    let notes: String?
    let source: String
    let liftSets: [LiftSet]
    let runSession: RunSession?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case notes
        case source
        case liftSets = "lift_sets"
        case runSession = "run_session"
    }
}

struct CreateWorkoutRequest: Encodable {
    let type: String
    let startedAt: Date
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case type
        case startedAt = "started_at"
        case notes
    }
}

/// `custom` is a shared catch-all, not lift- or run-specific — a workout
/// logged as `custom` from either screen will show up in both lists. Every
/// other value is unambiguous via its `lift_`/`run_` prefix.
enum WorkoutType {
    static let liftOptions: [(value: String, label: String)] = [
        ("lift_upper_a", "Upper A"),
        ("lift_lower_a", "Lower A"),
        ("lift_upper_b", "Upper B"),
        ("lift_lower_b", "Lower B"),
        ("custom", "Custom"),
    ]

    static let runOptions: [(value: String, label: String)] = [
        ("run_easy", "Easy Run"),
        ("run_long", "Long Run"),
        ("custom", "Custom"),
    ]

    static func label(for value: String) -> String {
        (liftOptions + runOptions).first(where: { $0.value == value })?.label ?? value.capitalized
    }

    static func isLiftType(_ value: String) -> Bool {
        value.hasPrefix("lift_") || value == "custom"
    }

    static func isRunType(_ value: String) -> Bool {
        value.hasPrefix("run_") || value == "custom"
    }
}
