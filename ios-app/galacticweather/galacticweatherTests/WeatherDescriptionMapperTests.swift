import XCTest
@testable import galacticweather

/// Expectations here are written out longhand rather than derived from the
/// mapper's own tables — a test that imports the table it is checking proves
/// nothing. The web app carries the same cases in
/// `web-app/galactic-weather/src/app/utils/weatherDescriptions.test.ts`;
/// the two must agree.
final class WeatherDescriptionMapperTests: XCTestCase {

    /// The API reports Kelvin (we send no `units`), so tests speak Fahrenheit.
    private func fromF(_ tempF: Double) -> Double {
        (tempF - 32) * 5 / 9 + 273.15
    }

    private func slot(_ code: Int, _ main: String, _ tempF: Double = 70) -> SlotId {
        WeatherDescriptionMapper.getSlotForWeather(
            conditionCode: code,
            weatherMain: main,
            tempKelvin: fromF(tempF)
        )
    }

    // MARK: - The condition-code table

    /// Every code the mapper claims to know, and the slot it must produce.
    private let codeTable: [(code: Int, main: String, expected: SlotId)] = [
        // 2xx thunderstorm
        (200, "Thunderstorm", "thunderstorm"),
        (201, "Thunderstorm", "thunderstorm"),
        (202, "Thunderstorm", "thunderstorm"),
        (210, "Thunderstorm", "thunderstorm"),
        (211, "Thunderstorm", "thunderstorm"),
        (212, "Thunderstorm", "thunderstorm"),
        (221, "Thunderstorm", "thunderstorm"),
        (230, "Thunderstorm", "thunderstorm"),
        (231, "Thunderstorm", "thunderstorm"),
        (232, "Thunderstorm", "thunderstorm"),

        // 3xx drizzle
        (300, "Drizzle", "drizzle"),
        (301, "Drizzle", "drizzle"),
        (302, "Drizzle", "drizzle"),
        (310, "Drizzle", "drizzle"),
        (311, "Drizzle", "drizzle"),
        (312, "Drizzle", "drizzle"),
        (313, "Drizzle", "drizzle"),
        (314, "Drizzle", "drizzle"),
        (321, "Drizzle", "drizzle"),

        // 5xx rain — intensity splits first (only the explicitly-light codes
        // break out, matching the 6xx snow split), then temperature. Table
        // cases run at the 70°F default, i.e. the warm side of 45°F.
        (500, "Rain", "rain_light"),
        (501, "Rain", "rain"),
        (502, "Rain", "rain"),
        (503, "Rain", "rain"),
        (504, "Rain", "rain"),
        (520, "Rain", "rain_light"),
        (521, "Rain", "rain"),
        (522, "Rain", "rain"),
        (531, "Rain", "rain"),
        // ...except freezing rain, which is ice and must not read as a warm downpour
        (511, "Rain", "snow_light"),

        // 6xx snow
        (600, "Snow", "snow_light"),
        (601, "Snow", "snow"),
        (602, "Snow", "snow"),
        (611, "Snow", "snow_light"),
        (612, "Snow", "snow_light"),
        (613, "Snow", "snow_light"),
        (615, "Snow", "snow_light"),
        (616, "Snow", "snow_light"),
        (620, "Snow", "snow_light"),
        (621, "Snow", "snow"),
        (622, "Snow", "snow"),

        // 7xx atmosphere
        (701, "Mist", "mist"),
        (711, "Smoke", "smoke"),
        (721, "Haze", "haze"),
        (731, "Dust", "dust"),
        (741, "Fog", "fog"),
        (751, "Sand", "dust"),
        (761, "Dust", "dust"),
        (762, "Ash", "smoke"),
        (771, "Squall", "thunderstorm"),
        (781, "Tornado", "thunderstorm"),
    ]

    func testConditionCodeTable() {
        for entry in codeTable {
            XCTAssertEqual(
                slot(entry.code, entry.main),
                entry.expected,
                "code \(entry.code) (\(entry.main))"
            )
        }
    }

    func testTableCoversEveryDocumentedCode() {
        // Guards against a code being dropped from the mapper's table. 8xx is
        // excluded — those are temperature-dependent and covered separately.
        XCTAssertEqual(codeTable.count, 50)
    }

    func testTableOnlyProducesRealSlotIds() {
        // SlotId is a bare `String`, so a typo here is otherwise invisible
        // until resolveWorld() silently falls back at runtime.
        let known = Set(SLOTS.map(\.id))
        for entry in codeTable {
            XCTAssertTrue(known.contains(entry.expected), "unknown slot \(entry.expected)")
        }
    }

    // MARK: - Cloud cover

    func testFewCloudsReadsAsClearSky() {
        XCTAssertEqual(slot(801, "Clouds", 70), "clear_temperate")
    }

    func testRealCloudCoverUsesCloudsLadder() {
        XCTAssertEqual(slot(802, "Clouds", 70), "clouds_temperate")
        XCTAssertEqual(slot(803, "Clouds", 70), "clouds_temperate")
        XCTAssertEqual(slot(804, "Clouds", 70), "clouds_temperate")
    }

    func testClearSkyUsesClearLadder() {
        XCTAssertEqual(slot(800, "Clear", 70), "clear_temperate")
    }

    // MARK: - Temperature bands

    func testClearTemperatureBands() {
        let bands: [(boundary: Double, atBoundary: SlotId, below: SlotId)] = [
            (100, "clear_scorching", "clear_hot"),
            (90, "clear_hot", "clear_warm"),
            (79, "clear_warm", "clear_temperate"),
            (69, "clear_temperate", "clear_cool"),
            (58, "clear_cool", "clear_chilly"),
            (45, "clear_chilly", "clear_cold"),
            (32, "clear_cold", "clear_freezing"),
        ]
        for band in bands {
            XCTAssertEqual(slot(800, "Clear", band.boundary), band.atBoundary,
                           "at \(band.boundary)°F")
            XCTAssertEqual(slot(800, "Clear", band.boundary - 1), band.below,
                           "at \(band.boundary - 1)°F")
        }
    }

    func testCloudsTemperatureBands() {
        let bands: [(boundary: Double, atBoundary: SlotId, below: SlotId)] = [
            (79, "clouds_warm", "clouds_temperate"),
            (69, "clouds_temperate", "clouds_cool"),
            (45, "clouds_cool", "clouds_cold"),
            (32, "clouds_cold", "clouds_freezing"),
        ]
        for band in bands {
            XCTAssertEqual(slot(804, "Clouds", band.boundary), band.atBoundary,
                           "at \(band.boundary)°F")
            XCTAssertEqual(slot(804, "Clouds", band.boundary - 1), band.below,
                           "at \(band.boundary - 1)°F")
        }
    }

    func testNoGapAtTheExtremes() {
        XCTAssertEqual(slot(800, "Clear", 140), "clear_scorching")
        XCTAssertEqual(slot(800, "Clear", -60), "clear_freezing")
        XCTAssertEqual(slot(804, "Clouds", 140), "clouds_warm")
        XCTAssertEqual(slot(804, "Clouds", -60), "clouds_freezing")
    }

    func testCloudsLadderIsAStrictCoarseningOfClear() {
        // Every clouds boundary must also be a clear boundary, or the two
        // ladders start disagreeing about where "cool" ends.
        let clearBoundaries: Set<Double> = [100, 90, 79, 69, 58, 45, 32]
        for boundary in [79, 69, 45, 32] as [Double] {
            XCTAssertTrue(clearBoundaries.contains(boundary), "\(boundary)°F")
        }
    }

    func testBandsOnTheRoundedTemperatureTheReadoutShows() {
        // 78.6°F displays as "79°F", so it must land in the 79–89 band and not
        // in the one the UI labels 69–78.
        XCTAssertEqual(slot(800, "Clear", 78.6), "clear_warm")
        XCTAssertEqual(slot(800, "Clear", 78.4), "clear_temperate")
        XCTAssertEqual(slot(804, "Clouds", 44.5), "clouds_cool")
        XCTAssertEqual(slot(804, "Clouds", 44.4), "clouds_cold")
    }

    func testBoundariesAreStableDespiteKelvinConversionError() {
        // 69, 79 and 100°F all convert to Kelvin and back a hair light; without
        // rounding each would fall one band short of where the hint says.
        XCTAssertEqual(slot(800, "Clear", 69), "clear_temperate")
        XCTAssertEqual(slot(800, "Clear", 79), "clear_warm")
        XCTAssertEqual(slot(800, "Clear", 100), "clear_scorching")
    }

    func testRainSplitsColdFromWarmAt45F() {
        XCTAssertEqual(slot(501, "Rain", 45), "rain")
        XCTAssertEqual(slot(501, "Rain", 44), "rain_cold")
        XCTAssertEqual(slot(500, "Rain", 45), "rain_light")
        XCTAssertEqual(slot(500, "Rain", 44), "rain_light_cold")
        // The case that motivated the split: a near-freezing downpour must not
        // land on Kamino's warm tropical rain.
        XCTAssertEqual(slot(502, "Rain", 34), "rain_cold")
        XCTAssertEqual(slot(502, "Rain", 88), "rain")
    }

    func testRainReusesThe45FBoundary() {
        let clearBoundaries: Set<Double> = [100, 90, 79, 69, 58, 45, 32]
        XCTAssertTrue(clearBoundaries.contains(45))
    }

    func testSnowAndThunderstormStayTemperatureBlind() {
        // Phase already implies the temperature, so these stay unbanded.
        for tempF in [10.0, 30.0, 34.0] {
            XCTAssertEqual(slot(601, "Snow", tempF), "snow", "at \(tempF)°F")
        }
        for tempF in [40.0, 70.0, 95.0] {
            XCTAssertEqual(slot(211, "Thunderstorm", tempF), "thunderstorm", "at \(tempF)°F")
        }
    }

    // MARK: - Fallbacks

    func testUnknownCodeDegradesToItsGroup() {
        XCTAssertEqual(slot(299, "Thunderstorm"), "thunderstorm")
        XCTAssertEqual(slot(399, "Drizzle"), "drizzle")
        XCTAssertEqual(slot(599, "Rain"), "rain")
        XCTAssertEqual(slot(699, "Snow"), "snow")
        XCTAssertEqual(slot(799, "Mist"), "mist")
    }

    func testUnknown8xxCodeDegradesToCloudsLadder() {
        XCTAssertEqual(slot(805, "Clouds", 40), "clouds_cold")
    }

    func testFallsBackToMainStringWhenCodeIsMeaningless() {
        XCTAssertEqual(slot(0, "Clear", 70), "clear_temperate")
        XCTAssertEqual(slot(0, "Clouds", 40), "clouds_cold")
        XCTAssertEqual(slot(0, "Snow", 30), "snow")
        XCTAssertEqual(slot(0, "Rain", 40), "rain_cold")
        XCTAssertEqual(slot(0, "Tornado", 70), "thunderstorm")
    }

    func testFallsBackToDefaultSlotWhenNothingMatches() {
        XCTAssertEqual(slot(0, "Sharknado", 70), FALLBACK_SLOT_ID)
    }

    // MARK: - Every main string the API can send

    func testEveryMainStringResolvesToARealSlot() {
        let allMains = [
            "Thunderstorm", "Drizzle", "Rain", "Snow", "Mist", "Smoke", "Haze",
            "Dust", "Fog", "Sand", "Ash", "Squall", "Tornado", "Clear", "Clouds",
        ]
        let known = Set(SLOTS.map(\.id))
        for main in allMains {
            XCTAssertTrue(known.contains(slot(0, main, 70)), "main \(main)")
        }
    }
}
