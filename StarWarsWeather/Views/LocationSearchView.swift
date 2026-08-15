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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if dropdownPosition == .above {
                dropdown
                textField
            } else {
                textField
                dropdown
            }
        }
        .frame(maxWidth: variant == .hero ? 480 : 280)
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
        if viewModel.candidates.count > 1 {
            VStack(spacing: 2) {
                ForEach(Array(viewModel.candidates.enumerated()), id: \.element.id) { index, candidate in
                    Button {
                        select(candidate)
                    } label: {
                        Text(candidate.displayName)
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.rowText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(index == viewModel.activeIndex ? Palette.rowActiveBackground : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        if isHovering {
                            viewModel.activeIndex = index
                        }
                    }
                }
            }
            .padding(4)
            .background(Palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        } else if !viewModel.message.isEmpty {
            VStack(spacing: 6) {
                Text(viewModel.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.rowText)
                    .multilineTextAlignment(.center)

                if viewModel.isApiError {
                    Button("Retry") {
                        viewModel.retry()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Palette.retryBackground)
                    .foregroundStyle(Palette.retryText)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        } else if viewModel.isLoading {
            Text("Resolving location…")
                .font(.system(size: 12))
                .foregroundStyle(Palette.rowText)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Palette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
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
