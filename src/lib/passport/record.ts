import type { ResolvedWorld } from "@/lib/atlas/types";
import type { Passport, Sighting, StampKind, WorldStamp } from "./types";

/** Local calendar date as "YYYY-MM-DD". */
export const localDate = (now: Date = new Date()): string => {
	const month = `${now.getMonth() + 1}`.padStart(2, "0");
	const day = `${now.getDate()}`.padStart(2, "0");
	return `${now.getFullYear()}-${month}-${day}`;
};

/**
 * A world resolved from a slot default was found in the wild; one the user
 * assigned themselves was chartered. `resolveWorld` already computes this —
 * `customized` is true exactly when the slot has an override.
 */
export const stampKind = (resolved: ResolvedWorld): StampKind =>
	resolved.customized ? "chartered" : "wild";

export interface SightingContext {
	city: string;
	tempF: number;
}

/**
 * Award a stamp for a world currently on screen.
 *
 * **Idempotent within a local day.** Calling this repeatedly for the same
 * world on the same day is a no-op that returns the passport unchanged (same
 * reference), which is what lets the caller fire it freely from an effect
 * without guarding, and lets the hook skip the write to localStorage. It also
 * means `count` can't be inflated by reloading the page — it counts distinct
 * days, not renders.
 *
 * The one thing that always applies, even on a repeat day, is recording a
 * *kind* not seen before: finding a charted world in the wild upgrades the
 * page immediately rather than waiting for tomorrow.
 *
 * Pure: never mutates its input.
 */
export const recordSighting = (
	passport: Passport,
	resolved: ResolvedWorld,
	context: SightingContext,
	now: Date = new Date()
): Passport => {
	// "default" is the placeholder the app renders before any weather lands.
	if (!resolved.planet || resolved.planet === "default") return passport;

	const today = localDate(now);
	const kind = stampKind(resolved);

	const sighting: Sighting = {
		date: today,
		city: context.city,
		slotId: resolved.slotId,
		tempF: Math.round(context.tempF),
	};

	const existing = passport[resolved.planet];

	if (!existing) {
		const stamp: WorldStamp = {
			worldId: resolved.planet,
			[kind]: sighting,
			count: 1,
			lastSeen: today,
		};
		return { ...passport, [resolved.planet]: stamp };
	}

	const isNewKind = existing[kind] === undefined;
	const isNewDay = existing.lastSeen !== today;

	if (!isNewKind && !isNewDay) return passport;

	const stamp: WorldStamp = {
		...existing,
		// First sighting of this kind only — a stamp records when you *first*
		// found a world, and nothing overwrites that date later.
		...(isNewKind ? { [kind]: sighting } : {}),
		count: isNewDay ? existing.count + 1 : existing.count,
		lastSeen: today,
	};

	return { ...passport, [resolved.planet]: stamp };
};
