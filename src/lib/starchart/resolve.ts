import { FALLBACK_SLOT_ID, getSlot } from "./slots";
import { getWorld } from "./worlds";
import type { ResolvedWorld, SlotId, StarChartOverrides, WorldId } from "./types";

/**
 * Stable hash of a string -> non-negative int. Used to pick which world a
 * multi-assigned slot shows, so the choice is steady within a day but differs
 * between days and between slots.
 */
const hash = (value: string): number => {
	let h = 2166136261;
	for (let i = 0; i < value.length; i += 1) {
		h ^= value.charCodeAt(i);
		h = Math.imul(h, 16777619);
	}
	return Math.abs(h);
};

/** Local calendar day, so rotation flips at the user's midnight, not UTC's. */
const dayKey = (now: Date): string =>
	`${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;

/**
 * Pick which world a slot shows right now.
 *
 * A slot with several assigned worlds rotates daily rather than picking at
 * random on every render — re-rendering must not swap the background out from
 * under someone mid-session.
 */
export const pickWorldForSlot = (
	slotId: SlotId,
	assigned: readonly WorldId[],
	now: Date = new Date()
): WorldId => {
	if (assigned.length === 1) return assigned[0];
	const index = hash(`${dayKey(now)}:${slotId}`) % assigned.length;
	return assigned[index];
};

/**
 * Resolve a weather slot to the world that should be displayed, honoring any
 * user customization. Falls back to the slot default, then to the temperate
 * clear-sky slot, so this never returns null for a slot the app can land in.
 */
export const resolveWorld = (
	slotId: SlotId,
	overrides: StarChartOverrides = {},
	now: Date = new Date()
): ResolvedWorld => {
	const slot = getSlot(slotId) ?? getSlot(FALLBACK_SLOT_ID)!;
	const assigned = overrides[slot.id];
	const customized = Array.isArray(assigned) && assigned.length > 0;

	const worldId = customized
		? pickWorldForSlot(slot.id, assigned, now)
		: slot.defaultWorld;

	// A stored world that no longer exists shouldn't blank the screen.
	const world = getWorld(worldId) ?? getWorld(slot.defaultWorld);

	if (!world) {
		return {
			slotId: slot.id,
			planet: "default",
			planetName: "",
			description: "",
			color: { primary: "#000000", headline: "#000000" },
			customized: false,
		};
	}

	const usingDefault = !customized && world.id === slot.defaultWorld;

	return {
		slotId: slot.id,
		planet: world.id,
		planetName: world.name,
		// Slot-specific copy only applies while the slot is untouched.
		description:
			usingDefault && slot.defaultDescription
				? slot.defaultDescription
				: world.description,
		color: world.color,
		customized,
	};
};
