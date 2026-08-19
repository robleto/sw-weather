# Widget — design spec

Status: **not built, not scoped into v1.0, and not authorized by this document.**
`SCOPE.md` lists "Home and lock-screen widgets" under deliberately deferred, with
an amendment bar this idea has not cleared: broken-not-missing, App Store
requires it, or multiple unrelated users asking unprompted. None apply yet.
This spec exists so the design is ready *if* that bar is cleared, the same way
`PASSPORT.md` and `MEASUREMENT.md` were written ahead of the decision they
inform — not as a quiet way around the freeze. If this gets built before the
bar is cleared, `SCOPE.md` needs an honest amendment entry saying why, per its
own rule.

Read `ATLAS-HANDOFF.md` for the Atlas architecture and `PASSPORT.md` for the
Passport this borrows storage patterns from. This document narrows three prior
passing mentions of widgets into one real design and disagrees with two of
them; see "What this supersedes" below.

---

## What it is

A home screen and Lock Screen widget showing the same thing the app's landed
screen shows — a world's art, the temperature, the condition — for one
location, picked once in the widget's own configuration. Tapping it opens the
app straight to that location.

**It is a weather widget first.** The Passport tie-in discussed while scoping
this — a small badge when the world on screen is an unfound stamp — is a
stretch goal, deferred behind the base widget shipping and proving itself
useful on its own. See "Stretch goal: the Passport badge."

## What this supersedes

Three prior mentions of widgets exist in this repo, all passing and none a
design:

- `ATLAS-HANDOFF.md` and `ATLAS-HANDOFF-ADDENDUM.md` list "home & lock screen
  widgets" as a **premium**, one-time-bundle feature — bucketed with alternate
  app icons and theme packs as "device/iCloud only, no infrastructure."
- `PRICING.md` repeats that bucketing, framing widgets as a possible future
  revenue lever precisely because they're "built once and never need feeding."
- `PASSPORT.md`'s roadmap section says "'Latest stamp' is an obvious
  lock-screen widget and it's already in the premium bundle."

This spec **disagrees with the gating, not the bundle placement.** The base
widget (one location, art + temperature + condition) should be free, for the
same reason search is free and current-location weather is free (see
`PremiumGate.swift`'s comment on that decision): a widget nobody can see
without paying is a paywall in front of the thing that would sell the
purchase, not a reward for having already bought it. What stays premium is
exactly what's already premium — *which* location it can point at. A free
user has one saved location plus device location (`PremiumGate.freeSavedLocationLimit
== 1`); the widget's configuration picker offers exactly the locations they're
already allowed to have. No new gate, no new `PremiumGate` rule — the existing
saved-locations limit *is* the widget limit, because the widget is just another
reader of the same list. Multiple *widget instances* (someone adds three
copies to point at three cities) is naturally capped the same way: a third
instance can only be configured to a location that exists, and a free user
only has two to choose from.

The Passport-badge idea from `PASSPORT.md`'s roadmap is kept, but demoted from
"the widget" to a stretch goal on top of it — see below for why doing it first
was the wrong order.

---

## Why a widget earns its slot, and why the Passport version wouldn't have

Nobody adds a "hunt progress" widget to their home screen — a static number
that only moves when they've already opened the app and done the thing the
widget claims to encourage doesn't clear the bar for "useful enough to look
at every day." A weather widget does, on its own, independent of anything the
app is trying to teach: the art is the reason to have it, checking today's
number is the reason to keep it.

That ordering also protects the Passport rather than exploiting it. Slapping a
score onto the one surface someone glances at without opening the app risks the
exact failure `MEASUREMENT.md` already names — the one-session collector,
false positive #2 — by turning the collection loop into a checklist visible at
a glance rather than something found by actually looking somewhere new.

## The measurement trap, stated plainly

A widget that shows today's world well **removes the reason to open the app.**
`MEASUREMENT.md`'s north star is returning landers reaching `Forecast.landed`
in the app — and a widget doing its job correctly makes that number go down
while the product is more loved, not less. `MEASUREMENT.md`'s whole premise is
that benchmarks chosen after the numbers arrive get chosen to flatter them;
shipping this and then quietly redefining the north star would be exactly that
move.

So the decision is made here, before any data exists: **the north star does
not change.** `Forecast.landed` stays app-only. A widget-driven glance is not
a landing. If widget adoption is high and `Forecast.landed` softens, that is
the widget working, not the product regressing — but it can only be told apart
from actual regression if widget presence is itself instrumented, which is the
one addition this spec proposes to `shared/analytics-signals.json`:

- Add `source` to `App.launched`'s payload, values `app` | `widget`, populated
  from whether the launch came through the widget's deep link.
  `payloadKeyAllowlist` gains `source`. This is a deliberate contract edit —
  expect both suites red until both platforms agree, per the file's own header
  comment.
- No new signal for "widget rendered" or "widget viewed." iOS does not tell an
  app when its widget is on screen, only when its timeline is requested for
  rendering — which happens on a system schedule regardless of whether a human
  ever looks at it, so a signal there would count refreshes, not attention, and
  the count would look like engagement while measuring the opposite.

---

## The IP question a widget raises that nothing prior did

`IP-REVIEW.md` drew its line at **distribution surface**, not in-app display —
screenshots, OG cards, marketing copy. Everything it reviewed lives either
fully inside the app's own chrome or fully outside the product (a public URL,
a store listing). A widget is neither. It renders outside the app's UI, on a
surface the user did not open and did not ask to see right now — closer in
kind to the broadcast surfaces the review scrutinized than to the in-app
display the review waved through.

Two concrete exposures, not raised anywhere else in this repo:

- **The widget gallery preview.** iOS renders a live or near-live preview of
  every installed widget's *current* content in the system widget picker —
  not a static screenshot the developer controls, but whatever world happens
  to be on screen when someone opens the gallery to add a widget. A franchise
  planet name and its art sit in a system surface with no equivalent to the
  App Store screenshot review this repo already put itself through.
- **Screenshots of the home screen.** Once installed, the widget is part of
  whatever the user's home screen looks like in a screenshot they take and
  share — a form of broadcast the developer has no control over, but one this
  product's own art will now appear in more often, at a size and prominence an
  in-app screen doesn't have.

Neither of these is resolved by this document. `IP-REVIEW.md` item 6 — "one
hour with an actual attorney" — was already the one open item on the existing
accepted-risk line; a widget is a reason to actually do that before this
ships, not a reason to extend the existing accepted-risk judgment to a surface
that judgment never considered. Recorded here so the next person doesn't
re-derive it from scratch, matching the "IP surface" reasoning that renamed
Holocron to Passport in the first place.

If the attorney conversation doesn't happen before this is built, the
fallback that costs nothing: keep the world **name** off the widget face
(temperature and condition only, the same demotion the OG cards already went
through — see `IP-REVIEW.md`'s "franchise-name-as-broadcast-art" resolution)
and let the art speak for itself. That mirrors a decision this project has
already made once and just needs applying to a new surface.

---

## Prerequisites — the real cost, before any widget UI exists

### 1. An App Group, and a narrow migration

`SavedLocationsStorage` writes to `UserDefaults.standard` — the main app's own
container, invisible to an extension process. A widget extension cannot read
it as-is.

**Scope the migration to `SavedLocationsStorage` only.** Not Atlas, not
Passport. The widget's configuration needs to enumerate saved locations; it
needs nothing else from app storage. Every byte of app state given to the
widget target is a byte future-Passport-badge work has to reason about for
merge safety (`PassportStorage.swift`'s whole doc-comment is about how easy
that is to get wrong) — so the stretch goal, if built, gets its own migration
later, scoped just as narrowly.

Concretely:

- Add an App Group entitlement (`group.com.robleto.galacticweather`) to
  `Config/galacticweather.entitlements` and to a new entitlements file for the
  widget extension target.
- `SavedLocationsStorage.save` gains a third write, to
  `UserDefaults(suiteName: "group.com.robleto.galacticweather")`, alongside
  the existing iCloud KVS and `.standard` writes. This is additive — a
  write-through cache for the widget to read — not a replacement for the
  existing sync path. `.standard` and iCloud KVS keep doing exactly what they
  do today for the app itself.
- The widget's own code never writes this store, only reads it. No merge
  logic needed on the widget side — merge already happened before the app
  wrote the App Group copy.
- After a location is added, removed, or reordered, call
  `WidgetCenter.shared.reloadTimelines(ofKind:)` so an edit doesn't wait for
  the system's own refresh cadence to reach the widget. Same call after a
  premium purchase completes, since that can change which saved locations are
  unlocked.

### 2. Widget-sized art

`Assets.xcassets/Planets` holds `scripts/downsample-art.py`'s output, sized
for `--height 2868` — full-bleed portrait phone art. A `systemMedium` widget
is roughly 360×170pt; a Lock Screen accessory is smaller still and, per Apple
HIG, must not carry full-color art at all (accessory widgets render in a
single tint on the Lock Screen — see family choice below).

This wants a second derivative, not the existing assets reused at a smaller
display size:

- Extend `downsample-art.py` with a widget target (e.g. `--height 400`, a
  landscape crop rather than the portrait-cover-fit framing) writing to a new
  `Assets.xcassets/PlanetsWidget/` catalog, included only in the widget
  extension target's sources.
- Do not point the widget at the app's own `Planets` imageset. Loading
  2868px-tall JPEGs into a widget's tight memory budget (WidgetKit extensions
  are killed for exceeding a much smaller memory ceiling than the host app) is
  the kind of thing that works in the simulator and gets silently blank
  widgets on-device.

### 3. Shared source membership, explicitly listed

XcodeGen makes this cheap, but it's exactly the globbing hazard `CLAUDE.md`
warns about — "XcodeGen globs that whole directory" — so the widget target's
`sources` list must name folders explicitly, not point at
`galacticweather/` wholesale and rely on nothing extra being in there:

```yaml
targets:
  galacticweatherWidget:
    type: appex
    platform: iOS
    sources:
      - path: galacticweatherWidget
      - path: galacticweather/Atlas          # Worlds, Slots, Resolve, AtlasTypes
      - path: galacticweather/Models/SavedLocation.swift
      - path: galacticweather/SavedLocations/SavedLocationsStorage.swift
      - path: galacticweather/Utils/Temperature.swift
      - path: galacticweather/Utils/WeatherDescriptionMapper.swift
      - path: galacticweather/Models/WeatherResponse.swift
      - path: galacticweather/Services/WeatherService.swift
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.robleto.galacticweather.widget
        CODE_SIGN_ENTITLEMENTS: Config/galacticweatherWidget.entitlements
    info:
      path: galacticweatherWidget/Info.plist
      properties:
        OPENWEATHERMAP_API_KEY: "$(OPENWEATHERMAP_API_KEY)"
```

`Passport/` is deliberately absent from that list — see the stretch goal
section for what adding it back later would cost.

The main app target gains `- target: galacticweatherWidget` with `embed: true`
under its `dependencies`, so the extension ships inside the host app bundle.

### 4. A deep link

Nothing in this app currently has a URL scheme (`grep`-confirmed: no
`CFBundleURLTypes` in `project.yml`). `widgetURL` needs somewhere to point.
Smallest addition that does the job: a custom scheme,
`galacticweather://location/<saved-location-id>` (and `.../current` for device
location), handled in `GalacticWeatherApp.swift`'s `onOpenURL` by resolving the
id against `SavedLocationsStorage.load()` and navigating straight to that
location's forecast — skipping the pager's default landing.

### 5. The archive process notices a new target

`TESTFLIGHT.md` documents `CURRENT_PROJECT_VERSION` as the thing that must be
bumped before every upload, and `scripts/archive.sh` as the thing that
enforces it. An embedded extension needs its own matching build number bump on
every upload (Apple validates extension and host build numbers together) and
its own entry in whatever `archive.sh`'s preflight checks — that script isn't
a place to improvise once this target exists; add a line to `TESTFLIGHT.md`
noting the extension needs a provisioning profile of its own the first time
this is archived, the same way the "first archive after adding a capability"
gotcha is already documented there for other capabilities.

---

## Widget design

**One configurable widget, `ConfigurationAppIntent`-driven**, not a family of
different widgets. The configuration surfaces the same choice `PremiumGate`
already governs: device location, plus whatever's in
`SavedLocationsStorage.load()`, filtered to `unlockedLocations` — a locked
saved location simply isn't offered as a widget option, so there's no locked
state to design for inside the widget itself.

| Family | Content | Notes |
|---|---|---|
| `systemMedium` | Widget-sized art, temperature, condition, city | The primary target — big enough for the art to matter |
| `systemSmall` | Temperature, condition, city, no art (or a heavily cropped detail) | Supported because WidgetKit expects a family ladder, not because it's the point |
| `accessoryRectangular` (Lock Screen / StandBy) | Temperature, condition, city, tinted glyph — no color, no art | Accessory families render single-tint per HIG; treat this as the pure-data mode, not a shrunk photo |

No `accessoryCircular` in v1 — a single number (temperature alone, no
condition or place) is the least useful surface here and the first one worth
cutting if the build needs trimming.

**Timeline provider fetches its own weather.** It does not read cached
forecast state from the host app (there isn't a durable one worth reading —
`WeatherViewModel` refetches per-session) and it does not need the App Group
for this part: given a saved location's lat/lon, or the device's own via
`CLLocationManager` in-extension for the "current location" configuration,
it calls `WeatherService.fetchWeather` exactly as the app does, then
`resolveWorld` to pick the slot and art. Reload policy: `.after(next hour
boundary)`, which sits comfortably inside WidgetKit's system-wide refresh
budget (matches the cadence a weather app is expected to request, per Apple's
own widget guidance) — plus the explicit `reloadTimelines` calls from
prerequisite #1 for edits that shouldn't wait.

**Failure states need their own design**, unlike the app, which can show a
loading spinner and retry on demand: no network, no location permission, API
error. A widget can't retry itself mid-render — show the last successfully
rendered entry with a small "as of" marker rather than an error state that's
uglier than stale data, mirroring how the app treats `GeocodeCache` as a
fallback rather than a failure.

---

## Stretch goal: the Passport badge

Deferred, explicitly, behind the base widget shipping and being worth keeping.
If it's built:

- A small stamp glyph appears in a corner **only** when the world currently on
  screen is one the Passport doesn't yet have wild — never a count, never
  "X/21," which is the score-forward design this spec rejected above for the
  base widget and the reason it's staying rejected here too.
- This is the one piece of the whole spec that would need `Passport/` added to
  the widget target's sources (prerequisite #3) and a second, equally narrow
  App Group migration of `PassportStorage` — read-only from the widget, same
  shape as the saved-locations one. Do not do this migration until the badge
  is actually being built; scoping it in advance the same way the base widget
  did would reintroduce the exact `Passport`/`Atlas` divergence-of-caution
  `PassportStorage.swift`'s doc-comment already explains at length (merge, not
  replace — a lost stamp can't be re-earned).
- Analytics implication if built: whether the badge changed anything is
  answerable from existing signals (`Passport.stampEarned` rate, segmented by
  `source: widget` launches once #App.launched has that field) without a new
  signal — another reason to build it second rather than first: by the time
  it's worth building, the instrumentation to judge it already exists.

## Parity note

Web has no widget equivalent — there's no OS-level widget surface for a web
app of this shape, and `SCOPE.md` already treats "not cross-platform-identical"
as accepted (separate Passport books, iOS-only saved locations and premium).
This is a second iOS-only surface for the same underlying reason: no
backend, and the things it depends on (`SavedLocationsStorage`, `PremiumGate`)
are already iOS-only. Worth one line in `ATLAS-HANDOFF.md` when this is built,
the same way the doc already flags Passport and premium as iOS-only, so the
next person doesn't read the asymmetry as drift.
