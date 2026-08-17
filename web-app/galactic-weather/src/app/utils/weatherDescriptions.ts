import { FALLBACK_SLOT_ID, getSlot } from "@/lib/atlas/slots";
import type { SlotId } from "@/lib/atlas/types";

/**
 * Maps an OpenWeather condition to an Atlas slot id.
 *
 * `weather[0].id` — the numeric condition code — is the primary signal. It is
 * the only field that separates sleet from heavy snow, freezing rain from a
 * warm downpour, and a few passing clouds from full overcast; `weather[0].main`
 * collapses all of those together. `main` is kept purely as a fallback for
 * codes we don't recognize.
 *
 * This deliberately stops at the slot. Which *world* a slot displays is a
 * separate question owned by Atlas (see lib/atlas/resolve.ts),
 * because the user can reassign it.
 */

/**
 * The condition fields this mapping needs, passed as one object so a caller
 * can't quietly omit the code and silently fall back to the coarse path.
 */
export interface WeatherCondition {
	/** OpenWeather `weather[0].id`. */
	id: number;
	/** OpenWeather `weather[0].main`. Only consulted for unrecognized codes. */
	main: string;
	/** Temperature in Kelvin — the API default, since we send no `units`. */
	tempKelvin: number;
}

/** Which temperature ladder a temperature-dependent code feeds into. */
type TempLadder = "clear" | "clouds" | "rain" | "rainLight";

/**
 * Condition codes that resolve to a slot outright, with no temperature input.
 *
 * Grouped by slot rather than by OpenWeather group so the non-obvious
 * placements stay visible — see the comments on snow_light in particular.
 */
const SLOT_CODES: readonly (readonly [SlotId, readonly number[]])[] = [
	// 2xx thunderstorm, plus squalls (771) and tornado (781), which the old
	// string aliases already folded in here.
	["thunderstorm", [200, 201, 202, 210, 211, 212, 221, 230, 231, 232, 771, 781]],

	// 3xx drizzle.
	["drizzle", [300, 301, 302, 310, 311, 312, 313, 314, 321]],

	// 5xx rain is temperature-dependent and lives in LADDER_CODES below.

	// 6xx snow, heavy end. Snow is not temperature-banded: the phase already
	// tells you it is near freezing, so a band would add nothing.
	["snow", [601, 602, 621, 622]],

	// 6xx snow, light end — plus sleet (611–613) and rain/snow mixes (615, 616),
	// which used to land on "Heavy snow", and freezing rain (511), which used to
	// land on Kamino's warm downpour despite being ice on the ground.
	["snow_light", [511, 600, 611, 612, 613, 615, 616, 620]],

	// 7xx atmosphere.
	["mist", [701]],
	["smoke", [711, 762]],
	["haze", [721]],
	["fog", [741]],
	["jakku", [731, 751, 761]],
];

const SLOT_BY_CODE = new Map<number, SlotId>(
	SLOT_CODES.flatMap(([slot, codes]) =>
		codes.map((code) => [code, slot] as [number, SlotId])
	)
);

/** Condition codes whose slot depends on temperature as well as condition. */
const LADDER_CODES: readonly (readonly [TempLadder, readonly number[]])[] = [
	// The 800 group encodes cloud cover as a percentage band. 801 is 11–25% —
	// a sunny day with some clouds in it — so it takes the clear ladder instead
	// of being flattened into overcast alongside 804.
	["clear", [800, 801]],
	["clouds", [802, 803, 804]],

	// 5xx rain, split cold from warm: a 35°F downpour has nothing in common
	// with a warm tropical one. Intensity splits first (the plain and moderate
	// variants sit with the heavy ones, matching how snow is split), then each
	// side splits again on temperature. Freezing rain (511) is absent on
	// purpose — it resolves straight to snow_light.
	["rain", [501, 502, 503, 504, 521, 522, 531]],
	["rainLight", [500, 520]],
];

const LADDER_BY_CODE = new Map<number, TempLadder>(
	LADDER_CODES.flatMap(([ladder, codes]) =>
		codes.map((code) => [code, ladder] as [number, TempLadder])
	)
);

const WEATHER_ALIASES: Record<string, SlotId> = {
	dust: "jakku",
	sand: "jakku",
	ash: "smoke",
	squall: "thunderstorm",
	tornado: "thunderstorm",
};

export const convertKelvinToFahrenheit = (kelvin: number): number =>
	((kelvin - 273.15) * 9) / 5 + 32;

/**
 * Bands are quoted to the user in whole degrees ("69–78°F"), and the readout
 * rounds too, so classification rounds first. Otherwise a true 75.6°F displays
 * as "76°F" while landing in the band the UI labels 69–78. Rounding also keeps
 * exact boundaries off the edge of Kelvin→Fahrenheit float error.
 */
const roundedF = (tempF: number): number => Math.floor(tempF + 0.5);

/**
 * The clear ladder. Anchored on the two temperatures that mean something
 * outside this app — freezing at 32°F and the century mark at 100°F — and
 * cut into 10–13°F steps in between, rather than the old 9–27°F spread that
 * buried 32°F in the middle of a band called "cold".
 */
const clearSlotForTemp = (temp: number): SlotId => {
	const tempF = roundedF(temp);
	if (tempF >= 100) return "clear_scorching";
	if (tempF >= 90) return "clear_hot";
	if (tempF >= 79) return "clear_warm";
	if (tempF >= 69) return "clear_temperate";
	if (tempF >= 58) return "clear_cool";
	if (tempF >= 45) return "clear_chilly";
	if (tempF >= 32) return "clear_cold";
	return "clear_freezing";
};

/**
 * The clouds ladder is a strict coarsening of the clear one — every boundary
 * here is also a clear boundary, so the two can never disagree about where
 * "cool" ends:
 *
 *   clouds_freezing  = clear_freezing                             (below 32)
 *   clouds_cold      = clear_cold                                 (32–44)
 *   clouds_cool      = clear_chilly   + clear_cool                (45–68)
 *   clouds_temperate = clear_temperate                            (69–78)
 *   clouds_warm      = clear_warm + clear_hot + clear_scorching   (79 and up)
 */
const cloudsSlotForTemp = (temp: number): SlotId => {
	const tempF = roundedF(temp);
	if (tempF >= 79) return "clouds_warm";
	if (tempF >= 69) return "clouds_temperate";
	if (tempF >= 45) return "clouds_cool";
	if (tempF >= 32) return "clouds_cold";
	return "clouds_freezing";
};

/**
 * Rain splits cold from warm at 45°F — an existing boundary on both the clear
 * and clouds ladders, so all three agree on where "cold" starts. Two bands
 * rather than the full ladder because liquid rain can only occur across a
 * narrow slice of it, and a slot that can never fire is just clutter in Atlas.
 */
const rainSlotForTemp = (temp: number): SlotId =>
	roundedF(temp) >= 45 ? "rain" : "rain_cold";

const rainLightSlotForTemp = (temp: number): SlotId =>
	roundedF(temp) >= 45 ? "rain_light" : "rain_light_cold";

const slotForLadder = (ladder: TempLadder, tempF: number): SlotId => {
	switch (ladder) {
		case "clear":
			return clearSlotForTemp(tempF);
		case "clouds":
			return cloudsSlotForTemp(tempF);
		case "rain":
			return rainSlotForTemp(tempF);
		case "rainLight":
			return rainLightSlotForTemp(tempF);
	}
};

/** Resolve by numeric condition code. Undefined means "code not recognized". */
const slotForCode = (code: number, tempF: number): SlotId | undefined => {
	const direct = SLOT_BY_CODE.get(code);
	if (direct) return direct;

	const ladder = LADDER_BY_CODE.get(code);
	if (ladder) return slotForLadder(ladder, tempF);

	// An unknown code is still informative: OpenWeather groups by leading digit,
	// so a code added after this table was written degrades to its group.
	switch (Math.floor(code / 100)) {
		case 2:
			return "thunderstorm";
		case 3:
			return "drizzle";
		case 5:
			return rainSlotForTemp(tempF);
		case 6:
			return "snow";
		case 7:
			return "mist";
		case 8:
			return cloudsSlotForTemp(tempF);
		default:
			return undefined;
	}
};

/** Fallback path: resolve from the coarse `main` string. */
const slotForConditionName = (main: string, tempF: number): SlotId => {
	const condition = main.toLowerCase();

	const aliased = WEATHER_ALIASES[condition];
	if (aliased && getSlot(aliased)) return aliased;

	if (condition === "clouds") return cloudsSlotForTemp(tempF);
	if (condition === "clear") return clearSlotForTemp(tempF);
	// `main` carries no intensity, so an unrecognized rain code takes the heavy
	// ladder — same reasoning as the 5xx group fallback above.
	if (condition === "rain") return rainSlotForTemp(tempF);

	if (getSlot(condition)) return condition;

	if (process.env.NODE_ENV !== "production") {
		console.warn(
			`Weather condition "${condition}" has no Atlas slot. Using fallback.`
		);
	}

	return FALLBACK_SLOT_ID;
};

export const getSlotForWeather = ({
	id,
	main,
	tempKelvin,
}: WeatherCondition): SlotId => {
	const tempF = convertKelvinToFahrenheit(tempKelvin);

	if (Number.isFinite(id)) {
		const fromCode = slotForCode(id, tempF);
		if (fromCode) return fromCode;
	}

	return slotForConditionName(main, tempF);
};
