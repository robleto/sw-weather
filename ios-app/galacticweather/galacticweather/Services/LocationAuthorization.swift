import CoreLocation
import Observation

/// Read-only view of the app's location permission, for the Settings screen.
///
/// Separate from `LocationManager`, which exists to *request* a one-shot fix
/// and is owned by `WeatherViewModel`. This one never requests anything —
/// constructing a `CLLocationManager` and reading `authorizationStatus`
/// doesn't prompt, so a user browsing Settings is never ambushed by a
/// permission dialog.
///
/// Delegate-backed rather than polled: `locationManagerDidChangeAuthorization`
/// fires when the status changes in iOS Settings, so the row is already
/// correct by the time the user switches back to the app.
@Observable
final class LocationAuthorization: NSObject, CLLocationManagerDelegate {
    @MainActor static let shared = LocationAuthorization()

    private(set) var status: CLAuthorizationStatus

    private let manager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.status = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    /// Whether sending someone to iOS Settings would actually let them change
    /// anything. `.notDetermined` has no row there yet, and `.restricted` is
    /// set by device policy and not theirs to change.
    var isChangeableInSettings: Bool {
        switch status {
        case .denied, .authorizedWhenInUse, .authorizedAlways: return true
        case .notDetermined, .restricted: return false
        @unknown default: return false
        }
    }

    /// Whether an in-app "use my location" control could still do anything.
    /// Once denied or restricted iOS won't prompt again, so such a control can
    /// only ever fail — the honest move is to not offer it and point at
    /// Settings instead, the same reasoning `SettingsView.locationRow` makes.
    var canRequest: Bool {
        switch status {
        case .notDetermined, .authorizedWhenInUse, .authorizedAlways: return true
        case .denied, .restricted: return false
        @unknown default: return false
        }
    }

    var summary: String {
        switch status {
        case .notDetermined:
            return "You'll be asked the first time it's used"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Allowed while using the app"
        case .denied:
            return "Denied — your location won't appear in the list"
        case .restricted:
            return "Restricted by this device's policy"
        @unknown default:
            return "Unavailable"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
    }
}

extension CLAuthorizationStatus {
    /// True only when a location fix can be had without showing the user
    /// anything. `.notDetermined` is deliberately false: it *would* succeed,
    /// but only by prompting.
    var isAuthorized: Bool {
        switch self {
        case .authorizedWhenInUse, .authorizedAlways: return true
        case .notDetermined, .denied, .restricted: return false
        @unknown default: return false
        }
    }
}
