import Foundation

/// Direct port of the original TypeScript `convertKelvinToFahrenheit`.
/// Same formula, no rounding here — rounding for display happens in the UI layer.
func kelvinToFahrenheit(_ kelvin: Double) -> Double {
    (kelvin - 273.15) * 9 / 5 + 32
}
