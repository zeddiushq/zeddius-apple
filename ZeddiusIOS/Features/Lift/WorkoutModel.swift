import Foundation
import Observation

@Observable
@MainActor
final class WorkoutModel {
    private(set) var workouts: [Workout] = []
    private(set) var exercises: [Exercise] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    /// `workouts` holds every type (lift and run share one `/workouts`
    /// list) — this screen only shows the lift-relevant ones.
    var liftWorkouts: [Workout] {
        workouts.filter { WorkoutType.isLiftType($0.type) }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            workouts = try await api.getWorkouts()
            if exercises.isEmpty {
                exercises = try await api.getExercises()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Creates just the workout shell — sets get added afterward, one at a
    /// time, from WorkoutDetailView. Most sessions aren't logged in one
    /// sitting, so there's no bulk "save everything at the end" step.
    func createWorkout(type: String, startedAt: Date, notes: String?) async -> Workout? {
        errorMessage = nil
        do {
            let workout = try await api.createWorkout(
                CreateWorkoutRequest(type: type, startedAt: startedAt, notes: notes)
            )
            workouts.insert(workout, at: 0)
            workouts.sort { $0.startedAt > $1.startedAt }
            return workout
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// `displayed` is `liftWorkouts` (a filtered view) — `offsets` indexes
    /// into it, not into `workouts`, so deletion is resolved by id.
    func delete(at offsets: IndexSet, in displayed: [Workout]) async {
        let toDelete = offsets.map { displayed[$0] }
        let idsToDelete = Set(toDelete.map(\.id))
        workouts.removeAll { idsToDelete.contains($0.id) }
        for workout in toDelete {
            do {
                try await api.deleteWorkout(id: workout.id)
            } catch {
                errorMessage = error.localizedDescription
                await load()
            }
        }
    }
}
