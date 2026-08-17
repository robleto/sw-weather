import XCTest
@testable import galacticweather

/// Cross-platform parity.
///
/// `shared/weather-slot-matrix.json` is the agreed behavior of the weather →
/// slot mapping, as a condition-code × temperature grid. This suite asserts the
/// iOS port matches it; the web app's `slotMatrix.test.ts` asserts the same of
/// its mapper against the same file. Neither platform can drift without going
/// red.
///
/// The fixture is bundled as a build-phase resource (see project.yml) because a
/// simulator test cannot read the repository path directly. It is referenced in
/// place, so the bundled copy is refreshed from the real file on every build.
///
/// Regenerate with `npm run matrix` in the web app after an intentional
/// behavior change, and review the diff.
final class SlotMatrixTests: XCTestCase {

    private struct SlotMatrix: Decodable {
        let probeTemperaturesF: [Double]
        let matrix: [String: [SlotId]]
    }

    private func loadFixture() throws -> SlotMatrix {
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(
            bundle.url(forResource: "weather-slot-matrix", withExtension: "json"),
            "weather-slot-matrix.json is not in the test bundle — check the "
                + "resources buildPhase for galacticweatherTests in project.yml"
        )
        return try JSONDecoder().decode(SlotMatrix.self, from: Data(contentsOf: url))
    }

    private func toKelvin(_ tempF: Double) -> Double {
        (tempF - 32) * 5 / 9 + 273.15
    }

    /// Mirrors the generator: `main` is only exercised on the fallback path.
    private func main(forCode code: Int) -> String {
        if code >= 800 { return code == 800 ? "Clear" : "Clouds" }
        switch code / 100 {
        case 2: return "Thunderstorm"
        case 3: return "Drizzle"
        case 5: return "Rain"
        case 6: return "Snow"
        case 7: return "Mist"
        default: return "Clear"
        }
    }

    // MARK: - Fixture integrity

    func testFixtureIsLoadedAndNonTrivial() throws {
        // A fixture that silently failed to load would make the parity test
        // below pass vacuously.
        let fixture = try loadFixture()
        XCTAssertFalse(fixture.probeTemperaturesF.isEmpty)
        XCTAssertEqual(fixture.matrix.count, 55)
        for (code, row) in fixture.matrix {
            XCTAssertEqual(row.count, fixture.probeTemperaturesF.count, "code \(code)")
        }
    }

    func testFixtureOnlyNamesSlotsThatExist() throws {
        let known = Set(SLOTS.map(\.id))
        for (code, row) in try loadFixture().matrix {
            for slot in row {
                XCTAssertTrue(known.contains(slot), "code \(code) names unknown slot \(slot)")
            }
        }
    }

    func testFixtureReachesEveryDeclaredSlot() throws {
        // If a slot is unreachable the mapper can never produce it, which means
        // it is dead weight in Atlas.
        let reached = Set(try loadFixture().matrix.values.flatMap { $0 })
        let unreachable = SLOTS.map(\.id).filter { !reached.contains($0) }
        XCTAssertEqual(unreachable, [], "unreachable slots")
    }

    func testFixtureProbesEveryBandBoundary() throws {
        // Each cutoff must appear as a probe, or a change to it could slip
        // through without moving a single cell.
        let temps = Set(try loadFixture().probeTemperaturesF)
        for boundary in [32.0, 45, 58, 69, 79, 90, 100] {
            XCTAssertTrue(temps.contains(boundary), "missing probe \(boundary)°F")
            XCTAssertTrue(temps.contains(boundary - 1), "missing probe \(boundary - 1)°F")
        }
    }

    // MARK: - Parity

    func testMapperMatchesTheSharedMatrix() throws {
        let fixture = try loadFixture()
        var drift: [String] = []

        for (codeString, row) in fixture.matrix {
            let code = try XCTUnwrap(Int(codeString))
            for (index, expected) in row.enumerated() {
                let tempF = fixture.probeTemperaturesF[index]
                let actual = WeatherDescriptionMapper.getSlotForWeather(
                    conditionCode: code,
                    weatherMain: main(forCode: code),
                    tempKelvin: toKelvin(tempF)
                )
                if actual != expected {
                    drift.append("code \(code) at \(tempF)°F: expected \(expected), got \(actual)")
                }
            }
        }

        XCTAssertEqual(
            drift.sorted(), [],
            "\(drift.count) cell(s) drifted from the web implementation"
        )
    }
}
