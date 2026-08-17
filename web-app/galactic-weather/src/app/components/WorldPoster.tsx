"use client";

import React, { useEffect, useRef } from "react";
import Image from "next/image";
import styles from "../styles/WorldPoster.module.css";
import { CLIMATE_LABELS, planetImageSrc } from "@/lib/atlas/worlds";
import type { Slot, World } from "@/lib/atlas/types";

/**
 * Assignment context. Optional because the poster is also openable from
 * surfaces that have no slot in hand — the Passport, where a world is a place
 * you've been rather than something you're picking.
 */
export interface PosterAssignment {
	slot: Slot;
	isAssigned: boolean;
	onToggle: () => void;
}

/**
 * Passport context: whether this world has been lived through, and where.
 *
 * `date` arrives preformatted. The Passport parses ISO stamp dates by hand to
 * dodge the UTC-midnight-shifts-the-day bug, and that logic should stay in one
 * place rather than being reimplemented here.
 */
export type PosterStamp =
	| {
			found: true;
			city: string;
			date: string;
			slotLabel?: string;
			tempF: number;
			/** Days this world has been seen; 1 unless it's recurred. */
			count: number;
			chartered: boolean;
	  }
	| {
			found: false;
			/** False when no weather bucket maps here, so it can't be found wild. */
			wildReachable: boolean;
	  };

interface WorldPosterProps {
	world: World;
	assignment?: PosterAssignment;
	stamp?: PosterStamp;
	onClose: () => void;
}

/**
 * A world shown the way it exists as a physical object: art in a print border,
 * title on a colour plate below it, caption underneath.
 *
 * The frame is the point. Every other surface in this app paints planet art
 * full-bleed as a *background*; matting it and giving it a title band is what
 * makes it read as a printed poster instead of just a larger backdrop.
 */
const WorldPoster: React.FC<WorldPosterProps> = ({
	world,
	assignment,
	stamp,
	onClose,
}) => {
	const closeRef = useRef<HTMLButtonElement>(null);
	// Held in a ref so the mount effect can stay dependency-free — re-running it
	// would steal focus back to the close button mid-interaction.
	const onCloseRef = useRef(onClose);
	onCloseRef.current = onClose;

	useEffect(() => {
		const previouslyFocused = document.activeElement as HTMLElement | null;
		closeRef.current?.focus();

		const handleKeyDown = (event: KeyboardEvent) => {
			if (event.key !== "Escape") return;
			// The picker sheet sits underneath and may grow its own Escape
			// handling later; the topmost layer should consume the key.
			event.stopPropagation();
			onCloseRef.current();
		};

		document.addEventListener("keydown", handleKeyDown);
		return () => {
			document.removeEventListener("keydown", handleKeyDown);
			previouslyFocused?.focus?.();
		};
	}, []);

	const slot = assignment?.slot;
	const isCanonTwin = slot ? world.id === slot.defaultWorld : false;
	const titleId = `world-poster-${world.id}`;

	// An unfound world stays drained of colour here, exactly as its Passport
	// thumbnail is. Colour is the reward for living through the weather, and
	// opening the poster shouldn't hand it over early — the plate still reads
	// "Visit", because that is what a travel poster says about a place you
	// haven't been.
	const isUnfound = stamp?.found === false;

	return (
		<div
			className={styles.overlay}
			role="dialog"
			aria-modal="true"
			aria-labelledby={titleId}
		>
			{/* Sibling rather than a parent so a click on the poster itself can't
			    bubble out and dismiss the thing being looked at. */}
			<button
				type="button"
				className={styles.scrim}
				onClick={onClose}
				aria-label="Close poster"
				tabIndex={-1}
			/>

			<div className={styles.stage}>
				<button
					type="button"
					ref={closeRef}
					className={styles.closeButton}
					onClick={onClose}
				>
					Close
				</button>

				<figure className={styles.poster}>
					<div className={styles.art}>
						<Image
							src={planetImageSrc(world.id)}
							alt={`${world.name} — ${world.description}`}
							fill
							sizes="(max-width: 640px) 92vw, 560px"
							priority
							className={`${styles.artImage} ${
								isUnfound ? styles.artImageUnfound : ""
							}`}
						/>
					</div>

					<figcaption
						className={styles.plate}
						style={{ backgroundColor: world.color.primary }}
					>
						<p className={styles.plateEyebrow}>Visit</p>
						<h2
							id={titleId}
							className={styles.plateTitle}
							style={{ color: world.color.headline }}
						>
							{world.name}
						</h2>
						<p className={styles.plateDescription}>{world.description}</p>

						<p className={styles.plateMeta}>
							<span>{CLIMATE_LABELS[world.climate]}</span>
							{isCanonTwin && slot && (
								<>
									<span aria-hidden="true">·</span>
									<span>The canon twin for {slot.label.toLowerCase()}</span>
								</>
							)}
						</p>
					</figcaption>
				</figure>

				<div className={styles.actions}>
					{/* Outside the frame on purpose: the plate is the poster's own
					    printed content, which can't know where you were standing.
					    Your sighting is an annotation on it, not part of it. */}
					{stamp && (
						<div className={styles.stamp}>
							{stamp.found ? (
								<>
									<span className={styles.stampHeadline}>
										Found in {stamp.city}
										{stamp.chartered && (
											<span className={styles.charteredTag}>Chartered</span>
										)}
									</span>
									<span className={styles.stampMeta}>
										{stamp.date}
										{stamp.slotLabel && ` · ${stamp.slotLabel}`}
										{` · ${stamp.tempF}°F`}
										{stamp.count > 1 && ` · seen on ${stamp.count} days`}
									</span>
								</>
							) : (
								<>
									<span className={styles.stampHeadlineUnfound}>
										Not yet found
									</span>
									<span className={styles.stampMeta}>
										{stamp.wildReachable
											? "Its weather has to actually happen somewhere you're looking."
											: "No forecast leads here — assign it in Atlas, then live through that weather."}
									</span>
								</>
							)}
						</div>
					)}

					{assignment && (
						<button
							type="button"
							className={`${styles.assignButton} ${
								assignment.isAssigned ? styles.assignButtonActive : ""
							}`}
							onClick={assignment.onToggle}
							aria-pressed={assignment.isAssigned}
						>
							{assignment.isAssigned
								? `Remove from ${assignment.slot.label}`
								: `Assign to ${assignment.slot.label}`}
						</button>
					)}

					<p className={styles.credit}>
						Original planet art, also sold as travel posters at{" "}
						<a
							href="https://creativemadness.studio"
							target="_blank"
							rel="noopener noreferrer"
						>
							creativemadness.studio
						</a>
						.
					</p>
				</div>
			</div>
		</div>
	);
};

export default WorldPoster;
