import Foundation

/// Errors thrown by `WeatherService` when fetching current weather directly
/// from OpenWeatherMap.
enum WeatherServiceError: Error, LocalizedError {
    /// `OPENWEATHERMAP_API_KEY` was missing (or empty) in Info.plist.
    case missingAPIKey
    /// The API returned a 404 for the given coordinates.
    case locationNotFound
    /// The API returned a non-2xx, non-404 status code.
    case httpError(statusCode: Int)
    /// The response body could not be decoded into `WeatherResponse`.
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "The OpenWeatherMap API key is missing from the app configuration."
        case .locationNotFound:
            return "No weather data was found for that location."
        case .httpError(let statusCode):
            return "The weather service returned an error (status code \(statusCode))."
        case .decodingFailed:
            return "The weather service returned data that could not be understood."
        }
    }
}

/// Calls the OpenWeatherMap "current weather" endpoint directly from the
/// device (no backend proxy).
struct WeatherService {
    private static let endpoint = URL(string: "https://api.openweathermap.org/data/2.5/weather")!
    private static let apiKeyInfoDictionaryKey = "OPENWEATHERMAP_API_KEY"

    /// Fetches current weather for the given coordinates.
    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: Self.apiKeyInfoDictionaryKey) as? String,
              !apiKey.isEmpty else {
            throw WeatherServiceError.missingAPIKey
        }

        var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon))
        ]

        guard let url = components.url else {
            throw WeatherServiceError.httpError(statusCode: -1)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.httpError(statusCode: -1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw WeatherServiceError.locationNotFound
            }
            throw WeatherServiceError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(WeatherResponse.self, from: data)
        } catch {
            throw WeatherServiceError.decodingFailed(underlying: error)
        }
    }
}
