import SwiftUI

/// The app's root view: owns the `WeatherViewModel` and `LocationSearchViewModel`,
/// and mirrors the original web app's idle/landed phase switch — a hyperspace
/// hero over a starfield while idle, and a full-bleed planet photo with the
/// forecast text pinned to the top half once landed. The location search
/// field is docked at the bottom of the screen in both phases; there is no
/// title bar.
struct ContentView: View {
    @State private var weatherViewModel: WeatherViewModel
    @State private var searchViewModel: LocationSearchViewModel
    @State private var atlasViewModel = AtlasViewModel()
    @State private var savedLocationsViewModel = SavedLocationsViewModel()
    @State private var isAtlasOpen = false
    @State private var isSettingsOpen = false
    @State private var isAccountOpen = false
    @State private var isCreditsOpen = false

    init() {
        let weatherViewModel = WeatherViewModel()
        _weatherViewModel = State(initialValue: weatherViewModel)
        _searchViewModel = State(initialValue: LocationSearchViewModel(
            onLocationResolved: { lat, lon, _ in
                // The search field is cleared inside `goToLocation` itself
                // once the load kicks off, rather than being set to the
                // resolved display name here.
                Task { await weatherViewModel.goToLocation(lat: lat, lon: lon) }
            }
        ))
    }

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            if weatherViewModel.appPhase == .idle {
                HyperspaceStarsView()
                    .ignoresSafeArea()
            }

            if let planetImageName = landedPlanetImageName {
                backdropImage(named: planetImageName)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                if weatherViewModel.appPhase == .landed {
                    topBar
                        .padding(.top, 8)
                }

                topContent
                    .padding(.top, weatherViewModel.appPhase == .landed ? 12 : 32)

                Spacer(minLength: 0)

                bottomSearchBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: weatherViewModel.appPhase)
        .task {
            await weatherViewModel.resolveInitialLocation()
        }
        .task {
            await PremiumStore.shared.start()
        }
        .fullScreenCover(isPresented: $isAtlasOpen) {
            AtlasView(viewModel: atlasViewModel)
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView(
                savedLocationsViewModel: savedLocationsViewModel,
                weatherViewModel: weatherViewModel
            )
        }
        .sheet(isPresented: $isAccountOpen) {
            AccountView()
        }
        .sheet(isPresented: $isCreditsOpen) {
            CreditsView()
        }
    }

    /// Weather picks the slot; Atlas decides which world that slot
    /// shows. Computed once here and threaded down, mirroring the web app's
    /// `page.tsx` composition of `useAtlas` + `resolveWorld`.
    private var weatherInfo: ResolvedWorld {
        weatherViewModel.resolvedWorld(overrides: atlasViewModel.overrides)
    }

    private var landedPlanetImageName: String? {
        guard weatherViewModel.appPhase == .landed, weatherViewModel.weatherData != nil else {
            return nil
        }
        return PlanetTheme.imageName(for: weatherInfo.planet)
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

    @ViewBuilder
    private var backgroundLayer: some View {
        switch weatherViewModel.appPhase {
        case .idle:
            PlanetTheme.background(for: "default")
        case .landed:
            PlanetTheme.background(for: weatherInfo.planet)
        }
    }

    /// Nav bar shown once weather is showing: a single, deliberately quiet
    /// menu button in the trailing corner. The planet art is the point of
    /// this screen, so navigation stays out of its way until asked for.
    private var topBar: some View {
        HStack(spacing: 10) {
            Spacer()
            menuButton
        }
        .padding(.horizontal, 20)
    }

    /// Atlas sits apart from the utility group: it's the thing people come
    /// here to play with, the rest is housekeeping.
    private var menuButton: some View {
        Menu {
            Button {
                isAtlasOpen = true
            } label: {
                Label(atlasMenuTitle, systemImage: "globe.americas")
            }

            Section {
                Button {
                    isSettingsOpen = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }

                Button {
                    isAccountOpen = true
                } label: {
                    Label("Account", systemImage: "person.crop.circle")
                }

                Button {
                    isCreditsOpen = true
                } label: {
                    Label("Credits", systemImage: "info.circle")
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().strokeBorder(.white.opacity(0.22)))
        }
        .accessibilityLabel("Menu")
    }

    /// Surfaces the customization count in the menu item itself, since the
    /// old badge on the nav button is gone.
    private var atlasMenuTitle: String {
        let count = atlasViewModel.customizedCount
        return count > 0 ? "Atlas (\(count) customized)" : "Atlas"
    }

    @ViewBuilder
    private var topContent: some View {
        switch weatherViewModel.appPhase {
        case .idle:
            HyperspaceHeroView(pageError: weatherViewModel.pageError)

        case .landed:
            VStack(spacing: 12) {
                // Shown while the first fetch is still loading, or if a later
                // "use my location" retry fails while old weather is still on
                // screen (goToLocation's failure path doesn't clear weatherData
                // unless the failing call is itself the one landing the app).
                if weatherViewModel.weatherData == nil || weatherViewModel.pageError != nil {
                    statusLine
                }

                WeatherDetailsView(weatherViewModel: weatherViewModel, weatherInfo: weatherInfo)
            }
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if let pageError = weatherViewModel.pageError {
            Text(pageError)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#ffd4d4"))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
        } else {
            Text(weatherViewModel.isWeatherLoading ? "Loading weather…" : "Preparing forecast…")
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
        }
    }

    private var bottomSearchBar: some View {
        HStack(alignment: .top, spacing: 10) {
            // Search is available to everyone — see the note in `PremiumGate`.
            // Without it, declining the location prompt leaves a free user with
            // no way to reach any weather at all.
            LocationSearchView(
                viewModel: searchViewModel,
                query: $weatherViewModel.locationQuery,
                variant: .hero,
                dropdownPosition: .above
            )

            currentLocationButton
        }
        .frame(maxWidth: .infinity)
    }

    /// "Use my current location" button, docked right after the search field.
    private var currentLocationButton: some View {
        Button {
            Task { await weatherViewModel.useCurrentLocation() }
        } label: {
            Group {
                if weatherViewModel.isResolvingLocation {
                    ProgressView()
                        .tint(Color(hex: "#e8f4ff"))
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(hex: "#e8f4ff"))
                }
            }
            .frame(width: 48, height: 48)
            .background(Circle().fill(.ultraThinMaterial))
            .overlay {
                Circle()
                    .strokeBorder(Color(hex: "#a0c8ff").opacity(0.4), lineWidth: 1.5)
            }
        }
        .disabled(weatherViewModel.isResolvingLocation)
        .accessibilityLabel("Use current location")
    }
}

#Preview {
    ContentView()
}
