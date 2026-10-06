import HeraldCore

/// Fails for any event that reaches it, so the error reporter shows events nobody mapped. Put it
/// last in a chain.
public struct RequireMappedAmplitudeEventTrackerFactory: AmplitudeEventTrackerFactory,
    FallbackFactory
{
    public init() {}

    public func create(_ event: any Event) throws -> Resolution<any AmplitudeEventTracker> {
        throw UnhandledEventError(event: event)
    }
}

public struct RequireMappedAmplitudePropertySetterFactory: AmplitudePropertySetterFactory,
    FallbackFactory
{
    public init() {}

    public func create(_ property: any Property) throws -> Resolution<any AmplitudePropertySetter> {
        throw UnhandledPropertyError(property: property)
    }
}
