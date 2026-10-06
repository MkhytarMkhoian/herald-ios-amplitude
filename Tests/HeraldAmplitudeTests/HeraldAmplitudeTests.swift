import HeraldCore
import Testing

@testable import HeraldAmplitude

@Suite struct Trackers {
    let amplitude = RecordingAmplitudeSDK()

    @Test func theGenericTrackerSendsTheEventUnderItsOwnNameWithTypedProperties() {
        let event = TestEvent(
            name: "checkout_started",
            parameters: [
                "plan": .string("pro"), "seats": .int(3), "price": .double(9.99),
                "trial": .bool(false),
            ])

        GenericAmplitudeEventTracker(event: event, sdk: amplitude).track()

        #expect(
            amplitude.calls == [
                "track checkout_started plan=String(pro) price=Double(9.99) seats=Int(3) "
                    + "trial=Bool(false)"
            ])
    }

    @Test func aScreenViewIsAmplitudesOwnWithItsNameAsTheScreenName() throws {
        let screen = TestScreenView(name: "checkout", parameters: ["source": .string("cart")])

        try ScreenViewAmplitudeEventTracker(event: screen, sdk: amplitude).track()

        #expect(
            amplitude.calls == [
                "track [Amplitude] Screen Viewed [Amplitude] Screen Name=String(checkout) "
                    + "source=String(cart)"
            ])
    }

    @Test func aScreenViewWithItsOwnScreenNameParameterIsRefusedAndNothingIsSent() {
        let screen = TestScreenView(
            name: "checkout", parameters: ["[Amplitude] Screen Name": .string("other")])

        #expect {
            try ScreenViewAmplitudeEventTracker(event: screen, sdk: amplitude).track()
        } throws: { error in
            "\(error)".contains("can't have an '[Amplitude] Screen Name' parameter")
        }
        #expect(amplitude.calls.isEmpty)
    }

    @Test func aPropertyIsSetThroughIdentifyWithItsType() {
        GenericAmplitudePropertySetter(
            property: TestProperty(name: "seats", value: .int(3)), sdk: amplitude
        ).set()

        #expect(amplitude.calls == ["identify seats=Int(3)"])
    }
}

/// A purchase, as an app describes it.
private struct PurchaseCompleted: Event {
    let productId: String
    let price: Double

    var name: String { "purchase_completed" }
    var parameters: [String: AnalyticsValue] { ["product_id": .string(productId)] }
}

/// Sends `PurchaseCompleted` as Amplitude revenue, and declines everything else.
private struct PurchaseAmplitudeEventTrackerFactory: AmplitudeEventTrackerFactory {
    let sdk: any AmplitudeSDK

    func create(_ event: any Event) -> Resolution<any AmplitudeEventTracker> {
        guard let purchase = event as? PurchaseCompleted else {
            return .declined
        }
        let revenue = AmplitudeRevenueEvent(
            name: purchase.name, price: purchase.price, productId: purchase.productId,
            currency: "EUR", insertId: "order-1")
        return .claimed([RevenueAmplitudeEventTracker(event: revenue, sdk: sdk)])
    }
}

@Suite struct RevenueEvents {
    let amplitude = RecordingAmplitudeSDK()

    @Test func everyFieldReachesAmplitudeAndTheInsertIdTravelsAsAnEventOption() {
        let event = AmplitudeRevenueEvent(
            name: "purchase", price: 4.99, quantity: 2, productId: "pro_monthly",
            revenueType: "subscription", currency: "EUR", revenue: 9.98, receipt: "r",
            receiptSig: "s", insertId: "order-1", parameters: ["source": .string("paywall")])

        RevenueAmplitudeEventTracker(event: event, sdk: amplitude).track()

        #expect(
            amplitude.calls == [
                "revenue price=4.99 quantity=2 productId=pro_monthly revenueType=subscription "
                    + "currency=EUR revenue=9.98 receipt=r receiptSig=s insertId=order-1 "
                    + "source=String(paywall)"
            ])
    }

    @Test func withoutAnInsertIdNoneIsSent() {
        let event = AmplitudeRevenueEvent(name: "purchase", price: 4.99)

        RevenueAmplitudeEventTracker(event: event, sdk: amplitude).track()

        #expect(amplitude.calls.first?.contains("quantity=1") == true)
        #expect(amplitude.calls.first?.contains("insertId=nil") == true)
    }

    @Test func revenueEventsAreEqualByValue() {
        #expect(
            AmplitudeRevenueEvent(name: "purchase", price: 1, parameters: ["a": .int(1)])
                == AmplitudeRevenueEvent(name: "purchase", price: 1, parameters: ["a": .int(1)]))
        #expect(
            AmplitudeRevenueEvent(name: "purchase", price: 1)
                != AmplitudeRevenueEvent(name: "purchase", price: 2))
    }

    @Test func aCustomFactorySendsAppEventsAsRevenueBeforeTheGenericFactory() {
        let tracker = AmplitudeAnalyticsTrackerService(
            eventTrackerFactory: CompositeAmplitudeEventTrackerFactory([
                PurchaseAmplitudeEventTrackerFactory(sdk: amplitude),
                GenericAmplitudeEventTrackerFactory(sdk: amplitude),
            ]),
            propertySetterFactory: GenericAmplitudePropertySetterFactory(sdk: amplitude)
        )
        let herald = Herald(providers: [HeraldProvider(name: "amplitude", events: tracker)])

        herald.track(PurchaseCompleted(productId: "pro_monthly", price: 4.99))
        herald.track(TestEvent(name: "cart_viewed"))

        #expect(amplitude.calls.count == 2)
        #expect(amplitude.calls.first?.hasPrefix("revenue price=4.99") == true)
        #expect(amplitude.calls.last == "track cart_viewed")
    }
}

@Suite struct Factories {
    let amplitude = RecordingAmplitudeSDK()

    @Test func theScreenViewFactoryClaimsScreenViewsOnly() throws {
        let factory = ScreenViewAmplitudeEventTrackerFactory(sdk: amplitude)

        #expect(
            try factory.create(TestScreenView(name: "home")).handlers().first
                is ScreenViewAmplitudeEventTracker)
        #expect(try factory.create(TestEvent(name: "cart_viewed")).handlers().isEmpty)
    }

    @Test func aChainEndingInRequireMappedReportsAnUnclaimedEventThroughHerald() throws {
        let failures = ReportedFailures()
        let tracker = AmplitudeAnalyticsTrackerService(
            eventTrackerFactory: CompositeAmplitudeEventTrackerFactory([
                ScreenViewAmplitudeEventTrackerFactory(sdk: amplitude),
                RequireMappedAmplitudeEventTrackerFactory(),
            ]),
            propertySetterFactory: RequireMappedAmplitudePropertySetterFactory()
        )
        let herald = Herald(
            providers: [HeraldProvider(name: "amplitude", events: tracker, properties: tracker)],
            errorReporter: { failure in failures.append(failure) }
        )

        herald.track(TestEvent(name: "checkout_started"))
        herald.set(TestProperty(name: "plan", value: .string("pro")))

        #expect(amplitude.calls.isEmpty)
        let failure = try #require(failures.all.first)
        #expect(failure.operation == .track(eventName: "checkout_started"))
        #expect(failure.error is UnhandledEventError)
        #expect(failures.all.last?.error is UnhandledPropertyError)
    }

    @Test func aRefusedScreenViewIsReportedThroughHerald() throws {
        let failures = ReportedFailures()
        let tracker = AmplitudeAnalyticsTrackerService(
            eventTrackerFactory: ScreenViewAmplitudeEventTrackerFactory(sdk: amplitude),
            propertySetterFactory: GenericAmplitudePropertySetterFactory(sdk: amplitude)
        )
        let herald = Herald(
            providers: [HeraldProvider(name: "amplitude", events: tracker)],
            errorReporter: { failure in failures.append(failure) }
        )

        herald.track(
            TestScreenView(name: "home", parameters: ["[Amplitude] Screen Name": .string("x")]))

        let failure = try #require(failures.all.first)
        #expect("\(failure)".hasPrefix("amplitude failed on Track(home): Screen view 'home'"))
    }
}

@Suite struct Service {
    let amplitude = RecordingAmplitudeSDK()

    @Test func startTouchesNothingSinceAmplitudeStartsWhenCreated() {
        AmplitudeAnalyticsService(sdk: amplitude).start()

        #expect(amplitude.calls.isEmpty)
    }

    @Test func consentMapsOntoTheOptOut() {
        let service = AmplitudeAnalyticsService(sdk: amplitude)

        service.setEnabled(true)
        service.setEnabled(false)

        #expect(amplitude.calls == ["optOut false", "optOut true"])
    }

    @Test func identifyResetAndFlushReachAmplitude() {
        let service = AmplitudeAnalyticsService(sdk: amplitude)

        service.identify(HeraldCore.Identity(userId: "user-1"))
        service.reset()
        service.flush()

        #expect(amplitude.calls == ["setUserId user-1", "reset", "flush"])
    }
}
