import Foundation
import Observation

@Observable
@MainActor
final class HomeModel {
    private(set) var user: User?
    private(set) var weightLogs: [WeightLog] = []
    private(set) var sleepLogs: [SleepLog] = []
    private(set) var foodEntries: [FoodEntry] = []
    private(set) var workouts: [Workout] = []
    private(set) var tasks: [DailyTask] = []
    private(set) var taskCompletions: [TaskCompletion] = []
    private(set) var checkins: [DailyCheckin] = []
    private(set) var isLoading = false
    private(set) var hasLoadedOnce = false
    var errorMessage: String?

    private let api: APIClient

    /// How far back task completions / check-ins are fetched. Everything
    /// else (weight/sleep/food/workouts) relies on each endpoint's own
    /// default range; this just needs to comfortably cover "browse back a
    /// few weeks," which is all Home's day navigation needs — one fetch,
    /// then every day-to-day move is local filtering, same as
    /// FoodEntryListView's day/week browsing.
    private static let historyWindowDays = 90

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

        let today = Date()
        let windowStart = Calendar.current.date(byAdding: .day, value: -Self.historyWindowDays, to: today) ?? today

        do {
            async let weightsTask = api.getWeightLogs()
            async let sleepsTask = api.getSleepLogs()
            async let foodsTask = api.getFoodEntries()
            async let workoutsTask = api.getWorkouts()
            async let userTask = api.getMe()
            async let tasksTask = api.getTasks()
            async let completionsTask = api.getTaskCompletions(from: windowStart, to: today)
            async let checkinsTask = api.getDailyCheckins(from: windowStart, to: today)

            weightLogs = try await weightsTask
            sleepLogs = try await sleepsTask
            foodEntries = try await foodsTask
            workouts = try await workoutsTask
            user = try await userTask
            tasks = try await tasksTask
            taskCompletions = try await completionsTask
            checkins = try await checkinsTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Nutrition

    func kcal(on date: Date) -> Decimal {
        foodEntries(on: date).reduce(0) { $0 + ($1.kcal ?? 0) }
    }

    func proteinG(on date: Date) -> Decimal {
        foodEntries(on: date).reduce(0) { $0 + ($1.proteinG ?? 0) }
    }

    private func foodEntries(on date: Date) -> [FoodEntry] {
        foodEntries.filter { Calendar.current.isDate($0.consumedAt, inSameDayAs: date) }
    }

    // MARK: - Sleep / weight logged

    func weightLogged(on date: Date) -> Bool {
        weightLogs.contains { Calendar.current.isDate($0.recordedAt, inSameDayAs: date) }
    }

    /// The sleep log a user would think of as "date's" — the one whose
    /// wake time falls on that day, matching how they'd actually log it.
    func sleepLog(on date: Date) -> SleepLog? {
        sleepLogs.first { Calendar.current.isDate($0.wakeTime, inSameDayAs: date) }
    }

    func sleepLogged(on date: Date) -> Bool { sleepLog(on: date) != nil }

    /// nil when there's no target set, or no sleep logged yet to compare.
    func wakeTimeMet(on date: Date) -> Bool? {
        guard let target = user?.targetWakeTime, let sleep = sleepLog(on: date) else { return nil }
        return Self.isTimeOfDay(sleep.wakeTime, onOrBefore: target)
    }

    /// The sleep log whose *bedtime* falls on `date`'s evening — that's
    /// recorded as the FOLLOWING day's log (its wake time is the next
    /// morning). Only meaningful for a past `date`, where that night has
    /// already happened and can be judged — "today" gets a forward-looking
    /// reminder instead, not a retrospective check, since tonight hasn't
    /// happened yet.
    func sleepLog(forNightOf date: Date) -> SleepLog? {
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) else { return nil }
        return sleepLog(on: nextDay)
    }

    func bedTimeMet(forNightOf date: Date) -> Bool? {
        guard let target = user?.targetBedTime, let sleep = sleepLog(forNightOf: date) else { return nil }
        return Self.isTimeOfDay(sleep.bedTime, onOrBefore: target)
    }

    // MARK: - Weekly run/lift cadence

    func weeklyRunCount(containing date: Date) -> Int {
        workouts.filter { workout in
            WorkoutType.isRunType(workout.type) && WorkoutCadence.isWeekday(workout.startedAt)
                && WorkoutCadence.isSameWeek(workout.startedAt, as: date) && WorkoutCadence.qualifiesAsRun(workout)
        }.count
    }

    func weeklyLiftCount(containing date: Date) -> Int {
        workouts.filter { WorkoutType.isLiftType($0.type) && WorkoutCadence.isSameWeek($0.startedAt, as: date) }.count
    }

    /// Time-of-day-only comparison, ignoring calendar date — target_wake_time
    /// / target_bed_time carry no date. Bed times routinely cross midnight
    /// (bed at 1am is later than an 11:30pm target, not earlier) — if the
    /// target is in the evening (PM) but the actual time is early morning
    /// (AM), treat the actual time as having rolled into the next day
    /// before comparing.
    private static func isTimeOfDay(_ actual: Date, onOrBefore target: Date) -> Bool {
        let targetSeconds = secondsSinceMidnight(target)
        var actualSeconds = secondsSinceMidnight(actual)
        if targetSeconds >= 12 * 3600 && actualSeconds < 12 * 3600 {
            actualSeconds += 24 * 3600
        }
        return actualSeconds <= targetSeconds
    }

    private static func secondsSinceMidnight(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return (c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60 + (c.second ?? 0)
    }

    // MARK: - Tasks

    func isTaskCompleted(_ task: DailyTask, on date: Date) -> Bool {
        taskCompletions.contains { $0.taskId == task.id && Calendar.current.isDate($0.completedDate, inSameDayAs: date) }
    }

    func completionsInWeek(_ task: DailyTask, containing date: Date) -> Int {
        taskCompletions
            .filter { $0.taskId == task.id && WorkoutCadence.isSameWeek($0.completedDate, as: date) }
            .count
    }

    func toggleTask(_ task: DailyTask, on date: Date) async {
        errorMessage = nil
        do {
            if isTaskCompleted(task, on: date) {
                try await api.uncompleteTask(id: task.id, date: date)
                taskCompletions.removeAll { $0.taskId == task.id && Calendar.current.isDate($0.completedDate, inSameDayAs: date) }
            } else {
                try await api.completeTask(id: task.id, date: date)
                taskCompletions.append(TaskCompletion(taskId: task.id, completedDate: date))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Close Day

    func checkin(for date: Date) -> DailyCheckin? {
        checkins.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// The focus decided the day before `date` — what `date`'s "today's
    /// focus" section shows.
    func focusSetForDay(_ date: Date) -> String? {
        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: date) else { return nil }
        return checkin(for: previousDay)?.tomorrowFocus
    }

    private func replaceCheckin(_ checkin: DailyCheckin) {
        if let index = checkins.firstIndex(where: { $0.id == checkin.id }) {
            checkins[index] = checkin
        } else {
            checkins.append(checkin)
        }
    }

    func saveTomorrowFocus(_ text: String?, for date: Date) async -> Bool {
        errorMessage = nil
        do {
            let dateString = APICoding.dateOnlyString(from: date)
            let checkin = try await api.upsertDailyCheckin(
                UpsertDailyCheckinRequest(date: dateString, tomorrowFocus: text)
            )
            replaceCheckin(checkin)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func closeDay(_ date: Date) async -> Bool {
        errorMessage = nil
        do {
            replaceCheckin(try await api.closeDay(date: date))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reopenDay(_ date: Date) async -> Bool {
        errorMessage = nil
        do {
            replaceCheckin(try await api.reopenDay(date: date))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
