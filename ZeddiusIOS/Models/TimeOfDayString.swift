import Foundation

/// The API's `NaiveTime` fields (target_wake_time, target_bed_time) serialize
/// as `"HH:MM:SS"` strings, not JSON numbers or full dates. Decodes into
/// today's `Date` at that time-of-day so it binds directly to
/// `DatePicker(.hourAndMinute)`; only the hour/minute/second ever get read
/// back out for encoding, so which day it lands on doesn't matter.
@propertyWrapper
struct OptionalTimeString: Codable, Hashable {
    var wrappedValue: Date?

    init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
            return
        }
        let raw = try container.decode(String.self)
        guard let date = Self.parse(raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected an HH:MM:SS time string, got \"\(raw)\""
            )
        }
        wrappedValue = date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let wrappedValue {
            try container.encode(Self.format(wrappedValue))
        } else {
            try container.encodeNil()
        }
    }

    private static func parse(_ raw: String) -> Date? {
        let parts = raw.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        let second = parts.count > 2 ? parts[2] : 0
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: second, of: Date())
    }

    private static func format(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return String(format: "%02d:%02d:%02d", c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }
}
