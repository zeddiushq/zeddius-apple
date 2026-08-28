import Foundation
import Observation

@Observable
@MainActor
final class FoodEntryModel {
    private(set) var entries: [FoodEntry] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            entries = try await api.getFoodEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addEntry(
        name: String,
        consumedAt: Date,
        kcal: Decimal?,
        proteinG: Decimal?,
        carbsG: Decimal?,
        fatG: Decimal?,
        mealSlot: String?
    ) async -> Bool {
        errorMessage = nil
        let body = CreateFoodEntryRequest(
            consumedAt: consumedAt,
            name: name,
            kcal: kcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            mealSlot: mealSlot
        )
        do {
            let created = try await api.createFoodEntry(body)
            entries.insert(created, at: 0)
            entries.sort { $0.consumedAt > $1.consumedAt }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// `displayed` is whatever (possibly filtered) list the view is currently rendering —
    /// `offsets` indexes into it, not into `entries`, so deletion is resolved by id rather
    /// than by position in the full array.
    func delete(at offsets: IndexSet, in displayed: [FoodEntry]) async {
        let toDelete = offsets.map { displayed[$0] }
        let idsToDelete = Set(toDelete.map(\.id))
        entries.removeAll { idsToDelete.contains($0.id) }
        for entry in toDelete {
            do {
                try await api.deleteFoodEntry(id: entry.id)
            } catch {
                errorMessage = error.localizedDescription
                entries.append(entry)
                entries.sort { $0.consumedAt > $1.consumedAt }
            }
        }
    }
}
