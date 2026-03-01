import planetData from "../data/planetData.json";

interface PlanetColor {
	primary: string;
	headline: string;
}

interface PlanetData {
	[key: string]: {
		planet: string;
		planetName: string;
		description: string;
		color: PlanetColor;
	};
}

const planetDataTyped: PlanetData = planetData as PlanetData;
const FALLBACK_KEY = "clear_temperate";

const WEATHER_ALIASES: Record<string, keyof PlanetData> = {
	dust: "haze",
	sand: "haze",
	ash: "smoke",
	squall: "thunderstorm",
	tornado: "thunderstorm",
};

export const getWeatherDescription = (weather: string, temp: number) => {
	const weatherCondition = weather.toLowerCase();
	const mappedCondition = WEATHER_ALIASES[weatherCondition];

	if (mappedCondition && mappedCondition in planetDataTyped) {
		return planetDataTyped[mappedCondition];
	}

	// Handle specific weather conditions
	if (weatherCondition in planetDataTyped) {
		return planetDataTyped[weatherCondition];
	}

	// Handle clear or cloudy conditions based on temperature
	if (weatherCondition === "clear" || weatherCondition === "clouds") {
		const tempF = convertKelvinToFahrenheit(temp);
		if (tempF >= 99) {
			return planetDataTyped["clear_scorching"];
		} else if (tempF >= 85) {
			return planetDataTyped["clear_hot"];
		} else if (tempF >= 76) {
			return planetDataTyped["clear_warm"];
		} else if (tempF >= 66) {
			return planetDataTyped["clear_temperate"];
		} else if (tempF >= 50) {
			return planetDataTyped["clear_cool"];
		} else if (tempF >= 41) {
			return planetDataTyped["clear_chilly"];
		} else if (tempF >= 14) {
			return planetDataTyped["clear_cold"];
		} else {
			return planetDataTyped["clear_freezing"];
		}
	}

	if (process.env.NODE_ENV !== "production") {
		console.warn(
			`Weather condition "${weatherCondition}" not found in planetData. Using fallback.`
		);
	}

	return planetDataTyped[FALLBACK_KEY];
};

const convertKelvinToFahrenheit = (kelvin: number): number => {
	return ((kelvin - 273.15) * 9) / 5 + 32;
};
