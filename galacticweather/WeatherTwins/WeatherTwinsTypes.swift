import Foundation

/// A world's asset id — must match an imageset in Assets.xcassets/Planets.
typealias WorldId = String

/// A weather bucket the app can land in. One slot resolves to one world.
typealias SlotId = String

/// User customizations, keyed by slot. A slot may hold several worlds; when it
/// does, one is chosen per resolution so the surprise of the free experience
/// survives customization. Port of the web app's `WeatherTwinsOverrides`.
typealias WeatherTwinsOverrides = [SlotId: [WorldId]]

/// Coarse climate grouping, used as the filter axis in the planet picker.
enum Climate: String, CaseIterable {
    case desert, ice, ocean, forest, volcanic, urban, temperate, storm, sky

    var label: String {
        switch self {
        case .desert: return "Desert"
        case .ice: return "Ice"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .volcanic: return "Volcanic"
        case .urban: return "Urban"
        case .temperate: return "Temperate"
        case .storm: return "Storm"
        case .sky: return "Sky"
        }
    }
}

struct WorldColor {
    /// Hex color string, e.g. "#7A609B".
    let primary: String
    /// Hex color string, e.g. "#7A609B".
    let headline: String
}

struct World: Identifiable {
    let id: WorldId
    let name: String
    let description: String
    let climate: Climate
    let color: WorldColor
    /// Locked in the planet picker for free users; premium unlocks it.
    let isPremium: Bool

    init(
        id: WorldId,
        name: String,
        description: String,
        climate: Climate,
        color: WorldColor,
        isPremium: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.climate = climate
        self.color = color
        self.isPremium = isPremium
    }
}

/// Slots are grouped purely for display in Weather Twins.
enum SlotGroup: String, CaseIterable {
    case precipitation = "Precipitation"
    case cloudCover = "Cloud cover"
    case clearSkies = "Clear skies"
    case atmosphere = "Atmosphere"
}

struct Slot: Identifiable, Hashable {
    let id: SlotId
    /// Human label shown in Weather Twins, e.g. "Heavy snow".
    let label: String
    let group: SlotGroup
    /// The world used when the user has not customized this slot.
    let defaultWorld: WorldId
    /// Slot-specific copy that reads better than the world's canonical
    /// description in this context. Only applies while the slot is at its
    /// default world — a user-assigned world always uses its own description.
    let defaultDescription: String?

    init(id: SlotId, label: String, group: SlotGroup, defaultWorld: WorldId, defaultDescription: String? = nil) {
        self.id = id
        self.label = label
        self.group = group
        self.defaultWorld = defaultWorld
        self.defaultDescription = defaultDescription
    }

    static func == (lhs: Slot, rhs: Slot) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A fully resolved slot, ready to render.
struct ResolvedWorld {
    let slotId: SlotId
    let planet: WorldId
    let planetName: String
    let description: String
    let color: WorldColor
    /// True when this slot is showing something other than its default.
    let customized: Bool

    /// Small "idle/loading" default value for use before any weather has loaded.
    static let idle = ResolvedWorld(
        slotId: "",
        planet: "default",
        planetName: "default",
        description: "",
        color: WorldColor(primary: "#000000", headline: "#000000"),
        customized: false
    )
}

/// De-dupes while preserving first-seen order — the Swift equivalent of the
/// web app's `Array.from(new Set(...))`, which JS also does in insertion order.
/// Order matters here: it determines which world a multi-assigned slot's
/// daily rotation index lands on.
func orderedUnique<T: Hashable>(_ items: [T]) -> [T] {
    var seen = Set<T>()
    var result: [T] = []
    for item in items where seen.insert(item).inserted {
        result.append(item)
    }
    return result
}
