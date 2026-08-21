import Foundation

struct WeightLog: Codable, Hashable, Identifiable {
    let id: UUID
    let recordedAt: Date
    @DecimalString var weightKg: Decimal
    @OptionalDecimalString var bodyFatPct: Decimal?
    @OptionalDecimalString var muscleMassKg: Decimal?
    @OptionalDecimalString var waterPct: Decimal?
    @OptionalDecimalString var boneMassKg: Decimal?
    let source: String
    let sourceUuid: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case recordedAt = "recorded_at"
        case weightKg = "weight_kg"
        case bodyFatPct = "body_fat_pct"
        case muscleMassKg = "muscle_mass_kg"
        case waterPct = "water_pct"
        case boneMassKg = "bone_mass_kg"
        case source
        case sourceUuid = "source_uuid"
        case createdAt = "created_at"
    }
}

struct CreateWeightLogRequest: Encodable {
    let recordedAt: Date
    @DecimalString var weightKg: Decimal
    @OptionalDecimalString var bodyFatPct: Decimal?
    @OptionalDecimalString var muscleMassKg: Decimal?
    @OptionalDecimalString var waterPct: Decimal?
    @OptionalDecimalString var boneMassKg: Decimal?

    enum CodingKeys: String, CodingKey {
        case recordedAt = "recorded_at"
        case weightKg = "weight_kg"
        case bodyFatPct = "body_fat_pct"
        case muscleMassKg = "muscle_mass_kg"
        case waterPct = "water_pct"
        case boneMassKg = "bone_mass_kg"
    }
}
