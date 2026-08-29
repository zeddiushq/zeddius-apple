import Foundation

enum APICoding {
    // Handles both ISO 8601 date-time (with fractional seconds) and plain
    // "YYYY-MM-DD" dates (e.g. `birthdate`) since the API mixes both formats
    // under the same `Date` type.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = parseDateTime(raw) {
                return date
            }
            if let date = parseDateOnly(raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date format: \(raw)"
            )
        }
        return decoder
    }()

    // Formatters are built fresh per call rather than captured from an outer
    // scope so the `@Sendable` decoding closure above doesn't hold a
    // non-Sendable `ISO8601DateFormatter`/`DateFormatter` across isolation.
    private static func parseDateTime(_ raw: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) {
            return date
        }
        let withoutFraction = ISO8601DateFormatter()
        withoutFraction.formatOptions = [.withInternetDateTime]
        return withoutFraction.date(from: raw)
    }

    private static func parseDateOnly(_ raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.date(from: raw)
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    // The shared encoder above always produces a full datetime string, which
    // a Rust `NaiveDate` field (e.g. `sleep_logs.date`) can't deserialize —
    // it needs a plain "YYYY-MM-DD". Use this for any request field typed
    // that way instead of routing it through `encoder`.
    //
    // Uses the device's local timezone, not UTC: a date-only field means
    // "which calendar day, as the user experiences it." Anchoring to UTC
    // instead silently shifted evening actions (Close Day, typically done
    // at night) onto the wrong day for anyone west of UTC — "today" at
    // 8pm Pacific is already "tomorrow" in UTC.
    static func dateOnlyString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    /// For `from`/`to` query params on endpoints whose field is a full
    /// `DateTime<Utc>` (food/sleep/workouts), not a date-only `NaiveDate` —
    /// a plain formatted string for the URL, not the JSON-body `.iso8601`
    /// encoder strategy above.
    static func iso8601String(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
