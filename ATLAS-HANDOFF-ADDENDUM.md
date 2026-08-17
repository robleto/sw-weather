# Addendum — monetization model (settled)

The reasoning behind the monetization decisions summarized in
`ATLAS-HANDOFF.md`. The model is decided and built; only the price is open.
Nobody has ever paid for anything, so there is no migration or grandfathering
to worry about.

Counts here were corrected against the code on 17 August 2026.

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

**The gating axis is world content, not slot count.** An early "one editable
slot" model was replaced before shipping. Every slot is freely reassignable for
everyone, but only from a *base* pool of worlds; the rest are premium-only and
render locked/greyed with a lock icon in the picker — visible so free users can
see what they'd get, but not assignable.

That began as 6 premium worlds out of 23. The catalog has since grown to **43
worlds, 22 of them premium**, which is the growth plan working as intended: new
worlds default to premium (`World.isPremium`), enlarging the premium pool over
time without touching the free base set. When the first worlds became premium,
three slot defaults were reassigned away from them (Ilum's "Clear · freezing" →
Hoth, Mortis's "Fog" → Endor, Alderaan's "Clear · cool" → Naboo) so the free
out-of-the-box experience stayed unchanged.

- Free: reassign any of the 26 conditions, but only using the 21 non-premium
  worlds. Single-assign only.
- Premium: every world (locked ones unlock), multi-assign, saved locations,
  and the perks below.

**Search itself stays free for everyone** (see the comment in
`PremiumGate.swift`). An early plan gated it to current location only; that
dead-ends anyone who declines the location prompt and hides the whole app
behind the paywall before they can see what they'd be buying. Saved locations,
not search, is the actual premium hook.

### Feature list, sorted by what each one demands

**Device/iCloud only — no infrastructure, all in the one-time bundle:**
Atlas (locked worlds + multi-assign) · saved locations · alternate app icons ·
home & lock screen widgets · theme packs (one tap assigns a whole chart) ·
share cards (free watermarks, premium doesn't) · faction UI chrome (accent
color, typeface, icon set — extends the per-world `color` shape) · the Passport
(log of worlds actually experienced, with date and city — formerly "Holocron";
specced in `PASSPORT.md` and since **built on both platforms**, and **free to
collect** rather than premium-only: the premium worlds are already unreachable
without a purchase, so the book gates itself)

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
