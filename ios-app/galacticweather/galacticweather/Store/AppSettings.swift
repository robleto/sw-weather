import Foundation
import Observation

/// User preferences that aren't the operating system's to hold.
///
/// The line is permissions vs. preferences: location and notification *grants*
/// live in Settings.app and can only be deep-linked to from here, but how a
/// temperature is written is entirely the app's business and belongs where
/// people will actually look for it. Deliberately not a `Settings.bundle` —
/// those are for configuration nobody touches, and this is on screen
/// constantly.
///
/// Same Observation contract as `PremiumStore`: a SwiftUI `body` that reads
/// `AppSettings.shared.temperatureUnit` is tracked automatically and redraws
/// on change, so read sites need no property wrapper.
@Observable
@MainActor
final class AppSettings {
    static let shared = AppSettings()

    private enum Key {
        static let temperatureUnit = "settings.temperatureUnit"
    }

    private let defaults: UserDefaults

    var temperatureUnit: TemperatureUnit {
        didSet {
            guard temperatureUnit != oldValue else { return }
            defaults.set(temperatureUnit.rawValue, forKey: Key.temperatureUnit)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Absent key falls back to the region rather than being written on
        // first launch, so someone who never opens Settings keeps tracking
        // their locale if they move.
        let stored = defaults.string(forKey: Key.temperatureUnit)
        temperatureUnit = stored.flatMap(TemperatureUnit.init(rawValue:)) ?? .deviceDefault
    }
}
