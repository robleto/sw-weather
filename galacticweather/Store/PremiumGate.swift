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

    /// Free users get their device location plus one saved spot. Saving isn't
    /// premium any more — saving *more than one* is. A free user with a single
    /// bookmark can still feel the whole loop (save, swipe between two places,
    /// come back tomorrow), which is what makes the second slot worth paying
    /// for. Gating the feature outright meant nobody ever felt it.
    /// `nonisolated` because paywall copy is assembled off the main actor —
    /// these are plain constants, unlike `maxSavedLocations`, which has to
    /// read the store.
    nonisolated static let freeSavedLocationLimit = 1

    /// Keeps the iCloud KVS payload small and the list itself easy to scan.
    nonisolated static let premiumSavedLocationLimit = 20

    /// How many saved locations this user may keep *active*.
    static var maxSavedLocations: Int {
        isPremium ? premiumSavedLocationLimit : freeSavedLocationLimit
    }

    /// Whether the saved location at `index` (in saved order) is usable.
    ///
    /// Deliberately index-based rather than count-based: a lapsed subscriber
    /// keeps everything they saved, and the entries past the free limit go
    /// dormant — visible in the list, locked, excluded from the pager —
    /// instead of being deleted. Resubscribing brings them straight back, and
    /// nothing the user created is ever destroyed by a billing event.
    static func isSavedLocationUnlocked(index: Int) -> Bool {
        index < maxSavedLocations
    }

    /// The Passport is free to open and free to fill.
    ///
    /// Collecting is the retention hook, and a half-finished book is the best
    /// paywall argument the app has — gating the whole thing is a hook that
    /// never sets. Nothing extra needs enforcing here either: the seven
    /// premium worlds are no slot's default, so a forecast can never serve one
    /// up, and `canUseWorld` already stops a free user assigning one. The book
    /// gates itself.
    static var canOpenPassport: Bool { true }

    /// Whether a Passport page renders locked rather than merely unfound.
    ///
    /// Takes `found` so an earned stamp is never taken away — consistent with
    /// `isSavedLocationUnlocked`, and with the never-un-stamp rule: nothing a
    /// user actually collected disappears because of an entitlement check.
    static func isPassportPageLocked(_ world: World, found: Bool) -> Bool {
        !found && world.isPremium && !isPremium
    }

    /// Copy shown on locked affordances. Keep it short — these render inside pills.
    static let multiAssignUpsell = "Randomize several worlds daily"
}
