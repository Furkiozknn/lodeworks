# How idle games actually make money, and what that means here

Researched September 2026. Every claim below carries the URL it came from.
Anything that could not be verified is marked **UNVERIFIED** and was kept out
of the reasoning rather than rounded up into a plausible number. Several
things I wanted — genre-specific rewarded-video eCPM, the exact price of
Idle Miner Tycoon's ad-removal bundle — could not be confirmed and so are not
used anywhere in the design.

The question this was gathered to answer was not "how do idle games make the
most money". It was **"what do the idle games their own players respect charge
for, and why"**, because Lodeworks is a game somebody is meant to keep on
their phone for months.

---

## 1. The respected games sell one thing, once

- **Melvor Idle.** The wiki states the Full Version is *"a one-time unlock,
  there is no ongoing membership fee"*.
  <https://wiki.melvoridle.com/w/Full_Version> · Steam price today $9.99
  <https://store.steampowered.com/app/1267910/Melvor_Idle/>. The developer has
  said in a Steam thread that the Steam price exists because Steam bars
  linking Patreon or PayPal, and that mobile instead sells a one-time
  ad-removal IAP.
  <https://steamcommunity.com/app/1267910/discussions/0/2999925876006176625/>
- **NGU Idle.** The Steam page is Free To Play with in-app purchases, but
  frames spending as support rather than need — *"toss me some cash because
  you want to, not because you need to"*.
  <https://store.steampowered.com/app/1147690/NGU_IDLE/>
- **Egg, Inc.** Premium currency ("Golden Eggs"), earnable or purchasable.
  PocketGamer.biz calls it the genre's gold standard specifically because it
  is transparent about offline-earning caps and does not gate meaningful
  progress behind spending, and states the single highest-priced Golden Egg
  IAP is **$3**.
  <https://www.pocketgamer.biz/comment-and-opinion/63770/egg-inc-idle-games-gold-standard/>
- **Antimatter Dimensions (mobile).** Listing shows ads and in-game purchases;
  a reviewer on the listing states progress *"with no spending and no ad
  watching is 100% doable"*.
  <https://play.google.com/store/apps/details?id=kajfosz.antimatterdimensions>
- **Idle Miner Tycoon.** The developer's own help centre documents a "No Ads
  Bundle" — permanent ad removal bundled with one-time boosts — and says the
  price varies by OS and location. The Play listing says "no forced ads".
  <https://kolibri-games.helpshift.com/hc/en/3-idle-miner-tycoon/faq/98-what-is-the-no-ads-bundle/>

**The counter-example.** Idle Champions of the Forgotten Realms draws
sustained backlash for its "Patron" premium currency and season passes. Steam
forum: *"why I refuse to spend money on a free to play pay to win game."*
<https://steamcommunity.com/app/627690/discussions/0/3886101131589342423>

**The middle case, and the warning.** Idle Slayer's premium currency buys
*permanent* power — its own wiki lists weapons at +10% and +35% CpS bought
with Jewels of Soul.
<https://idleslayer.fandom.com/wiki/In-App-Purchases> That is a soft
pay-to-win design, and it is exactly the line Lodeworks is not crossing.

---

## 2. What the price should be

- Aggregated app-review analysis puts well-received one-time ad removal in the
  **$0.99–$4.99** band, with complaints rising above $5. The same analysis
  finds pay-to-win *"the clearest pattern in negative reviews"* and that weekly
  subscriptions are called manipulative more often than monthly ones.
  <https://appfollow.io/blog/what-mobile-game-players-want-monetization-insights-from-app-store-reviews>
- Idle Slayer's paid Steam build, sold as the pay-once alternative to the
  free ad-supported mobile one, launched at **$4.99**.
  <https://steamcommunity.com/app/1353300/discussions/0/2792747775850483993/>

Hence the suggested tiers in `docs/PLAY.md`: $3.99 and $1.99, both inside the
band, with the more expensive one below the point where the complaints start.
Neither is in the code; the game shows whatever the store returns.

---

## 3. Ads

- Genre revenue split is roughly **60–70% ads, 30–40% IAP**.
  <https://adjoe.io/glossary/idle-games-mobile/>
- Deloitte's mobile-gaming-ads survey, via eMarketer: **52%** would abandon a
  session after multiple disruptive ads, **20%** would quit the app entirely,
  **14%** would leave a negative review. Comscore's 2024 State of Gaming
  Report: **50%** of gamers want ad skip options, **45%** don't mind ads if
  they are rewarded.
  <https://www.emarketer.com/content/poor-in-game-ads-push-1-5-mobile-gamers-quit-threaten-brand-loyalty>
- General mobile (not idle-specific) rewarded-video eCPM averages ~$15.15
  against ~$12.65 for interstitial.
  <https://business.mistplay.com/resources/rewarded-ads-stats>
  **UNVERIFIED for this genre** — no idle-specific eCPM or opt-in rate could
  be found, so no revenue estimate appears anywhere in this project.
- A designer's teardown of Idle Restaurant Tycoon documents the standard
  reward shapes: 1 ad = 2× offline earnings, 1 ad = a time skip, stacked
  temporary multipliers, currency grants — observed at ~25 ads in a 35-minute
  session.
  <https://davidmogaming.medium.com/masters-of-ad-placements-idle-restaurant-tycoon-empire-b50e531ef3db>
  A teardown of Idle Theme Park Tycoon records the author skipping rewarded
  ads because the reward's value wasn't legible against the 30–60 second cost.
  <https://martinjurasek.substack.com/p/900-seconds-with-idle-theme-park>

The second of those is why Lodeworks has exactly one rewarded placement, on
the offline panel: it is the only moment where the game has already printed
the exact value of the reward before asking.

---

## 4. What Google Play requires of the implementation

- **Pending transactions are mandatory for one-time products.** *"Your app
  must enable and support pending transactions for one-time products."* A
  PENDING purchase must not grant entitlement and must not be acknowledged —
  the acknowledgement window opens only on the transition to PURCHASED.
  <https://developer.android.com/google/play/billing/integrate>
- **Acknowledge within three days** or the purchase is automatically refunded
  and the entitlement revoked. Same source.
- **Call `queryPurchasesAsync` on connect and in `onResume`**, to catch
  purchases made on another device, redeemed from a promotion, or transitioned
  out of PENDING while the app was not running. Same source.
- **`ITEM_ALREADY_OWNED`** usually means a previous unacknowledged purchase;
  the recommended response is to query purchases rather than show an error.
  <https://www.revenuecat.com/blog/engineering/google-play-edge-cases/>
  That source also recommends reconnecting with exponential backoff and a
  retry ceiling after `onBillingServiceDisconnected`, and retrying failed
  acknowledgements.
- **Testing uses real product ids**, not the old static `android.test.*` ones,
  which no longer appear in the current testing documentation. License testers
  get test payment instruments including *"two test instruments for delayed
  forms of payment where the payment automatically completes or cancels after
  a couple of minutes"* — which is how the PENDING paths get exercised for
  real. <https://developer.android.com/google/play/billing/test>
- **One-time product copy limits:** display name up to **55 characters**
  (20 or fewer recommended so it fits one line), description **"200 single
  byte characters or less"**.
  <https://developer.android.com/guide/playpoints/create-products-one-time>

Every one of those became either code in `scripts/services/store.gd` or a test
in `tests/test_store.gd`. The 200-character cap in particular did the copy a
favour: it took a bullet reading "No ads, ever — the offline bonus is simply
always on" down to "No ads, ever", which is the better sentence.

---

## 5. What this research changed

Before it, the plan was one product and a vague sense that more would be
worse. After it:

1. **The catalogue stayed small, but for a reason that can be stated.** Every
   product type the genre reaches for — time skips, currency packs, starter
   packs — needs a wait to sell back, and `tools/money_lab.gd` measured that
   Lodeworks has none.
2. **A second product became defensible.** Cosmetics are the one thing the
   respected games sell without their communities objecting, and in a game
   drawn entirely from a colour table they cost nothing to make and can be
   *proven* to have no economic effect, because the simulation never imports
   the palette.
3. **Three real defects in the billing client were found and fixed.** A
   PENDING purchase was being granted on arrival and acknowledged while
   pending; `ITEM_ALREADY_OWNED` was surfaced as an error to somebody who had
   already paid; and a failed acknowledgement was never retried, which Google
   turns into an automatic refund after three days. None of those would have
   shown up in testing without a delayed payment instrument.
