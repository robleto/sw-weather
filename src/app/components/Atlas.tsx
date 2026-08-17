"use client";

import React, { useMemo, useState } from "react";
import Image from "next/image";
import styles from "../styles/Atlas.module.css";
import PlanetPicker from "./PlanetPicker";
import { SLOTS, SLOT_GROUP_ORDER, SLOT_RANGE_HINT, getSlot } from "@/lib/atlas/slots";
import { resolveWorld } from "@/lib/atlas/resolve";
import { getWorld } from "@/lib/atlas/worlds";
import type { SlotId, AtlasOverrides, WorldId } from "@/lib/atlas/types";

interface AtlasProps {
	overrides: AtlasOverrides;
	onToggleWorld: (slotId: SlotId, worldId: WorldId) => void;
	onResetSlot: (slotId: SlotId) => void;
	onResetAll: () => void;
	onClose: () => void;
}

const Atlas: React.FC<AtlasProps> = ({
	overrides,
	onToggleWorld,
	onResetSlot,
	onResetAll,
	onClose,
}) => {
	const [activeSlotId, setActiveSlotId] = useState<SlotId | null>(null);
	const [previewWorldId, setPreviewWorldId] = useState<WorldId | null>(null);

	const activeSlot = activeSlotId ? getSlot(activeSlotId) : null;

	const groupedSlots = useMemo(
		() =>
			SLOT_GROUP_ORDER.map((group) => ({
				group,
				slots: SLOTS.filter((slot) => slot.group === group),
			})),
		[]
	);

	// The backdrop shows whatever is being previewed, falling back to the world
	// the open slot currently resolves to — so opening the picker never flashes
	// an empty background.
	const backdropWorldId = useMemo(() => {
		if (previewWorldId) return previewWorldId;
		if (activeSlotId) return resolveWorld(activeSlotId, overrides).planet;
		return null;
	}, [previewWorldId, activeSlotId, overrides]);

	const customizedCount = Object.keys(overrides).length;

	return (
		<div className={styles.overlay} role="dialog" aria-modal="true" aria-label="Atlas">
			{backdropWorldId && (
				<div className={styles.backdrop} key={backdropWorldId}>
					<Image
						src={`/planets/${backdropWorldId}.png`}
						alt=""
						fill
						sizes="100vw"
						priority
						className={styles.backdropImage}
					/>
				</div>
			)}
			<div className={styles.scrim} />

			<div className={styles.content}>
				<header className={styles.header}>
					<div>
						<p className={styles.eyebrow}>Your Atlas</p>
						<h2 className={styles.title}>Reassign any condition</h2>
					</div>
					<button type="button" className={styles.closeButton} onClick={onClose}>
						Close
					</button>
				</header>

				<p className={styles.summary}>
					{customizedCount === 0
						? `${SLOTS.length} conditions, all set to canon.`
						: `${customizedCount} of ${SLOTS.length} conditions customized.`}
					{customizedCount > 0 && (
						<button type="button" className={styles.resetAll} onClick={onResetAll}>
							Reset all
						</button>
					)}
				</p>

				<div className={styles.groups}>
					{groupedSlots.map(({ group, slots }) => (
						<section key={group} className={styles.group}>
							<h3 className={styles.groupTitle}>{group}</h3>
							<ul className={styles.slotList}>
								{slots.map((slot) => {
									const assigned = overrides[slot.id] ?? [];
									const resolved = resolveWorld(slot.id, overrides);
									const extraCount = assigned.length > 1 ? assigned.length - 1 : 0;
									const rangeHint = SLOT_RANGE_HINT[slot.id];

									return (
										<li key={slot.id}>
											<button
												type="button"
												className={`${styles.slotRow} ${
													activeSlotId === slot.id ? styles.slotRowActive : ""
												}`}
												onClick={() =>
													setActiveSlotId((current) =>
														current === slot.id ? null : slot.id
													)
												}
												aria-expanded={activeSlotId === slot.id}
											>
												<span className={styles.slotThumb}>
													<Image
														src={`/planets/${resolved.planet}.png`}
														alt=""
														fill
														sizes="56px"
														className={styles.slotThumbImage}
													/>
												</span>

												<span className={styles.slotText}>
													<span className={styles.slotLabel}>{slot.label}</span>
													{rangeHint && (
														<span className={styles.slotRange}>{rangeHint}</span>
													)}
												</span>

												<span className={styles.slotWorld}>
													{resolved.planetName}
													{extraCount > 0 && (
														<span className={styles.extraCount}>+{extraCount}</span>
													)}
													{resolved.customized && (
														<span className={styles.customDot} aria-label="Customized" />
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

			{activeSlot && (
				<PlanetPicker
					slot={activeSlot}
					assigned={overrides[activeSlot.id] ?? []}
					onToggleWorld={(worldId) => onToggleWorld(activeSlot.id, worldId)}
					onResetSlot={() => onResetSlot(activeSlot.id)}
					onPreview={(worldId) => setPreviewWorldId(worldId && getWorld(worldId) ? worldId : null)}
					onClose={() => {
						setActiveSlotId(null);
						setPreviewWorldId(null);
					}}
				/>
			)}
		</div>
	);
};

export default Atlas;
