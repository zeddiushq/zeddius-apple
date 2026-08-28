import Foundation

struct Workout: Codable, Hashable, Identifiable {
    let id: UUID
    let type: String
    let startedAt: Date
    let endedAt: Date?
    let notes: String?
    let source: String
    let liftSets: [LiftSet]

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case notes
        case source
        case liftSets = "lift_sets"
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

/// The subset of `workouts.type` this app's Lift screen offers — `run_easy`/
/// `run_long` belong to the future Run feature (Chunk 5), not lift logging.
enum WorkoutType {
    static let liftOptions: [(value: String, label: String)] = [
        ("lift_upper_a", "Upper A"),
        ("lift_lower_a", "Lower A"),
        ("lift_upper_b", "Upper B"),
        ("lift_lower_b", "Lower B"),
        ("custom", "Custom"),
    ]

    static func label(for value: String) -> String {
        liftOptions.first(where: { $0.value == value })?.label ?? value.capitalized
    }
}
