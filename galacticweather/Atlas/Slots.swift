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
    Slot(id: "rain", label: "Rain", group: .precipitation, defaultWorld: "kamino"),
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
    Slot(id: "clouds_warm", label: "Cloudy · warm", group: .cloudCover, defaultWorld: "bespin"),
    Slot(id: "clouds_temperate", label: "Cloudy · mild", group: .cloudCover, defaultWorld: "bespin"),
    Slot(id: "clouds_cool", label: "Cloudy · cool", group: .cloudCover, defaultWorld: "bespin"),
    Slot(id: "clouds_cold", label: "Cloudy · cold", group: .cloudCover, defaultWorld: "bespin"),

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
    Slot(id: "clear_cool", label: "Clear · cool", group: .clearSkies, defaultWorld: "naboo"),
    Slot(id: "clear_chilly", label: "Clear · chilly", group: .clearSkies, defaultWorld: "kashyyyk"),
    Slot(
        id: "clear_cold",
        label: "Clear · cold",
        group: .clearSkies,
        defaultWorld: "hoth",
        defaultDescription: "A frozen wasteland of biting cold and clear, pale skies."
    ),
    Slot(id: "clear_freezing", label: "Clear · freezing", group: .clearSkies, defaultWorld: "hoth"),
]

let SLOT_GROUP_ORDER: [SlotGroup] = [.clearSkies, .cloudCover, .precipitation, .atmosphere]

/// Temperature bands shown as secondary text next to a slot label.
let SLOT_RANGE_HINT: [SlotId: String] = [
    "clouds_warm": "76°F and up",
    "clouds_temperate": "66–75°F",
    "clouds_cool": "50–65°F",
    "clouds_cold": "below 50°F",
    "clear_scorching": "99°F and up",
    "clear_hot": "85–98°F",
    "clear_warm": "76–84°F",
    "clear_temperate": "66–75°F",
    "clear_cool": "50–65°F",
    "clear_chilly": "41–49°F",
    "clear_cold": "14–40°F",
    "clear_freezing": "below 14°F",
]

private let slotByID: [SlotId: Slot] = Dictionary(uniqueKeysWithValues: SLOTS.map { ($0.id, $0) })

func getSlot(_ id: SlotId) -> Slot? { slotByID[id] }

let FALLBACK_SLOT_ID: SlotId = "clear_temperate"
