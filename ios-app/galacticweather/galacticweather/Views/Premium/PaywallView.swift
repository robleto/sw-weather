import SwiftUI

/// Where the user came from, so the headline speaks to what they just hit.
enum PaywallContext {
    case general
    case lockedWorld     // tapped a locked premium world in the picker
    case multiAssign     // tried to put a second world on one condition
    case savedLocations  // opened Saved Locations while free

    var headline: String {
        switch self {
        case .general: return "Galactic Weather Premium"
        case .lockedWorld: return "Unlock every world"
        case .multiAssign: return "Assign several worlds"
        case .savedLocations: return "Keep your favorite destinations"
        }
    }

    /// Stable name for analytics. Spelled out rather than derived from the
    /// case name so renaming a case can't silently rewrite history in the
    /// dashboard.
    var analyticsName: String {
        switch self {
        case .general: return "general"
        case .lockedWorld: return "lockedWorld"
        case .multiAssign: return "multiAssign"
        case .savedLocations: return "savedLocations"
        }
    }

    var subhead: String {
        switch self {
        case .general:
            return "Make the whole sky yours."
        case .lockedWorld:
            return "Premium adds this world — and every other locked one — to your picker, forever."
        case .multiAssign:
            return "Give one condition a handful of worlds and let it randomize, one per day."
        case .savedLocations:
            // `premiumSavedLocationLimit`, not `maxSavedLocations` — the
            // latter reports the *reader's* current cap, which on a paywall
            // is by definition the free one.
            return "Premium saves up to \(PremiumGate.premiumSavedLocationLimit) locations and syncs them across your devices."
        }
    }
}

struct PaywallView: View {
    let context: PaywallContext

    @Environment(\.dismiss) private var dismiss

    init(context: PaywallContext = .general) {
        self.context = context
    }

    private var backgroundColor: Color { Color(hex: "#0a0e16") }
    private var textColor: Color { Color(hex: "#f2f5fa") }
    private var accentColor: Color { Color(hex: "#8fc7ff") }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(PremiumPerk.all) { perk in
                            featureRow(perk)
                        }
                    }

                    if let errorMessage = PremiumStore.shared.lastErrorMessage {
                        errorRow(errorMessage)
                    }

                    if PremiumStore.shared.isPremium {
                        alreadyPremiumSection
                    } else {
                        purchaseSection
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task {
            await PremiumStore.shared.start()
        }
        // The denominator for purchases. App Store Connect reports what sold;
        // only this reports how many people saw the offer and didn't buy, and
        // which gate had sent them there.
        .onAppear {
            Analytics.track(
                AnalyticsSignal.premiumPaywallShown,
                AnalyticsPayload.premiumPaywallShown(context: context)
            )
        }
        .onChange(of: PremiumStore.shared.isPremium) { _, isPremium in
            if isPremium {
                dismiss()
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(context.headline)
                .font(.custom("PoiretOne-Regular", size: 30))
                .foregroundStyle(textColor)

            Text(context.subhead)
                .font(.system(size: 15))
                .foregroundStyle(textColor.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func featureRow(_ perk: PremiumPerk) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: perk.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(perk.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(textColor)
                Text(perk.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(textColor.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func errorRow(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.system(size: 13))

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(textColor.opacity(0.85))

            Spacer(minLength: 8)

            Button {
                PremiumStore.shared.clearError()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(textColor.opacity(0.6))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var purchaseSection: some View {
        VStack(spacing: 10) {
            Button {
                Task { await PremiumStore.shared.purchase() }
            } label: {
                Group {
                    if PremiumStore.shared.isPurchasing {
                        ProgressView()
                            .tint(backgroundColor)
                    } else {
                        Text("Unlock for \(PremiumStore.shared.displayPrice)")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .background(accentColor)
            .foregroundStyle(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(PremiumStore.shared.product == nil || PremiumStore.shared.isPurchasing)
            .opacity(PremiumStore.shared.product == nil ? 0.5 : 1)

            Text("One-time purchase · yours forever")
                .font(.system(size: 12))
                .foregroundStyle(textColor.opacity(0.55))

            restoreButton
        }
        .frame(maxWidth: .infinity)
    }

    private var restoreButton: some View {
        Button {
            Task { await PremiumStore.shared.restorePurchases() }
        } label: {
            if PremiumStore.shared.isRestoring {
                ProgressView()
                    .tint(accentColor)
            } else {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentColor)
            }
        }
        .padding(.top, 4)
    }

    private var alreadyPremiumSection: some View {
        VStack(spacing: 10) {
            Text("You already have Premium")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(textColor)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(accentColor)
            .foregroundStyle(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PaywallView(context: .lockedWorld)
}

#Preview("General") {
    PaywallView()
}
