import SwiftUI

/// The dots-and-icons control docked left of the search field.
///
/// Each page gets a mark: an arrow for the device location, a magnifier for
/// a transient search result, plain dots for saved locations. Tapping opens
/// the full saved list. For free users the whole thing collapses to a single
/// locked affordance that opens the paywall — saved locations are premium,
/// but the control stays visible so the feature sells itself.
struct PageIndicatorView: View {
    let pages: [WeatherPage]
    let selection: WeatherPageKind
    var onTap: () -> Void

    private var accent: Color { Color(hex: "#8fc7ff") }

    var body: some View {
        Button(action: onTap) {
            content
                .frame(height: 48)
                .padding(.horizontal, 12)
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay(Capsule().strokeBorder(.white.opacity(0.22)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        if PremiumGate.canUseSavedLocations {
            // Past a handful of saved locations a full dot row stops being
            // readable and starts being clutter, so fall back to a count.
            if pages.count > 6 {
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(selectedIndex + 1)/\(pages.count)")
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                }
                .foregroundStyle(Color(hex: "#e8f4ff"))
            } else {
                HStack(spacing: 7) {
                    ForEach(pages) { page in
                        mark(for: page)
                    }
                }
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(accent)
        }
    }

    @ViewBuilder
    private func mark(for page: WeatherPage) -> some View {
        let isActive = page.kind == selection

        if let symbol = page.kind.indicatorSymbol {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isActive ? Color(hex: "#e8f4ff") : Color(hex: "#e8f4ff").opacity(0.4))
        } else {
            Circle()
                .fill(isActive ? Color(hex: "#e8f4ff") : Color(hex: "#e8f4ff").opacity(0.35))
                .frame(width: 7, height: 7)
        }
    }

    private var selectedIndex: Int {
        pages.firstIndex { $0.kind == selection } ?? 0
    }

    private var accessibilityLabel: String {
        guard PremiumGate.canUseSavedLocations else {
            return "Saved locations, premium feature"
        }
        return "Saved locations, \(selectedIndex + 1) of \(pages.count). Opens the saved list."
    }
}
