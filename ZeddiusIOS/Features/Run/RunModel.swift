import Foundation
import Observation

@Observable
@MainActor
final class RunModel {
    private(set) var workouts: [Workout] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    /// `workouts` holds every type (lift and run share one `/workouts`
    /// list) — this screen only shows the run-relevant ones.
    var runWorkouts: [Workout] {
        workouts.filter { WorkoutType.isRunType($0.type) }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            workouts = try await api.getWorkouts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logRun(
        type: String,
        startedAt: Date,
        notes: String?,
        distanceMeters: Decimal,
        durationSeconds: Int,
        avgHeartRate: Int?,
        maxHeartRate: Int?,
        elevationGainMeters: Decimal?
    ) async -> Bool {
        errorMessage = nil
        do {
            let workout = try await api.createWorkout(
                CreateWorkoutRequest(type: type, startedAt: startedAt, notes: notes)
            )
            _ = try await api.createRunSession(
                workoutId: workout.id,
                CreateRunSessionRequest(
                    distanceMeters: distanceMeters,
                    durationSeconds: durationSeconds,
                    avgHeartRate: avgHeartRate,
                    maxHeartRate: maxHeartRate,
                    elevationGainMeters: elevationGainMeters
                )
            )
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// `displayed` is `runWorkouts` (a filtered view) — `offsets` indexes
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
