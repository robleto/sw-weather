import axios from "axios";

interface WeatherData {
	name: string;
	main: {
		temp: number;
	};
	weather: [
		{
			main: string;
		}
	];
}

const BASE_URL =
	process.env.NODE_ENV === "production"
		? "https://your-production-url.com"
		: "http://localhost:3000";

export async function fetchWeather(cityName: string): Promise<WeatherData> {
	const response = await axios.get(
		`${BASE_URL}/api/weather?address=${cityName}`
	);
	return response.data.data as WeatherData;
}

export async function fetchWeatherByCoordinates(
	latitude: number,
	longitude: number
): Promise<WeatherData> {
	const response = await axios.get(
		`${BASE_URL}/api/weather?lat=${latitude}&lon=${longitude}`
	);
	return response.data.data as WeatherData;
}
