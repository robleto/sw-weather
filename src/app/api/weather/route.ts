import { NextResponse } from "next/server";

const OPENWEATHERMAP_API_KEY = process.env.OPENWEATHERMAP_API_KEY;

function isValidLatitude(value: number): boolean {
	return Number.isFinite(value) && value >= -90 && value <= 90;
}

function isValidLongitude(value: number): boolean {
	return Number.isFinite(value) && value >= -180 && value <= 180;
}

export async function GET(request: Request) {
	if (!OPENWEATHERMAP_API_KEY) {
		return NextResponse.json(
			{ error: "Weather service is not configured." },
			{ status: 500 }
		);
	}

	const { searchParams } = new URL(request.url);
	const address = searchParams.get("address")?.trim();
	const lat = searchParams.get("lat");
	const lon = searchParams.get("lon");

	let url = `https://api.openweathermap.org/data/2.5/weather?appid=${OPENWEATHERMAP_API_KEY}`;

	if (address) {
		url += `&q=${address}`;
	} else if (lat && lon) {
		const latNum = Number(lat);
		const lonNum = Number(lon);

		if (!isValidLatitude(latNum) || !isValidLongitude(lonNum)) {
			return NextResponse.json(
				{ error: "Invalid coordinates." },
				{ status: 400 }
			);
		}

		url += `&lat=${lat}&lon=${lon}`;
	} else {
		return NextResponse.json(
			{ error: "Address or coordinates are required" },
			{ status: 400 }
		);
	}

	try {
		const response = await fetch(url, {
			headers: { Accept: "application/json" },
			cache: "no-store",
		});

		if (!response.ok) {
			if (response.status === 404) {
				return NextResponse.json(
					{ error: "Location not found." },
					{ status: 404 }
				);
			}

			return NextResponse.json(
				{ error: "Error fetching weather data" },
				{ status: 502 }
			);
		}

		const data = await response.json();
		return NextResponse.json(
			{ data },
			{
				headers: {
					"Cache-Control": "public, max-age=120, stale-while-revalidate=300",
				},
			}
		);
	} catch (error) {
		console.error("Error fetching weather data:", error);
		return NextResponse.json(
			{ error: "Error fetching weather data" },
			{ status: 502 }
		);
	}
}
