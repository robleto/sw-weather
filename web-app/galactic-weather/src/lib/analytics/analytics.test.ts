import { readFileSync } from "node:fs";
import { join } from "node:path";
import { beforeEach, describe, expect, it } from "vitest";
import {
	SIGNALS,
	atlasWorldAssignedPayload,
	forecastLandedPayload,
	passportStampEarnedPayload,
	stampCountBucket,
} from "./signals";
import { resolveClientId, __testing as idTesting } from "./clientId";
import { analyticsIsPermitted, analyticsTestMode, track, __testing } from "./analytics";

/**
 * Cross-platform parity, same arrangement as `slotMatrix.test.ts`.
 *
 * `shared/analytics-signals.json` is the agreed analytics contract;
 * `AnalyticsTests.swift` asserts the iOS port against the same file. Signal
 * names that drift produce two vocabularies in one dashboard, which is worse
 * than no analytics — the numbers look comparable and aren't.
 */

interface SignalSpec {
	name: string;
	platforms: string[];
	payload: string[];
}

interface AnalyticsFixture {
	payloadKeyAllowlist: string[];
	signals: SignalSpec[];
	stampCountProbes: Array<{ count: number; bucket: string }>;
}

const FIXTURE = join(
	__dirname,
	"..",
	"..",
	"..",
	"..",
	"..",
	"shared",
	"analytics-signals.json"
);

const fixture = JSON.parse(readFileSync(FIXTURE, "utf8")) as AnalyticsFixture;

const specFor = (name: string): SignalSpec => {
	const spec = fixture.signals.find((signal) => signal.name === name);
	if (!spec) throw new Error(`No fixture entry for signal "${name}"`);
	return spec;
};

describe("signal names", () => {
	it("sends exactly the signals the fixture declares for web", () => {
		const declared = fixture.signals
			.filter((signal) => signal.platforms.includes("web"))
			.map((signal) => signal.name)
			.sort();

		expect(Object.values(SIGNALS).slice().sort()).toEqual(declared);
	});

	it("does not send signals the fixture reserves for iOS", () => {
		const iosOnly = fixture.signals
			.filter((signal) => !signal.platforms.includes("web"))
			.map((signal) => signal.name);

		// Guards the assertion itself: if the fixture ever stops reserving
		// anything, the check above is the only one doing work and this test
		// would pass vacuously.
		expect(iosOnly).toContain("Premium.paywallShown");
		for (const name of iosOnly) {
			expect(Object.values(SIGNALS)).not.toContain(name);
		}
	});
});

describe("payloads", () => {
	const cases: Array<[string, Record<string, string>]> = [
		[SIGNALS.forecastLanded, forecastLandedPayload("snow")],
		[SIGNALS.atlasWorldAssigned, atlasWorldAssignedPayload("snow", "assign")],
		[SIGNALS.passportStampEarned, passportStampEarnedPayload("snow", "wild", 3)],
	];

	it("emits exactly the keys the fixture declares", () => {
		for (const [name, payload] of cases) {
			expect(Object.keys(payload).sort()).toEqual(specFor(name).payload.slice().sort());
		}
	});

	/**
	 * The privacy boundary, enforced rather than documented. A future payload
	 * that quietly starts carrying a city name or a world id fails here.
	 */
	it("never emits a key outside the allowlist", () => {
		for (const [, payload] of cases) {
			for (const key of Object.keys(payload)) {
				expect(fixture.payloadKeyAllowlist).toContain(key);
			}
		}
	});

	it("carries the slot, never the world", () => {
		const payload = passportStampEarnedPayload("clear_scorching", "chartered", 9);
		expect(payload.slotId).toBe("clear_scorching");
		expect(Object.values(payload)).not.toContain("tatooine");
	});

	it("buckets stamp totals rather than sending them exactly", () => {
		for (const probe of fixture.stampCountProbes) {
			expect(stampCountBucket(probe.count)).toBe(probe.bucket);
		}
	});
});

describe("client id", () => {
	const makeStore = (initial: Record<string, string> = {}) => {
		const data = { ...initial };
		return {
			data,
			getItem: (key: string) => data[key] ?? null,
			setItem: (key: string, value: string) => {
				data[key] = value;
			},
		};
	};

	const VALID = "3f2504e0-4f89-41d3-9a0c-0305e82c3301";

	it("reuses a stored id, so a returning visitor stays one person", () => {
		const store = makeStore({ [idTesting.STORAGE_KEY]: VALID });
		expect(resolveClientId(store, () => "generated")).toBe(VALID);
	});

	it("generates and persists an id on first visit", () => {
		const store = makeStore();
		expect(resolveClientId(store, () => VALID)).toBe(VALID);
		expect(store.data[idTesting.STORAGE_KEY]).toBe(VALID);
	});

	it("replaces an unrecognizable id rather than trusting it", () => {
		const store = makeStore({ [idTesting.STORAGE_KEY]: "not-a-uuid" });
		expect(resolveClientId(store, () => VALID)).toBe(VALID);
		expect(store.data[idTesting.STORAGE_KEY]).toBe(VALID);
	});
});

describe("opt-out signals", () => {
	it("stays off for Do Not Track and Global Privacy Control", () => {
		expect(analyticsIsPermitted({ doNotTrack: "1" })).toBe(false);
		expect(analyticsIsPermitted({ doNotTrack: "yes" })).toBe(false);
		expect(analyticsIsPermitted({ globalPrivacyControl: true })).toBe(false);
	});

	it("runs when neither is set", () => {
		expect(analyticsIsPermitted({ doNotTrack: null })).toBe(true);
		expect(analyticsIsPermitted({ doNotTrack: "0", globalPrivacyControl: false })).toBe(true);
	});
});

describe("test mode", () => {
	/**
	 * The Swift SDK tags DEBUG builds by itself; the JS SDK sets this for
	 * nobody. Without it, checking the wiring locally writes dev clicks into
	 * real data on the one metric this exists to measure.
	 */
	it("tags everything but a production build as test signals", () => {
		expect(analyticsTestMode("development")).toBe(true);
		expect(analyticsTestMode("test")).toBe(true);
		expect(analyticsTestMode(undefined)).toBe(true);
		expect(analyticsTestMode("production")).toBe(false);
	});
});

describe("track", () => {
	beforeEach(() => {
		__testing.reset();
	});

	/**
	 * `App.launched` fires on mount while the SDK is still loading. Dropping
	 * signals sent before startup settles would silently cost the retention
	 * measurement its first data point for every single visit.
	 */
	it("holds signals fired before startup settles, then flushes them", () => {
		const seen: Array<[string, unknown]> = [];
		track(SIGNALS.appLaunched);
		track(SIGNALS.forecastLanded, forecastLandedPayload("snow"));
		expect(seen).toHaveLength(0);

		__testing.useSink((name, payload) => seen.push([name, payload]));

		expect(seen).toEqual([
			[SIGNALS.appLaunched, undefined],
			[SIGNALS.forecastLanded, { slotId: "snow" }],
		]);
	});

	it("delivers straight through once started", () => {
		const seen: string[] = [];
		__testing.useSink((name) => seen.push(name));
		track(SIGNALS.atlasOpened);
		expect(seen).toEqual([SIGNALS.atlasOpened]);
	});

	it("bounds the queue so an unconfigured build cannot grow it forever", () => {
		for (let i = 0; i < 100; i += 1) track(SIGNALS.atlasOpened);
		expect(__testing.queueLength()).toBeLessThanOrEqual(20);
	});
});
