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

    func logWorkout(type: String, startedAt: Date, notes: String?, sets: [CreateLiftSetRequest]) async -> Bool {
        errorMessage = nil
        do {
            let workout = try await api.createWorkout(
                CreateWorkoutRequest(type: type, startedAt: startedAt, notes: notes)
            )
            if !sets.isEmpty {
                _ = try await api.createLiftSets(workoutId: workout.id, BulkCreateLiftSetsRequest(sets: sets))
            }
            // Simplest way to get the fresh workout (with lift_sets nested)
            // into the list in the right sorted position.
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(at offsets: IndexSet) async {
        let toDelete = offsets.map { workouts[$0] }
        workouts.remove(atOffsets: offsets)
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
