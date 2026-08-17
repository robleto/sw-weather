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
    @State private var isSavedLocationsOpen = false
    @State private var isSavedPaywallOpen = false

    init() {
        let weatherViewModel = WeatherViewModel()
        _weatherViewModel = State(initialValue: weatherViewModel)
        _searchViewModel = State(initialValue: LocationSearchViewModel(
            onLocationResolved: { lat, lon, displayName in
                // The search field is cleared inside `goToLocation` itself
                // once the load kicks off, rather than being set to the
                // resolved display name here — the name instead labels the
                // transient page the search lands on.
                Task {
                    await weatherViewModel.goToLocation(
                        lat: lat,
                        lon: lon,
                        displayName: displayName
                    )
                }
            }
        ))
    }

    var body: some View {
        ZStack {
            // Every page paints its own full-bleed art, so the whole planet
            // slides with the swipe rather than the text moving over a fixed
            // background. The idle hero has no page of its own.
            if weatherViewModel.appPhase == .idle {
                PlanetTheme.background(for: "default")
                    .ignoresSafeArea()
                HyperspaceStarsView()
                    .ignoresSafeArea()
            } else {
                pager
            }

            VStack(spacing: 0) {
                if weatherViewModel.appPhase == .landed {
                    topBar
                        .padding(.top, 8)
                }

                Spacer(minLength: 0)

                bottomSearchBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }

            if weatherViewModel.appPhase == .idle {
                HyperspaceHeroView(pageError: weatherViewModel.pageError)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: weatherViewModel.appPhase)
        .task {
            await weatherViewModel.resolveInitialLocation()
        }
        .task {
            await PremiumStore.shared.start()
        }
        .onAppear {
            weatherViewModel.syncSavedLocations(savedLocationsViewModel.locations)
        }
        .onChange(of: savedLocationsViewModel.locations) { _, locations in
            weatherViewModel.syncSavedLocations(locations)
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
        .sheet(isPresented: $isSavedLocationsOpen) {
            SavedLocationsView(viewModel: savedLocationsViewModel, weatherViewModel: weatherViewModel)
                .presentationDetents([.fraction(0.7), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(hex: "#0a0e16"))
        }
        .sheet(isPresented: $isSavedPaywallOpen) {
            PaywallView(context: .savedLocations)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    /// One page per location, swiped horizontally. The page indicator lives
    /// next to the search field instead of TabView's own centered dots, so
    /// it doesn't collide with the docked search bar.
    private var pager: some View {
        TabView(selection: pageSelection) {
            ForEach(weatherViewModel.pages) { page in
                weatherPage(page)
                    .tag(page.kind)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .task(id: weatherViewModel.selection) {
            await weatherViewModel.loadNeighborhood(around: weatherViewModel.selection)
        }
    }

    /// Clamps the selection to a page that actually exists. Removing the
    /// saved location you were looking at (or having no device fix yet) would
    /// otherwise leave `TabView` pointing at nothing, which renders blank.
    private var pageSelection: Binding<WeatherPageKind> {
        Binding(
            get: {
                let pages = weatherViewModel.pages
                if pages.contains(where: { $0.kind == weatherViewModel.selection }) {
                    return weatherViewModel.selection
                }
                return pages.first?.kind ?? .currentLocation
            },
            set: { weatherViewModel.selection = $0 }
        )
    }

    private func weatherPage(_ page: WeatherPage) -> some View {
        let state = weatherViewModel.state(for: page.kind)
        let info = weatherViewModel.resolvedWorld(for: page.kind, overrides: atlasViewModel.overrides)

        return ZStack {
            PlanetTheme.background(for: state.hasLoaded ? info.planet : "default")
                .ignoresSafeArea()

            if state.hasLoaded {
                backdropImage(named: PlanetTheme.imageName(for: info.planet))
                    .ignoresSafeArea()
            }

            VStack(spacing: 12) {
                // Leaves room for the top bar, which floats above the pager.
                Spacer().frame(height: 56)

                if !state.hasLoaded || state.error != nil {
                    statusLine(for: state)
                }

                if let weather = state.weather {
                    WeatherDetailsView(
                        weatherData: weather,
                        weatherInfo: info,
                        locationName: weatherViewModel.displayName(for: page.kind)
                    )
                }

                Spacer(minLength: 0)
            }
        }
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
    private func statusLine(for state: WeatherPageState) -> some View {
        if let error = state.error {
            Text(error)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#ffd4d4"))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
        } else {
            Text(state.isLoading ? "Loading weather…" : "Preparing forecast…")
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
        }
    }

    private var bottomSearchBar: some View {
        HStack(alignment: .top, spacing: 10) {
            // Only meaningful once there are pages to move between, so it
            // stays out of the idle hero.
            if weatherViewModel.appPhase == .landed {
                PageIndicatorView(
                    pages: weatherViewModel.pages,
                    selection: weatherViewModel.selection
                ) {
                    if PremiumGate.canUseSavedLocations {
                        isSavedLocationsOpen = true
                    } else {
                        isSavedPaywallOpen = true
                    }
                }
            }

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
