import AmplitudeSwift
import HeraldCore

public struct GenericAmplitudeEventTracker: AmplitudeEventTracker {
    private let event: any Event
    private let sdk: any AmplitudeSDK

    public init(event: any Event, amplitude: Amplitude) {
        self.init(event: event, sdk: LiveAmplitudeSDK(instance: amplitude))
    }

    init(event: any Event, sdk: any AmplitudeSDK) {
        self.event = event
        self.sdk = sdk
    }

    public func track() {
        sdk.track(eventType: event.name, eventProperties: event.parameters.toAmplitudeProperties())
    }
}
