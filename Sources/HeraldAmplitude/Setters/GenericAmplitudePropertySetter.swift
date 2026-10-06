import AmplitudeSwift
import HeraldCore

/// Sets `property` as an Amplitude user property, with its type.
public struct GenericAmplitudePropertySetter: AmplitudePropertySetter {
    private let property: any Property
    private let sdk: any AmplitudeSDK

    public init(property: any Property, amplitude: Amplitude) {
        self.init(property: property, sdk: LiveAmplitudeSDK(instance: amplitude))
    }

    init(property: any Property, sdk: any AmplitudeSDK) {
        self.property = property
        self.sdk = sdk
    }

    public func set() {
        sdk.setUserProperty(property.name, value: amplitudeValue(property.value))
    }
}
