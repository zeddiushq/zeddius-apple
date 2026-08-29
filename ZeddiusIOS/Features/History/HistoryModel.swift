import Foundation
import Observation

/// A single graph cell's resolved state. `.neutral` covers both "day/week
/// not yet resolved" (not closed, or week still ongoing) and "no target set"
/// — visually the same hollow cell either way.
enum HabitCellStatus {
    case met
    case missed
    case neutral
}

@Observable
@MainActor
final class HistoryModel {
    private(set) var user: User?
    private(set) var foodEntries: [FoodEntry] = []
    private(set) var sleepLogs: [SleepLog] = []
    private(set) var workouts: [Workout] = []
    private(set) var checkins: [DailyCheckin] = []
    private(set) var isLoading = false
    private(set) var hasLoadedOnce = false
    var errorMessage: String?

    private let api: APIClient
    private static let weeksToShow = 13

    /// Every day shown in the graph, oldest first, grid-aligned so day index
    /// `r` (0...6) of week column `c` is `gridDates[c * 7 + r]` — the grid's
    /// first column starts on the calendar's own first-day-of-week on or
    /// before "13 weeks ago," so week boundaries line up with real weeks
    /// rather than a raw 91-day rolling window.
    let gridDates: [Date]

    init(api: APIClient) {
        self.api = api
        gridDates = Self.makeGridDates()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoadedOnce = true
        }

        guard let rangeStart = gridDates.first, let rangeEnd = gridDates.last else { return }
        let calendar = Calendar.current
        // A day's padding on each side so a decode landing right at a
        // boundary (device-local midnight vs. the server's own clock)
        // can't silently drop the first or last column.
        let from = calendar.date(byAdding: .day, value: -1, to: rangeStart) ?? rangeStart
        let to = calendar.date(byAdding: .day, value: 1, to: rangeEnd) ?? rangeEnd

        do {
            async let userTask = api.getMe()
            async let foodsTask = api.getFoodEntries(from: from, to: to)
            async let sleepsTask = api.getSleepLogs(from: from, to: to)
            async let workoutsTask = api.getWorkouts(from: from, to: to)
            async let checkinsTask = api.getDailyCheckins(from: rangeStart, to: rangeEnd)

            user = try await userTask
            foodEntries = try await foodsTask
            sleepLogs = try await sleepsTask
            workouts = try await workoutsTask
            checkins = try await checkinsTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Daily habits

    func caloriesStatus(on date: Date) -> HabitCellStatus {
        guard let target = user?.targetCalories, isClosed(on: date) else { return .neutral }
        return kcal(on: date) > Decimal(target) ? .missed : .met
    }

    func proteinStatus(on date: Date) -> HabitCellStatus {
        guard let target = user?.targetProteinG, isClosed(on: date) else { return .neutral }
        return proteinG(on: date) >= Decimal(target) ? .met : .missed
    }

    func sleepStatus(on date: Date) -> HabitCellStatus {
        guard isClosed(on: date) else { return .neutral }
        return sleepLogged(on: date) ? .met : .missed
    }

    // MARK: - Weekly habits

    func runsStatus(forWeekContaining date: Date) -> HabitCellStatus {
        guard let target = user?.targetWeeklyRuns else { return .neutral }
        let count = workouts.filter { workout in
            WorkoutType.isRunType(workout.type) && WorkoutCadence.isWeekday(workout.startedAt)
                && WorkoutCadence.isSameWeek(workout.startedAt, as: date) && WorkoutCadence.qualifiesAsRun(workout)
                && isClosed(on: workout.startedAt)
        }.count
        if count >= target { return .met }
        return hasWeekEnded(containing: date) && hasAnyClosedDay(inWeekContaining: date) ? .missed : .neutral
    }

    func liftsStatus(forWeekContaining date: Date) -> HabitCellStatus {
        guard let target = user?.targetWeeklyLifts else { return .neutral }
        let count = workouts.filter { workout in
            WorkoutType.isLiftType(workout.type) && WorkoutCadence.isSameWeek(workout.startedAt, as: date)
                && isClosed(on: workout.startedAt)
        }.count
        if count >= target { return .met }
        return hasWeekEnded(containing: date) && hasAnyClosedDay(inWeekContaining: date) ? .missed : .neutral
    }

    private func hasWeekEnded(containing date: Date) -> Bool {
        !WorkoutCadence.isSameWeek(date, as: Date())
    }

    /// A week with zero closed days has no confirmed data at all — not "0
    /// runs logged," just unknown. Only mark a week missed once at least
    /// one of its days has actually been closed, mirroring the daily rows'
    /// "not closed → neutral" rule rather than treating silence as a fail.
    private func hasAnyClosedDay(inWeekContaining date: Date) -> Bool {
        checkins.contains { $0.closedAt != nil && WorkoutCadence.isSameWeek($0.date, as: date) }
    }

    // MARK: - Shared lookups

    /// "No logging or partial logging is not the complete picture" — a
    /// day's data only counts once Close Day has actually been pressed for
    /// it, same gate `HomeView` uses for its own daily-goals resolution.
    private func isClosed(on date: Date) -> Bool {
        checkins.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.closedAt != nil
    }

    private func kcal(on date: Date) -> Decimal {
        foodEntries(on: date).reduce(0) { $0 + ($1.kcal ?? 0) }
    }

    private func proteinG(on date: Date) -> Decimal {
        foodEntries(on: date).reduce(0) { $0 + ($1.proteinG ?? 0) }
    }

    private func foodEntries(on date: Date) -> [FoodEntry] {
        foodEntries.filter { Calendar.current.isDate($0.consumedAt, inSameDayAs: date) }
    }

    private func sleepLogged(on date: Date) -> Bool {
        sleepLogs.contains { Calendar.current.isDate($0.wakeTime, inSameDayAs: date) }
    }

    // MARK: - Grid geometry

    private static func makeGridDates() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let approxStart = calendar.date(byAdding: .day, value: -(weeksToShow * 7 - 1), to: today) ?? today
        let gridStart = startOfWeek(containing: approxStart, calendar: calendar)
        return (0..<(weeksToShow * 7)).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private static func startOfWeek(containing date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
}
