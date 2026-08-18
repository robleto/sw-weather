import type { LocationCandidate } from "./types";

/**
 * The two derived strings a candidate row shows beyond its raw fields.
 *
 * Ports `LocationCandidate.flag` and `.secondaryText` from
 * `ios-app/.../Models/LocationCandidate.swift`, which are computed properties
 * on the same six fields the geocode API already returns — so this needs no
 * change to `/api/geocode` and no new payload. Kept here rather than inlined in
 * the component because the Swift side is a model concern too, and the pair
 * should be findable together when one of them changes.
 */

/**
 * The country's flag, built from its ISO 3166 alpha-2 code rather than shipped
 * as artwork: offsetting each ASCII letter into the Unicode regional indicator
 * block (U+1F1E6…) produces the emoji the platform already has a glyph for. No
 * assets, no network, no licensing, and it stays correct as flags change.
 *
 * `null` for anything that isn't a two-letter code — notably the synthetic
 * candidate built for a raw `lat,lon` query, which has no country at all.
 */
export function candidateFlag(candidate: LocationCandidate): string | null {
	const code = candidate.country.toUpperCase();
	if (!/^[A-Z]{2}$/.test(code)) {
		return null;
	}
	// Indexed rather than spread: the project compiles without
	// `downlevelIteration`, and the regex above already guarantees exactly two
	// characters, so there is nothing to iterate over.
	const BASE = 0x1f1e6;
	return String.fromCodePoint(
		BASE + code.charCodeAt(0) - 65,
		BASE + code.charCodeAt(1) - 65
	);
}

/**
 * The line under the city name: region plus the country spelled out.
 * "Western Cape, South Africa" tells you where you're about to go in a way
 * "Western Cape, ZA" makes you decode.
 *
 * `Intl.DisplayNames` is the counterpart to iOS's
 * `Locale.current.localizedString(forRegionCode:)`. It throws on codes it can't
 * parse, so an unrecognized country falls back to the raw code rather than
 * taking the dropdown down with it.
 */
export function candidateSecondaryText(candidate: LocationCandidate): string {
	let countryName = candidate.country;
	if (candidate.country) {
		try {
			countryName =
				new Intl.DisplayNames(undefined, { type: "region" }).of(
					candidate.country
				) ?? candidate.country;
		} catch {
			countryName = candidate.country;
		}
	}
	return [candidate.regionOrState, countryName].filter(Boolean).join(", ");
}
