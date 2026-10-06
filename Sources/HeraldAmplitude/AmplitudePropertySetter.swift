/// One call to Amplitude for one property. A factory builds it.
public protocol AmplitudePropertySetter {
    func set() throws
}
