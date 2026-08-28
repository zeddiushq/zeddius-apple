import Foundation

struct Exercise: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let slug: String
    let muscleGroups: [String]
    let equipment: [String]
    let progressionType: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case muscleGroups = "muscle_groups"
        case equipment
        case progressionType = "progression_type"
    }
}
