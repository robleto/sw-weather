# IP review — the distribution surface

Status: **review complete 2026-08-18. One blocking finding. Not yet remediated.**

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
filenames. Two ambiguous details were cropped and upscaled before being judged.

---

## BLOCKING — the committed icon is stale, and the stale one ships vehicles

**Corrected 2026-08-18.** The first version of this section read as though the
poster composite were the intended icon. It is not. A replacement already exists
— original art, no franchise content — but it has not been wired into the
appiconset, so the old asset is still what a build produces. The finding is a
wiring gap, not a design problem. Details at the end of this section.


`ios-app/galacticweather/galacticweather/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

The icon is a composite of two travel posters, Naboo and Hoth. It contains:

- **An AT-AT walker**, large, centered in the right-hand poster, unmistakable.
- **Several more AT-ATs** in that poster's background.
- **Roughly four starfighters** in formation, upper left of the Naboo poster.
- **Three or four additional craft** across the Hoth poster.
- **A laser turret / artillery emplacement**, lower left of the Hoth poster.
- **NABOO and HOTH** set in large display type.

This is the single most broadcast asset in the entire product. It appears in the
App Store listing, in store search results, and on every device home screen. It
is the first thing an App Store reviewer sees. Of all the places for a
specifically protected vehicle design to appear, this is the worst one, and it is
a direct violation of the rule above rather than a borderline call.

**The replacement exists and is clean — it is just not in the repo.**

| File | Modified | State |
|---|---|---|
| `~/Downloads/app-icon.png` | 2026-08-17 09:49 | 1254px raster |
| `~/Desktop/app-icon.svg` | 2026-08-17 13:04 | vector wrapper around an embedded raster |

Twin suns behind a cloud over dune ridges. Original art: no vehicles, no
franchise names, no protected designs. It is also the stronger icon on craft
grounds — large simple shapes and high contrast that hold together at 40×40,
where the poster composite collapses into grey.

A franchise-term sweep of the SVG returns four apparent hits for "hoth." All four
sit inside base64 raster data — coincidental byte sequences, not metadata. Clean.

Two notes on provenance, since this tripped up the first version of this review:

- The committed `icon-1024.png` has an mtime of 2026-08-16 01:35 and `git log
  --all` shows no branch has modified that path since `b0a7b16` grafted the iOS
  app in. It went stale while the rest of the repo moved 23 commits.
- `design/app-icon/` — which held four earlier abstract concepts — is deleted in
  the working tree, uncommitted. Those concepts were superseded by the icon
  above. Do not go looking for them.

**The remaining work is wiring, not design:** generate the appiconset from
`app-icon.png`, move the source art into the repo so it stops living in
`~/Downloads`, and commit the `design/app-icon/` deletion so the tree is honest
about what was abandoned.

There is also a **non-IP reason** to abandon the current icon regardless: it is
two tilted rectangles on a light field with black letterbox bars top and bottom.
At the sizes an icon is actually rendered — down to 40×40 in search results and
Spotlight — the posters become an illegible grey smudge and the bars eat a third
of the canvas. The abstract concepts are the better icon on craft grounds alone.

---

## HIGH — a vehicle silhouette in the primary Open Graph image

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

## HIGH — the square OG card leads with a franchise name

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

## MEDIUM — posters are publicly fetchable, not just in-app

`web-app/galactic-weather/public/posters/` — Naboo, Hoth, Tatooine, Endor,
Scarif, Alderaan, Bespin.

These are the Credits posters, and the Naboo and Hoth files are the source art
for the icon composite, so they carry the same AT-AT and starfighters.

Displaying them in an in-app Credits screen falls inside the accepted-risk zone.
But files under `public/` are served as plain URLs from a public domain, which is
meaningfully more exposed than "in-app" — anyone, including a rights holder's
crawler, can fetch them directly without the app. Worth deciding whether that
counts as broadcast under your own rule. It probably does.

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

## Not IP, but on every broadcast asset

**"Todays Forecast" is missing its apostrophe.** It appears in `og-card.png`, in
`galactic-weather.png`, and in the poster art itself — so the typo is on the
primary link-share card, the square fallback, and the Credits posters. Since the
icon and OG art both need regenerating anyway, fix it in the same pass.

---

## Before submission

1. **Wire in the new app icon.** Generate the appiconset from
   `~/Downloads/app-icon.png`, bring the source art into the repo, and commit the
   `design/app-icon/` deletion. Blocking only because a build today still
   produces the old composite.
2. **Remove the Kamino aircraft** from `galactic-weather.png`.
3. **Decide the franchise-name-as-broadcast-art question**, and amend the rule
   in `ATLAS-HANDOFF.md` to say what was decided either way.
4. **Decide whether `public/posters/` counts as broadcast**, given the files are
   directly fetchable.
5. **Fix "Todays" → "Today's"** while regenerating art.
6. **One hour with an actual attorney.** Everything above is an audit against a
   self-imposed rule. Whether the accepted-risk position on in-app planet names
   holds up is a question for someone qualified to answer it, and it is cheap
   insurance relative to a takedown after launch.
7. **Screenshots do not exist yet.** No `fastlane/` or screenshot directory was
   found. When they are made, they are broadcast surface — same rules, and the
   Simulator being DLP-blocked means capturing them is work only you can do.
