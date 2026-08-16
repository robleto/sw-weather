import Foundation

/// Decodes the subset of the OpenWeatherMap "current weather" API response
/// actually used by the app.
struct WeatherResponse: Decodable {
    struct Main: Decodable {
        /// Temperature in Kelvin, as returned by OpenWeatherMap.
        let temp: Double
    }

    struct WeatherCondition: Decodable {
        let main: String
        let description: String
    }

    let name: String
    let main: Main
    let weather: [WeatherCondition]
}
