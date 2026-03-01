"use client";
import React, { useCallback, useEffect, useState } from "react";
import styles from "./styles/page.module.css";
import planetStyles from "./styles/planetStyles.module.css";
import { fetchWeatherByCoordinates } from "./utils/fetchWeather";
import { getWeatherDescription } from "./utils/weatherDescriptions";
import LocationSearch from "./components/LocationSearch";
import WeatherDetails from "./components/WeatherDetails";
import Footer from "./components/Footer";
import { geocodeLocation } from "@/lib/location/geocode";
import { parseLocationQuery } from "@/lib/location/parseLocationQuery";

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
  const [locationQuery, setLocationQuery] = useState("");
  const [isPageLoading, setIsPageLoading] = useState(true);
  const [pageError, setPageError] = useState<string | null>(null);

  const fetchDataByCoordinates = useCallback(async (lat: number, lon: number) => {
    setIsPageLoading(true);
    setPageError(null);

    try {
      const data = await fetchWeatherByCoordinates(lat, lon);
      setWeatherData(data);
    } catch (error) {
      console.error("Error fetching data:", error);
      setPageError("We couldn't load weather right now. Please try again.");
    } finally {
      setIsPageLoading(false);
    }
  }, []);

  const resolveInitialLocation = useCallback(async (query: string) => {
    const parsed = parseLocationQuery(query);

    if (parsed.kind === "coordinates") {
      await fetchDataByCoordinates(parsed.lat, parsed.lon);
      return;
    }

    if (parsed.kind === "geocode") {
      const candidates = await geocodeLocation(parsed.query);
      if (candidates.length > 0) {
        await fetchDataByCoordinates(candidates[0].lat, candidates[0].lon);
      }
    }
  }, [fetchDataByCoordinates]);

  useEffect(() => {
    const cityFromQuery = new URLSearchParams(window.location.search).get(
      "city"
    );
    if (cityFromQuery) {
      setLocationQuery(cityFromQuery);
      resolveInitialLocation(cityFromQuery).catch((error) => {
        console.error("Error resolving initial location:", error);
        setPageError("We couldn't resolve that location from the URL.");
        setIsPageLoading(false);
      });
    } else if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          fetchDataByCoordinates(latitude, longitude);
        },
        (error) => {
          console.error("Error getting geolocation:", error);
          setIsPageLoading(false);
          setPageError("Location access was denied. Search for a city to continue.");
        }
      );
    } else {
      setIsPageLoading(false);
      setPageError("Geolocation isn't available. Search for a city to continue.");
    }
  }, [fetchDataByCoordinates, resolveInitialLocation]);

  const weatherInfo = weatherData
		? getWeatherDescription(
				weatherData.weather[0].main,
				weatherData.main.temp
		  )
		: {
				planet: "default",
				planetName: "default",
				description: "",
				color: { primary: "#000000", headline: "#000000" },
		  };

  const widgetClass = planetStyles[weatherInfo.planet];

  return (
    <main className={`${styles.main} ${widgetClass}`}>
      <nav className={styles.navHeader}>
        <h1 className={styles.title}>Star Wars Weather</h1>
        <LocationSearch
          value={locationQuery}
          onValueChange={setLocationQuery}
          onLocationResolved={({ lat, lon, displayName }) => {
            setLocationQuery(displayName);
            fetchDataByCoordinates(lat, lon);
          }}
        />
      </nav>
      {isPageLoading && (
        <div className={styles.pageStatus} aria-live="polite">
          Loading weather…
        </div>
      )}
      {pageError && !isPageLoading && (
        <div className={`${styles.pageStatus} ${styles.pageStatusError}`} aria-live="polite">
          {pageError}
        </div>
      )}
      <WeatherDetails weatherData={weatherData} weatherInfo={weatherInfo} />
      <Footer />
    </main>
  );
};

export default Home;
