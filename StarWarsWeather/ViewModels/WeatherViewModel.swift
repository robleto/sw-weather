import CoreLocation
import Observation

/// The two high-level phases of the app's root screen (port of the original
/// web app's `AppPhase` union type).
enum AppPhase {
    /// Hyperspace hero, search box, no weather yet.
    case idle
    /// Weather is showing or loading.
    case landed
}

/// Root view model for the app: owns the weather-fetch state machine that was
/// originally inlined in the Next.js root page component.
@Observable
final class WeatherViewModel {
    private(set) var weatherData: WeatherResponse?
    var locationQuery: String = ""
    private(set) var appPhase: AppPhase = .idle
    private(set) var pageError: String?
    private(set) var isWeatherLoading = false
    private(set) var isResolvingLocation = false

    private let weatherService: WeatherService
    private let locationManager: LocationManager

    init(
        weatherService: WeatherService = WeatherService(),
        locationManager: LocationManager = LocationManager()
    ) {
        self.weatherService = weatherService
        self.locationManager = locationManager
    }

    /// Planet display info derived from the current weather, or the mapper's
    /// idle/default value before any weather has loaded.
    var weatherInfo: PlanetInfo {
        guard let weatherData, let condition = weatherData.weather.first else {
            return WeatherDescriptionMapper.idlePlanetInfo
        }
        return WeatherDescriptionMapper.describe(
            weatherMain: condition.main,
            tempKelvin: weatherData.main.temp,
            description: condition.description
        )
    }

    /// Fetches weather for `lat`/`lon` and lands the app on the weather screen.
    ///
    /// Does NOT clear `weatherData` first, so the previously-shown planet stays
    /// visible while the new weather loads (avoids a blank-background flash on
    /// every search). Every path that lands on a location — search selection,
    /// the current-location button, and the initial launch attempt — funnels
    /// through here, so clearing `locationQuery` in one place clears the
    /// search field after every load, rather than leaving stale/resolved text
    /// sitting in it.
    @MainActor
    func goToLocation(lat: Double, lon: Double) async {
        locationQuery = ""
        appPhase = .landed
        pageError = nil
        isWeatherLoading = true
        defer { isWeatherLoading = false }

        do {
            weatherData = try await weatherService.fetchWeather(lat: lat, lon: lon)
        } catch {
            pageError = "We couldn't load weather right now. Please try again."
            appPhase = .idle
            weatherData = nil
        }
    }

    /// Call once on launch (e.g. from a `.task` modifier) to try resolving the
    /// device's current location. On success, lands on that location's weather.
    /// On failure or permission denial, silently stays in `.idle` with no error
    /// shown — mirrors the original web app's silent fallback on geolocation denial.
    @MainActor
    func resolveInitialLocation() async {
        await requestCurrentLocation(surfaceErrors: false)
    }

    /// Re-resolves the device's current location on demand, e.g. from a
    /// "use my location" button tap. Unlike `resolveInitialLocation()`, this
    /// surfaces the failure reason as `pageError` since it's an explicit user
    /// action, not a silent launch-time attempt.
    @MainActor
    func useCurrentLocation() async {
        await requestCurrentLocation(surfaceErrors: true)
    }

    @MainActor
    private func requestCurrentLocation(surfaceErrors: Bool) async {
        isResolvingLocation = true
        defer { isResolvingLocation = false }

        do {
            let coordinate = try await locationManager.requestOneShotLocation()
            await goToLocation(lat: coordinate.latitude, lon: coordinate.longitude)
        } catch {
            if surfaceErrors {
                pageError = (error as? LocalizedError)?.errorDescription ?? "We couldn't determine your location."
            }
        }
    }
}
