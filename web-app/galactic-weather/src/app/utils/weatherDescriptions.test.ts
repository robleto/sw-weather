import { describe, expect, it } from "vitest";
import { SLOTS } from "@/lib/atlas/slots";
import type { SlotId } from "@/lib/atlas/types";
import { getSlotForWeather } from "./weatherDescriptions";

/**
 * Expectations here are written out longhand rather than derived from the
 * mapper's own tables — a test that imports the table it is checking proves
 * nothing. The Swift port carries the same cases in
 * `ios-app/.../WeatherDescriptionMapperTests.swift`; the two must agree.
 */

/** The API reports Kelvin (we send no `units`), so tests speak Fahrenheit. */
const fromF = (tempF: number): number => ((tempF - 32) * 5) / 9 + 273.15;

const slotFor = (id: number, main: string, tempF = 70): SlotId =>
	getSlotForWeather({ id, main, tempKelvin: fromF(tempF) });

// ── the condition-code table ────────────────────────────────────────────────

/** Every code the mapper claims to know, and the slot it must produce. */
const CODE_TABLE: readonly (readonly [number, string, SlotId])[] = [
	// 2xx thunderstorm
	[200, "Thunderstorm", "thunderstorm"],
	[201, "Thunderstorm", "thunderstorm"],
	[202, "Thunderstorm", "thunderstorm"],
	[210, "Thunderstorm", "thunderstorm"],
	[211, "Thunderstorm", "thunderstorm"],
	[212, "Thunderstorm", "thunderstorm"],
	[221, "Thunderstorm", "thunderstorm"],
	[230, "Thunderstorm", "thunderstorm"],
	[231, "Thunderstorm", "thunderstorm"],
	[232, "Thunderstorm", "thunderstorm"],

	// 3xx drizzle
	[300, "Drizzle", "drizzle"],
	[301, "Drizzle", "drizzle"],
	[302, "Drizzle", "drizzle"],
	[310, "Drizzle", "drizzle"],
	[311, "Drizzle", "drizzle"],
	[312, "Drizzle", "drizzle"],
	[313, "Drizzle", "drizzle"],
	[314, "Drizzle", "drizzle"],
	[321, "Drizzle", "drizzle"],

	// 5xx rain — intensity splits first (only the explicitly-light codes break
	// out, matching the 6xx snow split), then temperature. Table cases run at
	// the 70°F default, i.e. the warm side of the 45°F rain boundary.
	[500, "Rain", "rain_light"],
	[501, "Rain", "rain"],
	[502, "Rain", "rain"],
	[503, "Rain", "rain"],
	[504, "Rain", "rain"],
	[520, "Rain", "rain_light"],
	[521, "Rain", "rain"],
	[522, "Rain", "rain"],
	[531, "Rain", "rain"],
	// ...except freezing rain, which is ice and must not read as a warm downpour
	[511, "Rain", "snow_light"],

	// 6xx snow
	[600, "Snow", "snow_light"],
	[601, "Snow", "snow"],
	[602, "Snow", "snow"],
	[611, "Snow", "snow_light"],
	[612, "Snow", "snow_light"],
	[613, "Snow", "snow_light"],
	[615, "Snow", "snow_light"],
	[616, "Snow", "snow_light"],
	[620, "Snow", "snow_light"],
	[621, "Snow", "snow"],
	[622, "Snow", "snow"],

	// 7xx atmosphere
	[701, "Mist", "mist"],
	[711, "Smoke", "smoke"],
	[721, "Haze", "haze"],
	[731, "Dust", "jakku"],
	[741, "Fog", "fog"],
	[751, "Sand", "jakku"],
	[761, "Dust", "jakku"],
	[762, "Ash", "smoke"],
	[771, "Squall", "thunderstorm"],
	[781, "Tornado", "thunderstorm"],
];

describe("condition code table", () => {
	it.each(CODE_TABLE)("code %i (%s) resolves to %s", (id, main, expected) => {
		expect(slotFor(id, main)).toBe(expected);
	});

	it("maps every code the OpenWeather docs define", () => {
		// Guards against a code being dropped from the mapper's table. 8xx is
		// excluded — those are temperature-dependent and covered separately.
		expect(CODE_TABLE).toHaveLength(50);
	});

	it("only produces slot ids that actually exist", () => {
		// SlotId is a bare `string`, so a typo here is otherwise invisible until
		// resolveWorld() silently falls back at runtime.
		const known = new Set(SLOTS.map((slot) => slot.id));
		for (const [, , expected] of CODE_TABLE) {
			expect(known).toContain(expected);
		}
	});
});

// ── cloud cover ─────────────────────────────────────────────────────────────

describe("cloud cover", () => {
	it("treats few clouds (11-25%) as a clear sky, not overcast", () => {
		expect(slotFor(801, "Clouds", 70)).toBe("clear_temperate");
	});

	it("sends real cloud cover down the clouds ladder", () => {
		expect(slotFor(802, "Clouds", 70)).toBe("clouds_temperate");
		expect(slotFor(803, "Clouds", 70)).toBe("clouds_temperate");
		expect(slotFor(804, "Clouds", 70)).toBe("clouds_temperate");
	});

	it("sends clear sky down the clear ladder", () => {
		expect(slotFor(800, "Clear", 70)).toBe("clear_temperate");
	});
});

// ── temperature bands ───────────────────────────────────────────────────────

/** Lower bound of each clear band, and the value one degree below it. */
const CLEAR_BANDS: readonly (readonly [number, SlotId, SlotId])[] = [
	[100, "clear_scorching", "clear_hot"],
	[90, "clear_hot", "clear_warm"],
	[79, "clear_warm", "clear_temperate"],
	[69, "clear_temperate", "clear_cool"],
	[58, "clear_cool", "clear_chilly"],
	[45, "clear_chilly", "clear_cold"],
	[32, "clear_cold", "clear_freezing"],
];

const CLOUDS_BANDS: readonly (readonly [number, SlotId, SlotId])[] = [
	[79, "clouds_warm", "clouds_temperate"],
	[69, "clouds_temperate", "clouds_cool"],
	[45, "clouds_cool", "clouds_cold"],
	[32, "clouds_cold", "clouds_freezing"],
];

describe("temperature bands", () => {
	it.each(CLEAR_BANDS)(
		"clear: %i°F is %s, one degree lower is %s",
		(boundary, atBoundary, below) => {
			expect(slotFor(800, "Clear", boundary)).toBe(atBoundary);
			expect(slotFor(800, "Clear", boundary - 1)).toBe(below);
		}
	);

	it.each(CLOUDS_BANDS)(
		"clouds: %i°F is %s, one degree lower is %s",
		(boundary, atBoundary, below) => {
			expect(slotFor(804, "Clouds", boundary)).toBe(atBoundary);
			expect(slotFor(804, "Clouds", boundary - 1)).toBe(below);
		}
	);

	it("has no gap at the extremes", () => {
		expect(slotFor(800, "Clear", 140)).toBe("clear_scorching");
		expect(slotFor(800, "Clear", -60)).toBe("clear_freezing");
		expect(slotFor(804, "Clouds", 140)).toBe("clouds_warm");
		expect(slotFor(804, "Clouds", -60)).toBe("clouds_freezing");
	});

	it("keeps the clouds ladder a strict coarsening of the clear one", () => {
		// Every clouds boundary must also be a clear boundary, or the two
		// ladders start disagreeing about where "cool" ends.
		const clearBoundaries = new Set(CLEAR_BANDS.map(([boundary]) => boundary));
		for (const [boundary] of CLOUDS_BANDS) {
			expect(clearBoundaries).toContain(boundary);
		}
	});

	it("bands on the rounded temperature the readout shows", () => {
		// 78.6°F displays as "79°F", so it must land in the 79–89 band and not
		// in the one the UI labels 69–78.
		expect(slotFor(800, "Clear", 78.6)).toBe("clear_warm");
		expect(slotFor(800, "Clear", 78.4)).toBe("clear_temperate");
		expect(slotFor(804, "Clouds", 44.5)).toBe("clouds_cool");
		expect(slotFor(804, "Clouds", 44.4)).toBe("clouds_cold");
	});

	it("is stable at boundaries despite Kelvin conversion error", () => {
		// 69, 79 and 100°F all convert to Kelvin and back a hair light; without
		// rounding each would fall one band short of where the hint says.
		for (const [tempF, expected] of [
			[69, "clear_temperate"],
			[79, "clear_warm"],
			[100, "clear_scorching"],
		] as const) {
			expect(slotFor(800, "Clear", tempF)).toBe(expected);
		}
	});

	it("splits rain cold from warm at 45°F", () => {
		expect(slotFor(501, "Rain", 45)).toBe("rain");
		expect(slotFor(501, "Rain", 44)).toBe("rain_cold");
		expect(slotFor(500, "Rain", 45)).toBe("rain_light");
		expect(slotFor(500, "Rain", 44)).toBe("rain_light_cold");
		// The case that motivated the split: a near-freezing downpour must not
		// land on Kamino's warm tropical rain.
		expect(slotFor(502, "Rain", 34)).toBe("rain_cold");
		expect(slotFor(502, "Rain", 88)).toBe("rain");
	});

	it("reuses the 45°F boundary the other ladders already use", () => {
		const clearBoundaries = new Set(CLEAR_BANDS.map(([boundary]) => boundary));
		expect(clearBoundaries).toContain(45);
	});

	it("still ignores temperature for snow and thunderstorm", () => {
		// Phase already implies the temperature, so these stay unbanded.
		for (const tempF of [10, 30, 34]) {
			expect(slotFor(601, "Snow", tempF)).toBe("snow");
		}
		for (const tempF of [40, 70, 95]) {
			expect(slotFor(211, "Thunderstorm", tempF)).toBe("thunderstorm");
		}
	});
});

// ── fallbacks ───────────────────────────────────────────────────────────────

describe("unrecognized codes", () => {
	it("degrades an unknown code to its OpenWeather group", () => {
		expect(slotFor(299, "Thunderstorm")).toBe("thunderstorm");
		expect(slotFor(399, "Drizzle")).toBe("drizzle");
		expect(slotFor(599, "Rain")).toBe("rain");  // 70°F default -> warm side
		expect(slotFor(699, "Snow")).toBe("snow");
		expect(slotFor(799, "Mist")).toBe("mist");
	});

	it("degrades an unknown 8xx code to the clouds ladder", () => {
		expect(slotFor(805, "Clouds", 40)).toBe("clouds_cold");
	});

	it("falls back to the main string when the code is meaningless", () => {
		expect(slotFor(0, "Clear", 70)).toBe("clear_temperate");
		expect(slotFor(0, "Clouds", 40)).toBe("clouds_cold");
		expect(slotFor(0, "Snow", 30)).toBe("snow");
		expect(slotFor(0, "Rain", 40)).toBe("rain_cold");
		expect(slotFor(0, "Tornado", 70)).toBe("thunderstorm");
	});

	it("falls back to the default slot when nothing matches", () => {
		expect(slotFor(0, "Sharknado", 70)).toBe("clear_temperate");
	});

	it("survives a missing code without throwing", () => {
		const slot = getSlotForWeather({
			id: undefined as unknown as number,
			main: "Rain",
			tempKelvin: fromF(60),
		});
		expect(slot).toBe("rain");
	});
});

// ── every main string the API can send ──────────────────────────────────────

describe("main-string coverage", () => {
	const ALL_MAINS = [
		"Thunderstorm",
		"Drizzle",
		"Rain",
		"Snow",
		"Mist",
		"Smoke",
		"Haze",
		"Dust",
		"Fog",
		"Sand",
		"Ash",
		"Squall",
		"Tornado",
		"Clear",
		"Clouds",
	];

	it.each(ALL_MAINS)("%s resolves to a real slot without a code", (main) => {
		const known = new Set(SLOTS.map((slot) => slot.id));
		expect(known).toContain(slotFor(0, main, 70));
	});
});
