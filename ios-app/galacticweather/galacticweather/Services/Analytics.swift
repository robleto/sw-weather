import Foundation
import TelemetryDeck

/// The only file that talks to TelemetryDeck, in the same spirit as
/// `PremiumStore` being the only file that talks to StoreKit.
///
/// Off unless deliberately switched on. `TELEMETRYDECK_APP_ID` comes from
/// `Config/Secrets.xcconfig` via Info.plist, the same route as the weather API
/// key, so a checkout without that value — anyone cloning this, and every
/// local build until the key is added — sends nothing at all rather than
/// sending to a stranger's dashboard.
///
/// What it sends is fixed by `AnalyticsSignals`: six signals, and payload keys
/// restricted to an allowlist enforced by test on both platforms. No city
/// names, no coordinates, no search queries, no world names.
enum Analytics {
    private static let appIDInfoDictionaryKey = "TELEMETRYDECK_APP_ID"

    private static var isRunning = false

    /// Initialize once, at app launch. Repeat calls are ignored.
    static func start() {
        guard !isRunning, isEnabledForThisProcess else { return }

        guard
            let appID = Bundle.main.object(forInfoDictionaryKey: appIDInfoDictionaryKey) as? String,
            !appID.isEmpty,
            // An xcconfig variable that was never defined can reach Info.plist
            // as the literal "$(TELEMETRYDECK_APP_ID)" rather than as an empty
            // string, depending on how the build settings resolve. Treat that
            // as unconfigured too — it is, and initializing with it would send
            // every signal to a nonexistent app.
            !appID.hasPrefix("$(")
        else { return }

        TelemetryDeck.initialize(config: TelemetryDeck.Config(appID: appID))
        isRunning = true
    }

    /// Record a signal. A no-op until `start()` has succeeded, so call sites
    /// never need to know whether analytics is configured.
    static func track(_ signal: String, _ parameters: [String: String] = [:]) {
        guard isRunning else { return }
        TelemetryDeck.signal(signal, parameters: parameters)
    }

    /// Xcode previews and unit tests both instantiate real views and view
    /// models, and both would otherwise post signals — previews on every
    /// canvas redraw. Neither is a person using the app, and the dashboard
    /// only has value if everything in it is.
    private static var isEnabledForThisProcess: Bool {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return false
        }
        if NSClassFromString("XCTestCase") != nil {
            return false
        }
        return true
    }
}
