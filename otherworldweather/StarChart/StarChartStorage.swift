import Foundation

/// Persists the user's Star Chart via iCloud's key-value store
/// (`NSUbiquitousKeyValueStore`), mirrored to `UserDefaults` as a local,
/// offline/no-iCloud-account fallback. This syncs the chart across the
/// user's devices with zero backend and no accounts; the web app's
/// equivalent uses `localStorage` and stays entirely local to one browser.
/// Port of the web app's `src/lib/starchart/storage.ts`.
enum StarChartStorage {
    private static let storageKey = "otherworld:starchart:v1"

    /// Drop anything we don't recognize. Stored charts outlive app updates, so
    /// a slot or world removed in a later release must not break the whole
    /// chart — the unknown entry is discarded and that slot falls back to its
    /// default.
    private static func sanitize(_ raw: [String: [String]]) -> StarChartOverrides {
        var result: StarChartOverrides = [:]
        for (slotId, worldIds) in raw {
            guard getSlot(slotId) != nil else { continue }
            let known = worldIds.filter { isKnownWorld($0) }
            let unique = orderedUnique(known)
            // An empty list is meaningless, so treat it as "not customized".
            if !unique.isEmpty { result[slotId] = unique }
        }
        return result
    }

    private static func decode(_ data: Data?) -> StarChartOverrides? {
        guard let data else { return nil }
        guard let raw = try? JSONDecoder().decode([String: [String]].self, from: data) else { return nil }
        return sanitize(raw)
    }

    static func load() -> StarChartOverrides {
        if let iCloud = decode(NSUbiquitousKeyValueStore.default.data(forKey: storageKey)) {
            return iCloud
        }
        if let local = decode(UserDefaults.standard.data(forKey: storageKey)) {
            // Local-only chart from before iCloud sync existed (or before this
            // device had an iCloud account) — push it up so it starts syncing.
            save(local)
            return local
        }
        return [:]
    }

    static func save(_ overrides: StarChartOverrides) {
        guard let data = try? JSONEncoder().encode(overrides) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: storageKey)
        UserDefaults.standard.set(data, forKey: storageKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    /// Writes an explicit empty chart rather than removing the key.
    ///
    /// Removing it makes "reset to canon" indistinguishable from "never set",
    /// and `load()` falls back to the local mirror when iCloud has no value —
    /// so a reset on one device would be undone by another device's stale
    /// `UserDefaults` copy, which then gets pushed back up. An empty value
    /// syncs as a real state and sticks.
    static func clear() {
        save([:])
    }

    /// Registers for iCloud's "another device changed this" notification and
    /// hands back the freshly-loaded chart on the main queue. The returned
    /// token must be passed to `NotificationCenter.default.removeObserver(_:)`.
    static func observeRemoteChanges(_ handler: @escaping (StarChartOverrides) -> Void) -> NSObjectProtocol {
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
}
