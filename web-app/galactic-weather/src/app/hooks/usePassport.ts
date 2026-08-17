"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { loadPassport, savePassport } from "@/lib/passport/storage";
import { recordSighting, stampKind, type SightingContext } from "@/lib/passport/record";
import { buildProgress } from "@/lib/passport/progress";
import type { Passport } from "@/lib/passport/types";
import type { ResolvedWorld } from "@/lib/atlas/types";
import { track } from "@/lib/analytics/analytics";
import { SIGNALS, passportStampEarnedPayload } from "@/lib/analytics/signals";

/**
 * How long a world must stay on screen before it's stamped.
 *
 * Nothing on web can currently flick past worlds the way the iOS saved-location
 * pager can, so this is mostly parity insurance — but it also means a fast
 * search-and-retype doesn't leave a stamp for a city the user never read.
 */
export const DWELL_MS = 2000;

/**
 * Owns the user's Passport (the worlds they've actually landed on).
 *
 * Starts empty and hydrates from storage in an effect rather than during
 * render, so the server and first client render agree — same shape as
 * `useAtlas`.
 */
export const usePassport = () => {
	const [passport, setPassport] = useState<Passport>({});
	const [hydrated, setHydrated] = useState(false);

	/**
	 * Mirrors `passport`, updated synchronously.
	 *
	 * `record` needs to know whether a stamp was actually awarded so it can
	 * emit a signal for it, and deciding that inside a `setState` updater
	 * would put a side effect somewhere React is free to run twice — it does
	 * exactly that in StrictMode, which would double-count every stamp.
	 * Reading the current book from a ref keeps the decision out of the
	 * updater and the write purely a state assignment.
	 */
	const passportRef = useRef<Passport>({});

	useEffect(() => {
		const loaded = loadPassport();
		passportRef.current = loaded;
		setPassport(loaded);
		setHydrated(true);
	}, []);

	/**
	 * Award a stamp. Safe to call repeatedly — `recordSighting` returns the
	 * same object when there's nothing new, so a duplicate call neither
	 * re-renders nor writes.
	 */
	const record = useCallback((resolved: ResolvedWorld, context: SightingContext) => {
		const current = passportRef.current;
		const next = recordSighting(current, resolved, context);
		if (next === current) return;

		passportRef.current = next;
		savePassport(next);
		setPassport(next);

		track(
			SIGNALS.passportStampEarned,
			passportStampEarnedPayload(
				resolved.slotId,
				stampKind(resolved),
				Object.keys(next).length
			)
		);
	}, []);

	const progress = useMemo(() => buildProgress(passport), [passport]);

	return { passport, hydrated, record, progress };
};

export interface PendingSighting {
	resolved: ResolvedWorld;
	city: string;
	tempF: number;
}

/**
 * Stamps `pending` once it has held still for `DWELL_MS`.
 *
 * The timer is keyed on world + city, so re-renders don't restart it but
 * genuinely landing somewhere new does. Pass `null` to hold off entirely —
 * the caller must do that until the passport has hydrated, or a stamp awarded
 * against the empty initial state would be written over the stored book.
 */
export const useStampOnDwell = (
	record: (resolved: ResolvedWorld, context: SightingContext) => void,
	pending: PendingSighting | null
) => {
	const latest = useRef(pending);
	const recordRef = useRef(record);

	useEffect(() => {
		latest.current = pending;
		recordRef.current = record;
	});

	const key = pending ? `${pending.resolved.planet}:${pending.city}` : null;

	useEffect(() => {
		if (!key) return;

		const timer = window.setTimeout(() => {
			const sighting = latest.current;
			if (!sighting) return;
			recordRef.current(sighting.resolved, {
				city: sighting.city,
				tempF: sighting.tempF,
			});
		}, DWELL_MS);

		return () => window.clearTimeout(timer);
	}, [key]);
};
