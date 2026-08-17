import Foundation

/// Local calendar date as "YYYY-MM-DD".
///
/// Zero-padded and therefore sortable, which `merge` in `PassportStorage`
/// relies on. Deliberately *not* the same helper as `Resolve.swift`'s
/// `dayKey` — that one feeds a hash and its unpadded form is load-bearing
/// there, because changing it would reshuffle everyone's daily rotation.
func passportLocalDate(_ now: Date = Date(), calendar: Calendar = .current) -> String {
    let parts = calendar.dateComponents([.year, .month, .day], from: now)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
}

/// A world resolved from a slot default was found in the wild; one the user
/// assigned themselves was chartered. `resolveWorld` already computes this —
/// `customized` is true exactly when the slot has an override.
func stampKind(for resolved: ResolvedWorld) -> StampKind {
    resolved.customized ? .chartered : .wild
}

/// Award a stamp for a world currently on screen.
///
/// **Idempotent within a local day.** Returns `nil` when there's nothing new,
/// which is what lets the caller fire it freely without guarding, and lets the
/// view model skip both the redraw and the iCloud write. It also means `count`
/// can't be inflated by backgrounding and reopening the app — it counts
/// distinct days, not appearances.
///
/// The one thing that always applies, even on a repeat day, is recording a
/// *kind* not seen before: finding a charted world in the wild upgrades the
/// page immediately rather than waiting for tomorrow.
///
/// Port of the web app's `recordSighting`, which signals "no change" by
/// returning the same object reference. Swift has no equivalent for a value
/// type, hence the optional.
func recordSighting(
    into passport: Passport,
    resolved: ResolvedWorld,
    city: String,
    tempF: Double,
    now: Date = Date()
) -> Passport? {
    // "default" is the placeholder the app renders before any weather lands.
    guard !resolved.planet.isEmpty, resolved.planet != "default" else { return nil }

    let today = passportLocalDate(now)
    let kind = stampKind(for: resolved)

    let sighting = Sighting(
        date: today,
        city: city,
        slotId: resolved.slotId,
        tempF: Int(tempF.rounded())
    )

    var next = passport

    guard var stamp = passport[resolved.planet] else {
        var fresh = WorldStamp(worldId: resolved.planet, count: 1, lastSeen: today)
        fresh.setSighting(sighting, for: kind)
        next[resolved.planet] = fresh
        return next
    }

    let isNewKind = stamp.sighting(kind) == nil
    let isNewDay = stamp.lastSeen != today

    guard isNewKind || isNewDay else { return nil }

    // First sighting of this kind only — a stamp records when you *first*
    // found a world, and nothing overwrites that date later.
    if isNewKind { stamp.setSighting(sighting, for: kind) }
    if isNewDay { stamp.count += 1 }
    stamp.lastSeen = today

    next[resolved.planet] = stamp
    return next
}
