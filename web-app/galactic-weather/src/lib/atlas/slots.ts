import type { Slot, SlotGroup, SlotId } from "./types";

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
	{ id: "fog", label: "Fog", group: "Atmosphere", defaultWorld: "endor" },
	{ id: "haze", label: "Haze", group: "Atmosphere", defaultWorld: "niamos" },
	{ id: "smoke", label: "Smoke & ash", group: "Atmosphere", defaultWorld: "mustafar" },
	{ id: "jakku", label: "Dust & sand", group: "Atmosphere", defaultWorld: "tatooine" },

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
	{ id: "clear_freezing", label: "Clear · freezing", group: "Clear skies", defaultWorld: "hoth" },
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

const SLOT_BY_ID = new Map<SlotId, Slot>(SLOTS.map((s) => [s.id, s]));

export const getSlot = (id: SlotId): Slot | undefined => SLOT_BY_ID.get(id);

export const FALLBACK_SLOT_ID: SlotId = "clear_temperate";
