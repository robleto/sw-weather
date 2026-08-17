import SwiftUI
import UIKit

/// Utility settings — the shelf that future preferences (units, default
/// location, app icon) land on.
///
/// Briefly folded into Atlas on the grounds that it only had one row left.
/// Put back: Atlas is a creative surface you go to on purpose, settings is
/// housekeeping you go to when something needs changing, and burying the
/// second at the foot of the first made both worse. Thin is fine.
///
/// Saved locations used to be reached from here. They're their own screen
/// now, and it's reachable from the same menu, so this reports the slot
/// count rather than linking sideways to it.
struct SettingsView: View {
    @Bindable var savedLocationsViewModel: SavedLocationsViewModel
    @Bindable private var settings = AppSettings.shared

    @Environment(\.openURL) private var openURL

    /// Computed, not stored: a private stored property would make the
    /// synthesized memberwise initializer private too, and call sites need it.
    /// Observation still tracks the read, so the row updates when the
    /// permission changes.
    @MainActor
    private var locationAuthorization: LocationAuthorization { .shared }

    var body: some View {
        MenuScreen(eyebrow: "SETTINGS", title: "Preferences") {
            VStack(alignment: .leading, spacing: 10) {
                MenuRow(
                    symbol: "thermometer.medium",
                    title: "Temperature",
                    subtitle: temperatureSubtitle
                ) {
                    Picker("Temperature unit", selection: $settings.temperatureUnit) {
                        ForEach(TemperatureUnit.allCases) { unit in
                            Text(unit.shortLabel).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 108)
                }

                locationRow

                MenuRow(
                    symbol: "bookmark.fill",
                    title: "Saved locations",
                    subtitle: savedLocationsSubtitle
                ) {
                    EmptyView()
                }

                Text("More preferences are on the way — a default location and alternate app icons.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
            }
        }
    }

    /// Reports the permission and, where it's actually changeable, hands off
    /// to iOS Settings.
    ///
    /// The app can't grant this itself, and once someone has denied it iOS
    /// won't prompt again — so an in-app "use my location" button would fail
    /// silently forever. This row is the honest version of that button: it
    /// says what the state is and takes you to the one place it can change.
    @ViewBuilder
    private var locationRow: some View {
        let row = MenuRow(
            symbol: locationSymbol,
            title: "Location",
            subtitle: locationAuthorization.summary
        ) {
            if locationAuthorization.isChangeableInSettings {
                HStack(spacing: 4) {
                    Text("iOS Settings")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#8fc7ff"))
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#8fc7ff"))
                }
            }
        }

        if locationAuthorization.isChangeableInSettings {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                row
            }
            .buttonStyle(.plain)
        } else {
            row
        }
    }

    private var locationSymbol: String {
        switch locationAuthorization.status {
        case .authorizedWhenInUse, .authorizedAlways: return "location.fill"
        case .denied, .restricted: return "location.slash.fill"
        default: return "location"
        }
    }

    /// Says where the starting value came from, so someone who never set this
    /// isn't left wondering whether the app guessed or they once chose.
    private var temperatureSubtitle: String {
        settings.temperatureUnit == TemperatureUnit.deviceDefault
            ? "Matching your region"
            : "\(TemperatureUnit.deviceDefault.shortLabel) in your region"
    }

    private var savedLocationsSubtitle: String {
        let slots = PremiumGate.maxSavedLocations
        let noun = slots == 1 ? "slot" : "slots"
        let count = savedLocationsViewModel.locations.count
        if count == 0 {
            return "None saved yet — \(slots) \(noun) available"
        }
        return "\(count) saved, \(slots) \(noun) unlocked"
    }
}
