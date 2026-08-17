import XCTest
@testable import galacticweather

/// Slot ids key stored Atlas assignments and are stamped onto every Passport
/// sighting, so renaming one is a data migration rather than a refactor.
///
/// Both sanitizers drop unrecognized slots by design, which is exactly what
/// makes the failure mode silent: a stored assignment for a renamed slot does
/// not error, it quietly reverts to that slot's default and the user's
/// customization is gone.
///
/// Port of the "slot id migration" block in the web app's `atlas.test.ts`.
final class SlotRenameTests: XCTestCase {

    func testEveryHistoricalIdMapsOntoASlotThatStillExists() {
        XCTAssertFalse(RENAMED_SLOT_IDS.isEmpty)
        for (oldID, newID) in RENAMED_SLOT_IDS {
            XCTAssertNil(getSlot(oldID), "\(oldID) should no longer be a live slot")
            XCTAssertNotNil(getSlot(newID), "\(oldID) migrates to missing slot \(newID)")
        }
    }

    /// The specific reason this migration exists: every other slot id is
    /// generic weather vocabulary, and analytics sends slot ids precisely
    /// because of that. See `shared/analytics-signals.json`.
    func testRenamedTheFranchiseNamedSlotThatAnalyticsWouldHaveSent() {
        XCTAssertEqual(canonicalSlotId("jakku"), "dust")
        XCTAssertEqual(getSlot("dust")?.label, "Dust & sand")
    }

    func testIdsThatWereNeverRenamedPassThrough() {
        XCTAssertEqual(canonicalSlotId("snow"), "snow")
        XCTAssertEqual(canonicalSlotId("not_a_slot"), "not_a_slot")
    }

    // MARK: - Atlas assignments

    func testStoredAssignmentSurvivesTheRename() throws {
        let json = #"{"jakku":["hoth"]}"#
        let migrated = try XCTUnwrap(AtlasStorage.decodeForTesting(Data(json.utf8)))
        XCTAssertEqual(migrated, ["dust": ["hoth"]])
    }

    func testAssignmentsForGenuinelyRetiredSlotsAreStillDropped() throws {
        let json = #"{"retired_slot":["hoth"]}"#
        let migrated = try XCTUnwrap(AtlasStorage.decodeForTesting(Data(json.utf8)))
        XCTAssertTrue(migrated.isEmpty)
    }

    // MARK: - Passport provenance

    func testStampEarnedUnderTheOldIdKeepsItsProvenanceLine() throws {
        let json = """
        {"tatooine":{"wild":{"date":"2026-01-05","city":"Cairo","slotId":"jakku","tempF":91},\
        "count":1,"lastSeen":"2026-01-05"}}
        """
        let book = try XCTUnwrap(PassportStorage.decodeForTesting(Data(json.utf8)))
        XCTAssertEqual(book["tatooine"]?.wild?.slotId, "dust")
    }
}
