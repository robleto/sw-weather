import Foundation

/// The single place the app asks "is this allowed?" for a premium capability.
///
/// No other file should read `PremiumStore.shared.isPremium` directly — call
/// sites ask `PremiumGate` a question about a specific capability instead, so
/// the free/premium line can move (e.g. while pricing is tuned) by editing
/// only this file.
///
/// Note on Observation: `PremiumStore` is `@Observable`, so a SwiftUI `body`
/// that reads `PremiumGate.isPremium` (which reads
/// `PremiumStore.shared.isPremium`) is automatically tracked by SwiftUI and
/// re-renders when the purchase completes. Call sites need no
/// `@State`/`@Environment` wrapper for read-only checks — that's deliberate.
@MainActor
enum PremiumGate {
    static var isPremium: Bool { PremiumStore.shared.isPremium }

    /// Every slot is freely reassignable for everyone — free users work from
    /// the same base catalog, just a smaller one. What's gated is *which
    /// worlds* they can assign (see `canUseWorld`) and multi-assign.
    static func canUseWorld(_ world: World) -> Bool {
        !world.isPremium || isPremium
    }

    /// Assigning several worlds to one slot (they rotate daily) is premium.
    static var canAssignMultipleWorlds: Bool { isPremium }

    // Looking up a city is deliberately NOT gated.
    //
    // An earlier spec had free tier as current-location-only. That dead-ends
    // anyone who declines the location prompt — their only unlocked control is
    // the button they just said no to — and, worse, it hides the entire app
    // behind the paywall, so nobody can see what they'd be buying. Saved
    // locations are the premium hook here; looking one up is not.

    /// Bookmarking a location for quick return — unlike searching for one —
    /// is entirely premium.
    static var canUseSavedLocations: Bool { isPremium }

    /// Keeps the iCloud KVS payload small and the list itself easy to scan.
    static let maxSavedLocations = 20

    /// Copy shown on locked affordances. Keep it short — these render inside pills.
    static let multiAssignUpsell = "Randomize several worlds daily"
}
