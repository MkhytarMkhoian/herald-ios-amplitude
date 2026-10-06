import AmplitudeSwift
import HeraldCore

/// Tracks any event under its own name, with its parameters. Claims every event, so it goes last
/// in a chain.
public struct GenericAmplitudeEventTrackerFactory: AmplitudeEventTrackerFactory, FallbackFactory {
    private let sdk: any AmplitudeSDK

    public init(amplitude: Amplitude) {
        self.init(sdk: LiveAmplitudeSDK(instance: amplitude))
    }

    init(sdk: any AmplitudeSDK) {
        self.sdk = sdk
    }

    public func create(_ event: any Event) -> Resolution<any AmplitudeEventTracker> {
        .claimed([GenericAmplitudeEventTracker(event: event, sdk: sdk)])
    }
}

/// Claims every ``ScreenViewEvent`` as `[Amplitude] Screen Viewed` and declines everything else. To
/// send screen views differently, put your own factory before this one.
public struct ScreenViewAmplitudeEventTrackerFactory: AmplitudeEventTrackerFactory {
    private let sdk: any AmplitudeSDK

    public init(amplitude: Amplitude) {
        self.init(sdk: LiveAmplitudeSDK(instance: amplitude))
    }

    init(sdk: any AmplitudeSDK) {
        self.sdk = sdk
    }

    public func create(_ event: any Event) -> Resolution<any AmplitudeEventTracker> {
        if let screenView = event as? any ScreenViewEvent {
            return .claimed([ScreenViewAmplitudeEventTracker(event: screenView, sdk: sdk)])
        }
        return .declined
    }
}

/// Sets any property as an Amplitude user property, ``UserProperty`` included: Amplitude has one
/// kind of property. Claims every property, so it goes last in a chain.
public struct GenericAmplitudePropertySetterFactory: AmplitudePropertySetterFactory,
    FallbackFactory
{
    private let sdk: any AmplitudeSDK

    public init(amplitude: Amplitude) {
        self.init(sdk: LiveAmplitudeSDK(instance: amplitude))
    }

    init(sdk: any AmplitudeSDK) {
        self.sdk = sdk
    }

    public func create(_ property: any Property) -> Resolution<any AmplitudePropertySetter> {
        .claimed([GenericAmplitudePropertySetter(property: property, sdk: sdk)])
    }
}
