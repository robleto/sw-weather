import Foundation

/// A Star Wars planet mapped to a real-world weather condition/temperature,
/// as loaded from the bundled PlanetData.json.
struct PlanetInfo: Decodable {
    struct PlanetColor: Decodable {
        /// Hex color string, e.g. "#7A609B".
        let primary: String
        /// Hex color string, e.g. "#7A609B".
        let headline: String
    }

    let planet: String
    let planetName: String
    let description: String
    let color: PlanetColor
}
