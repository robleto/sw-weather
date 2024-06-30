import { NextResponse } from "next/server";
import axios from "axios";

const OPENWEATHERMAP_API_KEY = process.env.NEXT_PUBLIC_OPENWEATHERMAP_API_KEY;

export async function GET(request: Request) {
	const { searchParams } = new URL(request.url);
	const address = searchParams.get("address");
	const lat = searchParams.get("lat");
	const lon = searchParams.get("lon");

	let url = `https://api.openweathermap.org/data/2.5/weather?appid=${OPENWEATHERMAP_API_KEY}`;

	if (address) {
		url += `&q=${address}`;
	} else if (lat && lon) {
		url += `&lat=${lat}&lon=${lon}`;
	} else {
		return NextResponse.json(
			{ error: "Address or coordinates are required" },
			{ status: 400 }
		);
	}

	try {
		console.log(`Requesting weather data from URL: ${url}`);
		const response = await axios.get(url);
		const data = response.data;
		return NextResponse.json({ data });
	} catch (error) {
		console.error("Error fetching weather data:", error);
		return NextResponse.json(
			{ error: "Error fetching weather data" },
			{ status: 500 }
		);
	}
}
