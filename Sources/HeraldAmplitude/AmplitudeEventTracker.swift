/// One call to Amplitude for one event. A factory builds it.
public protocol AmplitudeEventTracker {
    func track() throws
}
