# Atlas — context and current state

**Atlas has shipped on both platforms.** This file was originally a
continuation prompt for *building* it, and read as one long after it stopped
being true. It is now a context document: the decisions behind the feature, the
IP rules, and the environment constraints — the parts that are still load-bearing.

Facts below were checked against the code on 17 August 2026. Where an earlier
claim was wrong rather than merely dated, it has been corrected in place rather
than struck through: a stack of supersede-notes is how this document became
misleading in the first place.

## The app

Galactic Weather takes a real local forecast and matches it to a fictional
world — "Chicago feels like being on **KAMINO**" — over full-bleed painterly
planet art. It was formerly called Star Wars Weather and was renamed to remove
trademark exposure ahead of a paid tier.

**One monorepo**, at `/Users/greg.robleto/Dev/galactic-weather/`, with a single
`.git` at the root and two remotes. It was two independent repositories when
this document was first written; they were combined in `c529552`.

| | path | remote | stack |
|---|---|---|---|
| Web | `web-app/galactic-weather` | `origin` → `robleto/galactic-weather` | Next.js 14.2.35, App Router, TypeScript, CSS Modules |
| iOS | `ios-app/galacticweather` | `ios-origin` → `robleto/galactic-weather-ios` | SwiftUI, XcodeGen |

Run the web app with:

```bash
cd ~/Dev/galactic-weather/web-app/galactic-weather && npm run dev
```

It needs geolocation permission, or use `http://localhost:3000/?city=Chicago`.

Run both test suites with `./scripts/test-all.sh` from the repository root —
never just one. See `CLAUDE.md`, which is the authoritative document for
testing, art, and analytics.

## Current state

Atlas is merged and live on both platforms: free and ungated on web,
premium-gated on iOS. The catalog is considerably larger than it was here:

- **43 worlds** — `src/lib/atlas/worlds.ts` and `Atlas/Worlds.swift`. 22 are
  premium-only on iOS (`World.isPremium`), leaving a free base pool of 21. The
  web app carries `isPremium` for data parity only and never gates on it.
- **26 slots** — `src/lib/atlas/slots.ts` and `Atlas/Slots.swift`. Weather
  buckets, each with a `defaultWorld`, grouped for display as Precipitation,
  Cloud cover, Clear skies, and Atmosphere.

Also built since this was written, and not reflected in the older text below:

- **The Passport** shipped on both platforms — the log of worlds actually
  experienced, specced in `PASSPORT.md`. This document used to say nothing was
  built.
- **Premium** on iOS: `PremiumGate`, `PremiumStore`, a one-time StoreKit
  purchase. See the monetization section.
- **Saved locations** on iOS, synced via iCloud KVS.
- **Analytics and a privacy policy** — six signals, off unless configured, with
  a shared parity fixture. See the Analytics section of `CLAUDE.md` and the
  policy at `/privacy`.

### Still unverified by a human

**Neither Atlas nor Passport has ever been clicked.** Both pass their test
suites — the parity fixtures make the two platforms' weather mapping provably
identical — but tests are not the same as someone using the thing, and the
environment constraints below are why: visual verification cannot happen inside
a session.

Check in this order:

1. The **normal forecast path** still works. Atlas rewrote `page.tsx`'s core
   render path from `getWeatherDescription` to `getSlotForWeather` +
   `resolveWorld`. If that is wrong the whole app is broken, not just the
   feature. This is the real risk, and it is still unretired.
2. Atlas opens from the nav button and lists all 26 slots.
3. Reassigning a slot actually changes the landed screen's background.
4. Assignments survive a reload.
5. The Passport opens and shows earned stamps, on both platforms.
6. The StoreKit purchase works in sandbox, including Restore Purchases.

## Why the code is shaped this way

The original `planetData.json` fused two concepts — the weather bucket and the
world shown for it — into one record, so nothing was reassignable. That was
split apart:

```
src/lib/atlas/types.ts     World, Slot, AtlasOverrides, ResolvedWorld
src/lib/atlas/worlds.ts    the world catalog: id, name, description, climate tag, colors
src/lib/atlas/slots.ts     the weather buckets, each with a defaultWorld
src/lib/atlas/resolve.ts   (slotId, overrides) -> the world to display
src/lib/atlas/storage.ts   localStorage, key "galacticweather:atlas:v1"
src/app/hooks/useAtlas.ts  React state + persistence
src/app/components/Atlas.tsx          full-screen overlay, slots grouped by kind
src/app/components/PlanetPicker.tsx   bottom sheet: climate filters, search, multi-assign
src/app/styles/{Atlas,PlanetPicker}.module.css
```

`src/app/utils/weatherDescriptions.ts` exports `getSlotForWeather()`, returning
only a slot id. Which *world* a slot shows is `resolveWorld()`'s job, because
the user can reassign it. `page.tsx` composes the two. The iOS port mirrors this
file for file under `Atlas/`.

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
  sheet. A 130px thumbnail badly undersells the artwork.

## Monetization — settled

The shape is decided and built; only the number is open.
`ATLAS-HANDOFF-ADDENDUM.md` has the full reasoning, including which features
would force a backend and why favorites don't. In short:

- **Premium exists only in the iOS app.** The web app stays entirely free and
  ungated — it is the demo that drives people to the paid app, and it costs
  nothing to run because preferences are device-local. **Do not add gating,
  paywall, or premium checks to the web app.**
- **One non-consumable in-app purchase.** Buy once, own forever; not a
  subscription. Entitlement is read from `Transaction.currentEntitlements` on
  device — Apple's ID *is* the account system, so there is no login, no users
  table, no server, and no receipt-validation backend. Apple takes 15% under
  $1M/yr via the Small Business Program.
- **The gating axis is world content, not slot count.** Every slot is freely
  reassignable by everyone; the premium worlds are what's locked, rendering
  greyed with a lock icon so free users can see what they'd get. Search stays
  free — gating location lookup would dead-end anyone who declines the location
  prompt and hide the app behind the paywall before they could see what they'd
  be buying. Saved locations, not search, is the premium hook.
- **Sync is iCloud Key-Value Store**, not a backend.
- **The price is still open**, and nobody has ever paid for anything, so there
  is no migration or grandfathering to worry about.

## Product context

- **"Weather twin" vocabulary — resolved by the Atlas rename.** The feature was
  briefly called "Weather Twins", which collided with "weather twin" as the term
  for a single condition→world pairing, and made the phrase premium-only
  vocabulary sitting on a free nav button. The split is now:
  - **Atlas** = the feature (the catalog of worlds and the screen for
    reassigning them). "Star Chart" was the original name; it implied
    astronomical navigation rather than what the feature does.
  - **weather twin** = one condition's matched world. Used in the picker
    header ("Weather twin for · Heavy snow") and for the premium
    multi-assign perk ("Weather Twin rotation").

  The free landed screen still says "&lt;city&gt; feels like being on" and should
  keep avoiding the phrase — not because it's paywalled vocabulary, but
  because the plain phrasing reads better cold.
- **The Passport** — the log of worlds you've actually experienced, as a
  scavenger hunt across the catalog — is built on both platforms and specced in
  `PASSPORT.md`. It is **free to collect**: the premium worlds are already
  unreachable without a purchase, so the book gates itself. It was called the
  "Holocron"; renamed because a franchise word on a nav button and in store
  screenshots is a bigger IP surface than in-app planet names.
- Premium perks still unbuilt: alternate app icons (iOS), home/lock-screen
  widgets, curated theme packs, share cards, faction UI chrome, and an extended
  forecast rendered as a strip of different worlds. That last one is the only
  one with a recurring API cost, and whether it belongs in the one-time bundle
  is a separate decision.

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
- The same reasoning is why analytics sends slot ids rather than world names:
  a third party's database is a distribution surface too.

## Environment constraints

A corporate DLP tool (BayCollector / bay-enforcer) blocks things silently and
irreversibly. Do not attempt workarounds for any of these. `CLAUDE.md` is the
authoritative copy; this is the short version.

- **Browser preview / MCP browser tools are blocked.** You cannot run or
  screenshot the web app. I have to verify visually myself — tell me what to
  check rather than trying another route.
- **iOS Simulator MCP tools are blocked.** `xcodebuild` is fine, including
  `xcodebuild test`; launching or screenshotting the Simulator is not.
- **Never run `rm`, `rmdir`, or `git rm`** — with or without wildcards, even on
  your own temp files. Use `mv` to rename things out of the way instead.
- **Never read `.env` / `.env.local` from a shell command.** If something needs
  an env var, write a script that reads the file itself and never prints the
  value.
- iOS only: `project.yml` is XcodeGen's source of truth. The `.xcodeproj` is
  gitignored and regenerated, so build settings, bundle id, and Info.plist keys
  must be changed in `project.yml` or they get silently reverted. Run
  `xcodegen generate` after adding or removing any file under `ios-app/`.

Also: these files previously lived in Dropbox, which destroyed a `.git`
directory (all 545 objects zeroed) and truncated several tracked files. They've
been moved to `~/Dev/`. If you see zero-byte files or git corruption, that's the
cause.
