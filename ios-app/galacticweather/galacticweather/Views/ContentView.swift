import SwiftUI

/// The app's root view: owns the `WeatherViewModel` and `LocationSearchViewModel`,
/// and mirrors the original web app's idle/landed phase switch — the idle hero
/// over a plain backdrop before anywhere is chosen, and a full-bleed planet
/// photo with the forecast text pinned to the top half once landed.
///
/// Once landed the screen is deliberately bare: planet art, the page dots,
/// and one button out to the list. Search, the app menu, and everything
/// administrative live on `SavedLocationsView` instead — the same split the
/// native Weather app makes. The idle hero keeps its own search field,
/// because with no locations yet there's no list worth opening.
struct ContentView: View {
    @State private var weatherViewModel: WeatherViewModel
    @State private var searchViewModel: LocationSearchViewModel
    @State private var atlasViewModel = AtlasViewModel()
    @State private var passportViewModel = PassportViewModel()
    @State private var savedLocationsViewModel = SavedLocationsViewModel()
    @State private var isListOpen = false
    /// Read, never requested — see `LocationAuthorization`. Observing it here
    /// means a user who leaves for iOS Settings, flips location on and comes
    /// back finds the hero already offering the arrow again, with no relaunch.
    private var locationAuthorization: LocationAuthorization { .shared }
    /// How far the weather screen has been dragged down. Drives the throw —
    /// see `tossGesture`.
    @State private var pagerOffset: CGFloat = 0

    init() {
        let weatherViewModel = WeatherViewModel()
        _weatherViewModel = State(initialValue: weatherViewModel)
        _searchViewModel = State(initialValue: LocationSearchViewModel(
            onLocationResolved: { lat, lon, displayName in
                // Only ever reached by an explicit tap on a dropdown row, and
                // it opens a preview rather than landing — the user decides
                // whether the place is worth keeping. The search field is
                // cleared inside `previewLocation` once that kicks off.
                Task {
                    await weatherViewModel.previewLocation(
                        lat: lat,
                        lon: lon,
                        displayName: displayName
                    )
                }
            }
        ))
    }

    var body: some View {
        // The list is the floor and the weather screen sits on top of it —
        // not a cover presented over the top. That's the whole trick behind
        // the dismissal feeling like the location is thrown off the phone to
        // reveal what was always underneath, rather than the list being
        // hauled up over it.
        GeometryReader { geometry in
            ZStack {
                listScreen

                if !isListOpen {
                    weatherScreen
                        .offset(y: pagerOffset)
                        .zIndex(1)
                        // Removal is driven by `pagerOffset` below, so the
                        // transition only has to handle coming back.
                        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .identity))
                        .simultaneousGesture(tossGesture(screenHeight: geometry.size.height))
                }
            }
            // A `GeometryReader` places its content top-leading at the
            // content's own size rather than filling, so without this the
            // layers size to their contents instead of the screen.
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .task {
            await weatherViewModel.resolveInitialLocation()
        }
        .task {
            await PremiumStore.shared.start()
        }
        // Landing on a world stamps it in the Passport, once it's held still
        // for a moment. `.task(id:)` *is* the dwell: swiping to the next page
        // changes the id, which cancels this before the sleep finishes, so a
        // fast flick through five saved locations leaves no stamps behind.
        .task(id: stampKey) {
            guard let pending = pendingSighting else { return }
            try? await Task.sleep(for: .seconds(PassportViewModel.dwellSeconds))
            guard !Task.isCancelled else { return }
            passportViewModel.record(
                pending.resolved,
                city: pending.city,
                tempF: pending.tempF
            )
        }
        .onAppear {
            weatherViewModel.syncSavedLocations(savedLocationsViewModel.unlockedLocations)
        }
        .onChange(of: savedLocationsViewModel.locations) { _, _ in
            weatherViewModel.syncSavedLocations(savedLocationsViewModel.unlockedLocations)
        }
        // A purchase (or a lapse) changes how many of the saved locations are
        // unlocked, so the pager has to be rebuilt even though the stored
        // list itself didn't change.
        .onChange(of: PremiumGate.isPremium) { _, _ in
            weatherViewModel.syncSavedLocations(savedLocationsViewModel.unlockedLocations)
        }
        // Picking a location from the list — by tapping a card or by
        // searching — is the signal that we're done with the list.
        .onChange(of: weatherViewModel.navigationTick) { _, _ in
            showPager()
        }
        // Presented from here rather than from the list, because the list is
        // no longer a separate presentation context — it's a sibling layer.
        .fullScreenCover(isPresented: previewBinding) {
            LocationPreviewView(
                weatherViewModel: weatherViewModel,
                atlasViewModel: atlasViewModel,
                onAdd: addPreviewedLocation,
                onCancel: { weatherViewModel.cancelPreview() }
            )
        }
    }

    // MARK: - Layers

    private var listScreen: some View {
        SavedLocationsView(
            viewModel: savedLocationsViewModel,
            weatherViewModel: weatherViewModel,
            atlasViewModel: atlasViewModel,
            passportViewModel: passportViewModel,
            searchViewModel: searchViewModel,
            // Its weather refresh is gated on this: as a permanently-mounted
            // base layer its `.task` would otherwise fire every page's fetch
            // at launch, behind a screen nobody is looking at.
            isVisible: isListOpen,
            onClose: { showPager() }
        )
    }

    private var weatherScreen: some View {
        ZStack {
            // Every page paints its own full-bleed art, so the whole planet
            // slides with the swipe rather than the text moving over a fixed
            // background. The idle hero has no page of its own.
            if weatherViewModel.appPhase == .idle {
                PlanetTheme.background(for: "default")
                    .ignoresSafeArea()
                backdropImage(named: PlanetTheme.idleImageName)
                    .ignoresSafeArea()
            } else {
                pager
            }

            // Above the docked bar in the file, and therefore *below* it on
            // screen. The hero used to come last, which put it on top: the
            // idle search dropdown opens upward (`dropdownPosition: .above`)
            // into exactly the space this copy occupies, so a query with
            // several matches drew the heading straight through the results
            // list. ZStack order is z-order, and the floating list has to win.
            if weatherViewModel.appPhase == .idle {
                IdleHeroView(
                    pageError: weatherViewModel.pageError,
                    locationStatus: locationAuthorization.status
                )
            }

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                if weatherViewModel.appPhase == .landed {
                    landedBottomBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                } else {
                    idleSearchBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: weatherViewModel.appPhase)
    }

    // MARK: - Toss-away

    /// Drags the weather screen with the finger and, past a threshold, throws
    /// it the rest of the way off the bottom before swapping it out.
    ///
    /// `simultaneous` so the paged `TabView` keeps its horizontal swipe, and
    /// vertical-dominant only so paging sideways never drags the screen down.
    /// Only the idle hero is exempt — there's nothing to throw away when you
    /// haven't landed anywhere yet.
    private func tossGesture(screenHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard weatherViewModel.appPhase == .landed else { return }
                guard value.translation.height > 0,
                      abs(value.translation.height) > abs(value.translation.width)
                else { return }
                pagerOffset = value.translation.height
            }
            .onEnded { value in
                guard weatherViewModel.appPhase == .landed else { return }

                // Velocity counts as much as distance: a short, fast flick is
                // a toss, and should not need to travel the same way a slow
                // deliberate drag does.
                let flung = value.predictedEndTranslation.height > 420
                let dragged = value.translation.height > screenHeight * 0.22
                guard flung || dragged else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        pagerOffset = 0
                    }
                    return
                }

                // Overshoots the measured height: that height excludes the
                // safe areas, but the planet art bleeds into them, so
                // travelling exactly that far would leave a strip of sky
                // showing at the top as the layer swaps out.
                withAnimation(.easeIn(duration: 0.22)) {
                    pagerOffset = screenHeight + 200
                } completion: {
                    // Swapped only once it's genuinely off-screen, so there's
                    // no flicker as the layer is removed and reset.
                    isListOpen = true
                    pagerOffset = 0
                }
            }
    }

    // MARK: - Passport

    /// What the user is actually looking at, as a stamp candidate.
    ///
    /// The preview wins whenever it's up: it's a full-screen cover over both
    /// the pager and the list, so the selected page is not on screen. A
    /// searched-but-unsaved city still counts — searching other places *is*
    /// the hunt, not a loophole. With the list open and no preview, nothing is
    /// showing a world, so nothing is stamped.
    private var pendingSighting: (resolved: ResolvedWorld, city: String, tempF: Double)? {
        if weatherViewModel.preview != nil {
            guard let weather = weatherViewModel.previewState.weather else { return nil }
            return (
                weatherViewModel.resolvedPreviewWorld(overrides: atlasViewModel.overrides),
                weather.name,
                kelvinToFahrenheit(weather.main.temp)
            )
        }

        guard !isListOpen else { return nil }

        let kind = weatherViewModel.selection
        guard let weather = weatherViewModel.state(for: kind).weather else { return nil }
        return (
            weatherViewModel.resolvedWorld(for: kind, overrides: atlasViewModel.overrides),
            // The user's own name for a place, not the weather station's —
            // it's what's on screen, and it's what they'd recognize later.
            weatherViewModel.displayName(for: kind),
            kelvinToFahrenheit(weather.main.temp)
        )
    }

    /// Restarting the dwell should track "am I looking at a different world in
    /// a different place", nothing finer — a temperature tick shouldn't reset
    /// the clock.
    private var stampKey: String? {
        guard let pending = pendingSighting else { return nil }
        return "\(pending.resolved.planet)|\(pending.city)"
    }

    private func showPager() {
        withAnimation(.easeOut(duration: 0.32)) {
            isListOpen = false
        }
    }

    private var previewBinding: Binding<Bool> {
        Binding(
            get: { weatherViewModel.preview != nil },
            set: { if !$0 { weatherViewModel.cancelPreview() } }
        )
    }

    /// Adding while the list is showing leaves you there — the new card is
    /// the confirmation. Adding from the hero has no list to return to, so it
    /// lands on the location instead.
    private func addPreviewedLocation() -> Bool {
        guard
            let candidate = weatherViewModel.previewSaveCandidate,
            savedLocationsViewModel.canSaveMore
        else { return false }

        savedLocationsViewModel.toggleSaved(
            displayName: candidate.displayName,
            lat: candidate.lat,
            lon: candidate.lon
        )
        weatherViewModel.syncSavedLocations(savedLocationsViewModel.unlockedLocations)
        weatherViewModel.cancelPreview()

        guard !isListOpen else { return true }

        let savedID = SavedLocation.id(lat: candidate.lat, lon: candidate.lon)
        if let page = weatherViewModel.pages.first(where: { $0.kind == .saved(savedID) }) {
            Task { await weatherViewModel.select(page: page) }
        }
        return true
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
                // The top bar is gone — its menu moved to the list screen —
                // so this is just breathing room under the status bar.
                Spacer().frame(height: 24)

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

    /// Everything the landed screen offers: out to the list on the left, and
    /// the dots centered. The list button is padded out to the same width as
    /// the button so the dots sit on the true center of the screen rather
    /// than the center of what's left over.
    private var landedBottomBar: some View {
        ZStack {
            PageIndicatorView(
                pages: weatherViewModel.pages,
                selection: weatherViewModel.selection
            )
            .frame(maxWidth: .infinity)

            HStack {
                listButton
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Takes the same route as the flick, so the button and the gesture read
    /// as the same action rather than two ways out of the screen.
    private var listButton: some View {
        Button {
            withAnimation(.easeIn(duration: 0.26)) {
                isListOpen = true
            }
        } label: {
            Image(systemName: "list.bullet")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().strokeBorder(.white.opacity(0.22)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Locations list")
    }

    /// The cold-start escape hatch. With no device fix and nothing saved
    /// there's no list to open, so the hero keeps a search field of its own —
    /// otherwise declining the location prompt leaves a new user with no way
    /// to reach any weather at all.
    private var idleSearchBar: some View {
        HStack(alignment: .top, spacing: 10) {
            LocationSearchView(
                viewModel: searchViewModel,
                query: $weatherViewModel.locationQuery,
                variant: .hero,
                dropdownPosition: .above
            )

            // Dropped once the answer is fixed at "no": iOS won't re-prompt
            // after a denial, so the arrow could only spin and fail. The hero
            // says why it's gone and offers the one thing that brings it back.
            if locationAuthorization.canRequest {
                currentLocationButton
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// "Use my current location" button, docked right after the search field.
    /// This is now the only thing that triggers the system permission alert —
    /// see `WeatherViewModel.resolveInitialLocation()`.
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
