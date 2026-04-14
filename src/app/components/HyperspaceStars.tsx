"use client";

import React, { useMemo } from "react";
import styles from "../styles/HyperspaceStars.module.css";

// Deterministic pseudo-random so SSR and client match
function r(seed: number): number {
  const x = Math.sin(seed + 1) * 10000;
  return x - Math.floor(x);
}

const STAR_COUNT = 45;

export default function HyperspaceStars() {
  const stars = useMemo(
    () =>
      Array.from({ length: STAR_COUNT }, (_, i) => ({
        id: i,
        top: r(i * 7 + 1) * 100,
        left: r(i * 13 + 2) * 100,
        angle: r(i * 17 + 3) * 360,
        height: 28 + r(i * 11 + 4) * 52,
        duration: 1.8 + r(i * 19 + 5) * 3.5,
        delay: -(r(i * 23 + 6) * 5), // negative = already mid-animation on mount
        brightness: 0.35 + r(i * 29 + 7) * 0.65,
      })),
    []
  );

  return (
    <div className={styles.starfield} aria-hidden="true">
      {stars.map((star) => (
        <span
          key={star.id}
          className={styles.star}
          style={{
            top: `${star.top}%`,
            left: `${star.left}%`,
            height: `${star.height}px`,
            transform: `rotate(${star.angle}deg)`,
            animationDuration: `${star.duration}s`,
            animationDelay: `${star.delay}s`,
            opacity: star.brightness,
          }}
        />
      ))}
    </div>
  );
}
