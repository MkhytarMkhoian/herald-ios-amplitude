import HeraldCore

/// Decides what Amplitude gets for an event: `claimed` with the calls to make, `dropped` to send
/// nothing, or `declined` to let the next factory decide.
///
/// A factory of your own that stores your `Amplitude` needs `@preconcurrency import AmplitudeSwift`
/// in Swift 6, because Amplitude isn't marked `Sendable`. Xcode offers the fix.
public protocol AmplitudeEventTrackerFactory: Sendable {
    func create(_ event: any Event) throws -> Resolution<any AmplitudeEventTracker>
}

/// Asks each factory in order and uses the first answer that isn't `declined`. If all decline,
/// nothing is sent. Stops the app if a ``FallbackFactory`` isn't last.
public struct CompositeAmplitudeEventTrackerFactory: AmplitudeEventTrackerFactory {
    private let factories: [any AmplitudeEventTrackerFactory]

    public init(_ factories: [any AmplitudeEventTrackerFactory]) {
        requireFallbackLast(factories)
        self.factories = factories
    }

    public func create(_ event: any Event) throws -> Resolution<any AmplitudeEventTracker> {
        try Resolution.firstOf(factories) { factory in try factory.create(event) }
    }
}
