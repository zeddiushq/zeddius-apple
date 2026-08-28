import Foundation
import Observation

@Observable
@MainActor
final class SleepLogModel {
    private(set) var entries: [SleepLog] = []
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
            entries = try await api.getSleepLogs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addEntry(bedTime: Date, wakeTime: Date, qualityScore: Int?) async -> Bool {
        errorMessage = nil
        let body = CreateSleepLogRequest(
            date: APICoding.dateOnlyString(from: wakeTime),
            bedTime: bedTime,
            wakeTime: wakeTime,
            qualityScore: qualityScore
        )
        do {
            let created = try await api.createSleepLog(body)
            entries.insert(created, at: 0)
            entries.sort { $0.bedTime > $1.bedTime }
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
                try await api.deleteSleepLog(id: entry.id)
            } catch {
                errorMessage = error.localizedDescription
                entries.append(entry)
                entries.sort { $0.bedTime > $1.bedTime }
            }
        }
    }
}
