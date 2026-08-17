import Foundation

/// One horizontally-swipeable page on the weather screen.
///
/// The order mirrors the native Weather app: the device's location first,
/// then the user's saved locations in their saved order. A location reached
/// by searching (and not saved) is a single transient page pinned to the end
/// — it's replaced by the next search rather than accumulating.
enum WeatherPageKind: Hashable, Identifiable {
    case currentLocation
    case saved(SavedLocation.ID)
    case searchResult

    var id: String {
        switch self {
        case .currentLocation: return "page:current"
        case .saved(let savedID): return "page:saved:\(savedID)"
        case .searchResult: return "page:search"
        }
    }

    /// The device-location page gets an arrow glyph in the page indicator
    /// instead of a plain dot, so "where I am" is distinguishable at a glance.
    var indicatorSymbol: String? {
        switch self {
        case .currentLocation: return "location.fill"
        case .searchResult: return "magnifyingglass"
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

    var hasLoaded: Bool { weather != nil }
}
