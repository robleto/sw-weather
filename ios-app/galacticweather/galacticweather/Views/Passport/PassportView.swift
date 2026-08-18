import SwiftUI

/// The Passport: every world in the catalog, grouped by biome, showing which
/// ones the user has actually landed on and where they were standing when it
/// happened. Port of the web app's `src/app/components/Passport.tsx`.
///
/// Built on `MenuScreen` rather than `AtlasView`'s full-bleed treatment: the
/// web version paints the hovered world behind the book, and there's no hover
/// on a phone. A dark, legible list is the honest translation.
struct PassportView: View {
    var viewModel: PassportViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var isPaywallOpen = false
    @State private var posterEntry: WorldProgress?

    private var progress: PassportProgress { viewModel.progress }

    var body: some View {
        MenuScreen(eyebrow: "YOUR PASSPORT", title: "Worlds you've found") {
            score
            blurb

            // Free users see the pitch where it argues for itself — right
            // above pages they can watch stay empty.
            if !PremiumGate.isPremium {
                PremiumUpsellCard(
                    headline: "\(AtlasCatalog.premiumWorldCount) worlds you can't reach yet",
                    subhead: "No forecast leads to them. Premium lets you assign them in Atlas, then earn the stamp for real."
                ) {
                    isPaywallOpen = true
                }
            }

            biomes
        }
        // Reached from the list, and thrown back to it the same way the
        // weather screen is.
        .tossToDismiss { dismiss() }
        .sheet(isPresented: $isPaywallOpen) {
            PaywallView(context: .lockedWorld)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $posterEntry) { entry in
            WorldPosterView(world: entry.world, stamp: posterStamp(for: entry))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    /// Flattens a progress entry into the shape the poster's caption needs.
    /// Locked is checked first: a premium world a free user hasn't reached
    /// should sell rather than merely report "not yet found".
    private func posterStamp(for entry: WorldProgress) -> PosterStamp {
        let found = entry.status != .unfound
        if PremiumGate.isPassportPageLocked(entry.world, found: found) {
            return .locked
        }
        guard found, let sighting = entry.primarySighting else {
            return .unfound(wildReachable: entry.wildReachable)
        }
        return .found(
            PosterStamp.Found(
                city: sighting.city,
                date: Self.displayDate(sighting.date),
                slotLabel: getSlot(sighting.slotId)?.label,
                temperature: Self.temperatureText(sighting.tempF),
                count: entry.stamp?.count ?? 1,
                chartered: entry.status == .chartered
            )
        )
    }

    // MARK: - Header

    private var score: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(progress.wildFound)")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color(hex: "#8fc7ff"))
                .monospacedDigit()
            Text("/\(progress.wildTotal) found wild")
                .font(.system(size: 15))
                .monospacedDigit()
            Text("·")
                .foregroundStyle(.white.opacity(0.35))
            Text("\(progress.found)/\(progress.total) in total")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .monospacedDigit()
        }
    }

    private var blurb: some View {
        Text(progress.blurb)
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.65))
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Pages

    private var biomes: some View {
        VStack(alignment: .leading, spacing: 28) {
            ForEach(progress.biomes) { biome in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(biome.label.uppercased())
                            .font(.system(size: 12, weight: .medium))
                            .tracking(1.4)
                        Text("\(biome.found)/\(biome.total)")
                            .font(.system(size: 12, weight: .medium))
                            .monospacedDigit()
                            .opacity(0.8)
                    }
                    .foregroundStyle(.white.opacity(0.5))

                    VStack(spacing: 6) {
                        ForEach(biome.worlds) { entry in
                            // The whole row is the target. Tapping a stamp did
                            // nothing before, so opening the poster costs no
                            // existing gesture and needs no extra affordance.
                            Button {
                                posterEntry = entry
                            } label: {
                                stampRow(entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func stampRow(_ entry: WorldProgress) -> some View {
        let found = entry.status != .unfound
        let locked = PremiumGate.isPassportPageLocked(entry.world, found: found)
        let sighting = entry.primarySighting

        return HStack(spacing: 14) {
            Image(entry.world.id)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .saturation(found ? 1 : 0)
                .opacity(found ? 1 : 0.7)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.world.name)
                        .font(.system(size: 15))
                    if let stamp = entry.stamp, stamp.count > 1 {
                        Text("×\(stamp.count)")
                            .font(.system(size: 11))
                            .monospacedDigit()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.white.opacity(0.16)))
                    }
                }

                if let sighting {
                    Text(sighting.city)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)

                    Text(metaLine(for: sighting))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                        .monospacedDigit()

                    if entry.status == .chartered {
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
                            .padding(.top, 2)
                    }
                } else {
                    Text("Not yet found")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))

                    // Suppressed when locked: the lock chip is already saying
                    // "not yours yet", and telling a free user to assign a
                    // world they can't assign is a dead end, not a hint.
                    if !entry.wildReachable, !locked {
                        Text("No forecast leads here — assign it in Atlas, then live through that weather")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer(minLength: 8)

            if locked {
                PremiumLockChip()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(rowFill(for: entry.status))
        )
        .overlay {
            // Wild gets a solid edge, chartered a dashed one — the same
            // distinction the web book draws, in the vocabulary a passport
            // already uses for a stamp you issued yourself.
            if entry.status == .wild {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(hex: "#8fc7ff").opacity(0.32))
            } else if entry.status == .chartered {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        .white.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            }
        }
        .opacity(found ? 1 : 0.55)
    }

    private func rowFill(for status: WorldStatus) -> Color {
        switch status {
        case .wild: return Color(hex: "#8fc7ff").opacity(0.1)
        case .chartered, .unfound: return .white.opacity(0.05)
        }
    }

    // MARK: - Formatting

    private func metaLine(for sighting: Sighting) -> String {
        var parts = [Self.displayDate(sighting.date)]
        if let label = getSlot(sighting.slotId)?.label { parts.append(label) }
        parts.append(Self.temperatureText(sighting.tempF))
        return parts.joined(separator: " · ")
    }

    /// Stored temperatures are always Fahrenheit; the display follows the
    /// user's setting. Converting from an already-rounded value can land a
    /// degree off in Celsius — acceptable on a decorative line, and better
    /// than storing two units or diverging from the web schema.
    private static func temperatureText(_ tempF: Int) -> String {
        switch AppSettings.shared.temperatureUnit {
        case .fahrenheit:
            return "\(tempF)°"
        case .celsius:
            return "\(Int(((Double(tempF) - 32) * 5 / 9).rounded()))°"
        }
    }

    private static let storedDateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Parsed in the *current* time zone, matching how `passportLocalDate`
    /// wrote it. Parsing as UTC would render every stamp a day early for
    /// anyone west of Greenwich.
    private static func displayDate(_ stored: String) -> String {
        guard let date = storedDateParser.date(from: stored) else { return stored }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}
