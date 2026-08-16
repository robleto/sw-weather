import { FALLBACK_SLOT_ID, getSlot } from "@/lib/weathertwins/slots";
import type { SlotId } from "@/lib/weathertwins/types";

/**
 * Maps an OpenWeather condition + temperature to a Weather Twins slot id.
 *
 * This deliberately stops at the slot. Which *world* a slot displays is a
 * separate question owned by Weather Twins (see lib/weathertwins/resolve.ts),
 * because the user can reassign it.
 */

const WEATHER_ALIASES: Record<string, SlotId> = {
	dust: "jakku",
	sand: "jakku",
	ash: "smoke",
	squall: "thunderstorm",
	tornado: "thunderstorm",
};

export const convertKelvinToFahrenheit = (kelvin: number): number =>
	((kelvin - 273.15) * 9) / 5 + 32;

const clearSlotForTemp = (tempF: number): SlotId => {
	if (tempF >= 99) return "clear_scorching";
	if (tempF >= 85) return "clear_hot";
	if (tempF >= 76) return "clear_warm";
	if (tempF >= 66) return "clear_temperate";
	if (tempF >= 50) return "clear_cool";
	if (tempF >= 41) return "clear_chilly";
	if (tempF >= 14) return "clear_cold";
	return "clear_freezing";
};

const cloudsSlotForTemp = (tempF: number): SlotId => {
	if (tempF >= 76) return "clouds_warm";
	if (tempF >= 66) return "clouds_temperate";
	if (tempF >= 50) return "clouds_cool";
	return "clouds_cold";
};

export const getSlotForWeather = (
	weather: string,
	temp: number,
	description = ""
): SlotId => {
	const condition = weather.toLowerCase();
	const tempF = convertKelvinToFahrenheit(temp);

	const aliased = WEATHER_ALIASES[condition];
	if (aliased && getSlot(aliased)) return aliased;

	if (condition === "snow") {
		return description.toLowerCase().includes("light") ? "snow_light" : "snow";
	}

	if (condition === "clouds") return cloudsSlotForTemp(tempF);
	if (condition === "clear") return clearSlotForTemp(tempF);

	if (getSlot(condition)) return condition;

	if (process.env.NODE_ENV !== "production") {
		console.warn(
			`Weather condition "${condition}" has no Weather Twins slot. Using fallback.`
		);
	}

	return FALLBACK_SLOT_ID;
};
