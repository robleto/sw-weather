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
    Slot(id: "fog", label: "Fog", group: .atmosphere, defaultWorld: "endor"),
    Slot(id: "haze", label: "Haze", group: .atmosphere, defaultWorld: "niamos"),
    Slot(id: "smoke", label: "Smoke & ash", group: .atmosphere, defaultWorld: "mustafar"),
    Slot(id: "jakku", label: "Dust & sand", group: .atmosphere, defaultWorld: "tatooine"),

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
    Slot(id: "clear_freezing", label: "Clear · freezing", group: .clearSkies, defaultWorld: "hoth"),
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

private let slotByID: [SlotId: Slot] = Dictionary(uniqueKeysWithValues: SLOTS.map { ($0.id, $0) })

func getSlot(_ id: SlotId) -> Slot? { slotByID[id] }

let FALLBACK_SLOT_ID: SlotId = "clear_temperate"
