import Foundation

/// Persists the user's Passport via iCloud's key-value store
/// (`NSUbiquitousKeyValueStore`), mirrored to `UserDefaults`.
///
/// **This does not follow `AtlasStorage`'s last-writer-wins rule, and must
/// not.** Atlas holds a preference: whichever device edited most recently is
/// the one the user meant, and a lost edit costs a few taps to redo. A
/// Passport holds accumulated history — stamps are earned by being somewhere
/// at a moment that has passed, and a lost stamp cannot be re-earned at all.
/// So every read and every remote change *merges* rather than replaces:
/// stamps only ever union, and the earliest find always wins.
///
/// Concretely, the bug this avoids: phone earns Kamino on a flight with no
/// signal; iPad meanwhile earns Hoth and syncs. Under `AtlasStorage`'s rule
/// the phone's next read would adopt iCloud wholesale and drop Kamino on the
/// floor. Here the two books combine.
enum PassportStorage {
    private static let storageKey = "galacticweather:passport:v1"

    // MARK: - Lenient decoding

    /// Every field optional so a schema that gains fields later still decodes,
    /// and so a stamp missing `count` or `lastSeen` is repaired rather than
    /// rejected.
    private struct StoredSighting: Codable {
        var date: String?
        var city: String?
        var slotId: String?
        var tempF: Double?
    }

    private struct StoredStamp: Codable {
        var worldId: String?
        var wild: StoredSighting?
        var chartered: StoredSighting?
        var count: Int?
        var lastSeen: String?
    }

    private static func sanitize(_ raw: StoredSighting?) -> Sighting? {
        guard
            let raw,
            let date = raw.date, !date.isEmpty,
            let city = raw.city,
            // Deliberately not checked against the slot catalog: a slot retired
            // in a later release should cost the stamp its "earned on Heavy
            // snow" line, not the stamp.
            let slotId = raw.slotId,
            let tempF = raw.tempF, tempF.isFinite
        else { return nil }
        // A renamed slot still described this stamp accurately when it was
        // earned, so carry it forward rather than letting the "earned on
        // Dust & sand" line quietly disappear from an old page.
        return Sighting(
            date: date,
            city: city,
            slotId: canonicalSlotId(slotId),
            tempF: Int(tempF.rounded())
        )
    }

    /// Drop anything we don't recognize.
    ///
    /// This matters more here than it does for Atlas. Assignments are a
    /// preference someone can redo in a minute; a passport is accumulated over
    /// months and is the one thing in the app that can't be re-earned. So a
    /// world retired in a later release costs exactly one page, never the book.
    private static func sanitize(_ raw: [String: StoredStamp]) -> Passport {
        var result: Passport = [:]

        for (worldId, stored) in raw {
            guard isKnownWorld(worldId) else { continue }

            let wild = sanitize(stored.wild)
            let chartered = sanitize(stored.chartered)
            // A stamp with neither sighting records nothing.
            guard let anchor = wild ?? chartered else { continue }

            let lastSeen = stored.lastSeen.flatMap { $0.isEmpty ? nil : $0 } ?? anchor.date
            let count = (stored.count.map { max(1, $0) }) ?? 1

            result[worldId] = WorldStamp(
                worldId: worldId,
                wild: wild,
                chartered: chartered,
                count: count,
                lastSeen: lastSeen
            )
        }

        return result
    }

    private static func decode(_ data: Data?) -> Passport? {
        guard let data else { return nil }
        guard let raw = try? JSONDecoder().decode([String: StoredStamp].self, from: data) else { return nil }
        return sanitize(raw)
    }

    // MARK: - Merge

    /// Dates are zero-padded ISO, so string order is chronological order.
    private static func earlier(_ a: Sighting?, _ b: Sighting?) -> Sighting? {
        guard let a else { return b }
        guard let b else { return a }
        return a.date <= b.date ? a : b
    }

    /// Union two books. Never loses a stamp, never moves a first-found date
    /// later.
    ///
    /// `count` takes the max rather than the sum: summing would double-count a
    /// day both devices saw, and a decorative number is the wrong thing to
    /// inflate. Under-counting a genuinely split day is the safer error.
    static func merge(_ a: Passport, _ b: Passport) -> Passport {
        var result = a

        for (worldId, incoming) in b {
            guard let existing = result[worldId] else {
                result[worldId] = incoming
                continue
            }

            result[worldId] = WorldStamp(
                worldId: worldId,
                wild: earlier(existing.wild, incoming.wild),
                chartered: earlier(existing.chartered, incoming.chartered),
                count: max(existing.count, incoming.count),
                lastSeen: max(existing.lastSeen, incoming.lastSeen)
            )
        }

        return result
    }

    // MARK: - Load / save

    /// Merges both stores rather than preferring iCloud, then writes the
    /// merged book back if either side was missing something — so the union
    /// propagates instead of having to be re-derived on every launch.
    static func load() -> Passport {
        let remote = decode(NSUbiquitousKeyValueStore.default.data(forKey: storageKey)) ?? [:]
        let local = decode(UserDefaults.standard.data(forKey: storageKey)) ?? [:]

        let merged = merge(local, remote)
        if merged != local || merged != remote {
            save(merged)
        }
        return merged
    }

    static func save(_ passport: Passport) {
        guard let data = try? JSONEncoder().encode(passport) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: storageKey)
        UserDefaults.standard.set(data, forKey: storageKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    /// Registers for iCloud's "another device changed this" notification and
    /// hands back the merged book on the main queue. The returned token must
    /// be passed to `NotificationCenter.default.removeObserver(_:)`.
    static func observeRemoteChanges(_ handler: @escaping (Passport) -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { _ in handler(load()) }
    }

    /// Pulls the latest iCloud values at launch.
    static func startSync() {
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    /// Nothing calls this. There is deliberately no "reset passport" in the
    /// UI — see the never-un-stamp rule in PASSPORT.md — but a debug build
    /// needs a way back to an empty book.
    static func clear() {
        save([:])
    }
}

#if DEBUG
extension PassportStorage {
    /// Test seam for the decode/sanitize path, which is otherwise only
    /// reachable through iCloud. Mirrors the web app's `__testing` export.
    /// Same-file extension, so `private` is still visible here.
    static func decodeForTesting(_ data: Data) -> Passport? { decode(data) }
}
#endif
