import type { SlotId, WorldId } from "@/lib/atlas/types";

/** One recorded encounter with a world. */
export interface Sighting {
	/** Local calendar date, "2026-08-17". Local, so a stamp is dated the day
	 *  the user experienced it, not the day UTC happened to be on. */
	date: string;
	/** The place whose forecast produced it, as it was shown on screen. */
	city: string;
	/** The weather bucket that earned it — "snow", "clear_scorching". */
	slotId: SlotId;
	tempF: number;
}

/**
 * How a world was found.
 *
 * `wild`      — the slot was at its default, so the forecast handed it to you.
 * `chartered` — you assigned this world to the slot in Atlas first. Still a
 *               real find (the weather had to actually happen), but you chose
 *               the destination, so it doesn't count toward the Wild book.
 */
export type StampKind = "wild" | "chartered";

/**
 * One page in the book. `wild` and `chartered` are separate optional fields
 * rather than a single sighting plus a kind, so a world charted today and
 * later found wild simply gains a second field — no precedence rule, no
 * migration, and both dates survive.
 */
export interface WorldStamp {
	worldId: WorldId;
	wild?: Sighting;
	chartered?: Sighting;
	/** Distinct days this world has been seen. See `recordSighting`. */
	count: number;
	lastSeen: string;
}

export type Passport = Record<WorldId, WorldStamp>;
