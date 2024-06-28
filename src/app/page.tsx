"use client";
import React, { useState, useEffect } from "react";
import styles from "./styles/page.module.css";
import planetStyles from "./styles/planetStyles.module.css";
import { fetchWeather, fetchWeatherByCoordinates } from "./utils/fetchWeather";
import { convertKelvinToFahrenheit } from "./utils/temperature";
import { getWeatherDescription } from "./utils/weatherDescriptions";
import WeatherForm from "./components/WeatherForm";
import WeatherDetails from "./components/WeatherDetails";
import Footer from "./components/Footer";

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

const Home = () => {
	const [weatherData, setWeatherData] = useState<WeatherData | null>(null);
	const [city, setCity] = useState("");

	async function fetchData(cityName: string) {
		try {
			const data = await fetchWeather(cityName);
			setWeatherData(data);
		} catch (error) {
			console.error("Error fetching data:", error);
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
					fetchWeatherByCoordinates(latitude, longitude).then(
						setWeatherData
					);
				},
				(error) => {
					console.error("Error getting geolocation:", error);
				}
			);
		}
	}, []);

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
				<WeatherForm
					city={city}
					setCity={setCity}
					fetchData={fetchData}
				/>
			</nav>
			<WeatherDetails
				weatherData={weatherData}
				weatherInfo={weatherInfo}
			/>
			<Footer />
		</main>
	);
};

export default Home;
