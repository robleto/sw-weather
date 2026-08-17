import SwiftUI

/// Utility settings. Currently hosts Saved Locations; this is the shelf that
/// future preferences (units, default location, app icon) land on.
struct SettingsView: View {
    @Bindable var savedLocationsViewModel: SavedLocationsViewModel
    var weatherViewModel: WeatherViewModel

    @State private var isSavedLocationsOpen = false

    var body: some View {
        MenuScreen(eyebrow: "SETTINGS", title: "Preferences") {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    isSavedLocationsOpen = true
                } label: {
                    MenuRow(
                        symbol: "bookmark.fill",
                        title: "Saved locations",
                        subtitle: savedLocationsSubtitle
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .buttonStyle(.plain)

                Text("More preferences are on the way — units, a default location, and alternate app icons.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
            }
        }
        .sheet(isPresented: $isSavedLocationsOpen) {
            SavedLocationsView(
                viewModel: savedLocationsViewModel,
                weatherViewModel: weatherViewModel
            )
            .presentationDetents([.fraction(0.7), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: "#0a0e16"))
        }
    }

    private var savedLocationsSubtitle: String {
        guard PremiumGate.canUseSavedLocations else {
            return "Premium — bookmark your favorite spots"
        }
        let count = savedLocationsViewModel.locations.count
        if count == 0 {
            return "None saved yet"
        }
        return "\(count) of \(PremiumGate.maxSavedLocations) saved"
    }
}
