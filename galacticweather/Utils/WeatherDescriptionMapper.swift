import Foundation

/// Maps an OpenWeatherMap condition + temperature to a Weather Twins slot id.
///
/// This deliberately stops at the slot. Which *world* a slot displays is a
/// separate question owned by Weather Twins (see WeatherTwins/Resolve.swift),
/// because the user can reassign it. Port of the web app's
/// `src/app/utils/weatherDescriptions.ts` (`getSlotForWeather`).
enum WeatherDescriptionMapper {
    private static let conditionAliases: [String: SlotId] = [
        "dust": "jakku",
        "sand": "jakku",
        "ash": "smoke",
        "squall": "thunderstorm",
        "tornado": "thunderstorm",
    ]

    private static func clearSlot(forFahrenheit tempF: Double) -> SlotId {
        if tempF >= 99 { return "clear_scorching" }
        if tempF >= 85 { return "clear_hot" }
        if tempF >= 76 { return "clear_warm" }
        if tempF >= 66 { return "clear_temperate" }
        if tempF >= 50 { return "clear_cool" }
        if tempF >= 41 { return "clear_chilly" }
        if tempF >= 14 { return "clear_cold" }
        return "clear_freezing"
    }

    private static func cloudsSlot(forFahrenheit tempF: Double) -> SlotId {
        if tempF >= 76 { return "clouds_warm" }
        if tempF >= 66 { return "clouds_temperate" }
        if tempF >= 50 { return "clouds_cool" }
        return "clouds_cold"
    }

    /// Main lookup: given a raw weather-condition string, a temperature in
    /// Kelvin, and an optional weather description, returns the matching slot id.
    static func getSlotForWeather(weatherMain: String, tempKelvin: Double, description: String = "") -> SlotId {
        let condition = weatherMain.lowercased()
        let tempF = kelvinToFahrenheit(tempKelvin)

        if let alias = conditionAliases[condition], getSlot(alias) != nil {
            return alias
        }

        if condition == "snow" {
            return description.lowercased().contains("light") ? "snow_light" : "snow"
        }

        if condition == "clouds" { return cloudsSlot(forFahrenheit: tempF) }
        if condition == "clear" { return clearSlot(forFahrenheit: tempF) }

        if getSlot(condition) != nil { return condition }

        return FALLBACK_SLOT_ID
    }
}
