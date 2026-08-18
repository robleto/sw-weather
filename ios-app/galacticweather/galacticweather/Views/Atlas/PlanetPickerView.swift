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
    @State private var posterWorld: World?

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
            currentAssignment
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
        .sheet(item: $posterWorld) { world in
            WorldPosterView(
                world: world,
                assignment: PosterAssignment(
                    slot: slot,
                    isAssigned: assigned.contains(world.id),
                    onToggle: { togglePosterAssignment(world) }
                )
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    /// Mirrors the card's own tap routing so assigning from the poster and
    /// assigning from the grid can't drift apart. Locked worlds never reach
    /// here — the poster shows an unlock button instead of an assign one.
    private func togglePosterAssignment(_ world: World) {
        if canMultiAssign {
            onToggleWorld(world.id)
        } else if assigned.contains(world.id) {
            onResetSlot()
        } else {
            onAssignSingleWorld(world.id)
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

    private var assignedWorlds: [World] { assigned.compactMap(getWorld) }

    /// What this slot resolves to right now, pinned directly above the grid.
    ///
    /// The grid does mark an assigned world — a 2pt border and a tinted name —
    /// but it sits wherever it falls alphabetically among 43 worlds, so
    /// answering "what is this set to?" meant hunting for a thin outline. It
    /// matters most with multi-assign, where tapping a world *adds* to the set:
    /// swapping one world for another otherwise means finding the old one in
    /// the grid and switching it off first. Each chip carries that removal, so
    /// overriding is a visible action rather than a deduced one.
    ///
    /// Sits above `worldGrid` — the only scrolling part — so it stays on screen
    /// while you browse.
    @ViewBuilder
    private var currentAssignment: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOW SET TO")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.55))

            if assignedWorlds.isEmpty {
                // No custom assignment, so the slot is on its canon world.
                // Shown without a remove control because there is nothing to
                // remove — canon is where removal returns you to.
                if let canon = getWorld(slot.defaultWorld) {
                    assignedChip(canon, onRemove: nil)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(assignedWorlds) { world in
                            assignedChip(world) { unassign(world) }
                        }
                    }
                }
            }
        }
        .padding(.bottom, 14)
    }

    /// Removal only — these chips exist for worlds that are already assigned.
    /// Routed the same way as tapping the world's own card, so there is one
    /// removal path rather than two that can drift apart.
    private func unassign(_ world: World) {
        if canMultiAssign {
            onToggleWorld(world.id)
        } else {
            onResetSlot()
        }
    }

    private func assignedChip(_ world: World, onRemove: (() -> Void)?) -> some View {
        HStack(spacing: 8) {
            Image(world.id)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(world.name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "#f2f5fa"))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.white.opacity(0.16)))
                        // Reaches out to a 44pt target without widening the chip.
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(world.name) from \(slot.label)")
            } else {
                Text("CANON")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, onRemove == nil ? 12 : 0)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.08))
        )
        // The same accent as the grid's selected border, so the two read as one
        // idea — but here it is at a fixed place near the top rather than
        // somewhere in a scrolling grid.
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(hex: "#8fc7ff").opacity(onRemove == nil ? 0.25 : 0.45))
        )
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

                // "To swap in", not "with Premium". The count is the persuasive
                // part and the Unlock button already names the product, so the
                // words in between are free to do the other job: establish that
                // these are alternates rather than something withheld.
                //
                // Free covers all 26 conditions — the free worlds are exactly the
                // set that are slot defaults, and the locked ones are exactly the
                // set that aren't. So nothing here is missing from the app; there
                // is just more to choose from. A picker that reads "half of this
                // is locked" undersells a line that is actually generous, and it
                // works against the free tier's whole point, which is letting
                // someone feel the loop before paying.
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(lockedVisibleCount) more to swap in here")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "#f2f5fa"))

                    Text("Every condition already has a world")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .fixedSize(horizontal: false, vertical: true)

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
        // The expand control is a sibling of the card, not a child: a Button
        // inside another Button's label doesn't reliably receive its own taps.
        ZStack(alignment: .topTrailing) {
            worldCardButton(world)
            expandButton(world)
        }
    }

    /// Opens the poster. Deliberately always visible rather than revealed by a
    /// gesture — it's the only route to the poster, and there's no hover on a
    /// phone to reveal it with.
    private func expandButton(_ world: World) -> some View {
        Button {
            posterWorld = world
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color(hex: "#0a0e16").opacity(0.55)))
                // A 44pt target that reaches inward from the corner, so the
                // chip stays small without shrinking the tap area.
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View \(world.name) as a poster")
    }

    private func worldCardButton(_ world: World) -> some View {
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
