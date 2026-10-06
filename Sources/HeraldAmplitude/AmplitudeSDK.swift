import AmplitudeSwift

/// The Amplitude calls this module makes, so the tests can record them instead:
/// ``LiveAmplitudeSDK`` in the app, a recorder in the tests.
protocol AmplitudeSDK: Sendable {
    func track(eventType: String, eventProperties: [String: Any])
    func setUserProperty(_ property: String, value: Any)
    func revenue(_ revenue: Revenue, insertId: String?)
    func setUserId(_ userId: String?)
    func reset()
    func flush()
    func setOptOut(_ optOut: Bool)
}

/// Passes each call to the app's `Amplitude`.
///
/// Amplitude does its work on its own queue and is safe to call from any thread, but it isn't
/// marked `Sendable`: hence `@unchecked Sendable`.
struct LiveAmplitudeSDK: AmplitudeSDK, @unchecked Sendable {
    let instance: Amplitude

    func track(eventType: String, eventProperties: [String: Any]) {
        instance.track(eventType: eventType, eventProperties: eventProperties)
    }

    func setUserProperty(_ property: String, value: Any) {
        instance.identify(identify: Identify().set(property: property, value: value))
    }

    func revenue(_ revenue: Revenue, insertId: String?) {
        var options: EventOptions?
        if let insertId {
            options = EventOptions(insertId: insertId)
        }
        instance.revenue(revenue: revenue, options: options)
    }

    func setUserId(_ userId: String?) {
        instance.setUserId(userId: userId)
    }

    func reset() {
        instance.reset()
    }

    func flush() {
        instance.flush()
    }

    func setOptOut(_ optOut: Bool) {
        instance.configuration.optOut = optOut
    }
}
