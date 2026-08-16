"use client";

import { useCallback, useEffect, useState } from "react";
import { clearOverrides, loadOverrides, saveOverrides } from "@/lib/starchart/storage";
import type { SlotId, StarChartOverrides, WorldId } from "@/lib/starchart/types";

/**
 * Owns the user's Star Chart (their slot -> world assignments).
 *
 * Starts empty and hydrates from storage in an effect rather than during
 * render, so the server and first client render agree.
 */
export const useStarChart = () => {
	const [overrides, setOverrides] = useState<StarChartOverrides>({});
	const [hydrated, setHydrated] = useState(false);

	useEffect(() => {
		setOverrides(loadOverrides());
		setHydrated(true);
	}, []);

	const persist = useCallback((next: StarChartOverrides) => {
		setOverrides(next);
		saveOverrides(next);
	}, []);

	/** Replace a slot's assignment. An empty list restores the default. */
	const assignSlot = useCallback(
		(slotId: SlotId, worldIds: WorldId[]) => {
			setOverrides((current) => {
				const next = { ...current };
				if (worldIds.length === 0) {
					delete next[slotId];
				} else {
					next[slotId] = Array.from(new Set(worldIds));
				}
				saveOverrides(next);
				return next;
			});
		},
		[]
	);

	/** Add or remove a single world from a slot, for multi-assign. */
	const toggleWorld = useCallback((slotId: SlotId, worldId: WorldId) => {
		setOverrides((current) => {
			const assigned = current[slotId] ?? [];
			const isAssigned = assigned.includes(worldId);
			const nextAssigned = isAssigned
				? assigned.filter((id) => id !== worldId)
				: [...assigned, worldId];

			const next = { ...current };
			if (nextAssigned.length === 0) {
				delete next[slotId];
			} else {
				next[slotId] = nextAssigned;
			}
			saveOverrides(next);
			return next;
		});
	}, []);

	const resetSlot = useCallback((slotId: SlotId) => {
		setOverrides((current) => {
			const next = { ...current };
			delete next[slotId];
			saveOverrides(next);
			return next;
		});
	}, []);

	const resetAll = useCallback(() => {
		clearOverrides();
		setOverrides({});
	}, []);

	const customizedCount = Object.keys(overrides).length;

	return {
		overrides,
		hydrated,
		assignSlot,
		toggleWorld,
		resetSlot,
		resetAll,
		customizedCount,
		persist,
	};
};
