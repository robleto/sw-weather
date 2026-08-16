"use client";

import React, { useMemo, useState } from "react";
import Image from "next/image";
import styles from "../styles/PlanetPicker.module.css";
import { WORLDS } from "@/lib/starchart/worlds";
import type { Climate, Slot, WorldId } from "@/lib/starchart/types";

const CLIMATE_LABELS: Record<Climate, string> = {
	desert: "Desert",
	ice: "Ice",
	ocean: "Ocean",
	forest: "Forest",
	volcanic: "Volcanic",
	urban: "Urban",
	temperate: "Temperate",
	storm: "Storm",
	sky: "Sky",
};

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
		<div className={styles.sheet} role="dialog" aria-label={`Choose a world for ${slot.label}`}>
			<header className={styles.sheetHeader}>
				<div>
					<p className={styles.eyebrow}>Weather twin for</p>
					<h3 className={styles.slotLabel}>{slot.label}</h3>
				</div>
				<button type="button" className={styles.closeButton} onClick={onClose}>
					Done
				</button>
			</header>

			<p className={styles.hint}>
				{selectionCount > 1
					? `${selectionCount} worlds assigned — one is chosen each day.`
					: "Pick one world, or several to rotate between them daily."}
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
						<li key={world.id}>
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
	);
};

export default PlanetPicker;
