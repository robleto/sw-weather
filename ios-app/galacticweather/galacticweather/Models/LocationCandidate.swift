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

    /// The country's flag, built from its ISO 3166 alpha-2 code rather than
    /// shipped as artwork: offsetting each ASCII letter into the Unicode
    /// regional indicator block (U+1F1E6…) produces the emoji the system
    /// already has a glyph for. No assets, no network, no licensing, and it
    /// stays correct as flags change.
    ///
    /// `nil` for anything that isn't a two-letter code — notably the synthetic
    /// candidate built for a raw `lat,lon` query, which has no country at all.
    var flag: String? {
        let code = country.uppercased()
        guard code.count == 2, code.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        let base: UInt32 = 0x1F1E6
        var result = ""
        for character in code.unicodeScalars {
            guard let scalar = Unicode.Scalar(base + character.value - 65) else { return nil }
            result.unicodeScalars.append(scalar)
        }
        return result
    }

    /// The line under the city name: region plus the country spelled out.
    /// "Western Cape, South Africa" tells you where you're about to go in a
    /// way "Western Cape, ZA" makes you decode.
    var secondaryText: String {
        let countryName = Locale.current.localizedString(forRegionCode: country) ?? country
        return [regionOrState, countryName]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
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
