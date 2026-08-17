import { isKnownWorld } from "@/lib/atlas/worlds";
import { canonicalSlotId } from "@/lib/atlas/slots";
import type { Passport, Sighting, WorldStamp } from "./types";

const STORAGE_KEY = "galacticweather:passport:v1";

const isRecord = (value: unknown): value is Record<string, unknown> =>
	typeof value === "object" && value !== null && !Array.isArray(value);

/**
 * A sighting is kept only if the parts the UI actually renders survived.
 *
 * `slotId` is deliberately not checked against the slot catalog: a slot
 * removed in a later release should cost the stamp its "earned on Heavy snow"
 * line, not the stamp. The UI looks it up defensively.
 */
const sanitizeSighting = (raw: unknown): Sighting | undefined => {
	if (!isRecord(raw)) return undefined;
	const { date, city, slotId, tempF } = raw;
	if (typeof date !== "string" || !date) return undefined;
	if (typeof city !== "string") return undefined;
	if (typeof slotId !== "string") return undefined;
	if (typeof tempF !== "number" || !Number.isFinite(tempF)) return undefined;
	// A renamed slot still described this stamp accurately when it was earned,
	// so carry it forward rather than letting the "earned on Dust & sand" line
	// quietly disappear from an old page.
	return { date, city, slotId: canonicalSlotId(slotId), tempF };
};

/**
 * Drop anything we don't recognize.
 *
 * This matters more here than it does for Atlas. Assignments are a preference
 * someone can redo in a minute; a passport is accumulated over months and is
 * the one thing in the app that can't be re-earned. So a world retired in a
 * later release costs exactly one page, never the book.
 */
const sanitize = (raw: unknown): Passport => {
	if (!isRecord(raw)) return {};

	const result: Passport = {};

	for (const [worldId, value] of Object.entries(raw)) {
		if (!isKnownWorld(worldId)) continue;
		if (!isRecord(value)) continue;

		const wild = sanitizeSighting(value.wild);
		const chartered = sanitizeSighting(value.chartered);
		// A stamp with neither sighting records nothing.
		if (!wild && !chartered) continue;

		const lastSeen =
			typeof value.lastSeen === "string" && value.lastSeen
				? value.lastSeen
				: (wild ?? chartered)!.date;

		const storedCount = value.count;
		const count =
			typeof storedCount === "number" && Number.isFinite(storedCount) && storedCount > 0
				? Math.floor(storedCount)
				: 1;

		const stamp: WorldStamp = { worldId, count, lastSeen };
		if (wild) stamp.wild = wild;
		if (chartered) stamp.chartered = chartered;

		result[worldId] = stamp;
	}

	return result;
};

export const loadPassport = (): Passport => {
	if (typeof window === "undefined") return {};
	try {
		const raw = window.localStorage.getItem(STORAGE_KEY);
		if (!raw) return {};
		return sanitize(JSON.parse(raw));
	} catch {
		// Corrupt or unavailable storage (private mode, quota) — start clean
		// rather than taking down the page.
		return {};
	}
};

export const savePassport = (passport: Passport): void => {
	if (typeof window === "undefined") return;
	try {
		window.localStorage.setItem(STORAGE_KEY, JSON.stringify(passport));
	} catch {
		// Storage full or blocked — the in-memory book still works for this
		// session.
	}
};

/** Exported for tests and for a future "reset" affordance; nothing calls it yet. */
export const clearPassport = (): void => {
	if (typeof window === "undefined") return;
	try {
		window.localStorage.removeItem(STORAGE_KEY);
	} catch {
		/* no-op */
	}
};

export const __testing = { sanitize, STORAGE_KEY };
