import { getSlot } from "./slots";
import { isKnownWorld } from "./worlds";
import type { AtlasOverrides } from "./types";

const STORAGE_KEY = "galacticweather:atlas:v1";

/**
 * Drop anything we don't recognize. Stored assignments outlive deploys, so a
 * slot or world removed in a later release must not break the whole set —
 * the unknown entry is discarded and that slot falls back to its default.
 */
const sanitize = (raw: unknown): AtlasOverrides => {
	if (!raw || typeof raw !== "object") return {};

	const result: AtlasOverrides = {};

	for (const [slotId, value] of Object.entries(raw as Record<string, unknown>)) {
		if (!getSlot(slotId)) continue;
		if (!Array.isArray(value)) continue;

		const worlds = value.filter(
			(id): id is string => typeof id === "string" && isKnownWorld(id)
		);
		// De-dupe; an empty list is meaningless, so treat it as "not customized".
		const unique = Array.from(new Set(worlds));
		if (unique.length > 0) result[slotId] = unique;
	}

	return result;
};

export const loadOverrides = (): AtlasOverrides => {
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

export const saveOverrides = (overrides: AtlasOverrides): void => {
	if (typeof window === "undefined") return;
	try {
		window.localStorage.setItem(STORAGE_KEY, JSON.stringify(overrides));
	} catch {
		// Storage full or blocked — the in-memory set still works for this
		// session.
	}
};

export const clearOverrides = (): void => {
	if (typeof window === "undefined") return;
	try {
		window.localStorage.removeItem(STORAGE_KEY);
	} catch {
		/* no-op */
	}
};
