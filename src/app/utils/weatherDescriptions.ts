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
	dust: "jakku",
	sand: "jakku",
	ash: "smoke",
	squall: "thunderstorm",
	tornado: "thunderstorm",
};

const convertKelvinToFahrenheit = (kelvin: number): number => {
	return ((kelvin - 273.15) * 9) / 5 + 32;
};

const getClearPlanet = (tempF: number): string => {
	if (tempF >= 99) return "clear_scorching";
	if (tempF >= 85) return "clear_hot";
	if (tempF >= 76) return "clear_warm";
	if (tempF >= 66) return "clear_temperate";
	if (tempF >= 50) return "clear_cool";
	if (tempF >= 41) return "clear_chilly";
	if (tempF >= 14) return "clear_cold";
	return "clear_freezing";
};

const getCloudsPlanet = (tempF: number): string => {
	if (tempF >= 76) return "clouds_warm";
	if (tempF >= 66) return "clouds_temperate";
	if (tempF >= 50) return "clouds_cool";
	return "clouds_cold";
};

export const getWeatherDescription = (weather: string, temp: number, description = "") => {
	const weatherCondition = weather.toLowerCase();
	const tempF = convertKelvinToFahrenheit(temp);

	// Aliases
	const mappedCondition = WEATHER_ALIASES[weatherCondition];
	if (mappedCondition && mappedCondition in planetDataTyped) {
		return planetDataTyped[mappedCondition];
	}

	// Snow — split light vs regular
	if (weatherCondition === "snow") {
		const isLight = description.toLowerCase().includes("light");
		const key = isLight ? "snow_light" : "snow";
		return planetDataTyped[key] ?? planetDataTyped["snow"];
	}

	// Clouds — temperature-based track
	if (weatherCondition === "clouds") {
		const key = getCloudsPlanet(tempF);
		return planetDataTyped[key] ?? planetDataTyped[FALLBACK_KEY];
	}

	// Clear — temperature-based track
	if (weatherCondition === "clear") {
		const key = getClearPlanet(tempF);
		return planetDataTyped[key] ?? planetDataTyped[FALLBACK_KEY];
	}

	// Direct match
	if (weatherCondition in planetDataTyped) {
		return planetDataTyped[weatherCondition];
	}

	if (process.env.NODE_ENV !== "production") {
		console.warn(`Weather condition "${weatherCondition}" not found in planetData. Using fallback.`);
	}

	return planetDataTyped[FALLBACK_KEY];
};
