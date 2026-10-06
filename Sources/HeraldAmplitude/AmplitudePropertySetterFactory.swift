import HeraldCore

public protocol AmplitudePropertySetterFactory: Sendable {
    func create(_ property: any Property) throws -> Resolution<any AmplitudePropertySetter>
}

/// Asks each factory in order and uses the first answer that isn't `declined`. If all decline,
/// nothing is sent. Stops the app if a ``FallbackFactory`` isn't last.
public struct CompositeAmplitudePropertySetterFactory: AmplitudePropertySetterFactory {
    private let factories: [any AmplitudePropertySetterFactory]

    public init(_ factories: [any AmplitudePropertySetterFactory]) {
        requireFallbackLast(factories)
        self.factories = factories
    }

    public func create(_ property: any Property) throws -> Resolution<any AmplitudePropertySetter> {
        try Resolution.firstOf(factories) { factory in try factory.create(property) }
    }
}
