import Foundation

/// The API's decimal fields (rust_decimal) serialize as JSON strings, not numbers.
/// Swift's `Decimal: Codable` expects a JSON number, so every decimal field decodes
/// through this wrapper instead of relying on the synthesized conformance.
@propertyWrapper
struct DecimalString: Codable, Hashable {
    var wrappedValue: Decimal

    init(wrappedValue: Decimal) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = Decimal(string: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a decimal string, got \"\(raw)\""
            )
        }
        wrappedValue = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.description)
    }
}

@propertyWrapper
struct OptionalDecimalString: Codable, Hashable {
    var wrappedValue: Decimal?

    init(wrappedValue: Decimal?) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
            return
        }
        let raw = try container.decode(String.self)
        guard let value = Decimal(string: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a decimal string, got \"\(raw)\""
            )
        }
        wrappedValue = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let wrappedValue {
            try container.encode(wrappedValue.description)
        } else {
            try container.encodeNil()
        }
    }
}
