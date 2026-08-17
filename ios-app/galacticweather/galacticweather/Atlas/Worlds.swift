import Foundation

/// The catalog of worlds available to assign to a weather slot.
///
/// `id` must match the imageset name in Assets.xcassets/Planets. Descriptions
/// here are the world's canonical copy — used whenever a world is assigned to
/// a slot that has no slot-specific description of its own (see Slots.swift).
/// Port of the web app's `src/lib/atlas/worlds.ts`.
let WORLDS: [World] = [
    World(
        id: "ahch-to",
        name: "Ahch-To",
        description: "A remote ocean world of jagged island peaks, sea spray, and restless grey water.",
        climate: .ocean,
        color: WorldColor(primary: "#5C7684", headline: "#B4CEDA"),
        isPremium: true
    ),
    World(
        id: "alderaan",
        name: "Alderaan",
        description: "A peaceful, beautiful world of rolling hills and crisp, clear air.",
        climate: .temperate,
        color: WorldColor(primary: "#5F749E", headline: "#C4D8E8"),
        isPremium: true
    ),
    World(
        id: "at-attin",
        name: "At-Attin",
        description: "A rumored paradise world — warm and hazy beneath a blanket of soft clouds.",
        climate: .temperate,
        color: WorldColor(primary: "#7A9E8A", headline: "#C8E0D0")
    ),
    World(
        id: "bespin",
        name: "Bespin",
        description: "Cloud City drifts through cold upper atmosphere, wrapped in dense cloud cover.",
        climate: .sky,
        color: WorldColor(primary: "#C15A51", headline: "#F4BE9C")
    ),
    World(
        id: "corellia",
        name: "Corellia",
        description: "A shipyard world of green industrial haze, its cranes fading into the murk.",
        climate: .urban,
        color: WorldColor(primary: "#3E6B57", headline: "#C3D68F")
    ),
    World(
        id: "coruscant",
        name: "Coruscant",
        description: "A city that covers a world entirely — endless towers under a haze of traffic light.",
        climate: .urban,
        color: WorldColor(primary: "#6E7A93", headline: "#C3CEE4"),
        isPremium: true
    ),
    World(
        id: "dagobah",
        name: "Dagobah",
        description: "A swampy, mist-laden world with a damp atmosphere that matches steady light rain.",
        climate: .forest,
        color: WorldColor(primary: "#48542D", headline: "#6C7858")
    ),
    World(
        id: "daiyu",
        name: "Daiyu",
        description: "A neon port city under low cloud, its streets slick with cold rain.",
        climate: .urban,
        color: WorldColor(primary: "#14403C", headline: "#63C7BC")
    ),
    World(
        id: "dantooine",
        name: "Dantooine",
        description: "Quiet farmland under tall white clouds — green, cool, and open to the horizon.",
        climate: .temperate,
        color: WorldColor(primary: "#2F8272", headline: "#D8E39B")
    ),
    World(
        id: "endor",
        name: "Endor",
        description: "A forest moon with cool, humid air and frequent mist through dense woodland.",
        climate: .forest,
        color: WorldColor(primary: "#6B8A60", headline: "#BCD2B5")
    ),
    World(
        id: "exegol",
        name: "Exegol",
        description: "A storm-wracked world with relentless lightning, heavy rain, and violent weather.",
        climate: .storm,
        color: WorldColor(primary: "#9589A4", headline: "#686788")
    ),
    World(
        id: "ferrix",
        name: "Ferrix",
        description: "A close-built foundry town where terracotta roofs hold the last of the sun.",
        climate: .urban,
        color: WorldColor(primary: "#B5622F", headline: "#F6CE93"),
        isPremium: true
    ),
    World(
        id: "ghorman",
        name: "Ghorman",
        description: "A temperate trade world of grey overcast skies and quiet, cultural streets.",
        climate: .urban,
        color: WorldColor(primary: "#7A8090", headline: "#B8C0C8")
    ),
    World(
        id: "hoth",
        name: "Hoth",
        description: "An icy world covered in snow year-round, swept by freezing wind.",
        climate: .ice,
        color: WorldColor(primary: "#39657F", headline: "#6DB3DC")
    ),
    World(
        id: "ilum",
        name: "Ilum",
        description: "A frigid, crystal-lined world with clear skies and severe cold.",
        climate: .ice,
        color: WorldColor(primary: "#A4B3C1", headline: "#A9CEEF")
    ),
    World(
        id: "jakku",
        name: "Jakku",
        description: "A desert scrapyard world with endless dunes and dust-choked skies.",
        climate: .desert,
        color: WorldColor(primary: "#A8895A", headline: "#E8D09A"),
        isPremium: true
    ),
    World(
        id: "janix",
        name: "Janix",
        description: "A skyline of glass towers under a deep, star-thick twilight.",
        climate: .urban,
        color: WorldColor(primary: "#172B6B", headline: "#C4A4BC"),
        isPremium: true
    ),
    World(
        id: "jedha",
        name: "Jedha",
        description: "A desert moon of pilgrim cities, its air thick with golden dust.",
        climate: .desert,
        color: WorldColor(primary: "#69865C", headline: "#FDD16E"),
        isPremium: true
    ),
    World(
        id: "kamino",
        name: "Kamino",
        description: "A water planet that experiences frequent, heavy rainfall.",
        climate: .ocean,
        color: WorldColor(primary: "#868D9F", headline: "#C9CFB9")
    ),
    World(
        id: "kashyyyk",
        name: "Kashyyyk",
        description: "A forested world that feels brisk and chilly beneath towering canopies.",
        climate: .forest,
        color: WorldColor(primary: "#6C7F74", headline: "#7C9688")
    ),
    World(
        id: "kef-bir",
        name: "Kef Bir",
        description: "An ocean moon of grey rolling swells and hard wind off open water.",
        climate: .ocean,
        color: WorldColor(primary: "#2D7787", headline: "#96BBC3"),
        isPremium: true
    ),
    World(
        id: "kessel",
        name: "Kessel",
        description: "A mining world under permanent stacks of black industrial smoke.",
        climate: .urban,
        color: WorldColor(primary: "#342F2E", headline: "#F1B26E")
    ),
    World(
        id: "kijimi",
        name: "Kijimi",
        description: "A cold mountain world with ancient cities dusted in light snowfall.",
        climate: .ice,
        color: WorldColor(primary: "#8AA3B5", headline: "#C8DDE8")
    ),
    World(
        id: "lothal",
        name: "Lothal",
        description: "Wide grass plains beneath an enormous, cloudless sky.",
        climate: .temperate,
        color: WorldColor(primary: "#2C7FA6", headline: "#FBDD97"),
        isPremium: true
    ),
    World(
        id: "mandalore",
        name: "Mandalore",
        description: "Glassed plains and drowned spires, half-lost in pale grey mist.",
        climate: .desert,
        color: WorldColor(primary: "#517566", headline: "#A2C2A7")
    ),
    World(
        id: "mathleen-divide",
        name: "Mathleen Divide",
        description: "A high range of snowbound peaks under a thin, pale sun.",
        climate: .ice,
        color: WorldColor(primary: "#548F8D", headline: "#D3DABF"),
        isPremium: true
    ),
    World(
        id: "mina-rau",
        name: "Mina-Rau",
        description: "A quiet farm world of golden grain under a wide, clear sky.",
        climate: .temperate,
        color: WorldColor(primary: "#3A8176", headline: "#B2C78A"),
        isPremium: true
    ),
    World(
        id: "mon-cala",
        name: "Mon Cala",
        description: "An ocean world seen from below — coral canyons and slanting light.",
        climate: .ocean,
        color: WorldColor(primary: "#1B708C", headline: "#6AD1D7"),
        isPremium: true
    ),
    World(
        id: "mortis",
        name: "Mortis",
        description: "A realm between worlds, shrouded in thick fog and an otherworldly stillness.",
        climate: .storm,
        color: WorldColor(primary: "#7A7090", headline: "#B0A8C8"),
        isPremium: true
    ),
    World(
        id: "mustafar",
        name: "Mustafar",
        description: "A volcanic world of lava rivers and an ash-filled, smoky sky.",
        climate: .volcanic,
        color: WorldColor(primary: "#AC5861", headline: "#B47A80")
    ),
    World(
        id: "naboo",
        name: "Naboo",
        description: "A balanced, temperate climate with clear skies and calm conditions.",
        climate: .temperate,
        color: WorldColor(primary: "#7A609B", headline: "#B5C0EE")
    ),
    World(
        id: "nevarro",
        name: "Nevarro",
        description: "A warm volcanic world where tall clouds pile above a sunlit town.",
        climate: .volcanic,
        color: WorldColor(primary: "#36726A", headline: "#D0A921"),
        isPremium: true
    ),
    World(
        id: "niamos",
        name: "Niamos",
        description: "A sunny, tropical beach planet known for its vibrant resorts and relaxing atmosphere.",
        climate: .ocean,
        color: WorldColor(primary: "#7B9684", headline: "#DBDFBF"),
        isPremium: true
    ),
    World(
        id: "nur",
        name: "Nur",
        description: "A dark ocean moon of perpetual rain, lashed by wind above a black sea.",
        climate: .ocean,
        color: WorldColor(primary: "#4A5A6B", headline: "#9DB2C4"),
        isPremium: true
    ),
    World(
        id: "ossus",
        name: "Ossus",
        description: "Green mountain forest beneath towering white cloud.",
        climate: .forest,
        color: WorldColor(primary: "#137769", headline: "#C9E6B7"),
        isPremium: true
    ),
    World(
        id: "ryloth",
        name: "Ryloth",
        description: "Red canyon spires beneath a violent violet-and-orange dusk.",
        climate: .desert,
        color: WorldColor(primary: "#282586", headline: "#F5A65B"),
        isPremium: true
    ),
    World(
        id: "scarif",
        name: "Scarif",
        description: "A warm tropical world with clear skies and bright coastal weather.",
        climate: .ocean,
        color: WorldColor(primary: "#237691", headline: "#95E1F6")
    ),
    World(
        id: "sorgan",
        name: "Sorgan",
        description: "A humid marsh of paddy ponds and thatched roofs, warm and still.",
        climate: .forest,
        color: WorldColor(primary: "#2C786D", headline: "#CFD575"),
        isPremium: true
    ),
    World(
        id: "takodana",
        name: "Takodana",
        description: "Forested lake country under bright, drifting cumulus.",
        climate: .forest,
        color: WorldColor(primary: "#3B619F", headline: "#CBDBE8"),
        isPremium: true
    ),
    World(
        id: "tatooine",
        name: "Tatooine",
        description: "A desert world of twin suns, known for its scorching heat and clear skies.",
        climate: .desert,
        color: WorldColor(primary: "#944505", headline: "#FDC683")
    ),
    World(
        id: "yavin",
        name: "Yavin 4",
        description: "A jungle moon draped in warm humidity and overcast tropical skies.",
        climate: .forest,
        color: WorldColor(primary: "#6B7A4A", headline: "#B8C890")
    ),
]

private let worldByID: [WorldId: World] = Dictionary(uniqueKeysWithValues: WORLDS.map { ($0.id, $0) })

func getWorld(_ id: WorldId) -> World? { worldByID[id] }

func isKnownWorld(_ id: String) -> Bool { worldByID[id] != nil }

/// Catalog-wide counts, computed once. Used by upsell copy so the numbers
/// track the catalog automatically as worlds are added — new worlds default
/// to premium (`World.isPremium`), so this is the number that grows.
enum AtlasCatalog {
    static let premiumWorldCount = WORLDS.filter(\.isPremium).count
    static let freeWorldCount = WORLDS.count - premiumWorldCount
}
