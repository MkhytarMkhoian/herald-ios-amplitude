import AmplitudeSwift
import HeraldCore

/// Sends `event` through Amplitude's revenue API. Its `insertId` goes as an event option, since
/// Amplitude's revenue type has no field for it.
public struct RevenueAmplitudeEventTracker: AmplitudeEventTracker {
    private let event: AmplitudeRevenueEvent
    private let sdk: any AmplitudeSDK

    public init(event: AmplitudeRevenueEvent, amplitude: Amplitude) {
        self.init(event: event, sdk: LiveAmplitudeSDK(instance: amplitude))
    }

    init(event: AmplitudeRevenueEvent, sdk: any AmplitudeSDK) {
        self.event = event
        self.sdk = sdk
    }

    public func track() {
        sdk.revenue(event.toAmplitudeRevenue(), insertId: event.insertId)
    }
}
