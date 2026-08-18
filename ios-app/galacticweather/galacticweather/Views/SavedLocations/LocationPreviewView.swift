import SwiftUI

/// A searched location shown full-screen before you commit to it: the same
/// planet art and forecast a real page would show, with an X to discard and
/// a "+" to keep.
///
/// Looking is free and leaves no trace — nothing enters the collection, the
/// pager, or the list until "+" is tapped. That's what lets a free user who
/// has spent their one slot still check the weather anywhere, which is also
/// the moment the upgrade makes the most sense to them.
struct LocationPreviewView: View {
    var weatherViewModel: WeatherViewModel
    var atlasViewModel: AtlasViewModel
    /// Returns whether the save succeeded. `false` means the collection is
    /// full, and this view raises the alert about it.
    var onAdd: () -> Bool
    var onCancel: () -> Void

    @State private var isFullAlertShown = false
    @State private var isPaywallOpen = false

    var body: some View {
        ZStack {
            let world = weatherViewModel.resolvedPreviewWorld(overrides: atlasViewModel.overrides)
            let state = weatherViewModel.previewState

            PlanetTheme.background(for: state.hasLoaded ? world.planet : "default")
                .ignoresSafeArea()

            if state.hasLoaded {
                backdropImage(named: PlanetTheme.imageName(for: world.planet))
                    .ignoresSafeArea()
            }

            VStack(spacing: 12) {
                Spacer().frame(height: 56)

                if let error = state.error {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#ffd4d4"))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                } else if !state.hasLoaded {
                    Text("Loading weather…")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }

                if let weather = state.weather {
                    WeatherDetailsView(
                        weatherData: weather,
                        weatherInfo: world,
                        locationName: weather.name
                    )
                }

                Spacer(minLength: 0)
            }

            VStack {
                topBar
                Spacer()
                addButton
                notSavedNote
                    .padding(.top, 10)
                    .padding(.bottom, 16)
            }
        }
        .alert("No room left", isPresented: $isFullAlertShown) {
            if PremiumGate.isPremium {
                Button("OK", role: .cancel) {}
            } else {
                Button("Unlock Premium") { isPaywallOpen = true }
                Button("Not now", role: .cancel) {}
            }
        } message: {
            Text(fullAlertMessage)
        }
        .sheet(isPresented: $isPaywallOpen) {
            PaywallView(context: .savedLocations)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var fullAlertMessage: String {
        let slots = PremiumGate.maxSavedLocations
        let noun = slots == 1 ? "location" : "locations"
        if PremiumGate.isPremium {
            return "You've saved all \(slots) \(noun). Remove one to save this one."
        }
        return "Free includes \(slots) saved \(noun). Remove it to save this one, or unlock Premium for \(PremiumGate.premiumSavedLocationLimit)."
    }

    /// Just the X, in the same trailing corner every other screen dismisses
    /// from. Adding lives at the bottom — see `addButton`.
    private var topBar: some View {
        HStack {
            Spacer()
            CloseButton(action: onCancel)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    /// Bottom center, in the spot the pager's dots occupy — this screen has
    /// no deck to page through, so the slot is free, and it's the one place
    /// on the layout the thumb is already going. Labelled rather than a bare
    /// glyph: "+" alone doesn't say what it adds you to.
    private var addButton: some View {
        Button {
            if !onAdd() {
                isFullAlertShown = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                Text("ADD")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(1.8)
            }
            .foregroundStyle(Color(hex: "#e8f4ff"))
            .frame(height: 48)
            .padding(.horizontal, 26)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(Color(hex: "#a0c8ff").opacity(0.4), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add this location to your collection")
    }

    /// "Not saved", under the Add button rather than in the readout.
    ///
    /// It started as a badge in the middle of the forecast text, which put a
    /// piece of app state inside the one block on this screen that is purely
    /// about the weather — it read as though the location itself were unsaved
    /// weather. Down here it sits with the control that resolves it, so the
    /// status and its remedy are one thing to look at instead of two.
    private var notSavedNote: some View {
        Text("Not saved")
            .font(.system(size: 12))
            .tracking(0.6)
            .foregroundStyle(.white.opacity(0.65))
            .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
            .accessibilityLabel("This location is not saved")
    }

    @ViewBuilder
    private func backdropImage(named name: String) -> some View {
        GeometryReader { geometry in
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                .clipped()
        }
    }
}
