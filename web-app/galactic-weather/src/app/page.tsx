"use client";
import React, { useCallback, useEffect, useState } from "react";
import Image from "next/image";
import styles from "./styles/page.module.css";
import locationSearchStyles from "./styles/LocationSearch.module.css";
import planetStyles from "./styles/planetStyles.module.css";
import { fetchWeatherByCoordinates } from "./utils/fetchWeather";
import { getSlotForWeather } from "./utils/weatherDescriptions";
import LocationSearch from "./components/LocationSearch";
import WeatherDetails from "./components/WeatherDetails";
import Atlas from "./components/Atlas";
import Passport from "./components/Passport";
import Footer from "./components/Footer";
import { GlobeIcon, SealCheckIcon } from "./components/NavIcons";
import { useAtlas } from "./hooks/useAtlas";
import { usePassport, useStampOnDwell } from "./hooks/usePassport";
import { resolveWorld } from "@/lib/atlas/resolve";
import { convertKelvinToFahrenheit } from "./utils/temperature";
import { geocodeLocation } from "@/lib/location/geocode";
import { parseLocationQuery } from "@/lib/location/parseLocationQuery";
import { startAnalytics, track } from "@/lib/analytics/analytics";
import {
  SIGNALS,
  atlasWorldAssignedPayload,
  forecastLandedPayload,
} from "@/lib/analytics/signals";
import { planetImageSrc } from "@/lib/atlas/worlds";

// ─── types ────────────────────────────────────────────────────────────────────

type AppPhase = "idle" | "landed";

interface WeatherData {
  name: string;
  main: {
    temp: number;
  };
  weather: [
    {
      id: number;
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
  const [isAtlasOpen, setIsAtlasOpen] = useState(false);
  const [isPassportOpen, setIsPassportOpen] = useState(false);

  const atlas = useAtlas();
  const passport = usePassport();

  // Assigning is the Atlas signal that matters — opening it is curiosity,
  // picking a world is intent. The current assignment is read before toggling
  // so the signal can say which direction it went.
  const handleToggleWorld = useCallback(
    (slotId: string, worldId: string) => {
      const wasAssigned = (atlas.overrides[slotId] ?? []).includes(worldId);
      atlas.toggleWorld(slotId, worldId);
      track(
        SIGNALS.atlasWorldAssigned,
        atlasWorldAssignedPayload(slotId, wasAssigned ? "unassign" : "assign")
      );
    },
    [atlas.overrides, atlas.toggleWorld]
  );

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
        // Fired here rather than from a render effect so it marks one
        // successful fetch, not every re-render that happens to be landed.
        track(
          SIGNALS.forecastLanded,
          forecastLandedPayload(
            getSlotForWeather({
              id: data.weather[0].id,
              main: data.weather[0].main,
              tempKelvin: data.main.temp,
            })
          )
        );
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

  // ── mount: analytics ──────────────────────────────────────────────────────

  // Does nothing at all unless NEXT_PUBLIC_TELEMETRYDECK_APP_ID is set, so
  // local development and anyone who clones this send nothing.
  useEffect(() => {
    void startAnalytics();
    track(SIGNALS.appLaunched);
  }, []);

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

  // Weather picks the slot; Atlas decides which world that slot shows.
  const weatherInfo = weatherData
    ? resolveWorld(
        getSlotForWeather({
          id: weatherData.weather[0].id,
          main: weatherData.weather[0].main,
          tempKelvin: weatherData.main.temp,
        }),
        atlas.overrides
      )
    : {
        slotId: "",
        planet: "default",
        planetName: "default",
        description: "",
        color: { primary: "#000000", headline: "#000000" },
        textTone: "light" as const,
        textColor: "#FAFAFA",
        customized: false,
      };

  // Landing on a world stamps it in the Passport, once it's held still for a
  // moment. Held back until the passport has hydrated — stamping against the
  // empty initial state would write over the stored book.
  useStampOnDwell(
    passport.record,
    appPhase === "landed" && weatherData && passport.hydrated
      ? {
          resolved: weatherInfo,
          city: weatherData.name,
          tempF: convertKelvinToFahrenheit(weatherData.main.temp),
        }
      : null
  );

  // idle → hyperspace background; landed → planet theme
  const bgClass =
    appPhase === "landed"
      ? (planetStyles[weatherInfo.planet] ?? planetStyles.default)
      : planetStyles.default;

  // ─── render ───────────────────────────────────────────────────────────────

  return (
    <main className={`${styles.main} ${bgClass}`} data-phase={appPhase}>

      {/* ── Planet photo, the same backdrop iOS draws ──────────────────────── */}
      {appPhase === "landed" && weatherInfo.planet !== "default" && (
        <div className={styles.backdrop} aria-hidden="true">
          <Image
            src={planetImageSrc(weatherInfo.planet)}
            alt=""
            fill
            priority
            sizes="100vw"
            className={styles.backdropImage}
          />
        </div>
      )}

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
            <div className={styles.navActions}>
              <button
                type="button"
                className={styles.navAction}
                onClick={() => {
                  setIsAtlasOpen(true);
                  track(SIGNALS.atlasOpened);
                }}
              >
                <GlobeIcon className={styles.navIcon} />
                Atlas
                {atlas.customizedCount > 0 && (
                  <span className={styles.navCount}>
                    {atlas.customizedCount}
                  </span>
                )}
              </button>
              <button
                type="button"
                className={styles.navAction}
                onClick={() => setIsPassportOpen(true)}
              >
                <SealCheckIcon className={styles.navIcon} />
                Passport
                {passport.progress.found > 0 && (
                  <span className={styles.navCount}>
                    {passport.progress.found}
                  </span>
                )}
              </button>
            </div>
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

      {/* ── Atlas overlay ─────────────────────────────────────────── */}
      {isAtlasOpen && (
        <Atlas
          overrides={atlas.overrides}
          onToggleWorld={handleToggleWorld}
          onResetSlot={atlas.resetSlot}
          onResetAll={atlas.resetAll}
          onClose={() => setIsAtlasOpen(false)}
        />
      )}

      {/* ── Passport overlay ──────────────────────────────────────── */}
      {isPassportOpen && (
        <Passport
          progress={passport.progress}
          onClose={() => setIsPassportOpen(false)}
        />
      )}
    </main>
  );
};

export default Home;
