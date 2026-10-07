import AmplitudeSwift
import Foundation
import HeraldCore

@testable import HeraldAmplitude

struct TestEvent: Event {
    let name: String
    var parameters: [String: AnalyticsValue] = [:]
}

struct TestScreenView: ScreenViewEvent {
    let name: String
    var parameters: [String: AnalyticsValue] = [:]
}

struct TestProperty: Property {
    let name: String
    let value: AnalyticsValue
}

/// Records the Amplitude calls instead of making them, each as one line that shows every value's
/// type, like `track checkout seats=Int(3)`. Locked, so any thread can call it: hence
/// `@unchecked Sendable`.
final class RecordingAmplitudeSDK: AmplitudeSDK, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []

    var calls: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func track(eventType: String, eventProperties: [String: Any]) {
        record("track \(eventType)\(formattedValues(eventProperties))")
    }

    func setUserProperty(_ property: String, value: Any) {
        record("identify \(property)=\(type(of: value))(\(value))")
    }

    func revenue(_ revenue: Revenue, insertId: String?) {
        var line = "revenue price=\(text(revenue.price)) quantity=\(revenue.quantity)"
        line += " productId=\(text(revenue.productId)) revenueType=\(text(revenue.revenueType))"
        line += " currency=\(text(revenue.currency)) revenue=\(text(revenue.revenue))"
        line += " receipt=\(text(revenue.receipt)) receiptSig=\(text(revenue.receiptSig))"
        line += " insertId=\(text(insertId))\(formattedValues(revenue.properties ?? [:]))"
        record(line)
    }

    func setUserId(_ userId: String?) { record("setUserId \(userId ?? "nil")") }

    func reset() { record("reset") }

    func flush() { record("flush") }

    func setOptOut(_ optOut: Bool) { record("optOut \(optOut)") }

    /// The value, or `nil` when there is none.
    private func text(_ value: Any?) -> String {
        if let value {
            return "\(value)"
        }
        return "nil"
    }

    private func formattedValues(_ properties: [String: Any]) -> String {
        var text = ""
        for key in properties.keys.sorted() {
            let value = properties[key]!
            text += " \(key)=\(type(of: value))(\(value))"
        }
        return text
    }

    private func record(_ line: String) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(line)
    }
}

/// What Herald sent to its error reporter. Locked like ``RecordingAmplitudeSDK``.
final class ReportedFailures: @unchecked Sendable {
    private let lock = NSLock()
    private var failures: [AnalyticsFailure] = []

    var all: [AnalyticsFailure] {
        lock.lock()
        defer { lock.unlock() }
        return failures
    }

    func append(_ failure: AnalyticsFailure) {
        lock.lock()
        defer { lock.unlock() }
        failures.append(failure)
    }
}
