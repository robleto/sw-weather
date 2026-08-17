import XCTest
@testable import galacticweather

/// The generated text tones, checked against the contract the generator must
/// keep rather than the values it happened to produce. The web app carries the
/// same cases in `src/lib/atlas/atlas.test.ts`; the two must agree.
final class AtlasTextToneTests: XCTestCase {

    private func srgb(_ c: Double) -> Double {
        let v = c / 255
        return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    private func luminance(_ hex: String) -> Double {
        var h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if h.count == 8 { h = String(h.prefix(6)) }   // ignore alpha for luminance
        let n = UInt32(h, radix: 16) ?? 0
        let r = Double((n >> 16) & 0xFF), g = Double((n >> 8) & 0xFF), b = Double(n & 0xFF)
        return 0.2126 * srgb(r) + 0.7152 * srgb(g) + 0.0722 * srgb(b)
    }

    func testEveryWorldHasAToneAndTextColor() {
        for world in WORLDS {
            XCTAssertTrue([.light, .dark].contains(world.textTone), world.id)
            // 7 chars, or 9 when it carries alpha (dark text is #222222CC).
            XCTAssertTrue([7, 9].contains(world.textColor.count),
                          "\(world.id): \(world.textColor)")
            XCTAssertTrue(world.textColor.hasPrefix("#"), world.id)
            XCTAssertNotNil(UInt32(world.textColor.dropFirst(), radix: 16), world.id)
        }
    }

    func testDarkTextUsesOneSharedTokenSoTheArtTintsIt() {
        // A per-world dark color amplified hue artifacts: Crait's near-white
        // #FDFCED darkened into olive. One translucent token lets the image
        // supply the tint instead.
        let dark = WORLDS.filter { $0.textTone == .dark }
        XCTAssertEqual(Set(dark.map(\.textColor)).count, 1)
        XCTAssertEqual(dark.first?.textColor.count, 9)
    }

    func testTextColorIsOnTheCorrectSideOfItsTone() {
        // A "light" tone whose color came out dark was a real bug during
        // development: the generator only knew how to darken, so Exegol — on
        // near-black art — was pushed the wrong way.
        for world in WORLDS {
            let l = luminance(world.textColor)
            if world.textTone == .light {
                XCTAssertGreaterThan(l, 0.15, "\(world.id) is light-toned but dark")
            } else {
                XCTAssertLessThan(l, 0.35, "\(world.id) is dark-toned but light")
            }
        }
    }

    func testResolveCarriesTheTextColorThrough() {
        let resolved = resolveWorld(slotId: "clear_temperate", overrides: [:])
        XCTAssertTrue(resolved.textColor.hasPrefix("#"))
        XCTAssertEqual(resolved.textColor.count, 7)
    }

    func testOnlyABoundedShareNeedsDarkText() {
        // Sanity bound, not a snapshot: if a regeneration flipped most of the
        // catalog to dark text, the measurement is wrong.
        let dark = WORLDS.filter { $0.textTone == .dark }
        XCTAssertGreaterThan(dark.count, 0)
        XCTAssertLessThan(dark.count, WORLDS.count / 3)
    }
}
