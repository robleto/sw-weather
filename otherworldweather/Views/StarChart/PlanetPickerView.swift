import SwiftUI

/// Bottom sheet for assigning one or more worlds to a weather slot. Port of
/// the web app's `src/app/components/PlanetPicker.tsx`, presented as a native
/// sheet instead of a hand-rolled absolutely-positioned panel. The web
/// version live-previews a world on mouse hover; there's no hover on iOS, so
/// the equivalent feedback is immediate: tapping a card toggles it right
/// away, and `StarChartView`'s backdrop (which stays on screen behind this
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
    @State private var isPaywallOpen = false

    private static let availableClimates: [Climate] = orderedUnique(WORLDS.map(\.climate))

    private var visibleWorlds: [World] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return WORLDS.filter { world in
            if let climate, world.climate != climate { return false }
            if !needle.isEmpty, !world.name.lowercased().contains(needle) { return false }
            return true
        }
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
        .sheet(isPresented: $isPaywallOpen) {
            PaywallView(context: .multiAssign)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("WEATHER TWIN FOR")
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
        return "Pick one world, or several to rotate between them daily."
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
        }
        .padding(.bottom, 14)
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

        return Button {
            if canMultiAssign {
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
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(selected ? Color(hex: "#8fc7ff") : .clear, lineWidth: 2)
                    }

                Text(world.name)
                    .font(.system(size: 13))
                    .tracking(0.4)
                    .foregroundStyle(selected ? Color(hex: "#8fc7ff") : Color(hex: "#f2f5fa"))

                if isDefault {
                    Text("SUITS THIS WEATHER")
                        .font(.system(size: 10))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
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
                    isPaywallOpen = true
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
