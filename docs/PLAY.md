# Publishing Lodeworks

What is done, what a person has to do, and what is still unknown. The live
version of the first two is generated, not written:

```sh
godot --headless --path . --script res://tools/play_readiness.gd
```

That opens the export preset, the product catalogue, the store assets and the
workflow files and reports each Play requirement as **DONE** (it checked),
**MANUAL** (it genuinely needs a person) or **UNKNOWN** (it needs a build or a
device that does not exist yet). It also regenerates `store/data-safety.md`
from the code's own allowlists, so the Data safety form cannot describe a
binary that does not exist. At the time of writing: **26 done, 11 need a
person, 8 unknown.**

Nothing in this file claims anything has been verified on a real device or in
a real store. Nothing has.

---

## The manual steps, in order

Each one is here because no amount of code can do it. They are stated as
narrowly as possible.

1. ~~Create the GitHub repository and push.~~ **Done 23 September 2026**:
   private `Furkiozknn/lodeworks`, pushed with `tools/push-to-github.sh`. Both
   workflows are green on `main`; the debug APK (with and without plugins)
   and a debug-signed AAB are built on every push (docs/CI.md).
2. **Register a Play Console developer account** and complete Android
   developer verification (government ID for a personal account, a D-U-N-S
   number for an organisation).
3. **Generate an upload keystore** and enrol in Play App Signing. Put the
   keystore and its passwords in GitHub Actions secrets; `tools/build-android.sh`
   injects them at build time and refuses to emit an unsigned bundle. Nothing
   secret is ever committed — `tests/test_release_config.gd` asserts that.
4. **Create the in-app products.** Exactly these, as one-time products, set to
   Active. The ids, titles and descriptions are generated from
   `scripts/core/monetization_db.gd` — run the readiness script and copy them
   rather than retyping:

   | Product id | Type | Suggested tier |
   |---|---|---|
   | `foremans_licence` | one-time, non-consumable | US$3.99 |
   | `foundry_themes` | one-time, non-consumable | US$1.99 |

   The suggested tiers are a starting point with a reason behind them, not a
   decision: review-mining across app stores puts well-received one-time
   purchases in the US$0.99–4.99 band with complaints rising above $5, and the
   idle games the genre holds up as fair keep their priciest single item near
   three dollars (sources in `docs/research/monetization-2026.md`). The game
   never composes a price — it shows whatever the store returns — so the
   console is the only place a number is typed.
5. **Create an AdMob account**, register the app, create one rewarded unit,
   and put the app id and unit id in the export preset's plugin configuration.
6. **Host the privacy policy** at a public https URL and put a real contact
   address in it. `store/privacy-policy.md` is the text; it has a `TODO` where
   the address goes. EU DSA trader status requires a name, address, phone
   number and email on the store page anyway.
7. **Paste `store/data-safety.md`** into App content → Data safety, and answer
   the content rating questionnaire (prepared answers below).
8. **Take the store assets from CI and upload the preview video to
   YouTube.** Every CI build renders the landscape screenshots (1920x1080
   phone, 2560x1440 tablet), the icon, the feature graphic and
   `preview.mp4`, checks them against Play's specs, and keeps them as the
   `screenshots` artifact of the "screenshots render" job. Choosing and
   uploading is a person's job. Play takes the video as a YouTube URL.
9. **Closed testing: 12 testers, 14 continuous days.** A new personal
   developer account cannot reach production without it.
10. **Run `docs/DEVICE-TEST.md` on a real Android phone.** 18 of its 25 checks
    are automated by the on-device self test; 7 need a human looking at the
    screen. Until this happens every performance and input number in this
    project is UNKNOWN.
11. **Buy each product once, as a license tester.** Play's supported test path
    is a license tester buying the *real* product with a test payment
    instrument — the static `android.test.*` ids are no longer in the current
    documentation. Use the slow test card in both directions to exercise the
    PENDING paths that `tests/test_store.gd` covers offline:
    - *Test instrument, always approves* → a normal purchase.
    - *Slow test card, approves after a few minutes* → PENDING, then granted.
    - *Slow test card, declines after a few minutes* → PENDING, then nothing.
    - *Test instrument, always declines* → a failed purchase with the game
      still playable.

---

## Content rating questionnaire — prepared answers

Category: **Game**. Every answer below is a statement about what is actually
in the build; if the build changes, so does the answer.

| Question | Answer | Why |
|---|---|---|
| Violence — realistic or cartoon | No | There is no character and nothing is harmed. The subject is machines in rock. |
| Sexuality | No | None. |
| Language | No | No dialogue at all. Every string in the game is UI or a machine name. |
| Controlled substances | No | None. |
| Gambling, simulated or real | **No** | Nothing in the game has a randomised purchase outcome. The two products are one-time non-consumables with a fixed, stated effect. Procedural stratum modifiers are generated when a stratum is entered and are not purchasable. |
| Loot boxes / randomised paid items | **No** | Asserted by `tests/test_store.gd`: every product is `"consumable": false` and its grants are enumerated in the catalogue. |
| User-generated content or user interaction | No | No accounts, no chat, no leaderboards, no sharing. |
| Shares location | No | The app requests no location permission. |
| Allows purchases of digital goods | **Yes** | Two one-time in-app products. |
| Contains ads | **Yes** | Rewarded video only, opt-in, never interstitial. Removed permanently by one of the two purchases. |
| Target age group | **13+** | Not in Designed for Families. |

---

## What monetization actually is here

Two one-time purchases, no currency, no packs, no subscription, no timers.
`scripts/core/monetization_db.gd` holds the whole catalogue and explains, with
the measurements behind it, why the list is that short. The measurements are
reproducible:

```sh
godot --headless --path . --script res://tools/money_lab.gd
```

The two findings that decided the design:

- **The player never waits.** Over the first 38 purchases the gap between
  affording one machine and the next does not grow — it shrinks, from an
  18.5 s average over the first three to 14.5 s over the last three. There is
  no energy bar, no build timer, no cooldown on anything that matters. So
  there is nothing to sell back, because nothing was taken away, and every
  product type the genre normally reaches for would have to manufacture the
  problem first.
- **Paying buys exactly what watching ads buys.** Simulating a fortnight of a
  twice-a-day player: free 1.000×, free-and-watches-the-ad 1.878×, licensed
  1.878×, bought-it-on-day-7 1.439×. The Licence is not an advantage over a
  free player; it is the same advantage without the thirty seconds. Locked in
  by `test_paying_buys_exactly_what_watching_ads_buys`.

---

## What is NOT verified

Stated here rather than buried, because the temptation to round these up is
the whole reason the project has a rule about it.

- **No signed release build exists.** Debug APKs and a debug-signed AAB are
  built by CI on every push (first green run: APK 162.9 MB without plugins,
  174.3 MB with, AAB 67.7 MB -- debug builds, x86_64 included, unstripped).
  A release size is UNKNOWN until a signed release build exists.
- **CI has run and is green** (`ci` and `android`); a signed release bundle
  has not been built, because no keystore secret exists.
- **Nothing has run on a real Android device.** Every frame-time, memory,
  battery, input-latency and touch figure is UNKNOWN.
- **No purchase has ever been made.** The billing client handles every
  documented state and is tested against records shaped exactly as the plugin
  delivers them, but whether the products are purchasable in a real store
  account is UNKNOWN until somebody buys one.
- **No ad has ever been shown.** The ad layer is written to survive an SDK
  that binds and then misbehaves, and the game is asserted playable with it
  dead, but no real fill has ever happened.
- **The 16 KB page alignment and the Billing Library version** are properties
  of the Godot Android template and the billing plugin, not of this project.
  Check them on the produced bundle.
