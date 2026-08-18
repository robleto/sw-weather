# TestFlight — getting a build to real people

Status: **build 1.0 (1) is installed and running on a real device, 2026-08-18.**
Parts 1 through 5 are done. Part 7's first run found **no defects** — forecast path,
Atlas, app icon and analytics all confirmed working.

**Paid Apps Agreement went Active the same day**, along with the bank account and
W-9, so the store blocker is cleared. Run 2 then exercised the whole purchase path on
device against the local StoreKit config: price shown, purchase completed, premium
unlocked, Atlas and Passport and saved locations all correct.

What that does **not** cover is a real transaction through Apple. Re-check the
TestFlight build for `$2.99` — `PremiumStore.start()` attempts the product load once
per launch, so a copy already running must be force-quit before it will retry.

Still pending, EU only: the Digital Services Act trader declaration is In Review.
That gates EU availability, not the purchase test.

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

### The Paid Apps Agreement, and the order nothing tells you

A first paid product needs a **Paid Apps Agreement**, and a brand-new account does
not have one — it has only a Free Apps Agreement. Until the paid one reaches
**Active**, `Product.products(for:)` returns an **empty array** rather than throwing,
so the paywall shows no price and nothing anywhere explains why. This is the default
state of every new developer account, not an edge case.

The sequence that gets there, discovered the hard way on 2026-08-18:

1. **Accept the updated Apple Developer Program License Agreement.** This is the
   gate, and it does not announce itself as one. App Store Connect shows a yellow
   banner saying the Account Holder must accept it; developer.apple.com/account →
   **Agreements** is where the accept action lives. If that page shows nothing to
   accept while the banner persists, it is a stale session — sign in again in a
   private window rather than concluding there is nothing to do.
2. **The Paid Apps Agreement row then appears** under Business → Agreements. There is
   no "request" button and no way to add it directly; it materialises once the
   license agreement is current. Looking for a way to create it is a dead end.
3. **Its status starts at "Pending User Info"** — which is not Active, and does not
   yet let StoreKit return products. Apple is waiting on contact details, banking
   information, and tax forms (a W-9 for a US individual).
4. **Once those are complete the status becomes Active** and products start loading.
   On 2026-08-18 this took under an hour end to end, not the days the wording implies
   — bank account, W-9 and Mexico questionnaire submitted in one sitting, and the
   agreement flipped to Active immediately afterwards. Do not defer this expecting a
   long wait.

Note the retry behaviour once it goes Active: `PremiumStore.start()` is guarded by
`didStart` and `loadProduct()` runs only from inside it, so the app makes exactly one
product-load attempt per launch. An already-running build will not pick up a
newly-active agreement — force-quit and reopen.

Two things follow from this. Everything else in Part 2 can be done while the
agreement is pending, so it should not stall the build. And premium is still
testable in the meantime by running Debug to a device against
`StoreKitConfig/Products.storekit` — see Part 7.

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

That bump only works because `Info.plist` now reads
`$(CURRENT_PROJECT_VERSION)` and `$(MARKETING_VERSION)` rather than literals. It
used to hardcode `1`, which outranked the build setting — so bumping `project.yml`
renamed the archive while still stamping the bundle build 1, and the duplicate was
only discovered after the upload. **Verify before uploading**, since the archive
filename is not evidence:

```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$(ls -td ~/Library/Developer/Xcode/Archives/*/*.xcarchive | head -1)/Products/Applications/galacticweather.app/Info.plist"
```

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

## Part 7 — First run on a real device

**Run 1: build 1.0 (1), 2026-08-18.** Until this build, nothing in this app had
ever been seen running by a human — browser preview and Simulator control are both
DLP-blocked in the environment it was written in, so every feature was built,
unit-tested and shipped without anyone clicking it.

| | |
|---|---|
| Forecast path | ✅ renders |
| Atlas | ✅ nothing erroneous |
| App icon at real size | ✅ |
| Analytics reaching TelemetryDeck | ✅ signals arriving |
| Paywall price | ⚠️ shows `—` — **not a bug, see 2** |
| Everything premium | ⏸ blocked in TestFlight, **testable via Debug on device — see below** |
| Passport hints, iCloud sync | ⏳ untested |

**Run 2: build 1.0 (1) via Debug on device, same day.** With the Paid Apps Agreement
Active and the local StoreKit config supplying the price, the purchase path ran end to
end for the first time in this product's life — `$2.99` displayed, purchase completed,
and StoreKit tagged it `[Environment: Xcode]`, its own marker for a
local-configuration transaction rather than sandbox or production. Premium unlocked,
and Atlas, Passport and saved locations all behaved as expected.

Confirmed incidentally: the saved-locations gate rendered its own paywall copy ("Keep
your favorite destinations") rather than the generic headline, so `PaywallContext` is
working per-gate rather than merely compiling.

**No defects found in either run.** Two runs on an app nobody had ever seen execute,
and nothing wrong with it. The one thing that looked broken was an Apple account state.

Still unverified, and worth not confusing with verified: **Restore Purchases**, a real
sandbox transaction, iCloud sync across two devices, and city search.

Ordered by risk, not by how the app is laid out. Work down it and write what breaks
directly into this section — a finding recorded here is worth more than a finding
remembered.

### Testing premium while the store is unprovisioned

A TestFlight build cannot exercise premium at all right now: the price does not
load, and `debugPremiumOverride` is `#if DEBUG`, so it is compiled out of a Release
build on purpose.

**Run the Debug configuration to a physical device from Xcode instead.** The scheme
already points `run` at Debug with `storeKitConfiguration:
StoreKitConfig/Products.storekit`, so this needs no setup:

- The paywall shows **$2.99** from the local config — App Store Connect is not involved
- Purchases complete locally, cost nothing, and need no sandbox account
- The premium toggle appears in the Account view (`AccountView.swift`), and unlike a
  real non-consumable it flips **both** ways, so the free experience stays testable
- Xcode → Debug → StoreKit → Manage Transactions resets purchases to re-test Restore

Needs Developer Mode enabled on the phone (Settings → Privacy & Security). This is
ordinary Xcode device deployment, not the DLP-blocked Simulator tooling.

**What it does not prove:** that the real App Store Connect product is fetchable,
that a real sandbox transaction settles, or that Restore works across devices via a
real Apple ID. Those need the Paid Applications Agreement. This covers everything
that could be wrong *in the app*, so that when the account is provisioned there is
one thing to verify rather than twenty to debug.

### 1. The plain forecast path

Launch, allow location, see a world. Not Atlas, not Passport — the landed screen.

This is first because it is the highest-risk thing in the build. Atlas rewrote
`page.tsx`'s core render path from `getWeatherDescription` to `getSlotForWeather` +
`resolveWorld`, and the iOS port mirrors that. If it is wrong, everything below is
moot. Also worth trying **city search** as well as geolocation, since a first-run
user who declines the location prompt has only that path.

- [x] Landed screen renders a world, temperature, and condition — **run 1**
- [ ] City search resolves and renders
- [ ] Text over the art is legible — this is what `measure-text-tone.py` generates
      `textColor` for, and it has never been checked against a real screen

### 2. The paywall price — **run 1: showed `—`, diagnosed**

**Root cause: the account has no Paid Applications Agreement.** Business →
Agreements lists only a Free Apps Agreement, so the account is not permitted to
sell anything and `Product.products(for:)` returns an **empty array** — no throw, no
products. Filed with Apple Developer Support; tax and banking verification takes
days.

Everything on this side was correct and is worth not re-checking: product ID
`com.robleto.galacticweather.premium` matches `PremiumStore.productID`, price set to
$2.99 across 175 regions, English (U.S.) localization saved, IAP status "Prepare for
Submission".

So the question this was meant to settle — whether a product in "Prepare for
Submission" is fetchable in sandbox — **is still open**, because the agreement
masked it. Re-check once Paid Applications is Active.

Two things changed as a result:

- The empty case now explains itself rather than showing a bare dash. See
  `PremiumStore.loadProduct()`.
- A brand-new developer account starts with only a Free Apps Agreement, so this is
  the *default* experience of shipping a first paid product, not an edge case.

- [ ] Re-verify once Paid Applications is Active: paywall shows **$2.99** in TestFlight

### 3. The purchase and the restore — **blocked on Apple**

Cannot run in TestFlight until Paid Applications is Active (see 2). Full detail in
Part 6. The short version: sandbox charges nothing, and **Restore Purchases after a
delete-and-reinstall is the test that matters** — it is what proves Apple's ID works
as the account system this app has instead of a backend.

Do the local versions now via Debug on device; they cover the app's own logic:

- [x] Local purchase completes against `Products.storekit`, premium worlds unlock — **run 2, Debug on device**
- [ ] Premium toggle off again restores the free experience intact
- [x] Saved-location cap goes from 1 to 20 — **run 2, Debug on device**
- [ ] …and back to 1 when premium is toggled off
- [x] Multi-assign accepts several worlds on one condition — **run 2, Debug on device**
- [x] **Entitlement survives a relaunch on its own**, with no Restore tap — **run 2, Debug on device** —
      `refreshEntitlement()` runs from `start()` and reads
      `Transaction.currentEntitlements`, so this is the architecture working: Apple's ID
      *is* the account system, and Restore is only a manual nudge for the same mechanism
- [x] **Restore with nothing to restore** reports "No previous purchase found on this
      Apple ID" rather than hanging or silently granting premium — **run 2, Debug on device** — the
      transaction was deleted in Xcode → Debug → StoreKit → Manage Transactions first,
      so inactive was the truth and the app said so
- [ ] Restore tapped *with* a transaction present, completing silently. Both halves are
      verified separately — `AppStore.sync()` did not throw in the negative case, and
      `refreshEntitlement()` is proven by the relaunch — but the success branch has not
      been watched end to end

Then, once the agreement is Active:

- [ ] Real sandbox purchase completes
- [ ] Delete the app, reinstall, Restore Purchases returns entitlement
- [ ] Entitlement appears on a second device on the same Apple ID

### 4. Atlas

- [x] Opens from the header — **run 2, Debug on device**
- [x] Lists all 26 conditions — **run 2, Debug on device**
- [x] Reassigning a condition actually changes the landed background — **run 2, Debug on device**
- [ ] Assignments survive a force-quit
- [ ] Multi-assign rotates by day rather than per render (needs two days, or a
      device date change)

### 5. Passport

- [x] Opens, shows biome grouping and progress — **run 2, Debug on device**
- [x] A stamp is earned by landing on a world — **run 2, Debug on device**
- [ ] **Unfound worlds show a hunt hint** — "Heavy snow or Clear · cold. Winter at
      altitude or high latitude — the Alps, the Rockies, Hokkaido." First time that
      copy exists outside a test assertion.
- [ ] Premium alternates instead show "No forecast leads here — assign it in Atlas"

### 6. The things changed most recently

Least likely to be broken, most likely to look wrong, because none of it has been
seen at real size on a real screen.

- [x] **App icon** on the home screen, legible at real size — **run 1**
- [ ] **Picker banner** reads "N more to swap in here" / "Every condition already
      has a world" — needs checking with premium **off**. Run 2 had it unlocked, so the
      banner was correctly *absent*, which is not the same as verified.
- [ ] Fonts render as intended — Poiret One and Russo One are bundled, and the web
      side had a real bug where a font resolved to a synthetic weight

### 7. iCloud sync

Needs a second device on the same Apple ID.

- [ ] Atlas assignments appear on device two
- [ ] Saved locations appear on device two

This is the entitlement that made Part 1 necessary. If it silently does nothing,
check that the App ID still has iCloud Key-Value Storage enabled and that the
signed build carries `com.apple.developer.ubiquity-kvstore-identifier`.

### 8. Analytics actually arriving

- [x] TelemetryDeck dashboard shows signals arriving — **run 1**

The build was verified to carry a substituted `TELEMETRYDECK_APP_ID`, so signals
should flow. If the dashboard stays empty, that is worth chasing before inviting
anyone else — a round with no data cannot answer the questions in `MEASUREMENT.md`,
which is the entire reason for running it.

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

Everything in Parts 1, 2 and 5, the upload in Part 4, and all of Parts 6 and 7.
Those need your Apple account, your device, and your eyes.

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
