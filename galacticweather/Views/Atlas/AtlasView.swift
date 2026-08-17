import SwiftUI

/// Full-screen Atlas overlay: every weather slot the app can land
/// in, grouped for browsing, each showing which world it currently resolves
/// to. Tapping a slot opens `PlanetPickerView` to reassign it. Port of the
/// web app's `src/app/components/Atlas.tsx`.
struct AtlasView: View {
    @Bindable var viewModel: AtlasViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var activeSlot: Slot?
    @State private var isPaywallOpen = false

    private static let groupedSlots: [(group: SlotGroup, slots: [Slot])] =
        SLOT_GROUP_ORDER.map { group in (group, SLOTS.filter { $0.group == group }) }

    /// The world shown full-bleed behind the sheet: whatever the open slot
    /// currently resolves to, so opening the picker never flashes an empty
    /// background, and toggling a world updates it live.
    private var backdropWorldId: WorldId? {
        guard let activeSlot else { return nil }
        return resolveWorld(slotId: activeSlot.id, overrides: viewModel.overrides).planet
    }

    var body: some View {
        ZStack(alignment: .top) {
            backdrop
            scrim
            content
        }
        .ignoresSafeArea()
        .sheet(item: $activeSlot) { slot in
            PlanetPickerView(
                slot: slot,
                assigned: viewModel.overrides[slot.id] ?? [],
                canMultiAssign: viewModel.canAssignMultipleWorlds,
                onToggleWorld: { worldId in viewModel.toggleWorld(slotId: slot.id, worldId: worldId) },
                onAssignSingleWorld: { worldId in viewModel.assignSingleWorld(slotId: slot.id, worldId: worldId) },
                onResetSlot: { viewModel.resetSlot(slot.id) }
            )
            .presentationDetents([.fraction(0.62), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: "#0a0e16").opacity(0.97))
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        if let backdropWorldId {
            GeometryReader { geometry in
                Image(backdropWorldId)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .id(backdropWorldId)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.32), value: backdropWorldId)
        } else {
            Color(hex: "#060910")
        }
    }

    private var scrim: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "#060910").opacity(0.92), location: 0),
                .init(color: Color(hex: "#060910").opacity(0.78), location: 0.45),
                .init(color: Color(hex: "#060910").opacity(0.9), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                summary
                groups
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 60)
        }
        .foregroundStyle(Color(hex: "#f2f5fa"))
        .sheet(isPresented: $isPaywallOpen) {
            PaywallView(context: .general)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR ATLAS")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Reassign any condition")
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

    @ViewBuilder
    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(summaryText)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if viewModel.customizedCount > 0 {
                    Button("Reset all") { viewModel.resetAll() }
                        .font(.system(size: 13))
                        .underline()
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            // Free users get the full pitch inline — this screen is where
            // the value of unlocking is most legible, because they're
            // already looking at the worlds they can't have yet. Premium
            // users get none of it.
            if !PremiumGate.isPremium {
                PremiumUpsellCard(
                    headline: "Unlock \(AtlasCatalog.premiumWorldCount) more worlds",
                    subhead: "You're using \(AtlasCatalog.freeWorldCount) of \(WORLDS.count) worlds. Premium opens the rest of the catalog — plus multiple worlds per condition and saved locations."
                ) {
                    isPaywallOpen = true
                }
            }
        }
    }

    private var summaryText: String {
        guard PremiumGate.isPremium else {
            return "All \(SLOTS.count) conditions are yours to reassign."
        }
        return viewModel.customizedCount == 0
            ? "\(SLOTS.count) conditions, all set to canon."
            : "\(viewModel.customizedCount) of \(SLOTS.count) conditions customized."
    }

    private var groups: some View {
        VStack(alignment: .leading, spacing: 28) {
            ForEach(Self.groupedSlots, id: \.group) { entry in
                VStack(alignment: .leading, spacing: 10) {
                    Text(entry.group.rawValue.uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.5))

                    VStack(spacing: 6) {
                        ForEach(entry.slots) { slot in
                            slotRow(slot)
                        }
                    }
                }
            }
        }
    }

    private func slotRow(_ slot: Slot) -> some View {
        let assigned = viewModel.overrides[slot.id] ?? []
        let resolved = resolveWorld(slotId: slot.id, overrides: viewModel.overrides)
        let extraCount = assigned.count > 1 ? assigned.count - 1 : 0
        let rangeHint = SLOT_RANGE_HINT[slot.id]
        let isActive = activeSlot?.id == slot.id

        return Button {
            activeSlot = (activeSlot?.id == slot.id) ? nil : slot
        } label: {
            HStack(spacing: 14) {
                Image(resolved.planet)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.label)
                        .font(.system(size: 15))
                    if let rangeHint {
                        Text(rangeHint)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    Text(resolved.planetName)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)

                    if extraCount > 0 {
                        Text("+\(extraCount)")
                            .font(.system(size: 11))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.white.opacity(0.18)))
                    }

                    if resolved.customized {
                        Circle()
                            .fill(Color(hex: "#8fc7ff"))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(isActive ? 0.14 : 0.05))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(isActive ? 0.35 : 0))
            }
        }
        .buttonStyle(.plain)
    }
}
