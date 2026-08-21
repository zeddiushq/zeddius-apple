import Foundation
import Observation

@Observable
@MainActor
final class WeightLogModel {
    private(set) var entries: [WeightLog] = []
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
            entries = try await api.getWeightLogs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addEntry(weightKg: Decimal, bodyFatPct: Decimal?, recordedAt: Date) async -> Bool {
        errorMessage = nil
        let body = CreateWeightLogRequest(
            recordedAt: recordedAt,
            weightKg: weightKg,
            bodyFatPct: bodyFatPct,
            muscleMassKg: nil,
            waterPct: nil,
            boneMassKg: nil
        )
        do {
            let created = try await api.createWeightLog(body)
            entries.insert(created, at: 0)
            entries.sort { $0.recordedAt > $1.recordedAt }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(at offsets: IndexSet) async {
        let toDelete = offsets.map { entries[$0] }
        entries.remove(atOffsets: offsets)
        for entry in toDelete {
            do {
                try await api.deleteWeightLog(id: entry.id)
            } catch {
                errorMessage = error.localizedDescription
                entries.append(entry)
                entries.sort { $0.recordedAt > $1.recordedAt }
            }
        }
    }
}
