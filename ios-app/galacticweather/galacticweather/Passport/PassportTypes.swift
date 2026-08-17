import Foundation

/// One recorded encounter with a world.
/// Port of the web app's `src/lib/passport/types.ts`.
struct Sighting: Codable, Equatable {
    /// Local calendar date, "2026-08-17". Local, so a stamp is dated the day
    /// the user experienced it, not the day UTC happened to be on.
    let date: String
    /// The place whose forecast produced it, as it was shown on screen.
    let city: String
    /// The weather bucket that earned it — "snow", "clear_scorching".
    let slotId: SlotId
    /// Always Fahrenheit, matching the web schema, regardless of the user's
    /// display preference — `AppSettings.temperatureUnit` is about how numbers
    /// are read, not what a historical record stores. `PassportView` converts
    /// for display, which can land a degree off in Celsius for a stamp earned
    /// long ago. That's acceptable on a decorative detail.
    let tempF: Int
}

/// How a world was found.
///
/// `wild`      — the slot was at its default, so the forecast handed it to you.
/// `chartered` — you assigned this world to the slot in Atlas first. Still a
///               real find (the weather had to actually happen), but you chose
///               the destination, so it doesn't count toward the Wild book.
enum StampKind: String, Codable {
    case wild
    case chartered
}

/// One page in the book.
///
/// `wild` and `chartered` are separate optional fields rather than a single
/// sighting plus a kind, so a world charted today and later found wild simply
/// gains a second field — no precedence rule, no migration, and both dates
/// survive.
struct WorldStamp: Codable, Equatable {
    let worldId: WorldId
    var wild: Sighting?
    var chartered: Sighting?
    /// Distinct days this world has been seen. See `recordSighting`.
    var count: Int
    var lastSeen: String

    func sighting(_ kind: StampKind) -> Sighting? {
        switch kind {
        case .wild: return wild
        case .chartered: return chartered
        }
    }

    mutating func setSighting(_ sighting: Sighting, for kind: StampKind) {
        switch kind {
        case .wild: wild = sighting
        case .chartered: chartered = sighting
        }
    }
}

typealias Passport = [WorldId: WorldStamp]
