import SwiftUI

/// Shared chrome for the utility screens reached from the menu (Settings,
/// Account, Credits): dark background, eyebrow + title header, Close button,
/// and a scrolling content area. Mirrors `AtlasView`'s header treatment so
/// the whole app reads as one surface.
struct MenuScreen<Content: View>: View {
    let eyebrow: String
    let title: String
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#0a0e16").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    content()
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(Color(hex: "#f2f5fa"))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.6))
                Text(title)
                    .font(.custom("PoiretOne-Regular", size: 30))
                    .tracking(0.5)
            }
            Spacer()
            Button("Close") { dismiss() }
                .font(.system(size: 13, weight: .semibold))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(Color(hex: "#f2f5fa"))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Capsule().fill(.white.opacity(0.1)))
                .overlay(Capsule().strokeBorder(.white.opacity(0.2)))
        }
    }
}

/// A tappable row used by the menu screens — leading SF Symbol, title with
/// optional subtitle, and a trailing chevron or status text.
struct MenuRow<Trailing: View>: View {
    let symbol: String
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "#8fc7ff"))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "#f2f5fa"))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.05))
        )
    }
}
