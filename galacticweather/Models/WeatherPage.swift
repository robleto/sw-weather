import Foundation

/// One horizontally-swipeable page on the weather screen.
///
/// The order mirrors the native Weather app: the device's location first,
/// then the user's saved locations in their saved order.
///
/// Searching no longer produces a page. A search result opens as a preview
/// (`WeatherViewModel.preview`) that you either add or discard, so the only
/// things in the deck are places you actually keep.
enum WeatherPageKind: Hashable, Identifiable {
    case currentLocation
    case saved(SavedLocation.ID)

    var id: String {
        switch self {
        case .currentLocation: return "page:current"
        case .saved(let savedID): return "page:saved:\(savedID)"
        }
    }

    /// The device-location page gets an arrow glyph in the page indicator
    /// instead of a plain dot, so "where I am" is distinguishable at a glance.
    var indicatorSymbol: String? {
        switch self {
        case .currentLocation: return "location.fill"
        case .saved: return nil
        }
    }
}

struct WeatherPage: Identifiable, Hashable {
    let kind: WeatherPageKind
    /// `nil` for the device-location page until Core Location resolves it.
    let coordinate: Coordinate?
    /// Fallback label used before weather (which carries the real city name)
    /// has loaded.
    let displayName: String

    var id: WeatherPageKind.ID { kind.id }

    struct Coordinate: Hashable {
        let lat: Double
        let lon: Double
    }
}

/// Per-page load state. Kept separate from the page itself so reordering or
/// re-deriving the page list never discards already-fetched weather.
struct WeatherPageState {
    var weather: WeatherResponse?
    var isLoading = false
    var error: String?
    /// When `weather` was fetched. Drives the saved-locations list's freshness
    /// window so reopening the list doesn't re-bill every card.
    var fetchedAt: Date?

    var hasLoaded: Bool { weather != nil }

    /// Whether this state is recent enough to reuse instead of refetching.
    func isFresh(within ttl: TimeInterval, now: Date = Date()) -> Bool {
        guard hasLoaded, let fetchedAt else { return false }
        return now.timeIntervalSince(fetchedAt) < ttl
    }
}
