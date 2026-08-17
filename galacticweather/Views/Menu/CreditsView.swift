import SwiftUI

/// Attribution and links. This content used to live in a bottom bar on the
/// landed screen (`FooterView`), which was orphaned when the layout moved to
/// full-bleed planet art — it now has a home in the menu instead.
///
/// The screen used to carry an "ELSEWHERE" list of five social profiles
/// (robleto.com, CodePen, Dribbble, GitHub, LinkedIn). That real estate now
/// explains the artwork instead: the posters are the thing worth showing here,
/// and the personal site is still reachable from the byline below.
struct CreditsView: View {
    /// A spread across biomes rather than the first few alphabetically — warm
    /// desert, ice, volcanic, forest, bright ocean, and sky read as six
    /// different places at thumbnail size. All non-premium, so nothing shown
    /// off here is something a free reader can't actually visit.
    private static let featuredWorldIDs = [
        "tatooine", "hoth", "scarif", "mustafar", "endor", "bespin"
    ]

    private var featuredWorlds: [World] {
        Self.featuredWorldIDs.compactMap { getWorld($0) }
    }

    var body: some View {
        MenuScreen(
            eyebrow: "CREDITS",
            title: "Originally made by hand… improved with AI",
            titleSize: 24
        ) {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(inspiredLine)
                    Text(developedByLine)
                }
                .font(.system(size: 14))
                .tint(Color(hex: "#8fc7ff"))
                .foregroundStyle(Color(hex: "#f2f5fa").opacity(0.75))

                posterSection

                Text("World names are used affectionately, not officially.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Travel posters

    private var posterSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TRAVEL POSTERS")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.45))

            // Bleeds past the screen's 20pt gutter so a partial poster shows at
            // the trailing edge — that clipped edge is what says "scroll me".
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(featuredWorlds) { world in
                        PosterThumb(world: world)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
            .padding(.horizontal, -20)

            Text("Every world in the app is an original painting, made the way railways and airlines once sold real destinations — a travel poster for somewhere that doesn't exist.")
                .font(.system(size: 14))
                .lineSpacing(2)
                .foregroundStyle(Color(hex: "#f2f5fa").opacity(0.75))

            Link(destination: URL(string: "https://creativemadness.studio")!) {
                HStack(spacing: 12) {
                    Image(systemName: "printer")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#8fc7ff"))
                        .frame(width: 18)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prints of the full set")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "#f2f5fa"))
                        Text("creativemadness.studio")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.05))
                )
            }
        }
    }

    // MARK: - Prose

    private var inspiredLine: AttributedString {
        var result = AttributedString("Inspired by a ")
        var link = AttributedString("weather site")
        link.link = URL(string: "https://www.tomscott.com/weather/starwars/")
        link.underlineStyle = .single
        result += link
        result += AttributedString(" from long ago.")
        return result
    }

    private var developedByLine: AttributedString {
        var result = AttributedString("Designed and developed by ")
        var link = AttributedString("Greg Robleto")
        link.link = URL(string: "https://www.robleto.com/")
        link.underlineStyle = .single
        result += link
        result += AttributedString(".")
        return result
    }
}

/// One world at poster scale: art in a paper mat, title on a plate keyed to the
/// world's own palette. The mat is the point — planet art is a full-bleed
/// *background* everywhere else in the app, and matting it is what makes it
/// read as a printed object instead of another backdrop.
private struct PosterThumb: View {
    let world: World

    private let artWidth: CGFloat = 104

    var body: some View {
        VStack(spacing: 0) {
            Image(world.id)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: artWidth, height: artWidth * 3 / 4)
                .clipped()

            VStack(spacing: 1) {
                Text("VISIT")
                    .font(.system(size: 6, weight: .medium))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.7))

                Text(world.name.uppercased())
                    .font(.custom("PoiretOne-Regular", size: 13))
                    .tracking(1.0)
                    .foregroundStyle(Color(hex: world.color.headline))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: artWidth)
            .padding(.vertical, 7)
            .background(Color(hex: world.color.primary))
        }
        .padding(3)
        .background(Color(hex: "#f6f2ea").opacity(0.92))
        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(world.name) travel poster")
    }
}

#Preview {
    CreditsView()
}
