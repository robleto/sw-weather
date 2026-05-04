import React, { useState } from "react";
import Image from "next/image";
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
	const [imgError, setImgError] = useState(false);

	if (!weatherData) return null;

	const planetColors = weatherInfo.color;
	const secondaryStyle = { color: planetColors.headline, opacity: 0.78 };

	return (
		<section className={weatherStyles.weatherSection}>
			<div className={weatherStyles.weatherDetails}>
				<p
					className={weatherStyles.location}
					style={secondaryStyle}
				>
					Today&apos;s Forecast for {weatherData.name}
				</p>
				<p
					className={weatherStyles.tempForecast}
					style={{ color: planetColors.headline }}
				>
					{convertKelvinToFahrenheit(weatherData.main.temp).toFixed(0)}°F and {weatherData.weather[0].main}
				</p>
				<p
					className={weatherStyles.mightAs}
					style={secondaryStyle}
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
					style={secondaryStyle}
				>
					{weatherInfo.description}
				</p>
			</div>
			{!imgError && (
				<div className={parallaxStyles.imageContainer}>
					<Image
						src={`/planets/${weatherInfo.planet}.png`}
						alt={weatherInfo.planetName}
						fill
						sizes="100vw"
						className={parallaxStyles.planetImage}
						onError={() => setImgError(true)}
					/>
				</div>
			)}
		</section>
	);
};

export default WeatherDetails;
