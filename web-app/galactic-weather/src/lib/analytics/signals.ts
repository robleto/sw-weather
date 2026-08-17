import type { SlotId } from "@/lib/atlas/types";
import type { StampKind } from "@/lib/passport/types";

/**
 * The signals this app sends, and the only ones it sends.
 *
 * Names and payload keys are fixed by `shared/analytics-signals.json`, which
 * the iOS port is held to as well — see the fixture's own comment for why.
 * `Premium.paywallShown` is absent here on purpose: the web app has no premium
 * tier, so it is declared iOS-only in the fixture and the parity test expects
 * it to be missing from this object.
 */
export const SIGNALS = {
	appLaunched: "App.launched",
	forecastLanded: "Forecast.landed",
	atlasOpened: "Atlas.opened",
	atlasWorldAssigned: "Atlas.worldAssigned",
	passportStampEarned: "Passport.stampEarned",
} as const;

export type SignalName = (typeof SIGNALS)[keyof typeof SIGNALS];

/**
 * TelemetryDeck coerces payload values to strings, so they are strings here
 * rather than being stringified at the boundary — a number in this type would
 * be a lie about what arrives at the other end.
 */
export type SignalPayload = Record<string, string>;

/**
 * Stamp totals are bucketed rather than sent exactly.
 *
 * An exact count is a surprisingly good fingerprint once it gets large — "the
 * user with 37 stamps" is one person. Buckets answer the only question being
 * asked (is the collection loop engaging anyone, or does everyone stall at
 * one?) without carrying that.
 *
 * Clamps below 1: a stamp total should never be zero at the moment one is
 * earned, but an unlabelled bucket would be worse than a wrong one.
 */
export const stampCountBucket = (count: number): string => {
	if (count <= 1) return "1";
	if (count <= 5) return "2-5";
	if (count <= 15) return "6-15";
	return "16+";
};

/**
 * Which world someone landed on is deliberately not sent — the slot is.
 *
 * A slot ("snow", "clear_scorching") answers the same product question in
 * generic weather vocabulary. World names are the catalog's documented IP
 * exposure, and shipping them to a third party would create an external record
 * of that association for no analytical gain.
 */
export const forecastLandedPayload = (slotId: SlotId): SignalPayload => ({ slotId });

export const atlasWorldAssignedPayload = (
	slotId: SlotId,
	action: "assign" | "unassign"
): SignalPayload => ({ slotId, action });

export const passportStampEarnedPayload = (
	slotId: SlotId,
	kind: StampKind,
	totalStamps: number
): SignalPayload => ({
	slotId,
	kind,
	totalStamps: stampCountBucket(totalStamps),
});
