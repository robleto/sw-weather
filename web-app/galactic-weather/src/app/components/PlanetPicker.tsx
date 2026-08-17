"use client";

import React, { useMemo, useState } from "react";
import Image from "next/image";
import styles from "../styles/PlanetPicker.module.css";
import WorldPoster from "./WorldPoster";
import { CLIMATE_LABELS, WORLDS, getWorld } from "@/lib/atlas/worlds";
import type { Climate, Slot, WorldId } from "@/lib/atlas/types";

// Only offer filters for climates that actually have worlds behind them.
const AVAILABLE_CLIMATES = Array.from(
	new Set(WORLDS.map((w) => w.climate))
) as Climate[];

interface PlanetPickerProps {
	slot: Slot;
	assigned: readonly WorldId[];
	onToggleWorld: (worldId: WorldId) => void;
	onResetSlot: () => void;
	onPreview: (worldId: WorldId | null) => void;
	onClose: () => void;
}

const PlanetPicker: React.FC<PlanetPickerProps> = ({
	slot,
	assigned,
	onToggleWorld,
	onResetSlot,
	onPreview,
	onClose,
}) => {
	const [climate, setClimate] = useState<Climate | "all">("all");
	const [query, setQuery] = useState("");
	const [posterWorldId, setPosterWorldId] = useState<WorldId | null>(null);

	const posterWorld = posterWorldId ? getWorld(posterWorldId) : undefined;

	const visibleWorlds = useMemo(() => {
		const needle = query.trim().toLowerCase();
		return WORLDS.filter((world) => {
			if (climate !== "all" && world.climate !== climate) return false;
			if (needle && !world.name.toLowerCase().includes(needle)) return false;
			return true;
		});
	}, [climate, query]);

	const isCustomized = assigned.length > 0;
	const selectionCount = isCustomized ? assigned.length : 0;

	return (
		<>
		<div className={styles.sheet} role="dialog" aria-label={`Choose a world for ${slot.label}`}>
			<header className={styles.sheetHeader}>
				<div>
					<p className={styles.eyebrow}>World for</p>
					<h3 className={styles.slotLabel}>{slot.label}</h3>
				</div>
				<button type="button" className={styles.closeButton} onClick={onClose}>
					Done
				</button>
			</header>

			<p className={styles.hint}>
				{selectionCount > 1
					? `${selectionCount} worlds assigned — one is chosen each day.`
					: "Pick one world, or several to randomize between them daily."}
			</p>

			<div className={styles.controls}>
				<div className={styles.chipRow}>
					<button
						type="button"
						className={`${styles.chip} ${climate === "all" ? styles.chipActive : ""}`}
						onClick={() => setClimate("all")}
					>
						All
					</button>
					{AVAILABLE_CLIMATES.map((c) => (
						<button
							key={c}
							type="button"
							className={`${styles.chip} ${climate === c ? styles.chipActive : ""}`}
							onClick={() => setClimate(c)}
						>
							{CLIMATE_LABELS[c]}
						</button>
					))}
				</div>

				<input
					type="search"
					className={styles.search}
					placeholder="Search worlds…"
					value={query}
					onChange={(event) => setQuery(event.target.value)}
					aria-label="Search worlds"
				/>
			</div>

			<ul className={styles.grid}>
				{visibleWorlds.map((world) => {
					const selected = assigned.includes(world.id);
					const isDefault = world.id === slot.defaultWorld;

					return (
						// The expand control has to be a sibling of the card, not a
						// child: a button inside a button is invalid HTML and the
						// inner one stops being reachable.
						<li key={world.id} className={styles.worldCell}>
							<button
								type="button"
								className={`${styles.worldCard} ${selected ? styles.worldCardSelected : ""}`}
								onClick={() => onToggleWorld(world.id)}
								onMouseEnter={() => onPreview(world.id)}
								onFocus={() => onPreview(world.id)}
								onMouseLeave={() => onPreview(null)}
								onBlur={() => onPreview(null)}
								aria-pressed={selected}
							>
								<span className={styles.thumb}>
									<Image
										src={`/planets/${world.id}.png`}
										alt=""
										fill
										sizes="140px"
										className={styles.thumbImage}
									/>
								</span>
								<span className={styles.worldName}>{world.name}</span>
								{isDefault && <span className={styles.defaultBadge}>Suits this weather</span>}
							</button>

							{/* An inert layer mirroring the thumb's box, so the chip can
							    sit at the *thumb's* bottom-right. The cell is taller
							    than the thumb by a name and a sometimes-present badge,
							    so anchoring to the cell would drift between cards. */}
							<span className={styles.expandLayer}>
								<button
									type="button"
									className={styles.expandButton}
									onClick={() => setPosterWorldId(world.id)}
									aria-label={`View ${world.name} as a poster`}
								>
									{/* The chip is a child so the button can carry a
									    44px hit area while the mark stays 32px. */}
									<span className={styles.expandChip}>
										<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
											<path
												d="M9 3H3v6M15 3h6v6M9 21H3v-6M15 21h6v-6"
												fill="none"
												stroke="currentColor"
												strokeWidth="2"
												strokeLinecap="round"
												strokeLinejoin="round"
											/>
										</svg>
									</span>
								</button>
							</span>
						</li>
					);
				})}
			</ul>

			{visibleWorlds.length === 0 && (
				<p className={styles.emptyState}>No worlds match that filter.</p>
			)}

			<footer className={styles.sheetFooter}>
				<button
					type="button"
					className={styles.resetButton}
					onClick={onResetSlot}
					disabled={!isCustomized}
				>
					Reset to canon
				</button>
			</footer>
		</div>

		{/* Rendered as a sibling of the sheet: the sheet's backdrop-filter makes
		    it a containing block, which would trap the poster's position:fixed
		    inside the sheet's bounds. */}
		{posterWorld && (
			<WorldPoster
				world={posterWorld}
				assignment={{
					slot,
					isAssigned: assigned.includes(posterWorld.id),
					onToggle: () => onToggleWorld(posterWorld.id),
				}}
				onClose={() => setPosterWorldId(null)}
			/>
		)}
		</>
	);
};

export default PlanetPicker;
