"use client";
import React, { useCallback, useEffect, useState } from "react";
import styles from "./styles/page.module.css";
import locationSearchStyles from "./styles/LocationSearch.module.css";
import planetStyles from "./styles/planetStyles.module.css";
import { fetchWeatherByCoordinates } from "./utils/fetchWeather";
import { getSlotForWeather } from "./utils/weatherDescriptions";
import LocationSearch from "./components/LocationSearch";
import WeatherDetails from "./components/WeatherDetails";
import StarChart from "./components/StarChart";
import Footer from "./components/Footer";
import { useStarChart } from "./hooks/useStarChart";
import { resolveWorld } from "@/lib/starchart/resolve";
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
  const [isWeatherLoading, setIsWeatherLoading] = useState(false);
  const [isStarChartOpen, setIsStarChartOpen] = useState(false);

  const starChart = useStarChart();

  // ── fetch + land ──────────────────────────────────────────────────────────

  const goToLocation = useCallback(
    async (lat: number, lon: number) => {
      // Do NOT clear weatherData here — keep the previous planet visible while
      // the new weather loads, which eliminates the blank-background flash.
      setAppPhase("landed");
      setPageError(null);
      setIsWeatherLoading(true);
      try {
        const data = await fetchWeatherByCoordinates(lat, lon);
        setWeatherData(data);
      } catch (error) {
        console.error("Error fetching weather:", error);
        setPageError("We couldn't load weather right now. Please try again.");
        setAppPhase("idle");
        setWeatherData(null);
      } finally {
        setIsWeatherLoading(false);
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

  // ── mount: geolocation or URL param ───────────────────────────────────────

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

    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          goToLocation(latitude, longitude);
        },
        (error) => {
          console.error("Geolocation denied:", error);
          setAppPhase("idle");
        }
      );
    } else {
      setAppPhase("idle");
    }
  }, [goToLocation, resolveInitialLocation]);

  // ─── derived display values ────────────────────────────────────────────────

  // Weather picks the slot; the Star Chart decides which world that slot shows.
  const weatherInfo = weatherData
    ? resolveWorld(
        getSlotForWeather(
          weatherData.weather[0].main,
          weatherData.main.temp
        ),
        starChart.overrides
      )
    : {
        slotId: "",
        planet: "default",
        planetName: "default",
        description: "",
        color: { primary: "#000000", headline: "#000000" },
        customized: false,
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
        <h1 className={styles.title}>Galactic Weather</h1>
        {/* Search input moves to the nav only once weather is showing */}
        {appPhase === "landed" && (
          <>
            <LocationSearch
              value={locationQuery}
              onValueChange={setLocationQuery}
              onLocationResolved={({ lat, lon, displayName }) => {
                setLocationQuery(displayName);
                goToLocation(lat, lon);
              }}
            />
            <button
              type="button"
              className={styles.starChartButton}
              onClick={() => setIsStarChartOpen(true)}
            >
              Star Chart
              {starChart.customizedCount > 0 && (
                <span className={styles.starChartCount}>
                  {starChart.customizedCount}
                </span>
              )}
            </button>
          </>
        )}
      </nav>

      {/* ── IDLE: hyperspace hero ─────────────────────────────────────────── */}
      {appPhase === "idle" && (
        <div className={styles.hyperspaceHero}>
          <div className={styles.heroContent}>
            <p className={styles.heroEyebrow}>
              Somewhere out there, it feels just like this…
            </p>
            <h2 className={styles.heroHeading}>
              Where in the galaxy are you?
            </h2>
            <p className={styles.heroSubtext}>
              Enter your location to see which world it feels like today
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
            {pageError && (
              <p className={styles.heroError} role="alert">
                {pageError}
              </p>
            )}
          </div>
        </div>
      )}

      {/* ── LANDED: weather details ───────────────────────────────────────── */}
      {appPhase === "landed" && (
        <>
          {!weatherData && !pageError && (
            <div className={styles.pageStatus} aria-live="polite">
              {isWeatherLoading ? "Loading weather…" : "Preparing forecast…"}
            </div>
          )}
          {pageError && (
            <div
              className={`${styles.pageStatus} ${styles.pageStatusError}`}
              role="alert"
            >
              {pageError}
            </div>
          )}
          <WeatherDetails weatherData={weatherData} weatherInfo={weatherInfo} />
          <Footer />
        </>
      )}

      {/* ── Star Chart overlay ────────────────────────────────────────────── */}
      {isStarChartOpen && (
        <StarChart
          overrides={starChart.overrides}
          onToggleWorld={starChart.toggleWorld}
          onResetSlot={starChart.resetSlot}
          onResetAll={starChart.resetAll}
          onClose={() => setIsStarChartOpen(false)}
        />
      )}
    </main>
  );
};

export default Home;
