import AmplitudeSwift
import HeraldCore

/// Amplitude's lifecycle, identity and consent, over the `Amplitude` the app has created.
///
/// Amplitude collects from the moment it's created. Create it with `optOut: true` in its
/// configuration so nothing is sent before the user answers. Amplitude forgets the opt-out between
/// launches, so call `setEnabled` with the stored answer on every launch.
public struct AmplitudeAnalyticsService: AnalyticsLifecycleService, IdentifiableUserService,
    ConsentService
{
    private let sdk: any AmplitudeSDK

    public init(amplitude: Amplitude) {
        self.init(sdk: LiveAmplitudeSDK(instance: amplitude))
    }

    init(sdk: any AmplitudeSDK) {
        self.sdk = sdk
    }

    /// Amplitude starts itself when it's created, so there is nothing to do.
    public func start() {}

    public func flush() {
        sdk.flush()
    }

    public func setEnabled(_ enabled: Bool) {
        sdk.setOptOut(!enabled)
    }

    public func identify(_ identity: HeraldCore.Identity) {
        sdk.setUserId(identity.userId)
    }

    /// Clears the user id and also changes the device id, so the next user isn't linked to the last
    /// one.
    public func reset() {
        sdk.reset()
    }
}
