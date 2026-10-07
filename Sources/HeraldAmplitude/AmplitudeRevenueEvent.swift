import AmplitudeSwift
import HeraldCore

/// A purchase, in the fields Amplitude's revenue API takes.
///
/// Your events don't conform to it: your Amplitude factory builds one from your event and sends it
/// with ``RevenueAmplitudeEventTracker``.
public struct AmplitudeRevenueEvent: Event, Equatable {
    /// Not sent. Only used in failure reports.
    public let name: String

    /// Price of one item. Amplitude drops revenue without it.
    public let price: Double
    public let quantity: Int
    public let productId: String?
    public let revenueType: String?

    /// Without one, Amplitude assumes USD.
    public let currency: String?

    /// The total, when it isn't `price` times `quantity`.
    public let revenue: Double?
    public let receipt: String?
    public let receiptSig: String?

    /// Makes a purchase sent twice count once.
    public let insertId: String?
    public let parameters: [String: AnalyticsValue]

    public init(
        name: String,
        price: Double,
        quantity: Int = 1,
        productId: String? = nil,
        revenueType: String? = nil,
        currency: String? = nil,
        revenue: Double? = nil,
        receipt: String? = nil,
        receiptSig: String? = nil,
        insertId: String? = nil,
        parameters: [String: AnalyticsValue] = [:]
    ) {
        self.name = name
        self.price = price
        self.quantity = quantity
        self.productId = productId
        self.revenueType = revenueType
        self.currency = currency
        self.revenue = revenue
        self.receipt = receipt
        self.receiptSig = receiptSig
        self.insertId = insertId
        self.parameters = parameters
    }

    /// This purchase as Amplitude's `Revenue`. `insertId` isn't in it: the tracker sends it as an
    /// event option.
    func toAmplitudeRevenue() -> Revenue {
        let amplitudeRevenue = Revenue()
        amplitudeRevenue.price = price
        amplitudeRevenue.quantity = quantity
        amplitudeRevenue.productId = productId
        amplitudeRevenue.revenueType = revenueType
        amplitudeRevenue.currency = currency
        amplitudeRevenue.revenue = revenue
        amplitudeRevenue.receipt = receipt
        amplitudeRevenue.receiptSig = receiptSig
        amplitudeRevenue.properties = parameters.toAmplitudeProperties()
        return amplitudeRevenue
    }
}
