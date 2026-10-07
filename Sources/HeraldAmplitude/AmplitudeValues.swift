import HeraldCore

/// Amplitude takes text, numbers and booleans as themselves, so every value keeps its type.
func amplitudeValue(_ value: AnalyticsValue) -> Any {
    switch value {
    case .string(let text):
        return text
    case .int(let number):
        return number
    case .double(let number):
        return number
    case .bool(let flag):
        return flag
    }
}

extension [String: AnalyticsValue] {
    /// The parameters as Amplitude takes them, each value as its own type. For a tracker of your
    /// own: `amplitude.track(eventType: "refund", eventProperties: ...)`.
    public func toAmplitudeProperties() -> [String: Any] {
        var properties: [String: Any] = [:]
        for (key, value) in self {
            properties[key] = amplitudeValue(value)
        }
        return properties
    }
}

/// Why this module refused an event: it says what to change.
struct AmplitudeRefusal: Error, CustomStringConvertible {
    let description: String
}
