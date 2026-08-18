# Pricing — the one-time iOS unlock

Status: **$2.99 flat, decided 2026-08-18. Not yet configured in App Store
Connect.** Two alternatives were considered and rejected — planet packs sold on top
of premium, and a price ladder tied to catalog growth. Both are recorded below with
the reasoning, because the question resurfaces.

`ATLAS-HANDOFF-ADDENDUM.md` settled the *model* — one non-consumable StoreKit
purchase, iOS only, no subscription. This document settles the *number*, and
records the reasoning so a future change is a decision rather than a drift.

## Recommendation: $2.99

Apple's Small Business Program takes 15% under $1M/yr, so that nets **$2.54 per
sale**.

## Why a one-time price is safe, not just simpler

The original handoff left this open as "one-time price for cosmetics vs.
subscription for anything costing recurring API calls." That worry can now be
closed, because the recurring cost is effectively zero at any scale this app
will plausibly reach soon.

Both platforms call `data/2.5/weather` and `geo/1.0/direct` — the classic
OpenWeather endpoints, whose free tier runs at 60 calls/minute and roughly
1,000,000 calls/month. This is *not* the One Call 3.0/4.0 path with its
1,000-calls-per-day cap, which is the number most pricing discussions assume.

Rough sizing against that ceiling, with the existing 2-minute weather cache and
24-hour geocode cache:

| User type | Calls/month, roughly | Users before the free ceiling |
|---|---|---|
| Casual — opens twice a day | ~60 | ~16,000 |
| Heavy premium — pages 5 saved spots, twice a day | ~300 | ~3,300 |

The app has zero users. Recurring cost is not a pricing constraint and will not
become one before there is revenue to pay for a tier upgrade. A subscription
would be charging monthly for something that costs nothing monthly, which is
the kind of thing users notice and resent.

## Why $2.99 and not more

The instinct is to anchor against weather apps. That is the wrong comparable
set, and `SCOPE.md` says why: this is explicitly **not a weather utility.**
CARROT and Hello Weather sell forecast accuracy, radar, and alerts — real
utility that justifies $36 lifetime or a recurring plan. Galactic Weather sells
an aesthetic and a collection loop. Anchoring on utility pricing invites the
comparison it would lose.

The right frame is an impulse-tier content unlock:

- **$0.99 reads as a token.** It would undersell 22 worlds and cheapen the
  catalog the purchase is meant to make feel worth having.
- **$2.99 is below the deliberation threshold.** Nobody opens a spreadsheet.
  That matters for a product whose value proposition is "this is delightful"
  rather than "this solves my problem."
- **$4.99 is defensible on content** — it matches the Weather 360 Pro premium
  IAP, and 22 worlds plus a 20× increase in saved locations is arguably worth
  it. It is the right price *if* the audience turns out to be collectors rather
  than casual weather-checkers. That is currently unknown.

The tiebreaker is not revenue, it is **sample size.** With no users, the goal of
v1.0 pricing is to learn the `Premium.paywallShown` → purchase rate at all. A
price nobody pays teaches nothing. $2.99 maximizes the chance of getting enough
purchases to read a conversion number.

It is also the safer direction to be wrong in. Raising a one-time price later is
painless — existing owners keep what they bought, and nobody is grandfathered
into anything awkward. Lowering a price after launch trains people to wait for
the next discount and reads as a product that did not sell.

## The gate is structural, not a ratio — correcting an earlier reading

An earlier version of this document flagged the locked share as possibly the single
biggest threat to conversion: the addendum planned **6** premium worlds, the catalog
grew to 43, and **22** ended up premium — from roughly 14% locked to 51%. Half a
catalog behind lock icons sounded stingy, and it looked like drift with no decision
attached.

Reading the actual data killed that concern. The split has zero exceptions:

| | Count | What they are |
|---|---|---|
| Slots (weather buckets) | 26 | Each needs a world to display |
| **Free worlds** | **21** | **Exactly the set that are slot defaults** |
| **Premium worlds** | **22** | **Exactly the set that are not defaults** |

Every free world is some slot's default. Every premium world is not. Five free
worlds cover two slots each, which is how 21 worlds fill 26 slots.

So the line is not a percentage someone picked. It is **free gives you a complete
app — every weather condition has its world — and premium gives you the alternates
to reassign.** That is a fair and legible story, and 51% is the wrong way to read
it.

The consequence for the product: **cutting the catalog down is far more expensive
than it looks.** Reducing to ~20 worlds would cut into the 21 defaults, so slots
would lose their world and the free out-of-the-box experience would break — while
deleting the 22 non-defaults that are the entire premium tier. There would be
nothing left to sell.

What remains true is that the *framing* matters more than the ratio. A picker that
reads "these are alternates you can swap in" lands very differently from one that
reads "half of this is locked." That is copy, not architecture.
`Premium.paywallShown` carries a `context` payload naming which gate fired, so the
question stays measurable. `PremiumGate.swift` remains the single place the line
lives if it ever needs moving.

## Rejected: planet packs sold on top of premium

The idea: shrink the catalog to ~20, then sell packs of new worlds as add-ons to
people who already paid. It is rejected, for four reasons in descending order of
weight.

**It requires a content pipeline the product was designed to avoid.**
`PASSPORT.md` states the appeal outright — "Nothing about this needs a backend, a
season pass, or new artwork." Packs are a season pass. Every world is hand-painted,
so each pack is real recurring production cost carried by one person against small
per-pack revenue.

**It breaks a promise already written into the code.** The addendum settled on "buy
once, own forever. Not a subscription." Someone who pays for a thing called Premium
and then meets more paywalls was sold something narrower than the label, and that
resentment lands hardest on the users who paid.

**It makes the Passport worse.** The catalog is the game board. Fragment it across
purchases and a complete Passport becomes something you buy in tiers rather than
hunt, which inverts the design.

**And it is not free to build.** Entitlement today is one boolean read from
`Transaction.currentEntitlements`. Packs mean per-product entitlement, more App
Store Connect records, more restore paths, more iCloud KVS state — real work
against zero evidence that anyone will pay $2.99 even once.

## Rejected: a price ladder tied to catalog growth

The first version of this document recommended holding $2.99 now and raising it
toward $4.99 as the catalog grew, since the addendum already plans to default new
worlds to premium. That recommendation was **inconsistent with the paragraph above
it** and is withdrawn.

Rejecting packs partly because they demand a content pipeline, then proposing a
price ladder that depends on catalog growth, is the same treadmill with the revenue
removed. The distinction that actually holds is **obligation, not effort**: unpaid
additions create no expectation, right up until revenue starts depending on their
cadence. At that point growth becomes load-bearing, and load-bearing is the
treadmill.

**So: $2.99 flat, and catalog growth is not a strategy.** New worlds are something
to add when there is an appetite to paint one — a gift, never a roadmap item, never
something the business leans on.

## Why that is safe: the depth axis is weather rarity, not catalog size

Holding the catalog still costs nothing, because the Passport's difficulty was never
a function of how many worlds exist. It comes from physics.

Of the 26 slots, some are findable any day anywhere — `clear_temperate`,
`clear_cool`, `clouds_temperate`, `rain_light`. Others are genuinely hard:
`clear_scorching` needs 99°F *and* clear sky, which in January is a short list of
places on Earth; `smoke`, `dust`, and `clear_freezing` are rare and geographically
narrow; `thunderstorm` has to be happening somewhere right now.

**43 stamps, several of them weather-gated, is already more than anyone will
finish.** A 44th world adds one stamp to a set nobody has completed. This is what
"more is not necessarily better" means concretely.

The depth that *is* untapped costs no art: **a per-world hint on how to find it** —
"needs 99°F and clear; think southern hemisphere in January." One line of static
copy per world, in the voice `PASSPORT.md` already uses, turning a checklist into a
puzzle. Words, not painting, and no obligation attached.

## The real answer to the revenue ceiling: the posters

A one-time $2.99 caps in-app lifetime revenue at **$2.54 net** after Apple's 15%.
That ceiling is real, and packs were an attempt to raise it. There is already a
better instrument, and it is already shipped.

Both platforms link to physical poster sales from inside the world-poster view —
`WorldPoster.tsx` and `WorldPosterView.swift`, at the most engaged moment in the
app, when someone is looking at a world their own weather matched.

| | Packs | Tip jar | Posters |
|---|---|---|---|
| Monetizes art already painted | no | n/a | **yes** |
| Apple's cut applies | yes | yes | **no** |
| Creates content obligation | **yes** | no | no |
| Fragments the Passport | **yes** | no | no |
| Price point | low | low | **highest** |

Each of the 43 worlds is already a permanent SKU. Painting a 44th adds one; painting
none costs nothing. **The app's commercial job is to make someone want a poster of
the world their weather matched** — which is a better business than selling planet
packs, and it is the one already set up.

A **tip-jar IAP** — a StoreKit purchase that unlocks nothing, usually consumable so
it can repeat — is the other option with no obligation attached. It is worth
knowing about and worth very little: a pressure valve for the few people who want to
give more than $2.99, not a revenue plan. Low effort, low return, no downside.

If more in-app revenue is wanted later, prefer the **one-off builds** already on the
planned list: widgets, alternate app icons, share cards, the extended-forecast
strip. Their defining property is that each is built once and never needs feeding.

## Before this goes live

- Configure the product in App Store Connect at **$2.99**.
- ~~**Make `StoreKitConfig/Products.storekit` match.**~~ **Done** — set to
  **$2.99**. Worth being precise about what that did and did not fix: that file
  supplies the price **only in the Simulator**. Sandbox and TestFlight read it from
  App Store Connect, so until the product is created there the beta has no price at
  all, and once it exists the two can disagree again. Nothing in the app hardcodes a
  number — `PremiumStore.displayPrice` always returns StoreKit's own localized
  string — so a disagreement shows up as a wrong price on the paywall rather than as
  a bug.
- Exercise the sandbox purchase end to end, including Restore Purchases. Still
  untested, and it is the only revenue path in the product. See `TESTFLIGHT.md`
  Part 6.
- ~~Decide whether 22 premium worlds is the launch ratio.~~ **Answered:** yes. The
  split is structural — 21 defaults free, 22 alternates premium — not a ratio to
  tune. See the gate section above.
