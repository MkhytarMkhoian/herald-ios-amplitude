import HeraldCore

/// Sends events and properties to Amplitude, as its factory chains decide. The calls for one event
/// run in order, and if one fails the rest don't run. Anything no factory claims isn't sent.
///
/// ```swift
/// let tracker = AmplitudeAnalyticsTrackerService(
///     eventTrackerFactory: CompositeAmplitudeEventTrackerFactory([
///         ScreenViewAmplitudeEventTrackerFactory(amplitude: amplitude),
///         GenericAmplitudeEventTrackerFactory(amplitude: amplitude),
///     ]),
///     propertySetterFactory: GenericAmplitudePropertySetterFactory(amplitude: amplitude)
/// )
/// ```
public struct AmplitudeAnalyticsTrackerService: EventTrackerService, PropertyTrackerService {
    private let eventTrackerFactory: any AmplitudeEventTrackerFactory
    private let propertySetterFactory: any AmplitudePropertySetterFactory

    public init(
        eventTrackerFactory: any AmplitudeEventTrackerFactory,
        propertySetterFactory: any AmplitudePropertySetterFactory
    ) {
        self.eventTrackerFactory = eventTrackerFactory
        self.propertySetterFactory = propertySetterFactory
    }

    public func track(_ event: any Event) {
        do {
            for tracker in try eventTrackerFactory.create(event).handlers() {
                try tracker.track()
            }
        } catch {
            Herald.reportFailure(error)
        }
    }

    public func set(_ property: any Property) {
        do {
            for setter in try propertySetterFactory.create(property).handlers() {
                try setter.set()
            }
        } catch {
            Herald.reportFailure(error)
        }
    }
}
