# Addendum — monetization model (settled)

Follow-up to `ATLAS-HANDOFF.md`. That doc left the paywall as an open
question. It's now decided. Paste everything below the divider.

---

## Addendum to the Atlas handoff — the paywall model is now settled

This supersedes the "What is NOT done → no paywall" section. Nobody has ever
paid for anything, so there is no migration or grandfathering to worry about.

### Entitlement: StoreKit, iOS only, one-time

- **Premium exists only in the iOS app.** The web app stays entirely free and
  ungated.
- **One non-consumable in-app purchase** — buy once, own forever. Not a
  subscription.
- Entitlement is read from `Transaction.currentEntitlements` on device. Apple's
  ID *is* the account system: no login, no users table, no server, no receipt
  validation backend. "Restore Purchases" is a few lines.
- Apple takes 15% under $1M/yr via the Small Business Program.

**Do not add any gating, paywall, or premium check to the web app.** The free
web Atlas is deliberate — it's the demo that drives people to the paid
iOS app, and it costs nothing to run since preferences are device-local.

### Sync: iCloud Key-Value Store, not a backend

Use `NSUbiquitousKeyValueStore` for iOS Atlas and saved locations. It's
a synced `UserDefaults` — Apple replicates it across every device on that Apple
ID, free, with no accounts and no server. Limits are 1 MB and 1024 keys, far
beyond what a set of assignments plus saved locations needs.

This is the decision that buys the most runway: **saved locations sync across
someone's devices on day one with zero infrastructure.**

### Free vs. premium on iOS

**Superseded again — the gating axis changed from slot-count to world-content.**
The original "one editable slot" model was replaced before shipping: every
slot is now freely reassignable for everyone, but only from a *base* pool of
worlds. A subset of worlds (6 to start: Ahch-To, Coruscant, Nur, Ilum, Mortis,
Alderaan) is premium-only and renders locked/greyed with a lock icon in the
picker — visible so free users can see what they'd get, but not assignable.
Reassigning three slot defaults away from the newly-premium worlds (Ilum's
"Clear · freezing" → Hoth, Mortis's "Fog" → Endor, Alderaan's "Clear · cool" →
Naboo) kept the free out-of-the-box experience unchanged. The plan is to add
30-40 more worlds later, defaulting new ones to premium (`World.isPremium`),
growing the premium pool over time without touching the free base set.

- Free: reassign any of the 22 conditions, but only using non-premium worlds
  (17 to start). Single-assign only.
- Premium: every world (locked ones unlock), multi-assign, saved locations,
  and the perks below.

~~current location only~~ — superseded earlier during implementation: search
itself stays free for everyone (see the comment in `PremiumGate.swift`).
Gating location lookup dead-ends anyone who declines the location prompt and
hides the whole app behind the paywall before they can see what they'd be
buying. Saved locations, not search, is the actual premium hook.

### Feature list, sorted by what each one demands

**Device/iCloud only — no infrastructure, all in the one-time bundle:**
Atlas (locked worlds + multi-assign) · saved locations · alternate app icons ·
home & lock screen widgets · theme packs (one tap assigns a whole chart) ·
share cards (free watermarks, premium doesn't) · faction UI chrome (accent
color, typeface, icon set — extends the per-world `color` shape) · the Passport
(log of worlds actually experienced, with date and city — formerly "Holocron";
now specced as a full scavenger hunt in `PASSPORT.md`, and **free to collect**
rather than premium-only: the 7 premium worlds are already unreachable without
a purchase, so the book gates itself)

**Recurring API cost, still no accounts:**
Extended forecast — 7 days as a strip of seven different worlds. Visually the
strongest thing the app could do, but more calls per user forever. Decide
separately whether it belongs in the one-time bundle.

**Requires a real backend — deferred:**
Notifications. Needs device tokens and a scheduler. This is the *only* item that
forces server infrastructure.

### The line to watch

A backend becomes necessary only for: cross-platform sync (assignments made on
iOS appearing on the web — this is what forces real accounts, since Apple's identity
doesn't extend to your website), push notifications, or anything
server-computed. **Favorites do not cross that line.** Don't build accounts for
them.

Pricing shape follows from this: one-time purchase for the no-infrastructure
bundle now; a subscription tier introduced later and separately *if* and when
notifications or heavy forecast usage arrive.

### Practical implications for work in flight

- Web Atlas: no gating code. Ship it free.
- iOS Atlas: persist via iCloud KVS from the start, not plain
  `UserDefaults` — retrofitting sync later means migrating everyone's stored
  assignments.
- Gate on a single `isPremium` boolean derived from StoreKit. Keep that check in
  one place so the free/premium split stays easy to move while pricing is still
  being tuned.
- Nothing is locked in commercially yet. Price, and which perks sit behind the
  wall, can still change right up until launch.
