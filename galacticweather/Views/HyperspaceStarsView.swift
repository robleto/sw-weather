import SwiftUI

/// Deterministic seeded "hyperspace" star-streak background, shown only
/// during the idle phase, layered behind the hero content. Port of the
/// original web app's `HyperspaceStars.tsx` + `HyperspaceStars.module.css`.
struct HyperspaceStarsView: View {
    private struct Star {
        let topPercent: Double
        let leftPercent: Double
        let angleDegrees: Double
        let height: Double
        let duration: Double
        /// Negative "animation-delay" equivalent: the star's cycle is
        /// pre-staggered as if it had already been running for this many
        /// seconds, matching the original CSS's negative delay trick.
        let delay: Double
    }

    private static let starCount = 40
    private static let starColor = Color(red: 200.0 / 255.0, green: 220.0 / 255.0, blue: 255.0 / 255.0)
        .opacity(0.7)

    private static func makeStar(at i: Int) -> Star {
        let top: Double = seededRandom(Double(i * 7 + 1)) * 100
        let left: Double = seededRandom(Double(i * 13 + 2)) * 100
        let angle: Double = seededRandom(Double(i * 17 + 3)) * 360
        let height: Double = 35 + seededRandom(Double(i * 11 + 4)) * 55
        let duration: Double = 2 + seededRandom(Double(i * 19 + 5)) * 3
        let delay: Double = -(seededRandom(Double(i * 23 + 6)) * 6)
        return Star(
            topPercent: top,
            leftPercent: left,
            angleDegrees: angle,
            height: height,
            duration: duration,
            delay: delay
        )
    }

    private static let stars: [Star] = (0..<starCount).map { i in makeStar(at: i) }

    /// Direct port of the original JS `r(seed)`: `sin(seed + 1) * 10000`,
    /// keeping only the fractional part. Deterministic across launches.
    private static func seededRandom(_ seed: Double) -> Double {
        let x = sin(seed + 1) * 10000
        return x - x.rounded(.down)
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                ForEach(Array(Self.stars.enumerated()), id: \.offset) { _, star in
                    Capsule()
                        .fill(Self.starColor)
                        .frame(width: 1, height: star.height)
                        .rotationEffect(.degrees(star.angleDegrees))
                        .opacity(Self.opacity(for: star, at: timeline.date))
                        .position(
                            x: geometry.size.width * star.leftPercent / 100,
                            y: geometry.size.height * star.topPercent / 100
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Piecewise-linear port of the original CSS
    /// `@keyframes blink { 0% → 0, 20% → 0.9, 75% → 0.7, 100% → 0 }`,
    /// driven by wall-clock time so each star's own duration and negative
    /// delay stagger is respected, looping forever.
    private static func opacity(for star: Star, at date: Date) -> Double {
        let elapsed = date.timeIntervalSinceReferenceDate + star.delay
        let rawCycle = elapsed.truncatingRemainder(dividingBy: star.duration)
        let cycle = rawCycle < 0 ? rawCycle + star.duration : rawCycle
        let phase = cycle / star.duration

        switch phase {
        case ..<0.20:
            return phase / 0.20 * 0.9
        case ..<0.75:
            let t = (phase - 0.20) / (0.75 - 0.20)
            return 0.9 + t * (0.7 - 0.9)
        default:
            let t = (phase - 0.75) / (1.0 - 0.75)
            return 0.7 + t * (0 - 0.7)
        }
    }
}

#Preview {
    HyperspaceStarsView()
        .background(PlanetTheme.idleBackgroundColor)
}
