import type { ParsedLocationQuery } from "./types";

const LAT_LON_REGEX =
	/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/;

function normalizeWhitespace(value: string): string {
	return value.trim().replace(/\s+/g, " ");
}

function normalizeCommaSpacing(value: string): string {
	return value.replace(/\s*,\s*/g, ",").trim();
}

export function normalizeLocationQuery(value: string): string {
	return normalizeCommaSpacing(normalizeWhitespace(value)).toLowerCase();
}

export function parseLocationQuery(rawQuery: string): ParsedLocationQuery {
	const trimmed = normalizeWhitespace(rawQuery);

	if (!trimmed) {
		return { kind: "empty" };
	}

	const latLonMatch = trimmed.match(LAT_LON_REGEX);
	if (latLonMatch) {
		const lat = Number(latLonMatch[1]);
		const lon = Number(latLonMatch[2]);

		if (
			Number.isFinite(lat) &&
			Number.isFinite(lon) &&
			lat >= -90 &&
			lat <= 90 &&
			lon >= -180 &&
			lon <= 180
		) {
			return {
				kind: "coordinates",
				lat,
				lon,
				normalizedQuery: normalizeLocationQuery(trimmed),
			};
		}
	}

	return {
		kind: "geocode",
		query: normalizeCommaSpacing(trimmed),
		normalizedQuery: normalizeLocationQuery(trimmed),
	};
}
