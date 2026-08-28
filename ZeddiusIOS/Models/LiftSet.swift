import Foundation

struct LiftSet: Codable, Hashable, Identifiable {
    let id: UUID
    let workoutId: UUID
    let exerciseId: UUID
    let setNumber: Int
    let actualReps: Int?
    @OptionalDecimalString var actualWeightKg: Decimal?
    @OptionalDecimalString var rpe: Decimal?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case workoutId = "workout_id"
        case exerciseId = "exercise_id"
        case setNumber = "set_number"
        case actualReps = "actual_reps"
        case actualWeightKg = "actual_weight_kg"
        case rpe
        case notes
    }
}

struct CreateLiftSetRequest: Encodable {
    let exerciseId: UUID
    let setNumber: Int
    let actualReps: Int?
    @OptionalDecimalString var actualWeightKg: Decimal?
    @OptionalDecimalString var rpe: Decimal?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case setNumber = "set_number"
        case actualReps = "actual_reps"
        case actualWeightKg = "actual_weight_kg"
        case rpe
        case notes
    }
}

struct BulkCreateLiftSetsRequest: Encodable {
    let sets: [CreateLiftSetRequest]
}

/// Every field is "leave unchanged if omitted" — matches the server's
/// COALESCE-based PATCH semantics, same as every other update request.
struct UpdateLiftSetRequest: Encodable {
    let actualReps: Int?
    @OptionalDecimalString var actualWeightKg: Decimal?
    @OptionalDecimalString var rpe: Decimal?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case actualReps = "actual_reps"
        case actualWeightKg = "actual_weight_kg"
        case rpe
        case notes
    }
}
