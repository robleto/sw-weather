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

/// Root view model for the app: owns the swipeable set of weather pages and
/// each one's fetch state.
///
/// Weather is fetched per page and cached, rather than all at once — the
/// number of pages grows with saved locations, and every fetch is a billable
/// API call. Only the selected page (and whatever the user swipes to) loads.
@Observable
final class WeatherViewModel {
    /// Device location, once Core Location resolves it.
    private(set) var currentCoordinate: WeatherPage.Coordinate?
    /// The user's saved locations, mirrored from `SavedLocationsViewModel`.
    private(set) var savedLocations: [SavedLocation] = []
    /// A searched-but-unsaved location. Transient: replaced by the next search.
    private(set) var searchResult: (coordinate: WeatherPage.Coordinate, name: String)?

    private(set) var states: [WeatherPageKind: WeatherPageState] = [:]
    var selection: WeatherPageKind = .currentLocation

    var locationQuery: String = ""
    private(set) var appPhase: AppPhase = .idle
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

    // MARK: - Pages

    /// Device location first, then saved locations in saved order, then the
    /// transient search result.
    ///
    /// The device page only exists once Core Location actually resolves —
    /// otherwise someone who declines the permission prompt gets a permanently
    /// blank page they can swipe back into.
    var pages: [WeatherPage] {
        var result: [WeatherPage] = []

        if let currentCoordinate {
            result.append(
                WeatherPage(
                    kind: .currentLocation,
                    coordinate: currentCoordinate,
                    displayName: "My Location"
                )
            )
        }

        result += savedLocations.map { saved in
            WeatherPage(
                kind: .saved(saved.id),
                coordinate: WeatherPage.Coordinate(lat: saved.lat, lon: saved.lon),
                displayName: saved.displayName
            )
        }

        if let searchResult {
            result.append(
                WeatherPage(
                    kind: .searchResult,
                    coordinate: searchResult.coordinate,
                    displayName: searchResult.name
                )
            )
        }

        return result
    }

    func state(for kind: WeatherPageKind) -> WeatherPageState {
        states[kind] ?? WeatherPageState()
    }

    var selectedState: WeatherPageState { state(for: selection) }

    /// Resolves the world a given page should show, honoring the user's Atlas
    /// customizations. Weather picks the slot (`getSlotForWeather`); Atlas
    /// decides which world that slot shows (`resolveWorld`).
    func resolvedWorld(for kind: WeatherPageKind, overrides: AtlasOverrides) -> ResolvedWorld {
        guard
            let weather = state(for: kind).weather,
            let condition = weather.weather.first
        else {
            return .idle
        }
        let slotId = WeatherDescriptionMapper.getSlotForWeather(
            weatherMain: condition.main,
            tempKelvin: weather.main.temp,
            description: condition.description
        )
        return resolveWorld(slotId: slotId, overrides: overrides)
    }

    /// Mirrors the saved list in. Prunes cached state for locations that were
    /// removed, and keeps the selection valid if the selected page vanished.
    @MainActor
    func syncSavedLocations(_ locations: [SavedLocation]) {
        savedLocations = locations

        let liveIDs = Set(locations.map(\.id))
        for kind in states.keys {
            if case .saved(let savedID) = kind, !liveIDs.contains(savedID) {
                states.removeValue(forKey: kind)
            }
        }

        // Saving the location you searched for would otherwise leave two
        // pages for it — the transient search page and the new saved one.
        // Retire the transient page and hand its already-fetched weather to
        // the saved page so bookmarking doesn't trigger a refetch.
        if let searchResult {
            let searchID = SavedLocation.id(lat: searchResult.coordinate.lat, lon: searchResult.coordinate.lon)
            if liveIDs.contains(searchID) {
                if let carried = states[.searchResult], states[.saved(searchID)] == nil {
                    states[.saved(searchID)] = carried
                }
                states.removeValue(forKey: .searchResult)
                self.searchResult = nil
                if selection == .searchResult {
                    selection = .saved(searchID)
                }
            }
        }

        if case .saved(let savedID) = selection, !liveIDs.contains(savedID) {
            selection = pages.first?.kind ?? .currentLocation
        }
    }

    // MARK: - Loading

    /// Fetches a page's weather unless it's already loaded or in flight.
    /// Safe to call on every appearance.
    @MainActor
    func loadIfNeeded(_ kind: WeatherPageKind) async {
        guard let coordinate = pages.first(where: { $0.kind == kind })?.coordinate else { return }
        let existing = state(for: kind)
        guard !existing.hasLoaded, !existing.isLoading else { return }
        await load(kind, coordinate: coordinate)
    }

    /// Loads the selected page plus its immediate neighbors.
    ///
    /// A paged `TabView` builds all of its children eagerly, so hanging a
    /// per-page `.task` off each one would fire a weather fetch for every
    /// saved location the moment the app launches — up to
    /// `PremiumGate.maxSavedLocations` billable calls that nobody asked for.
    /// Loading a window around the selection keeps swiping in either
    /// direction instant while capping that at three.
    @MainActor
    func loadNeighborhood(around kind: WeatherPageKind) async {
        let all = pages
        guard let index = all.firstIndex(where: { $0.kind == kind }) else { return }

        let neighbors = [index, index - 1, index + 1]
            .filter { all.indices.contains($0) }
            .map { all[$0].kind }

        // Selected first, so the visible page never waits on a neighbor.
        for neighbor in neighbors {
            await loadIfNeeded(neighbor)
        }
    }

    @MainActor
    private func load(_ kind: WeatherPageKind, coordinate: WeatherPage.Coordinate) async {
        var next = state(for: kind)
        next.isLoading = true
        next.error = nil
        states[kind] = next

        do {
            let weather = try await weatherService.fetchWeather(lat: coordinate.lat, lon: coordinate.lon)
            var loaded = state(for: kind)
            loaded.weather = weather
            loaded.isLoading = false
            states[kind] = loaded
            appPhase = .landed
        } catch {
            var failed = state(for: kind)
            failed.isLoading = false
            failed.error = "We couldn't load weather right now. Please try again."
            states[kind] = failed
            // Only fall back to the hero if nothing at all is on screen.
            if !states.values.contains(where: \.hasLoaded) {
                appPhase = .idle
            }
        }
    }

    /// Lands on an arbitrary coordinate, e.g. from search or from tapping a
    /// row in the saved list. If it matches a page we already have, that page
    /// is selected instead of creating a duplicate transient one.
    @MainActor
    func goToLocation(lat: Double, lon: Double, displayName: String? = nil) async {
        locationQuery = ""
        appPhase = .landed

        let savedID = SavedLocation.id(lat: lat, lon: lon)
        if savedLocations.contains(where: { $0.id == savedID }) {
            selection = .saved(savedID)
            await loadIfNeeded(.saved(savedID))
            return
        }

        if let currentCoordinate, SavedLocation.id(lat: currentCoordinate.lat, lon: currentCoordinate.lon) == savedID {
            selection = .currentLocation
            await loadIfNeeded(.currentLocation)
            return
        }

        // Replace any previous transient page and reload it from scratch.
        searchResult = (WeatherPage.Coordinate(lat: lat, lon: lon), displayName ?? "Searched location")
        states[.searchResult] = WeatherPageState()
        selection = .searchResult
        await load(.searchResult, coordinate: WeatherPage.Coordinate(lat: lat, lon: lon))
    }

    // MARK: - Device location

    /// Call once on launch. Failure stays silent, mirroring the web app's
    /// behavior on a denied geolocation prompt — but rather than stranding
    /// someone on the hero when they have saved locations they can't reach
    /// (the pager and its indicator only exist once landed), fall back to
    /// their first saved location.
    @MainActor
    func resolveInitialLocation() async {
        await requestCurrentLocation(surfaceErrors: false)

        guard currentCoordinate == nil, appPhase == .idle, let first = savedLocations.first else { return }
        selection = .saved(first.id)
        appPhase = .landed
        await loadIfNeeded(.saved(first.id))
    }

    /// Explicit "use my location" tap, so failures are surfaced.
    @MainActor
    func useCurrentLocation() async {
        selection = .currentLocation
        await requestCurrentLocation(surfaceErrors: true)
    }

    @MainActor
    private func requestCurrentLocation(surfaceErrors: Bool) async {
        isResolvingLocation = true
        defer { isResolvingLocation = false }

        do {
            let coordinate = try await locationManager.requestOneShotLocation()
            currentCoordinate = WeatherPage.Coordinate(lat: coordinate.latitude, lon: coordinate.longitude)
            // A new fix invalidates whatever the device page was showing.
            states[.currentLocation] = WeatherPageState()
            appPhase = .landed
            await load(.currentLocation, coordinate: currentCoordinate!)
        } catch {
            if surfaceErrors {
                var failed = state(for: .currentLocation)
                failed.error = (error as? LocalizedError)?.errorDescription ?? "We couldn't determine your location."
                states[.currentLocation] = failed
            }
        }
    }

    // MARK: - Compatibility accessors

    /// The weather currently on screen, for call sites that only care about
    /// the selected page.
    var weatherData: WeatherResponse? { selectedState.weather }
    var isWeatherLoading: Bool { selectedState.isLoading }
    var pageError: String? { selectedState.error }

    /// The location currently on screen, suitable for saving. `nil` until a
    /// fetch has actually succeeded.
    var landedLocation: (lat: Double, lon: Double, displayName: String)? {
        guard
            let page = pages.first(where: { $0.kind == selection }),
            let coordinate = page.coordinate,
            let weather = selectedState.weather
        else { return nil }
        return (coordinate.lat, coordinate.lon, weather.name)
    }
}
