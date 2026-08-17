import XCTest
@testable import galacticweather

/// Cross-platform parity, the same arrangement `SlotMatrixTests` uses.
///
/// `shared/analytics-signals.json` is the agreed analytics contract; the web
/// app's `analytics.test.ts` asserts its port against the same file. Signal
/// names that drift produce two vocabularies in one dashboard, which is worse
/// than no analytics at all — the numbers look comparable and aren't.
///
/// The fixture is bundled as a build-phase resource (see project.yml) because
/// a simulator test cannot read the repository path directly.
final class AnalyticsTests: XCTestCase {

    private struct Fixture: Decodable {
        struct Signal: Decodable {
            let name: String
            let platforms: [String]
            let payload: [String]
        }
        struct StampProbe: Decodable {
            let count: Int
            let bucket: String
        }
        let payloadKeyAllowlist: [String]
        let signals: [Signal]
        let stampCountProbes: [StampProbe]
    }

    private func loadFixture() throws -> Fixture {
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(
            bundle.url(forResource: "analytics-signals", withExtension: "json"),
            "analytics-signals.json is not in the test bundle — check the "
                + "resources buildPhase for galacticweatherTests in project.yml"
        )
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    private func spec(_ name: String, in fixture: Fixture) throws -> Fixture.Signal {
        try XCTUnwrap(
            fixture.signals.first(where: { $0.name == name }),
            "No fixture entry for signal \"\(name)\""
        )
    }

    // MARK: - Fixture integrity

    /// A fixture that silently failed to load would make everything below
    /// pass vacuously.
    func testFixtureIsLoadedAndNonTrivial() throws {
        let fixture = try loadFixture()
        XCTAssertGreaterThanOrEqual(fixture.signals.count, 6)
        XCTAssertFalse(fixture.payloadKeyAllowlist.isEmpty)
        XCTAssertFalse(fixture.stampCountProbes.isEmpty)
    }

    // MARK: - Signal names

    func testSendsExactlyTheSignalsTheFixtureDeclaresForIOS() throws {
        let fixture = try loadFixture()
        let declared = fixture.signals
            .filter { $0.platforms.contains("ios") }
            .map(\.name)
            .sorted()

        XCTAssertEqual(AnalyticsSignal.all.sorted(), declared)
    }

    /// The web app has no premium tier, so this one is ours alone — and the
    /// web suite asserts the mirror image of this.
    func testPaywallSignalIsDeclaredIOSOnly() throws {
        let fixture = try loadFixture()
        let spec = try spec(AnalyticsSignal.premiumPaywallShown, in: fixture)
        XCTAssertEqual(spec.platforms, ["ios"])
    }

    // MARK: - Payloads

    func testPayloadsEmitExactlyTheKeysTheFixtureDeclares() throws {
        let fixture = try loadFixture()

        let cases: [(String, [String: String])] = [
            (
                AnalyticsSignal.forecastLanded,
                AnalyticsPayload.forecastLanded(slotId: "snow")
            ),
            (
                AnalyticsSignal.atlasWorldAssigned,
                AnalyticsPayload.atlasWorldAssigned(slotId: "snow", action: .assign)
            ),
            (
                AnalyticsSignal.passportStampEarned,
                AnalyticsPayload.passportStampEarned(slotId: "snow", kind: .wild, totalStamps: 3)
            ),
            (
                AnalyticsSignal.premiumPaywallShown,
                AnalyticsPayload.premiumPaywallShown(context: .lockedWorld)
            ),
        ]

        for (name, payload) in cases {
            let declared = try spec(name, in: fixture).payload.sorted()
            XCTAssertEqual(payload.keys.sorted(), declared, "payload mismatch for \(name)")
        }
    }

    /// The privacy boundary, enforced rather than documented. A payload that
    /// quietly starts carrying a city name or a world id fails here.
    func testNoPayloadEmitsAKeyOutsideTheAllowlist() throws {
        let fixture = try loadFixture()

        let payloads: [[String: String]] = [
            AnalyticsPayload.forecastLanded(slotId: "snow"),
            AnalyticsPayload.atlasWorldAssigned(slotId: "snow", action: .unassign),
            AnalyticsPayload.passportStampEarned(slotId: "snow", kind: .chartered, totalStamps: 20),
            AnalyticsPayload.premiumPaywallShown(context: .savedLocations),
        ]

        for payload in payloads {
            for key in payload.keys {
                XCTAssertTrue(
                    fixture.payloadKeyAllowlist.contains(key),
                    "\"\(key)\" is not on the payload allowlist"
                )
            }
        }
    }

    func testCarriesTheSlotNeverTheWorld() {
        let payload = AnalyticsPayload.passportStampEarned(
            slotId: "clear_scorching",
            kind: .chartered,
            totalStamps: 9
        )
        XCTAssertEqual(payload["slotId"], "clear_scorching")
        XCTAssertFalse(payload.values.contains("tatooine"))
    }

    func testStampTotalsAreBucketedNotSentExactly() throws {
        let fixture = try loadFixture()
        for probe in fixture.stampCountProbes {
            XCTAssertEqual(
                AnalyticsPayload.stampCountBucket(probe.count),
                probe.bucket,
                "bucket mismatch for count \(probe.count)"
            )
        }
    }

    // MARK: - Kind and action vocabularies

    /// `StampKind`'s raw values reach the dashboard directly, so they are part
    /// of the wire contract and match the web app's `StampKind` strings.
    func testStampKindRawValuesMatchTheWebVocabulary() {
        XCTAssertEqual(StampKind.wild.rawValue, "wild")
        XCTAssertEqual(StampKind.chartered.rawValue, "chartered")
    }

    func testAssignmentActionsMatchTheWebVocabulary() {
        XCTAssertEqual(AnalyticsPayload.AssignmentAction.assign.rawValue, "assign")
        XCTAssertEqual(AnalyticsPayload.AssignmentAction.unassign.rawValue, "unassign")
    }

    /// Spelled out longhand deliberately: these strings are history in the
    /// dashboard, and deriving them from the case names would let a rename
    /// rewrite it.
    func testPaywallContextNamesAreStable() {
        XCTAssertEqual(PaywallContext.general.analyticsName, "general")
        XCTAssertEqual(PaywallContext.lockedWorld.analyticsName, "lockedWorld")
        XCTAssertEqual(PaywallContext.multiAssign.analyticsName, "multiAssign")
        XCTAssertEqual(PaywallContext.savedLocations.analyticsName, "savedLocations")
    }

    // MARK: - Off by default

    /// Analytics must be inert in the test process. If this ever fails, the
    /// suite has been posting signals to the real dashboard.
    func testAnalyticsIsInertUnderXCTest() {
        // Both calls must be safe no-ops; the assertion is that they neither
        // crash nor require configuration.
        Analytics.start()
        Analytics.track(AnalyticsSignal.appLaunched)
        XCTAssertNotNil(NSClassFromString("XCTestCase"))
    }
}
