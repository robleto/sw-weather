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

export async function fetchWeather(cityName: string): Promise<WeatherData> {
	const response = await axios.get(`/api/weather?address=${cityName}`);
	return response.data.data as WeatherData;
}

export async function fetchWeatherByCoordinates(
	latitude: number,
	longitude: number
): Promise<WeatherData> {
	const response = await axios.get(
		`/api/weather?lat=${latitude}&lon=${longitude}`
	);
	return response.data.data as WeatherData;
}
