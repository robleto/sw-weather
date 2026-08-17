"use client";

import React, { useMemo, useState } from "react";
import Image from "next/image";
import styles from "../styles/Passport.module.css";
import WorldPoster, { type PosterStamp } from "./WorldPoster";
import { getSlot } from "@/lib/atlas/slots";
import type { PassportProgress, WorldProgress } from "@/lib/passport/progress";
import type { Sighting } from "@/lib/passport/types";
import type { WorldId } from "@/lib/atlas/types";
import { planetImageSrc } from "@/lib/atlas/worlds";

interface PassportProps {
	/** Derived once in `usePassport`, so the book never recomputes it on open. */
	progress: PassportProgress;
	onClose: () => void;
}

/**
 * "2026-08-17" -> "Aug 17, 2026".
 *
 * Split by hand rather than `new Date(iso)`: the string form parses as UTC
 * midnight, which renders as the previous day everywhere west of Greenwich —
 * so a stamp earned on the 17th would read as the 16th for most of the US.
 */
const formatStampDate = (iso: string): string => {
	const [year, month, day] = iso.split("-").map(Number);
	if (!year || !month || !day) return iso;
	return new Date(year, month - 1, day).toLocaleDateString(undefined, {
		month: "short",
		day: "numeric",
		year: "numeric",
	});
};

/** The wild find is the one that counts, so it's the one the stamp shows. */
const primarySighting = (entry: WorldProgress): Sighting | undefined =>
	entry.stamp?.wild ?? entry.stamp?.chartered;

/** Flattens a progress entry into the shape the poster's caption needs. */
const toPosterStamp = (entry: WorldProgress): PosterStamp => {
	const sighting = primarySighting(entry);
	if (!sighting || entry.status === "unfound") {
		return { found: false, wildReachable: entry.wildReachable };
	}
	return {
		found: true,
		city: sighting.city,
		date: formatStampDate(sighting.date),
		slotLabel: getSlot(sighting.slotId)?.label,
		tempF: sighting.tempF,
		count: entry.stamp?.count ?? 1,
		chartered: entry.status === "chartered",
	};
};

const Passport: React.FC<PassportProps> = ({ progress, onClose }) => {
	const [previewWorldId, setPreviewWorldId] = useState<WorldId | null>(null);
	const [posterWorldId, setPosterWorldId] = useState<WorldId | null>(null);

	const posterEntry = useMemo(() => {
		if (!posterWorldId) return undefined;
		return progress.biomes
			.flatMap((biome) => biome.worlds)
			.find((entry) => entry.world.id === posterWorldId);
	}, [posterWorldId, progress]);

	return (
		<div className={styles.overlay} role="dialog" aria-modal="true" aria-label="Passport">
			{previewWorldId && (
				<div className={styles.backdrop} key={previewWorldId}>
					<Image
						src={planetImageSrc(previewWorldId)}
						alt=""
						fill
						sizes="100vw"
						className={styles.backdropImage}
					/>
				</div>
			)}
			<div className={styles.scrim} />

			<div className={styles.content}>
				<header className={styles.header}>
					<div>
						<p className={styles.eyebrow}>Your Passport</p>
						<h2 className={styles.title}>Worlds you&apos;ve found</h2>
					</div>
					<button type="button" className={styles.closeButton} onClick={onClose}>
						Close
					</button>
				</header>

				<p className={styles.summary}>
					<span className={styles.score}>
						<strong>{progress.wildFound}</strong>/{progress.wildTotal} found wild
					</span>
					<span className={styles.scoreDivider} aria-hidden="true">
						·
					</span>
					<span className={styles.scoreMuted}>
						{progress.found}/{progress.total} in total
					</span>
				</p>

				<p className={styles.blurb}>{progress.blurb}</p>

				<div className={styles.biomes}>
					{progress.biomes.map((biome) => (
						<section key={biome.climate} className={styles.biome}>
							<h3 className={styles.biomeTitle}>
								{biome.label}
								<span className={styles.biomeCount}>
									{biome.found}/{biome.total}
								</span>
							</h3>

							<ul className={styles.stampGrid}>
								{biome.worlds.map((entry) => {
									const sighting = primarySighting(entry);
									const found = entry.status !== "unfound";
									const slotLabel = sighting
										? getSlot(sighting.slotId)?.label
										: undefined;

									return (
										<li
											key={entry.world.id}
											className={`${styles.stamp} ${
												found ? styles[entry.status] : styles.unfound
											}`}
											onMouseEnter={() =>
												setPreviewWorldId(found ? entry.world.id : null)
											}
											onMouseLeave={() => setPreviewWorldId(null)}
										>
											{/* The whole row is the target. Tapping a stamp did
											    nothing before, so opening the poster costs no
											    existing gesture and needs no extra affordance. */}
											<button
												type="button"
												className={styles.stampButton}
												onClick={() => setPosterWorldId(entry.world.id)}
											>
												<span className={styles.stampThumb}>
													<Image
														src={planetImageSrc(entry.world.id)}
														alt=""
														fill
														sizes="72px"
														className={styles.stampThumbImage}
													/>
												</span>

												<span className={styles.stampBody}>
													<span className={styles.stampName}>
														{entry.world.name}
														{entry.stamp && entry.stamp.count > 1 && (
															<span
																className={styles.stampCount}
																title={`Seen on ${entry.stamp.count} days`}
															>
																×{entry.stamp.count}
															</span>
														)}
													</span>

													{sighting ? (
														<>
															<span className={styles.stampPlace}>
																{sighting.city}
															</span>
															<span className={styles.stampMeta}>
																{formatStampDate(sighting.date)}
																{slotLabel && ` · ${slotLabel}`}
																{` · ${sighting.tempF}°F`}
															</span>
															{entry.status === "chartered" && (
																<span className={styles.charteredTag}>
																	Chartered
																</span>
															)}
														</>
													) : (
														<>
															<span className={styles.stampPlace}>
																Not yet found
															</span>
															{!entry.wildReachable && (
																<span className={styles.stampHint}>
																	No forecast leads here — assign it in
																	Atlas, then live through that weather
																</span>
															)}
														</>
													)}
												</span>
											</button>
										</li>
									);
								})}
							</ul>
						</section>
					))}
				</div>
			</div>

			{posterEntry && (
				<WorldPoster
					world={posterEntry.world}
					stamp={toPosterStamp(posterEntry)}
					onClose={() => setPosterWorldId(null)}
				/>
			)}
		</div>
	);
};

export default Passport;
