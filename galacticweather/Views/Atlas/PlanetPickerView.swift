import SwiftUI

/// Bottom sheet for assigning one or more worlds to a weather slot. Port of
/// the web app's `src/app/components/PlanetPicker.tsx`, presented as a native
/// sheet instead of a hand-rolled absolutely-positioned panel. The web
/// version live-previews a world on mouse hover; there's no hover on iOS, so
/// the equivalent feedback is immediate: tapping a card toggles it right
/// away, and `AtlasView`'s backdrop (which stays on screen behind this
/// sheet) updates the moment the assignment changes.
struct PlanetPickerView: View {
    let slot: Slot
    var assigned: [WorldId]
    var canMultiAssign: Bool
    var onToggleWorld: (WorldId) -> Void
    var onAssignSingleWorld: (WorldId) -> Void
    var onResetSlot: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var climate: Climate?
    @State private var query = ""
    @State private var sort: WorldSort = .alphabetical
    @State private var isMultiAssignPaywallOpen = false
    @State private var isLockedWorldPaywallOpen = false

    private static let availableClimates: [Climate] = orderedUnique(WORLDS.map(\.climate))

    /// How the world grid is ordered.
    enum WorldSort: String, CaseIterable, Identifiable {
        /// Catalog order, which is already A–Z by id.
        case alphabetical
        /// Everything the user can actually assign right now, first.
        case unlockedFirst

        var id: String { rawValue }

        var label: String {
            switch self {
            case .alphabetical: return "A–Z"
            case .unlockedFirst: return "Unlocked first"
            }
        }
    }

    private var visibleWorlds: [World] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = WORLDS.filter { world in
            if let climate, world.climate != climate { return false }
            if !needle.isEmpty, !world.name.lowercased().contains(needle) { return false }
            return true
        }

        switch sort {
        case .alphabetical:
            return filtered
        case .unlockedFirst:
            // Stable partition, so each group stays A–Z internally.
            return filtered.filter { !$0.isPremium } + filtered.filter(\.isPremium)
        }
    }

    private var lockedVisibleCount: Int {
        visibleWorlds.filter { !PremiumGate.canUseWorld($0) }.count
    }

    private var isCustomized: Bool { !assigned.isEmpty }

    private let gridColumns = [GridItem(.adaptive(minimum: 130), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            hint
            controls
            worldGrid
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .foregroundStyle(Color(hex: "#f2f5fa"))
        .sheet(isPresented: $isMultiAssignPaywallOpen) {
            PaywallView(context: .multiAssign)
        }
        .sheet(isPresented: $isLockedWorldPaywallOpen) {
            PaywallView(context: .lockedWorld)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("WORLD FOR")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.55))
                Text(slot.label)
                    .font(.system(size: 20, weight: .semibold))
            }
            Spacer()
            Button("Done") { dismiss() }
                .font(.system(size: 13, weight: .semibold))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(Color(hex: "#f2f5fa"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(.white.opacity(0.14)))
                .overlay(Capsule().strokeBorder(.white.opacity(0.22)))
        }
    }

    private var hint: some View {
        Text(hintText)
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.6))
            .padding(.top, 8)
            .padding(.bottom, 12)
    }

    private var hintText: String {
        if assigned.count > 1 {
            return "\(assigned.count) worlds assigned — one is chosen each day."
        }
        guard canMultiAssign else {
            return "Pick one world for this condition."
        }
        return "Pick one world, or several to randomize between them daily."
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    climateChip(label: "All", isActive: climate == nil) { climate = nil }
                    ForEach(Self.availableClimates, id: \.self) { c in
                        climateChip(label: c.label, isActive: climate == c) { climate = c }
                    }
                }
            }

            HStack(spacing: 10) {
                TextField("", text: $query, prompt: Text("Search worlds…").foregroundStyle(.white.opacity(0.4)))
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color(hex: "#f2f5fa"))
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(.white.opacity(0.14))
                    }

                sortMenu
            }

            if !PremiumGate.isPremium, lockedVisibleCount > 0 {
                lockedBanner
            }
        }
        .padding(.bottom, 14)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(WorldSort.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .semibold))
                Text(sort.label)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            .foregroundStyle(Color(hex: "#f2f5fa"))
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.14))
            }
        }
        .accessibilityLabel("Sort worlds")
    }

    /// Names the exact number of worlds the current filter is hiding behind
    /// the paywall — a concrete count converts better than a generic pitch,
    /// and it responds to whatever the user is browsing.
    private var lockedBanner: some View {
        Button {
            isLockedWorldPaywallOpen = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#8fc7ff"))

                Text("\(lockedVisibleCount) more world\(lockedVisibleCount == 1 ? "" : "s") here with Premium")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "#f2f5fa"))

                Spacer(minLength: 4)

                Text("Unlock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#0a0e16"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "#8fc7ff")))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "#8fc7ff").opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(hex: "#8fc7ff").opacity(0.28))
            )
        }
        .buttonStyle(.plain)
    }

    private func climateChip(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12))
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(isActive ? .white.opacity(0.9) : .white.opacity(0.07)))
                .foregroundStyle(isActive ? Color(hex: "#0a0e16") : Color(hex: "#f2f5fa"))
                .overlay {
                    if !isActive {
                        Capsule().strokeBorder(.white.opacity(0.12))
                    }
                }
        }
    }

    @ViewBuilder
    private var worldGrid: some View {
        if visibleWorlds.isEmpty {
            Text("No worlds match that filter.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.vertical, 16)
        } else {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(visibleWorlds) { world in
                        worldCard(world)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    private func worldCard(_ world: World) -> some View {
        let selected = assigned.contains(world.id)
        let isDefault = world.id == slot.defaultWorld
        let isLocked = !PremiumGate.canUseWorld(world)

        return Button {
            if isLocked {
                isLockedWorldPaywallOpen = true
            } else if canMultiAssign {
                onToggleWorld(world.id)
            } else if assigned.contains(world.id) {
                onResetSlot()
            } else {
                onAssignSingleWorld(world.id)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Color.clear
                    .aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .overlay {
                        Image(world.id)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(isLocked ? 0.35 : 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(hex: "#0a0e16"))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color(hex: "#8fc7ff")))
                                .overlay(Circle().strokeBorder(Color(hex: "#0a0e16").opacity(0.35), lineWidth: 1))
                                .padding(8)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(selected ? Color(hex: "#8fc7ff") : .clear, lineWidth: 2)
                    }

                Text(world.name)
                    .font(.system(size: 13))
                    .tracking(0.4)
                    .foregroundStyle(
                        selected ? Color(hex: "#8fc7ff") : Color(hex: "#f2f5fa").opacity(isLocked ? 0.6 : 1)
                    )

                if isLocked {
                    Text("PREMIUM")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Color(hex: "#8fc7ff"))
                } else if isDefault {
                    Text("SUITS THIS WEATHER")
                        .font(.system(size: 10))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(isLocked ? "Premium unlocks this world" : "")
    }

    private var footer: some View {
        HStack {
            Button("Reset to canon") { onResetSlot() }
                .font(.system(size: 12, weight: .medium))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Color(hex: "#f2f5fa").opacity(isCustomized ? 1 : 0.35))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(Capsule().strokeBorder(.white.opacity(isCustomized ? 0.22 : 0.1)))
                .disabled(!isCustomized)
            Spacer()
            if !canMultiAssign {
                Button {
                    isMultiAssignPaywallOpen = true
                } label: {
                    HStack(spacing: 6) {
                        Text(PremiumGate.multiAssignUpsell)
                            .font(.system(size: 12, weight: .medium))
                        PremiumLockChip()
                    }
                }
            }
        }
        .padding(.top, 10)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
        }
    }
}
