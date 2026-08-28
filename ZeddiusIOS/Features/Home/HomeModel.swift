import Foundation
import Observation

@Observable
@MainActor
final class HomeModel {
    private(set) var latestWeight: WeightLog?
    private(set) var latestSleep: SleepLog?
    private(set) var todayKcal: Decimal = 0
    private(set) var todayProteinG: Decimal = 0
    private(set) var targetCalories: Int?
    private(set) var targetProteinG: Int?
    private(set) var lastWorkout: Workout?
    private(set) var isLoading = false
    private(set) var hasLoadedOnce = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoadedOnce = true
        }

        do {
            async let weightsTask = api.getWeightLogs()
            async let sleepsTask = api.getSleepLogs()
            async let foodsTask = api.getFoodEntries()
            async let workoutsTask = api.getWorkouts()
            async let userTask = api.getMe()

            let weights = try await weightsTask
            let sleeps = try await sleepsTask
            let foods = try await foodsTask
            let workouts = try await workoutsTask
            let user = try await userTask

            latestWeight = weights.first
            latestSleep = sleeps.first
            lastWorkout = workouts.first
            targetCalories = user.targetCalories
            targetProteinG = user.targetProteinG

            let todayFoods = foods.filter { Calendar.current.isDateInToday($0.consumedAt) }
            todayKcal = todayFoods.reduce(0) { $0 + ($1.kcal ?? 0) }
            todayProteinG = todayFoods.reduce(0) { $0 + ($1.proteinG ?? 0) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
