/** A world's asset id — must match /public/planets/<id>.png. */
export type WorldId = string;

/** Coarse climate grouping, used as the filter axis in the planet picker. */
export type Climate =
	| "desert"
	| "ice"
	| "ocean"
	| "forest"
	| "volcanic"
	| "urban"
	| "temperate"
	| "storm"
	| "sky";

export interface WorldColor {
	primary: string;
	headline: string;
}

export interface World {
	id: WorldId;
	name: string;
	description: string;
	climate: Climate;
	color: WorldColor;
}

/** A weather bucket the app can land in. One slot resolves to one world. */
export type SlotId = string;

/** Slots are grouped purely for display in Weather Twins. */
export type SlotGroup = "Precipitation" | "Cloud cover" | "Clear skies" | "Atmosphere";

export interface Slot {
	id: SlotId;
	/** Human label shown in Weather Twins, e.g. "Heavy snow". */
	label: string;
	group: SlotGroup;
	/** The world used when the user has not customized this slot. */
	defaultWorld: WorldId;
	/**
	 * Slot-specific copy that reads better than the world's canonical
	 * description in this context. Only applies while the slot is at its
	 * default world — a user-assigned world always uses its own description.
	 */
	defaultDescription?: string;
}

/**
 * User customizations, keyed by slot. A slot may hold several worlds; when it
 * does, one is chosen per resolution so the surprise of the free experience
 * survives customization.
 */
export type WeatherTwinsOverrides = Record<SlotId, WorldId[]>;

/** A fully resolved slot, ready to render. */
export interface ResolvedWorld {
	slotId: SlotId;
	planet: WorldId;
	planetName: string;
	description: string;
	color: WorldColor;
	/** True when this slot is showing something other than its default. */
	customized: boolean;
}
