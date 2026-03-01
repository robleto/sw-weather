import { NextResponse } from "next/server";
import type { LocationCandidate } from "@/lib/location/types";

const OPENWEATHERMAP_API_KEY = process.env.OPENWEATHERMAP_API_KEY;
const CANDIDATE_LIMIT = 5;

interface OpenWeatherGeoResponse {
	name: string;
	lat: number;
	lon: number;
	state?: string;
	country?: string;
}

function toDisplayName(candidate: {
	name: string;
	regionOrState: string;
	country: string;
}): string {
	return [candidate.name, candidate.regionOrState, candidate.country]
		.filter(Boolean)
		.join(", ");
}

function normalizeCandidate(item: OpenWeatherGeoResponse): LocationCandidate {
	const regionOrState = item.state?.trim() ?? "";
	const country = item.country?.trim() ?? "";
	const name = item.name?.trim() ?? "";

	return {
		name,
		regionOrState,
		country,
		lat: item.lat,
		lon: item.lon,
		displayName: toDisplayName({ name, regionOrState, country }),
	};
}

function dedupeCandidates(candidates: LocationCandidate[]): LocationCandidate[] {
	const seen = new Set<string>();
	return candidates.filter((candidate) => {
		const key = `${candidate.name}:${candidate.regionOrState}:${candidate.country}:${candidate.lat}:${candidate.lon}`;
		if (seen.has(key)) {
			return false;
		}
		seen.add(key);
		return true;
	});
}

export async function GET(request: Request) {
	if (!OPENWEATHERMAP_API_KEY) {
		return NextResponse.json(
			{ error: "Server geocoding is not configured." },
			{ status: 500 }
		);
	}

	const { searchParams } = new URL(request.url);
	const query = (searchParams.get("q") ?? "").trim();

	if (!query) {
		return NextResponse.json({ error: "q is required" }, { status: 400 });
	}

	if (query.length > 120) {
		return NextResponse.json(
			{ error: "q is too long" },
			{ status: 400 }
		);
	}

	const url =
		`https://api.openweathermap.org/geo/1.0/direct?q=${encodeURIComponent(
			query
		)}` + `&limit=${CANDIDATE_LIMIT}&appid=${OPENWEATHERMAP_API_KEY}`;

	try {
		const response = await fetch(url, {
			headers: { Accept: "application/json" },
			cache: "no-store",
		});

		if (!response.ok) {
			return NextResponse.json(
				{ error: "Unable to resolve location right now." },
				{ status: 502 }
			);
		}

		const data = (await response.json()) as OpenWeatherGeoResponse[];
		const results = dedupeCandidates(
			data.map(normalizeCandidate).filter((candidate) => Boolean(candidate.name))
		);

		return NextResponse.json(
			{ candidates: results },
			{
				headers: {
					"Cache-Control": "public, max-age=300, stale-while-revalidate=600",
				},
			}
		);
	} catch {
		return NextResponse.json(
			{ error: "Unable to resolve location right now." },
			{ status: 502 }
		);
	}
}
