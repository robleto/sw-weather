import Foundation

/// Maps an OpenWeatherMap condition to an Atlas slot id.
///
/// `weather[0].id` — the numeric condition code — is the primary signal. It is
/// the only field that separates sleet from heavy snow, freezing rain from a
/// warm downpour, and a few passing clouds from full overcast; `weather[0].main`
/// collapses all of those together. `main` is kept purely as a fallback for
/// codes we don't recognize.
///
/// This deliberately stops at the slot. Which *world* a slot displays is a
/// separate question owned by Atlas (see Atlas/Resolve.swift),
/// because the user can reassign it. Port of the web app's
/// `src/app/utils/weatherDescriptions.ts` (`getSlotForWeather`).
enum WeatherDescriptionMapper {
    /// Which temperature ladder a temperature-dependent code feeds into.
    private enum TempLadder {
        case clear
        case clouds
        case rain
        case rainLight
    }

    /// Condition codes that resolve to a slot outright, with no temperature
    /// input. Grouped by slot rather than by OpenWeatherMap group so the
    /// non-obvious placements stay visible — see `snow_light` in particular.
    private static let slotCodes: [(SlotId, [Int])] = [
        // 2xx thunderstorm, plus squalls (771) and tornado (781), which the old
        // string aliases already folded in here.
        ("thunderstorm", [200, 201, 202, 210, 211, 212, 221, 230, 231, 232, 771, 781]),

        // 3xx drizzle.
        ("drizzle", [300, 301, 302, 310, 311, 312, 313, 314, 321]),

        // 5xx rain is temperature-dependent and lives in ladderCodes below.

        // 6xx snow, heavy end. Snow is not temperature-banded: the phase
        // already tells you it is near freezing, so a band would add nothing.
        ("snow", [601, 602, 621, 622]),

        // 6xx snow, light end — plus sleet (611–613) and rain/snow mixes
        // (615, 616), which used to land on "Heavy snow", and freezing rain
        // (511), which used to land on Kamino's warm downpour despite being
        // ice on the ground.
        ("snow_light", [511, 600, 611, 612, 613, 615, 616, 620]),

        // 7xx atmosphere.
        ("mist", [701]),
        ("smoke", [711, 762]),
        ("haze", [721]),
        ("fog", [741]),
        ("jakku", [731, 751, 761]),
    ]

    private static let slotByCode: [Int: SlotId] = {
        var table: [Int: SlotId] = [:]
        for (slot, codes) in slotCodes {
            for code in codes { table[code] = slot }
        }
        return table
    }()

    /// Condition codes whose slot depends on temperature as well as condition.
    private static let ladderCodes: [(TempLadder, [Int])] = [
        // The 800 group encodes cloud cover as a percentage band. 801 is
        // 11–25% — a sunny day with some clouds in it — so it takes the clear
        // ladder instead of being flattened into overcast alongside 804.
        (.clear, [800, 801]),
        (.clouds, [802, 803, 804]),

        // 5xx rain, split cold from warm: a 35°F downpour has nothing in
        // common with a warm tropical one. Intensity splits first (the plain
        // and moderate variants sit with the heavy ones, matching how snow is
        // split), then each side splits again on temperature. Freezing rain
        // (511) is absent on purpose — it resolves straight to snow_light.
        (.rain, [501, 502, 503, 504, 521, 522, 531]),
        (.rainLight, [500, 520]),
    ]

    private static let ladderByCode: [Int: TempLadder] = {
        var table: [Int: TempLadder] = [:]
        for (ladder, codes) in ladderCodes {
            for code in codes { table[code] = ladder }
        }
        return table
    }()

    private static let conditionAliases: [String: SlotId] = [
        "dust": "jakku",
        "sand": "jakku",
        "ash": "smoke",
        "squall": "thunderstorm",
        "tornado": "thunderstorm",
    ]

    /// Bands are quoted to the user in whole degrees ("69–78°F"), and the
    /// readout rounds too, so classification rounds first. Otherwise a true
    /// 75.6°F displays as "76°F" while landing in the band the UI labels
    /// 69–78. Rounding also keeps exact boundaries off the edge of
    /// Kelvin→Fahrenheit float error.
    ///
    /// `floor(x + 0.5)` rather than `.rounded()` so this matches the web app's
    /// `Math.round` exactly, including for negative halves.
    private static func roundedF(_ tempF: Double) -> Double {
        (tempF + 0.5).rounded(.down)
    }

    /// The clear ladder. Anchored on the two temperatures that mean something
    /// outside this app — freezing at 32°F and the century mark at 100°F —
    /// and cut into 10–13°F steps in between, rather than the old 9–27°F
    /// spread that buried 32°F in the middle of a band called "cold".
    private static func clearSlot(forFahrenheit temp: Double) -> SlotId {
        let tempF = roundedF(temp)
        if tempF >= 100 { return "clear_scorching" }
        if tempF >= 90 { return "clear_hot" }
        if tempF >= 79 { return "clear_warm" }
        if tempF >= 69 { return "clear_temperate" }
        if tempF >= 58 { return "clear_cool" }
        if tempF >= 45 { return "clear_chilly" }
        if tempF >= 32 { return "clear_cold" }
        return "clear_freezing"
    }

    /// The clouds ladder is a strict coarsening of the clear one — every
    /// boundary here is also a clear boundary, so the two can never disagree
    /// about where "cool" ends:
    ///
    ///   clouds_freezing  = clear_freezing                           (below 32)
    ///   clouds_cold      = clear_cold                               (32–44)
    ///   clouds_cool      = clear_chilly   + clear_cool              (45–68)
    ///   clouds_temperate = clear_temperate                          (69–78)
    ///   clouds_warm      = clear_warm + clear_hot + clear_scorching (79 and up)
    private static func cloudsSlot(forFahrenheit temp: Double) -> SlotId {
        let tempF = roundedF(temp)
        if tempF >= 79 { return "clouds_warm" }
        if tempF >= 69 { return "clouds_temperate" }
        if tempF >= 45 { return "clouds_cool" }
        if tempF >= 32 { return "clouds_cold" }
        return "clouds_freezing"
    }

    /// Rain splits cold from warm at 45°F — an existing boundary on both the
    /// clear and clouds ladders, so all three agree on where "cold" starts.
    /// Two bands rather than the full ladder because liquid rain can only occur
    /// across a narrow slice of it, and a slot that can never fire is just
    /// clutter in Atlas.
    private static func rainSlot(forFahrenheit temp: Double) -> SlotId {
        roundedF(temp) >= 45 ? "rain" : "rain_cold"
    }

    private static func rainLightSlot(forFahrenheit temp: Double) -> SlotId {
        roundedF(temp) >= 45 ? "rain_light" : "rain_light_cold"
    }

    private static func slot(for ladder: TempLadder, tempF: Double) -> SlotId {
        switch ladder {
        case .clear: return clearSlot(forFahrenheit: tempF)
        case .clouds: return cloudsSlot(forFahrenheit: tempF)
        case .rain: return rainSlot(forFahrenheit: tempF)
        case .rainLight: return rainLightSlot(forFahrenheit: tempF)
        }
    }

    /// Resolve by numeric condition code. `nil` means "code not recognized".
    private static func slot(forCode code: Int, tempF: Double) -> SlotId? {
        if let direct = slotByCode[code] { return direct }
        if let ladder = ladderByCode[code] { return slot(for: ladder, tempF: tempF) }

        // An unknown code is still informative: OpenWeatherMap groups by
        // leading digit, so a code added after this table was written
        // degrades to its group.
        switch code / 100 {
        case 2: return "thunderstorm"
        case 3: return "drizzle"
        case 5: return rainSlot(forFahrenheit: tempF)
        case 6: return "snow"
        case 7: return "mist"
        case 8: return cloudsSlot(forFahrenheit: tempF)
        default: return nil
        }
    }

    /// Fallback path: resolve from the coarse `main` string.
    private static func slot(forConditionName main: String, tempF: Double) -> SlotId {
        let condition = main.lowercased()

        if let alias = conditionAliases[condition], getSlot(alias) != nil {
            return alias
        }

        if condition == "clouds" { return cloudsSlot(forFahrenheit: tempF) }
        if condition == "clear" { return clearSlot(forFahrenheit: tempF) }
        // `main` carries no intensity, so an unrecognized rain code takes the
        // heavy ladder — same reasoning as the 5xx group fallback above.
        if condition == "rain" { return rainSlot(forFahrenheit: tempF) }

        if getSlot(condition) != nil { return condition }

        return FALLBACK_SLOT_ID
    }

    /// Main lookup. Every argument is required — an optional trailing parameter
    /// is exactly how the web app silently lost its light-snow handling.
    static func getSlotForWeather(
        conditionCode: Int,
        weatherMain: String,
        tempKelvin: Double
    ) -> SlotId {
        let tempF = kelvinToFahrenheit(tempKelvin)

        if let fromCode = slot(forCode: conditionCode, tempF: tempF) {
            return fromCode
        }

        return slot(forConditionName: weatherMain, tempF: tempF)
    }
}
