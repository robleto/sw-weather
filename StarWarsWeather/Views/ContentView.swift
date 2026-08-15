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
                topContent
                    .padding(.top, 32)

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
    }

    private var landedPlanetImageName: String? {
        guard weatherViewModel.appPhase == .landed, weatherViewModel.weatherData != nil else {
            return nil
        }
        return PlanetTheme.imageName(for: weatherViewModel.weatherInfo.planet)
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
            PlanetTheme.background(for: weatherViewModel.weatherInfo.planet)
        }
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

                WeatherDetailsView(weatherViewModel: weatherViewModel)
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
