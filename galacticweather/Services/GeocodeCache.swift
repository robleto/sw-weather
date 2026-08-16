import Foundation

/// A client-side 24-hour TTL cache of geocode results, keyed by a normalized
/// query string. Backed by `UserDefaults`, mirroring the original web app's
/// `localStorage`-based cache.
struct GeocodeCache {
    /// Codable wrapper stored (JSON-encoded) per normalized query.
    private struct CacheEntry: Codable {
        let timestamp: Date
        let results: [LocationCandidate]
    }

    private static let keyPrefix = "sw-weather:geocode:v1:"
    private static let ttl: TimeInterval = 24 * 60 * 60

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    private func storageKey(for normalizedQuery: String) -> String {
        Self.keyPrefix + normalizedQuery
    }

    /// Returns cached results for `normalizedQuery`, or `nil` if there is no
    /// entry, the entry is older than the TTL, or the entry fails to decode.
    /// Stale or corrupt entries are removed as a side effect.
    func read(normalizedQuery: String) -> [LocationCandidate]? {
        let key = storageKey(for: normalizedQuery)
        guard let data = userDefaults.data(forKey: key) else { return nil }

        let entry: CacheEntry
        do {
            entry = try JSONDecoder().decode(CacheEntry.self, from: data)
        } catch {
            userDefaults.removeObject(forKey: key)
            return nil
        }

        guard Date().timeIntervalSince(entry.timestamp) < Self.ttl else {
            userDefaults.removeObject(forKey: key)
            return nil
        }

        return entry.results
    }

    /// Stores `results` for `normalizedQuery`, timestamped with the current time.
    func write(normalizedQuery: String, results: [LocationCandidate]) {
        let entry = CacheEntry(timestamp: Date(), results: results)
        guard let data = try? JSONEncoder().encode(entry) else { return }
        userDefaults.set(data, forKey: storageKey(for: normalizedQuery))
    }
}
