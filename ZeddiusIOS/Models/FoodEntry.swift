import Foundation

struct FoodEntry: Codable, Hashable, Identifiable {
    let id: UUID
    let consumedAt: Date
    let name: String
    @OptionalDecimalString var kcal: Decimal?
    @OptionalDecimalString var proteinG: Decimal?
    @OptionalDecimalString var carbsG: Decimal?
    @OptionalDecimalString var fatG: Decimal?
    let source: String
    @OptionalDecimalString var portionCount: Decimal?
    let mealSlot: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case consumedAt = "consumed_at"
        case name
        case kcal
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case source
        case portionCount = "portion_count"
        case mealSlot = "meal_slot"
        case createdAt = "created_at"
    }
}

struct CreateFoodEntryRequest: Encodable {
    let consumedAt: Date
    let name: String
    @OptionalDecimalString var kcal: Decimal?
    @OptionalDecimalString var proteinG: Decimal?
    @OptionalDecimalString var carbsG: Decimal?
    @OptionalDecimalString var fatG: Decimal?
    let mealSlot: String?

    enum CodingKeys: String, CodingKey {
        case consumedAt = "consumed_at"
        case name
        case kcal
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case mealSlot = "meal_slot"
    }
}
