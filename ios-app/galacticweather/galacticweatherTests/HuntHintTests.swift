import XCTest
@testable import galacticweather

/// The Passport's hunt hints — the copy that turns "Not yet found" into
/// something you can go looking for.
///
/// Mirrors the `hunt hints` block in the web app's
/// `src/lib/atlas/atlas.test.ts`. The hint prose itself is allowed to differ
/// between platforms (it is display copy, not behaviour, so a divergent sentence
/// is cosmetic rather than a wrong answer) — what these tests pin is the
/// structure: every slot covered, nothing orphaned, and the derivation from slot
/// defaults rather than a hand-written per-world list.
final class HuntHintTests: XCTestCase {

    func testEverySlotHasAHint() {
        // A slot without a hint shows a bare label, which is the checklist
        // reading the hints exist to replace. Adding a slot should fail here
        // until its hint is written.
        let missing = SLOTS
            .filter { (SLOT_HUNT_HINT[$0.id]?.trimmingCharacters(in: .whitespaces) ?? "").isEmpty }
            .map(\.id)
        XCTAssertEqual(missing, [], "slots missing a hunt hint")
    }

    func testNoHintsForSlotsThatNoLongerExist() {
        let known = Set(SLOTS.map(\.id))
        let orphaned = SLOT_HUNT_HINT.keys.filter { !known.contains($0) }.sorted()
        XCTAssertEqual(orphaned, [], "hunt hints for unknown slots")
    }

    func testDescribesAWorldASlotDefaultsTo() {
        let hunt = huntForWorld("mustafar")
        XCTAssertEqual(hunt?.slotLabels, ["Clear · scorching"])
        XCTAssertEqual(hunt?.range, "100°F and up")
        XCTAssertEqual(hunt?.hint?.contains("Desert interiors"), true)
    }

    func testNamesEveryConditionAWorldCovers() {
        // Hoth is the default for both heavy snow and clear · cold. Naming one
        // would send someone hunting for half the ways they could find it — and
        // this is derived from the slot table precisely so a moved default cannot
        // leave a hand-written list stale.
        XCTAssertEqual(huntForWorld("hoth")?.slotLabels, ["Heavy snow", "Clear · cold"])
    }

    func testNoHuntForWorldsNoForecastLeadsTo() {
        // The premium alternates. The Passport tells these to assign the world in
        // Atlas instead, which is a different sentence for a different situation.
        XCTAssertNil(huntForWorld("ahch-to"))
        XCTAssertNil(huntForWorld("not-a-world"))
    }

    func testHuntCountMatchesTheSetOfSlotDefaults() {
        let withHunt = WORLDS.filter { huntForWorld($0.id) != nil }.count
        XCTAssertEqual(withHunt, Set(SLOTS.map(\.defaultWorld)).count)
    }

    func testHuntTextNamesBothConditionsThenTheHint() {
        // Hoth's first owning slot is `snow`, which is condition-defined and so
        // has no temperature band — the range belongs to `clear_cold`, its second
        // slot, and deliberately does not appear. Asserting 32–44°F here is what
        // caught that; the range tracks the slot the hint came from, not whichever
        // of a world's slots happens to have one.
        let hunt = huntForWorld("hoth")!
        XCTAssertNil(hunt.range)
        XCTAssertEqual(
            PassportView.huntText(hunt),
            "Heavy snow or Clear · cold. Winter at altitude or high latitude — the Alps, the Rockies, Hokkaido."
        )
    }

    func testHuntTextIncludesTheRangeWhenTheSlotHasOne() {
        let hunt = huntForWorld("mustafar")!
        let line = PassportView.huntText(hunt)
        XCTAssertTrue(line.hasPrefix("Clear · scorching · 100°F and up. "), line)
    }

    func testHuntTextUsesOnlyOneEmDash() {
        // The separator used to be an em-dash, which collided with the dash most
        // hints already carry and produced a run-on. Every generated line should
        // contain at most the hint's own.
        for world in WORLDS {
            guard let hunt = huntForWorld(world.id) else { continue }
            let line = PassportView.huntText(hunt)
            let dashes = line.filter { $0 == "—" }.count
            XCTAssertLessThanOrEqual(dashes, 1, "\(world.id): \(line)")
        }
    }
}
