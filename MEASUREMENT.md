# Measurement — what counts as working

Status: **written 2026-08-18, before launch and before any user data exists.**

That timing is the point. Benchmarks chosen after the numbers arrive are chosen
to flatter them. Everything below was set while there was nothing to defend.

The instrumentation this describes is the six signals in
`shared/analytics-signals.json`. Read that file first — it is the contract, and
each signal already carries the question it exists to answer.

## North Star

**Returning landers: distinct clients that reach `Forecast.landed` in a given
week, having also reached it in a prior week.**

Not launches, not installs, not stamps. Landing on a forecast is the moment the
product delivers its one idea, and doing it again a week later is the only
evidence that the idea survived contact with novelty wearing off.

`App.launched` plus the durable client ID yields retention on its own, which is
why the contract notes it. Pairing it with `Forecast.landed` filters out
launches where location permission or search failed and the person saw nothing
worth returning for.

## The funnel, mapped to what is actually instrumented

| Stage | Signal | What it tells you |
|---|---|---|
| Acquisition | *not instrumented* | No channel attribution by design — see the gaps section |
| Activation | `Forecast.landed` | The core path worked and a world appeared |
| Engagement | `Atlas.opened` → `Atlas.worldAssigned` | Curiosity converting into intent |
| Engagement | `Passport.stampEarned` | Whether the collection loop caught anyone |
| Retention | `App.launched` + client ID | Whether anyone came back |
| Revenue | `Premium.paywallShown` → App Store Connect | Offer-to-purchase conversion |

**Activation is `Forecast.landed`, not install.** Someone who installs, denies
location, never searches a city, and quits has not experienced the product at
all. Counting them as a user who churned confuses a permissions problem with a
product problem, and those have completely different fixes.

## Benchmarks

Generic consumer-app retention bars, adopted deliberately rather than invented:

| Point | Bar | Reading |
|---|---|---|
| D1 | >25% | First impression landed |
| D7 | >15% | Something habit-shaped is forming |
| D30 | >10% | It stuck |

An honest caveat on these: a weather app has a natural daily occasion, which
should push retention *up* relative to a typical consumer app. A novelty toy
with no notifications, no account, and nothing to lose by not opening it pushes
*down*. Those two forces are in genuine tension and which one wins is precisely
the open question. If D7 lands well under 15%, the daily-occasion advantage did
not materialize and the novelty read is the correct one.

Secondary bars, less load-bearing but worth watching:

- **Atlas opened → assigned above 30%.** The contract calls the gap between
  these "the interesting number." A wide gap means Atlas is decoration people
  look at once, not a feature they use.
- **Any stamps earned in a session after the first.** One burst of stamps on day
  one is a checklist being cleared, not a hunt being played.
- **Paywall shown → purchase above 2%.** Below that, either the premium pool is
  not compelling or the gate fires at the wrong moment.

## What a false positive looks like here

The MVP playbook's warning is that launch energy comes from ephemeral forces and
none of them predict week six. These are the specific shapes that would look
like success for this app and would not be:

1. **The launch-day spike.** Friends, a Hacker News thread, a subreddit. Every
   acquisition number is excellent for 48 hours and D7 is near zero. This is the
   most likely false positive by a wide margin, and the only defense is refusing
   to read anything into week one.
2. **The one-session collector.** `Passport.stampEarned` fires many times on day
   one and never again. That is someone clearing a checklist out of curiosity,
   which feels identical to engagement in aggregate stamp counts and is the
   opposite of it.
3. **Atlas as a museum.** High `Atlas.opened`, near-zero `Atlas.worldAssigned`.
   People are looking at the catalog, which is pleasant, and not customizing
   anything, which means the feature is not doing the job it was built for.
4. **Revenue without retention.** Someone buys premium in their first session
   and never returns. This is the most flattering possible number and the least
   meaningful — a purchase is evidence of an appealing *offer*, not an appealing
   *product*. Any purchase-rate reading must be paired with whether purchasers
   come back.
5. **Weather doing the work.** A blizzard drives a Hoth spike; a heat wave
   drives Mustafar. Traffic that tracks weather events rather than user habit is
   the world reminding you it exists, not evidence anyone chose your app.

## Deliberate measurement gaps

These are not oversights, and nobody should later add instrumentation to close
them without re-deciding the trade:

- **No acquisition attribution.** No campaign parameters, no referrer capture,
  no install source. Channel performance will have to be inferred from timing
  and whatever the App Store reports.
- **No city, coordinates, search queries, or world names.** The
  `payloadKeyAllowlist` excludes them and both test suites enforce it. Slot IDs
  answer the same product questions in generic weather vocabulary and carry none
  of the catalog's IP exposure.
- **No cross-platform identity.** Web and iOS keep separate books. A person
  using both is two clients and there is no way to know otherwise.

The cost is that some questions are unanswerable. That was the trade, and it is
the right one for an app whose entire architecture is "no backend."

## The decision rule

Read nothing in week one. From week two, the questions in order:

1. Did anyone come back? (D7 against the bar)
2. Did the ones who came back do the thing? (`Forecast.landed` on return)
3. Did anyone go deeper? (Atlas assigns, stamps after session one)
4. Did anyone pay, and did payers stay?

**After three iteration cycles without movement toward these bars, stop
iterating and run the diagnostic instead:** is there a segment behaving
differently from the rest; is the gap between designed and experienced value a
positioning problem or a product problem; and what would have to be true for
this product to find fit given what the data actually shows.

Two qualitative instruments worth more than any dashboard at this scale:

- **The Sean Ellis test.** Ask active users how they would feel if they could no
  longer use it. Above 40% "very disappointed" is a real signal.
- **The effort test.** Before fit, retention needs constant pushing — outreach,
  posting, telling people. After fit, the product does that work itself. When it
  starts pulling instead of being pushed, something changed.

Disconfirming evidence here is the system working. It surfaces before the
over-investment, which is the entire reason for writing this down first.
