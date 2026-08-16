import Foundation

/// A location the user has bookmarked for quick return, distinct from
/// `LocationCandidate` (an ephemeral geocode search result). Premium-only —
/// see `PremiumGate.canUseSavedLocations`.
struct SavedLocation: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let lat: Double
    let lon: Double

    init(displayName: String, lat: Double, lon: Double) {
        self.id = Self.id(lat: lat, lon: lon)
        self.displayName = displayName
        self.lat = lat
        self.lon = lon
    }

    /// Coordinates rounded to ~11m precision, so saving "the same" spot twice
    /// (e.g. current location vs. a search result for the same city) dedupes
    /// to one entry instead of two near-identical ones.
    static func id(lat: Double, lon: Double) -> String {
        "\(round(lat * 10000) / 10000),\(round(lon * 10000) / 10000)"
    }
}
