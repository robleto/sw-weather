import Foundation

/// The signals this app sends, and the only ones it sends.
///
/// Names and payload keys are fixed by `shared/analytics-signals.json`, which
/// the web app is held to as well — `AnalyticsTests` asserts this file against
/// it, and `analytics.test.ts` asserts the TypeScript port against the same
/// fixture. Two vocabularies in one dashboard is worse than no analytics: the
/// numbers look comparable and aren't.
///
/// Deliberately free of any TelemetryDeck import, so the contract stays
/// testable without the SDK and the vendor coupling lives in exactly one file
/// (`Analytics.swift`).
enum AnalyticsSignal {
    static let appLaunched = "App.launched"
    static let forecastLanded = "Forecast.landed"
    static let atlasOpened = "Atlas.opened"
    static let atlasWorldAssigned = "Atlas.worldAssigned"
    static let passportStampEarned = "Passport.stampEarned"
    /// iOS only — the web app has no premium tier.
    static let premiumPaywallShown = "Premium.paywallShown"

    /// Every signal name, for the parity test.
    static let all: [String] = [
        appLaunched,
        forecastLanded,
        atlasOpened,
        atlasWorldAssigned,
        passportStampEarned,
        premiumPaywallShown,
    ]
}

/// Builders for the payloads that accompany those signals. Port of the web
/// app's `src/lib/analytics/signals.ts`.
enum AnalyticsPayload {
    /// Stamp totals are bucketed rather than sent exactly.
    ///
    /// An exact count is a surprisingly good fingerprint once it gets large —
    /// "the user with 37 stamps" is one person. Buckets answer the only
    /// question being asked (is the collection loop engaging anyone, or does
    /// everyone stall at one?) without carrying that.
    ///
    /// Clamps below 1: a total should never be zero at the moment a stamp is
    /// earned, but an unlabelled bucket would be worse than a wrong one.
    static func stampCountBucket(_ count: Int) -> String {
        switch count {
        case ..<2: return "1"
        case ..<6: return "2-5"
        case ..<16: return "6-15"
        default: return "16+"
        }
    }

    /// Which world someone landed on is deliberately not sent — the slot is.
    ///
    /// A slot ("snow", "clear_scorching") answers the same product question in
    /// generic weather vocabulary. World names are the catalog's documented IP
    /// exposure, and shipping them to a third party would create an external
    /// record of that association for no analytical gain.
    static func forecastLanded(slotId: SlotId) -> [String: String] {
        ["slotId": slotId]
    }

    static func atlasWorldAssigned(slotId: SlotId, action: AssignmentAction) -> [String: String] {
        ["slotId": slotId, "action": action.rawValue]
    }

    static func passportStampEarned(
        slotId: SlotId,
        kind: StampKind,
        totalStamps: Int
    ) -> [String: String] {
        ["slotId": slotId, "kind": kind.rawValue, "totalStamps": stampCountBucket(totalStamps)]
    }

    static func premiumPaywallShown(context: PaywallContext) -> [String: String] {
        ["context": context.analyticsName]
    }

    enum AssignmentAction: String {
        case assign
        case unassign
    }
}
