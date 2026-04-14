"use client";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import styles from "./styles/page.module.css";
import locationSearchStyles from "./styles/LocationSearch.module.css";
import planetStyles from "./styles/planetStyles.module.css";
import { fetchWeatherByCoordinates } from "./utils/fetchWeather";
import { getWeatherDescription } from "./utils/weatherDescriptions";
import LocationSearch from "./components/LocationSearch";
import WeatherDetails from "./components/WeatherDetails";
import Footer from "./components/Footer";
import { geocodeLocation } from "@/lib/location/geocode";
import { parseLocationQuery } from "@/lib/location/parseLocationQuery";

// ─── types ────────────────────────────────────────────────────────────────────

type AppPhase = "idle" | "warping" | "landed";

interface WeatherData {
  name: string;
  main: { temp: number };
  weather: [{ main: string }];
}

// ─── constants ────────────────────────────────────────────────────────────────

const STAR_COUNT = 72;
// Minimum warp duration so the effect has time to land
const MIN_WARP_MS = 1400;

// ─── component ────────────────────────────────────────────────────────────────

const Home = () => {
  const [weatherData, setWeatherData] = useState<WeatherData | null>(null);
  const [locationQuery, setLocationQuery] = useState("");
  const [appPhase, setAppPhase] = useState<AppPhase>("idle");
  const [pageError, setPageError] = useState<string | null>(null);

  // Stable star configs — generated once, never change
  const stars = useMemo(() =>
    Array.from({ length: STAR_COUNT }, (_, i) => ({
      // Evenly distribute angles with a small random jitter for organic feel
      angle: (i / STAR_COUNT) * 360 + (Math.random() - 0.5) * 3,
      duration: 1.2 + Math.random() * 1.6,
      // Negative delay staggers starts so stars are already mid-flight on load
      delay: -(Math.random() * 3),
    })),
    []
  );

  // ── fetch + warp ──────────────────────────────────────────────────────────

  const goToLocation = useCallback(async (lat: number, lon: number) => {
    setAppPhase("warping");
    setPageError(null);

    const reducedMotion =
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    try {
      const [data] = await Promise.all([
        fetchWeatherByCoordinates(lat, lon),
        // Hold warp for minimum duration — skip for reduced motion
        reducedMotion ? Promise.resolve() : new Promise((r) => setTimeout(r, MIN_WARP_MS)),
      ]);
      setWeatherData(data as WeatherData);
      setAppPhase("landed");
    } catch (error) {
      console.error("Error fetching weather:", error);
      setPageError("We couldn't load weather right now. Please try again.");
      setAppPhase("idle");
    }
  }, []);

  // ── initial location (URL ?city= param or geolocation) ───────────────────

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

  useEffect(() => {
    const cityFromQuery = new URLSearchParams(window.location.search).get("city");

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
        ({ coords }) => goToLocation(coords.latitude, coords.longitude),
        (error) => {
          console.error("Geolocation denied:", error);
          setAppPhase("idle");
        }
      );
    } else {
      setAppPhase("idle");
    }
  }, [goToLocation, resolveInitialLocation]);

  // ─── derived values ───────────────────────────────────────────────────────

  const weatherInfo = weatherData
    ? getWeatherDescription(weatherData.weather[0].main, weatherData.main.temp)
    : {
        planet: "default",
        planetName: "default",
        description: "",
        color: { primary: "#0a0c14", headline: "#0a0c14" },
      };

  const bgClass =
    appPhase === "landed"
      ? (planetStyles[weatherInfo.planet] ?? planetStyles.default)
      : "";

  // ─── render ───────────────────────────────────────────────────────────────

  return (
    <main className={`${styles.main} ${bgClass}`} data-phase={appPhase}>

      {/* ── Fixed nav ─────────────────────────────────────────────────────── */}
      <nav className={styles.navHeader} data-phase={appPhase}>
        <h1 className={styles.title}>Star Wars Weather</h1>
        {/* Search in nav during warp + landed; hero has its own search during idle */}
        {appPhase !== "idle" && (
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

      {/* ── Hyperspace starfield — idle + warping ──────────────────────────── */}
      {appPhase !== "landed" && (
        <div className={styles.hyperspaceHero} aria-hidden="true">
          <div
            className={styles.starfield}
            data-warping={appPhase === "warping" ? "" : undefined}
          >
            {stars.map((star, i) => (
              <div
                key={i}
                className={styles.star}
                style={
                  {
                    "--angle": `${star.angle}deg`,
                    "--duration": `${star.duration}s`,
                    "--delay": `${star.delay}s`,
                  } as React.CSSProperties
                }
              />
            ))}
          </div>
        </div>
      )}

      {/* ── IDLE: hero copy + centered search ─────────────────────────────── */}
      {appPhase === "idle" && (
        <div className={styles.heroContent}>
          <p className={styles.heroEyebrow}>
            A long time ago, in a galaxy far, far away…
          </p>
          <h2 className={styles.heroHeading}>Where in the galaxy are you?</h2>
          <p className={styles.heroSubtext}>
            Enter your location to discover your Star Wars planet
          </p>
          <LocationSearch
            className={locationSearchStyles.heroSearch}
            variant="hero"
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
      )}

      {/* ── WARPING: anticipation copy ─────────────────────────────────────── */}
      {appPhase === "warping" && (
        <div className={styles.warpStatus} aria-live="polite" role="status">
          Scanning the galaxy…
        </div>
      )}

      {/* ── LANDED: weather details ────────────────────────────────────────── */}
      {appPhase === "landed" && (
        <>
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
    </main>
  );
};

export default Home;
