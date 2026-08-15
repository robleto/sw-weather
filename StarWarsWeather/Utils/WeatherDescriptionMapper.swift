import Foundation

/// Port of the planet-mapping logic that turns a weather condition + temperature
/// into a `PlanetInfo`, backed by the bundled PlanetData.json.
enum WeatherDescriptionMapper {
    /// Fallback key used when no more specific match is found.
    private static let fallbackKey = "clear_temperate"

    /// Aliases from a raw weather-condition string to a different lookup key.
    private static let conditionAliases: [String: String] = [
        "dust": "jakku",
        "sand": "jakku",
        "ash": "smoke",
        "squall": "thunderstorm",
        "tornado": "thunderstorm"
    ]

    /// The decoded planet data, keyed by lookup key. Parsed exactly once.
    static let planetData: [String: PlanetInfo] = {
        guard let url = Bundle.main.url(forResource: "PlanetData", withExtension: "json") else {
            assertionFailure("PlanetData.json not found in bundle")
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([String: PlanetInfo].self, from: data)
        } catch {
            assertionFailure("Failed to decode PlanetData.json: \(error)")
            return [:]
        }
    }()

    /// A small "idle/loading" default value for use before any weather has loaded.
    static let idlePlanetInfo = PlanetInfo(
        planet: "default",
        planetName: "default",
        description: "",
        color: PlanetInfo.PlanetColor(primary: "#000000", headline: "#000000")
    )

    /// Picks a "clear" planet key from a Fahrenheit temperature.
    private static func clearPlanetKey(forFahrenheit tempF: Double) -> String {
        if tempF >= 99 { return "clear_scorching" }
        if tempF >= 85 { return "clear_hot" }
        if tempF >= 76 { return "clear_warm" }
        if tempF >= 66 { return "clear_temperate" }
        if tempF >= 50 { return "clear_cool" }
        if tempF >= 41 { return "clear_chilly" }
        if tempF >= 14 { return "clear_cold" }
        return "clear_freezing"
    }

    /// Picks a "clouds" planet key from a Fahrenheit temperature.
    private static func cloudsPlanetKey(forFahrenheit tempF: Double) -> String {
        if tempF >= 76 { return "clouds_warm" }
        if tempF >= 66 { return "clouds_temperate" }
        if tempF >= 50 { return "clouds_cool" }
        return "clouds_cold"
    }

    /// Main lookup: given a raw weather-condition string, a temperature in
    /// Kelvin, and an optional weather description, returns the matching `PlanetInfo`.
    static func describe(weatherMain: String, tempKelvin: Double, description: String = "") -> PlanetInfo {
        let condition = weatherMain.lowercased()
        let tempF = kelvinToFahrenheit(tempKelvin)
        let data = planetData
        let fallback = data[fallbackKey] ?? idlePlanetInfo

        if let alias = conditionAliases[condition], let aliased = data[alias] {
            return aliased
        }

        if condition == "snow" {
            let lowerDescription = description.lowercased()
            let key = lowerDescription.contains("light") ? "snow_light" : "snow"
            return data[key] ?? data["snow"] ?? fallback
        }

        if condition == "clouds" {
            let key = cloudsPlanetKey(forFahrenheit: tempF)
            return data[key] ?? fallback
        }

        if condition == "clear" {
            let key = clearPlanetKey(forFahrenheit: tempF)
            return data[key] ?? fallback
        }

        if let direct = data[condition] {
            return direct
        }

        return fallback
    }
}
