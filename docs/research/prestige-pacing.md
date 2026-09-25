# How long a prestige layer lasts: reference points for the collapse decision

*25 September 2026. Written for the owner's decision on the collapse payout
and the size of the permanent tree (docs/GAP-AUDIT.md, B-2). Web research
only; nothing here was measured in Lodeworks except the numbers quoted from
`tools/journey_lab.gd`, `LODEWORKS_JOURNEY=collapses`.*

**Source labels.** **[P]** primary: a developer talk, slides or article.
**[W]** a fan wiki, read from its raw source. **[A]** a player anecdote or
community guide. **UNVERIFIED**: looked for, not found. Most reference times
are wall-clock and include idle and offline hours; the Lodeworks numbers
are active play only, so the two are not directly comparable.

## 1. How long the first prestige takes

- **Designer guidance** (Pecorella, GDC Europe 2016) [P] gives no target
  duration. It is qualitative: "Ensure that players reach a valuable
  prestige point regularly", and the questions "Will their progress through
  the early part be quick?" and "Will they be able to get noticeably farther
  than last time?"
- **AdVenture Capitalist** [W]: "A good target for the first reset is between
  50 and 150 Angel Investors, which can be achieved in a day or two with
  reasonably efficient play", which makes the next session x2-4.
- **Antimatter Dimensions** [W, community guide]: first Infinity "a few hours
  to a couple days", first Eternity "a couple days to a week", first Reality
  "a week to a month". "Whereas your first Eternity may have taken a week,
  your second one may take an hour."
- **NGU Idle** [W]: the first rebirth when "your number [is] at 2", i.e.
  twice as strong; minimum rebirth 3 minutes; long runs are rewarded.
- **Cookie Clicker** [W]: recommended first ascension at 365 heavenly chips.
  How long that takes: UNVERIFIED.
- **Egg, Inc.**, **Idle Slayer**, **Realm Grinder**: time to the first reset
  UNVERIFIED. **Idle Miner Tycoon** [W] caps prestige at six levels per mine
  and spreads it across many mines.
- A hobbyist post [A] advises the first prestige "within 10-15 minutes".

## 2. How long a permanent layer lasts, and what keeps it going

- **Pecorella 2016** [P]: "Do you want the cycles to get faster, slower, or
  vary? Faster: players will shift prestige point to be a lot higher.
  Slower: could get tiresome, must have a meta prestige too." Prestiges "can
  be nested".
- **The payout formula** (Pecorella, *The Math of Idle Games, Part III*,
  2017) [P] sets how much more a player must earn to double the prestige
  currency: about 4x for square-root payouts (Realm Grinder, AdVenture
  Capitalist), 8x for a cube root (Cookie Clicker), "128 (2^7) times as
  much" for Egg, Inc.
- **Permanent trees are priced across many orders of magnitude** [W]:
  Cookie Clicker's heavenly upgrades run from 1 chip to about 1.9x10^16
  against a recommended first ascension of 365; Idle Slayer's 112 ascension
  skills cost 2 to 180,000,000 points, about 5.7x10^8 in all, against a
  first ascension of 20.
- **Layers** [W]: Realm Grinder goes Abdication, Reincarnation (each costs
  1,000 times more than the last), Ascension; Clicker Heroes' Transcendence
  holds several Ascensions each; Antimatter Dimensions' layers each take
  about an order of magnitude longer than the one before.
- **How many cycles a layer lasts**: no primary source gives a number.
  UNVERIFIED.

## 3. Rules of thumb for the multiplier

- Pecorella 2016 [P]: "Common rule of thumb is to reset when you would gain
  somewhere in the range of +50% to +200% prestige currency." The only
  primary-source rule found.
- AdVenture Capitalist [W]: reset "after the Angel Investor number is at
  least doubled". NGU Idle [W]: first rebirth at about x2.
- "Each prestige should make the next run 2-3x faster": UNVERIFIED; no
  designer source says it.

## 4. Retention context

- GameAnalytics 2026 benchmarks (calendar 2025, all genres) [P]: median D1
  about 22%, D7 just under 4%, D30 0.68-0.79%; the top 1% reach D1 64-68%
  and D30 13-15%. No genre split in that report.
- One idle title [P]: Gold & Goblins, "a 50% D1 retention rate and a 10% for
  D30" (AppQuantum, in AppMagic's 2022 overview on IGDA).

## 5. Against the measured Lodeworks numbers

**Arithmetic on what the lab measured** (a competent player who builds what
"What now?" names and collapses after a 15-minute stall):

- Payout grew x2.2 from run 1 to run 2 (76 to 167 Cores) while the run got
  shorter (78 to 54 minutes) and deeper (stratum 15 to 19).
- At the second collapse the gain was +220% of the Cores held, just above
  Pecorella's +50-200% band: an early reset is normal behaviour here.
- The whole tree the game offers costs 351 Cores, 4.6 times the first
  payout. The reference ratios are of another order: about 3x10^7 (Idle
  Slayer, tree against first ascension) and 5x10^13 (Cookie Clicker, top
  node against the recommended first ascension).
- None of the reference games has a permanent layer that runs out after
  three or four resets. Each keeps the reset worth taking with at least one
  of: costs that grow exponentially, a sublinear payout, a nested next layer.

**Inference, not evidence:**

- The first collapse at 78 active minutes and the x2.2 growth per run look
  within genre norms. The outlier is the size of the tree, not the payout.
- Once the tree is finished a collapse has no purpose left unless something
  new opens at about the same time (Pecorella: "must have a meta prestige
  too").
- Options, smallest first: (1) geometric or repeatable top nodes so the
  tree's total is far above a run's payout; (2) a square- or cube-root on
  the Cores formula, which slows the growth without changing the first
  run; (3) a second layer that opens near the tree's end. Each is an
  economy change and the owner's call.
- A player averaging 35 minutes a day would reach the current four active
  hours in the first week, well inside the D30 horizon the benchmarks use.

## Sources

- Pecorella, GDC EU 2016 slides:
  https://media.gdcvault.com/gdceurope2016/presentations/Pecorella_Anthony_Quest%20for%20Progress.pdf
  (Vault: https://www.gdcvault.com/play/1023876/Quest-for-Progress-The-Math)
- Pecorella, worksheets (3a Prestige Patterns): https://archive.org/details/idlegameworksheets
- Pecorella, *The Math of Idle Games, Part III*: https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii
- Pecorella, GDC 2015 transcript: https://archive.org/stream/GDC2015Pecorella/GDC2015-Pecorella_djvu.txt
- AdVenture Capitalist wiki: https://adventure-capitalist.fandom.com/wiki/Angel/Hard_Reset,
  https://adventure-capitalist.fandom.com/wiki/Angel_Investors
- Antimatter Dimensions wiki: https://antimatter-dimensions.fandom.com/wiki/BubbaCow's_Antimatter_Dimensions_Guide,
  https://antimatter-dimensions.fandom.com/wiki/Guide
- Cookie Clicker wiki: https://cookieclicker.wiki.gg/wiki/Ascension
- Egg, Inc. wiki: https://egg-inc.fandom.com/wiki/Prestige
- NGU Idle wiki: https://ngu-idle.fandom.com/wiki/Rebirths,
  https://ngu-idle.fandom.com/wiki/Frequently_Asked_Questions
- Realm Grinder wiki: https://realm-grinder.fandom.com/wiki/Abdication,
  https://realm-grinder.fandom.com/wiki/Reincarnation
- Clicker Heroes wiki: https://clickerheroes.fandom.com/wiki/Transcendence
- Idle Miner Tycoon wiki: https://idleminertycoon.fandom.com/wiki/Prestige
- Idle Slayer wiki: https://idleslayer.fandom.com/wiki/Ascension
- Unnamed Space Idle, Steam thread: https://steamcommunity.com/app/2471100/discussions/0/3874840228864185320/
- Hobbyist post: https://dev.to/aguier/i-built-7-idle-games-in-30-days-what-i-learned-about-incremental-design-5d3f
- GameAnalytics 2026 benchmarks: https://www.gameanalytics.com/reports/2026-mobile-pc-gaming-benchmarks
- GameAnalytics Q1 2024 summary: https://gamedevreports.substack.com/p/gameanalytics-benchmarks-in-mobile
- IGDA / AppMagic idle tycoon overview: https://igda.org/news-archive/idle-tycoon-games-market-overview/
