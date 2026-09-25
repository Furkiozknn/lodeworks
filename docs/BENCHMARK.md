# Lodeworks against the benchmark: where the player loop stands

The benchmark is Clash of Clans. The second group is Boom Beach, Whiteout
Survival, Rise of Kingdoms, Hay Day, Township and State of Survival.

This file takes stock of the game as it is (26 September 2026, branch
`visual/landscape-iso`) against their player loop. It measures the gaps,
and it records the one problem chosen to work on next.

- **Sources.** The mechanics and their sources are in `research/progression-reference.md`, `research/feature-pool.md` and the five reports in `research/reference-games/`.
- **Measurements.** They come from `tools/core_journey.gd`: a scripted player on the real game, reporting each Core level as a stage (`PROGRESSION.md`, "Core 7", "How it is measured").
- **Where numbers are unknown.** A human's pace, and anything on a phone, is UNKNOWN until it is measured. It is never estimated here.

## 1. The systems, as they are

Status meanings:

- **DONE:** built and covered by a test or a measuring tool.
- **PARTIAL:** built, with a gap the docs name.
- **MISSING:** not built.
- **UNKNOWN:** can only be settled on a device or with a human.
- **OBSOLETE:** superseded, but still in the repository.

| system | status | evidence | gap |
|---|---|---|---|
| Core 1→7 progression | DONE (this round) | `core_levels.gd`; `test_core_levels.gd`, `test_core7.gd`; played to Core 7 by `core_journey` | human pace unknown |
| Core 8 and later | PARTIAL | designed and graph-checked; asks for Overdrive and Resonant Frames 4 | not played; 9+ are a formula (P5) |
| Research tree | PARTIAL | `economy.gd`; the Core caps each line | a purchase list, not a choice: every research-paid line gets bought, and all are complete by Core 6 bar Resonant Frames; Ceramic Lining (heat) is paid in Cores |
| Strata | PARTIAL | 12 modifiers; the Core caps depth; `test_strata_*` | no stratum band has resources or sites of its own (P4) |
| Heat | PARTIAL | safe range, modes, levels, heat card; `test_heat.gd`; `heat_lab` in CI | no mode or cause mark on the board |
| Stability row | DONE | `CoreLevels.stable`, `holding_back`; tests | the hardest row on hot rock (see §3) |
| Resource chains | DONE | Ore → Gravel → Ingot → Plate → Component; each feeds levels, the store, Labs, Overdrive | no material after Components (Core 3); a new one waits on the owner (D1, FP-18) |
| Machines and levels | DONE | 12 types; levels; Overdrive | no Overdrive glow |
| Storage (the Core's store) | DONE | Vault levels; store rows; tests | no "store full" badge (FP-04) |
| Contracts (Dispatch) | PARTIAL | `dispatch.gd`; `test_dispatch.gd` | first version: no big shipments, no bulk buyer |
| Collapse | PARTIAL | `sim.gd` collapse; the tree and Cores kept | measured weak (§5); what it keeps is the owner's P6 |
| Blueprint | MISSING | `Sim.blueprints` saved but never written | P7, waits on P6 |
| Factory expansion (yard) | DONE | a ring every three strata from 10; test | growth is area only; see §4 |
| "What now?" | DONE | `worklist.gd`; tests | -- |
| Codex | PARTIAL | 12 running pages; test | no page for the Core, store, levels, modes, Overdrive, Dispatch |
| Tutorial | DONE | 8 steps; test | ends at the first Descend; never teaches the Core card |
| Save / migration | PARTIAL | atomic save, backup, newer-build guard; tests | version 1, no migration step (TD1) |
| Monetization | PARTIAL | rewarded double-offline; two one-time purchases; tests | no ad unit or Play products live; never run live |
| Settings / accessibility | PARTIAL | larger text, reduce motion, zoom key, battery saver | no colour-vision check; touch targets 43-44 dp only reported |
| Localization | DONE | English and Turkish; `loc_check` in CI | other languages not ready |
| Android / release | PARTIAL | debug APKs and AAB in CI | no signed build; Play Console is the owner's; CI billing blocked since 25 Sep |
| Camera / input | DONE on desktop, UNKNOWN on a phone | `test_iso.gd` | tiles 19-22 dp at depth; `DEVICE-TEST.md` not run |
| Performance | UNKNOWN on a phone | desktop: 6.2 ms p50 hero board, 18 ms p50 on a 308-machine board | never measured on a device |
| Visual presentation | PARTIAL | the Core grows to level 5 (marks to 8); level-up sound, pulse, Foreman line | no level-up card, no per-era look, single-frame sprites |
| `tools/journey_lab.gd` | OBSOLETE | plays without Core levels, still in CI | its numbers predate the Core; rewrite on `core_journey` or retire |

## 2. The benchmark loop, and Lodeworks' version of it

The benchmark games each run the same chain:

- a **problem**;
- a **mechanic** that answers it;
- a **decision** the mechanic forces;
- a **reward**;
- a **next goal**.

These are the chains that keep players for years (the sources are in the
research reports), with Lodeworks' version and its state:

| benchmark chain | Lodeworks version | state |
|---|---|---|
| TH can't go further → TH upgrade with prerequisites → which building first → caps rise, new buildings → fill the new caps | Factory Core → multi-row Core level → which row first → depth, levels, research, Overdrive → the next level's rows | Cores 1-7 DONE |
| Builders busy, resources pile up → parallel queues (builders, laboratory, army) → what to start now → completions at several cadences → the next job | three queues: credits (levels, the Core), store materials (Vault, levels, Overdrive), research (lines, Overdrive) | Core 7 runs all three; Cores 4-6 ran one (§3); research is not a choice (§1) |
| Resources past storage → storage upgrades as prerequisites → spend now or grow storage → a bigger store → the next tier's price | the store rows, beyond the Vault's level | DONE |
| Base full of maxed buildings → Supercharge, merges → which to push past the cap → more strength from old buildings → the next cap | Overdrive (Core 7) | DONE, first version |
| Orders board (Hay Day, Township) → make the goods asked → which order → a premium → the next order | the Dispatch board | first version |
| Survival pressure (Whiteout's cold) → heat as the constraint → where to heat and cool → working buildings → deeper, colder, harder | heat and strata: rock heat rises with depth; modes; cooling levels | DONE, and the game's own identity |
| Fog and regions (Boom Beach) → explore for resources → which region → new income → further regions | the world ring (FP-18) | MISSING; waits on the owner (A2, D1) |
| Prestige layer (idle genre) → reset for a permanent multiplier → when to reset → a faster next run → deeper runs | collapse → Cores → the Core-priced tree | weak (§5) |
| Layout editor (CoC) → saved layouts → try a configuration → a better base → share | Blueprint (FP-20) | MISSING (P7) |
| Clan, wars, capital (CoC) → cooperation | none (D3: no server) | out by decision; limits in §8 |

## 3. The economy, stage by stage

Scripted player, a new game, 25-26 September 2026:

- **A stage** is one Core level to the next.
- **Saving** is the time when every row still open is bought with credits alone: the Core's price, or a level short only of credits.
- **Decision minutes** are the minutes in which the player did anything.

Credit-only waits before Core 7 are fast-forwarded at the measured rate.

**Before this round (Core 7 as built on 25 September; old Cores 5 and 6):**

| stage | length | saving | decision minutes | earned, per second over the stage | into machine levels | into the Core | research made / spent |
|---|---|---|---|---|---|---|---|
| 1 → 2 | 7 min 30 s | 3% | 8 of 8 | 18/s | 750 | 1K | 43 / 40 |
| 2 → 3 | 8 min 50 s | 17% | 10 of 10 | 261/s | 10.9K | 60K | 754 / 565 |
| 3 → 4 | 16 min 49 s | 30% | 15 of 18 | 1.4K/s | 153K | 1.2M | 4.8K / 4.3K |
| 4 → 5 | 44 min 31 s | 82% | 8 of 45 | 4.0K/s | 518K | 10M | -- |
| 5 → 6 | 2 h 59 min | 91% | 17 of 180 | 6.3K/s | 7.5M | 60M | -- |
| 6 → 7 | 6 h 40 min | 2% | 139 of 401 | 6.1K/s | 106M | 15M | -- |

**After (new Cores 5 and 6):**

| stage | length | saving | decision minutes | earned, per second over the stage | into machine levels | into the Core | research made / spent |
|---|---|---|---|---|---|---|---|
| 4 → 5 | 12 min 34 s | 43% | 9 of 13 | 3.6K/s | 518K | 2M | 11.9K / 12.2K |
| 5 → 6 | 34 min | 52% | 23 of 35 | 5.7K/s | 7.5M | 3M | 19.3K / 19.2K |
| 6 → 7 | 5 h 35 min | 4% | 95 of 337 | 5.5K/s | 84M | 15M | 655K / 590K |
| 7 → 8 | not reached in 9 h | 0% | 296 of 546 | 2.8K/s | 38M | -- | 506K / 526K (14 Overdrive steps) |

**Firsts, new game:**

| Core | before | after |
|---|---|---|
| 5 | 1 h 18 min | 46 min |
| 6 | 4 h 17 min | 1 h 20 min |
| 7 | 10 h 57 min | 6 h 55 min |

**Storage** needed by each stage's rows:

| stage | store rows | Vault |
|---|---|---|
| 4 → 5 | 2,500 | 5 |
| 5 → 6 | 8,000 | 6 |
| 6 → 7 | 25,000 | 7 |
| 7 → 8 | 80,000 | 8 |

**The Core 7 era.**

- **Income:** 8.4K/s at Core 7 fell to 2.9K/s on stratum 19. The factory re-lays for heat: it placed 370 machines and sold 384 in nine hours.
- **Components:** the store's Components stopped at 6.7K (of 80K), because the Assemblers do not run on that rock.
- **Stability:** held at 38-42 of 100.
- **Resonant Frames 4:** 937K research.

## 4. What the benchmark questions show

- **A new player's first hour.** Measured on the old table.
  - 7 min: Core 2 (the first line, levels, the first research).
  - 16 min: Core 3 (Plates).
  - 33 min: Core 4 (Components, an Amplifier).
  - 1 h 18 min: Core 5.
  - From 45 minutes the player mostly waited: Core 4 → 5 was 82% credit-only, and Core 5 → 6 91%, with a decision in 17 of 180 minutes.
  - On the new table: Core 5 at 46 min, Core 6 at 1 h 20 min, and a decision in 32 of the 48 minutes between them.
- **Parallel goals.**
  - Early (Cores 1-3) and at Core 6 → 7 the player has 4-8 rows open at once, in different systems.
  - Cores 4-6 had one: credits.
- **Why come back tomorrow.**
  - Offline earnings: 45% of the measured rate, 4 hours banked.
  - The Core's next rows, and "What now?".
  - The store and contracts do not change while the player is away (FP-05).
  - Nothing is lost by staying away (no decay, no streaks: D2, V3).
- **Research.** A purchase list. Every research-paid line gets bought, and they are finished by Core 6; Resonant Frames and Overdrive are the first research spending that competes (research paces Overdrive in the Core 7 era).
- **Expansion.**
  - The yard grows by a ring every three strata.
  - The decisions grow with depth, not area: the rock's heat turns layout into cooling work.
  - The Core 7 factory is 175 machines, 57 of them Coolant Cells.
- **Mastery.**
  - The heat card, modes and Overdrive reward knowing the factory: a well-cooled line earns more than a hot one (Heat, measured).
  - There is no record of mastery yet (FP-13, FP-17).
- **Return loop.** The loop is:
  - come back;
  - see what was banked;
  - see the Core's rows and "What now?";
  - fix what stalled, buy a level or a step, start the next row.

  It works when there is more than one row to work on. In the old Cores 4-6 it did not: there was nothing to decide.

## 5. Collapse, measured

A second shaft after a collapse at Core 7, on the old Cores 5 and 6:

- **What it carried.** The research tree, and 111 Cores. The player bought Ceramic Lining 3 and Night Shift with the Cores.
- **Core 4 came much faster:** 7 min 40 s, against 33 min.
- **Core 6 came barely faster:** 3 h 50 min, against 4 h 17 min. The 10M and 60M prices still took 3 h 16 min of saving.
- **Core 7 was not reached in 16 hours.** The player could not hold stratum 15 stable with a smaller factory.
- **What that costs.** A collapse at Core 7 gives up about 11 hours of the Core's progress for a second shaft that is not faster where it matters.

Collapse is not yet a second progression layer:

- it keeps nothing of the Core;
- what it keeps (the tree) buys speed only where the game was already fast.

The same second shaft on the new Cores 5 and 6:

- **Core 5:** 15 minutes.
- **Core 6:** 42 minutes, against 3 h 50 min.
- **Core 7:** not reached in 16 hours; the player stalled at the stability row again.

Prestige now pays where the tree helps, in the first hour. The hot rock is
still a wall that a collapse does not touch.

## 6. The problem chosen, and why

**Four things were measured.**

- **Core 5 → 6 was a credit wall.** 91% of the stage was saving, and so was 82% of Core 4 → 5. A decision fell in 25 of their 225 minutes.
- **After Core 7, income falls.** 8.4K/s to 2.9K/s on strata 16-19, and Core 8's rows are out of reach for that factory.
- **Core 7 → 8 was not reached in 9 hours.** It was blocked by stability 100, Components and 937K research.
- **Collapse is weak.** A collapse at Core 7 bought a second shaft that reached Core 6 only 27 min sooner, because the mid-game prices were the same in every shaft.

**The problem chosen: the mid-game credit wall (Cores 4 → 6).**

- **It limits every player at the point retention is decided: the first day.** On the old table, hours 1 to 4 were 89% saving with one queue open, credits. The benchmark's first days are never a single queue.
- **It also capped prestige.** A second shaft paid the same 70M of mid-game prices, so a collapse bought almost no speed.
- **The cure was already built and measured.** The Core 7 model: rows that are the era's work, and a price set from what the factory earns while it does them.
- **The rest can wait.** The Core 7 era's wall comes later (hour 7 and on). It needs a design built on the measured income curve, which the brief itself asks for before Core 8 is written.

**What it did** (`PROGRESSION.md`, "Cores 5 and 6"):

- Cores 4 → 6 take 47 minutes, not 3 h 44 min.
- Saving fell from 3 h 19 min to 23 min.
- Core 7 comes at 6 h 55 min, not 10 h 57 min.
- A second shaft reaches Core 6 in 42 minutes, not 3 h 50 min.

**The next single problem: the Core 7 era.**

- **Deeper rock makes the factory poorer.** In the benchmark, every tier makes the base stronger. Here the Core 7 era gives Overdrive, but the rock takes 65% of the income.
- **Core 8 has to be designed from that curve,** not from a formula.

## 7. Retention loop, by horizon

| horizon | why a player comes back | what makes it true now | gap |
|---|---|---|---|
| first session | the next Core row is always in reach; every level opens a material or machine through Core 5 | Cores 1-4 in 33 min; "What now?" | the tutorial ends at the first Descend |
| first day | the Core's rows in several systems; offline banking | Core 7 is about 11 hours of active play | the Core 4-6 waiting (§6) |
| first week | hot rock: heat and stability at 13-19; Overdrive; the Core 7 era | measured to Core 7 and 3 h past it | income falls on strata 16-19; Core 8 not measured |
| first month | prestige; records; new material bands | -- | collapse weak (§5); no new material after Core 3; Blueprint missing |

Daily and weekly systems are left out on purpose:

- they are the benchmark games' answer to a server calendar;
- the owner ruled them out (D2);
- the game's return loop is the factory's state, not a clock.

## 8. Social: where the architecture stops

**Nothing is built, and nothing should be built for "later".** The limits
a future social layer would work within:

- **Sharing and visits.** Factory sharing, layout sharing and visits need a blueprint format. A share code (text, no server) is allowed now (FP-20), and it can be done in the single-player game first.
- **Server-backed systems.** Assistance, resource exchange, cooperative projects, leaderboards and reputation all need a server, an account and a privacy surface. They are out by decision (D3, V1).
- **What would help such a layer later:**
  - deterministic simulation (D5);
  - boards that serialize (`Grid.to_dict`);
  - a pure `Simulation` a server could replay.
- **Async challenges.** These can start without a server: fixed-seed trial boards (FP-16).

## 9. Visual and mobile

- **What the visuals show now.** The Core picture grows with its level. The yard grows ring by ring, and the heat view colours the board. On a level-up the Core pulses, a sound plays and the Foreman speaks.
- **Gaps against the benchmark:**
  - no level-up card listing what opened (FP-10);
  - no per-era ground or palette (B1);
  - no Overdrive glow;
  - single-frame sprites.
- **No new art this round.** The chosen problem is not visual, and the art budget stays where it is.
- **Mobile.**
  - The layout check covers eleven screen shapes, and the smoke test six windows.
  - Tiles at depth are 19-22 dp (B8).
  - Nothing has been measured on a phone (`DEVICE-TEST.md`).

## 10. Monetization

Monetization does not stand in for progression:

- rewarded video doubles offline earnings;
- two one-time purchases never change an economy number (tested).

Nothing changed in this round. Measuring how it sits in real play needs a
live build and players.
