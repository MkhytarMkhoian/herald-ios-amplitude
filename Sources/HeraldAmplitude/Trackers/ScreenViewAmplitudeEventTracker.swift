import AmplitudeSwift
import HeraldCore

/// Tracks `event` as Amplitude's own `[Amplitude] Screen Viewed`, with its name as
/// `[Amplitude] Screen Name`.
///
/// Keep Amplitude's own screen-view capture off: leave `.screenViews` out of the configuration's
/// `autocapture`, as it is by default. Otherwise every screen is counted twice.
///
/// Throws if the event has its own `[Amplitude] Screen Name` parameter, because it would replace
/// the screen's name.
public struct ScreenViewAmplitudeEventTracker: AmplitudeEventTracker {
    private let event: any ScreenViewEvent
    private let sdk: any AmplitudeSDK

    public init(event: any ScreenViewEvent, amplitude: Amplitude) {
        self.init(event: event, sdk: LiveAmplitudeSDK(instance: amplitude))
    }

    init(event: any ScreenViewEvent, sdk: any AmplitudeSDK) {
        self.event = event
        self.sdk = sdk
    }

    public func track() throws {
        var properties = amplitudeProperties(event.parameters)
        if properties["[Amplitude] Screen Name"] != nil {
            throw AmplitudeRefusal(
                description: "Screen view '\(event.name)' can't have an '[Amplitude] Screen Name' "
                    + "parameter: it holds the screen's name.")
        }
        properties["[Amplitude] Screen Name"] = event.name
        sdk.track(eventType: "[Amplitude] Screen Viewed", eventProperties: properties)
    }
}
