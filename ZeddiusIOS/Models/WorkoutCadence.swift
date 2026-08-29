import Foundation

/// Shared weekly-cadence rules for runs/lifts — used by both `HomeModel`
/// (today's/selected day's week) and `HistoryModel` (every week in the
/// history graph), so the qualifying-run thresholds can't drift between them.
enum WorkoutCadence {
    static let metersPerMile = Decimal(1609.344)
    static let qualifyingRunMinDurationSeconds = 1200 // 20 minutes

    static func qualifiesAsRun(_ workout: Workout) -> Bool {
        guard let session = workout.runSession else { return false }
        let meetsDistance = session.distanceMeters >= 2 * metersPerMile
        let meetsDuration = session.durationSeconds >= qualifyingRunMinDurationSeconds
        return meetsDistance || meetsDuration
    }

    static func isWeekday(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date) // 1 = Sun ... 7 = Sat
        return weekday >= 2 && weekday <= 6
    }

    static func isSameWeek(_ date: Date, as reference: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: reference, toGranularity: .weekOfYear)
    }
}
