interface WeatherData {
	name: string;
	main: {
		temp: number;
	};
	weather: [
		{
			main: string;
			description: string;
		}
	];
}

export async function fetchWeatherByCoordinates(
	latitude: number,
	longitude: number
): Promise<WeatherData> {
	const response = await fetch(`/api/weather?lat=${latitude}&lon=${longitude}`);
	if (!response.ok) {
		throw new Error(`Weather request failed (${response.status})`);
	}

	const payload = (await response.json()) as { data: WeatherData };
	return payload.data;
}
