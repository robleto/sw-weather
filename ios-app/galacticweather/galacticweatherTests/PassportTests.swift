import XCTest
@testable import galacticweather

/// The Passport's rules, which are pure by design precisely so they can be
/// checked here rather than by clicking through a Simulator.
///
/// The web app carries the same cases in
/// `web-app/galactic-weather/src/lib/passport/passport.test.ts`; the two must
/// agree everywhere the semantics are shared. The `merge` suite is iOS-only —
/// the web app has no cross-device sync to get wrong.
final class PassportTests: XCTestCase {

    private let gregorian = Calendar(identifier: .gregorian)

    private func day(_ iso: String) -> Date {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        var components = DateComponents()
        (components.year, components.month, components.day, components.hour) =
            (parts[0], parts[1], parts[2], 12)
        return gregorian.date(from: components)!
    }

    private func wild(_ planet: WorldId, _ slotId: SlotId = "rain") -> ResolvedWorld {
        ResolvedWorld(
            slotId: slotId, planet: planet, planetName: planet, description: "",
            color: WorldColor(primary: "", headline: ""),
            textTone: .light, textColor: "#FAFAFA", customized: false
        )
    }

    private func charted(_ planet: WorldId, _ slotId: SlotId = "rain") -> ResolvedWorld {
        ResolvedWorld(
            slotId: slotId, planet: planet, planetName: planet, description: "",
            color: WorldColor(primary: "", headline: ""),
            textTone: .light, textColor: "#FAFAFA", customized: true
        )
    }

    // MARK: - recordSighting

    func testFirstSightingCreatesAWildStamp() {
        let passport = recordSighting(
            into: [:], resolved: wild("kamino"), city: "Chicago",
            tempF: 52.4, now: day("2026-08-17")
        )

        XCTAssertEqual(passport?["kamino"], WorldStamp(
            worldId: "kamino",
            wild: Sighting(date: "2026-08-17", city: "Chicago", slotId: "rain", tempF: 52),
            chartered: nil,
            count: 1,
            lastSeen: "2026-08-17"
        ), "temperature should round, and the sighting should land in `wild`")
    }

    func testRepeatSightingSameDayIsANoOp() {
        let first = recordSighting(
            into: [:], resolved: wild("kamino"), city: "Chicago",
            tempF: 52, now: day("2026-08-17")
        )!

        XCTAssertNil(
            recordSighting(
                into: first, resolved: wild("kamino"), city: "Seattle",
                tempF: 60, now: day("2026-08-17")
            ),
            "nil is what lets the caller fire this from a task without guarding"
        )
    }

    func testNextDayBumpsTheCountButNotTheFirstFound() {
        let first = recordSighting(
            into: [:], resolved: wild("kamino"), city: "Chicago",
            tempF: 52, now: day("2026-08-17")
        )!
        let second = recordSighting(
            into: first, resolved: wild("kamino"), city: "Seattle",
            tempF: 60, now: day("2026-08-18")
        )!

        XCTAssertEqual(second["kamino"]?.count, 2)
        XCTAssertEqual(second["kamino"]?.lastSeen, "2026-08-18")
        XCTAssertEqual(
            second["kamino"]?.wild,
            Sighting(date: "2026-08-17", city: "Chicago", slotId: "rain", tempF: 52),
            "a stamp records where you FIRST found a world; nothing overwrites it"
        )
    }

    func testAssignedWorldIsCharteredNotWild() {
        let passport = recordSighting(
            into: [:], resolved: charted("ilum", "clear_freezing"),
            city: "Yakutsk", tempF: -30, now: day("2026-08-17")
        )!

        XCTAssertNotNil(passport["ilum"]?.chartered)
        XCTAssertNil(passport["ilum"]?.wild)
        XCTAssertEqual(statusOf(passport["ilum"]), .chartered)
    }

    func testFindingACharteredWorldWildUpgradesItSameDay() {
        let charteredFirst = recordSighting(
            into: [:], resolved: charted("ilum"), city: "Yakutsk",
            tempF: -30, now: day("2026-08-17")
        )!
        let upgraded = recordSighting(
            into: charteredFirst, resolved: wild("ilum"), city: "Yakutsk",
            tempF: -30, now: day("2026-08-17")
        )

        XCTAssertNotNil(upgraded?["ilum"]?.wild, "a new kind applies even on a repeat day")
        XCTAssertEqual(upgraded?["ilum"]?.count, 1, "an upgrade must not inflate the day count")
        XCTAssertEqual(upgraded?["ilum"]?.chartered?.date, "2026-08-17", "both dates survive")
        XCTAssertEqual(statusOf(upgraded?["ilum"]), .wild)
    }

    func testPlaceholderWorldIsNeverStamped() {
        XCTAssertNil(recordSighting(into: [:], resolved: wild("default"), city: "x", tempF: 0))
        XCTAssertNil(recordSighting(into: [:], resolved: wild(""), city: "x", tempF: 0))
    }

    func testStampKindReadsCustomized() {
        XCTAssertEqual(stampKind(for: wild("x")), .wild)
        XCTAssertEqual(stampKind(for: charted("x")), .chartered)
    }

    // MARK: - Dates

    func testLocalDateUsesLocalCalendarPartsNotUTC() {
        // 11:30pm local on the 17th is already the 18th in UTC for the Americas.
        var late = DateComponents()
        (late.year, late.month, late.day, late.hour, late.minute) = (2026, 8, 17, 23, 30)
        XCTAssertEqual(
            passportLocalDate(gregorian.date(from: late)!, calendar: gregorian),
            "2026-08-17"
        )
    }

    func testLocalDateIsZeroPaddedAndThereforeSortable() {
        var early = DateComponents()
        (early.year, early.month, early.day, early.hour) = (2026, 1, 5, 9)
        XCTAssertEqual(
            passportLocalDate(gregorian.date(from: early)!, calendar: gregorian),
            "2026-01-05",
            "PassportStorage.merge compares these as strings"
        )
    }

    // MARK: - Storage: decode + sanitize

    private let goodSighting = #"{"date":"2026-08-17","city":"Chicago","slotId":"rain","tempF":52}"#

    private func decode(_ json: String) -> Passport? {
        PassportStorage.decodeForTesting(Data(json.utf8))
    }

    func testUnknownWorldIdIsDropped() {
        let book = decode(#"{"atlantis":{"wild":\#(goodSighting),"count":1,"lastSeen":"2026-08-17"}}"#)
        XCTAssertEqual(book?.count, 0)
    }

    func testStampWithNoSightingsIsDropped() {
        XCTAssertEqual(decode(#"{"kamino":{"count":9,"lastSeen":"2026-08-17"}}"#)?.count, 0)
    }

    func testGarbageDecodesToNilSoLoadStartsClean() {
        XCTAssertNil(decode("nonsense"))
    }

    func testMissingFieldsAreRepairedRatherThanRejected() {
        let book = decode(#"{"kamino":{"wild":\#(goodSighting)}}"#)
        XCTAssertEqual(book?["kamino"]?.count, 1)
        XCTAssertEqual(book?["kamino"]?.lastSeen, "2026-08-17", "backfilled from the sighting")
    }

    func testNegativeCountIsRepaired() {
        let book = decode(#"{"kamino":{"wild":\#(goodSighting),"count":-4,"lastSeen":"x"}}"#)
        XCTAssertEqual(book?["kamino"]?.count, 1)
    }

    func testMalformedSightingIsDroppedWithoutTakingTheStamp() {
        let noTemp = #"{"date":"2026-08-17","city":"Chicago","slotId":"rain"}"#
        let book = decode(#"{"kamino":{"wild":\#(noTemp),"chartered":\#(goodSighting),"count":2,"lastSeen":"x"}}"#)

        XCTAssertNotNil(book?["kamino"])
        XCTAssertNil(book?["kamino"]?.wild)
        XCTAssertNotNil(book?["kamino"]?.chartered)
    }

    func testRetiredSlotIdKeepsTheStamp() {
        let retired = #"{"date":"2026-08-17","city":"Chicago","slotId":"retired_slot","tempF":52}"#
        let book = decode(#"{"kamino":{"wild":\#(retired),"count":1,"lastSeen":"x"}}"#)

        XCTAssertNotNil(
            book?["kamino"]?.wild,
            "a retired slot costs the stamp its label line, not the stamp"
        )
    }

    func testOneBadPageNeverCostsTheBook() {
        let book = decode("""
        {"atlantis":{"wild":\(goodSighting),"count":1,"lastSeen":"x"},\
        "kamino":{"wild":\(goodSighting),"count":1,"lastSeen":"x"}}
        """)
        XCTAssertEqual(Array(book?.keys ?? [:].keys), ["kamino"])
    }

    func testWorldIdComesFromTheKeyNotTheValue() {
        let book = decode(#"{"hoth":{"worldId":"WRONG","wild":\#(goodSighting),"count":1,"lastSeen":"x"}}"#)
        XCTAssertEqual(book?["hoth"]?.worldId, "hoth")
    }

    func testEncodeDecodeRoundTripsExactly() throws {
        let original = recordSighting(
            into: [:], resolved: wild("hoth", "snow"), city: "Tromsø",
            tempF: 12, now: day("2026-01-09")
        )!
        let data = try JSONEncoder().encode(original)

        XCTAssertEqual(PassportStorage.decodeForTesting(data), original)
    }

    // MARK: - Storage: merge (iOS only — stamps union, never replace)

    func testAStampEarnedOfflineOnOneDeviceIsNotDroppedByTheOther() {
        let phone = recordSighting(
            into: [:], resolved: wild("kamino"), city: "Chicago",
            tempF: 52, now: day("2026-08-17")
        )!
        let pad = recordSighting(
            into: [:], resolved: wild("hoth", "snow"), city: "Tromsø",
            tempF: 12, now: day("2026-08-18")
        )!

        let merged = PassportStorage.merge(phone, pad)

        XCTAssertEqual(Set(merged.keys), ["kamino", "hoth"])
        XCTAssertEqual(PassportStorage.merge(pad, phone), merged, "merge is commutative")
        XCTAssertEqual(PassportStorage.merge(phone, [:]), phone, "empty is the identity")
        XCTAssertEqual(PassportStorage.merge(phone, phone), phone, "merge is idempotent")
    }

    func testMergeKeepsTheEarlierFindAndNeverSumsTheCount() {
        let early = recordSighting(
            into: [:], resolved: wild("naboo"), city: "Lisbon",
            tempF: 70, now: day("2026-03-01")
        )!
        var later = recordSighting(
            into: [:], resolved: wild("naboo"), city: "Oslo",
            tempF: 66, now: day("2026-06-01")
        )!
        later = recordSighting(
            into: later, resolved: wild("naboo"), city: "Oslo",
            tempF: 66, now: day("2026-06-02")
        )!

        let merged = PassportStorage.merge(later, early)

        XCTAssertEqual(merged["naboo"]?.wild?.city, "Lisbon", "a first-found date never moves later")
        XCTAssertEqual(merged["naboo"]?.wild?.date, "2026-03-01")
        XCTAssertEqual(merged["naboo"]?.count, 2, "max, not sum — a shared day must not double-count")
        XCTAssertEqual(merged["naboo"]?.lastSeen, "2026-06-02")
        XCTAssertEqual(PassportStorage.merge(early, later), merged)
    }

    func testMergeKeepsBothKindsForOneWorld() {
        let onPhone = recordSighting(
            into: [:], resolved: charted("mortis", "fog"), city: "London",
            tempF: 45, now: day("2026-02-01")
        )!
        let onPad = recordSighting(
            into: [:], resolved: wild("mortis", "fog"), city: "Dublin",
            tempF: 44, now: day("2026-02-02")
        )!

        let merged = PassportStorage.merge(onPhone, onPad)

        XCTAssertEqual(merged["mortis"]?.chartered?.city, "London")
        XCTAssertEqual(merged["mortis"]?.wild?.city, "Dublin")
    }

    // MARK: - Hunt state

    func testHuntStateStaysInHuntingForMostOfTheBook() {
        XCTAssertEqual(huntStateFor(wildFound: 0, wildTotal: 21, found: 0, total: 43), .hunting)
        XCTAssertEqual(huntStateFor(wildFound: 17, wildTotal: 21, found: 17, total: 43), .hunting)
    }

    func testHuntStateClosesWithThreeOrFewerWildWorldsLeft() {
        XCTAssertEqual(huntStateFor(wildFound: 18, wildTotal: 21, found: 18, total: 43), .closing)
        XCTAssertEqual(huntStateFor(wildFound: 20, wildTotal: 21, found: 20, total: 43), .closing)
    }

    func testHuntStateMarksTheWildBookDoneBeforeTheCatalog() {
        XCTAssertEqual(huntStateFor(wildFound: 21, wildTotal: 21, found: 21, total: 43), .wildComplete)
        XCTAssertEqual(huntStateFor(wildFound: 21, wildTotal: 21, found: 42, total: 43), .wildComplete)
    }

    func testHuntStateOnlySaysCompleteWhenEveryWorldIsFound() {
        XCTAssertEqual(huntStateFor(wildFound: 21, wildTotal: 21, found: 43, total: 43), .complete)
    }

    func testNoBlurbNamesAWorldSoNoLineCanGoStale() {
        // The bug this replaced: a hardcoded "Hoth is easier in the hemisphere
        // having winter", still coaching you after Hoth was stamped.
        let copy = [HuntState.hunting, .closing, .wildComplete, .complete]
            .map { blurbFor($0, wildRemaining: 3) }
            .joined(separator: " ")

        XCTAssertEqual(WORLDS.map(\.name).filter { copy.contains($0) }, [])
    }

    func testBuildProgressAgreesWithItsOwnCounters() {
        let progress = buildProgress([:])
        XCTAssertEqual(progress.state, .hunting)
        XCTAssertEqual(progress.blurb, blurbFor(.hunting, wildRemaining: 21))
    }

    // MARK: - Progress

    func testWildReachableIsDerivedFromSlotDefaults() {
        XCTAssertEqual(WILD_REACHABLE_WORLDS, Set(SLOTS.map(\.defaultWorld)))
        XCTAssertEqual(WILD_REACHABLE_WORLDS.count, 21)
    }

    func testCharterOnlyWorldsAreExactlyThePremiumSeven() {
        let charterOnly = WORLDS.filter { !WILD_REACHABLE_WORLDS.contains($0.id) }

        XCTAssertEqual(
            charterOnly.map(\.id).sorted(),
            WORLDS.filter(\.isPremium).map(\.id).sorted(),
            """
            The free/premium split and the wild/chartered split are the same line. \
            If this fails, either a premium world became reachable by forecast, or a \
            free world became unearnable — check slot defaults before touching this test.
            """
        )
    }

    func testEmptyBookCoversTheWholeCatalog() {
        let progress = buildProgress([:])

        XCTAssertEqual(progress.wildFound, 0)
        XCTAssertEqual(progress.found, 0)
        XCTAssertEqual(progress.wildTotal, 21)
        XCTAssertEqual(progress.total, WORLDS.count)
        XCTAssertEqual(
            progress.biomes.reduce(0) { $0 + $1.total }, WORLDS.count,
            "every world appears on exactly one biome page"
        )
        XCTAssertEqual(progress.biomes.reduce(0) { $0 + $1.wildTotal }, 21)
        XCTAssertTrue(progress.biomes.allSatisfy { $0.total > 0 }, "no empty pages")
        XCTAssertEqual(progress.biomes.map(\.climate), CLIMATE_ORDER)
    }

    func testAFreeUserCanCompleteTheWildBookButNotTheCatalog() {
        var book: Passport = [:]
        for id in WILD_REACHABLE_WORLDS {
            book = recordSighting(
                into: book, resolved: wild(id), city: "Somewhere",
                tempF: 60, now: day("2026-08-17")
            ) ?? book
        }

        let progress = buildProgress(book)
        XCTAssertEqual(progress.wildFound, 21)
        XCTAssertEqual(progress.wildTotal, 21)
        XCTAssertEqual(progress.found, 21)
        XCTAssertEqual(progress.total, 43)
    }

    func testCharteringTheRestCompletesTheCatalogWithoutMovingTheWildScore() throws {
        var book: Passport = [:]
        for id in WILD_REACHABLE_WORLDS {
            book = recordSighting(
                into: book, resolved: wild(id), city: "Somewhere",
                tempF: 60, now: day("2026-08-17")
            ) ?? book
        }
        for world in WORLDS where !WILD_REACHABLE_WORLDS.contains(world.id) {
            book = recordSighting(
                into: book, resolved: charted(world.id), city: "Somewhere",
                tempF: 60, now: day("2026-08-17")
            ) ?? book
        }

        let progress = buildProgress(book)
        XCTAssertEqual(progress.found, 43)
        XCTAssertEqual(progress.wildFound, 21, "chartered finds fill pages, never the wild score")

        let ocean = try XCTUnwrap(progress.biomes.first { $0.climate == .ocean })
        XCTAssertEqual(ocean.found, 7)
        XCTAssertEqual(ocean.wild, 2)
        XCTAssertEqual(
            ocean.worlds.filter { !$0.wildReachable }.map(\.world.id).sorted(),
            ["ahch-to", "kef-bir", "mon-cala", "niamos", "nur"]
        )
    }
}
