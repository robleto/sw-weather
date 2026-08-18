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
    /// desert, ice, bright ocean, temperate, forest, and sky read as six
    /// different places at thumbnail size. All non-premium, so nothing shown
    /// off here is something a free reader can't actually visit.
    ///
    /// Bounded by which posters actually exist: these name real printed
    /// artwork in `Assets.xcassets/Posters/`, not planet backdrops, so a world
    /// can only appear here once its poster has been drawn. Mustafar held the
    /// volcanic slot until the real posters arrived and it had none; Naboo
    /// takes its place. Alderaan has a poster and is deliberately absent — it
    /// is premium, and the rule above outranks the spread.
    /// Internal rather than private so `CreditsPosterTests` can assert that a
    /// poster asset actually exists for each one. A missing or misspelled asset
    /// name compiles cleanly and renders an empty rectangle, which is precisely
    /// the failure a test has to catch here — the Simulator is not available
    /// for visual checks in this project's environment.
    static let featuredWorldIDs = [
        "tatooine", "hoth", "scarif", "naboo", "endor", "bespin"
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
                    Text(weatherDataLine)
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

            // "digital design", not "painting" — the same words the web footer
            // uses. This is a provenance claim about how the art was made, and
            // the two platforms saying it differently invites the question of
            // which one is true.
            Text("Every world in the app is an original digital design, made the way railways and airlines once sold real destinations — a travel poster for somewhere that doesn't exist.")
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

    /// A license condition, not a courtesy: OpenWeather requires visible
    /// attribution on the free tier, and their data is offered under
    /// CC BY-SA. It had only ever appeared in the web app's privacy policy, as
    /// a description of where coordinates go, which is not the same thing as
    /// crediting the source in the product.
    private var weatherDataLine: AttributedString {
        var result = AttributedString("Weather data by ")
        var link = AttributedString("OpenWeather")
        link.link = URL(string: "https://openweathermap.org/")
        link.underlineStyle = .single
        result += link
        result += AttributedString(".")
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

/// One real travel poster in a paper mat.
///
/// This used to *fabricate* a poster: the landscape planet backdrop cropped to
/// 4:3, with a "VISIT <WORLD>" plate built underneath from the world's palette.
/// That was a stand-in for artwork that didn't exist yet. The real posters do
/// now — portrait, with their own title, tagline and typography already part of
/// the composition — so the plate is gone rather than doubled up.
///
/// The mat survives the change and matters more than before: it is what says
/// "printed object" about an image that would otherwise read as one more piece
/// of app art.
private struct PosterThumb: View {
    let world: World

    private let artWidth: CGFloat = 124

    /// The posters are authored 750x1050. Derived rather than written as 1.4 so
    /// the frame can't quietly disagree with the source and letterbox.
    private var artHeight: CGFloat { artWidth * 1050 / 750 }

    var body: some View {
        Image("poster-\(world.id)")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: artWidth, height: artHeight)
            .clipped()
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
