import Foundation

/// Port of a TypeScript discriminated union describing the result of parsing
/// a raw, user-entered location query string.
enum ParsedLocationQuery: Equatable {
    case empty
    case coordinates(lat: Double, lon: Double, normalizedQuery: String)
    case geocode(query: String, normalizedQuery: String)
}
