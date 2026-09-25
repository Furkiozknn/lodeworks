# The feature pool: what the reference games can give Lodeworks

Read on 25 September 2026. A pool of features for development, taken from
five studies of the reference games and adapted to Lodeworks. The aim is to
adapt what works, not to copy.

**Sources.** Every claim about a reference game is in one of the five full
reports, with its sources. Each report lists 60-150 features, each with what
it is, how it works, what it solves, its core-loop role, related features,
dependencies, challenges, fit and conflicts. This file only uses their
feature IDs:

| report | features | IDs |
|---|---|---|
| [Clash of Clans](reference-games/clash-of-clans.md) | 150 | `CoC #n` |
| [Boom Beach](reference-games/boom-beach.md) | 117 | `BB Fn` |
| [Whiteout Survival](reference-games/whiteout-survival.md) | about 110 | `WOS X#` |
| [Rise of Kingdoms](reference-games/rise-of-kingdoms.md) | 120 | `RoK n` |
| [Hay Day, Township, State of Survival](reference-games/hay-day-township-state-of-survival.md) | about 130 | `HD X#` |

The progression backbone they build on is
[`../PROGRESSION.md`](../PROGRESSION.md). The earlier studies are
[`clash-ux.md`](clash-ux.md) and
[`progression-reference.md`](progression-reference.md).

**The rule for this pool.** A feature is in only if it connects to the
progression graph: the Factory Core's rows, the store, machine levels,
research, depth, heat or the chain. Anything that cannot be connected
waits, as PROGRESSION.md requires.

**How to read an entry.**

- *Source* — the game(s) and feature IDs.
- *In the source* — how it works there.
- *Value* — what it gives the player.
- *Solves* — the problem it solves.
- *Core loop* — what it adds to the moment-to-moment game.
- *Adaptation* — the Lodeworks version.
- *Depends on* — the technical and system dependencies (section 8).
- *Related* — which pool entries it works with.
- *Challenges* — technical and design difficulties.
- *Vision* — any tension with the Lodeworks vision.
- *Decisions* — any conflict with a decision already taken.

## The decisions every entry was checked against

These are binding; the pool does not propose anything that breaks them.

| # | decision | where |
|---|---|---|
| V1 | Single-player; no account, no server | README; AUDIT §2 D3 |
| V2 | Monetization: rewarded video only (opt-in, additive), plus two one-time purchases that never change an economy number (tested) | README "Monetisation" |
| V3 | No energy, no timers as gates, no gacha, no subscription, no daily-login guilt | README |
| V4 | No stealable resources, raids, shields or combat | clash-ux.md "leave" |
| V5 | Every feature connects to the Core's progression graph | PROGRESSION.md |
| D1 | No more machines, strata or currencies as a content treadmill. Amended 25 Sep 2026 by the owner: a new resource only if it is connected to other systems ("Kaynak sayısını sırf oyun uzun sürsün diye artırma") | AUDIT §2 D1; the owner's progression brief |
| D2 | No daily or weekly challenges, no streaks | AUDIT §2 D2; the owner, 25 Sep 2026 |
| D3 | No multiplayer, leaderboards or social features that need a server | AUDIT §2 D3; the owner, 25 Sep 2026 |
| D4 | No premium currency, starter packs, subscriptions or interstitials | AUDIT §2 D4 |
| D5 | No randomized hidden bonuses; every effect deterministic and printed | AUDIT §2 D5 |
| P6 / P7 | What a collapse keeps, and blueprints: **waiting on the owner** | PROGRESSION.md; GAP-AUDIT A1 |

---

## 1. Recommended features

Ranked by value for effort within each tier. Tier A needs no owner decision
and connects directly to what exists. Tier B is a medium build. Tier C
waits for an owner decision named in its entry.

### Tier A

**FP-01 · Every "why not yet" answered, with a tap that goes and does it**

- *Source:* CoC #111 (lock reasons, Feb 2026), #110 (cap bars); HD L3; RoK 74 (retroactive quest credit); WOS Q1 (a chapter mission tap goes to the place).
- *In the source:* a locked icon, tapped, says what unlocks it. Main quests credit steps already done. A mission row moves the camera to the building.
- *Value:* the player never meets a wall without its reason.
- *Solves:* "why can't I?" frustration, and wasted taps on a 44×44 board.
- *Core loop:* every locked tray key, research card, machine level and Core row becomes an actionable goal.
- *Adaptation:*
  - Locked tray keys say "Core level N" or "stratum N".
  - Capped machine-level keys already say "Core first" or "Vault first"; they should also name the level that lifts the cap.
  - Research cards already show "Core level N".
  - The Core's rows already jump to the machine, the Vault, the heat view, or the machines holding a row back.
- *Depends on:* CoreLevels (built); iso_view focus (built).
- *Related:* FP-02, FP-04, FP-09.
- *Challenges:* consistent wording in English and Turkish; the loc width check.
- *Vision / Decisions:* none.
- *Status:* partly built. The Core card, the machine level key, research cards and "What now?" do it; the tray's locked keys do not yet.

**FP-02 · Highlight every machine of a type**

- *Source:* CoC #29.
- *In the source:* selecting a building highlights all of its type.
- *Value:* the whole chain of a type is read at a glance.
- *Solves:* finding "my Smelters" on a big isometric board; seeing heat reach.
- *Core loop:* the adjacency and heat puzzle becomes readable.
- *Adaptation:*
  - Tapping a machine rings every machine of its type.
  - Each ring is coloured by its heat against its ideal (the heat overlay's own colours).
  - A dim ring marks machines that do not count towards a Core working row.
- *Depends on:* iso_view overlays (the chain highlight exists: `Iso.chain`).
- *Related:* FP-01, FP-05, FP-11.
- *Challenges:* draw cost on a 300-machine board. The late-board budget is 18 ms; measure with perf_probe.
- *Vision / Decisions:* none.

**FP-03 · Have / need on every cost, and a bonuses page**

- *Source:* RoK 88 (owned quantity on costs), 89 (bonus breakdown).
- *In the source:* costs show what is owned against what is needed; the City Hall shows an economy chart of every bonus.
- *Value:* a cost is a plan, not a guess.
- *Solves:* hidden multipliers; "how far am I?".
- *Core loop:* upgrade and Core decisions become arithmetic the player can do.
- *Adaptation:*
  - Every cost chip shows have/need and turns green when it is met. The machine level key already reds a short cost.
  - A **Bonuses** page lists every multiplier by source: research, machine level, stratum, support machines, later mastery.
- *Depends on:* one source of truth for multipliers (`Economy.multipliers`, `Strata.apply`, `level_mult`).
- *Related:* FP-01, FP-10.
- *Challenges:* collecting the multipliers into one list without a second implementation of the rules.
- *Vision / Decisions:* none.

**FP-04 · Ready badges and a readable store**

- *Source:* BB F10 (green upgrade arrows), F38 (cap hygiene); HD B5 (fill crates), B6 (ready and close badges); WOS U2, M1.
- *In the source:* a green arrow over what can be upgraded now; resources at cap shown in orange; a warning before collecting past the cap.
- *Value:* affordable upgrades are never missed.
- *Solves:* missed opportunities and waste at the cap.
- *Core loop:* shorter sessions with better decisions.
- *Adaptation:*
  - A small badge over each machine type whose next level can be paid now. The key already lights up; a board badge is the addition.
  - The Store row turns orange at the Vault's limit.
  - When the store is full, the Core's picture shows it, and "What now?" offers the Vault's level.
- *Depends on:* `Sim.machine_upgrade_blocker`, `Sim.stock_cap` (built).
- *Related:* FP-01, FP-10, FP-15.
- *Challenges:* badge clutter on a small screen (one per type, not per machine; an option to hide them).
- *Vision / Decisions:* none.

**FP-05 · The Away report (Logbook)**

- *Source:* WOS I5, BB F32 (activity log with jump-to), CoC #114 (results breakdowns), RoK 73 (Yearbook).
- *In the source:* the return screen or log lists what happened; each line jumps to its place.
- *Value:* coming back is a story, not a number.
- *Solves:* offline production that is invisible except as credits.
- *Core loop:* each return starts with "what to fix".
- *Adaptation:*
  - The offline panel (built) gains lines for what was stored, research finished and machines that stalled, with their causes.
  - Each line jumps to the machine.
  - No guilt copy.
- *Depends on:* offline yield (built); lifetime counters (TD2).
- *Related:* FP-06, FP-08.
- *Challenges:* the offline estimate is a rate × time model, not a replay. It must not claim a stall it did not see, so it can only say what was true at the save.
- *Vision:* none (V3 is kept: no absence penalty).
- *Decisions:* none.

**FP-06 · The Dispatch board: contracts with no clock**

- *Source:*
  - HD C1 (truck orders: 9 slots, no expiry, replaced at once);
  - C2 (only makeable goods, including unbuilt unlocked machines);
  - C11 (next order preview);
  - C5 (partial credit);
  - C4 (three-tier big shipments);
  - C3 (coins versus XP trade-off);
  - C6 (orders paying gate items);
  - C12 (named buyers);
  - Township plane and train (rows with partial rewards; the train brings gate items).
- *In the source:* a board of small orders for goods the player can make. Filled with one tap, replaced when done, never expiring. Big shipments are split into crates, each paying on its own.
- *Value:* a steady stream of small, printed goals between Core levels, with a choice in which to fill.
- *Solves:* the empty short-term layer. Today the short-term goal is "the next quota" or a Core row that takes 10-30 minutes.
- *Core loop:*
  - Contracts pull materials out of the Core's store.
  - They make the old tiers matter: a contract for Gravel or Ingots at Core 5.
  - They make "what to produce" a decision.
- *Adaptation:*
  - Three contracts at a time, each "Deliver N of a material that is reachable now" (unlocked, and the store can hold it).
  - Filled from the store with a tap, paying credits at a premium over the Vault or a printed progress reward. No new currency.
  - A new contract is dealt when one is filled; the next one is visible, greyed.
  - A contract can be dropped for free. Its replacement arrives after N units of any production, not after wall-clock time.
  - Later: one big contract with three offered tiers and a payment per crate.
  - Contracts are generated deterministically from (Core level, depth, count).
- *Depends on:* the Core's store (built); a deterministic generator (TD3); save migration (TD1); UI; the core_journey bot (TD10).
- *Related:*
  - FP-07: a Core row can ask for contracts filled;
  - FP-15: exchange;
  - FP-04;
  - O1: heat-graded goods.
- *Challenges:*
  - Balancing the premium so Vaults stay worth building.
  - Contract size against the store's limit.
  - Keeping the board from becoming a checklist.
- *Vision:* no timer, no expiry, no energy (V3 kept).
- *Decisions:* D2 is kept (never daily or weekly; no resets). D1 is kept (pays credits or progress, not a currency).
- *Status:* **built, first version (25 Sep 2026).**
  - What there is:
    - `scripts/core/dispatch.gd`;
    - the board on the Core card;
    - a "What now?" line;
    - `tests/test_dispatch.gd`.
  - How it works:
    - Three slots, dealt deterministically for materials the shaft can make, sized to the store.
    - Paid in credits (2× the Vault, at least 12 s of income) or research (1.25× a Lab).
    - A filled contract is replaced at once. A dropped one rests for 25 units into the store.
    - A collapse deals a new board and keeps the lifetime count.
  - Not yet: big three-tier contracts, the bulk buyer (FP-15), rewards for the ledger count.
  - Balance: a 45-second floor paid more than all of a played factory's Vaults; it is now 12 seconds (docs/PROGRESSION.md, "Balance history").

**FP-07 · Descent readiness**

- *Source:* WOS H5 (storm countdown with requirements and a "Ready" button).
- *In the source:* an incoming storm shows a countdown and what is needed to weather it.
- *Value:* the next stratum is a planned puzzle, not a surprise.
- *Solves:* modifiers that break a layout only after Descend.
- *Core loop:* planning heat before the move.
- *Adaptation:*
  - The "below" card (built) gains a checklist computed from the next stratum's modifiers, for example "Thermal Vent: 2 Presses will overheat — add Coolant".
  - No clock: the player descends when ready.
- *Depends on:* `Strata.effect_on` (built); `links_if_placed` (built).
- *Related:* FP-01, FP-11.
- *Challenges:* a readable checklist from 12 modifiers × layouts; say only what the simulation can predict.
- *Vision / Decisions:* none.

**FP-08 · Heat that explains itself**

- *Source:* WOS H4 (temperature always on the HUD), H8 (two causes shown), SU1 (Suggestion Box complaints naming the cause), U2 (status icon over a building).
- *In the source:* the key variable is always visible; the settlement tells you why something is failing.
- *Value:* diagnosis becomes play.
- *Solves:* "my machine is slow and I do not know why".
- *Core loop:* heat is the identity of Lodeworks; making it legible makes it the game.
- *Adaptation:*
  - The status badges (built) gain a cause mark: too hot, too cold, starved, backed up.
  - The Foreman names the cause once per stratum and jumps to the tile.
  - The warning key's tooltip already counts problems by kind.
- *Depends on:* `CoreLevels.why_not_working` (built this round); badges (built).
- *Related:* FP-02, FP-05, FP-11.
- *Challenges:* the Foreman must not nag (once per stratum, as the overheating line already does).
- *Vision / Decisions:* none.

**FP-09 · Principles: no waste, no loss, choice not chance**

These are rules every later feature follows, not features to build:

- Anything made useless by progress converts to something useful (RoK 111).
- Anything removed or reworked is refunded (CoC #133, #135 warn before investing).
- A machine that fails stalls and recovers, and is never destroyed (WOS H10, A1).
- A reward is a printed choice, never a roll (HD R3; D5).
- Rewards the player earned are never lost (WOS A2).

**FP-10 · A Core level-up that feels like a milestone**

- *Source:* CoC #118 (celebration), #5 salvage (a one-time payout instead of a timed boost); progression-reference principle 16 ("soften each new tier": Town Hall upgrades power up troops and boost collectors for 3-5 days).
- *In the source:* a new Town Hall arrives with a moment and temporary boosts.
- *Value:* the milestone is felt.
- *Solves:* a Core level that changes numbers without a moment.
- *Core loop:* the reward that closes the long-term loop.
- *Adaptation:*
  - A level-up moment: the Core's picture grows (built), a card lists what opened.
  - A **surge** that counts production, not time: the next N units made run at +X%, instead of CoC's 3-5 days. A timed boost would create "play now or lose it", which V3 rules out.
- *Depends on:* the `core_upgraded` signal (built); a production counter (TD2).
- *Related:* FP-05, FP-13.
- *Challenges:* sizing the surge so it does not become the reason to grow.
- *Vision:* a timed version would break V3; the production-counted one does not.
- *Decisions:* none.

### Tier B

**FP-11 · Machine modes: Max Power and heat trade-offs**

- *Source:* WOS H2 (Furnace On/Off and Max Power at double fuel), H9 (Cookhouse meal-tier selector), P12 (an old building gains a new function late).
- *In the source:* a lever that trades resources for heat or safety.
- *Value:* a decision the player takes, not only a layout they place.
- *Solves:* heat is only positional today; there is no lever.
- *Core loop:* more heat decisions per session.
- *Adaptation:*
  - A Boiler **Max Power** mode: more heat and a running credit cost. A Boiler has no input today, so the cost would be credits or Gravel fed to it; this is a design choice.
  - A Smelter **Hot / Standard / Eco** dial (speed against heat out).
  - Modes open with Core levels, so old machines gain a function late.
- *Depends on:* the machine table (per-cell mode); the simulation and offline yield respecting it; save.
- *Related:* FP-02, FP-08, FP-13.
- *Challenges:* so that Max is not always optimal; the offline estimate uses the measured rate, so it inherits modes automatically.
- *Vision:* none.
- *Decisions:* D1 is kept (no new machine).

**FP-12 · Overdrive past the cap**

- *Source:* CoC #50 (Supercharge: extra, cheaper steps on a fully upgraded building, with a glow), #54 (mastery visuals); WOS P13 (Expert Research overflow sink).
- *In the source:* "fully upgraded" still has something to do.
- *Value:* a type at its Core cap is not finished.
- *Solves:* dead time between Core levels once every machine is at its cap; the scripted player shows exactly this.
- *Core loop:* a long sink for old materials (Ingots and Gravel stay useful).
- *Adaptation:*
  - Each machine type at the Core's cap can take up to 3 Overdrive steps: small speed gains, paid mostly in low-tier materials from the store.
  - Overdriven machines glow, and the Core card shows one pip per overdriven type.
  - A new Core level folds Overdrive into the next real level, with credit for what was paid (FP-09).
- *Depends on:* machine levels (built); art for the glow.
- *Related:* FP-13, FP-15.
- *Challenges:* stacking with levels and research; glow cost on phones.
- *Vision / Decisions:* none (no currency: CoC's Sparky Stones are rejected, D1).

**FP-13 · Mastery lines per machine type**

- *Source:* RoK 75 (side quest line per building), 29 (talent points); HD E (Hay Day building masteries from hours of use); WOS P11 (album with permanent buffs).
- *In the source:* medium goals tied to one building each.
- *Value:* every machine has its own story of progress.
- *Solves:* a medium-term layer per machine; a reason to use old machines.
- *Core loop:* more goals among the ones already played for.
- *Adaptation:*
  - Each type has a mastery line on its Codex card: build 3, run 10 minutes at working heat, make 1,000 units, reach level 5.
  - One step is active at a time; they are credited retroactively.
  - Rewards: cosmetic trims or a small permanent bonus to that type.
  - Mastery accrues only at working heat (O3).
- *Depends on:* lifetime counters per type (TD2); save (TD1); the Codex.
- *Related:* FP-11, FP-12, FP-16.
- *Challenges:* "run 10 minutes" must count simulated time the same way online and offline; balance of permanent bonuses (they survive a collapse?, P6).
- *Vision / Decisions:* none.

**FP-14 · The Chronicle: a personal timeline of eras**

- *Source:*
  - RoK 64 (kingdom timeline: an ordered, visible list of goals and unlocks), 65 (chapters unlock regardless; the reward depends on the goal), 26 (Ages as visual eras);
  - WOS Q1 (chapters), Q5 (Wish Station: sequential requests);
  - CoC #46 (Hero Journey track).
- *In the source:* a planned, visible long game in chapters.
- *Value:* the player sees the whole road, not only the next step.
- *Solves:* the long game past the first hours (GAP-AUDIT E1: "past that nothing is designed").
- *Core loop:* a frame that gives each Core era a title, a story and a bonus goal.
- *Adaptation:*
  - One chapter per Core era (Extraction, Processing, Fabrication…).
  - Its gate is the Core level itself.
  - Each chapter has one optional bonus goal (for example "reach Core 3 before stratum 5"), paid in cosmetics or a trim.
  - The Foreman narrates each chapter in one line.
  - No dates, no server; CoC's and RoK's shared schedules are rejected (D3).
- *Depends on:* CoreLevels (built); save; loc text.
- *Related:* FP-10, FP-13, FP-05.
- *Challenges:* writing; staying one line per chapter.
- *Vision / Decisions:* none.

**FP-15 · Exchange and bulk buyers for surplus**

- *Source:* WOS E2 (converter with asymmetric fixed rates), O5 (trading in obsolete items); HD C7 (visitors who buy a share of overstock at a premium), B8 (never-blocking overflow); BB F43 (Trader, milestone-triggered).
- *In the source:* surplus has an outlet at a fixed rate.
- *Value:* an imbalanced chain is not a dead end.
- *Solves:* a full store blocking Core feeders (the scripted player hit this); a line too strong for its neighbours.
- *Core loop:* "what do I do with 800 Ingots" becomes a choice.
- *Adaptation:*
  - An Exchange at the Core, opened at Core 3: trade one stored material for another at a fixed lossy rate (3 : 1 down the chain, 5 : 1 up). No daily cap.
  - A **bulk buyer** contract (FP-06) appears when a material sits at the store's limit.
- *Depends on:* the store (built); FP-06.
- *Related:* FP-04, FP-06, FP-12.
- *Challenges:* rates that never make a chain pointless.
- *Vision:* none.
- *Decisions:* D2 is kept (no daily cap or refresh).

**FP-16 · Trials: boards that teach, and your own board under test**

- *Source:*
  - BB F62 (Dr. T Threat stages with a downgrade button), F63 (Hammerman: defend your own base, no loss), F82 (Training Grounds lessons), F104 (reward plateau), F105 (no-loss failure);
  - RoK 55, 56 (stars);
  - CoC #104 (practice), #33 (attack your own base), #4 (4× speed).
- *In the source:* optional, always-available PvE; lessons; testing a layout without risk.
- *Value:* mastery content that never expires.
- *Solves:* AUDIT C2 (challenge runs) and the teaching of heat and adjacency past the tutorial.
- *Core loop:* a place to experiment with layouts.
- *Adaptation:*
  - **Drills:** 6×6 lesson boards, one mechanic each: heat spread, Coolant, bridging, Amplifier.
  - **Trials:** fixed-seed boards under a modifier pair, with 1-3 stars for output targets. Stars pay a permanent cosmetic or a blueprint slot.
  - **Stress test:** run a copy of your own yard at 4× under the next stratum's rules.
  - No limit per day, no leaderboard.
- *Depends on:* a sandbox Simulation (TD4: Grid and Simulation are pure, so a second instance is cheap); scenes.
- *Related:* FP-07, FP-19, O8.
- *Challenges:* authoring boards; UI for a second board.
- *Vision:* none.
- *Decisions:* D2 and D3 are kept (no daily cap, no ranking).

**FP-17 · Stratum records**

- *Source:* HD I2 (= AUDIT C3); WOS M5 (local personal records).
- *In the source:* a record kept against yourself.
- *Value:* a reason to re-descend a stratum already cleared.
- *Solves:* repeating strata after a collapse feel identical.
- *Core loop:* a small medium goal after each collapse.
- *Adaptation:* the best credits per second measured on each stratum, kept across collapses, shown on the stratum card with a medal at set thresholds.
- *Depends on:* save; the rate window (built).
- *Related:* FP-05, FP-19.
- *Challenges:* the rate after a Descend starts at 0 (the header resets); measure over a stable window.
- *Vision / Decisions:* none (no leaderboard).

### Tier C (each waits for the decision named in it)

**FP-18 · The ring beyond the yard: survey, sites, a haul**

This answers P4 and GAP-AUDIT A2, the resource-node economy.

- *Source:*
  - BB F20-F23 (fog regions bought with Gold, throttled offers, teasers through fog, one-time chests), F24-F26 (resource bases and freed villages whose type sets their output), F1 (a boat that collects world income), F32 (log);
  - RoK 40-48 (fog with a frontier rule, a scouting report, tribal villages, holy sites with non-stacking buffs);
  - HD A7, D1, D4 (plots and rubble), D6.
- *In the source:* the world beyond the base is earned and produces.
- *Value:* the empty ground round the yard becomes a place to go.
- *Solves:* crystal fields, ore seams and heat vents that no machine uses today.
- *Core loop:* a production-paid exploration loop that works offline.
- *Adaptation:*
  - **Survey** the ring for credits; how far it reaches grows with the Core level.
  - Silhouettes of sites show through the fog, and a Discovery log keeps every find.
  - One-time caches pay materials.
  - Claimed **sites** have deterministic functions:
    - a heat vent heats adjacent machines like a free Boiler (O2);
    - an ore seam makes Drills beside it richer;
    - a crystal field yields crystal — see D1 below.
  - A Core row per era band can ask for a site. A collapse re-rolls the ring.
- *Depends on:* ResourceNodes (words only today); world-node effects in the simulation (TD8); save; art.
- *Related:* FP-05, FP-19, O2.
- *Challenges:*
  - Nodes currently vanish when the yard reaches them (BuildArea); they would have to stay.
  - Heat from sites needs a heat source outside the grid.
- *Vision:* none.
- *Decisions:*
  - The **owner's decision A2** (node function).
  - **D1:** crystal as a new material is allowed only if it connects to other systems (the owner's 25 Sep amendment). It must never be a shop currency.

**FP-19 · What a collapse keeps**

This answers P6.

- *Source:* WOS EV6 (permanent unlocks once reached), P2 (a standard level per type); BB F47 (statues that survive), F48; RoK 10-12 (civilization choice); CoC principle "nothing resets" and the Builder Base switch-over.
- *In the source:* a new start is stronger, not empty.
- *Value:* a collapse feels like "a stronger foundation", not a reset (the owner's own words).
- *Solves:* today a collapse throws away every Core level, machine level and store.
- *Core loop:* the permanent layer that feeds the next shaft's pace.
- *Adaptation, options for the owner:*
  - (a) **Standard levels**: a new shaft's machine types start at half the previous best.
  - (b) **Milestone unlocks**: a Core level once reached leaves a permanent convenience, such as a Drill line pre-placed or a free Vault level.
  - (c) **Charters**: at each collapse, choose one of 2-3 perk sets (RoK civilizations), free to switch next time.
  - Measure each with core_journey across collapses.
- *Depends on:* collapse (built); save; core_journey across collapses.
- *Related:* FP-13, FP-17, FP-20.
- *Challenges:* not trivialising the early Core levels on the second shaft; research is already permanent and pre-meets research rows.
- *Vision:* none.
- *Decisions:* the **owner's decision P6**.

**FP-20 · Blueprints, line recipes and share codes**

This answers P7 and GAP-AUDIT A1.

- *Source:* CoC #23-#28, #31 (edit mode, layout slots, copy, share links, draft overlay); BB F9 (saved layouts, "apply"); RoK 5, 86 (City Editor); WOS U7 (batch actions).
- *In the source:* plan, save, borrow and re-apply layouts.
- *Value:* rebuilding after a collapse is one decision, not a hundred taps.
- *Solves:* the scripted player rebuilds the same three Core lines every shaft.
- *Core loop:* layout craft becomes a thing to keep.
- *Adaptation:*
  - Save a region as a blueprint.
  - Stamp it as ghosts; place what is affordable, and let the rest fill in as credits arrive.
  - Codex example boards become stampable recipes (O9).
  - A share code, with no server, carries a blueprint between players by any messenger ("Factory Tours").
- *Depends on:* a blueprint format, ghost rendering, partial placement (TD6); share codes (TD7). `Sim.blueprints` is already saved; the Drafting Table research and the Licence slots are hidden.
- *Related:* FP-16, FP-19.
- *Challenges:* layouts that cross the yard's edge; strata that block cells (Cramped).
- *Vision:* none.
- *Decisions:* the **owner's decision P7 / A1**. Share codes are allowed because they need no server (D3 is kept).

---

## 2. Clusters of features that complete each other

| cluster | entries | how they work together | the reference cluster |
|---|---|---|---|
| **K1 What next, and why not yet** | FP-01, FP-03, FP-04, FP-07, FP-08, "What now?" (built) | "What now?" says what to do. Lock reasons, have/need and badges say why not. The descent checklist says what is coming. Heat badges say where the trouble is. All of them read data the Core's rows already hold. | CoC cluster B; BB guidance stack; WOS B; HD 6 |
| **K2 Short-term production goals** | FP-06, FP-15, FP-04, O1 | Contracts pull from the store. The store's limit (FP-04) and the Exchange (FP-15) keep "full" from being a dead end. Contracts make old tiers useful. | HD Dispatch loop (1), storage gate (2) |
| **K3 Heat as a readable crisis loop** | FP-08, FP-11, FP-07, FP-02, the heat view (built) | Badge and Foreman say the cause, the lever (Max Power, a mode) or a re-layout answers it, and the machine recovers with no loss. | WOS A |
| **K4 Maxed never means done** | FP-12, FP-13, FP-15, FP-11 | Overdrive past the cap and mastery lines keep a finished type busy, paid in early materials. Modes give old machines a late function. | CoC A; WOS D; HD 3 |
| **K5 The long game you can see** | FP-14, FP-10, FP-05, FP-17 | The Chronicle names each era. The level-up moment closes it. The Logbook and records remember it. | RoK Chronicle (6); CoC D, I |
| **K6 A collapse that builds a foundation** | FP-19, FP-20, FP-17, FP-13 | What survives (P6) and blueprints (P7) together decide whether a new shaft is a restart or a faster climb. Records give the second shaft its own goals. | BB 2; RoK 2; WOS E |
| **K7 The world beyond the yard** | FP-18, FP-05, O2 | Survey, sites and caches feed the store and the heat system, and the Logbook reports them. | BB 1; RoK 1; HD 4 |
| **K8 Replayable content with no calendar** | FP-16, FP-17, FP-20 | Drills teach, Trials test, a stress test checks your own yard, and blueprints carry what worked back. | BB 3; RoK 7; CoC C |
| **K9 Trust** | FP-09, FP-04, FP-05 | No waste, no loss, compensation, cap hygiene, and honest reports. | CoC F; RoK 8; HD 7 |

## 3. Systems to decide together

These are larger choices where one decision changes several features. Each
needs the owner or a measurement first.

1. **Collapse (P6) with blueprints (P7).** Whether a new shaft keeps machine
   levels or a Core floor decides whether blueprints are
   quality-of-life or essential. The scripted player shows that the three
   Core lines are rebuilt identically every shaft. Decide P6 first, then
   P7; measure both with core_journey over several collapses.
2. **The world ring (FP-18) with D1.** A crystal material from world sites
   is the first new resource since the Core levels. The owner's amendment
   allows it only if it connects: it must feed Core rows or recipes, never
   a shop. Decide the node functions (A2) and the crystal's role together.
3. **Dispatch (FP-06) with the Vault economy.**
   - If contracts pay more than a Vault, Vaults become fillers.
   - If they pay less, contracts are ignored.
   - Tune with core_journey plus a contract-filling bot.
4. **Rewarded video (V2) in new places.** Several references put an ad on
   an optional extra: BB F75's second pick, HD C14's double order, WOS
   I4's rush of production. Lodeworks allows opt-in, additive ads (one
   placement ships). Each new placement is a monetization decision; none
   is proposed here.
5. **Notifications.** CoC G, WOS N1 and HD N1 send at most one factual,
   opt-in notice ("the store is full", "the Core can grow"). This needs an
   Android plugin and the POST_NOTIFICATIONS permission (TD9). It must
   stay factual to keep V3, so no "we miss you".
6. **Characters.** WOS P4 (growth heroes), RoK commanders and HD
   named buyers would add faces. Lodeworks has one character, the Foreman.
   Specialists assigned to machines would be a new system with its own
   screens; it is held back (section 7) to avoid clutter.

## 4. Features that must be reshaped before they fit

Each row is a reference mechanic whose idea is kept and whose form breaks
a rule. The right column is what Lodeworks keeps instead.

| reference mechanic | what breaks a rule | the Lodeworks form |
|---|---|---|
| Timed boosts on a new tier (CoC #5, TH boosts for 3-5 days) | wall-clock (V3) | a production-counted surge (FP-10) |
| Discard cooldowns (HD C9, 6-30 min) | wall-clock (V3) | a replacement after N units of production (FP-06) |
| Boat windows and arrival timers (HD C4: 18 h / 4 h) | wall-clock (V3) | a big contract that appears when the last is shipped |
| Supply Chests every 6 h with a pick of 3 (BB F4) | time-gated | milestone crates earned by output, pick 1 of 3 (printed, D5) |
| Order-count tracks that reset daily (HD C10) | D2 | a permanent Dispatch ledger |
| Sparky Stones, Fancy Shop (CoC #53) | D1 currency | Overdrive unlocks its cosmetic directly (FP-12) |
| Wish Sigils (WOS Q5) | D1 currency | Commissions paying direct unlocks, folded into the Chronicle (FP-14) |
| Crafting Station modules paid in Ores (CoC #45, #52) | D1 currency | Core modules paid in store materials (section 7) |
| Statues from random stones (BB F47) | D5 randomness | fixed, printed permanent bonuses (FP-19 option b) |
| Drill Camp auto-levelling (WOS P2) | — (already true) | machine levels are per type: a new machine is already at its type's level |
| Kingdom timeline shared by a server (RoK 64) | D3 | a personal Chronicle (FP-14) |
| Hammerman defence of your base (BB F63) | combat (V4) | a stress test of your own yard under the next stratum's rules (FP-16) |
| Clash's clone bases, layouts shared by link (CoC #3, #27) | D3 (clones) | share codes with no server (FP-20) |
| Resource bases captured from players (BB F25) | V4, D3 | world sites claimed with production (FP-18) |
| Visitors with a daily cap and part drops (HD C7) | D2, D5 | a bulk buyer with no cap, printed price (FP-15) |
| Idle rewards capped at 9-12 h (WOS M1) | refresh pressure | offline capped only by the research line already there (built) |

## 5. Rejected features

Rejected because they conflict with the vision (V1-V5), or because they
would add clutter without connecting to the graph.

| feature (sources) | why |
|---|---|
| Construction, research and training timers; speedups; builder queues bought with premium currency (CoC #143, #144, #47, #48; WOS C2, C3, A4; RoK 1, 23, 97; BB F113, F114; HD S1, A2) | V3 timers as gates, and D4 |
| Magic Items: Books, Hammers, Potions, Runes, Wall Rings, Star Jars (CoC W7); Time Savers and Build Tokens (BB) | each exists to skip a timer or a cost |
| Energy, stamina, attempt caps, bait regeneration (WOS E7; RoK 2; BB F66 Mega Crab caps; HD R6) | V3 |
| Gacha: chests, wheels, card packs, recruitment, luck events (CoC #67, #74, #148; WOS EV3, hero recruitment; RoK 117, 118; BB F60, F115; HD S7, House of Luck) | V3; D5 |
| Premium currency, VIP, packs, offers, rentals, paid slots (CoC #143-#149; WOS MO1-MO6; RoK 39, 115, 116; BB F113; HD S5, S6, S8, S9, S11) | D4; V2 |
| Season passes, event passes, monthly cards, growth funds (CoC #58, #59, #61, #65; BB F71, F73; WOS MO3; HD S2) | subscription-like, with paid tracks (V2, D4) |
| Loot, raids, shields, revenge, protected storage, plunder (CoC #7, #130, #131, #122; WOS E5; RoK 20; BB F109) | V4: nothing can be stolen |
| Armies, troops, combat, gunboats, heroes as fighters, pets (CoC #12-#15; BB F59; RoK PvE combat; WOS P5-P8) | out of genre; pets and extra menu characters are clutter |
| Decay and wilting (HD R1); obstacles that grow back (CoC #32) | punishes absence (V3) |
| Several separate stores on one screen (HD B1); upgrade parts that take storage space (HD B4) | clutter on a small screen |
| Calendar and server-age gating (WOS P14, P15; RoK zones) | FOMO; needs a shared clock |
| Pre-event reminders, absence pushes (WOS U8, N1 pushes; BB F92) | daily-login guilt (V3) |
| Paid respec or refunds (RoK 120; WOS P3 paid form) | V2 |
| Cosmetics with stat bonuses (WOS CU1; RoK 69, 100) | a purchase changing an economy number (V2) |

## 6. Features that conflict with a decision already taken

Recorded as "conflicts with an existing decision", with the reason. They are
not proposed.

| decision | features that conflict (sources) | why they conflict |
|---|---|---|
| **D2 daily or weekly chores, streaks** | <ul><li>CoC: Star Bonus (#5), Season task cards (#56), Streak Event (#68), Trader weekly (#38), medal events (#64-#66), Login Calendar (#120)</li><li>BB: Daily Reward boat (F5), Cycle of Evil (F61), weekly Intel and Trader</li><li>WOS: Daily Missions (Q4), VIP login days (N2), themed days (EV2), Endless Trials (EV8)</li><li>RoK: daily objectives and activity chests (76), VIP streak (115), 7-day event (71), daily Expedition claims (55)</li><li>HD: daily events (H1), County Fair streak (H3), track resets (C10), bonus days (C15), consecutive-day blimp (N2)</li><li>**Lodeworks' own earlier proposal "Rock of the Week" (clash-ux.md, GAP-AUDIT §4), which the owner's 25 Sep list now rules out**</li></ul> | a reason to feel bad for missing a day or a week (D2) |
| **D3 multiplayer, leaderboards, social needing a server** | <ul><li>CoC: clans, chat, donations, perks, friends, Global Chat (#85-#93); Clan Capital, Raid Weekends (#96, #82); Friendly Wars (#97); Clan Games (#63); all competition (#98-#102)</li><li>BB: Task Forces, Operations, Intel, leaderboards, friends (F70, F76-F79)</li><li>WOS: alliances, SvS, Bear Hunt, Arena, every ranking (SO1, EV1, M4)</li><li>RoK: alliances, KvK, Ark of Osiris, Mightiest Governor, rankings, Trading Post (57, 60, 61, 67-69, 81-85, 24)</li><li>HD: Derby, Regatta, help requests, the Valley, player shops, card trading (J1-J6, C13, F1, I7)</li><li>**Lodeworks' own earlier proposals Union, Requisitions, Union Works, Output Trials (clash-ux.md §10.2)**</li></ul> | an account, a server and a privacy surface the game does not have (D3) |
| **D1 currencies as a content treadmill** | CoC Sparky Stones (#53), event medals and tokens (#65), Ores as a currency (#45); BB black-market coins, Build Tokens, Keycards (F44); WOS Gems, Contentment, 15+ event tokens, Charms, generation marks (E6, W4, P8); RoK keys, medals, canyon coins, season coins, stones (25, 33, 37); HD currency sprawl, seasonal machines, coupons (F5, A10, E4) | each new currency is a new store page and a new ledger to watch (D1) |
| **D4 premium currency, packs, subscriptions** | every premium-currency, pack, pass and subscription row in section 5 | D4 |
| **D5 random hidden bonuses** | CoC random chests (#148); BB random statue boosts (F47); RoK random stars and rerolls (17, 31, 35); HD random part drops, creature spawns, puzzle pieces (B3, H7, I6) | the player cannot tell clever from lucky (D5) |

## 7. Later

Worth doing, but only after a measurement, a decision or a system that
does not exist yet.

| feature | sources | why later |
|---|---|---|
| **Twin machines**: two neighbouring machines at their cap merge into one stronger one | CoC #51 | the costliest simulation change: footprint and heat rules; after FP-12 |
| **Core modules**: 2-3 slots on the Core, filled with modules made from store materials | CoC #45, #52 | build variety; after the store economy is measured |
| **Monument**: an endless sink with capped, printed bonuses | BB F42; CoC Capital (#43, #44) | only when players are seen to finish everything (AUDIT C1) |
| **Specialisation**: mastery points spent on branch nodes, with a free respec | RoK 14, 15, 29; WOS P4 | after FP-13; the highest balance effort |
| **Fittings**: machine attachments forged from materials, with set bonuses that count adjacency | RoK 32-36 | a sink with adjacency depth; after FP-18 decides crystals |
| **Crystal Works**: a research tree per shaft funded by crystals | RoK 37 | depends on FP-18 and D1 |
| **Deep run**: an optional modifier stack that pays by the deepest stratum reached | RoK 58 | after FP-19 (collapse) |
| **A second shaft** with one link reward | CoC Builder Base, B.O.B (#17, #20); clash-ux §10.2.13 | a second board and economy; much later |
| **Specialists / characters** | WOS P4; RoK commanders | clutter risk; revisit with FP-13 |
| **Visual eras** (the Core's shell, ground and palette per era) | RoK 26; WOS | art cost (image generation budget) |
| **A share image** of the factory | CoC #95 | after statistics (TD2) |
| **One factual, opt-in notification** | CoC G; WOS N1; HD N1 | an Android plugin and a permission (TD9) |
| **Milestone crates**, pick 1 of 3 | BB F4 | once rewards have things to be (FP-12, FP-13 cosmetics) |
| **Codex completion rewards**; the Ledger building that grows with marks | WOS P11; HD I1; clash-ux Ledger | cosmetic; after FP-13 |
| **Two-stage contracts** | HD C8 | after FP-06 |

## 8. Technical dependencies

| # | system | state today | needed by | effort |
|---|---|---|---|---|
| TD1 | **Save migration step**: `_migrate(d)` keyed on `"v"` | the save is version 1, and defaults stand in for migrations (GAP-AUDIT B9) | FP-06, FP-13, FP-14, FP-17, FP-19, FP-20 | small; do first |
| TD2 | **Lifetime counters** per material (made, stored, sold) and per machine type (seconds at working heat, units made) | only lifetime credits | FP-05, FP-10, FP-13, FP-14, FP-17, share image | small; counted in `Simulation._work` and `Sim._collect_stock` |
| TD3 | **Deterministic generator** for contracts and survey, seeded by (Core level, depth, count) | strata are already seeded by depth | FP-06, FP-18 | small |
| TD4 | **Sandbox simulation**: a second Grid and Simulation | both are pure RefCounted classes; the tools already run them headless | FP-16, the FP-07 checklist | medium: the UI for a second board |
| TD5 | **Highlight and focus layers** in IsoView | `focus_cell`, `pulse`, the chain highlight exist | FP-01, FP-02, FP-08 | small |
| TD6 | **Blueprint format**, ghost rendering, partial placement | `Sim.blueprints` saved, never written | FP-20 | medium |
| TD7 | **Share code** encode/decode with validation | none | FP-20 | small |
| TD8 | **World-node effects**: nodes kept in the ring, claims, heat from sites | `ResourceNodes` words only; nodes vanish under the yard | FP-18 | large |
| TD9 | **Android local notifications** (plugin, POST_NOTIFICATIONS) | none | a notification (section 7) | medium; release work |
| TD10 | **core_journey hooks** for each new system (a contract-filling player, collapses) | the Core levels are played to Core 5 | every economy feature | per feature |
| TD11 | **Loc** in English and Turkish, and the loc width check | in place (`loc_extract`, `loc_tr_seed`, `loc_check`) | every UI feature | per feature |
| TD12 | **Art**: glow, site sprites, era palettes | the art pipeline and budget exist (docs/ART.md) | FP-12, FP-18, eras | per feature; credit-free generation first |

**Order.** TD1 and TD2 come first; they are small and unblock most of the
pool. Then TD3 and FP-06 (Dispatch), TD5 (FP-01, FP-02, FP-08), and TD4
(FP-16). TD6-TD8 wait for the owner's decisions (P7, A2).

## 9. New design opportunities

Ideas that no reference game has in this form. Each comes from combining a
reference mechanic with something only Lodeworks has.

- **O1 Heat-graded goods.** A contract or a Core row asks for materials
  made *at working heat* ("tempered Plates"), counted from machines at 90%
  or more. Heat management becomes a demand, not only an efficiency. Whiteout's heat is survival;
  here it is quality.
- **O2 Vents as heat supply.** A claimed heat vent is a free, fixed Boiler
  that never burns anything. Placing a Smelter line beside a vent is the
  world rewarding a layout. (FP-18 with the heat simulation.)
- **O3 Mastery only at working heat.** Mastery seconds count only while a
  machine is at its working heat. The medium-term layer then rewards the
  core puzzle instead of time spent. (FP-13 with FP-08.)
- **O4 Strata as markets.** Dispatch contracts are drawn with the current
  stratum's modifier: a Dense Seam buyer pays more for Plates, and a Barren
  stratum asks for less. Strata become market conditions with no calendar.
  (FP-06 with Strata.)
- **O5 The Core's side as prime ground.** Only machines touching the Core
  fill its store, so the 16 tiles round it are the most valuable on the
  board. A later Core level could add a store pipe that extends "touching"
  by one tile, a Core-side upgrade that is pure layout. (Store with FP-01.)
- **O6 A foundation, not a reset.** A new shaft's machine types start at
  a standard level derived from the last shaft's best (WOS P2 with P6).
  The second shaft climbs faster through the early Core levels and slows
  where the new content starts. (FP-19.)
- **O7 The Foreman as chronicler.** Each Core era gets one line of the
  shaft's story from the Foreman, at level-up and in the Chronicle. It
  gives character without a new cast. (FP-14.)
- **O8 Trials built from the modifier table.** The 12 modifiers × a fixed
  layout budget give dozens of hand-checkable puzzles with no new content
  pipeline, rewarding stars with blueprint slots. (FP-16 with FP-20.)
- **O9 The Codex boards as recipes.** The Codex already runs example
  boards. Making them stampable blueprints turns the manual into a tool.
  (FP-20.)
- **O10 Records that survive a collapse.** Best rate per stratum kept across
  shafts gives each shaft a personal ghost to beat, without a leaderboard.
  (FP-17 with FP-19.)

## Where this meets the vision, and where it strains it

- **The pool fits the vision.** Every recommended entry is single-player,
  deterministic and timer-free. The Core graph, the store and heat are the
  centre of almost all of them.
- **The owner's direction and D1.** The owner asked (25 Sep 2026) for new
  resources per era *if connected*. D1 refused new currencies. Both hold if
  crystal (FP-18) is a material in the store and the Core's rows, never a
  price in a shop.
- **Ads.** The references attach rewarded video to optional extras. The vision allows opt-in, additive ads,
  but each new placement is a monetization decision, not a design default (section 3.4).
- **Collapse.** A collapse today resets the whole Core progression, which
  strains the owner's "stronger foundation" (FP-19, O6). This is the
  largest open design question the research raised.
- **Earlier proposals.** Two of Lodeworks' own earlier proposals now
  conflict with the owner's 25 Sep list: "Rock of the Week" (weekly) and
  Union / Output Trials (server). They move to section 6.
