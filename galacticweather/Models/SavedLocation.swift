import Foundation

/// A location the user has bookmarked for quick return, distinct from
/// `LocationCandidate` (an ephemeral geocode search result). Premium-only —
/// see `PremiumGate.canUseSavedLocations`.
struct SavedLocation: Codable, Identifiable, Hashable {
    let id: String
    /// The name the geocoder/weather API gave this place. Kept even after a
    /// rename so "Reset name" can restore it.
    let displayName: String
    /// A user-chosen label. The API's name for a place is often not what
    /// someone calls it — the nearest reporting station rather than their
    /// town, say — so this takes precedence wherever the location is shown.
    var customName: String?
    let lat: Double
    let lon: Double

    /// What to actually show. Blank/whitespace custom names fall back rather
    /// than rendering an empty row.
    var name: String {
        guard let trimmed = customName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else { return displayName }
        return trimmed
    }

    var isRenamed: Bool { name != displayName }

    init(displayName: String, customName: String? = nil, lat: Double, lon: Double) {
        self.id = Self.id(lat: lat, lon: lon)
        self.displayName = displayName
        self.customName = customName
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
