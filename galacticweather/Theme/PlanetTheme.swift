import SwiftUI

extension Color {
    /// Parses a hex color string like "#RRGGBB" (the "#" is optional) into a
    /// `Color`. Unrecognized/malformed input falls back to opaque black.
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)

        let red = Double((value & 0xFF0000) >> 16) / 255
        let green = Double((value & 0x00FF00) >> 8) / 255
        let blue = Double(value & 0x0000FF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

/// Maps a planet key (e.g. "naboo") to a themed SwiftUI background and to the
/// Assets.xcassets image name used for that planet's full-bleed backdrop
/// photo. Port of the original web app's per-planet CSS gradients
/// (`planetStyles.module.css`).
enum PlanetTheme {
    /// Idle/default state: solid near-black, no gradient.
    static let idleBackgroundColor = Color(hex: "#05070A")

    /// Returns the themed background for `planet`. Pass `"default"` (or any
    /// unrecognized key) for the idle/no-weather-yet look.
    @ViewBuilder
    static func background(for planet: String) -> some View {
        if planet == "default" {
            idleBackgroundColor
        } else if let gradient = bespokeGradients[planet] {
            gradient
        } else if let color = colorByPlanetKey[planet] {
            // Deliberate design fill-in: worlds with no hand-authored CSS
            // gradient in the original app (kijimi, mortis, jakku, at-attin,
            // yavin, ghorman, and any future world not covered by
            // `bespokeGradients`) get a plain 2-stop vertical gradient
            // synthesized directly from that world's own
            // color.primary → color.headline.
            LinearGradient(
                colors: [Color(hex: color.primary), Color(hex: color.headline)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            idleBackgroundColor
        }
    }

    /// The Assets.xcassets image name for a planet's full-bleed background
    /// photo (imagesets live directly in the `Planets` group, un-namespaced).
    static func imageName(for planet: String) -> String {
        planet
    }

    // MARK: - Data-driven fallback lookup

    /// `WorldColor` keyed by world id (e.g. "naboo"), built once from the
    /// Star Chart's `WORLDS` catalog.
    private static let colorByPlanetKey: [String: WorldColor] = {
        var result: [String: WorldColor] = [:]
        for world in WORLDS {
            result[world.id] = world.color
        }
        return result
    }()

    // MARK: - Bespoke gradients ported from the original CSS

    private static func verticalGradient(_ stops: [(hex: String, location: Double)]) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: stops.map { .init(color: Color(hex: $0.hex), location: $0.location) }),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private static let bespokeGradients: [String: LinearGradient] = [
        "alderaan": verticalGradient([("#add8e6", 0), ("#4682b4", 1)]),

        "bespin": verticalGradient([
            ("#ed685a", 0),
            ("#ebe187", 0.35),
            ("#2473ad", 0.7),
            ("#7eb4cb", 1)
        ]),

        "dagobah": verticalGradient([("#697a4c", 0), ("#b9cbd3", 1)]),

        "endor": verticalGradient([("#115836", 0), ("#b9cbd3", 1)]),

        // Deep purple-navy tones mixed toward the top, into the base blue/teal.
        "exegol": verticalGradient([
            ("#5b4a6e", 0),
            ("#453657", 0.18),
            ("#01487d", 0.55),
            ("#c0dcde", 1)
        ]),

        "hoth": verticalGradient([("#175586", 0), ("#a0d0e7", 0.4), ("#cceaf9", 1)]),

        "kamino": verticalGradient([("#314e60", 0), ("#41647c", 0.4), ("#4e7791", 1)]),

        "kashyyyk": verticalGradient([("#1f7661", 0), ("#b9cbd3", 1)]),

        // Warm red/orange tones mixed toward the top, into the base navy/teal.
        "mustafar": verticalGradient([
            ("#6d1831", 0),
            ("#d23e28", 0.18),
            ("#0b0144", 0.55),
            ("#c0dcde", 1)
        ]),

        // Same deep-blue → sky-blue → ice-blue base as hoth, washed with soft purple.
        "naboo": verticalGradient([
            ("#957eb3", 0),
            ("#bba2da", 0.2),
            ("#175586", 0.5),
            ("#cceaf9", 1)
        ]),

        "niamos": verticalGradient([("#29bdd2", 0), ("#ebd89e", 1)]),

        "ilum": verticalGradient([
            ("#3887b7", 0),
            ("#66bcf2", 0.33),
            ("#ddaae1", 0.66),
            ("#b2cbe1", 1)
        ]),

        "scarif": verticalGradient([("#0fa9da", 0), ("#86dced", 1)]),

        "tatooine": verticalGradient([("#ee7e26", 0), ("#fee1a7", 1)])
    ]
}
