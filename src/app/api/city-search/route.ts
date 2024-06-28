import { NextResponse } from "next/server";
import axios from "axios";

const OPENWEATHERMAP_API_KEY = process.env.NEXT_PUBLIC_OPENWEATHERMAP_API_KEY;

export async function GET(request: Request) {
	const { searchParams } = new URL(request.url);
	const city = searchParams.get("city");

	if (!city) {
		return NextResponse.json(
			{ error: "City query parameter is required" },
			{ status: 400 }
		);
	}

	const url = `http://api.openweathermap.org/data/2.5/find?q=${city}&type=like&sort=population&cnt=5&appid=${OPENWEATHERMAP_API_KEY}`;

	try {
		const response = await axios.get(url);
		const data = response.data;
		return NextResponse.json(data);
	} catch (error) {
		console.error(error);
		return NextResponse.json(
			{ error: "Error fetching city suggestions" },
			{ status: 500 }
		);
	}
}
