import Foundation

/// Direct port of the original TypeScript `convertKelvinToFahrenheit`.
/// Same formula, no rounding here — rounding for display happens in the UI layer.
///
/// Still used directly by `WeatherDescriptionMapper`, whose thresholds are
/// defined in Fahrenheit. That's deliberate and must not follow the user's
/// display preference: which world a forecast maps to is a property of the
/// weather, not of how someone likes to read it.
func kelvinToFahrenheit(_ kelvin: Double) -> Double {
    (kelvin - 273.15) * 9 / 5 + 32
}

func kelvinToCelsius(_ kelvin: Double) -> Double {
    kelvin - 273.15
}

/// How temperatures are shown. Display only — see the note above.
enum TemperatureUnit: String, CaseIterable, Identifiable, Codable {
    case fahrenheit
    case celsius

    var id: String { rawValue }

    /// "F" / "C", for the rare place that spells the unit out. Most of the UI
    /// shows a bare degree sign, the way the native Weather app does.
    var symbol: String {
        switch self {
        case .fahrenheit: return "F"
        case .celsius: return "C"
        }
    }

    var shortLabel: String { "°\(symbol)" }

    /// The whole-degree value to display for a Kelvin reading.
    func degrees(fromKelvin kelvin: Double) -> Int {
        switch self {
        case .fahrenheit: return Int(kelvinToFahrenheit(kelvin).rounded())
        case .celsius: return Int(kelvinToCelsius(kelvin).rounded())
        }
    }

    /// e.g. "76°". The bare form used on cards and in the big readouts.
    func degreeString(fromKelvin kelvin: Double) -> String {
        "\(degrees(fromKelvin: kelvin))\u{00B0}"
    }

    /// The unit to start someone on, from their region — so the overwhelming
    /// majority never have to find this setting at all.
    static var deviceDefault: TemperatureUnit {
        Locale.current.measurementSystem == .us ? .fahrenheit : .celsius
    }
}
