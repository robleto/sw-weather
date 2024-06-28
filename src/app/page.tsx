"use client";
import React, { useState, useEffect } from "react";
import axios from "axios";
import styles from "./styles/page.module.css";
import planetStyles from "./styles/planetStyles.module.css";
import { fetchWeather } from "./utils/fetchWeather";

// Define the type for weather data
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

interface City {
	name: string;
	country: string;
}

const Home = () => {
	const [weatherData, setWeatherData] = useState<WeatherData | null>(null);
	const [city, setCity] = useState("");
	const [suggestions, setSuggestions] = useState<City[]>([]);

	async function fetchData(cityName: string) {
		try {
			const data = await fetchWeather(cityName);
			setWeatherData(data);
		} catch (error) {
			console.error("Error fetching data:", error);
		}
	}

	async function fetchCitySuggestions(cityName: string) {
		try {
			const response = await axios.get(
				`/api/city-search?city=${cityName}`
			);
			setSuggestions(response.data.list || []);
		} catch (error) {
			console.error("Error fetching city suggestions:", error);
		}
	}

	useEffect(() => {
		const cityFromQuery = new URLSearchParams(window.location.search).get(
			"city"
		);
		if (cityFromQuery) {
			setCity(cityFromQuery);
			fetchData(cityFromQuery);
		} else if ("geolocation" in navigator) {
			navigator.geolocation.getCurrentPosition(
				(position) => {
					const { latitude, longitude } = position.coords;
					fetchDataByCoordinates(latitude, longitude);
				},
				(error) => {
					console.error("Error getting geolocation:", error);
				}
			);
		}
	}, []);

	async function fetchDataByCoordinates(latitude: number, longitude: number) {
		try {
			const response = await axios.get(
				`/api/weather?lat=${latitude}&lon=${longitude}`
			);
			setWeatherData(response.data.data);
		} catch (error) {
			console.error("Error fetching data:", error);
		}
	}

	const convertKelvinToFahrenheit = (kelvin: number) => {
		return ((kelvin - 273.15) * 9) / 5 + 32;
	};

	const getWeatherDescription = (main: string, temp: number) => {
		const weatherCondition = main.toLowerCase();
		const tempF = convertKelvinToFahrenheit(temp);

		if (weatherCondition === "thunderstorm") {
			return {
				planet: "exegol",
				description:
					"Known for its perpetual, intense thunderstorms with constant heavy rain and violent storms.",
			};
		}
		if (weatherCondition === "drizzle") {
			return {
				planet: "dagobah",
				description:
					"The swampy, mist-laden planet often has a drizzly and damp atmosphere, fitting the constant light rain.",
			};
		}
		if (weatherCondition === "rain") {
			return {
				planet: "kamino",
				description:
					"A water planet that experiences frequent, heavy rainfall.",
			};
		}
		if (weatherCondition === "snow") {
			return {
				planet: "hoth",
				description:
					"The icy planet covered in ice and snow year-round, making it the perfect match for snowy conditions.",
			};
		}
		if (weatherCondition === "mist") {
			return {
				planet: "endor",
				description:
					"The forest moon often features misty conditions with dense forests and a cool, humid atmosphere.",
			};
		}
		if (weatherCondition === "smoke") {
			return {
				planet: "mustafar",
				description:
					"A volcanic planet with rivers of lava and a smoky, ash-filled atmosphere due to constant volcanic activity.",
			};
		}
		if (weatherCondition === "haze") {
			return {
				planet: "coruscant",
				description:
					"The city-planet often has a hazy atmosphere due to pollution and dense urban activity, creating a perpetual smog.",
			};
		}
		if (weatherCondition === "fog") {
			return {
				planet: "bespin",
				description:
					"Though primarily known for its clouds, the lower levels of Cloud City can be quite foggy, with thick, low-lying clouds creating fog-like conditions.",
			};
		}
		if (weatherCondition === "clear" || weatherCondition === "clouds") {
			if (tempF >= 90) {
				return {
					planet: "tatooine",
					description:
						"The desert planet with twin suns is known for its scorching heat and clear skies.",
				};
			} else if (tempF >= 76) {
				return {
					planet: "scarif",
					description:
						"This rocky, arid planet has clear skies and hot temperatures, though not as extreme as Tatooine.",
				};
			} else if (tempF >= 66) {
				return {
					planet: "naboo",
					description:
						"Known for its beautiful landscapes and pleasant, temperate climate with clear skies.",
				};
			} else if (tempF >= 50) {
				return {
					planet: "alderaan",
					description:
						"This now-destroyed planet had a diverse climate, with clear, cool conditions in many regions.",
				};
			} else if (tempF >= 32) {
				return {
					planet: "kashyyyk",
					description:
						"A diverse climate with clear, cool conditions in many regions.",
				};
			} else {
				return {
					planet: "ilum",
					description:
						"A frigid planet, often with clear skies, known for its kyber crystal caves and cold temperatures.",
				};
			}
		}
		return { planet: "default", description: main };
	};

	const weatherInfo = weatherData
		? getWeatherDescription(
				weatherData.weather[0].main,
				weatherData.main.temp
		  )
		: { planet: "default", description: "" };

	const widgetClass = planetStyles[weatherInfo.planet];

	return (
		<main className={`${styles.main} ${widgetClass}`}>
			<nav className={styles.navHeader}>
				<h1 className={styles.title}>Star Wars Weather</h1>
				<form
					className={styles.weatherLocation}
					onSubmit={(e) => {
						e.preventDefault();
						fetchData(city);
					}}
				>
					<input
						className={styles.input_field}
						placeholder="Enter a City"
						type="text"
						id="cityName"
						name="cityName"
						value={city}
						onChange={(e) => {
							setCity(e.target.value);
							if (e.target.value.length > 2) {
								fetchCitySuggestions(e.target.value);
							}
						}}
					/>
					<button className={styles.search_button} type="submit">
						Search
					</button>
					{suggestions.length > 0 && (
						<ul className={styles.suggestionsList}>
							{suggestions.map((suggestion, index) => (
								<li
									key={index}
									onClick={() => {
										setCity(
											`${suggestion.name}, ${suggestion.country}`
										);
										setSuggestions([]);
									}}
								>
									{suggestion.name}, {suggestion.country}
								</li>
							))}
						</ul>
					)}
				</form>
			</nav>
			{weatherData && (
				<section className={styles.weatherSection}>
					<div className={styles.weatherDetails}>
						<p className={styles.location}>
							Today's Forecast for {weatherData.name}
						</p>
						<h3 className={styles.tempForecast}>
							{convertKelvinToFahrenheit(
								weatherData.main.temp
							).toFixed(0)}
							°F and {weatherData.weather[0].main}
						</h3>
						<p className={styles.mightAs}>
							You might as well be on{" "}
						</p>
						<h2 className={styles.planetName}>
							{weatherInfo.planet}
						</h2>
						<p className={styles.planetDesc}>
							{" "}
							{weatherInfo.description}
						</p>
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
			)}
			<footer className={styles.footer}>
				<p className={styles.inspiredBy}>
					Inspired by the original, now defunct, Star Wars Weather{" "}
				</p>
				<div className={styles.credits}>
					Designed and developed by Greg Robleto
				</div>
			</footer>
		</main>
	);
};

export default Home;
