import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { SLOTS } from "@/lib/atlas/slots";
import type { SlotId } from "@/lib/atlas/types";
import { getSlotForWeather } from "./weatherDescriptions";

/**
 * Cross-platform parity.
 *
 * `shared/weather-slot-matrix.json` is the agreed behavior of the weather →
 * slot mapping, as a condition-code × temperature grid. This suite asserts the
 * web mapper matches it; `WeatherDescriptionMapperTests.swift` asserts the same
 * of the iOS port against the same file. Neither platform can drift without
 * going red.
 *
 * Regenerate with `npm run matrix` after an intentional behavior change, and
 * review the diff — it names exactly which weather now resolves differently.
 */

interface SlotMatrix {
	probeTemperaturesF: number[];
	matrix: Record<string, SlotId[]>;
}

const FIXTURE = join(
	__dirname,
	"..",
	"..",
	"..",
	"..",
	"..",
	"shared",
	"weather-slot-matrix.json"
);

const fixture = JSON.parse(readFileSync(FIXTURE, "utf8")) as SlotMatrix;
const { probeTemperaturesF: TEMPS, matrix } = fixture;

const toKelvin = (tempF: number): number => ((tempF - 32) * 5) / 9 + 273.15;

/** Mirrors the generator: `main` is only exercised on the fallback path. */
const mainForCode = (code: number): string => {
	if (code >= 800) return code === 800 ? "Clear" : "Clouds";
	return (
		{ 2: "Thunderstorm", 3: "Drizzle", 5: "Rain", 6: "Snow", 7: "Mist" }[
			Math.floor(code / 100)
		] ?? "Clear"
	);
};

describe("slot matrix fixture", () => {
	it("is loaded and non-trivial", () => {
		// A fixture that silently failed to load would make every case below
		// pass vacuously.
		expect(TEMPS.length).toBeGreaterThan(0);
		expect(Object.keys(matrix).length).toBe(55);
		for (const row of Object.values(matrix)) {
			expect(row).toHaveLength(TEMPS.length);
		}
	});

	it("only names slots that exist", () => {
		const known = new Set(SLOTS.map((slot) => slot.id));
		for (const [code, row] of Object.entries(matrix)) {
			for (const slot of row) {
				expect(known, `code ${code}`).toContain(slot);
			}
		}
	});

	it("reaches every declared slot", () => {
		// If a slot is unreachable the mapper can never produce it, which means
		// it is dead weight in Atlas.
		const reached = new Set(Object.values(matrix).flat());
		const declared = SLOTS.map((slot) => slot.id);
		expect([...declared].filter((slot) => !reached.has(slot))).toEqual([]);
	});

	it("probes every band boundary", () => {
		// Each cutoff must appear as a probe, or a change to it could slip
		// through without moving a single cell.
		for (const boundary of [32, 45, 58, 69, 79, 90, 100]) {
			expect(TEMPS).toContain(boundary);
			expect(TEMPS).toContain(boundary - 1);
		}
	});
});

describe("web mapper matches the shared matrix", () => {
	const cases = Object.entries(matrix).flatMap(([code, row]) =>
		row.map((expected, i) => ({
			code: Number(code),
			tempF: TEMPS[i],
			expected,
		}))
	);

	it(`agrees on all ${cases.length} condition × temperature cells`, () => {
		const drift: string[] = [];
		for (const { code, tempF, expected } of cases) {
			const actual = getSlotForWeather({
				id: code,
				main: mainForCode(code),
				tempKelvin: toKelvin(tempF),
			});
			if (actual !== expected) {
				drift.push(`code ${code} at ${tempF}°F: expected ${expected}, got ${actual}`);
			}
		}
		expect(drift).toEqual([]);
	});
});
