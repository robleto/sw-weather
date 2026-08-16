import Foundation

/// A single candidate location returned from geocoding, e.g. for
/// disambiguation when a user's search query matches multiple places.
struct LocationCandidate: Codable, Identifiable, Hashable {
    let name: String
    let regionOrState: String
    let country: String
    let lat: Double
    let lon: Double
    let displayName: String

    var id: String {
        "\(lat),\(lon),\(displayName)"
    }

    init(name: String, regionOrState: String, country: String, lat: Double, lon: Double) {
        self.name = name
        self.regionOrState = regionOrState
        self.country = country
        self.lat = lat
        self.lon = lon
        self.displayName = [name, regionOrState, country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
