# The whole game, against the benchmark loop

The round of 26 September 2026. The owner's brief: Lodeworks is to have
the progression and engagement loops of Clash of Clans and the other
long-lived reference games -- build, produce, upgrade, research, make
robots, upgrade them, send them out, (later) fight other factories, come
home with rewards, and grow -- in a factory, robot and underground world of
its own. It is not to copy their names or art, and not to leave out any
category of system they offer only because Lodeworks does not have it yet.

This document takes stock of every system, answers whether a new player
sees that fantasy in the first minutes, maps the reference games' unit and
operation loops, and designs the first slice of the missing loop.

Sources: the project's own research reports (`research/reference-games/`,
`research/clash-ux.md`, `research/feature-pool.md`), read for this round
and cited by their feature numbers; the code; the measurements in
`PROGRESSION.md`.

## 1. Can a new player see the fantasy in the first minutes?

**Yes, since the second slice (section 7): from the first minute.**

- **Minute 0:** the Core comes online with the Foreman's Rig standing in front of it. Every machine level bought, it walks out to the machines of that type, works on them with sparks, and walks back.
- **Minute 7 (Core 2):** the first gallery past the yard opens. The Foreman says so, and What now? points at it. The Rig clears its site alone and comes home with credits, research and Plates or Ingots. Core 3 asks for one site cleared, so every player sends it at least once.
- **Minute 31 (Core 4):** Assemblers learn to build Rigs, the other two galleries open, and the crew grows to three.

**Before it, the answer was no.** The first measurement found:

- **The first session is a factory in a shaft.** The tutorial's eight steps (`scripts/sim/tutorial.gd`) teach Drill, Crusher, Smelter and Vault, moving a machine, and the first Descend. The scripted player reaches Core 2 at 8 minutes, Core 3 at 16 and Core 4 at 33.
- **Nothing on the board is a robot or a character.** The only person is the Foreman, and he stands in the screen's margin by design (`scripts/ui/foreman.gd`: "He is never on the board").
- **Nothing leaves the factory.** The world around the yard is drawn: ore veins, crystal, heat vents. But nothing goes out to it and nothing comes back (`scripts/core/resource_nodes.gd`: "No machine draws on a node itself").
- **What the first hour promises is depth, not a world.** Deeper strata, more machines, the Core's next level. That loop is real and measured (Core 9 at 12 h 14 min), but it is only the first half of the owner's fantasy.

So the loop the reference games hang everything on -- the base makes an
army, the army goes out, what it brings back makes the base stronger -- was
not visible at any point, early or late. The first slice (sections 6 and 7)
put it at the Core's level 4, 33 minutes into the scripted player's game;
the second brought a small version of it into the first minutes.

## 2. Every system, classified

- **DONE:** built, tested or measured.
- **PARTIAL:** built, with a named gap.
- **MISSING:** not built.
- **WRONG-DIRECTION:** built or decided against the brief as it now stands.
- **UNKNOWN:** only a device or a person can settle it.

| system | status | evidence | gap |
|---|---|---|---|
| Core progression | PARTIAL | Cores 1-9 played by `tools/core_journey.gd` (Core 9 at 12 h 14 min); Core 10 written out and being played; 11 and up a formula grown 1.5 times a level (`PROGRESSION.md`, "Core 10") | human pace; Core 11+ unplayed, and past stratum 30 the rock alone overheats a Deep Bore |
| Factory Core | PARTIAL | levels, card, store, and from Core 10 its own export | its picture grows to level 5 only; no level-up card |
| Machines | DONE | 12 types, jobs, levels, modes, Overdrive | -- |
| Production chains | DONE | ore to Components; crystal to Alloy to Frames; Frames to research (Assay Bench) | -- |
| Resources | DONE | 8 materials, credits, research, Cores; each tied to two systems or more | -- |
| Storage | DONE | Vault levels, store rows, export (Core 10) | no "store full" badge |
| Contracts (Dispatch) | PARTIAL | `dispatch.gd`, tested | first version |
| Research / doctrine / Assay | PARTIAL | tree, branches, one doctrine a shaft, Assay Bench | the doctrine rows of Cores 8 and 9 ask for every level the shaft may have; research is spent by a fixed rule, not weighed |
| Heat | DONE | the game's own constraint, measured every era | no mode mark on the board |
| Strata | PARTIAL | 12 modifiers, crystal from 16, the Core caps depth | no sites of their own; conductive strata 26, 28, 29 broke the played factory (`PROGRESSION.md`, "Core 10") |
| Factory expansion | PARTIAL | the yard grows a ring every three strata | area only; no new kind of ground |
| Workers / robots / characters | **MISSING** → PARTIAL (this round) | the Foreman, in the margin; now Rigs: one at the Core from the first minute, more made on the board from Core 4, walking to the machines levelled (section 7) | one kind; drawn in code, not a sprite |
| Upgrades | DONE | machine levels, Overdrive, research | -- |
| Missions / operations | **MISSING** → PARTIAL (this round) | the galleries: one site from Core 2, three from Core 4; sorties, rewards (section 7) | four kinds of site; no chain of sites, no region |
| Combat potential | **WRONG-DIRECTION** → PARTIAL | V4 said "no combat"; amended by the owner this round (section 5). The rogue drill nest is the first site that fights back: strength against strength, wear as the cost | no roles, no counters, no defence |
| Rewards | PARTIAL | a Core level's opens, contracts' pay, Overdrive; now what sorties bring home: credits, research and materials | no reward only a sortie gives (a schematic, a blueprint) |
| Collapse / prestige | PARTIAL | the tree, Cores, blueprints and half the best Core kept | the second shaft saves for machine levels again (84% of Core 5 → 6) |
| Blueprint | DONE | save, check, lay from each line's end | no ghost on the board; no share codes |
| Long-term goals | PARTIAL | the Core's rows give goals of 30 min to 3 h | nothing beyond the next Core: no roadmap, no region, no army to grow |
| Return loop | PARTIAL | offline earnings, the Away report | no reason to come back except the factory; daily and streak loops are out by decision (D2) |
| Social architecture | MISSING by decision | V1/D3: single-player, no server; `BENCHMARK.md` §8 | -- |
| Monetization | PARTIAL | rewarded double-offline; two one-time purchases; tested | nothing live |
| Mobile UX | UNKNOWN | layout checked on eleven screen shapes in two languages | never played on a device (`DEVICE-TEST.md`) |

**The largest gaps, in the owner's own order of the fantasy:**

1. robots and characters;
2. operations;
3. rewards from outside;
4. combat.

All four are MISSING or were decided against. Everything else is at least
PARTIAL, and its gaps are named in `PROGRESSION.md` and `BENCHMARK.md`.

## 3. The reference games' unit and operation loops

Each chain reads: problem → mechanic → the player's decision → reward →
next goal. The source keys are the reports' own feature numbers:

- CoC = `clash-of-clans.md`
- BB = `boom-beach.md`
- WOS = `whiteout-survival.md`
- RoK = `rise-of-kingdoms.md`
- HD = `hay-day-township-state-of-survival.md`
- UX = `clash-ux.md`

Where a report does not say something, this document does not either.

### Clash of Clans

- **Making an army.**
  - *Problem:* waits between attacks (CoC #1).
  - *Mechanic:* the Barracks trains troops. Training cost was removed in 2022, and training time and hero healing in 2025 (UX §3; CoC #1).
  - *Decision:* the army's make-up; Army Recipes answer "what should I bring?" (#31).
  - *Reward:* loot, most of the income (#7).
  - *Next:* an upgrade, then another attack.
- **Heroes.**
  - The Hero Hall caps hero levels and gives 1-4 slots; each hero carries 2 equipment items (#10, #45).
  - *Decision:* the loadout.
  - *Next:* the next Hall cap.
- **Practice against the computer.**
  - The Goblin campaign: 90 levels, loot taken once, free retries, no clock (#21). Practice Mode (#104); Attack Challenges with a set army (#73).
  - *Decision:* the approach.
  - *Reward:* one-time loot, stars.
  - *Next:* the next level.
- **Base and army depend on each other.** Donated troops cost Elixir, and the Clan Castle's level caps the troops received (#87). UX §9.9: "waiting was moved off the fun verb".

### Boom Beach

- **Paying for attacks.**
  - Gold pays for actions, building materials for buildings (F37).
  - *Decision:* the target, helped by a difficulty label from "Too Easy" to "Impossible" measured against your own force (F69).
  - *Reward:* loot fixed at the first scout (F3); supply chests (F4).
  - *Next:* Radar opens more of the 149 regions (F20).
- **Upkeep sets capacity.** Garrisoned troops cost Gold an hour out of production (F17).
- **Conquest pays the base.**
  - Resource bases ship to the base, and are held against other players (F25, F1).
  - Boss bases never respawn and pay fixed rewards (F27).
- **Expeditions.** Submarine dives: three open at once, 6 h to two days, deeper with the Sub's level (F30).
- **Ladders against the computer.**
  - Dr. T's stages raise the threat after a full clear (F62).
  - Damage carries over between attacks (F65, F66).
  - Hammerman: defend against scripted waves with a preview and no loss (F63).

### Whiteout Survival

- **Training.** The loop is "build queue, then research, then training" (§1). Timers are skipped with speed-ups (C3).
- **Research and gear feed the troops:** Battle, Growth and Economy trees (P1); Chief Gear (P7).
- **Heroes without troops:** idle Exploration; each stage cleared raises the idle rate (M1).
- **Injury, on the workers:** cold makes survivors sick, the Clinic heals them (H10). Heat touches only the city (H7).

### Rise of Kingdoms

- **Tiers.**
  - Research opens troop tiers (27).
  - Upgrading a troop in place costs the difference (28).
  - Old tiers keep jobs: gathering, cheap fights (106).
- **Commanders.**
  - Barbarians cost Action Points (2).
  - Commander experience from barbarians and forts (29).
  - Talents (14).
- **Wounds.** Hospital or death; a full hospital kills (63). Losses against barbarians heal on return (112).
- **PvE feeds the base.**
  - The Castle needs Books of Covenant from barbarian forts (22).
  - A failed fort needs fewer troops next time (54).
- **Send and collect:** Expedition stars (55); dispatch missions whose success is near-certain when their requirements are met (38).

### Hay Day, Township, State of Survival

These have no units. Their "send it out, bring something back" loop is delivery:

- **Truck orders.** No expiry (C1); coins against experience (C3).
- **Boats and planes.** Crates to fixed destinations for fixed pay (C4, C5).
- **Township's ships and train.**
  - Islands with their own goods (A7).
  - The train brings back building materials (C6).
- **State of Survival.** Rescue intel adds troops; stamina recovers 1 per 300 s (R6). Its Underground has 101 floors with a pick of 1 of 3 (H6).

## 4. What Lodeworks takes, adapts, defers and rejects

| mechanic | seen in | verdict | why, and the Lodeworks version |
|---|---|---|---|
| Units made from the production chain | CoC Barracks; RoK 27 | **ADAPT** | A Rig is made by an Assembler on a job, from Plates and Components, into the Core's store: the factory is the army's supply line. |
| Unit production with no cost in time to skip | CoC #1; UX §3 | **TAKE** | A Rig takes a machine's cycles, not a wall clock. |
| Training or healing timers, speed-ups, paid queues | WOS C3; RoK 1 | **REJECT** | V3 (no timers as gates), D4. |
| Capacity | CoC #112; WOS U6 | **ADAPT** | A crew limit set by the Core's level, shown as have / limit. |
| Upkeep out of production | BB F17 | **DEFER** | A drain while offline reads as a punishment. |
| One research line that raises every unit | BB Armory; WOS P9 | **ADAPT** | "Rig Plating", paid in research: research gets a second customer. |
| Upgrade in place; old tiers keep jobs | RoK 28, 106 | **TAKE** | FP-09, no waste. |
| Heroes, talents, equipment | CoC #10; RoK 14 | **DEFER** | After the first loop holds. |
| Gacha recruitment; chance upgrades | BB F60; RoK 31 | **REJECT** | V3, D5. |
| Wounds, a hospital, death when it is full | RoK 63 | **ADAPT** (wear) / **REJECT** (death) | Rigs come home worn and are repaired with Plates. None is ever lost. |
| Stamina, action points, attempt caps, daily claims | RoK 2; HD R6 | **REJECT** | V3, D2. |
| A ladder against the computer: loot once, retries, no clock | CoC #21; BB F62 | **TAKE** | The operations board. |
| Printed fixed rewards; difficulty against your own force | BB F3, F69 | **TAKE** | Every site prints what it needs, what it pays, and "Too easy" to "Out of reach". D5 holds. |
| Damage that carries over; failure eases the next try | BB F65; RoK 54 | **ADAPT** | A site keeps what a short sortie took out of it. |
| A send-and-collect board | RoK 38; HD C1; Dispatch | **ADAPT** | Three sites, dealt deterministically like Dispatch contracts. |
| Wall-clock expeditions of hours | BB F30 | **DEFER** | A sortie is a walk of a minute or two that the player watches or leaves: the fun verb is not waited on. |
| PvE drops that gate base upgrades | RoK 22; HD C6 | **ADAPT** | A Core row asks for operations cleared. |
| Captured sites that ship resources home | BB F25 | **DEFER** | Needs the world ring (FP-18). Nothing stealable. |
| Defending the base against scripted waves | BB F63 | **DEFER** | The factory has no defences yet. |
| Unit roles, counters, loadouts | RoK 63; CoC #31 | **DEFER** | One Rig first; roles against strata hazards later. |
| Raids on players, theft, shields, revenge | CoC #7; UX §10.3 | **REJECT** now | V1, D3. The server-free version later: a rival factory loaded from a share code, and nothing is taken. |
| Rewarded video on an operation | HD C14 | **DEFER** | Each placement is the owner's call (V2). |
| Heat touches only the base | WOS H7 | **TAKE** | Heat stays a factory problem. A Rig has no heat, but the Assembler that makes it does. |

## 5. The binding decision this round changes

**V4 amended, 26 September 2026, by the owner.**

- **In:** robots, operations and fights against the computer.
- **Out until a server exists (V1/D3):** raids on other players, stealable resources, shields and revenge.
- **Later, without a server:** a rival factory loaded from a blueprint share code, fought with nothing taken.

`research/feature-pool.md` records the amendment beside the decision.

## 6. The first slice: Rigs and sorties

**Where it starts: the Core's level 4** (33 minutes into the scripted
player's game). Assemblers, Plates and Components are all there. It is
the first Core level whose store rows ask for Components.

**What the player does:**

1. **Makes Rigs.** An Assembler set to the **Rig Frame** job makes a Rig from two Plates. Made anywhere in the yard, a Rig walks to the Core, which keeps it as crew, up to the limit its level allows. The Rigs stand beside the Core, on the board.
2. **Reads the board.** The Core card shows three sites in the galleries below the shaft: a flooded gallery, a collapsed drift, an old pump house, a nest of rogue drills. Each prints:
   - what it needs, in strength;
   - its hazard, which wears the Rigs;
   - its fixed reward, in credits, research and materials;
   - how it compares to the crew, from "Too easy" to "Out of reach".
3. **Sends a sortie.** The player picks the site and how many Rigs to send, and pays their fuel in Ingots. The Rigs walk out across the yard to the site's mark beyond the edge, work there, and walk home. A sortie takes one to two minutes, and the factory runs on meanwhile.
4. **Takes the reward home.** It is decided the moment the sortie leaves, and printed.
   - **Enough strength:** the full reward, and the more to spare, the less wear.
   - **Too little:** a share of the reward in proportion to the strength sent, and the site keeps the damage done for the next sortie.
5. **Repairs.** Worn Rigs are weaker. Repairing them costs Plates from the store, at once.
6. **Upgrades.** Rig Plating, a research line, makes every Rig stronger.
7. **Goes further.** A cleared site is dealt again, harder, from what the Core's level and the stratum allow. Core 5 asks for five sites cleared.

**What it hooks into:**

| system | how |
|---|---|
| machines and jobs | the Rig Frame job, and the rule that only a machine touching the Core fills its store |
| store and lines | a Press's Plates make Rigs; Ingots from the store fuel sorties; Plates repair |
| heat | the Assembler that makes Rigs is a heat decision like any other |
| research | Rig Plating |
| strata | a site's hazard comes from the stratum's modifiers, and deeper sites open with depth |
| Core rows | a new kind of row, operations cleared |
| collapse | Rigs and the board go with the shaft; the research is kept |

**What it leaves out:**

- more than one kind of Rig, roles and counters;
- heroes, equipment and upkeep;
- the world map and held sites;
- defending the base;
- sorties of hours;
- picks during a sortie;
- rewarded video;
- anything that needs a server.

Each of those is a later layer on the same rule.

**Why these choices:**

- **The Rigs are seen.** The owner asked for robots that are physically on the board, and for operations that do not feel like a menu apart from the factory. So the Rigs stand at the Core and walk out to their site.
- **A sortie is short.** Its outcome is decided when it leaves, as a Clash battle's is played in minutes; a minute or two of walking keeps the verb visible without gating anything on the clock (V3).
- **Nothing random** (D5). The same board, the same sortie and the same outcome on every device.

## 7. What was built this round

| part | where | tested |
|---|---|---|
| **Rig**: a new product (not a store material), sold by a Vault at 140 | `MachineDB.Res.RIG` | `test_operations.gd` |
| **Rig Frame**: an Assembler job, 2 Plates → Rig, a tenth of the pace, from Core 4; a Rig walks to the Core from wherever it is made | `MachineDB.JOBS`, `Simulation._transfer` | yes |
| **The crew**: the Core keeps Rigs up to a limit (3 at Core 4, +1 a level); Rigs out still count | `Sim.crew_cap`, `_sync_core` | yes |
| **The board**: three sites dealt from the Core's level, the stratum and a count (flooded gallery, collapsed drift, old pump house; from Core 5 the rogue drill nest, which wears Rigs hardest) | `Operations.deal` | yes |
| **Sorties**: decided when they leave; the walk of 40-80 s; reward and wear on the way home; a short sortie keeps its share and leaves the site weaker | `Sim.send_sortie`, `advance_ops`, `Operations.resolve` | yes |
| **Repairs** in Plates; **Rig Plating** (a research line, the new Robotics branch) | `Sim.repair_rigs`; `Economy` | yes |
| **Core 5 asks for five sites cleared** (a new kind of row) | `CoreLevels.Req.OPERATIONS` | the graph checks (`test_core7.gd`) |
| **Saves and collapse**: sorties out when the game closes come home on loading; a collapse takes the crew and the board, and keeps Rig Plating | `Sim.to_dict`, `from_dict`, `collapse` | yes |
| **On the board**: Rigs stand in a row at the Core; sorties walk out across the yard to gallery mouths past three of its edges, work there (sparks), and walk home; a bar under each mouth shows what is left of its site; a tap on a mouth opens the galleries | `IsoView._draw_galleries` | a capture (`tools/screenshot.gd`, `LODEWORKS_CAPTURE=rigs`) |
| **The Core card**: a Galleries section first, the crew line with a Repair key, each site with its strength against the crew, its pay and a Send key | `main.gd`, `_core_operations` | the UI smoke and layout checks |
| **The scripted player** lays a Rig Frame beside a Press where its heat overheats nothing, sells it once the crew is whole, repairs at a third worn, buys Rig Plating only when a repaired crew could not clear any site, and sends a sortie to every site the crew clears -- or, while the Core asks for sites, its whole crew to the weakest. | `core_journey_player.gd` | `core_journey` |
| **English and Turkish** for every new line | `locale/` | `loc_check` |

**Cost on the board:** the galleries and the whole crew go to the
renderer as one list of triangles a frame, on the layer the machines are
drawn on: no node and no texture. `tools/perf_probe.tscn` now measures the
board with five Rigs home and two sorties out. On this machine (Intel UHD,
gl_compatibility, 1440x720), drawn a shape at a time they took the idle
board from 191 draw calls to 295 and its median frame from 6.2 to 8.3 ms;
as one list, 186 draw calls and 7.0 ms, the same as the board without them
(7.1 ms, 187). The late board (308 machines, stratum 16), with the
same crew on it, went from 336 draw calls to 227. A phone: not measured.

**Added after the first commit of the slice:**

- **The crew grows by what it has done.** Every ten sites cleared, in any shaft, the Core finds room for one more Rig, up to six more (`Operations.earned_rigs`). The Core card says how many sites are still to go.
- **Service calls.** When a machine type is levelled or driven, up to three Rigs from the Core walk to the machines of that type nearest it, work on them with sparks, and walk back. The upgrade is the player's the moment it is bought: this is only for the eye, so the decision has a body on the board.
- **A Rig is drawn in the board's own projection:** an orange box on dark treads, a cab set back, a lamp, and an antenna whose light blinks faster at work. It is still drawn in code, a few polygons, not a sprite.
- **The Foreman's first-contact line** at Core 4, and **the gallery mouths from the first minute**, boarded up until the crew opens (a tap says when).

**The second slice: the crew in the first minutes.**

- **The Foreman's Rig.** The Core comes online with one Rig (`Operations.FIRST_CREW`). Until Core 4 it is the whole crew: nothing makes Rigs yet, and sites cleared earn no room.
- **The first gallery, at Core 2.** One site (`Operations.slots`), a Flooded Gallery or a Collapsed Drift, of strength 8, which one whole Rig clears. It pays a quarter of what a site of its strength pays later (`EARLY_PAY`), and never less than ten seconds of the factory's income.
- **Core 3 asks for one site cleared.** A Core row now counts the sites cleared since the Core last grew, so Core 5's five are still the Core 4 crew's.
- **What now? has a line for a sortie:** "Send 1 Rig to the Flooded Gallery", when the Rigs at home clear a site and can go.
- **The Foreman's line at Core 2** says the first gallery is open.
- **The scripted player** repairs as soon as wear alone keeps its crew from every site, and lays no Rig Frame again under a Core whose rock overheated one (measured: see section 8).

**Not yet:**

- a sprite for the Rig and the gallery mouths as rich as the machines';
- a second kind of Rig;
- a reward only the galleries give.

## 8. Played

A new game by the scripted player, against the same game before the crew:

| | before | with the crew |
|---|---|---|
| Core 4 | 33 min 09 s | 33 min 09 s |
| the first Rigs, and the Rig Frame sold (the crew whole) | -- | 34 min 24 s |
| the first sortie | -- | 34 min 59 s |
| Core 5 (now asks for five sites cleared) | 45 min 44 s | 45 min 44 s |
| Core 6 | 1 h 19 min 44 s | 1 h 21 min 10 s |

- **The crew costs the early game two minutes.** Five sites cleared go into the Core 4 stage beside its other rows, and the Core 5 stage plays as before.
- **The Core 5 stage is the scripted player's most fragile.** Its rows ask for stability 60 on stratum 12, where lines laid on stratum 9 overheat. Two things tipped it into three hours without Core 6:
  - a Rig Frame laid on a fixed tile, whose heat overheated the Press beside it (measured from the same Core 5 game, with and without it);
  - Rig Plating bought against a worn crew, which took the Core 4 era's research (with it, Core 6 was not reached in 2 h 30 min; without any, at 1 h 29 min).
  The player now lays its Rig Frame where its heat is safe and sells it once the crew is whole, and weighs Rig Plating against a repaired crew. Sorties themselves did not tip it: with the crew sent out whenever a site can be cleared, Core 6 came at 1 h 21 min.
- **Played past Core 6 with the crew, it stalled.** A whole new game, 26 hours of play: Core 7 was never reached. The Core 7 row's stability stood at 0 from 2 h to 26 h. One Assembler overheated there: a Rig Frame, laid again each time the crew earned room for one more Rig, sold for stability, and laid again (689 decisions in the stage: 322 machines placed, 329 sold). The player now sells a Rig Frame the rock overheats and lays none again under that Core.

**The second slice, played** (a new game, the same scripted player, credit-only waits fast-forwarded):

| | the first slice (crew from Core 4) | the second slice (the Foreman's Rig) |
|---|---|---|
| the first sortie | 34 min 59 s | **7 min 30 s** (Core 2) |
| the first repair | 39 min 49 s | 12 min 55 s |
| Core 3 (now asks for one site) | 16 min 20 s | 15 min 20 s |
| Core 4 | 33 min 09 s | 30 min 59 s |
| Core 5 | 45 min 44 s | 45 min 54 s |
| Core 6 | 1 h 21 min 10 s | 1 h 18 min 04 s |
| Core 7 | not in 26 h | **4 h 49 min** (6 h 55 min before the crew) |
| Core 8 | -- | **6 h 52 min** (8 h 50 min before the crew, and only from kept saves) |
| Core 9 | -- | not in 8 h of play from Core 8 (below) |

- **The first sortie comes at minute 7, and the early game is a minute or two faster.** The one site costs the Core 2 stage nothing; its pay (a quarter of a later site's) brings Core 3 a minute sooner and Core 4 two.
- **This is the first new game played straight to Core 8.** The measurements of Cores 8 and 9 in `PROGRESSION.md` were made from saves kept at Cores 7 and 8 of earlier games.
- **Core 8 → 9 did not finish.** Its Frame row stood at 0 of 30,000. The scripted player's Core 8 factory:
  - made no Components at all (11 in the store for eight hours). With Vault 9's Alloy and Components fed to the store, as it feeds a machine row, the store was full of Components within two hours;
  - still made no Frames. Every Frame Jig on the Core's side starved of Components: two of the three Alloy Parts machines it laid stood beside the Core, not beside a Jig, and filled the store; the one beside a Jig had no Alloy; and in two and a half hours no feeder was laid beside a starved Jig.
  This is the scripted player's limit, not yet the game's: a person lays an Alloy Parts machine between a White Heat Smelter and a Frame Jig. The Core 9 era is measured in `PROGRESSION.md` from a kept Core 8 save (3 h 24 min).
- **A finding for the design, not the player:** at Core 8 the Core's store held 85,899 Components and 85,899 Alloy while its Frame Jigs starved. The store only takes: nothing on the board draws from it. Whether a machine beside the Core should is a design question for a later round.
