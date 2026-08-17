import SwiftUI

/// The canonical list of what premium unlocks, in one place so the paywall,
/// the Account screen, and the in-context upsells can't drift apart.
struct PremiumPerk: Identifiable {
    let id: String
    let symbol: String
    let title: String
    let detail: String

    static let all: [PremiumPerk] = [
        PremiumPerk(
            id: "worlds",
            symbol: "globe.americas.fill",
            title: "Every world",
            detail: "Unlock all \(AtlasCatalog.premiumWorldCount) locked worlds — and every new one added later."
        ),
        PremiumPerk(
            id: "rotation",
            symbol: "shuffle",
            title: "Weather Twin rotation",
            detail: "Assign several worlds to one condition and let them rotate, one per day."
        ),
        PremiumPerk(
            id: "saved",
            symbol: "bookmark.fill",
            title: "Saved locations",
            detail: "Bookmark up to \(PremiumGate.maxSavedLocations) spots, synced across your devices."
        )
    ]
}

/// Compact perk list used inside upsell cards (the paywall renders its own
/// roomier version).
struct PremiumPerkList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(PremiumPerk.all) { perk in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: perk.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#8fc7ff"))
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(perk.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "#f2f5fa"))
                        Text(perk.detail)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

/// The standard "go premium" card: perks plus a CTA. Shown on the Atlas
/// screen and in the picker for free users; callers hide it when premium.
struct PremiumUpsellCard: View {
    let headline: String
    let subhead: String
    var onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "#f2f5fa"))
                Text(subhead)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }

            PremiumPerkList()

            Button(action: onUnlock) {
                Text("Unlock Premium")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .background(Color(hex: "#8fc7ff"))
            .foregroundStyle(Color(hex: "#0a0e16"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(hex: "#8fc7ff").opacity(0.25))
        )
    }
}
