import Foundation

/// The worlds a forecast can serve up on its own — every world that is some
/// slot's default.
///
/// Derived, never hand-maintained: reassigning a slot default in `Slots.swift`
/// silently changes what is findable, and this is the only thing standing
/// between that and a world nobody can ever earn.
let WILD_REACHABLE_WORLDS: Set<WorldId> = Set(SLOTS.map(\.defaultWorld))

func isWildReachable(_ worldId: WorldId) -> Bool {
    WILD_REACHABLE_WORLDS.contains(worldId)
}

enum WorldStatus {
    case wild
    case chartered
    case unfound
}

struct WorldProgress: Identifiable {
    let world: World
    let stamp: WorldStamp?
    let status: WorldStatus
    /// False for worlds only reachable by assigning them in Atlas first —
    /// which, today, is exactly the premium seven.
    let wildReachable: Bool

    var id: WorldId { world.id }

    /// The wild find is the one that counts, so it's the one the stamp shows.
    var primarySighting: Sighting? { stamp?.wild ?? stamp?.chartered }
}

struct BiomeProgress: Identifiable {
    let climate: Climate
    let worlds: [WorldProgress]
    /// Found by any means.
    let found: Int
    /// Found in the wild.
    let wild: Int
    let total: Int
    let wildTotal: Int

    var id: String { climate.rawValue }
    var label: String { climate.label }
}

/// How far along the hunt is, which decides the line under the score.
///
/// Deliberately coarse and world-agnostic. An earlier version hardcoded "Hoth
/// is easier in the hemisphere having winter" — which reads well exactly once,
/// then quietly coaches you toward a world you already have. Naming a *target*
/// is the hint system PASSPORT.md defers on purpose; naming a *strategy* is
/// onboarding, and that's all this does.
enum HuntState {
    case hunting
    case closing
    case wildComplete
    case complete
}

/// Wild worlds remaining at which the copy switches to the closing note.
private let closingThreshold = 3

func huntStateFor(wildFound: Int, wildTotal: Int, found: Int, total: Int) -> HuntState {
    if found >= total { return .complete }
    if wildFound >= wildTotal { return .wildComplete }
    if wildTotal - wildFound <= closingThreshold { return .closing }
    return .hunting
}

/// The line under the score.
///
/// Lives here rather than in the view so the iOS book and the web book can't
/// drift apart — the same reason the slot and world catalogs are shared data
/// rather than per-platform copy. Must stay word-for-word identical to
/// `blurbFor` in the web app's `src/lib/passport/progress.ts`.
func blurbFor(_ state: HuntState, wildRemaining: Int) -> String {
    switch state {
    case .hunting:
        return "A world is yours once its weather actually happens somewhere you're looking. The forecast won't come to you — search the far side of the planet, or the season you're not in."
    case .closing:
        return "\(wildRemaining) left to find in the wild. What's missing now is the difficult weather: the extremes, and the conditions that pass in an hour."
    case .wildComplete:
        return "Every world a forecast can reach is yours. The rest have to be charted — assign one in Atlas, then go and live through its weather."
    case .complete:
        return "Every world in the catalog, found. Nothing left out there."
    }
}

struct PassportProgress {
    let biomes: [BiomeProgress]
    /// Worlds found in the wild, over the number that can be. This is the
    /// scoreboard that means something — it's completable without spending.
    let wildFound: Int
    let wildTotal: Int
    /// Worlds found by any means, over the whole catalog.
    let found: Int
    let total: Int
    let state: HuntState
    /// Pre-rendered copy for `state`. See `blurbFor`.
    let blurb: String
}

func statusOf(_ stamp: WorldStamp?) -> WorldStatus {
    if stamp?.wild != nil { return .wild }
    if stamp?.chartered != nil { return .chartered }
    return .unfound
}

/// Fixed display order, the same way `SLOT_GROUP_ORDER` fixes slot groups.
/// Roughly hospitable -> hostile, so the book reads as a journey outward
/// rather than an alphabetical list. Matches the web app's `CLIMATE_ORDER`.
let CLIMATE_ORDER: [Climate] = [
    .temperate, .forest, .ocean, .desert, .ice, .volcanic, .storm, .sky, .urban,
]

func buildProgress(_ passport: Passport) -> PassportProgress {
    let biomes: [BiomeProgress] = CLIMATE_ORDER.compactMap { climate in
        let worlds = WORLDS.filter { $0.climate == climate }.map { world -> WorldProgress in
            let stamp = passport[world.id]
            return WorldProgress(
                world: world,
                stamp: stamp,
                status: statusOf(stamp),
                wildReachable: WILD_REACHABLE_WORLDS.contains(world.id)
            )
        }

        guard !worlds.isEmpty else { return nil }

        return BiomeProgress(
            climate: climate,
            worlds: worlds,
            found: worlds.filter { $0.status != .unfound }.count,
            wild: worlds.filter { $0.status == .wild }.count,
            total: worlds.count,
            wildTotal: worlds.filter(\.wildReachable).count
        )
    }

    let wildFound = biomes.reduce(0) { $0 + $1.wild }
    let wildTotal = WILD_REACHABLE_WORLDS.count
    let found = biomes.reduce(0) { $0 + $1.found }
    let total = WORLDS.count

    let state = huntStateFor(wildFound: wildFound, wildTotal: wildTotal, found: found, total: total)

    return PassportProgress(
        biomes: biomes,
        wildFound: wildFound,
        wildTotal: wildTotal,
        found: found,
        total: total,
        state: state,
        blurb: blurbFor(state, wildRemaining: wildTotal - wildFound)
    )
}

#if DEBUG
/// A non-premium world with no slot default is unreachable for everyone, wild
/// or otherwise — the Passport would show a page that can never be filled.
/// Premium worlds are expected here: they're charter-only by design.
///
/// Called once from `PassportViewModel.init`. Swift has no module-load hook,
/// so unlike the web app's module-level check this needs a call site.
func warnAboutStrandedWorlds() {
    let stranded = WORLDS.filter { !$0.isPremium && !WILD_REACHABLE_WORLDS.contains($0.id) }
    guard !stranded.isEmpty else { return }
    let names = stranded.map(\.name).joined(separator: ", ")
    let verb = stranded.count == 1 ? "is" : "are"
    let pronoun = stranded.count == 1 ? "it" : "they"
    print("[passport] \(names) \(verb) no slot's default, so \(pronoun) can never be found in the wild. Give a slot that default, or mark the world premium.")
}
#endif
