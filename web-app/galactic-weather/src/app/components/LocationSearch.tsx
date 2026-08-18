"use client";

import React, { useEffect, useMemo, useRef, useState } from "react";
import styles from "../styles/LocationSearch.module.css";
import { geocodeLocation } from "@/lib/location/geocode";
import { parseLocationQuery } from "@/lib/location/parseLocationQuery";
import {
	candidateFlag,
	candidateSecondaryText,
} from "@/lib/location/candidateDisplay";
import type { LocationCandidate } from "@/lib/location/types";

interface LocationSearchProps {
	value: string;
	onValueChange: (value: string) => void;
	onLocationResolved: (payload: {
		lat: number;
		lon: number;
		displayName: string;
	}) => void;
	/** Optional extra class applied to the root form element */
	className?: string;
}

const NO_RESULTS_MESSAGE =
	"No matches found—try City, State or City, Country.";
const API_ERROR_MESSAGE =
	"We couldn't resolve that location. Please try again.";

/** Stands in for the flag on a raw `lat,lon` entry, which has no country. */
const CoordinateGlyph = () => (
	<svg viewBox="0 0 16 16" width="15" height="15" aria-hidden="true" focusable="false">
		<circle
			cx="6.75"
			cy="6.75"
			r="4.25"
			fill="none"
			stroke="currentColor"
			strokeWidth="1.5"
		/>
		<path
			d="M10 10l3.5 3.5"
			fill="none"
			stroke="currentColor"
			strokeWidth="1.5"
			strokeLinecap="round"
		/>
	</svg>
);

const Chevron = () => (
	<svg viewBox="0 0 12 12" width="9" height="9" aria-hidden="true" focusable="false">
		<path
			d="M4 2l4 4-4 4"
			fill="none"
			stroke="currentColor"
			strokeWidth="2"
			strokeLinecap="round"
			strokeLinejoin="round"
		/>
	</svg>
);

const LocationSearch: React.FC<LocationSearchProps> = ({
	value,
	onValueChange,
	onLocationResolved,
	className,
}) => {
	const [candidates, setCandidates] = useState<LocationCandidate[]>([]);
	const [activeIndex, setActiveIndex] = useState<number>(-1);
	const [message, setMessage] = useState<string>("");
	const [isApiError, setIsApiError] = useState(false);
	const [isLoading, setIsLoading] = useState(false);
	const [retryTick, setRetryTick] = useState(0);

	// Keep a stable ref to the latest callback so the geocoding effect doesn't
	// need to list it as a dependency (avoids re-running on every parent render).
	const onLocationResolvedRef = useRef(onLocationResolved);
	onLocationResolvedRef.current = onLocationResolved;

	// When the user picks a candidate we call onValueChange to update the input.
	// That change would normally re-trigger the geocoding effect — skip it.
	const skipNextEffectRef = useRef(false);

	const trimmedValue = useMemo(() => value.trim(), [value]);

	useEffect(() => {
		// Candidate was just selected; the value change is intentional — don't geocode.
		if (skipNextEffectRef.current) {
			skipNextEffectRef.current = false;
			setIsLoading(false);
			return;
		}

		if (!trimmedValue) {
			setCandidates([]);
			setActiveIndex(-1);
			setMessage("");
			setIsApiError(false);
			setIsLoading(false);
			return;
		}

		let cancelled = false;
		setIsLoading(true);
		setMessage("");
		setIsApiError(false);

		const timeout = window.setTimeout(async () => {
			const parsed = parseLocationQuery(trimmedValue);

			if (parsed.kind === "empty") {
				if (!cancelled) {
					setCandidates([]);
					setIsLoading(false);
				}
				return;
			}

			if (parsed.kind === "coordinates") {
				if (!cancelled) {
					// Offered as a one-row dropdown rather than resolved on the
					// spot — see the note on the geocode results below.
					const displayName = `${parsed.lat}, ${parsed.lon}`;
					setCandidates([
						{
							name: displayName,
							regionOrState: "",
							country: "",
							lat: parsed.lat,
							lon: parsed.lon,
							displayName,
						},
					]);
					setActiveIndex(0);
					setIsLoading(false);
				}
				return;
			}

			try {
				const results = await geocodeLocation(parsed.query);
				if (cancelled) return;

				if (results.length === 0) {
					setCandidates([]);
					setActiveIndex(-1);
					setMessage(NO_RESULTS_MESSAGE);
					setIsLoading(false);
					return;
				}

				// Every candidate list gets shown, including a single hit —
				// nothing resolves without a tap. A lone result used to jump
				// straight to that place, which meant an unambiguous query
				// navigated the whole page with no dropdown ever appearing and
				// nothing to confirm it had understood you. Matches iOS, where
				// `LocationSearchViewModel` has never auto-resolved.
				setCandidates(results);
				setActiveIndex(0);
			} catch {
				if (!cancelled) {
					setCandidates([]);
					setActiveIndex(-1);
					setMessage(API_ERROR_MESSAGE);
					setIsApiError(true);
					if (process.env.NODE_ENV !== "production") {
						console.error("[LocationSearch] geocodeLocation failed for:", trimmedValue);
					}
				}
			} finally {
				if (!cancelled) {
					setIsLoading(false);
				}
			}
		}, 450);

		return () => {
			cancelled = true;
			window.clearTimeout(timeout);
		};
		// onLocationResolved intentionally omitted — accessed via ref
		// eslint-disable-next-line react-hooks/exhaustive-deps
	}, [trimmedValue, retryTick]);

	const handleCandidateClick = (candidate: LocationCandidate) => {
		// Signal the next effect run (caused by onValueChange below) to skip geocoding
		skipNextEffectRef.current = true;
		setCandidates([]);
		setActiveIndex(-1);
		setMessage("");
		setIsApiError(false);
		onValueChange(candidate.displayName);
		onLocationResolvedRef.current({
			lat: candidate.lat,
			lon: candidate.lon,
			displayName: candidate.displayName,
		});
	};

	const listboxId = "location-candidate-list";

	const handleInputKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
		if (event.key === "Escape") {
			setCandidates([]);
			setActiveIndex(-1);
			setMessage("");
			return;
		}

		if (candidates.length === 0) {
			return;
		}

		if (event.key === "ArrowDown") {
			event.preventDefault();
			setActiveIndex((prev) =>
				prev < 0 ? 0 : (prev + 1) % candidates.length
			);
			return;
		}

		if (event.key === "ArrowUp") {
			event.preventDefault();
			setActiveIndex((prev) =>
				prev < 0 ? candidates.length - 1 : (prev - 1 + candidates.length) % candidates.length
			);
			return;
		}

		if (event.key === "Enter" && activeIndex >= 0) {
			event.preventDefault();
			handleCandidateClick(candidates[activeIndex]);
		}
	};

	return (
		<form className={`${styles.weatherLocation}${className ? ` ${className}` : ''}`} onSubmit={(e) => e.preventDefault()}>
			<label htmlFor="locationQuery" className={styles.srOnly}>
				Search by city, state, country, ZIP, or coordinates
			</label>
			<input
				className={styles.input_field}
				placeholder="Enter City, ZIP, or lat,lon"
				type="text"
				id="locationQuery"
				name="locationQuery"
				value={value}
				role="combobox"
				aria-autocomplete="list"
				aria-expanded={candidates.length > 0}
				aria-controls={listboxId}
				aria-activedescendant={
					activeIndex >= 0 && candidates[activeIndex]
						? `location-candidate-${activeIndex}`
						: undefined
				}
				onChange={(e) => onValueChange(e.target.value)}
				onKeyDown={handleInputKeyDown}
			/>

			{isLoading && (
				<div className={styles.searchStatus} aria-live="polite" role="status">
					Resolving location…
				</div>
			)}

			{candidates.length > 0 && (
				<ul className={styles.candidateList} role="listbox" id={listboxId}>
					{candidates.map((candidate, index) => {
						const flag = candidateFlag(candidate);
						const secondaryText = candidateSecondaryText(candidate);
						return (
							<li
								key={`${candidate.lat}-${candidate.lon}-${candidate.displayName}`}
								role="none"
							>
								<button
									type="button"
									id={`location-candidate-${index}`}
									role="option"
									aria-selected={activeIndex === index}
									className={`${styles.candidateButton} ${
										activeIndex === index ? styles.candidateButtonActive : ""
									}`}
									onMouseDown={(event) => event.preventDefault()}
									onClick={() => handleCandidateClick(candidate)}
									onMouseEnter={() => setActiveIndex(index)}
								>
									{/* Flag, city, and where the city is — the three things you
									    need to tell two same-named places apart, which is the
									    whole reason this list exists. The flag does most of that
									    work before you've read anything. */}
									<span className={styles.candidateGlyph} aria-hidden="true">
										{flag ?? <CoordinateGlyph />}
									</span>
									<span className={styles.candidateText}>
										<span className={styles.candidateName}>{candidate.name}</span>
										{secondaryText && (
											<span className={styles.candidateSecondary}>
												{secondaryText}
											</span>
										)}
									</span>
									<span className={styles.candidateChevron} aria-hidden="true">
										<Chevron />
									</span>
								</button>
							</li>
						);
					})}
				</ul>
			)}

			{message && (
				<div className={styles.searchStatus} aria-live="polite" role="status">
					{message}
					{isApiError && (
						<button
							type="button"
							className={styles.retryButton}
							onClick={() => setRetryTick((prev) => prev + 1)}
						>
							Retry
						</button>
					)}
				</div>
			)}
		</form>
	);
};

export default LocationSearch;
