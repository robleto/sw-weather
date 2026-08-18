import { describe, expect, it } from "vitest";
import { candidateFlag, candidateSecondaryText } from "./candidateDisplay";
import type { LocationCandidate } from "./types";

const candidate = (
	overrides: Partial<LocationCandidate> = {}
): LocationCandidate => ({
	name: "Cape Town",
	regionOrState: "Western Cape",
	country: "ZA",
	lat: -33.92,
	lon: 18.42,
	displayName: "Cape Town, Western Cape, ZA",
	...overrides,
});

describe("candidateFlag", () => {
	it("maps an ISO alpha-2 code to its regional indicator pair", () => {
		// U+1F1FF U+1F1E6 — the two letters offset into the indicator block,
		// not a shipped image.
		expect(candidateFlag(candidate())).toBe("\u{1F1FF}\u{1F1E6}");
	});

	it("accepts lowercase codes", () => {
		expect(candidateFlag(candidate({ country: "za" }))).toBe(
			candidateFlag(candidate({ country: "ZA" }))
		);
	});

	it("returns null for the synthetic lat,lon candidate, which has no country", () => {
		expect(candidateFlag(candidate({ country: "" }))).toBeNull();
	});

	it("returns null rather than mojibake for codes that aren't two ASCII letters", () => {
		// Guards the arithmetic: anything outside A–Z would offset to an
		// unrelated codepoint instead of a flag.
		for (const country of ["USA", "Z", "Z1", "ß-", "  "]) {
			expect(candidateFlag(candidate({ country }))).toBeNull();
		}
	});
});

describe("candidateSecondaryText", () => {
	it("spells the country out rather than leaving the code to be decoded", () => {
		expect(candidateSecondaryText(candidate())).toBe(
			"Western Cape, South Africa"
		);
	});

	it("omits an empty region instead of leaving a dangling separator", () => {
		expect(candidateSecondaryText(candidate({ regionOrState: "" }))).toBe(
			"South Africa"
		);
	});

	it("is empty for a candidate with neither, so no blank line is rendered", () => {
		expect(
			candidateSecondaryText(candidate({ regionOrState: "", country: "" }))
		).toBe("");
	});

	it("falls back to the raw code when the code is malformed", () => {
		// `Intl.DisplayNames.of` throws a RangeError on anything that isn't a
		// well-formed region subtag. The catch is what keeps one bad geocode
		// row from taking the whole dropdown down.
		expect(
			candidateSecondaryText(candidate({ regionOrState: "", country: "Z1" }))
		).toBe("Z1");
	});

	it("passes through a well-formed but unassigned code", () => {
		// "QQ" is structurally valid and simply has no name, so `of` hands the
		// code straight back — no throw, nothing to fall back to.
		expect(
			candidateSecondaryText(candidate({ regionOrState: "", country: "QQ" }))
		).toBe("QQ");
	});
});
