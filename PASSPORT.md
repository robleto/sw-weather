# Passport — design spec

Status: **built on both platforms, run on neither.** Supersedes the "Holocron"
bullets in `ATLAS-HANDOFF.md` and `ATLAS-HANDOFF-ADDENDUM.md`, which were the
only prior record of this idea (two passing mentions, no spec).

Read `ATLAS-HANDOFF.md` first for the Atlas architecture this sits on top of.

Web passes `tsc --noEmit`, `next lint`, `next build`, and `vitest run`; iOS
passes `xcodebuild test`. The rules are covered by committed tests on both
sides — `src/lib/passport/passport.test.ts` (34 cases) and
`galacticweatherTests/PassportTests.swift` (33). But **nobody has clicked
either one** — browser tooling and Simulator control are both DLP-blocked in
the environment this was written in. Everything below describes code that
exists. See "Verify before building on this."

---

## What it is

A scavenger hunt for worlds. You collect a world by **actually landing on a
screen where it's showing** — which means the real forecast somewhere on Earth
had to match that world's weather at the moment you looked. Each find is a
stamp: the world, the biome, the city you were looking at, the date, and the
weather that earned it.

Atlas is the map of where worlds *could* appear. Passport is the record of
where you've actually been.

## Why it works

**Real global weather is the game board.** The app already searches any city on
Earth, and the forecast decides the world. That turns the world catalog into a
hunt with no content to author:

- Hoth in July means searching the southern hemisphere.
- Exegol means finding a thunderstorm that is happening *right now*, somewhere.
- Mustafar's clear-sky stamp needs 99°F, which in January means a short list of
  places on the planet.

Nothing about this needs a backend, a season pass, or new artwork. It's a
second reading of data the app already fetches. That's the whole appeal — it
costs one localStorage key and makes the search field, which is currently a
utility, into the primary toy.

## Naming: Passport, not Holocron

The handoff docs call this the "Holocron." **Renaming to Passport**, for two
reasons:

1. **IP surface.** `ATLAS-HANDOFF.md` draws the line at *distribution surface* —
   in-app planet names are an accepted risk, but anything broadcast is not.
   A feature name is not in the same category as a planet name buried behind a
   weather match: it sits on a nav button, in App Store screenshots, in the
   listing text, and probably in a keyword. That's the exact surface the app was
   renamed off a trademark to protect.
2. **It writes the UI for itself.** Pages, stamps, dates, cities, "places
   you've been" — the metaphor answers layout questions before they're asked.
   "Holocron" answers none of them.

Pairs cleanly with the existing vocabulary: **Atlas** = the map of worlds,
**Passport** = where you've been, **weather twin** = one condition's world.

---

## The load-bearing fact: 16 wild, 7 charter-only

Audited against `src/lib/atlas/{worlds,slots}.ts` at web `302fb55`:

- 23 worlds, 22 slots, **16 distinct slot defaults**.
- The 7 worlds that are *never* any slot's default are **exactly the 7 premium
  worlds**: Ahch-To, Alderaan, Coruscant, Ilum, Jakku, Mortis, Nur.

That's not luck — the addendum reassigned three slot defaults away from premium
worlds (Ilum→Hoth, Mortis→Endor, Alderaan→Naboo) specifically to keep the free
experience unchanged. The side effect is a clean two-tier hunt that needs no new
gating logic:

| | worlds | how you get them | who can |
|---|---|---|---|
| **Wild** | 16 | The forecast served it to you at a slot's default | everyone, free |
| **Chartered** | 7 | You own the world, assigned it in Atlas, then lived through that weather | premium (iOS) |

**A free user can complete a full Wild book — all 16, no purchase.** That is the
point. The paywall isn't a wall across the hunt; it's seven more pages at the
back of a book you already finished.

### Reachability check (all 16 wild worlds are genuinely findable)

Every wild world has at least one slot that real weather hits regularly. The
hardest is **Mustafar** — `clear_scorching` needs ≥99°F clear, or the rare
`smoke` condition. **Kijimi** needs the API to say *light* snow specifically.
Everything else is a normal day somewhere. Hoth is the easiest rare-feeling one:
it holds three slots (`snow`, `clear_cold`, `clear_freezing`).

No wild world is unreachable. Worth re-running the audit any time slot defaults
change — a reassignment can strand a world silently.

### Biome pages

`World.climate` already gives 9 biomes, no new data:

| biome | worlds | wild | roster |
|---|---|---|---|
| ocean | 5 | 3 | Ahch-To\*, Kamino, Niamos, Nur\*, Scarif |
| forest | 4 | 4 | Dagobah, Endor, Kashyyyk, Yavin 4 |
| temperate | 3 | 2 | Alderaan\*, At-Attin, Naboo |
| ice | 3 | 2 | Hoth, Ilum\*, Kijimi |
| urban | 2 | 1 | Coruscant\*, Ghorman |
| storm | 2 | 1 | Exegol, Mortis\* |
| desert | 2 | 1 | Jakku\*, Tatooine |
| sky | 1 | 1 | Bespin |
| volcanic | 1 | 1 | Mustafar |

\* = premium, charter-only.

Forest is the only biome completable wild. That asymmetry is fine and even
useful — it gives the premium pages an obvious shape ("1 world from complete").

---

## Data model

One record per world, not an append-only event log. A log grows without bound
and the UI only ever renders first-found plus a count.

```ts
interface Sighting {
  date: string;       // ISO local date, "2026-08-17"
  city: string;       // display name as shown, "Reykjavík"
  slotId: SlotId;     // what weather earned it — "snow", "clear_scorching"
  tempF: number;      // rounded, for stamp flavor
}

interface WorldStamp {
  worldId: WorldId;
  wild?: Sighting;        // first time found at a slot default
  chartered?: Sighting;   // first time seen via a user assignment
  count: number;          // total sightings, both kinds
  lastSeen: string;       // ISO local date
}

type Passport = Record<WorldId, WorldStamp>;
```

Holding `wild` and `chartered` as separate optional fields makes the upgrade
path free: chart Ilum, see it, later find it wild (if defaults ever change) and
it simply gains a second field. No migration, no precedence rule.

**Storage** — key `galacticweather:passport:v1` on both, sanitize-on-read on
both. That matters more here than for Atlas: a passport accumulates over
months, so a world removed in a later release must cost one stamp, not the
book.

- Web — `localStorage`.
- iOS — `NSUbiquitousKeyValueStore` mirrored to `UserDefaults`. iCloud KVS
  caps at 1 MB; 23 stamps is ~4 KB.

### iOS must not copy AtlasStorage's sync rule

**This is the one place the port genuinely diverges, and it's a data-loss bug
if it's ever "simplified" back into parity.**

`AtlasStorage.load()` prefers iCloud wholesale — correct for Atlas, where the
data is a *preference*: the most recent edit is the one the user meant, and a
lost edit costs a few taps. A Passport is *accumulated history*. A stamp is
earned by being somewhere at a moment that has passed, and cannot be re-earned
at all.

The concrete failure: phone earns Kamino on a flight with no signal; iPad
meanwhile earns Hoth and syncs. Under last-writer-wins the phone's next read
adopts iCloud wholesale and drops Kamino on the floor, permanently.

So `PassportStorage` **merges** on every read and every remote change:

- stamps union — neither side's worlds are ever dropped
- for a world on both sides, the **earlier** `wild` and the **earlier**
  `chartered` sighting win, so a first-found date never moves later
- `count` takes the max, not the sum (summing double-counts a day both devices
  saw; under-counting a genuinely split day is the safer error)
- `lastSeen` takes the latest — ISO dates are zero-padded, so string order is
  chronological order

`PassportViewModel` merges the remote payload against its own in-memory book
too, so a stamp earned in the seconds around a remote change survives. Merge
is verified commutative and idempotent.

## Stamp rules

**Award point.** The single place a world becomes visible:

- Web — `page.tsx`, after `weatherInfo` resolves and `weatherData` is non-null.
- iOS — `WeatherViewModel.resolvedWorld(for:overrides:)`, for the **selected**
  page only, plus `resolvedPreviewWorld`.

**Wild vs. Chartered** is already computed. `ResolvedWorld.customized` is true
exactly when the slot has a user override. `customized === false` → Wild;
`true` → Chartered. No new resolution logic, no new state.

**A searched city counts.** Searching other places is the hunt, not a loophole —
it's the literal mechanic ("find it from a different destination"). This
includes the iOS preview page, which isn't a saved location.

**Dwell before stamping.** On iOS, saved locations are a swipeable pager; a fast
swipe through five cities should not machine-gun five stamps for worlds the user
never looked at. Require the page to be selected and loaded for a short dwell
(~2s) before awarding. Web has one screen at a time, but apply the same rule so
the two implementations don't drift.

**First open stamps immediately.** Existing users start with an empty book and
whatever world is on screen. That's the right onboarding beat — the feature
introduces itself with a stamp rather than an empty state.

**Never un-stamp.** Nothing revokes a stamp — not resetting Atlas, not a lapsed
entitlement, not a world going premium in a later release. This follows the
precedent already set in `PremiumGate.isSavedLocationUnlocked`: a billing event
never destroys something the user made.

## UI

**Web** — nav button beside Atlas, with a count badge in the style of
`styles.atlasCount`: `Passport 12`. Opens a full-screen overlay like `Atlas.tsx`.

**iOS** — an entry in `MenuScreen`, next to Atlas and Saved Locations.

**The book itself**, both platforms — 9 biome pages, `SLOT_GROUP_ORDER`-style
fixed ordering. Each page is a grid of stamps:

- **Found (wild)** — full-color, world name, city, date, and the weather that
  earned it. Solid ink.
- **Found (chartered)** — same information, visibly a different stamp: outline
  rather than solid, "chartered" ribbon. Legible as a real find that you steered
  toward, because that's what it is.
- **Not yet found** — greyed, *named*. The Atlas picker already lists every
  world, so hiding names buys nothing and costs the hunt its target list.
- **Locked (iOS free, premium worlds)** — greyed with the lock chip already
  built for the picker (`PremiumLockChip`). An unfinished ocean page with two
  locked slots is the best paywall argument the app has, and it costs nothing to
  make.

Header shows both counters, because they mean different things:
`Wild 14/16 · Complete 14/23`.

## Gating (iOS)

Two capability questions in `PremiumGate`, and no enforcement anywhere else:

- `canOpenPassport` — always true. Collecting is the retention hook and a
  half-finished book is the paywall's best argument.
- `isPassportPageLocked(world:found:)` — takes `found`, so a stamp already
  earned never renders as locked. Same principle as
  `isSavedLocationUnlocked`: nothing a user actually collected disappears
  because of an entitlement check.

Nothing else needs gating, which is the nice part. The seven premium worlds are
no slot's default, so a forecast can never serve one up, and `canUseWorld`
already stops a free user assigning one. **The book gates itself** — the lock
chips are signage over a door that was already shut.

Web stays entirely ungated per the addendum — and note that on web, where every
world is assignable, all 23 are chartered-reachable. That's correct: web is the
demo that sells the iOS app.

## Where it hooks in

Nothing here rewrites an existing render path — the Atlas rebuild already did
that work, and this is a read of its output.

**Web — built.** New files mirror `lib/atlas/` exactly:

```
src/lib/passport/types.ts       Sighting, WorldStamp, Passport
src/lib/passport/storage.ts     localStorage + sanitize, key :passport:v1
src/lib/passport/record.ts      recordSighting() — pure, idempotent per day
src/lib/passport/progress.ts    WILD_REACHABLE_WORLDS + per-biome counters
src/app/hooks/usePassport.ts    state, persistence, useStampOnDwell
src/app/components/Passport.tsx overlay, biome pages
src/app/styles/Passport.module.css
```

Touched: `page.tsx` (hook, dwell call, nav button, overlay),
`page.module.css` (`.atlasButton`/`.atlasCount` generalized to
`.navAction`/`.navCount` now that two buttons share them, plus a `.navActions`
row), `lib/atlas/worlds.ts` (`CLIMATE_LABELS` lifted out of `PlanetPicker` so
both surfaces share one list, plus `CLIMATE_ORDER`), `PlanetPicker.tsx`
(imports those instead of defining them).

**iOS — built.** Mirrors the web lib, as Atlas does:

```
galacticweather/Passport/PassportTypes.swift     Sighting, StampKind, WorldStamp
galacticweather/Passport/PassportRecord.swift    recordSighting() — pure
galacticweather/Passport/PassportStorage.swift   iCloud KVS + UserDefaults + merge
galacticweather/Passport/PassportProgress.swift  WILD_REACHABLE_WORLDS + counters
galacticweather/ViewModels/PassportViewModel.swift
galacticweather/Views/Passport/PassportView.swift
```

Touched: `ContentView.swift` (owns the view model, `pendingSighting`, the
dwell task), `SavedLocationsView.swift` (menu entry + cover),
`PremiumGate.swift` (`canOpenPassport`, `isPassportPageLocked`).

Three deliberate departures from the web version, none of them arbitrary:

- **`recordSighting` returns `Passport?`**, nil meaning "nothing changed."
  Web signals that by returning the same object reference, which a Swift value
  type has no equivalent for.
- **The dwell is `.task(id:)`, not a timer.** Changing the id cancels the
  in-flight task, so a fast swipe through the saved-location pager cancels
  before the sleep finishes and leaves no stamps. This is the case web doesn't
  have and the reason the dwell exists at all.
- **`PassportView` uses `MenuScreen` chrome, not `AtlasView`'s full-bleed
  backdrop.** The web book paints the hovered world behind itself; there is no
  hover on a phone, so a dark legible list is the honest translation rather
  than a backdrop with no trigger.

`record.ts` and `Record.swift` should stay pure `(passport, resolved, context)
-> passport` so the rules are testable without a browser or a Simulator —
which matters, because neither can be driven in this environment (see
"Environment constraints" in `ATLAS-HANDOFF.md`).

---

## Verify before building on this

The pure rules are tested; the wiring and every pixel are not. Check in this
order — item 1 on each platform is the only thing that can break the existing
app.

**Web**

1. **The normal forecast path still works.** `page.tsx` gained a hook, a dwell
   call, and a nav button. If the landed screen renders as it did before this
   feature existed, the risk is behind you.
2. **A stamp appears.** Land somewhere, wait ~2s, open Passport. One world
   should be filled in and the nav badge should read `1`.
3. **It survives a reload**, and the count does *not* climb on repeated
   reloads the same day — that's the idempotence rule, and it's the one the
   UI can contradict even though the unit checks pass.
4. **Chartered renders differently.** Reassign a slot in Atlas, land on that
   weather, and confirm the stamp shows a dashed border and a "Chartered" tag,
   and that the "found wild" score does *not* move.
5. **Nav fits on a phone.** Two buttons now share the bar with the title and
   the search field at 560px and below. This is the most likely thing to be
   visibly wrong, and nothing in the toolchain can catch it.
6. **Hovering a found stamp** paints that world full-bleed behind the book;
   unfound ones deliberately don't.
7. **The blurb reads right at each stage.** Only `hunting` shows up naturally;
   to see the others, paste a book into `localStorage` under
   `galacticweather:passport:v1` and reload. Worth doing once for
   `wildComplete`, which is the app's only acknowledgement that you finished
   the free hunt. Same copy on both platforms — checking it on web covers iOS.

**iOS**

1. **The pager still works.** `ContentView` gained a view model, two computed
   properties, and a `.task(id:)`. Swiping between saved locations and the
   throw-to-dismiss gesture should be untouched.
2. **A stamp appears** after ~2s on a landed page, and the menu row reads
   `Passport (1/16 wild)`.
3. **Swiping fast leaves nothing behind.** Flick through several saved
   locations without pausing — no stamps. Pause on one — one stamp. This is
   the whole reason the dwell exists and the one behavior with no web
   equivalent.
4. **A searched city counts.** Search a place, don't save it, wait on the
   preview — it should stamp.
5. **Locked pages.** As a free user, premium worlds show a lock chip; the
   charter-only hint line does not appear alongside it as redundant noise.
6. **iCloud merge.** The one that needs two devices: earn a stamp on each with
   the other offline, then bring both online. Both stamps must survive. If
   only one device is available, at least confirm a stamp survives a delete
   and reinstall (iCloud restores it).

## Known gaps

- **Midnight rollover with the page left open.** The dwell timer is keyed on
  world + city, so a browser sitting on one city overnight won't bump `count`
  until something changes or the page reloads. The world is already stamped by
  then, so the cost is one missed increment on a decorative number. Not worth
  a timer.
- **No reset or export.** `clearPassport()` exists and nothing calls it.
- **The tests are unit tests only.** The rules are covered; the wiring
  (`usePassport`, `useStampOnDwell`, `ContentView.pendingSighting`, both
  views) has no coverage and no easy path to it without a browser or a
  Simulator. `PassportStorage.decodeForTesting` is the one seam added for
  testing, `#if DEBUG` only.
- **The iCloud merge is tested as a pure function, not against real iCloud.**
  `merge` is proven commutative, idempotent, and non-destructive, but nothing
  here exercises `NSUbiquitousKeyValueStore` itself. Two-device behavior is
  item 6 on the iOS checklist for a reason.
- **iOS temperatures are stored as Fahrenheit** to match the web schema, and
  converted for display when the user prefers Celsius. Converting an
  already-rounded value can land a degree off on an old stamp. Storing Kelvin
  would fix it and break schema parity; not worth it for a decorative line.

## Open questions

1. **Dwell duration.** 2s is a guess. Long enough to not fire mid-swipe, short
   enough that a real look always counts.
2. **Home vs. away.** A passport records foreign travel. Marking stamps earned
   at your device location differently from ones earned in a searched city is
   thematically right and might be one field (`away: boolean`) — or might be a
   distinction nobody asked for. Cheap to add later, so defaulting to *not now*.
3. **Hints — settled, mostly.** Naming a *target* is still deferred, for the
   original reason: it hands over the answer, which is the fun.

   The distinction that took a bug to find: the line under the score isn't a
   hint, it's onboarding. It teaches that you can go looking. The first build
   hardcoded "Hoth is easier in the hemisphere having winter" — vivid once,
   then permanently coaching you toward a world you already had, and naming
   one of the easiest worlds in the catalog at that.

   Replaced with a four-state machine (`huntStateFor` / `blurbFor` in
   `progress.ts` and `PassportProgress.swift`) that names a *strategy* and
   never a world: **hunting** → **closing** (≤3 wild left) → **wildComplete**
   → **complete**. `wildComplete` also marks finishing 16/16, which otherwise
   passed unremarked.

   The copy lives in the shared lib rather than the two views, so the books
   can't drift; a test on each side asserts no blurb contains any world name.
   Nothing checks the two platforms' strings against *each other* — that's
   convention, same as the weather-mapper tests. They were verified identical
   by hand when written.

   Still open: a genuine per-world hint for someone stalled on their last
   stamp. Only worth building if the data shows books stalling.
4. **Share cards.** A completed biome page is the most shareable artifact the
   app could produce, and share cards are already on the premium list. Must
   follow the IP rule: landscape and architecture only, no vehicles.
5. **Widgets.** "Latest stamp" is an obvious lock-screen widget and it's already
   in the premium bundle.
6. **Export / reset.** Probably needed eventually. No reason to block on it.

## Deliberately not doing

- **No streaks, no daily login reward, no points.** The hunt's pull is that the
  weather is real. A streak counter would make it a chore app.
- **No leaderboards or social.** That's the one item on the whole roadmap that
  forces accounts and a backend, and the addendum is explicit about where that
  line sits.
- **No new artwork or worlds required to ship this.** The addendum plans 30–40
  more worlds later; each one adds a page to an existing book for free. Worth
  auditing at that point whether new worlds get a slot default (wild) or stay
  charter-only (premium) — that choice is now also a game-design decision, not
  just a monetization one.
