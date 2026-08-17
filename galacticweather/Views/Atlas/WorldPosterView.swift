import SwiftUI

/// Assignment context. Optional because the poster also opens from the
/// Passport, where a world is a place you've been rather than something
/// you're picking.
struct PosterAssignment {
    let slot: Slot
    let isAssigned: Bool
    let onToggle: () -> Void
}

/// Passport context: whether this world has been lived through, and where.
///
/// `date` and `temperature` arrive preformatted. `PassportView` owns both —
/// stamp dates are parsed in the current time zone to avoid rendering a day
/// early, and stored Fahrenheit is converted per `AppSettings`. Neither should
/// be reimplemented here.
enum PosterStamp {
    struct Found {
        let city: String
        let date: String
        let slotLabel: String?
        let temperature: String
        /// Days this world has been seen; 1 unless it's recurred.
        let count: Int
        let chartered: Bool
    }

    case found(Found)
    /// Not collected yet, but reachable — or reachable only via Atlas.
    case unfound(wildReachable: Bool)
    /// A premium world a free user hasn't found. No web equivalent: the web
    /// app has no premium tier.
    case locked
}

/// A world shown the way it exists as a physical object: art in a paper mat,
/// title on a plate keyed to the world's own palette, caption underneath.
/// Port of the web app's `src/app/components/WorldPoster.tsx`.
///
/// The mat is the point. Every other surface in this app paints planet art
/// full-bleed as a *background*; matting it and giving it a title band is what
/// makes it read as a printed poster instead of another backdrop.
struct WorldPosterView: View {
    let world: World
    var assignment: PosterAssignment?
    var stamp: PosterStamp?

    @Environment(\.dismiss) private var dismiss
    @State private var isPaywallOpen = false

    /// Colour is drained only in Passport context, and deliberately *not* for
    /// a world merely locked in the picker.
    ///
    /// These look inconsistent side by side and aren't: in the Passport,
    /// colour is the reward for living through the weather, so an uncollected
    /// world stays grey exactly as its row thumbnail does. In the picker, full
    /// colour is the entire sales pitch for a locked world — greying out the
    /// thing you're asking someone to buy would be self-defeating.
    private var isDrained: Bool {
        switch stamp {
        case .unfound, .locked: return true
        case .found, .none: return false
        }
    }

    /// True when the primary action should sell Premium rather than assign.
    private var showsUnlock: Bool {
        if case .locked = stamp { return true }
        return assignment != nil && !PremiumGate.canUseWorld(world)
    }

    private var isCanonTwin: Bool {
        guard let slot = assignment?.slot else { return false }
        return world.id == slot.defaultWorld
    }

    var body: some View {
        ZStack {
            Color(hex: "#0a0e16").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        CloseButton { dismiss() }
                    }

                    poster
                    caption
                    action
                    credit
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 44)
            }
        }
        .foregroundStyle(Color(hex: "#f2f5fa"))
        .sheet(isPresented: $isPaywallOpen) {
            PaywallView(context: .lockedWorld)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - The poster

    private var poster: some View {
        VStack(spacing: 0) {
            Color.clear
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
                .overlay {
                    Image(world.id)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .clipped()
                .saturation(isDrained ? 0 : 1)
                .opacity(isDrained ? 0.85 : 1)

            plate
        }
        .padding(7)
        .background(Color(hex: "#f6f2ea").opacity(0.92))
        .shadow(color: .black.opacity(0.55), radius: 26, y: 12)
        .accessibilityElement(children: .combine)
    }

    private var plate: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Still "VISIT" for a world you haven't found: that's what a travel
            // poster says about a place you've never been. Status lives in the
            // caption below the frame, not on the printed plate.
            Text("VISIT")
                .font(.system(size: 10, weight: .medium))
                .tracking(3.0)
                .foregroundStyle(.white.opacity(0.72))

            Text(world.name.uppercased())
                .font(.custom("PoiretOne-Regular", size: 40))
                .tracking(3.5)
                .foregroundStyle(Color(hex: world.color.headline))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
                .padding(.top, 3)

            Text(world.description)
                .font(.system(size: 14))
                .lineSpacing(2)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(height: 1)
                .padding(.top, 13)

            Text(metaLine)
                .font(.system(size: 10, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(hex: world.color.primary))
    }

    private var metaLine: String {
        var parts = [world.climate.label.uppercased()]
        if isCanonTwin, let slot = assignment?.slot {
            parts.append("THE CANON TWIN FOR \(slot.label.uppercased())")
        }
        return parts.joined(separator: "  ·  ")
    }

    // MARK: - Caption
    //
    // Outside the frame on purpose: the plate is the poster's own printed
    // content, which can't know where you were standing. Your sighting is an
    // annotation on it, not part of it.

    @ViewBuilder
    private var caption: some View {
        switch stamp {
        case .found(let found):
            VStack(spacing: 5) {
                HStack(spacing: 8) {
                    Text("Found in \(found.city)")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#8fc7ff"))
                    if found.chartered { charteredTag }
                }
                Text(foundMetaLine(found))
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

        case .unfound(let wildReachable):
            VStack(spacing: 5) {
                Text("Not yet found")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))
                Text(wildReachable
                     ? "Its weather has to actually happen somewhere you're looking."
                     : "No forecast leads here — assign it in Atlas, then live through that weather.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .locked:
            VStack(spacing: 8) {
                PremiumLockChip()
                // Unlike the Passport row, the Atlas hint is worth saying here:
                // the unlock button is directly below it, so it's a next step
                // rather than the dead end it would be in the list.
                Text("No forecast leads here. Premium lets you assign it in Atlas, then earn the stamp for real.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .none:
            EmptyView()
        }
    }

    private func foundMetaLine(_ found: PosterStamp.Found) -> String {
        var parts = [found.date]
        if let label = found.slotLabel { parts.append(label) }
        parts.append(found.temperature)
        if found.count > 1 { parts.append("seen on \(found.count) days") }
        return parts.joined(separator: " · ")
    }

    private var charteredTag: some View {
        Text("CHARTERED")
            .font(.system(size: 9, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(
                        .white.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 2])
                    )
            )
    }

    // MARK: - Action

    @ViewBuilder
    private var action: some View {
        if showsUnlock {
            Button {
                isPaywallOpen = true
            } label: {
                Text("Unlock every world")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: "#0a0e16"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color(hex: "#8fc7ff")))
            }
            .buttonStyle(.plain)
        } else if let assignment {
            Button {
                assignment.onToggle()
            } label: {
                Text(assignment.isAssigned
                     ? "Remove from \(assignment.slot.label)"
                     : "Assign to \(assignment.slot.label)")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(assignment.isAssigned
                                     ? Color(hex: "#8fc7ff")
                                     : Color(hex: "#0a0e16"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background {
                        if assignment.isAssigned {
                            Capsule().fill(.white.opacity(0.08))
                                .overlay(Capsule().strokeBorder(Color(hex: "#8fc7ff").opacity(0.7)))
                        } else {
                            Capsule().fill(.white.opacity(0.92))
                        }
                    }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Credit

    /// Deliberately a caption, not a call to action — no chevron, no chip.
    private var credit: some View {
        Text(creditLine)
            .font(.system(size: 12))
            .tint(Color(hex: "#8fc7ff"))
            .foregroundStyle(.white.opacity(0.42))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var creditLine: AttributedString {
        var result = AttributedString("Original planet art, also sold as travel posters at ")
        var link = AttributedString("creativemadness.studio")
        link.link = URL(string: "https://creativemadness.studio")
        link.underlineStyle = .single
        result += link
        result += AttributedString(".")
        return result
    }
}

#Preview("Picker context") {
    WorldPosterView(
        world: getWorld("kamino")!,
        assignment: PosterAssignment(
            slot: SLOTS[0],
            isAssigned: false,
            onToggle: {}
        )
    )
}

#Preview("Unfound") {
    WorldPosterView(
        world: getWorld("hoth")!,
        stamp: .unfound(wildReachable: true)
    )
}
