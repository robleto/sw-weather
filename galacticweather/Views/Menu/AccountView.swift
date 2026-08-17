import SwiftUI

/// Premium status and purchase management.
///
/// There is no account system — Apple's ID *is* the account (see
/// `PremiumStore`). So this screen shows entitlement state, the unlock path
/// for free users, and Restore Purchases, rather than any profile UI.
struct AccountView: View {
    @State private var isPaywallOpen = false

    private var accentColor: Color { Color(hex: "#8fc7ff") }
    private var backgroundColor: Color { Color(hex: "#0a0e16") }

    var body: some View {
        MenuScreen(eyebrow: "ACCOUNT", title: statusTitle) {
            VStack(alignment: .leading, spacing: 20) {
                statusCard

                if !PremiumGate.isPremium {
                    unlockSection
                }

                restoreSection

                Text("Galactic Weather has no login. Your purchase lives with your Apple ID, and your Atlas and saved locations sync through iCloud.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .sheet(isPresented: $isPaywallOpen) {
            PaywallView(context: .general)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var statusTitle: String {
        PremiumGate.isPremium ? "Premium" : "Free plan"
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: PremiumGate.isPremium ? "checkmark.seal.fill" : "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 3) {
                Text(PremiumGate.isPremium ? "Premium unlocked" : "You're on the free plan")
                    .font(.system(size: 15, weight: .semibold))
                Text(PremiumGate.isPremium
                     ? "Every world, multi-assign, and saved locations."
                     : "\(AtlasCatalog.freeWorldCount) worlds and all \(SLOTS.count) conditions.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(accentColor.opacity(PremiumGate.isPremium ? 0.35 : 0))
        )
    }

    private var unlockSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PremiumPerkList()

            Button {
                isPaywallOpen = true
            } label: {
                Text("See what's included")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(accentColor)
            .foregroundStyle(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var restoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task { await PremiumStore.shared.restorePurchases() }
            } label: {
                HStack(spacing: 8) {
                    if PremiumStore.shared.isRestoring {
                        ProgressView().tint(accentColor)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text("Restore purchases")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(accentColor)
            }

            if let errorMessage = PremiumStore.shared.lastErrorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#ffd4d4"))
            }
        }
        .task {
            await PremiumStore.shared.start()
        }
    }
}

#Preview {
    AccountView()
}
