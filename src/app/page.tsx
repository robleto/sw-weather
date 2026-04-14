"use client";
import React, { useCallback, useEffect, useState } from "react";
import styles from "./styles/page.module.css";
import locationSearchStyles from "./styles/LocationSearch.module.css";
import planetStyles from "./styles/planetStyles.module.css";
import { fetchWeatherByCoordinates } from "./utils/fetchWeather";
import { getWeatherDescription } from "./utils/weatherDescriptions";
import LocationSearch from "./components/LocationSearch";
import WeatherDetails from "./components/WeatherDetails";
import Footer from "./components/Footer";
import HyperspaceStars from "./components/HyperspaceStars";
import { geocodeLocation } from "@/lib/location/geocode";
import { parseLocationQuery } from "@/lib/location/parseLocationQuery";

// ─── types ────────────────────────────────────────────────────────────────────

type AppPhase = "idle" | "landed";

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

// ─── component ────────────────────────────────────────────────────────────────

const Home = () => {
  const [weatherData, setWeatherData] = useState<WeatherData | null>(null);
  const [locationQuery, setLocationQuery] = useState("");
  const [appPhase, setAppPhase] = useState<AppPhase>("idle");
  const [pageError, setPageError] = useState<string | null>(null);

  // ── fetch + land ──────────────────────────────────────────────────────────

  const goToLocation = useCallback(
    async (lat: number, lon: number) => {
      setWeatherData(null);
      setAppPhase("landed");
      setPageError(null);
      try {
        const data = await fetchWeatherByCoordinates(lat, lon);
        setWeatherData(data);
      } catch (error) {
        console.error("Error fetching data:", error);
        setPageError("We couldn't load weather right now. Please try again.");
        setAppPhase("idle");
      }
    },
    []
  );

  // ── initial location (URL ?city= param) ──────────────────────────────────

  const resolveInitialLocation = useCallback(
    async (query: string) => {
      const parsed = parseLocationQuery(query);

      if (parsed.kind === "coordinates") {
        goToLocation(parsed.lat, parsed.lon);
        return;
      }

      if (parsed.kind === "geocode") {
        const candidates = await geocodeLocation(parsed.query);
        if (candidates.length > 0) {
          goToLocation(candidates[0].lat, candidates[0].lon);
        }
      }
    },
    [goToLocation]
  );

  // ── geolocation button handler ────────────────────────────────────────────

  const [isGeolocating, setIsGeolocating] = useState(false);

  const handleGeolocate = useCallback(() => {
    if (!("geolocation" in navigator)) {
      setPageError("Geolocation is not supported by your browser.");
      return;
    }
    setIsGeolocating(true);
    setPageError(null);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        setIsGeolocating(false);
        goToLocation(latitude, longitude);
      },
      (error) => {
        console.error("Geolocation denied:", error);
        setIsGeolocating(false);
        setPageError("Location access denied. Please search manually.");
      }
    );
  }, [goToLocation]);

  // ── mount: URL ?city= param, then geolocation after hero is visible ───────

  useEffect(() => {
    const cityFromQuery = new URLSearchParams(window.location.search).get(
      "city"
    );

    if (cityFromQuery) {
      setLocationQuery(cityFromQuery);
      resolveInitialLocation(cityFromQuery).catch((error) => {
        console.error("Error resolving initial location:", error);
        setPageError("We couldn't resolve that location from the URL.");
        setAppPhase("idle");
      });
      return;
    }

    // Brief delay so user sees the hyperspace hero before auto-geolocating
    const timer = setTimeout(() => {
      if ("geolocation" in navigator) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            const { latitude, longitude } = position.coords;
            goToLocation(latitude, longitude);
          },
          (error) => {
            console.error("Geolocation denied:", error);
            // Stay on idle — user can search manually or click "Use my location"
          }
        );
      }
    }, 1200);

    return () => clearTimeout(timer);
  }, [goToLocation, resolveInitialLocation]);

  // ─── derived display values ────────────────────────────────────────────────

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

  // idle → hyperspace background; landed → planet theme
  const bgClass =
    appPhase === "landed"
      ? (planetStyles[weatherInfo.planet] ?? planetStyles.default)
      : planetStyles.default;

  // ─── render ───────────────────────────────────────────────────────────────

  return (
    <main className={`${styles.main} ${bgClass}`} data-phase={appPhase}>

      {/* ── Fixed nav ─────────────────────────────────────────────────────── */}
      <nav className={styles.navHeader} data-phase={appPhase}>
        <h1 className={styles.title}>Star Wars Weather</h1>
        {/* Search input moves to the nav only once weather is showing */}
        {appPhase === "landed" && (
          <LocationSearch
            value={locationQuery}
            onValueChange={setLocationQuery}
            onLocationResolved={({ lat, lon, displayName }) => {
              setLocationQuery(displayName);
              goToLocation(lat, lon);
            }}
          />
        )}
      </nav>

      {/* ── IDLE: hyperspace hero ─────────────────────────────────────────── */}
      {appPhase === "idle" && (
        <>
        <HyperspaceStars />
        <div className={styles.hyperspaceHero}>
          <div className={styles.heroContent}>
            <p className={styles.heroEyebrow}>
              A long time ago, in a galaxy far, far away…
            </p>
            <h2 className={styles.heroHeading}>
              Where in the galaxy are you?
            </h2>
            <p className={styles.heroSubtext}>
              Enter your location to discover your Star Wars weather forecast
            </p>
            <LocationSearch
              className={locationSearchStyles.heroSearch}
              value={locationQuery}
              onValueChange={setLocationQuery}
              onLocationResolved={({ lat, lon, displayName }) => {
                setLocationQuery(displayName);
                goToLocation(lat, lon);
              }}
            />
            <button
              type="button"
              className={styles.geolocateButton}
              onClick={handleGeolocate}
              disabled={isGeolocating}
            >
              {isGeolocating ? "Locating…" : "Use my location"}
            </button>
            {pageError && (
              <p className={styles.heroError} role="alert">
                {pageError}
              </p>
            )}
          </div>
        </div>
        </>
      )}

      {/* ── LANDED: weather details ───────────────────────────────────────── */}
      {appPhase === "landed" && (
        <>
          {!weatherData && !pageError && (
            <div className={styles.pageStatus} aria-live="polite">
              Loading weather…
            </div>
          )}
          {pageError && (
            <div
              className={`${styles.pageStatus} ${styles.pageStatusError}`}
              aria-live="polite"
            >
              {pageError}
            </div>
          )}
          <WeatherDetails weatherData={weatherData} weatherInfo={weatherInfo} />
          <Footer />
        </>
      )}
    </main>
  );
};

export default Home;
