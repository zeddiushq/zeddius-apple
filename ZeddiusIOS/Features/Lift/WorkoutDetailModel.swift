import Foundation
import Observation

@Observable
@MainActor
final class WorkoutDetailModel {
    let workoutId: UUID
    private(set) var workout: Workout?
    private(set) var exercises: [Exercise] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient, workoutId: UUID) {
        self.api = api
        self.workoutId = workoutId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let workoutTask = api.getWorkout(id: workoutId)
            async let exercisesTask = api.getExercises()
            workout = try await workoutTask
            exercises = try await exercisesTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// `set_number` continues from however many sets this exercise already
    /// has in this workout — "set 4 of bench," not "the 12th thing logged."
    func addSet(
        exerciseId: UUID,
        actualReps: Int?,
        actualWeightKg: Decimal?,
        rpe: Decimal?,
        notes: String?
    ) async -> Bool {
        errorMessage = nil
        let existingCount = workout?.liftSets.filter { $0.exerciseId == exerciseId }.count ?? 0
        let request = CreateLiftSetRequest(
            exerciseId: exerciseId,
            setNumber: existingCount + 1,
            actualReps: actualReps,
            actualWeightKg: actualWeightKg,
            rpe: rpe,
            notes: notes
        )
        do {
            _ = try await api.createLiftSets(workoutId: workoutId, BulkCreateLiftSetsRequest(sets: [request]))
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateSet(
        id: UUID,
        actualReps: Int?,
        actualWeightKg: Decimal?,
        rpe: Decimal?,
        notes: String?
    ) async -> Bool {
        errorMessage = nil
        do {
            _ = try await api.updateLiftSet(
                id: id,
                UpdateLiftSetRequest(actualReps: actualReps, actualWeightKg: actualWeightKg, rpe: rpe, notes: notes)
            )
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
