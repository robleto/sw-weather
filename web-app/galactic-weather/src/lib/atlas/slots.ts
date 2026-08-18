import type { Slot, SlotGroup, SlotId, WorldId } from "./types";

/**
 * Every weather bucket the app can land in, with the world it uses by default.
 *
 * These defaults reproduce the original planetData.json mapping exactly.
 * `defaultDescription` is set only where the original slot copy read better
 * than the world's canonical description; a user-assigned world always brings
 * its own description with it.
 */
export const SLOTS: readonly Slot[] = [
	// ── Precipitation ──────────────────────────────────────────────────────
	{ id: "thunderstorm", label: "Thunderstorm", group: "Precipitation", defaultWorld: "exegol" },
	{ id: "drizzle", label: "Drizzle", group: "Precipitation", defaultWorld: "dagobah" },
	{ id: "rain", label: "Heavy rain", group: "Precipitation", defaultWorld: "kamino" },
	{ id: "rain_cold", label: "Heavy rain · cold", group: "Precipitation", defaultWorld: "daiyu" },
	{ id: "rain_light", label: "Light rain", group: "Precipitation", defaultWorld: "dagobah" },
	{
		id: "rain_light_cold",
		label: "Light rain · cold",
		group: "Precipitation",
		defaultWorld: "kashyyyk",
		defaultDescription:
			"A brisk, chilly drizzle filtering down through towering canopies.",
	},
	{
		id: "snow",
		label: "Heavy snow",
		group: "Precipitation",
		defaultWorld: "hoth",
		defaultDescription:
			"The icy planet covered in ice and snow year-round, making it the perfect match for heavy snow.",
	},
	{ id: "snow_light", label: "Light snow", group: "Precipitation", defaultWorld: "kijimi" },

	// ── Atmosphere ─────────────────────────────────────────────────────────
	{ id: "mist", label: "Mist", group: "Atmosphere", defaultWorld: "endor" },
	{ id: "fog", label: "Fog", group: "Atmosphere", defaultWorld: "mandalore" },
	{ id: "haze", label: "Haze", group: "Atmosphere", defaultWorld: "corellia" },
	{ id: "smoke", label: "Smoke & ash", group: "Atmosphere", defaultWorld: "kessel" },
	{ id: "dust", label: "Dust & sand", group: "Atmosphere", defaultWorld: "tatooine" },

	// ── Cloud cover ────────────────────────────────────────────────────────
	{ id: "clouds_warm", label: "Cloudy · warm", group: "Cloud cover", defaultWorld: "at-attin" },
	{ id: "clouds_temperate", label: "Cloudy · mild", group: "Cloud cover", defaultWorld: "yavin" },
	{ id: "clouds_cool", label: "Cloudy · cool", group: "Cloud cover", defaultWorld: "ghorman" },
	{ id: "clouds_cold", label: "Cloudy · cold", group: "Cloud cover", defaultWorld: "bespin" },
	{
		id: "clouds_freezing",
		label: "Cloudy · freezing",
		group: "Cloud cover",
		defaultWorld: "kijimi",
		// Kijimi's canonical copy mentions falling snow, which is wrong here —
		// this is the overcast-and-freezing slot, not a precipitation one.
		defaultDescription:
			"A cold mountain world of ancient streets beneath low, freezing cloud.",
	},

	// ── Clear skies ────────────────────────────────────────────────────────
	{
		id: "clear_scorching",
		label: "Clear · scorching",
		group: "Clear skies",
		defaultWorld: "mustafar",
		defaultDescription: "An extremely hot volcanic world with blistering heat and fiery terrain.",
	},
	{
		id: "clear_hot",
		label: "Clear · hot",
		group: "Clear skies",
		defaultWorld: "tatooine",
		defaultDescription:
			"The desert planet with twin suns is known for its scorching heat and clear skies.",
	},
	{ id: "clear_warm", label: "Clear · warm", group: "Clear skies", defaultWorld: "scarif" },
	{ id: "clear_temperate", label: "Clear · mild", group: "Clear skies", defaultWorld: "naboo" },
	{ id: "clear_cool", label: "Clear · cool", group: "Clear skies", defaultWorld: "dantooine" },
	{ id: "clear_chilly", label: "Clear · chilly", group: "Clear skies", defaultWorld: "kashyyyk" },
	{
		id: "clear_cold",
		label: "Clear · cold",
		group: "Clear skies",
		defaultWorld: "hoth",
		defaultDescription:
			"An icy world at its calmest — crisp, cold air beneath clear, pale skies.",
	},
	{ id: "clear_freezing", label: "Clear · freezing", group: "Clear skies", defaultWorld: "ilum" },
] as const;

export const SLOT_GROUP_ORDER: readonly SlotGroup[] = [
	"Clear skies",
	"Cloud cover",
	"Precipitation",
	"Atmosphere",
];

/** Temperature bands shown as secondary text next to a slot label. */
export const SLOT_RANGE_HINT: Readonly<Record<SlotId, string>> = {
	rain: "45°F and up",
	rain_cold: "below 45°F",
	rain_light: "45°F and up",
	rain_light_cold: "below 45°F",
	clouds_warm: "79°F and up",
	clouds_temperate: "69–78°F",
	clouds_cool: "45–68°F",
	clouds_cold: "32–44°F",
	clouds_freezing: "below 32°F",
	clear_scorching: "100°F and up",
	clear_hot: "90–99°F",
	clear_warm: "79–89°F",
	clear_temperate: "69–78°F",
	clear_cool: "58–68°F",
	clear_chilly: "45–57°F",
	clear_cold: "32–44°F",
	clear_freezing: "below 32°F",
};

/**
 * Where on Earth to go looking for each condition.
 *
 * The Passport's difficulty was never a function of how many worlds exist — it
 * comes from physics. `clear_temperate` happens everywhere; `clear_scorching`
 * needs 100°F *and* a clear sky, which in January is a short list of places.
 * Without a nudge that asymmetry is invisible, and an unfound world reads as a
 * checklist row rather than something huntable.
 *
 * Deliberately geographic and seasonal rather than numeric: `SLOT_RANGE_HINT`
 * already carries the temperature band, and repeating it here would say nothing
 * the label doesn't. These name places.
 *
 * Kept as a map beside the range hints rather than a field on `Slot`, for the
 * same reason that one is: it is display copy, not part of resolution, and
 * nothing in the mapping logic should be able to read it.
 *
 * Duplicated in the iOS `Slots.swift`. Divergence here is cosmetic — unlike the
 * weather→slot mapping, prose drifting between platforms produces a slightly
 * different sentence, not a wrong answer, which is why this has no shared
 * fixture.
 */
export const SLOT_HUNT_HINT: Readonly<Record<SlotId, string>> = {
	thunderstorm: "Somewhere is always storming — the tropics, or inland on a summer afternoon.",
	drizzle: "Maritime coasts and mild winters — Britain, the Pacific Northwest.",
	rain: "Monsoon belts, or a warm front parked over a coast.",
	rain_cold: "Late autumn in the north — the Great Lakes, the Baltic.",
	rain_light: "Common and forgiving. Most temperate coasts will do.",
	rain_light_cold: "A raw drizzle in shoulder season — the North Atlantic.",
	snow: "Winter at altitude or high latitude — the Alps, the Rockies, Hokkaido.",
	snow_light: "The edges of winter, or a cold snap anywhere temperate.",
	mist: "River valleys at dawn, and mild coasts just after rain.",
	fog: "Cool water beside warm land — San Francisco, Newfoundland, the North Sea.",
	haze: "Humid summer air over a large city.",
	smoke: "Rare and grim: downwind of a wildfire, in fire season.",
	dust: "Desert margins in spring — the Sahel, Mongolia, inland Australia.",
	clouds_warm: "An overcast tropic — the Gulf Coast, Southeast Asia.",
	clouds_temperate: "The default weather of half the temperate world.",
	clouds_cool: "Northern Europe, most of the year.",
	clouds_cold: "A grey winter day inland — above freezing, but not by much.",
	clouds_freezing: "Overcast and below freezing — continental interiors in deep winter.",
	clear_scorching: "Desert interiors at midsummer — Arabia, the Sahara, Death Valley.",
	clear_hot: "A cloudless summer afternoon in the subtropics.",
	clear_warm: "Mediterranean summer, or the tropics in dry season.",
	clear_temperate: "The easiest stamp in the book — a fine spring day almost anywhere.",
	clear_cool: "Clear and crisp — temperate spring and autumn.",
	clear_chilly: "A bright, cold morning in early spring.",
	clear_cold: "Clear winter sun with frost still on the ground.",
	clear_freezing: "A clear winter night inland — Siberia, the Prairies, high Asia.",
};

/** What a Passport entry needs to say about how to find a world in the wild. */
export interface WorldHunt {
	/** Every condition this world is the default for, in slot order. */
	slotLabels: readonly string[];
	/** Temperature band for the first of those conditions, when it has one. */
	range?: string;
	/** Where to go looking. */
	hint?: string;
}

/**
 * How to find `worldId` without assigning it first.
 *
 * Derived from the slot table rather than authored per world, so it cannot fall
 * out of step with the defaults — five worlds cover two conditions each, and a
 * hand-written list would have to be revisited every time a default moved.
 *
 * Returns undefined for a world no slot defaults to. Those are the 22 premium
 * alternates, which no forecast leads to and which the Passport already covers
 * with its own copy.
 */
export const huntForWorld = (worldId: WorldId): WorldHunt | undefined => {
	const owning = SLOTS.filter((s) => s.defaultWorld === worldId);
	if (owning.length === 0) return undefined;
	return {
		slotLabels: owning.map((s) => s.label),
		range: SLOT_RANGE_HINT[owning[0].id],
		hint: SLOT_HUNT_HINT[owning[0].id],
	};
};

/**
 * Slot ids that have been renamed, old id → current id.
 *
 * Slot ids are not just internal labels: they key stored Atlas assignments and
 * are recorded on every Passport stamp, so renaming one orphans real data.
 * Both storage layers drop entries whose slot they don't recognize, which would
 * turn a rename into a silent reset of that slot's assignment.
 *
 * `dust` was `jakku` — a franchise world name where every other slot is generic
 * weather vocabulary. That mattered once analytics started sending slot ids
 * precisely *because* they're generic; see `shared/analytics-signals.json`.
 *
 * This map can go once no stored data predates the rename. Given nobody has
 * shipped or installed a build carrying the old id beyond the developer's own
 * devices, that is a short list — but "short" isn't "empty", and the cost of
 * keeping it is three lines.
 */
export const RENAMED_SLOT_IDS: Readonly<Record<string, SlotId>> = {
	jakku: "dust",
};

/** The current id for a possibly-historical one. Unknown ids pass through. */
export const canonicalSlotId = (id: string): SlotId => RENAMED_SLOT_IDS[id] ?? id;

const SLOT_BY_ID = new Map<SlotId, Slot>(SLOTS.map((s) => [s.id, s]));

export const getSlot = (id: SlotId): Slot | undefined => SLOT_BY_ID.get(id);

export const FALLBACK_SLOT_ID: SlotId = "clear_temperate";
