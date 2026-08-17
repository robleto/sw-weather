# Atlas — continuation prompt

Paste everything below into the new thread.

---

I'm continuing work on the **Atlas** feature (formerly called "Star
Chart" — renamed because "Star Chart" implied astronomical navigation, not
what the feature does) for Galactic Weather. Here's everything you need;
assume you have no prior context.

## The app

Galactic Weather takes a real local forecast and matches it to a fictional
world — "Chicago feels like being on **KAMINO**" — over full-bleed painterly
planet art. It was formerly called Star Wars Weather and was renamed to remove
trademark exposure ahead of a paid tier.

Two independent repos under `/Users/greg.robleto/Dev/galactic-weather/`:

| | path | remote | stack |
|---|---|---|---|
| Web | `web-app/galactic-weather` | `robleto/galactic-weather` | Next.js 14.2.35, App Router, TypeScript, CSS Modules |
| iOS | `ios-app/galacticweather` | `robleto/galactic-weather-ios` | SwiftUI, XcodeGen |

Run the web app with:

```bash
cd ~/Dev/galactic-weather/web-app/galactic-weather && npm run dev
```

It needs geolocation permission, or use `http://localhost:3000/?city=Chicago`.

## Current state

- Web `main` = `d7ac6f9` — shipped, does **not** contain Atlas.
- Web `feat/weather-twin` = `3fcef78` — **Atlas, one clean commit,
  rebased directly onto `main`.** Merging is a plain fast-forward.
- iOS `main` = `f7e7720` — has **no** Atlas at all.

## What already exists on `feat/weather-twin`

The original `planetData.json` fused two concepts — the weather bucket and the
world shown for it — into one record, so nothing was reassignable. That was
split apart:

```
src/lib/atlas/types.ts     World, Slot, AtlasOverrides, ResolvedWorld
src/lib/atlas/worlds.ts    23 worlds: id, name, description, climate tag, colors
src/lib/atlas/slots.ts     22 weather buckets, each with a defaultWorld
src/lib/atlas/resolve.ts   (slotId, overrides) -> the world to display
src/lib/atlas/storage.ts   localStorage, key "galacticweather:atlas:v1"
src/app/hooks/useAtlas.ts  React state + persistence
src/app/components/Atlas.tsx   full-screen overlay, slots grouped by kind
src/app/components/PlanetPicker.tsx   bottom sheet: climate filters, search, multi-assign
src/app/styles/{Atlas,PlanetPicker}.module.css
```

`src/app/utils/weatherDescriptions.ts` was rewritten: it now exports
`getSlotForWeather()` returning only a slot id. Which *world* a slot shows is
`resolveWorld()`'s job, because the user can reassign it. `page.tsx` composes
the two.

### Design decisions worth preserving

- **Defaults reproduce the old mapping exactly.** Slot-specific copy is kept via
  `Slot.defaultDescription` and applies only while a slot is untouched (Hoth
  reads differently under "heavy snow" than under "clear · cold"). A
  user-assigned world brings its own description.
- **Multi-assign rotates daily, not randomly.** Assign several worlds to one
  slot and the choice is an FNV hash of the local calendar day + slot id.
  Random-per-render would swap the background mid-session. This is the thing
  that makes customizing an *upgrade* rather than a sidegrade — it preserves the
  surprise that makes the free app fun.
- **Stored assignments are sanitized on read.** Unknown slot/world ids are
  discarded so removing a world in a later release can't break someone's
  saved set.
- **Preview is full-bleed.** Hovering a world in the picker paints it behind the
  sheet. A 130px thumbnail badly undersells 4000×3000 artwork.
- Surfaces `coruscant`, `nur`, and `ahch-to`, which shipped as assets but were
  never mapped to any slot.

## Start here

**This code has never been run.** It passes `next build`, ESLint, and
TypeScript, but no one has clicked a single button in it. Verify before
building anything new, and check in this order:

1. The **normal forecast path** still works. Atlas rewrote
   `page.tsx`'s core render path from `getWeatherDescription` to
   `getSlotForWeather` + `resolveWorld`. If that's wrong the whole app breaks,
   not just the new feature. This is the real risk.
2. Atlas opens from the nav button and lists all 22 slots.
3. Reassigning a slot actually changes the landed screen's background.
4. Assignments survive a reload.

Expect to find bugs. Fix them first.

## Update: the below has since shipped

The rest of this section described the state as of the original handoff. It's
stale — since then: the paywall/gating model was settled (see the addendum
below) and built on iOS (`PremiumGate`, `PremiumStore`, one-time StoreKit
purchase, free = 1 editable slot, premium = all 22 + multi-assign); iOS got
full Atlas parity plus a premium-gated Saved Locations feature synced
via iCloud KVS; the 7 missing world gradients were added to
`planetStyles.module.css`; and web `feat/weather-twin` was merged into `main`,
so Atlas is live and free for everyone on web. Treat the bullets below
as historical context for *why* those things were built, not as an open task
list — check current `git log` on both repos before assuming anything here is
still outstanding.

- ~~No paywall, no gating.~~ Built — see the addendum.
- ~~iOS has no Atlas.~~ Built, with premium gating.
- 7 worlds (`at-attin`, `ghorman`, `jakku`, `kijimi`, `mortis`, `nur`, `yavin`)
  had no gradient class in `planetStyles.module.css` and fell back to
  `.default`. Fixed on both platforms.

## Product context

- **"Weather twin" vocabulary — resolved by the Atlas rename.** This was
  briefly muddled: the feature was called "Weather Twins" for a while, which
  collided with "weather twin" as the term for a single condition→world
  pairing, and made the phrase premium-only vocabulary sitting on a free nav
  button. Renaming the feature to **Atlas** untangles it, and that split is
  now the intended usage:
  - **Atlas** = the feature (the catalog of worlds and the screen for
    reassigning them). "Star Chart" was the original name; it implied
    astronomical navigation rather than what the feature does.
  - **weather twin** = one condition's matched world. Used in the picker
    header ("Weather twin for · Heavy snow") and for the premium
    multi-assign perk ("Weather Twin rotation").
  The free landed screen still says "<city> feels like being on" and should
  keep avoiding the phrase — not because it's paywalled vocabulary, but
  because the plain phrasing reads better cold.
- Planned premium perks beyond Atlas: saved locations (shipped on iOS
  since this was written), alternate app icons (iOS), home/lock-screen
  widgets, curated theme packs, share cards, an extended forecast rendered as
  a strip of different worlds, and a log of worlds you've actually
  experienced. That last one has since grown into a designed feature — the
  **Passport**, a scavenger hunt across all 23 worlds. It's specced in
  `PASSPORT.md` and nothing is built yet. It was called the "Holocron" here;
  renamed because a franchise word on a nav button and in store screenshots is
  a bigger IP surface than in-app planet names.
- One-time price for cosmetics vs. subscription for anything costing recurring
  API calls is an open decision.

## IP constraints — read before touching copy or art

The app was renamed off a trademark. Rules that still apply:

- **Never** put franchise names in the app name, metadata, keywords, README, or
  store listing. That was scrubbed deliberately.
- Planet names **inside the app** are a deliberate, accepted risk — leave them.
- The planet artwork is original (mine + AI), not screengrabs. Some images
  contain ships. Also accepted, because they're buried in-app and surface only
  when the weather matches.
- **The line is distribution surface, not in-app.** Anything broadcast —
  social/OG cards, App Store screenshots, marketing — must be pure landscape
  and architecture, no vehicle designs. An OG card was already replaced for
  exactly this reason.

## Environment constraints

A corporate DLP tool (BayCollector / bay-enforcer) blocks things silently and
irreversibly. Do not attempt workarounds for any of these:

- **Browser preview / MCP browser tools are blocked.** You cannot run or
  screenshot the web app. I have to verify visually myself — tell me what to
  check rather than trying another route.
- **iOS Simulator MCP tools are blocked.** `xcodebuild` is fine; launching or
  screenshotting the Simulator is not.
- **Never run `rm`, `rmdir`, or `git rm`** — with or without wildcards, even on
  your own temp files. Use `mv` to rename things out of the way instead.
- **Never read `.env` / `.env.local` from a shell command.** If something needs
  an env var, write a script that reads the file itself and never prints the
  value.
- iOS only: `project.yml` is XcodeGen's source of truth. The `.xcodeproj` is
  gitignored and regenerated, so build settings, bundle id, and Info.plist keys
  must be changed in `project.yml` or they get silently reverted.

Also: these repos previously lived in Dropbox, which destroyed a `.git`
directory (all 545 objects zeroed) and truncated several tracked files. They've
been moved to `~/Dev/`. If you see zero-byte files or git corruption, that's the
cause.
