import planetData from "../data/planetData.json";

interface PlanetColor {
	primary: string;
	headline: string;
}

interface PlanetData {
	[key: string]: {
		planet: string;
		description: string;
		color: PlanetColor;
	};
}

const planetDataTyped: PlanetData = planetData as PlanetData;

export const getWeatherDescription = (weather: string, temp: number) => {
	const weatherCondition = weather.toLowerCase();
	console.log("Weather condition received from API:", weatherCondition); // Debug log

	// Handle specific weather conditions
	if (weatherCondition in planetDataTyped) {
		return planetDataTyped[weatherCondition];
	}

	// Handle clear or cloudy conditions based on temperature
	if (weatherCondition === "clear" || weatherCondition === "clouds") {
		const tempF = convertKelvinToFahrenheit(temp);
		if (tempF >= 90) {
			return planetDataTyped["clear_hot"];
		} else if (tempF >= 76) {
			return planetDataTyped["clear_warm"];
		} else if (tempF >= 66) {
			return planetDataTyped["clear_temperate"];
		} else if (tempF >= 50) {
			return planetDataTyped["clear_cool"];
		} else if (tempF >= 18) {
			return planetDataTyped["clear_cold"];
		} else {
			return planetDataTyped["clear_freezing"];
		}
	}

	console.warn(
		`Weather condition "${weatherCondition}" not found in planetData.`
	);
	return {
		planet: "unknown",
		description: "Unknown weather condition",
		color: { primary: "#000000", headline: "#000000" },
	};
};

const convertKelvinToFahrenheit = (kelvin: number): number => {
	return ((kelvin - 273.15) * 9) / 5 + 32;
};
