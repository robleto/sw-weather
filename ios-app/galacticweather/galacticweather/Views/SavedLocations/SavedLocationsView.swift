import SwiftUI

/// The app's list screen: every location you can reach, as full-width cards
/// with live conditions, plus the search field for adding a new one.
///
/// This is now a primary surface rather than a settings sub-page — it's where
/// search lives, and it's what a downward flick on the weather pager returns
/// you to. The pager stays uncluttered because everything administrative
/// happens here, including the app menu behind the "…" button.
struct SavedLocationsView: View {
    @Bindable var viewModel: SavedLocationsViewModel
    @Bindable var weatherViewModel: WeatherViewModel
    var atlasViewModel: AtlasViewModel
    var passportViewModel: PassportViewModel
    @Bindable var searchViewModel: LocationSearchViewModel

    /// Whether this screen is actually the one on top. It's a permanently
    /// mounted base layer now rather than a presented cover, so it has to be
    /// told — otherwise its weather refresh fires at launch, behind the
    /// weather screen, for a list nobody has opened.
    var isVisible: Bool
    /// Stands in for `dismiss()`: a base layer can't dismiss itself, it can
    /// only ask for the weather screen to come back over it.
    var onClose: () -> Void

    @State private var editMode: EditMode = .inactive
    @State private var isPaywallOpen = false
    @State private var isAtlasOpen = false
    @State private var isPassportOpen = false
    @State private var isSettingsOpen = false
    @State private var isAccountOpen = false
    @State private var isCreditsOpen = false
    @State private var renaming: SavedLocation?
    @State private var draftName = ""

    private var backgroundColor: Color { Color(hex: "#0a0e16") }
    private var textColor: Color { Color(hex: "#f2f5fa") }
    private var accentColor: Color { Color(hex: "#8fc7ff") }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                list
                searchBar
            }
        }
        .foregroundStyle(textColor)
        .environment(\.editMode, $editMode)
        // Deleting the last saved location would otherwise leave you in an
        // edit mode with nothing left to edit — just the device card, which
        // was never yours to move or remove.
        .onChange(of: viewModel.unlockedLocations.count) { _, count in
            if count == 0, isEditing {
                withAnimation { editMode = .inactive }
            }
        }
        // The one place that fans out beyond the pager's selected-page window,
        // because every card shows a temperature. Bounded by the freshness
        // window, so reopening the list is usually free — and by `isVisible`,
        // so it doesn't fire for a screen sitting unseen under the weather.
        .task(id: isVisible) {
            guard isVisible else { return }
            await weatherViewModel.refreshPagesForList()
        }
        .fullScreenCover(isPresented: $isAtlasOpen) {
            AtlasView(viewModel: atlasViewModel)
        }
        .fullScreenCover(isPresented: $isPassportOpen) {
            PassportView(viewModel: passportViewModel)
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsView(savedLocationsViewModel: viewModel)
        }
        .sheet(isPresented: $isAccountOpen) { AccountView() }
        .sheet(isPresented: $isCreditsOpen) { CreditsView() }
        .sheet(isPresented: $isPaywallOpen) {
            PaywallView(context: .savedLocations)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Rename location", isPresented: renameAlertBinding, presenting: renaming) { location in
            TextField(location.displayName, text: $draftName)
                .autocorrectionDisabled()

            Button("Save") {
                viewModel.rename(location, to: draftName)
                renaming = nil
            }

            if location.isRenamed {
                Button("Use \(location.displayName)") {
                    viewModel.rename(location, to: nil)
                    renaming = nil
                }
            }

            Button("Cancel", role: .cancel) { renaming = nil }
        } message: { location in
            Text("Weather data reports this as \(location.displayName). Call it whatever you like.")
        }
    }

    // MARK: - Header

    /// Title centered with the app menu trailing, mirroring the native
    /// Weather app's list screen. The close chevron leads, and the whole bar
    /// is also a drag handle — attaching the dismiss gesture here rather than
    /// to the screen keeps it from fighting the scroll view underneath.
    private var header: some View {
        ZStack {
            Text("Galactic Weather")
                .font(.system(size: 18, weight: .semibold))

            HStack {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(textColor)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close list")
                .disabled(isEditing)
                .opacity(isEditing ? 0 : 1)

                Spacer()

                if isEditing {
                    doneEditingButton
                } else {
                    appMenu
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    // Not while editing: a drag on the header is how you'd
                    // scroll the list you're reordering, and dismissing
                    // mid-edit would strand the change half-made.
                    guard !isEditing else { return }
                    if value.translation.height > 40 { onClose() }
                }
        )
    }

    /// Replaces the "…" while editing, the way Weather swaps it for a check.
    private var doneEditingButton: some View {
        Button {
            withAnimation { editMode = .inactive }
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(textColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Done editing")
    }

    /// Atlas and Passport sit apart from the utility group: they're the things
    /// people come here to play with, the rest is housekeeping. They pair —
    /// Atlas is the map of where worlds could appear, Passport is where you've
    /// actually been.
    private var appMenu: some View {
        Menu {
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
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.white.opacity(0.1)))
        }
        .accessibilityLabel("Menu")
    }

    // MARK: - Destinations

    /// Atlas and Passport are the two things people come here to play with, so
    /// they get real buttons rather than menu items. They sit where the
    /// save-this-location row used to: that row offered to save whatever page
    /// was selected, which included the device location — never in
    /// `savedLocations`, so it always read as unsaved and the row never went
    /// away. Searched locations are saved from the preview's own add button, so
    /// nothing is lost by dropping it.
    private var destinations: some View {
        // Each detail line appears only once there's something to say —
        // Atlas's after a slot is customized, which a free user can't do at
        // all, and Passport's after the first stamp. So the common case is one
        // card with a second line and one without, which left them visibly
        // different heights side by side. Whenever either has a detail, the
        // other holds the same line open empty rather than shrinking to its
        // own content; when neither does, both stay short.
        let atlas = atlasDetail
        let passport = passportDetail
        let reservesDetailLine = atlas != nil || passport != nil

        return HStack(spacing: 10) {
            destinationButton(
                title: "Atlas",
                detail: atlas,
                reservesDetailLine: reservesDetailLine,
                systemImage: "globe.americas.fill"
            ) { isAtlasOpen = true }

            destinationButton(
                title: "Passport",
                detail: passport,
                reservesDetailLine: reservesDetailLine,
                systemImage: "checkmark.seal.fill"
            ) { isPassportOpen = true }
        }
    }

    private func destinationButton(
        title: String,
        detail: String?,
        reservesDetailLine: Bool,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(accentColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                    if reservesDetailLine {
                        // A space, not an empty string: `Text("")` collapses
                        // to nothing and the card would go back to being the
                        // shorter of the two.
                        Text(detail ?? " ")
                            .font(.system(size: 12))
                            .foregroundStyle(textColor.opacity(0.6))
                    }
                }
                .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(detail.map { "\(title), \($0)" } ?? title)
    }

    private var atlasDetail: String? {
        let count = atlasViewModel.customizedCount
        return count > 0 ? "\(count) customized" : nil
    }

    /// Shows the wild score rather than the total: it's the one that's
    /// completable without paying, so it's the one worth advertising.
    private var passportDetail: String? {
        let progress = passportViewModel.progress
        guard progress.found > 0 else { return nil }
        return "\(progress.wildFound)/\(progress.wildTotal) wild"
    }

    /// Edit List belongs to the list, so it sits under it rather than in the
    /// dropdown, which is now only account and settings. Offered only when
    /// there is something to edit — an edit mode opening onto nothing but the
    /// undeletable device location is a dead end.
    @ViewBuilder
    private var editListRow: some View {
        if !viewModel.unlockedLocations.isEmpty {
            Button {
                withAnimation { editMode = .active }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Edit List")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(textColor.opacity(0.75))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Cards

    /// A `List` rather than a `ScrollView` of cards, entirely so that Edit
    /// List can exist: `.onMove` and `.onDelete` give the drag handles and
    /// red minus buttons the native Weather app shows, with the reorder
    /// mechanics handled by the system. Everything else here is undoing
    /// `List`'s default chrome so the cards still look full-bleed.
    ///
    /// The device location sits outside the `ForEach` on purpose — it's not
    /// yours to delete or reorder, so it gets no controls in edit mode, and
    /// it stays pinned at the top the way it does in Weather.
    ///
    /// Locations past the free cap aren't rendered at all. They were, as
    /// dimmed locked cards — but that's a misdirect: it only happens after a
    /// premium user drops to free, and a wall of padlocks where their places
    /// used to be reads as the app having taken something away. The list
    /// shows what's usable; `upsell` accounts for the rest in words.
    private var list: some View {
        List {
            if !isEditing {
                destinations.plainCardRow()
            }

            if let devicePage = weatherViewModel.pages.first(where: { $0.kind == .currentLocation }) {
                pageCard(devicePage).plainCardRow()
            }

            ForEach(viewModel.unlockedLocations) { location in
                savedCard(location)
                    .plainCardRow()
                    .contextMenu {
                        Button {
                            beginRename(location)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            viewModel.remove(location)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
            }
            .onMove { source, destination in
                viewModel.move(fromOffsets: source, toOffset: destination)
            }
            .onDelete { offsets in
                for location in offsets.map({ viewModel.unlockedLocations[$0] }) {
                    viewModel.remove(location)
                }
            }

            if !isEditing {
                editListRow.plainCardRow()
            }

            if !PremiumGate.isPremium, !isEditing {
                upsell.plainCardRow()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
    }

    private var isEditing: Bool { editMode.isEditing }

    private func savedCard(_ location: SavedLocation) -> some View {
        let kind = WeatherPageKind.saved(location.id)
        return Button {
            // In edit mode the row belongs to the drag/delete controls, not
            // to navigation.
            guard !isEditing else { return }
            if let page = weatherViewModel.pages.first(where: { $0.kind == kind }) {
                Task { await weatherViewModel.select(page: page) }
                onClose()
            }
        } label: {
            SavedLocationCardView(
                name: weatherViewModel.displayName(for: kind),
                mode: cardMode(forKind: kind)
            )
        }
        .buttonStyle(.plain)
    }

    private func pageCard(_ page: WeatherPage) -> some View {
        Button {
            guard !isEditing else { return }
            Task { await weatherViewModel.select(page: page) }
            onClose()
        } label: {
            SavedLocationCardView(
                name: weatherViewModel.displayName(for: page.kind),
                mode: cardMode(for: page)
            )
        }
        .buttonStyle(.plain)
    }

    private func cardMode(for page: WeatherPage) -> SavedLocationCardView.Mode {
        cardMode(forKind: page.kind)
    }

    private func cardMode(forKind kind: WeatherPageKind) -> SavedLocationCardView.Mode {
        guard let weather = weatherViewModel.state(for: kind).weather else { return .loading }
        return .ready(weather, weatherViewModel.resolvedWorld(for: kind, overrides: atlasViewModel.overrides))
    }

    // MARK: - Upsell

    private var upsell: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(upsellText)
                .font(.system(size: 13))
                .foregroundStyle(textColor.opacity(0.7))

            Button("Unlock Premium") { isPaywallOpen = true }
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(accentColor)
                .foregroundStyle(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 8)
    }

    /// A lapsed subscriber gets told, in words, that the locations they can
    /// no longer see still exist. Hiding the cards shouldn't imply the data
    /// was thrown away — and "your 6 places are waiting" is a far better
    /// reason to resubscribe than a generic feature pitch.
    private var upsellText: String {
        let dormant = viewModel.lockedLocations.count
        if dormant > 0 {
            let noun = dormant == 1 ? "location is" : "locations are"
            return "\(dormant) more saved \(noun) still here, waiting. Premium brings them back and takes you to \(PremiumGate.premiumSavedLocationLimit), synced across your devices."
        }
        return "Free includes your current location and \(PremiumGate.freeSavedLocationLimit) saved spot. Premium takes you to \(PremiumGate.premiumSavedLocationLimit), synced across your devices."
    }

    // MARK: - Search

    /// Docked at the bottom, the way the native Weather app docks it — this
    /// screen is the only place you add a location now.
    ///
    /// No "use my location" button beside it any more: the device location is
    /// resolved on launch and pinned to the top of this list, so a button to
    /// fetch the thing already sitting in row one was just noise.
    private var searchBar: some View {
        LocationSearchView(
            viewModel: searchViewModel,
            query: $weatherViewModel.locationQuery,
            variant: .hero,
            dropdownPosition: .above
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 8)
    }

    // MARK: - Rename plumbing

    private var renameAlertBinding: Binding<Bool> {
        Binding(
            get: { renaming != nil },
            set: { if !$0 { renaming = nil } }
        )
    }

    private func beginRename(_ location: SavedLocation) {
        draftName = location.customName ?? ""
        renaming = location
    }
}

private extension View {
    /// Strips a `List` row back to nothing so a full-bleed card can sit in
    /// it: no separator, no default background or selection tint, and insets
    /// that give the same 16pt gutter and 12pt rhythm the cards had in the
    /// scroll view they replaced.
    func plainCardRow() -> some View {
        listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
