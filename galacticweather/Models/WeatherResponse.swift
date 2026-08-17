import Foundation

/// Decodes the subset of the OpenWeatherMap "current weather" API response
/// actually used by the app.
struct WeatherResponse: Decodable {
    struct Main: Decodable {
        /// Temperature in Kelvin, as returned by OpenWeatherMap.
        let temp: Double
        /// Caveat worth knowing: on the *current weather* endpoint these are
        /// the min/max observed across the city's reporting area right now —
        /// not the day's high and low. They're what the saved-locations cards
        /// show as H/L because they cost nothing extra; a true daily H/L needs
        /// the forecast endpoint, which is a separate (billable) call.
        let tempMin: Double?
        let tempMax: Double?

        private enum CodingKeys: String, CodingKey {
            case temp
            case tempMin = "temp_min"
            case tempMax = "temp_max"
        }
    }

    struct WeatherCondition: Decodable {
        /// OpenWeatherMap's numeric condition code. The primary signal for
        /// Atlas slot selection — it is the only field that separates sleet
        /// from heavy snow, or a few clouds from full overcast.
        let id: Int
        let main: String
        let description: String
    }

    let name: String
    let main: Main
    let weather: [WeatherCondition]
    /// Timestamp of the observation, seconds since epoch (UTC).
    let dt: Int?
    /// The location's offset from UTC in seconds. Lets the saved-locations
    /// cards show each place's own local clock, the way the native Weather
    /// app does, without a second timezone lookup.
    let timezone: Int?

    /// The wall-clock time at this location when the observation was taken.
    /// `nil` if the API omitted either field.
    var localTimeText: String? {
        guard let dt, let timezone else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(secondsFromGMT: timezone)
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(dt)))
    }
}
