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

    /// A location the user tapped in the search dropdown but hasn't decided
    /// about yet. Held apart from `pages` on purpose: a preview shouldn't add
    /// a dot to the pager or a card to the list until it's been added.
    private(set) var preview: PreviewLocation?
    private(set) var previewState = WeatherPageState()

    struct PreviewLocation: Equatable {
        let coordinate: WeatherPage.Coordinate
        let displayName: String
    }

    private(set) var states: [WeatherPageKind: WeatherPageState] = [:]
    var selection: WeatherPageKind = .currentLocation

    var locationQuery: String = ""
    private(set) var appPhase: AppPhase = .idle
    private(set) var isResolvingLocation = false

    /// Bumped every time the user deliberately navigates to a location.
    ///
    /// The list screen closes on this rather than on `selection`, because
    /// "navigated somewhere" and "selection changed" aren't the same event —
    /// searching for the place you're already looking at, for instance,
    /// leaves the selection untouched but should still close the list.
    private(set) var navigationTick = 0

    /// How long a fetched page stays reusable before the saved-locations list
    /// will refetch it. Long enough that opening the list, tapping into a
    /// place, and flicking back doesn't re-bill anything; short enough that
    /// the temperatures on the cards aren't stale.
    static let freshnessWindow: TimeInterval = 15 * 60

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
                displayName: saved.name
            )
        }

        return result
    }

    func state(for kind: WeatherPageKind) -> WeatherPageState {
        states[kind] ?? WeatherPageState()
    }

    /// The label to show for a page. A saved location's user-chosen name wins
    /// over whatever the weather API reports for those coordinates — renaming
    /// is there precisely because the reported name is often the nearest
    /// station rather than the place someone means.
    func displayName(for kind: WeatherPageKind) -> String {
        let pageName = pages.first { $0.kind == kind }?.displayName
        if case .saved = kind {
            return pageName ?? ""
        }
        return state(for: kind).weather?.name ?? pageName ?? ""
    }

    var selectedState: WeatherPageState { state(for: selection) }

    /// Resolves the world a given page should show, honoring the user's Atlas
    /// customizations. Weather picks the slot (`getSlotForWeather`); Atlas
    /// decides which world that slot shows (`resolveWorld`).
    func resolvedWorld(for kind: WeatherPageKind, overrides: AtlasOverrides) -> ResolvedWorld {
        resolvedWorld(for: state(for: kind).weather, overrides: overrides)
    }

    /// Same resolution for the preview, which deliberately isn't a page.
    func resolvedPreviewWorld(overrides: AtlasOverrides) -> ResolvedWorld {
        resolvedWorld(for: previewState.weather, overrides: overrides)
    }

    private func resolvedWorld(for weather: WeatherResponse?, overrides: AtlasOverrides) -> ResolvedWorld {
        guard
            let weather,
            let condition = weather.weather.first
        else {
            return .idle
        }
        let slotId = WeatherDescriptionMapper.getSlotForWeather(
            conditionCode: condition.id,
            weatherMain: condition.main,
            tempKelvin: weather.main.temp
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

        // Adding the previewed location hands its already-fetched weather to
        // the new saved page, so tapping "+" never triggers a refetch of the
        // forecast the user is looking at while they tap it.
        if let preview {
            let previewID = SavedLocation.id(lat: preview.coordinate.lat, lon: preview.coordinate.lon)
            if liveIDs.contains(previewID), states[.saved(previewID)] == nil, previewState.hasLoaded {
                states[.saved(previewID)] = previewState
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

    /// Loads every page that isn't already fresh, for the saved-locations
    /// list — its cards each show a live temperature, so unlike the pager it
    /// genuinely needs all of them at once.
    ///
    /// This is the one place that deliberately fans out beyond the
    /// selected-page window, so it's bounded twice over: by
    /// `PremiumGate.maxSavedLocations`, and by `freshnessWindow` (reopening
    /// the list inside that window costs nothing). Locked saved locations
    /// aren't pages, so they're never fetched either.
    @MainActor
    func refreshPagesForList() async {
        for page in pages {
            guard let coordinate = page.coordinate else { continue }
            let existing = state(for: page.kind)
            guard !existing.isLoading, !existing.isFresh(within: Self.freshnessWindow) else { continue }
            await load(page.kind, coordinate: coordinate)
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
            loaded.fetchedAt = Date()
            states[kind] = loaded
            appPhase = .landed

            // Fired per successful fetch rather than from a view's appearance,
            // so paging back to an already-loaded world doesn't count twice.
            if let condition = weather.weather.first {
                Analytics.track(
                    AnalyticsSignal.forecastLanded,
                    AnalyticsPayload.forecastLanded(
                        slotId: WeatherDescriptionMapper.getSlotForWeather(
                            conditionCode: condition.id,
                            weatherMain: condition.main,
                            tempKelvin: weather.main.temp
                        )
                    )
                )
            }
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

    /// Jumps to a page that already exists, e.g. from tapping a card in the
    /// list. Distinct from `previewLocation` because there's nothing to
    /// resolve, dedupe, or decide about — the page is right there.
    @MainActor
    func select(page: WeatherPage) async {
        appPhase = .landed
        selection = page.kind
        navigationTick += 1
        await loadIfNeeded(page.kind)
    }

    // MARK: - Preview

    /// Opens a coordinate as a save-or-discard preview, from a tap in the
    /// search dropdown.
    ///
    /// A place you already have isn't previewed — there's nothing to add, so
    /// it just navigates there and reports that with `false`, letting the
    /// caller skip presenting a preview it would immediately have to explain.
    @discardableResult
    @MainActor
    func previewLocation(lat: Double, lon: Double, displayName: String? = nil) async -> Bool {
        locationQuery = ""

        let savedID = SavedLocation.id(lat: lat, lon: lon)
        if savedLocations.contains(where: { $0.id == savedID }) {
            appPhase = .landed
            navigationTick += 1
            selection = .saved(savedID)
            await loadIfNeeded(.saved(savedID))
            return false
        }

        if let currentCoordinate, SavedLocation.id(lat: currentCoordinate.lat, lon: currentCoordinate.lon) == savedID {
            appPhase = .landed
            navigationTick += 1
            selection = .currentLocation
            await loadIfNeeded(.currentLocation)
            return false
        }

        let coordinate = WeatherPage.Coordinate(lat: lat, lon: lon)
        preview = PreviewLocation(coordinate: coordinate, displayName: displayName ?? "Searched location")
        previewState = WeatherPageState(isLoading: true)

        do {
            let weather = try await weatherService.fetchWeather(lat: lat, lon: lon)
            // A second tap while the first was in flight wins; don't let a
            // stale response overwrite the newer preview.
            guard preview?.coordinate == coordinate else { return true }
            previewState = WeatherPageState(weather: weather, isLoading: false, fetchedAt: Date())
        } catch {
            guard preview?.coordinate == coordinate else { return true }
            previewState = WeatherPageState(
                isLoading: false,
                error: "We couldn't load weather right now. Please try again."
            )
        }
        return true
    }

    /// Discards the preview without keeping the location — the "X".
    @MainActor
    func cancelPreview() {
        preview = nil
        previewState = WeatherPageState()
    }

    /// The previewed location as something `SavedLocationsViewModel` can
    /// store. Prefers the name the weather API reported over the geocoder's,
    /// matching what the preview is showing on screen as you tap "+".
    @MainActor
    var previewSaveCandidate: (lat: Double, lon: Double, displayName: String)? {
        guard let preview else { return nil }
        return (
            preview.coordinate.lat,
            preview.coordinate.lon,
            previewState.weather?.name ?? preview.displayName
        )
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
        navigationTick += 1
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
