import planetDescriptions from "../data/planetDescriptions.json";
import { convertKelvinToFahrenheit } from "./temperature";

interface WeatherDescription {
	planet: string;
	description: string;
}

export const getWeatherDescription = (
	main: string,
	temp: number
): WeatherDescription => {
	const weatherCondition = main.toLowerCase();
	const tempF = convertKelvinToFahrenheit(temp);

	if (weatherCondition === "thunderstorm")
		return planetDescriptions.thunderstorm;
	if (weatherCondition === "drizzle") return planetDescriptions.drizzle;
	if (weatherCondition === "rain") return planetDescriptions.rain;
	if (weatherCondition === "snow") return planetDescriptions.snow;
	if (weatherCondition === "mist") return planetDescriptions.mist;
	if (weatherCondition === "smoke") return planetDescriptions.smoke;
	if (weatherCondition === "haze") return planetDescriptions.haze;
	if (weatherCondition === "fog") return planetDescriptions.fog;
	if (weatherCondition === "clear" || weatherCondition === "clouds") {
		if (tempF >= 90) return planetDescriptions.clear_hot;
		if (tempF >= 76) return planetDescriptions.clear_warm;
		if (tempF >= 66) return planetDescriptions.clear_temperate;
		if (tempF >= 50) return planetDescriptions.clear_cool;
		return planetDescriptions.clear_cold;
	}
	return { planet: "default", description: main };
};
