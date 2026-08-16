import Foundation

/// Persists the user's saved locations via iCloud's key-value store
/// (`NSUbiquitousKeyValueStore`), mirrored to `UserDefaults` as a local,
/// offline/no-iCloud-account fallback. Same sync strategy as
/// `StarChartStorage`, so a list built on one device shows up on the next
/// with zero backend and no accounts.
enum SavedLocationsStorage {
    private static let storageKey = "galacticweather:savedlocations:v1"

    private static func decode(_ data: Data?) -> [SavedLocation]? {
        guard let data else { return nil }
        return try? JSONDecoder().decode([SavedLocation].self, from: data)
    }

    static func load() -> [SavedLocation] {
        if let iCloud = decode(NSUbiquitousKeyValueStore.default.data(forKey: storageKey)) {
            return iCloud
        }
        if let local = decode(UserDefaults.standard.data(forKey: storageKey)) {
            // Local-only list from before iCloud sync existed (or before this
            // device had an iCloud account) — push it up so it starts syncing.
            save(local)
            return local
        }
        return []
    }

    static func save(_ locations: [SavedLocation]) {
        guard let data = try? JSONEncoder().encode(locations) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: storageKey)
        UserDefaults.standard.set(data, forKey: storageKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    /// Registers for iCloud's "another device changed this" notification and
    /// hands back the freshly-loaded list on the main queue. The returned
    /// token must be passed to `NotificationCenter.default.removeObserver(_:)`.
    static func observeRemoteChanges(_ handler: @escaping ([SavedLocation]) -> Void) -> NSObjectProtocol {
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
