import React, { useState } from "react";
import Image from "next/image";
import weatherStyles from "../styles/WeatherDetails.module.css";
import parallaxStyles from "../styles/Parallax.module.css";
import { convertKelvinToFahrenheit } from "../utils/temperature";
import { planetImageSrc } from "@/lib/atlas/worlds";

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
		/** Measured against this world's art — see TextTone in atlas/types. */
		textColor: string;
	};
}

const WeatherDetails: React.FC<WeatherDetailsProps> = ({
	weatherData,
	weatherInfo,
}) => {
	const [imgError, setImgError] = useState(false);

	if (!weatherData) return null;

	// This text sits directly on the planet photo, so it uses the world's
	// measured textColor rather than `headline` — see TextTone in atlas/types.
	const textColor = weatherInfo.textColor;
	const secondaryStyle = { color: textColor, opacity: 0.78 };

	return (
		<section className={weatherStyles.weatherSection}>
			<div className={weatherStyles.weatherDetails}>
				<p
					className={weatherStyles.location}
					style={secondaryStyle}
				>
					Today&apos;s Forecast for
				</p>
				<p
					className={weatherStyles.city}
					style={{ color: textColor }}
				>
					{weatherData.name}
				</p>
				<p
					className={weatherStyles.tempForecast}
					style={{ color: textColor }}
				>
					{convertKelvinToFahrenheit(weatherData.main.temp).toFixed(0)}°F and {weatherData.weather[0].main}
				</p>
				{/* Just "feels like being on" now — with the city on its own
				    line above, naming it again a few lines later read as a
				    stutter rather than a callback. */}
				<p
					className={weatherStyles.feelsLike}
					style={secondaryStyle}
				>
					feels like being on
				</p>
				<h2
					className={weatherStyles.planetName}
					style={{ color: textColor }}
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
						src={planetImageSrc(weatherInfo.planet)}
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
