import SwiftUI

/// Visual variant for `LocationSearchView`, matching the original web app's
/// two call sites for the same component.
enum LocationSearchVariant {
    /// Compact pill shown in the fixed nav bar once landed.
    case nav
    /// Wide, translucent field shown centered in the idle hero.
    case hero
}

/// Where the candidate/status dropdown opens relative to the text field.
/// Docked at the bottom of the screen, it needs to open upward so it isn't
/// pushed off-screen below the home indicator.
enum LocationSearchDropdownPosition {
    case below
    case above
}

/// Search input plus typeahead dropdown, bound to `LocationSearchViewModel`.
struct LocationSearchView: View {
    @Bindable var viewModel: LocationSearchViewModel
    @Binding var query: String
    var variant: LocationSearchVariant = .nav
    var dropdownPosition: LocationSearchDropdownPosition = .below

    /// Set right before calling `viewModel.selectCandidate(_:)`, whose
    /// `onLocationResolved` callback updates the bound `query` text. Without
    /// this, the resulting `query` mutation would re-trigger `onChange` and
    /// kick off a redundant debounced re-search of the just-resolved name —
    /// mirrors the original TSX's `skipNextEffectRef` guard.
    @State private var skipNextQueryChange = false

    /// Bound to the text field so `select(_:)` can dismiss the keyboard the
    /// moment a candidate is chosen, instead of leaving it up while the
    /// resolved location loads behind it.
    @FocusState private var isFieldFocused: Bool

    private enum Palette {
        static let navFill = Color(hex: "#e4e8f1")
        static let navText = Color(hex: "#333333")
        static let heroText = Color(hex: "#e8f4ff")
        static let heroPlaceholder = Color(hex: "#e8f4ff")
        static let cardBackground = Color(hex: "#3b4154")
        static let rowText = Color(hex: "#f1f4fb")
        static let rowActiveBackground = Color(hex: "#5e6681")
        static let retryBackground = Color(hex: "#e4e8f1")
        static let retryText = Color(hex: "#1f2330")
    }

    /// Gap between the field and the list, matching the web `.candidateList`'s
    /// `top: calc(100% + 6px)`.
    private static let dropdownGap: CGFloat = 6

    var body: some View {
        textField
            .frame(maxWidth: variant == .hero ? 480 : 280)
            // An overlay, not a sibling in a stack: the list has to float over
            // whatever is behind it rather than take layout space.
            //
            // As a stack sibling it did both jobs badly. On `SavedLocationsView`
            // — `VStack { header; list; searchBar }` — the growing dropdown
            // shrank the greedy `List` and shoved the whole thing upward, so
            // typing scrolled the screen out from under you. And in the idle
            // hero's `HStack(alignment: .top)`, the taller stack dragged the
            // "use my location" arrow up to align with the top of the dropdown.
            // Web never had either problem: `.candidateList` is
            // `position: absolute`, which is what this now is.
            .overlay(alignment: dropdownPosition == .above ? .top : .bottom) {
                dropdown
                    .frame(maxWidth: .infinity)
                    .alignmentGuide(dropdownPosition == .above ? .top : .bottom) { d in
                        // Anchors the list's near edge to the field's, then
                        // pushes it clear by the gap. Above: the list's own
                        // bottom becomes its "top" guide, so it hangs upward.
                        dropdownPosition == .above
                            ? d[.bottom] + Self.dropdownGap
                            : d[.top] - Self.dropdownGap
                    }
            }
            .onChange(of: query) { _, newValue in
                if skipNextQueryChange {
                    skipNextQueryChange = false
                    return
                }
                viewModel.search(query: newValue)
            }
    }

    @ViewBuilder
    private var textField: some View {
        TextField("Enter City, ZIP, or lat,lon", text: $query, prompt: placeholderText)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .foregroundStyle(variant == .hero ? Palette.heroText : Palette.navText)
            .padding(.horizontal, variant == .hero ? 18 : 12)
            .frame(height: variant == .hero ? 48 : 34)
            .focused($isFieldFocused)
            .background(fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: variant == .hero ? 24 : 14, style: .continuous))
            .overlay {
                if variant == .hero {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color(hex: "#a0c8ff").opacity(0.4), lineWidth: 1.5)
                }
            }
            .onKeyPress(.downArrow) { moveActiveIndex(by: 1); return .handled }
            .onKeyPress(.upArrow) { moveActiveIndex(by: -1); return .handled }
            .onKeyPress(.escape) { viewModel.activeIndex = -1; return .handled }
            .onKeyPress(.return) {
                guard viewModel.activeIndex >= 0, viewModel.candidates.indices.contains(viewModel.activeIndex) else {
                    return .ignored
                }
                select(viewModel.candidates[viewModel.activeIndex])
                return .handled
            }
    }

    private var placeholderText: Text {
        Text("Enter City, ZIP, or lat,lon")
            .foregroundStyle(variant == .hero ? Palette.heroPlaceholder.opacity(0.55) : Color.gray)
    }

    @ViewBuilder
    private var fieldBackground: some View {
        switch variant {
        case .nav:
            Palette.navFill
        case .hero:
            Rectangle().fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var dropdown: some View {
        // Every candidate list gets shown, including a single hit — nothing
        // resolves without a tap.
        if !viewModel.candidates.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.candidates.enumerated()), id: \.element.id) { index, candidate in
                    Button {
                        select(candidate)
                    } label: {
                        candidateRow(candidate, isActive: index == viewModel.activeIndex)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        if isHovering {
                            viewModel.activeIndex = index
                        }
                    }

                    // Hairlines between rows rather than gaps: the list reads
                    // as one surface you're choosing within, not a stack of
                    // separate chips.
                    if index < viewModel.candidates.count - 1 {
                        Divider()
                            .overlay(Palette.rowText.opacity(0.12))
                            .padding(.leading, 52)
                    }
                }
            }
            .background(dropdownSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.14))
            )
            .shadow(color: .black.opacity(0.45), radius: 20, y: 8)
        } else if !viewModel.message.isEmpty {
            statusPanel {
                VStack(spacing: 8) {
                    Text(viewModel.message)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.rowText.opacity(0.85))
                        .multilineTextAlignment(.center)

                    if viewModel.isApiError {
                        Button("Retry") {
                            viewModel.retry()
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Palette.retryBackground)
                        .foregroundStyle(Palette.retryText)
                        .clipShape(Capsule())
                    }
                }
            }
        } else if viewModel.isLoading {
            statusPanel {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Palette.rowText.opacity(0.7))
                    Text("Searching…")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.rowText.opacity(0.85))
                }
            }
        }
    }

    /// Same surface, corner radius, border and shadow as the candidate list,
    /// so the empty and error states don't look like a different component
    /// than the thing they replace.
    private func statusPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(dropdownSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.14))
            )
            .shadow(color: .black.opacity(0.45), radius: 20, y: 8)
    }

    /// Flag, city, and where the city is — the three things you need to tell
    /// two same-named places apart, which is the whole reason this list
    /// exists. The flag does most of that work before you've read anything.
    private func candidateRow(_ candidate: LocationCandidate, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            Group {
                if let flag = candidate.flag {
                    Text(flag)
                        .font(.system(size: 24))
                } else {
                    // Raw coordinate entries have no country to show.
                    Image(systemName: "location.magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.rowText.opacity(0.6))
                }
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(candidate.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.rowText)
                    .lineLimit(1)

                if !candidate.secondaryText.isEmpty {
                    Text(candidate.secondaryText)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.rowText.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.rowText.opacity(isActive ? 0.7 : 0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? Palette.rowActiveBackground.opacity(0.55) : Color.clear)
        .contentShape(Rectangle())
    }

    /// Material rather than the old flat fill, so the list sits over the
    /// planet art the way the app's other floating chrome does. An explicit
    /// `ZStack` — a bare multi-statement builder here reaches `.background`
    /// as one opaque `TupleView` and its internal layering stops being
    /// something you can reason about.
    private var dropdownSurface: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(Palette.cardBackground.opacity(0.72))
        }
    }

    private func moveActiveIndex(by delta: Int) {
        let count = viewModel.candidates.count
        guard count > 1 else { return }
        if viewModel.activeIndex < 0 {
            viewModel.activeIndex = delta > 0 ? 0 : count - 1
        } else {
            viewModel.activeIndex = ((viewModel.activeIndex + delta) % count + count) % count
        }
    }

    private func select(_ candidate: LocationCandidate) {
        skipNextQueryChange = true
        isFieldFocused = false
        viewModel.selectCandidate(candidate)
    }
}
