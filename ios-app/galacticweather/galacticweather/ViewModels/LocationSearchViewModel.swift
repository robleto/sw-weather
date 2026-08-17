import Foundation
import Observation

/// Port of the debounced-search logic originally in the web app's
/// `LocationSearch` component: parses/geocodes the query as the user types
/// and reports a resolved location back to the caller.
@Observable
@MainActor
final class LocationSearchViewModel {
    private(set) var candidates: [LocationCandidate] = []
    var activeIndex: Int = -1
    private(set) var message: String = ""
    private(set) var isApiError = false
    private(set) var isLoading = false

    private let geocodeService: GeocodeService
    private let geocodeCache: GeocodeCache
    private let onLocationResolved: (_ lat: Double, _ lon: Double, _ displayName: String) -> Void

    private var searchTask: Task<Void, Never>?
    private var lastQuery: String = ""

    private static let debounceNanoseconds: UInt64 = 450_000_000
    /// Matches the original's exact wording/punctuation, including the em dash.
    private static let noResultsMessage = "No matches found\u{2014}try City, State or City, Country."
    private static let apiErrorMessage = "We couldn't resolve that location. Please try again."

    init(
        geocodeService: GeocodeService = GeocodeService(),
        geocodeCache: GeocodeCache = GeocodeCache(),
        onLocationResolved: @escaping (_ lat: Double, _ lon: Double, _ displayName: String) -> Void
    ) {
        self.geocodeService = geocodeService
        self.geocodeCache = geocodeCache
        self.onLocationResolved = onLocationResolved
    }

    /// Call whenever the search text changes. Cancels any in-flight debounce
    /// task and starts a new debounced search for `query`.
    func search(query: String) {
        lastQuery = query
        startSearch(query: query)
    }

    /// Re-runs the search flow again for the current query text (used by a
    /// Retry button shown next to API-error messages).
    func retry() {
        startSearch(query: lastQuery)
    }

    /// Call when the user explicitly taps a candidate in the list. No debounce
    /// wait — this is an explicit user action, not a text-change event.
    func selectCandidate(_ candidate: LocationCandidate) {
        searchTask?.cancel()
        candidates = []
        activeIndex = -1
        message = ""
        isApiError = false
        isLoading = false
        onLocationResolved(candidate.lat, candidate.lon, candidate.displayName)
    }

    private func startSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.runSearch(query: query)
        }
    }

    private func runSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            candidates = []
            activeIndex = -1
            message = ""
            isApiError = false
            isLoading = false
            return
        }

        isLoading = true
        message = ""
        isApiError = false

        try? await Task.sleep(nanoseconds: Self.debounceNanoseconds)
        if Task.isCancelled { return }

        switch LocationQueryParser.parseLocationQuery(trimmed) {
        case .empty:
            candidates = []
            activeIndex = -1
            isLoading = false

        case .coordinates(let lat, let lon, _):
            // Offered as a one-row dropdown rather than resolved on the spot.
            // Nothing here resolves without an explicit tap — see the note on
            // `resolveGeocode`.
            candidates = [
                LocationCandidate(
                    name: "\(Self.jsNumberString(lat)), \(Self.jsNumberString(lon))",
                    regionOrState: "",
                    country: "",
                    lat: lat,
                    lon: lon
                )
            ]
            activeIndex = 0
            isLoading = false

        case .geocode(let queryText, let normalizedQuery):
            await resolveGeocode(query: queryText, normalizedQuery: normalizedQuery)
        }
    }

    /// Formats a `Double` the way JavaScript's `Number` stringification does
    /// for the plain lat/lon values this app deals with (e.g. `40.0` -> `"40"`,
    /// `-74.25` -> `"-74.25"`), matching `${parsed.lat}, ${parsed.lon}` in the
    /// original LocationSearch.tsx rather than Swift's default `"40.0"`.
    private static func jsNumberString(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0, abs(value) < 1e15 {
            return String(Int64(value))
        }
        return String(value)
    }

    private func resolveGeocode(query: String, normalizedQuery: String) async {
        defer { isLoading = false }

        do {
            let results: [LocationCandidate]
            if let cached = geocodeCache.read(normalizedQuery: normalizedQuery) {
                results = cached
            } else {
                results = try await geocodeService.geocode(query: query)
                if Task.isCancelled { return }
                geocodeCache.write(normalizedQuery: normalizedQuery, results: results)
            }

            if Task.isCancelled { return }

            if results.isEmpty {
                candidates = []
                activeIndex = -1
                message = Self.noResultsMessage
            } else {
                // A lone result is still offered as a dropdown row rather than
                // resolved for you. Typing is not choosing: auto-resolving on
                // the way past "Lond" to "London" pulled up whole locations
                // mid-keystroke, and now that landing on a location opens a
                // save-or-discard preview, doing it unasked is worse still.
                candidates = results
                activeIndex = 0
            }
        } catch {
            if !Task.isCancelled {
                candidates = []
                activeIndex = -1
                message = Self.apiErrorMessage
                isApiError = true
            }
        }
    }
}
