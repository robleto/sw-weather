import React from "react";
import weatherStyles from "../styles/WeatherDetails.module.css";
import parallaxStyles from "../styles/Parallax.module.css";
import { convertKelvinToFahrenheit } from "../utils/temperature";

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

interface PlanetColor {
	primary: string;
	headline: string;
}

interface WeatherDetailsProps {
	weatherData: WeatherData | null;
	weatherInfo: {
		planet: string;
		planetName: string;
		description: string;
		color: PlanetColor;
	};
}

const WeatherDetails: React.FC<WeatherDetailsProps> = ({
	weatherData,
	weatherInfo,
}) => {
	if (!weatherData) return null;

	const planetColors = weatherInfo.color;

	return (
		<section className={weatherStyles.weatherSection}>
			<div className={weatherStyles.weatherDetails}>
				<p
					className={weatherStyles.location}
					style={{ color: planetColors.primary }}
				>
					Today's Forecast for {weatherData.name}
				</p>
				<h3
					className={weatherStyles.tempForecast}
					style={{ color: planetColors.headline }}
				>
					{convertKelvinToFahrenheit(weatherData.main.temp).toFixed(
						0
					)}
					°F and {weatherData.weather[0].main}
				</h3>
				<p
					className={weatherStyles.mightAs}
					style={{ color: planetColors.primary }}
				>
					{weatherData.name} feels like being on
				</p>
				<h2
					className={weatherStyles.planetName}
					style={{ color: planetColors.headline }}
				>
					{weatherInfo.planetName}
				</h2>
				<p
					className={weatherStyles.planetDesc}
					style={{ color: planetColors.primary }}
				>
					{weatherInfo.description}
				</p>
			</div>
			<div className={parallaxStyles.imageContainer}>
				{[...Array(6)].map((_, index) => (
					<div
						key={index}
						className={`${parallaxStyles.parallaxLayer} ${
							parallaxStyles[`layer${index}`]
						}`}
					>
						<img
							src={`/images/${weatherInfo.planet}/${
								weatherInfo.planet
							}-${index + 1}.svg`}
							alt={`${weatherInfo.planet}-${index + 1}`}
							className={`${parallaxStyles.weatherImage}`}
						/>
					</div>
				))}
			</div>
		</section>
	);
};

export default WeatherDetails;
