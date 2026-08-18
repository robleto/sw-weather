import CoreLocation
import SwiftUI

/// The app's first page: eyebrow line, display heading, and subtext, centred
/// over the idle background. The location search field lives in
/// `ContentView`'s bottom-docked bar instead of here, so this view only owns
/// the copy above it.
///
/// This is a real screen now rather than a flash. Since the permission alert
/// is no longer fired at launch (see
/// `WeatherViewModel.resolveInitialLocation()`), it's what a first run opens
/// on, and where a denial leaves you.
struct IdleHeroView: View {
    var pageError: String?

    /// Only the subtext moves with this — the eyebrow and heading are the same
    /// on every path. Being told "no" to a permission you were asked about
    /// doesn't change what the app is, and swapping the title for an apology
    /// would make a working screen read as a failed one. What changes is the
    /// instruction underneath, because the instruction is what's now wrong.
    var locationStatus: CLAuthorizationStatus = .notDetermined

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 20) {
            Text("Somewhere out there, it feels just like this…")
                .font(.system(size: 12, weight: .medium))
                .tracking(2.5)
                .textCase(.uppercase)
                .foregroundStyle(Color(hex: "#a0c8ff").opacity(0.65))

            Text("Where in the galaxy are you?")
                // PoiretOne, sized up from RussoOne's 40 — it's a hairline
                // face where Russo was a heavy squarish one, so it reads
                // several points smaller at the same size.
                .font(.custom("PoiretOne-Regular", size: 46))
                .tracking(1.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "#e8f4ff"))
                .shadow(color: Color(hex: "#64a0ff").opacity(0.55), radius: 24)

            Text(subtext)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "#c8dcff").opacity(0.6))

            if locationStatus == .denied {
                settingsButton
            }

            if let pageError {
                Text(pageError)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#ffd4d4"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 560)
    }

    /// Every branch names the search field as a way forward, because it always
    /// is one — the app works fully without location, so no state here is a
    /// dead end that has to be resolved before continuing.
    private var subtext: String {
        switch locationStatus {
        case .denied:
            return "Location is off for Galactic Weather, so we can't tell where you are. Search for any place below, or turn location back on in Settings."
        case .restricted:
            return "Location is unavailable on this device. Search for any place below to see which world it feels like today."
        case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
            return "Enter your location to see which world it feels like today"
        @unknown default:
            return "Enter your location to see which world it feels like today"
        }
    }

    /// Shown for `.denied` only. `.restricted` is set by device policy and is
    /// not the user's to change, so sending them to Settings would be sending
    /// them to a switch that isn't there — `.notDetermined` likewise has no row
    /// yet. This mirrors `LocationAuthorization.isChangeableInSettings`.
    private var settingsButton: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 6) {
                Text("Open Settings")
                    .font(.system(size: 14, weight: .semibold))
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color(hex: "#e8f4ff"))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay {
                Capsule()
                    .strokeBorder(Color(hex: "#a0c8ff").opacity(0.4), lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Not determined") {
    IdleHeroView(locationStatus: .notDetermined)
        .background(PlanetTheme.idleBackground)
}

#Preview("Denied") {
    IdleHeroView(locationStatus: .denied)
        .background(PlanetTheme.idleBackground)
}

#Preview("Restricted") {
    IdleHeroView(locationStatus: .restricted)
        .background(PlanetTheme.idleBackground)
}
