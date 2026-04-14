"use client";

import React, { useMemo } from "react";
import styles from "../styles/HyperspaceStars.module.css";

function r(seed: number): number {
  const x = Math.sin(seed + 1) * 10000;
  return x - Math.floor(x);
}

export default function HyperspaceStars() {
  const stars = useMemo(
    () =>
      Array.from({ length: 40 }, (_, i) => ({
        id: i,
        top: r(i * 7 + 1) * 100,
        left: r(i * 13 + 2) * 100,
        angle: r(i * 17 + 3) * 360,
        height: 35 + r(i * 11 + 4) * 55,
        duration: 2 + r(i * 19 + 5) * 3,
        delay: -(r(i * 23 + 6) * 6),
      })),
    []
  );

  return (
    <>
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
          }}
        />
      ))}
    </>
  );
}
