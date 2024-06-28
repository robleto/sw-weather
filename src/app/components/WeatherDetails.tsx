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

interface WeatherDetailsProps {
	weatherData: WeatherData | null;
	weatherInfo: {
		planet: string;
		description: string;
	};
}

const WeatherDetails: React.FC<WeatherDetailsProps> = ({
	weatherData,
	weatherInfo,
}) => {
	if (!weatherData) return null;

	const planet = weatherInfo.planet;

	return (
		<section className={weatherStyles.weatherSection}>
			<div className={weatherStyles.weatherDetails}>
				<p className={weatherStyles.location}>
					Today's Forecast for {weatherData.name}
				</p>
				<h3 className={weatherStyles.tempForecast}>
					{convertKelvinToFahrenheit(weatherData.main.temp).toFixed(
						0
					)}
					°F and {weatherData.weather[0].main}
				</h3>
				<p className={weatherStyles.mightAs}>You might as well be on</p>
				<h2 className={weatherStyles.planetName}>
					{weatherInfo.planet}
				</h2>
				<p className={weatherStyles.planetDesc}>
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
							src={`/images/${planet}/${planet}-${index + 1}.svg`}
							alt={`${planet}-${index + 1}`}
							className={`${parallaxStyles.weatherImage}`}
						/>
					</div>
				))}
			</div>
		</section>
	);
};

export default WeatherDetails;
