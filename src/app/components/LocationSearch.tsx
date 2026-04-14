"use client";

import React, { useEffect, useMemo, useRef, useState } from "react";
import styles from "../styles/LocationSearch.module.css";
import { geocodeLocation } from "@/lib/location/geocode";
import { parseLocationQuery } from "@/lib/location/parseLocationQuery";
import type { LocationCandidate } from "@/lib/location/types";

interface LocationSearchProps {
	value: string;
	onValueChange: (value: string) => void;
	onLocationResolved: (payload: {
		lat: number;
		lon: number;
		displayName: string;
	}) => void;
	className?: string;
	variant?: "default" | "hero";
}

const NO_RESULTS_MESSAGE =
	"No matches found—try City, State or City, Country.";
const API_ERROR_MESSAGE =
	"We couldn't resolve that location. Please try again.";

const LocationSearch: React.FC<LocationSearchProps> = ({
	value,
	onValueChange,
	onLocationResolved,
	className,
	variant = "default",
}) => {
	const [candidates, setCandidates] = useState<LocationCandidate[]>([]);
	const [activeIndex, setActiveIndex] = useState<number>(-1);
	const [message, setMessage] = useState<string>("");
	const [isApiError, setIsApiError] = useState(false);
	const [isLoading, setIsLoading] = useState(false);
	const [retryTick, setRetryTick] = useState(0);

	// Stable ref so the geocoding effect doesn't re-run on every parent render
	const onLocationResolvedRef = useRef(onLocationResolved);
	onLocationResolvedRef.current = onLocationResolved;

	const trimmedValue = useMemo(() => value.trim(), [value]);

	useEffect(() => {
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
					setCandidates([]);
					setActiveIndex(-1);
					setIsLoading(false);
					onLocationResolvedRef.current({
						lat: parsed.lat,
						lon: parsed.lon,
						displayName: `${parsed.lat}, ${parsed.lon}`,
					});
				}
				return;
			}

			try {
				const results = await geocodeLocation(parsed.query);
				if (cancelled) {
					return;
				}

				if (results.length === 0) {
					setCandidates([]);
					setActiveIndex(-1);
					setMessage(NO_RESULTS_MESSAGE);
					setIsLoading(false);
					return;
				}

				if (results.length === 1) {
					setCandidates([]);
					setActiveIndex(-1);
					setIsLoading(false);
					onLocationResolvedRef.current({
						lat: results[0].lat,
						lon: results[0].lon,
						displayName: results[0].displayName,
					});
					return;
				}

				setCandidates(results);
				setActiveIndex(0);
			} catch {
				if (!cancelled) {
					setCandidates([]);
					setActiveIndex(-1);
					setMessage(API_ERROR_MESSAGE);
					setIsApiError(true);
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
			return;
		}

		if (candidates.length <= 1) {
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
				className={`${styles.input_field} ${variant === "hero" ? styles.input_field_hero : ""}`}
				placeholder="Enter City, ZIP, or lat,lon"
				type="text"
				id="locationQuery"
				name="locationQuery"
				value={value}
				role="combobox"
				aria-autocomplete="list"
				aria-expanded={candidates.length > 1}
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

			{candidates.length > 1 && (
				<ul className={styles.candidateList} role="listbox" id={listboxId}>
					{candidates.map((candidate, index) => (
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
								onClick={() => handleCandidateClick(candidate)}
								onMouseEnter={() => setActiveIndex(index)}
							>
								{candidate.displayName}
							</button>
						</li>
					))}
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
