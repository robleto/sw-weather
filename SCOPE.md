# Scope — v1.0

Status: **frozen as of 2026-08-18.** This document exists to end the build phase.

Read `CLAUDE.md` for environment rules and `ATLAS-HANDOFF.md` for architecture.
This one answers a narrower question: what is v1.0, what is deliberately not, and
what evidence would justify changing that.

## Why freeze

The engineering punch list is clear and the app has no users. Those two facts
together are the whole argument. Every additional refinement from here is
work whose value cannot be measured, because there is nobody to measure it
against — and the cost of building it is now so low that nothing naturally
stops the loop.

This is a known failure mode, not a personal one: when a change takes an
afternoon instead of a sprint, the price of engineering time stops enforcing
discipline, and the product sprawls past its boundaries one individually
defensible commit at a time. A written scope is the substitute for the
discipline that cost used to provide.

The MVP stage ends when there is evidence, not when the product feels finished.

## What v1.0 is

A weather app that answers "what does today feel like" with a place instead of a
number. The forecast picks a world; the world fills the screen.

**Shipping on both platforms**

- The forecast path: geolocation or city search, resolved to a slot, rendered as
  a world over full-bleed art.
- Atlas — the catalog of worlds, and reassignment of which world a weather slot
  shows. Free and ungated on web.
- Passport — stamps collected by actually landing on a world.
- The utility pages: privacy, terms, support, credits.
- Analytics: six signals, off unless the env key is set, payload keys enforced by
  test on both platforms.

**iOS only**

- Saved locations, synced by iCloud KVS.
- Premium: one-time StoreKit purchase, unlocking the premium world pool and
  saved locations. No subscription, no account, no server.

**Deliberately not in v1.0**

These have been discussed and are deferred, not rejected:

- Alternate app icons.
- Home and lock-screen widgets.
- Curated theme packs.
- Share cards.
- Extended forecast rendered as a strip of worlds.
- Any web premium tier. The free web app is the demo that sells the iOS one;
  gating it would remove the only distribution advantage it has.
- Any backend, account system, or server-side user record.

**Not features, but required before submission**

- A price for the iOS purchase.
- The StoreKit sandbox purchase exercised end to end, including Restore.
- An IP pass over screenshots and marketing copy — landscape and architecture
  only, no vehicle designs. In-app planet names remain an accepted risk; the
  distribution surface is the line.

## Non-goals

Worth stating plainly, because each is a thing this app could drift toward and
should not:

- **Not a weather utility.** Accuracy, radar, hourly precision, severe-weather
  alerts — all of these are better served by apps that exist. Competing on
  forecast quality is a losing fight and dilutes the only interesting idea.
- **Not a social product.** No feed, no friends, no leaderboard of who has more
  stamps. The Passport is a private record.
- **Not a content pipeline.** No authored lore, no seasonal events, no
  battle-pass cadence. The appeal is that real global weather is the game board
  and nothing needs writing.
- **Not cross-platform-identical.** Web and iOS keep separate books by design.
  That is a consequence of having no backend and it is an accepted trade.

## Amendment criteria

The question is not "should we build this?" It is **"has a critical mass of
users told us they cannot get value without it?"**

A v1.0 addition needs one of:

1. It is broken, not missing. Bugs are always in scope.
2. App Store review requires it.
3. Multiple unrelated users independently asked for the same thing, unprompted,
   and its absence is why they stopped using the app.

Founder enthusiasm is not evidence. Neither is a single request, a friend's
suggestion, or the fact that it would only take an afternoon. Anything that
clears none of the three bars goes on the deferred list above and waits for
v1.1.

If an idea genuinely will not wait, the honest move is to amend this document
and say why in the commit — not to build it quietly.
