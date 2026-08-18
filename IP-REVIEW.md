# IP review — the distribution surface

Status: **closed 2026-08-18. Every art finding is remediated and the
franchise-name question is resolved by design. Only the attorney review remains
outstanding, and it is a recommendation rather than a defect.**

**This is not legal advice.** It is an audit of the broadcast assets against the
rule this project already set for itself, recorded in `ATLAS-HANDOFF.md`:

> Never put franchise names in the app name, metadata, keywords, README, or store
> listing. Planet names **inside the app** are a deliberate, accepted risk — leave
> them. **The line is distribution surface, not in-app.** Anything broadcast —
> social/OG cards, App Store screenshots, marketing — must be pure landscape and
> architecture, no vehicle designs.

Whether that line is drawn in the right place is a judgment for a qualified
attorney, and worth one hour of real counsel before submission given the
franchise involved. What follows is only whether the current assets sit on the
correct side of the line as drawn.

Every visual claim below was made by opening the file, not by inference from
filenames, and ambiguous details were cropped and upscaled before being judged.

**Two limits of that method, recorded because both produced wrong calls.** Crops
were drawn tightly around objects already noticed, which is verification of a
hypothesis rather than a sweep — the Tatooine foreground was cleared as "a domed
homestead, architecture, permitted" while a speeder sat just outside the crop
window. And `og-card.png` was judged from a single full-image view at display
resolution with no crops at all, then written up as "no vehicles found," which was
more confidence than the evidence carried. The owner found and removed vehicles in
both places. A foreground sweep at several crops beats one crop aimed at the thing
you already suspect.

---

## RESOLVED — the app icon

`ios-app/galacticweather/galacticweather/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

**What the icon was.** A composite of the Naboo and Hoth travel posters, carrying
an AT-AT walker at centre right, several more in that poster's background, roughly
four starfighters over Naboo, three or four further craft across Hoth, a laser
turret, and NABOO / HOTH in large display type. Protected vehicle designs on the
most broadcast asset the product has — store listing, search results, every home
screen, and the first thing a reviewer sees.

**What it is now.** Twin suns behind a cloud over dune ridges. Original art: no
vehicles, no franchise names, no protected designs. Also the stronger icon on
craft grounds — large simple shapes and high contrast that survive 40×40, where
the poster composite collapsed into grey.

**Two spec violations found and fixed while wiring it in.** Both would have failed
App Store validation rather than review:

| Property | Was | Now | Apple requires |
|---|---|---|---|
| Dimensions | 1254×1254 | 1024×1024 | exactly 1024×1024 |
| Colour mode | RGBA | RGB | no alpha channel |

`Contents.json` declared the slot as `1024x1024` while the file was 1254px, and
the image carried a fully-opaque alpha channel — enough on its own to trigger
"the app icon can't contain an alpha channel." Resized with LANCZOS and flattened
to RGB; re-opened afterwards to confirm no visible artefacts. The corners are
square and unmasked, which is correct — iOS applies the rounded mask itself.

**The `design/` folder is gone on purpose, and source art stays outside the repo.**
An earlier pass of this review moved the vector and a full-resolution master into
`design/app-icon/`; that was reverted at the owner's direction along with the rest
of the folder. The tracked copy of the icon is therefore the single conformed
1024×1024 RGB PNG in the appiconset, and the higher-resolution originals live in
`~/Downloads/app-icon.png` and `~/Desktop/app-icon.svg`.

The consequence, stated once: if those two local files are lost, the icon can only
be recovered by upscaling the 1024px shipping asset. That is a deliberate trade,
not an oversight.

One identity worth recording, because git surfaced it and it would be easy to
misread later: `~/Desktop/app-icon.svg` is byte-identical to the
`public/galactic-weather-logo.svg` deleted in the same commit — both hash to
`45ea15af`. **The site logo and the app icon are one artwork, not two.** Nothing
referenced the logo from `public/`, so its removal breaks nothing, but anything
wanting a web-facing logo later needs a copy put back deliberately.

A franchise-term sweep of the SVG returns four apparent hits for "hoth." All four
sit inside base64 raster data — coincidental byte sequences, not metadata. Clean.

**One provenance note, because it caused a wrong call in the first draft of this
review.** The old `icon-1024.png` had an mtime of 2026-08-16 and `git log --all`
showed no branch touching that path since `b0a7b16` grafted the iOS app in — two
days untouched while the repo moved 23 commits. That staleness was the signal that
the committed asset was not the intended design, and it was misread as intent. The
four earlier concepts under `design/app-icon/` had already been superseded and
deleted; that deletion is now committed rather than dangling in the working tree.

**Still open, and not an IP matter:** `web-app/galactic-weather/public/icon-1024.png`
is unreferenced by any source file. Next.js App Router picks favicons up from
`src/app/icon.png` by convention, not from `public/`, so a file in that location
does nothing on its own. Either wire it up or drop it.

---

## RESOLVED — the primary Open Graph image

**Fixed 2026-08-18, across two passes.** `01eeaa7` removed the Kamino craft. A
second pass by the owner went further than this review had asked:

- The **Tatooine speeder** removed — the vehicle this review had missed.
- **Planet names demoted** from the largest element on each panel to a subordinate
  caption beneath the temperature: `72°F & CLOUDY` over `It feels like being on
  Ghorman`.
- **`Today's Forecast`** with the apostrophe, on all three panels.
- A **mislabelled panel corrected** — the Ghorman art had briefly been captioned
  Kamino, duplicating the third panel.

Verified panel by panel at 3–4× crops rather than from the full view: three
distinct worlds, correct captions, apostrophes present. Kamino's sky retains only
platform edges, the antenna spire, and lightning — architecture and weather. The
finding as originally written follows.

`web-app/galactic-weather/public/galactic-weather.png` (1200×630)

This is `openGraph.images[0]` and the sole `twitter.images` entry, so it is what
renders on every link share. Three phone mockups: Ghorman, Tatooine, Kamino.

- **Kamino panel contains an aircraft.** A dark hulled craft with two lit
  windows and a swept crossbar wing, mid-air between the two platform towers.
  Small — roughly 20px square at native size — but a vehicle design on a
  broadcast surface, which is the thing the rule prohibits.
- **Ghorman panel is clean.** Colonnade, dome, spire, volcano. Architecture and
  landscape only.
- **Tatooine panel is clean.** The foreground object reads as a vehicle at a
  glance; cropped and upscaled it is plainly a **domed homestead with a
  doorway** — architecture, which the rule permits.
- Three franchise planet names in large type: GHORMAN, TATOOINE, KAMINO.

Remove or paint out the Kamino craft. The rest of the image is compliant.

---

## RESOLVED — the square OG card no longer leads with a franchise name

**Fixed 2026-08-18.** `91°F & SUNNY` is now the dominant element and the world is a
caption beneath it — `It feels like being on Tatooine`. The apostrophe is correct,
and a speeder in the foreground was removed, leaving a domed homestead and dunes.
The twin-suns composition remains, which this review flagged as the softer half of
the concern and does not consider actionable. The finding as originally written
follows.

`web-app/galactic-weather/public/og-card.png` (1200×1200)

`openGraph.images[1]`, the 1:1 fallback that iMessage, WhatsApp, and Mastodon
prefer — so in practice this is the card most often seen in private sharing.

- **The art is clean.** Dunes, ridgelines, domed structures, a spire. No
  vehicles found.
- **"TATOOINE" is the dominant visual element**, set in the largest type on the
  card.
- The **twin-suns composition** is among the most recognizable single images the
  franchise has. As a recall trigger it is arguably stronger than a ship would
  be, even though no rule explicitly names it.

The written rule bans franchise names from "the app name, metadata, keywords,
README, or store listing" and bans vehicles from broadcast art — it does not
quite say what to do about a franchise *planet name* rendered as broadcast art.
That gap is worth closing deliberately rather than by accident, because both OG
images currently sit in it.

---

## RESOLVED — the publicly fetchable posters are gone from the web app

`web-app/galactic-weather/public/posters/` held Naboo, Hoth, Tatooine, Endor,
Scarif, Alderaan, and Bespin. The Naboo and Hoth files were the source art for the
old icon composite, so they carried the same AT-AT and starfighters — served as
plain URLs from a public domain, fetchable by anyone including a rights holder's
crawler, without ever opening the app. That is broadcast in every practical sense.

**Removed 2026-08-18.** They were dead weight as well as exposure — 3.7 MB serving
no purpose. Verified unreferenced before removal, by more than a filename grep:

- The only dynamic image paths anywhere in the web codebase are
  `planetImageSrc = (id) => \`/planets/${id}.jpg\`` and
  `IDLE_BACKDROP_SRC = "/planets/_hyperspace.jpg"`, both in `src/lib/atlas/worlds.ts`.
  Neither touches `/posters/`.
- `WorldPoster.tsx` — the component that *renders* a poster — loads
  `planetImageSrc(world.id)`. It composes the poster look in CSS from planet art
  rather than loading a pre-rendered JPG, which is why the directory could go
  unreferenced while the feature kept working.
- Zero references to any of the seven filenames; nothing in sitemap or robots.

**iOS is unaffected.** It keeps its own copies in
`Resources/Assets.xcassets/Posters/` as `poster-<world>.imageset`, guarded by
`galacticweatherTests/CreditsPosterTests.swift`. In-app Credits on iOS still shows
the posters, which remains inside the accepted-risk zone — the exposure that got
removed was the public web URL, not the in-app display.

---

## Clean — no action needed

**Metadata passed everywhere it matters.** A sweep for franchise terms across
`.json`, `.yml`, `.md`, `.ts`, `.tsx`, `.swift`, and `.plist` found nothing in
any shipping field:

| Surface | Value |
|---|---|
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.robleto.galacticweather` |
| `CFBundleDisplayName` | `Galactic Weather` |
| Web `title` / `applicationName` | `Galactic Weather` |
| Web `keywords` | weather, forecast, weather app, location weather, weather twin, galactic weather |

`project.yml` — the XcodeGen source of truth — is correct. The rename was done
properly at the metadata layer.

**Stale build artifacts, no exposure.** `ios-app/galacticweather/.build/`
contains `StarWarsWeather.app` from before the rename. It is gitignored and
untracked, so nothing ships it, but a clean rebuild would clear the old product
name out of local build output.

**The Tom Scott credit should stay.** `Footer.tsx` and `CreditsView.swift` link
to `tomscott.com/weather/starwars/`. The franchise term appears only in the href;
the rendered link text is "weather site." Crediting the original inspiration is
good-faith practice and helps rather than hurts — it makes the project legibly
homage rather than passing-off. Leave it.

---

## RESOLVED — not IP, but it was on every broadcast asset

**"Todays Forecast" now reads "Today's Forecast."** Fixed on `og-card.png` and on
all three panels of `galactic-weather.png`, each verified by individual crop rather
than from the full view — the first fix pass landed on the square card only, and
that partial state was invisible at full-image scale.

Still present in the poster art iOS bundles for Credits, which is in-app rather
than broadcast, so it is cosmetic rather than a submission concern.

---

## Before submission

1. ~~**Wire in the new app icon.**~~ **Done** (`f015687`). New art in the
   appiconset, conformed to 1024×1024 RGB. Suites green afterwards: 164 web, 85 iOS.
2. ~~**Remove the Kamino aircraft** from `galactic-weather.png`.~~ **Done**
   (`01eeaa7`).
3. ~~**Decide whether `public/posters/` counts as broadcast.**~~ **Decided and
   done** — removed from the web app; iOS keeps its own copies for in-app Credits.
4. ~~**Decide the franchise-name-as-broadcast-art question.**~~ **Resolved by
   design, not by policy.** Rather than rule on whether a franchise planet name may
   headline a broadcast card, the cards were changed so none of them does — the
   world is now a caption under the temperature on every surface. The gap in the
   written rule still exists in principle; it no longer has anything sitting in it.
   Worth one line in `ATLAS-HANDOFF.md` recording that broadcast art leads with
   weather and treats the world as a caption, so the next redesign does not
   reintroduce the question.
5. ~~**Fix "Todays" → "Today's"** on the OG art.~~ **Done** on both cards.
6. **One hour with an actual attorney.** Everything above is an audit against a
   self-imposed rule. Whether the accepted-risk position on in-app planet names
   holds up is a question for someone qualified to answer it, and it is cheap
   insurance relative to a takedown after launch.
7. **Screenshots do not exist yet.** No `fastlane/` or screenshot directory was
   found. When they are made, they are broadcast surface — same rules, and the
   Simulator being DLP-blocked means capturing them is work only you can do.
