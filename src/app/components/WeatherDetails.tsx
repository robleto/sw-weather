import React from "react";
import styles from "../styles/page.module.css";
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

	return (
		<section className={styles.weatherSection}>
			<div className={styles.weatherDetails}>
				<p className={styles.location}>
					Today's Forecast for {weatherData.name}
				</p>
				<h3 className={styles.tempForecast}>
					{convertKelvinToFahrenheit(weatherData.main.temp).toFixed(
						0
					)}
					°F and {weatherData.weather[0].main}
				</h3>
				<p className={styles.mightAs}>You might as well be on</p>
				<h2 className={styles.planetName}>{weatherInfo.planet}</h2>
				<p className={styles.planetDesc}>{weatherInfo.description}</p>
			</div>
			<div className={styles.imageContainer}>
				{[...Array(10)].map((_, index) => (
					<img
						key={index}
						src=""
						alt={`${weatherInfo.planet}-${index + 1}`}
						className={`${styles.weatherImage} ${
							weatherInfo.planet
						}-${index + 1}`}
					/>
				))}
			</div>
		</section>
	);
};

export default WeatherDetails;
