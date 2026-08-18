import React from "react";

/**
 * The marks on the Atlas and Passport nav buttons.
 *
 * iOS labels the same two destinations with SF Symbols — `globe.americas.fill`
 * and `checkmark.seal.fill` (SavedLocationsView.destinations) — so these are
 * hand-drawn stand-ins for those, not new iconography. There is no icon
 * dependency here and adding one for two glyphs would not pay for itself;
 * PlanetPicker's expand chip already establishes the inline-SVG idiom
 * (24-unit box, `currentColor`, `aria-hidden`).
 *
 * They render at whatever `currentColor` the button sets, so the accent stays
 * a CSS decision rather than something baked into the path data.
 */

type IconProps = { className?: string };

/** Atlas: a globe with an equator and a meridian. */
export const GlobeIcon: React.FC<IconProps> = ({ className }) => (
	<svg
		className={className}
		viewBox="0 0 24 24"
		aria-hidden="true"
		focusable="false"
		fill="none"
		stroke="currentColor"
		strokeWidth="1.8"
		strokeLinecap="round"
		strokeLinejoin="round"
	>
		<circle cx="12" cy="12" r="9" />
		<ellipse cx="12" cy="12" rx="4.1" ry="9" />
		<path d="M3.2 9.2h17.6M3.2 14.8h17.6" />
	</svg>
);

/**
 * Passport: a checkmark inside a scalloped seal — the stamp you collect, which
 * is what the Passport actually holds. The seal outline is a 12-lobe polygon
 * rather than a plain circle so it reads as a stamp and not as a generic
 * confirmation tick.
 */
export const SealCheckIcon: React.FC<IconProps> = ({ className }) => (
	<svg
		className={className}
		viewBox="0 0 24 24"
		aria-hidden="true"
		focusable="false"
		fill="none"
		stroke="currentColor"
		strokeWidth="1.8"
		strokeLinecap="round"
		strokeLinejoin="round"
	>
		<path d="M12 2.3L14.1 4L16.9 3.6L17.9 6.1L20.4 7.2L20 9.9L21.7 12L20 14.1L20.4 16.8L17.9 17.9L16.9 20.4L14.1 20L12 21.7L9.9 20L7.2 20.4L6.1 17.9L3.6 16.8L4 14.1L2.3 12L4 9.9L3.6 7.1L6.1 6.1L7.1 3.6L9.9 4Z" />
		<path d="M8.4 12.2l2.5 2.5 4.7-5" />
	</svg>
);
