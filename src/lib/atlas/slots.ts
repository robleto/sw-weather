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
	{ id: "rain", label: "Rain", group: "Precipitation", defaultWorld: "kamino" },
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
	{ id: "clouds_warm", label: "Cloudy · warm", group: "Cloud cover", defaultWorld: "bespin" },
	{ id: "clouds_temperate", label: "Cloudy · mild", group: "Cloud cover", defaultWorld: "bespin" },
	{ id: "clouds_cool", label: "Cloudy · cool", group: "Cloud cover", defaultWorld: "bespin" },
	{ id: "clouds_cold", label: "Cloudy · cold", group: "Cloud cover", defaultWorld: "bespin" },

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
	{ id: "clear_cool", label: "Clear · cool", group: "Clear skies", defaultWorld: "naboo" },
	{ id: "clear_chilly", label: "Clear · chilly", group: "Clear skies", defaultWorld: "kashyyyk" },
	{
		id: "clear_cold",
		label: "Clear · cold",
		group: "Clear skies",
		defaultWorld: "hoth",
		defaultDescription: "A frozen wasteland of biting cold and clear, pale skies.",
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
	clouds_warm: "76°F and up",
	clouds_temperate: "66–75°F",
	clouds_cool: "50–65°F",
	clouds_cold: "below 50°F",
	clear_scorching: "99°F and up",
	clear_hot: "85–98°F",
	clear_warm: "76–84°F",
	clear_temperate: "66–75°F",
	clear_cool: "50–65°F",
	clear_chilly: "41–49°F",
	clear_cold: "14–40°F",
	clear_freezing: "below 14°F",
};

const SLOT_BY_ID = new Map<SlotId, Slot>(SLOTS.map((s) => [s.id, s]));

export const getSlot = (id: SlotId): Slot | undefined => SLOT_BY_ID.get(id);

export const FALLBACK_SLOT_ID: SlotId = "clear_temperate";
