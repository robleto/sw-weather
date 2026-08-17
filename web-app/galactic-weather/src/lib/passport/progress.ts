import { SLOTS } from "@/lib/atlas/slots";
import { CLIMATE_LABELS, CLIMATE_ORDER, WORLDS } from "@/lib/atlas/worlds";
import type { Climate, World, WorldId } from "@/lib/atlas/types";
import type { Passport, WorldStamp } from "./types";

/**
 * The worlds a forecast can serve up on its own — every world that is some
 * slot's default.
 *
 * Derived, never hand-maintained: reassigning a slot default in slots.ts
 * silently changes what is findable, and this is the only thing standing
 * between that and a world nobody can ever earn.
 */
export const WILD_REACHABLE_WORLDS: ReadonlySet<WorldId> = new Set(
	SLOTS.map((slot) => slot.defaultWorld)
);

export const isWildReachable = (worldId: WorldId): boolean =>
	WILD_REACHABLE_WORLDS.has(worldId);

if (process.env.NODE_ENV !== "production") {
	// A non-premium world with no slot default is unreachable for everyone,
	// wild or otherwise — the Passport would show a page that can never be
	// filled. Premium worlds are expected here: they're charter-only by design.
	const stranded = WORLDS.filter((w) => !w.isPremium && !WILD_REACHABLE_WORLDS.has(w.id));
	if (stranded.length > 0) {
		console.warn(
			`[passport] ${stranded.map((w) => w.name).join(", ")} ${
				stranded.length === 1 ? "is" : "are"
			} no slot's default, so ${
				stranded.length === 1 ? "it" : "they"
			} can never be found in the wild. Give a slot that default, or mark the world premium.`
		);
	}
}

export type WorldStatus = "wild" | "chartered" | "unfound";

export interface WorldProgress {
	world: World;
	stamp?: WorldStamp;
	status: WorldStatus;
	/** False for worlds only reachable by assigning them in Atlas first. */
	wildReachable: boolean;
}

export interface BiomeProgress {
	climate: Climate;
	label: string;
	worlds: WorldProgress[];
	/** Found by any means. */
	found: number;
	/** Found in the wild. */
	wild: number;
	total: number;
	wildTotal: number;
}

/**
 * How far along the hunt is, which decides the line under the score.
 *
 * Deliberately coarse and world-agnostic. An earlier version hardcoded "Hoth
 * is easier in the hemisphere having winter" — which reads well exactly once,
 * then quietly coaches you toward a world you already have. Naming a *target*
 * is the hint system PASSPORT.md defers on purpose; naming a *strategy* is
 * onboarding, and that's all this does.
 */
export type HuntState = "hunting" | "closing" | "wildComplete" | "complete";

/** Wild worlds remaining at which the copy switches to the closing note. */
const CLOSING_THRESHOLD = 3;

export const huntStateFor = (
	wildFound: number,
	wildTotal: number,
	found: number,
	total: number
): HuntState => {
	if (found >= total) return "complete";
	if (wildFound >= wildTotal) return "wildComplete";
	if (wildTotal - wildFound <= CLOSING_THRESHOLD) return "closing";
	return "hunting";
};

/**
 * The line under the score.
 *
 * Lives here rather than in the component so the web book and the iOS book
 * can't drift apart — the same reason the slot and world catalogs are shared
 * data rather than per-platform copy.
 */
export const blurbFor = (state: HuntState, wildRemaining: number): string => {
	switch (state) {
		case "hunting":
			return "A world is yours once its weather actually happens somewhere you're looking. The forecast won't come to you — search the far side of the planet, or the season you're not in.";
		case "closing":
			return `${wildRemaining} left to find in the wild. What's missing now is the difficult weather: the extremes, and the conditions that pass in an hour.`;
		case "wildComplete":
			return "Every world a forecast can reach is yours. The rest have to be charted — assign one in Atlas, then go and live through its weather.";
		case "complete":
			return "Every world in the catalog, found. Nothing left out there.";
	}
};

export interface PassportProgress {
	biomes: BiomeProgress[];
	/** Worlds found in the wild, over the number that can be. This is the
	 *  scoreboard that means something — it's completable without spending. */
	wildFound: number;
	wildTotal: number;
	/** Worlds found by any means, over the whole catalog. */
	found: number;
	total: number;
	state: HuntState;
	/** Pre-rendered copy for `state`. See `blurbFor`. */
	blurb: string;
}

export const statusOf = (stamp: WorldStamp | undefined): WorldStatus => {
	if (stamp?.wild) return "wild";
	if (stamp?.chartered) return "chartered";
	return "unfound";
};

export const buildProgress = (passport: Passport): PassportProgress => {
	const biomes: BiomeProgress[] = CLIMATE_ORDER.map((climate) => {
		const worlds: WorldProgress[] = WORLDS.filter((w) => w.climate === climate).map(
			(world) => {
				const stamp = passport[world.id];
				return {
					world,
					stamp,
					status: statusOf(stamp),
					wildReachable: WILD_REACHABLE_WORLDS.has(world.id),
				};
			}
		);

		return {
			climate,
			label: CLIMATE_LABELS[climate],
			worlds,
			found: worlds.filter((w) => w.status !== "unfound").length,
			wild: worlds.filter((w) => w.status === "wild").length,
			total: worlds.length,
			wildTotal: worlds.filter((w) => w.wildReachable).length,
		};
	}).filter((biome) => biome.total > 0);

	const wildFound = biomes.reduce((sum, b) => sum + b.wild, 0);
	const wildTotal = WILD_REACHABLE_WORLDS.size;
	const found = biomes.reduce((sum, b) => sum + b.found, 0);
	const total = WORLDS.length;

	const state = huntStateFor(wildFound, wildTotal, found, total);

	return {
		biomes,
		wildFound,
		wildTotal,
		found,
		total,
		state,
		blurb: blurbFor(state, wildTotal - wildFound),
	};
};
