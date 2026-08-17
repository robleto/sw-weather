import { describe, expect, it } from "vitest";
import { SLOTS } from "@/lib/atlas/slots";
import { WORLDS } from "@/lib/atlas/worlds";
import type { ResolvedWorld, WorldId } from "@/lib/atlas/types";
import { localDate, recordSighting, stampKind } from "./record";
import { __testing } from "./storage";
import { blurbFor, buildProgress, huntStateFor, statusOf, WILD_REACHABLE_WORLDS } from "./progress";
import type { Passport } from "./types";

/**
 * The Passport's rules, which are pure by design precisely so they can be
 * checked here rather than by clicking through a browser.
 *
 * The Swift port carries the same cases in
 * `ios-app/.../galacticweatherTests/PassportTests.swift`; the two must agree
 * everywhere the semantics are shared. Merge behavior is iOS-only — the web
 * app has no cross-device sync to get wrong.
 */

const resolved = (
	planet: WorldId,
	{ slotId = "rain", customized = false } = {}
): ResolvedWorld => ({
	slotId,
	planet,
	planetName: planet,
	description: "",
	color: { primary: "", headline: "" },
	customized,
});

const wild = (planet: WorldId, slotId = "rain") => resolved(planet, { slotId });
const charted = (planet: WorldId, slotId = "rain") =>
	resolved(planet, { slotId, customized: true });

const day = (iso: string): Date => {
	const [year, month, date] = iso.split("-").map(Number);
	return new Date(year, month - 1, date, 12);
};

// ── recordSighting ──────────────────────────────────────────────────────────

describe("recordSighting", () => {
	it("creates a wild stamp on a first sighting, rounding the temperature", () => {
		const book = recordSighting({}, wild("kamino"), { city: "Chicago", tempF: 52.4 }, day("2026-08-17"));

		expect(book.kamino).toEqual({
			worldId: "kamino",
			wild: { date: "2026-08-17", city: "Chicago", slotId: "rain", tempF: 52 },
			count: 1,
			lastSeen: "2026-08-17",
		});
	});

	it("never mutates the passport it was given", () => {
		const before: Passport = {};
		recordSighting(before, wild("kamino"), { city: "Chicago", tempF: 52 }, day("2026-08-17"));
		expect(before).toEqual({});
	});

	it("returns the same reference on a repeat sighting the same day", () => {
		const first = recordSighting({}, wild("kamino"), { city: "Chicago", tempF: 52 }, day("2026-08-17"));
		const again = recordSighting(first, wild("kamino"), { city: "Seattle", tempF: 60 }, day("2026-08-17"));

		// Identity, not equality: this is what lets the caller fire it from an
		// effect without guarding, and lets the hook skip the localStorage write.
		expect(again).toBe(first);
	});

	it("bumps the count on a new day without moving the first-found record", () => {
		const first = recordSighting({}, wild("kamino"), { city: "Chicago", tempF: 52 }, day("2026-08-17"));
		const second = recordSighting(first, wild("kamino"), { city: "Seattle", tempF: 60 }, day("2026-08-18"));

		expect(second.kamino.count).toBe(2);
		expect(second.kamino.lastSeen).toBe("2026-08-18");
		expect(second.kamino.wild).toEqual({
			date: "2026-08-17",
			city: "Chicago",
			slotId: "rain",
			tempF: 52,
		});
	});

	it("files an assigned world as chartered, not wild", () => {
		const book = recordSighting({}, charted("ilum", "clear_freezing"), { city: "Yakutsk", tempF: -30 }, day("2026-08-17"));

		expect(book.ilum.chartered).toBeDefined();
		expect(book.ilum.wild).toBeUndefined();
		expect(statusOf(book.ilum)).toBe("chartered");
	});

	it("upgrades a chartered world to wild the same day it's found", () => {
		const charteredFirst = recordSighting({}, charted("ilum"), { city: "Yakutsk", tempF: -30 }, day("2026-08-17"));
		const upgraded = recordSighting(charteredFirst, wild("ilum"), { city: "Yakutsk", tempF: -30 }, day("2026-08-17"));

		expect(upgraded).not.toBe(charteredFirst);
		expect(upgraded.ilum.wild).toBeDefined();
		expect(upgraded.ilum.chartered?.date).toBe("2026-08-17");
		expect(upgraded.ilum.count).toBe(1);
		expect(statusOf(upgraded.ilum)).toBe("wild");
	});

	it("never stamps the pre-forecast placeholder", () => {
		expect(recordSighting({}, wild("default"), { city: "x", tempF: 0 })).toEqual({});
		expect(recordSighting({}, wild(""), { city: "x", tempF: 0 })).toEqual({});
	});

	it("reads the kind off `customized`", () => {
		expect(stampKind(wild("x"))).toBe("wild");
		expect(stampKind(charted("x"))).toBe("chartered");
	});
});

describe("localDate", () => {
	it("uses local calendar parts, not UTC", () => {
		// 11:30pm local on the 17th is already the 18th in UTC for the Americas.
		expect(localDate(new Date(2026, 7, 17, 23, 30))).toBe("2026-08-17");
	});

	it("zero-pads, and is therefore sortable", () => {
		expect(localDate(new Date(2026, 0, 5, 9))).toBe("2026-01-05");
	});
});

// ── storage sanitize ────────────────────────────────────────────────────────

describe("storage sanitize", () => {
	const { sanitize } = __testing;
	const good = { date: "2026-08-17", city: "Chicago", slotId: "rain", tempF: 52 };

	it("drops an unknown world id", () => {
		expect(sanitize({ atlantis: { wild: good, count: 1, lastSeen: "2026-08-17" } })).toEqual({});
	});

	it("drops a stamp with no sightings", () => {
		expect(sanitize({ kamino: { count: 9, lastSeen: "2026-08-17" } })).toEqual({});
	});

	it("survives junk input", () => {
		expect(sanitize("nonsense")).toEqual({});
		expect(sanitize(null)).toEqual({});
		expect(sanitize([1, 2, 3])).toEqual({});
	});

	it("repairs missing fields rather than rejecting the stamp", () => {
		const book = sanitize({ kamino: { wild: good } });
		expect(book.kamino.count).toBe(1);
		expect(book.kamino.lastSeen).toBe("2026-08-17");
	});

	it("repairs a nonsense count", () => {
		expect(sanitize({ kamino: { wild: good, count: -4, lastSeen: "x" } }).kamino.count).toBe(1);
		expect(sanitize({ kamino: { wild: good, count: 3.7, lastSeen: "x" } }).kamino.count).toBe(3);
	});

	it("drops a malformed sighting without taking the stamp with it", () => {
		const book = sanitize({
			kamino: { wild: { ...good, tempF: "warm" }, chartered: good, count: 2, lastSeen: "x" },
		});

		expect(book.kamino).toBeDefined();
		expect(book.kamino.wild).toBeUndefined();
		expect(book.kamino.chartered).toBeDefined();
	});

	it("keeps a stamp whose slot has since been retired", () => {
		// The slot only supplies a label. Losing it costs the stamp a line of
		// text, not the stamp.
		const book = sanitize({
			kamino: { wild: { ...good, slotId: "retired_slot" }, count: 1, lastSeen: "x" },
		});
		expect(book.kamino.wild).toBeDefined();
	});

	it("lets one bad page cost one page, never the book", () => {
		const book = sanitize({
			atlantis: { wild: good, count: 1, lastSeen: "x" },
			kamino: { wild: good, count: 1, lastSeen: "x" },
		});
		expect(Object.keys(book)).toEqual(["kamino"]);
	});

	it("takes worldId from the key rather than trusting the value", () => {
		expect(sanitize({ hoth: { worldId: "WRONG", wild: good } }).hoth.worldId).toBe("hoth");
	});

	it("round-trips what the app writes", () => {
		const original = recordSighting({}, wild("hoth", "snow"), { city: "Tromsø", tempF: 12 }, day("2026-01-09"));
		expect(sanitize(JSON.parse(JSON.stringify(original)))).toEqual(original);
	});
});

// ── hunt state ──────────────────────────────────────────────────────────────

describe("huntStateFor", () => {
	it("stays in hunting for most of the book", () => {
		expect(huntStateFor(0, 18, 0, 28)).toBe("hunting");
		expect(huntStateFor(14, 18, 14, 28)).toBe("hunting");
	});

	it("switches to closing with three or fewer wild worlds left", () => {
		expect(huntStateFor(15, 18, 15, 28)).toBe("closing");
		expect(huntStateFor(17, 18, 17, 28)).toBe("closing");
	});

	it("marks the Wild book done before the catalog is", () => {
		expect(huntStateFor(18, 18, 18, 28)).toBe("wildComplete");
		expect(huntStateFor(18, 18, 27, 28)).toBe("wildComplete");
	});

	it("only says complete when every world is found", () => {
		expect(huntStateFor(18, 18, 28, 28)).toBe("complete");
	});

	it("names no world in any state, so no line can go stale", () => {
		// The bug this replaced: a hardcoded "Hoth is easier in the hemisphere
		// having winter", still coaching you after Hoth was stamped.
		const names = WORLDS.map((w) => w.name);
		const copy = (["hunting", "closing", "wildComplete", "complete"] as const)
			.map((state) => blurbFor(state, 3))
			.join(" ");

		expect(names.filter((name) => copy.includes(name))).toEqual([]);
	});

	it("agrees with the counters buildProgress derived", () => {
		const progress = buildProgress({});
		expect(progress.state).toBe("hunting");
		expect(progress.blurb).toBe(blurbFor("hunting", 18));
	});
});

// ── progress ────────────────────────────────────────────────────────────────

describe("progress", () => {
	it("derives the wild-reachable set from slot defaults", () => {
		expect(WILD_REACHABLE_WORLDS).toEqual(new Set(SLOTS.map((slot) => slot.defaultWorld)));
		expect(WILD_REACHABLE_WORLDS.size).toBe(18);
	});

	it("keeps the charter-only worlds and the premium worlds as the same set", () => {
		// The free/premium split and the wild/chartered split are one line. If
		// this fails, either a premium world became reachable by forecast, or a
		// free world became unearnable — check slot defaults before this test.
		const charterOnly = WORLDS.filter((w) => !WILD_REACHABLE_WORLDS.has(w.id));
		expect(charterOnly.map((w) => w.id).sort()).toEqual(
			WORLDS.filter((w) => w.isPremium).map((w) => w.id).sort()
		);
	});

	it("covers the whole catalog with no empty pages", () => {
		const progress = buildProgress({});

		expect([progress.wildFound, progress.found]).toEqual([0, 0]);
		expect([progress.wildTotal, progress.total]).toEqual([18, WORLDS.length]);
		expect(progress.biomes.reduce((n, b) => n + b.total, 0)).toBe(WORLDS.length);
		expect(progress.biomes.reduce((n, b) => n + b.wildTotal, 0)).toBe(18);
		expect(progress.biomes.every((b) => b.total > 0)).toBe(true);
	});

	it("lets a free user complete the Wild book but not the catalog", () => {
		let book: Passport = {};
		for (const id of Array.from(WILD_REACHABLE_WORLDS)) {
			book = recordSighting(book, wild(id), { city: "Somewhere", tempF: 60 }, day("2026-08-17"));
		}

		const progress = buildProgress(book);
		expect([progress.wildFound, progress.wildTotal]).toEqual([18, 18]);
		expect([progress.found, progress.total]).toEqual([18, 28]);
	});

	it("fills the remaining pages by chartering, without moving the wild score", () => {
		let book: Passport = {};
		for (const id of Array.from(WILD_REACHABLE_WORLDS)) {
			book = recordSighting(book, wild(id), { city: "Somewhere", tempF: 60 }, day("2026-08-17"));
		}
		for (const world of WORLDS.filter((w) => !WILD_REACHABLE_WORLDS.has(w.id))) {
			book = recordSighting(book, charted(world.id), { city: "Somewhere", tempF: 60 }, day("2026-08-17"));
		}

		const progress = buildProgress(book);
		expect([progress.found, progress.total]).toEqual([28, 28]);
		expect(progress.wildFound).toBe(18);

		const ocean = progress.biomes.find((b) => b.climate === "ocean")!;
		expect([ocean.found, ocean.wild, ocean.total, ocean.wildTotal]).toEqual([5, 3, 5, 3]);
		expect(ocean.worlds.filter((w) => !w.wildReachable).map((w) => w.world.id).sort()).toEqual([
			"ahch-to",
			"nur",
		]);
	});
});
