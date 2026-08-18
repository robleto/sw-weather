import Foundation

/// Every weather bucket the app can land in, with the world it uses by default.
///
/// These defaults reproduce the original PlanetData.json mapping exactly.
/// `defaultDescription` is set only where the original slot copy read better
/// than the world's canonical description; a user-assigned world always
/// brings its own description with it. Port of the web app's
/// `src/lib/atlas/slots.ts`.
let SLOTS: [Slot] = [
    // ── Precipitation ────────────────────────────────────────────────────
    Slot(id: "thunderstorm", label: "Thunderstorm", group: .precipitation, defaultWorld: "exegol"),
    Slot(id: "drizzle", label: "Drizzle", group: .precipitation, defaultWorld: "dagobah"),
    Slot(id: "rain", label: "Heavy rain", group: .precipitation, defaultWorld: "kamino"),
    Slot(id: "rain_cold", label: "Heavy rain · cold", group: .precipitation, defaultWorld: "daiyu"),
    Slot(id: "rain_light", label: "Light rain", group: .precipitation, defaultWorld: "dagobah"),
    Slot(
        id: "rain_light_cold",
        label: "Light rain · cold",
        group: .precipitation,
        defaultWorld: "kashyyyk",
        defaultDescription: "A brisk, chilly drizzle filtering down through towering canopies."
    ),
    Slot(
        id: "snow",
        label: "Heavy snow",
        group: .precipitation,
        defaultWorld: "hoth",
        defaultDescription: "The icy planet covered in ice and snow year-round, making it the perfect match for heavy snow."
    ),
    Slot(id: "snow_light", label: "Light snow", group: .precipitation, defaultWorld: "kijimi"),

    // ── Atmosphere ───────────────────────────────────────────────────────
    Slot(id: "mist", label: "Mist", group: .atmosphere, defaultWorld: "endor"),
    Slot(id: "fog", label: "Fog", group: .atmosphere, defaultWorld: "mandalore"),
    Slot(id: "haze", label: "Haze", group: .atmosphere, defaultWorld: "corellia"),
    Slot(id: "smoke", label: "Smoke & ash", group: .atmosphere, defaultWorld: "kessel"),
    Slot(id: "dust", label: "Dust & sand", group: .atmosphere, defaultWorld: "tatooine"),

    // ── Cloud cover ──────────────────────────────────────────────────────
    Slot(id: "clouds_warm", label: "Cloudy · warm", group: .cloudCover, defaultWorld: "at-attin"),
    Slot(id: "clouds_temperate", label: "Cloudy · mild", group: .cloudCover, defaultWorld: "yavin"),
    Slot(id: "clouds_cool", label: "Cloudy · cool", group: .cloudCover, defaultWorld: "ghorman"),
    Slot(id: "clouds_cold", label: "Cloudy · cold", group: .cloudCover, defaultWorld: "bespin"),
    Slot(
        id: "clouds_freezing",
        label: "Cloudy · freezing",
        group: .cloudCover,
        defaultWorld: "kijimi",
        // Kijimi's canonical copy mentions falling snow, which is wrong here —
        // this is the overcast-and-freezing slot, not a precipitation one.
        defaultDescription: "A cold mountain world of ancient streets beneath low, freezing cloud."
    ),

    // ── Clear skies ──────────────────────────────────────────────────────
    Slot(
        id: "clear_scorching",
        label: "Clear · scorching",
        group: .clearSkies,
        defaultWorld: "mustafar",
        defaultDescription: "An extremely hot volcanic world with blistering heat and fiery terrain."
    ),
    Slot(
        id: "clear_hot",
        label: "Clear · hot",
        group: .clearSkies,
        defaultWorld: "tatooine",
        defaultDescription: "The desert planet with twin suns is known for its scorching heat and clear skies."
    ),
    Slot(id: "clear_warm", label: "Clear · warm", group: .clearSkies, defaultWorld: "scarif"),
    Slot(id: "clear_temperate", label: "Clear · mild", group: .clearSkies, defaultWorld: "naboo"),
    Slot(id: "clear_cool", label: "Clear · cool", group: .clearSkies, defaultWorld: "dantooine"),
    Slot(id: "clear_chilly", label: "Clear · chilly", group: .clearSkies, defaultWorld: "kashyyyk"),
    Slot(
        id: "clear_cold",
        label: "Clear · cold",
        group: .clearSkies,
        defaultWorld: "hoth",
        defaultDescription: "An icy world at its calmest — crisp, cold air beneath clear, pale skies."
    ),
    Slot(id: "clear_freezing", label: "Clear · freezing", group: .clearSkies, defaultWorld: "ilum"),
]

let SLOT_GROUP_ORDER: [SlotGroup] = [.clearSkies, .cloudCover, .precipitation, .atmosphere]

/// Temperature bands shown as secondary text next to a slot label.
let SLOT_RANGE_HINT: [SlotId: String] = [
    "rain": "45°F and up",
    "rain_cold": "below 45°F",
    "rain_light": "45°F and up",
    "rain_light_cold": "below 45°F",
    "clouds_warm": "79°F and up",
    "clouds_temperate": "69–78°F",
    "clouds_cool": "45–68°F",
    "clouds_cold": "32–44°F",
    "clouds_freezing": "below 32°F",
    "clear_scorching": "100°F and up",
    "clear_hot": "90–99°F",
    "clear_warm": "79–89°F",
    "clear_temperate": "69–78°F",
    "clear_cool": "58–68°F",
    "clear_chilly": "45–57°F",
    "clear_cold": "32–44°F",
    "clear_freezing": "below 32°F",
]

/// Where on Earth to go looking for each condition.
///
/// The Passport's difficulty was never a function of how many worlds exist — it
/// comes from physics. `clear_temperate` happens everywhere; `clear_scorching`
/// needs 100°F *and* a clear sky, which in January is a short list of places.
/// Without a nudge that asymmetry is invisible, and an unfound world reads as a
/// checklist row rather than something huntable.
///
/// Deliberately geographic and seasonal rather than numeric: `SLOT_RANGE_HINT`
/// already carries the temperature band, and repeating it here would say nothing
/// the label doesn't. These name places.
///
/// Port of the web app's `SLOT_HUNT_HINT`. Divergence is cosmetic — unlike the
/// weather->slot mapping, prose drifting between platforms produces a slightly
/// different sentence, not a wrong answer, which is why this has no shared
/// fixture.
let SLOT_HUNT_HINT: [SlotId: String] = [
    "thunderstorm": "Somewhere is always storming — the tropics, or inland on a summer afternoon.",
    "drizzle": "Maritime coasts and mild winters — Britain, the Pacific Northwest.",
    "rain": "Monsoon belts, or a warm front parked over a coast.",
    "rain_cold": "Late autumn in the north — the Great Lakes, the Baltic.",
    "rain_light": "Common and forgiving. Most temperate coasts will do.",
    "rain_light_cold": "A raw drizzle in shoulder season — the North Atlantic.",
    "snow": "Winter at altitude or high latitude — the Alps, the Rockies, Hokkaido.",
    "snow_light": "The edges of winter, or a cold snap anywhere temperate.",
    "mist": "River valleys at dawn, and mild coasts just after rain.",
    "fog": "Cool water beside warm land — San Francisco, Newfoundland, the North Sea.",
    "haze": "Humid summer air over a large city.",
    "smoke": "Rare and grim: downwind of a wildfire, in fire season.",
    "dust": "Desert margins in spring — the Sahel, Mongolia, inland Australia.",
    "clouds_warm": "An overcast tropic — the Gulf Coast, Southeast Asia.",
    "clouds_temperate": "The default weather of half the temperate world.",
    "clouds_cool": "Northern Europe, most of the year.",
    "clouds_cold": "A grey winter day inland — above freezing, but not by much.",
    "clouds_freezing": "Overcast and below freezing — continental interiors in deep winter.",
    "clear_scorching": "Desert interiors at midsummer — Arabia, the Sahara, Death Valley.",
    "clear_hot": "A cloudless summer afternoon in the subtropics.",
    "clear_warm": "Mediterranean summer, or the tropics in dry season.",
    "clear_temperate": "The easiest stamp in the book — a fine spring day almost anywhere.",
    "clear_cool": "Clear and crisp — temperate spring and autumn.",
    "clear_chilly": "A bright, cold morning in early spring.",
    "clear_cold": "Clear winter sun with frost still on the ground.",
    "clear_freezing": "A clear winter night inland — Siberia, the Prairies, high Asia.",
]

/// What a Passport entry needs to say about how to find a world in the wild.
struct WorldHunt {
    /// Every condition this world is the default for, in slot order.
    let slotLabels: [String]
    /// Temperature band for the first of those conditions, when it has one.
    let range: String?
    /// Where to go looking.
    let hint: String?
}

/// How to find `worldID` without assigning it first.
///
/// Derived from the slot table rather than authored per world, so it cannot fall
/// out of step with the defaults — five worlds cover two conditions each, and a
/// hand-written list would have to be revisited every time a default moved.
///
/// Returns nil for a world no slot defaults to. Those are the premium
/// alternates, which no forecast leads to and which the Passport already covers
/// with its own copy.
func huntForWorld(_ worldID: WorldId) -> WorldHunt? {
    let owning = SLOTS.filter { $0.defaultWorld == worldID }
    guard let first = owning.first else { return nil }
    return WorldHunt(
        slotLabels: owning.map(\.label),
        range: SLOT_RANGE_HINT[first.id],
        hint: SLOT_HUNT_HINT[first.id]
    )
}

/// Slot ids that have been renamed, old id -> current id.
///
/// Slot ids are not just internal labels: they key stored Atlas assignments and
/// are recorded on every Passport stamp, so renaming one orphans real data.
/// Both storage layers drop entries whose slot they don't recognize, which
/// would turn a rename into a silent reset of that slot's assignment.
///
/// `dust` was `jakku` — a franchise world name where every other slot is
/// generic weather vocabulary. That mattered once analytics started sending
/// slot ids precisely *because* they're generic; see
/// `shared/analytics-signals.json`.
///
/// Port of the web app's `RENAMED_SLOT_IDS`; both can go once no stored data
/// predates the rename.
let RENAMED_SLOT_IDS: [String: SlotId] = [
    "jakku": "dust"
]

/// The current id for a possibly-historical one. Unknown ids pass through.
func canonicalSlotId(_ id: String) -> SlotId { RENAMED_SLOT_IDS[id] ?? id }

private let slotByID: [SlotId: Slot] = Dictionary(uniqueKeysWithValues: SLOTS.map { ($0.id, $0) })

func getSlot(_ id: SlotId) -> Slot? { slotByID[id] }

let FALLBACK_SLOT_ID: SlotId = "clear_temperate"
