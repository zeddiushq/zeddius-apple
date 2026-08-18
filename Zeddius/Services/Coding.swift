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
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: raw)
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
