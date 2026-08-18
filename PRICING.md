# Pricing — the one-time iOS unlock

Status: **recommendation, 2026-08-18.** Not yet configured in App Store Connect.

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

## The bigger risk is the gate, not the number

Worth flagging plainly, because it drifted without a decision attached:

The addendum specifies **6** premium worlds to start — Ahch-To, Coruscant, Nur,
Ilum, Mortis, Alderaan — with more added later, defaulting new ones to premium.
The catalog has since grown to 43 worlds and **22 of them are now premium.** The
locked share went from about 14% to 51%.

That may be fine. It may also be the single biggest threat to conversion, and it
has nothing to do with price. A first-time user opening Atlas and finding half
the catalog greyed out with lock icons has a materially different experience
from one finding six locked — the first reads as a demo, the second as a
generous app with a little more available. The free tier was carefully designed
so people could "feel the whole loop" before paying; a half-locked catalog works
against that intent.

This is testable rather than arguable. `Premium.paywallShown` already carries a
`context` payload naming which gate sent someone — a locked world, a second
world on one slot, or a second saved location. That distribution will say
whether the locked worlds are driving interest or driving people away.

`PremiumGate.swift` was deliberately written as the single place the free/premium
line lives, so moving it is a one-file edit. Use that. **Tune the gate, hold the
price.**

## Before this goes live

- Configure the product in App Store Connect at $2.99 (Tier 3).
- Exercise the sandbox purchase end to end, including Restore Purchases. Still
  untested, and it is the only revenue path in the product.
- Decide consciously whether 22 premium worlds is the launch ratio, or whether to
  pull it back toward the addendum's original 6 and grow from there.
