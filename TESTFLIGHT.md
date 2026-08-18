# TestFlight — getting a build to real people

Status: **nothing has been set up in App Store Connect yet.** The code side is
ready; the account side is untouched.

This is the step between "the app works on my machine" and "strangers have
opinions." It comes before any launch channel — `MEASUREMENT.md` sets bars that
need actual users, and friends on TestFlight are the cheapest users there are.

**The thing worth knowing first: TestFlight does not require screenshots.**
Screenshots are an App Store *submission* requirement. Not having them is not
blocking anything below.

---

## Already done, in code

| | Value |
|---|---|
| Bundle identifier | `com.robleto.galacticweather` |
| Team ID | `WNJ76895SD` |
| Signing | `CODE_SIGN_STYLE: Automatic` |
| IAP product ID | `com.robleto.galacticweather.premium` |
| IAP type | Non-consumable, one-time |
| Deployment target | iOS 17.0 |
| Orientation | Portrait only, `UIRequiresFullScreen` |
| Version / build | `MARKETING_VERSION 1.0` / `CURRENT_PROJECT_VERSION 1` |
| App icon | 1024×1024 RGB, validation-conformant |
| Privacy / terms / support pages | Live on the web app |

`project.yml` owns all of it. The `.xcodeproj` is generated and gitignored, so
every change goes in `project.yml` or it gets silently reverted.

---

## Part 1 — Apple Developer portal

**Register the App ID, and enable iCloud Key-Value Storage on it.**

That second half is the one that bites. `Config/galacticweather.entitlements`
requests `com.apple.developer.ubiquity-kvstore-identifier`, because Atlas
assignments and saved locations sync through `NSUbiquitousKeyValueStore`. If the
App ID does not have iCloud Key-Value Storage enabled, automatic signing cannot
produce a matching profile and the archive fails with a provisioning error that
does not mention iCloud anywhere in its text.

If `scripts/archive.sh` fails on signing, this is the first thing to check.

---

## Part 2 — App Store Connect

**Create the app record.** Bundle ID `com.robleto.galacticweather`, name
"Galactic Weather". Expect to supply the privacy policy URL and support URL —
both pages already exist on the web app, which is what they were built for.

**Create the in-app purchase.** Product ID `com.robleto.galacticweather.premium`,
type Non-Consumable, matching what `PremiumStore.swift` asks StoreKit for. A
mismatch here does not error — `Product.products(for:)` simply returns nothing and
the paywall renders with no purchase button.

**Set the price to $2.99.** `StoreKitConfig/Products.storekit` already says
$2.99, but that file only supplies the price in the Simulator — sandbox and
TestFlight both read it from App Store Connect. Until the product exists there,
the paywall in a TestFlight build shows "—", because
`PremiumStore.displayPrice` falls back to that when no product loads. Nothing
hardcodes a number, so the two files disagreeing surfaces as a wrong price on the
paywall rather than as a crash.

**Fill in App Privacy.** The app sends analytics through TelemetryDeck, so data
collection has to be declared. `shared/analytics-signals.json` is the honest
inventory of what actually goes out — six signals, and a `payloadKeyAllowlist`
enforced by tests on both platforms that excludes city names, coordinates, search
queries, and world names. `PrivacyInfo.xcprivacy` is already in the iOS target.

---

## Part 3 — Local preflight

**Set `TELEMETRYDECK_APP_ID` in `Config/Secrets.xcconfig`.**

This is the quiet failure and the expensive one. `Services/Analytics.swift` sends
nothing at all unless that key is set, so a build made without it produces a
TestFlight round with **no data** — no retention, no activation, no idea whether
anyone came back. That is the entire purpose of the round, per `MEASUREMENT.md`.

`scripts/archive.sh` checks for it and makes you confirm before continuing without
it. The check reads the file in-process and reports only booleans; secret values
are never printed or read into the shell.

`OPENWEATHERMAP_API_KEY` must also be set or the app cannot fetch a forecast at
all, which the script treats as a hard stop rather than a warning.

---

## Part 4 — Archive and upload

```bash
./scripts/archive.sh
```

Runs the preflight, refuses to archive on failing tests, regenerates the Xcode
project, and writes a timestamped `.xcarchive` into **Xcode's own Archives
folder** — `~/Library/Developer/Xcode/Archives/<today>/`.

That location is deliberate. **Organizer only lists archives found there**, and
Distribute App is a button on the Organizer row — so an archive written anywhere
else leaves you hunting for a button that cannot exist. An earlier version of this
script wrote to `build/archives/` and produced exactly that dead end.

Then upload, via **Xcode → Window → Organizer → Archives**: select the build, then
**Distribute App → App Store Connect → Upload**.

**Expect a distribution-certificate prompt the first time.** Only an *Apple
Development* certificate exists in the keychain; App Store distribution needs an
*Apple Distribution* one, and Xcode will offer to create it. Let it.

`./scripts/archive.sh --export` will also produce a signed `.ipa` if you would
rather use Transporter. Uploading is deliberately not automated here: it needs App
Store Connect credentials, and the Organizer flow is three clicks and hard to get
wrong.

**Every upload needs a unique build number.** Bump `CURRENT_PROJECT_VERSION` in
`project.yml` — not in Xcode, where the change will be regenerated away. App Store
Connect rejects a build number it has already seen, which is a confusing error to
hit after a long upload.

Expect an export-compliance question. The app makes ordinary HTTPS calls and uses
no custom cryptography, which normally lands in the standard exemption — answer
per the App Store Connect prompts rather than from memory.

---

## Part 5 — Invite testers

**Internal testers** — up to 100, and no Beta App Review. They must hold a role on
your App Store Connect team, which for friends means adding them as users. Builds
reach them within minutes. **This is the fast route, and the right one for a first
round.**

**External testers** — up to 10,000, no team role needed, but the first build
requires Beta App Review. Usually quick, but it is a review, and it wants a beta
app description and a feedback email.

Start internal. Nothing about a first friends round needs 10,000 seats, and
skipping review means you find out today whether the thing works on real devices.

---

## Part 6 — Test the purchase

The StoreKit purchase has **never been exercised with a real transaction**. It is
the only revenue path in the product, and it has only ever run against
`Products.storekit` locally, if at all.

TestFlight builds use the **sandbox** StoreKit environment automatically, so a
purchase there charges nothing. Create a Sandbox Apple Account in App Store
Connect (Users and Access → Sandbox Testers) and sign into it on the device.

Test both directions: buy it, and then **Restore Purchases** on a second device or
after a reinstall. `PremiumGate.swift` reads entitlement from
`Transaction.currentEntitlements`, so restore is the path that proves Apple's ID
is genuinely acting as the account system — the assumption the whole
no-backend architecture rests on.

---

## Gotchas, in rough order of likelihood

1. **Provisioning fails without mentioning iCloud.** Part 1. The App ID needs
   iCloud Key-Value Storage.
2. **Analytics silently off.** Part 3. No `TELEMETRYDECK_APP_ID`, no data, wasted
   round.
3. **Duplicate build number.** Bump `CURRENT_PROJECT_VERSION` in `project.yml`.
4. **Paywall with no purchase button.** The App Store Connect product ID does not
   match `PremiumStore.productID` exactly.
5. **Changes reverted.** Anything edited in Xcode rather than `project.yml` is
   regenerated away on the next `xcodegen generate`.
6. **A file that never compiles.** Adding a source file without regenerating means
   it is silently absent — and a test file that never compiles produces a
   confident green run that proves nothing.

---

## What only you can do

Everything in Parts 1, 2, and 5, plus the upload in Part 4 and the device testing
in Part 6. Those need your Apple account and your machine.

Worth stating plainly: the Simulator is DLP-blocked in this environment, so no
assistant session can see this app running. `xcodebuild` archives and tests fine —
what is unavailable is eyes on the screen. A green archive is not a working app,
and a TestFlight round is the first time anyone will actually find out.

---

## After this

Screenshots become the next real blocker, and they are App Store submission work
rather than TestFlight work — captured on your machine, and subject to the same
broadcast rules as everything else in `IP-REVIEW.md`: landscape and architecture,
no vehicle designs, and the world as a caption rather than a headline.

Then the launch channel, which is where `go-to-market` picks up.
