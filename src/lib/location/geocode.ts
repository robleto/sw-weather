import { normalizeLocationQuery, parseLocationQuery } from "./parseLocationQuery";
import type { LocationCandidate } from "./types";

const CACHE_PREFIX = "sw-weather:geocode:v1:";
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

interface GeocodeApiResponse {
	candidates: LocationCandidate[];
}

interface CachedGeocode {
	timestamp: number;
	results: LocationCandidate[];
}

function getCacheKey(normalizedQuery: string): string {
	return `${CACHE_PREFIX}${normalizedQuery}`;
}

function readCachedGeocode(normalizedQuery: string): LocationCandidate[] | null {
	if (typeof window === "undefined") {
		return null;
	}

	const raw = window.localStorage.getItem(getCacheKey(normalizedQuery));
	if (!raw) {
		return null;
	}

	try {
		const parsed = JSON.parse(raw) as CachedGeocode;
		if (Date.now() - parsed.timestamp > CACHE_TTL_MS) {
			window.localStorage.removeItem(getCacheKey(normalizedQuery));
			return null;
		}
		return parsed.results;
	} catch {
		window.localStorage.removeItem(getCacheKey(normalizedQuery));
		return null;
	}
}

function writeCachedGeocode(
	normalizedQuery: string,
	results: LocationCandidate[]
): void {
	if (typeof window === "undefined") {
		return;
	}

	const payload: CachedGeocode = {
		timestamp: Date.now(),
		results,
	};

	window.localStorage.setItem(getCacheKey(normalizedQuery), JSON.stringify(payload));
}

export async function geocodeLocation(query: string): Promise<LocationCandidate[]> {
	const parsed = parseLocationQuery(query);
	if (parsed.kind !== "geocode") {
		return [];
	}

	const normalizedQuery = normalizeLocationQuery(parsed.query);
	const cached = readCachedGeocode(normalizedQuery);
	if (cached) {
		return cached;
	}

	const url = `/api/geocode?q=${encodeURIComponent(parsed.query)}`;

	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(`Geocoding request failed (${response.status})`);
	}

	const data = (await response.json()) as GeocodeApiResponse;
	const results = data.candidates ?? [];

	writeCachedGeocode(normalizedQuery, results);
	return results;
}
