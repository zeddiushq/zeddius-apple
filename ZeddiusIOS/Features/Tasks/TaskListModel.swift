import Foundation
import Observation

@Observable
@MainActor
final class TaskListModel {
    private(set) var tasks: [DailyTask] = []
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
            tasks = try await api.getTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTask(title: String, recurrence: String, targetCountPerWeek: Int?) async -> Bool {
        errorMessage = nil
        do {
            let task = try await api.createTask(
                CreateTaskRequest(title: title, recurrence: recurrence, targetCountPerWeek: targetCountPerWeek)
            )
            tasks.append(task)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(at offsets: IndexSet) async {
        let toDelete = offsets.map { tasks[$0] }
        let idsToDelete = Set(toDelete.map(\.id))
        tasks.removeAll { idsToDelete.contains($0.id) }
        for task in toDelete {
            do {
                try await api.deleteTask(id: task.id)
            } catch {
                errorMessage = error.localizedDescription
                await load()
            }
        }
    }
}
