"use client";

import type { SignalPayload } from "./signals";
import { loadClientId } from "./clientId";

type Sink = (name: string, payload?: SignalPayload) => void;

/**
 * `idle` before `startAnalytics` runs, `starting` while the SDK loads, then
 * settled to `on` or `off` forever.
 *
 * The distinction between "not started yet" and "started and disabled" is what
 * makes the queue below safe: signals fired during startup are held, signals
 * fired when analytics is off are dropped on the floor.
 */
type Status = "idle" | "starting" | "on" | "off";

let status: Status = "idle";
let sink: Sink | null = null;
let queue: Array<[string, SignalPayload | undefined]> = [];

/**
 * Bounded so a misconfigured build that never settles can't grow this without
 * limit. Nothing legitimate fires twenty signals before the SDK finishes
 * loading; if it somehow did, losing the tail is the right failure.
 */
const MAX_QUEUED = 20;

/**
 * Honor Do Not Track and Global Privacy Control.
 *
 * Neither is legally binding for this kind of measurement in most places, and
 * plenty of analytics vendors ignore both. Respecting them costs one branch,
 * and it means the privacy policy's claim is enforced by the code rather than
 * by good intentions.
 */
/**
 * Whether signals should be tagged as test signals.
 *
 * The Swift SDK does this for itself — anything compiled in DEBUG is tagged,
 * so running from Xcode can't pollute real data. The JavaScript SDK supports
 * the same flag but sets it for nobody, which makes this the one place the two
 * platforms would behave differently for the same act: putting the app ID in a
 * local `.env.local` to check the wiring would write dev clicks into the real
 * dataset, permanently, on the very metric this exists to measure.
 *
 * `next dev` runs with NODE_ENV "development"; `next build` sets "production".
 * So local is test, the deployed site is real, matching iOS exactly.
 */
export const analyticsTestMode = (nodeEnv: string | undefined): boolean =>
	nodeEnv !== "production";

export const analyticsIsPermitted = (signals: {
	doNotTrack?: string | null;
	globalPrivacyControl?: boolean;
}): boolean => {
	if (signals.globalPrivacyControl === true) return false;
	const dnt = signals.doNotTrack;
	if (dnt === "1" || dnt === "yes") return false;
	return true;
};

const flush = () => {
	const pending = queue;
	queue = [];
	if (!sink) return;
	for (const [name, payload] of pending) sink(name, payload);
};

const disable = () => {
	status = "off";
	sink = null;
	queue = [];
};

/**
 * Start analytics, or decide not to. Safe to call repeatedly; only the first
 * call does anything.
 *
 * Every branch that isn't "explicitly configured and permitted" ends in a
 * no-op: no app ID (the default for local development and for anyone who
 * clones this), no storage to hold an identifier, DNT/GPC set, or an SDK that
 * fails to load. Analytics is never allowed to be the reason the page breaks.
 */
export const startAnalytics = async (): Promise<void> => {
	if (status !== "idle") return;
	status = "starting";

	if (typeof window === "undefined") return disable();

	const appID = process.env.NEXT_PUBLIC_TELEMETRYDECK_APP_ID;
	if (!appID) return disable();

	if (
		!analyticsIsPermitted({
			doNotTrack: window.navigator.doNotTrack,
			globalPrivacyControl: (
				window.navigator as Navigator & { globalPrivacyControl?: boolean }
			).globalPrivacyControl,
		})
	) {
		return disable();
	}

	const clientUser = loadClientId();
	if (!clientUser) return disable();

	try {
		const { default: TelemetryDeck } = await import("@telemetrydeck/sdk");
		const td = new TelemetryDeck({
			appID,
			clientUser,
			testMode: analyticsTestMode(process.env.NODE_ENV),
		});
		sink = (name, payload) => {
			// The SDK returns a promise; a rejected one must not surface as an
			// unhandled rejection in the user's console over a metric.
			void td.signal(name, payload).catch(() => {});
		};
		status = "on";
		flush();
	} catch {
		disable();
	}
};

/**
 * Record a signal. Never throws, never blocks, and does nothing at all until
 * `startAnalytics` has settled `on`.
 */
export const track = (name: string, payload?: SignalPayload): void => {
	if (status === "on") {
		sink?.(name, payload);
		return;
	}
	if (status === "off") return;
	if (queue.length >= MAX_QUEUED) return;
	queue.push([name, payload]);
};

export const __testing = {
	reset: () => {
		status = "idle";
		sink = null;
		queue = [];
	},
	/** Settle into `on` with a fake sink, skipping the real SDK. */
	useSink: (fake: Sink) => {
		status = "on";
		sink = fake;
		flush();
	},
	status: () => status,
	queueLength: () => queue.length,
};
