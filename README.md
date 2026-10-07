# Herald for Amplitude

Sends [Herald](https://github.com/MkhytarMkhoian/herald-ios) events, user properties and revenue to
Amplitude, over [`Amplitude-Swift`](https://github.com/amplitude/Amplitude-Swift).

## Install

In Xcode, File → Add Package Dependencies, and add both packages:

- `https://github.com/MkhytarMkhoian/herald-ios`, for `HeraldCore`;
- `https://github.com/MkhytarMkhoian/herald-ios-amplitude`, for `HeraldAmplitude`.

It works with `Amplitude-Swift` 1.12 or newer, and needs iOS 15 or newer. All Herald for iOS
packages share one version, so use the same one for `herald-ios`.

## Set up

Create Amplitude as usual, then hand it to Herald's factories and service:

```swift
import AmplitudeSwift
import HeraldAmplitude
import HeraldCore

let amplitude = Amplitude(configuration: Configuration(apiKey: "<api key>", optOut: true))

let tracker = AmplitudeAnalyticsTrackerService(
    eventTrackerFactory: CompositeAmplitudeEventTrackerFactory([
        ScreenViewAmplitudeEventTrackerFactory(amplitude: amplitude),
        GenericAmplitudeEventTrackerFactory(amplitude: amplitude),
    ]),
    propertySetterFactory: GenericAmplitudePropertySetterFactory(amplitude: amplitude)
)
let service = AmplitudeAnalyticsService(amplitude: amplitude)

let provider = HeraldProvider(
    name: "amplitude",
    events: tracker,
    properties: tracker,
    identity: service,
    lifecycle: service,
    consent: service
)
```

| Herald | Amplitude |
| --- | --- |
| an event | `track(eventType:eventProperties:)`, with each value as its own type |
| a `ScreenViewEvent` | `[Amplitude] Screen Viewed`, with the event's name as `[Amplitude] Screen Name` |
| a property, including a `UserProperty` | a user property, through `identify` |
| an `AmplitudeRevenueEvent` | `revenue`, with its `insertId` as an event option |
| `identify` / `reset` | `setUserId` / `reset()`, which also changes the device id |
| `flush` | `flush()` |
| `setEnabled` | the configuration's `optOut` |

A screen view with its own `[Amplitude] Screen Name` parameter is refused and sent to Herald's
error reporter, because it would replace the screen's name. Keep Amplitude's own screen-view
capture off: leave `.screenViews` out of `autocapture`, as it is by default.

**Consent.** Amplitude collects from the moment it's created and forgets an opt-out between
launches. Create it with `optOut: true`, and call `setEnabled` with the user's stored answer on
every launch.

## Revenue

Your events don't conform to Amplitude's revenue type. A factory of your own builds an
`AmplitudeRevenueEvent` from your event, and goes before the generic factory:

```swift
@preconcurrency import AmplitudeSwift
import HeraldAmplitude
import HeraldCore

struct PurchaseAmplitudeEventTrackerFactory: AmplitudeEventTrackerFactory {
    let amplitude: Amplitude

    func create(_ event: any Event) -> Resolution<any AmplitudeEventTracker> {
        guard let purchase = event as? PurchaseCompleted else {
            return .declined
        }
        let revenue = AmplitudeRevenueEvent(
            name: purchase.name, price: purchase.price, productId: purchase.productId,
            currency: purchase.currency, insertId: purchase.orderId)
        return .claimed([RevenueAmplitudeEventTracker(event: revenue, amplitude: amplitude)])
    }
}
```

## Two Swift notes

- **`@preconcurrency import AmplitudeSwift`** in a file whose factory stores your `Amplitude`, as
  above. Amplitude isn't marked `Sendable`, so Swift 6 refuses it otherwise; Xcode offers this fix.
- **`HeraldCore.Identity`.** Amplitude has an `Identity` type too, so in a file that imports both
  modules, write `HeraldCore.Identity(userId: id)`.

## Documentation

The [Herald website](https://mkhytarmkhoian.github.io/herald-docs/) has the guides.

## License

Apache License 2.0. See [LICENSE](LICENSE).
