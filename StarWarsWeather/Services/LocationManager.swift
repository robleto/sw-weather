import CoreLocation
import Observation

/// Errors thrown by `LocationManager.requestOneShotLocation()`.
enum LocationManagerError: Error, LocalizedError {
    case authorizationDenied
    case authorizationRestricted
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Location access was denied. Enable it in Settings to use your current location."
        case .authorizationRestricted:
            return "Location access is restricted on this device."
        case .locationUnavailable:
            return "Unable to determine your current location."
        }
    }
}

/// An async/await-friendly, one-shot wrapper around `CLLocationManager`
/// (mirrors the web app's single `navigator.geolocation.getCurrentPosition`
/// call on launch — no continuous location updates).
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    /// If no location, error, or authorization change arrives within this
    /// window, the request fails instead of hanging forever. Needed because
    /// `CLLocationManager` simply never calls back at all when there's no
    /// location fix available to it — most notably the iOS Simulator with
    /// its Features → Location menu set to "None", which otherwise leaves
    /// the request (and any UI spinner tied to it) stuck indefinitely.
    private static let timeout: Duration = .seconds(15)

    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var isAwaitingAuthorization = false
    private var timeoutTask: Task<Void, Never>?

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
    }

    /// Requests a single, one-shot location fix, requesting when-in-use
    /// authorization first if needed. Resumes as soon as a location arrives,
    /// an error occurs, authorization is already denied/restricted, or the
    /// timeout above elapses with no response at all.
    @MainActor
    func requestOneShotLocation() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                isAwaitingAuthorization = true
                manager.requestWhenInUseAuthorization()
            case .denied:
                finish(.failure(LocationManagerError.authorizationDenied))
                return
            case .restricted:
                finish(.failure(LocationManagerError.authorizationRestricted))
                return
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            @unknown default:
                finish(.failure(LocationManagerError.authorizationDenied))
                return
            }

            timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: Self.timeout)
                guard !Task.isCancelled else { return }
                self?.finish(.failure(LocationManagerError.locationUnavailable))
            }
        }
    }

    private func finish(_ result: Result<CLLocationCoordinate2D, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        continuation.resume(with: result)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isAwaitingAuthorization else { return }

        switch manager.authorizationStatus {
        case .notDetermined:
            // Still waiting on the user; keep the continuation pending.
            break
        case .authorizedWhenInUse, .authorizedAlways:
            isAwaitingAuthorization = false
            manager.requestLocation()
        case .denied:
            isAwaitingAuthorization = false
            finish(.failure(LocationManagerError.authorizationDenied))
        case .restricted:
            isAwaitingAuthorization = false
            finish(.failure(LocationManagerError.authorizationRestricted))
        @unknown default:
            isAwaitingAuthorization = false
            finish(.failure(LocationManagerError.authorizationDenied))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(.failure(LocationManagerError.locationUnavailable))
            return
        }
        finish(.success(location.coordinate))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(error))
    }
}
