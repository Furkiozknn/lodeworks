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
| Core progression | PARTIAL | Cores 1-13 written out and played by `tools/core_journey.gd` from a new game (section 13, "Played"); 14 and up a formula that grows each kind of row in its own way (`PROGRESSION.md`, "Cores 12 and 13") | human pace; Core 14+ unplayed, and past stratum 30 the rock alone overheats a Deep Bore |
| Factory Core | PARTIAL | levels, card, store, and from Core 10 its own export | its picture grows to level 5 only; no level-up card |
| Machines | DONE | 12 types, jobs, levels, modes, Overdrive | -- |
| Production chains | DONE | ore to Components; crystal to Alloy to Frames; Frames to research (Assay Bench) | -- |
| Resources | DONE | 12 materials (with Resonite, the Lens, Umbrite and the Prism of the deep map), credits, research, Cores; each tied to two systems or more; the Lens now has six uses (section 13) | -- |
| Storage | DONE | Vault levels, store rows, export (Core 10) | no "store full" badge |
| Contracts (Dispatch) | PARTIAL | `dispatch.gd`, tested | first version |
| Research / doctrine / Assay | PARTIAL | tree, branches, one doctrine a shaft, Assay Bench | the doctrine rows of Cores 8 and 9 ask for every level the shaft may have; research is spent by a fixed rule, not weighed |
| Heat | DONE | the game's own constraint, measured every era | no mode mark on the board |
| Strata | PARTIAL | 12 modifiers, crystal from 16, the Core caps depth | no sites of their own; conductive strata 26, 28, 29 broke the played factory (`PROGRESSION.md`, "Core 10") |
| Factory expansion | PARTIAL | the yard grows a ring every three strata | area only; no new kind of ground |
| Workers / robots / characters | **MISSING** → PARTIAL (this round) | the Foreman, in the margin; now Rigs: one at the Core from the first minute, more made on the board from Core 4, walking to the machines levelled (section 7); from Core 6 the Breaker, from Core 10 the Surveyor (section 12), each with a pose sheet of its own (section 13); a Surveyor also keeps a Beacon, guides in the dark and tunes a machine | three kinds |
| Upgrades | DONE | machine levels, Overdrive, research | -- |
| Missions / operations | **MISSING** → PARTIAL (this round) | the galleries: one site from Core 2, three from Core 4; sorties, rewards (section 7); from Core 10 expeditions into three regions with sites of their own (section 12); from Core 11 a region is held by a Beacon and gives work of its own, from Core 12 a fourth, the Dark Reach (section 13) | no chain of sites; four fixed regions |
| Combat potential | **WRONG-DIRECTION** → PARTIAL | V4 said "no combat"; amended by the owner this round (section 5). The rogue drill nest is the first site that fights back: strength against strength, wear as the cost | no roles, no counters, no defence |
| Rewards | PARTIAL | a Core level's opens, contracts' pay, Overdrive; what sorties bring home: credits, research, materials, and **salvage**, which only a cleared site pays and which buys Salvaged Gearing (every machine faster) and Rig Plating (section 7) | one currency of its own; no one-time finds (a schematic, a blueprint) |
| Collapse / prestige | PARTIAL | the tree, Cores, blueprints and half the best Core kept | the second shaft saves for machine levels again (84% of Core 5 → 6) |
| Blueprint | DONE | save, check, lay from each line's end | no ghost on the board; no share codes |
| Long-term goals | PARTIAL | the Core's rows give goals of 30 min to 3 h; from Core 10 a region to open each level to Core 12, and a crew of three kinds to grow (section 12); from Core 11 Beacons to light and keep, from Core 12 the Dark Reach and its Prisms; Core 14 asks for all four regions and three Beacons (section 13) | no roadmap screen; after the fourth region the formula asks for more of the same kinds |
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
| Loot only a battle brings, spent on the base | CoC #7; BB Power Stones; RoK 22 | **ADAPT** | Salvage: only a cleared site pays it; it buys a production line (Salvaged Gearing) and the crew's own (Rig Plating), so every sortie is spent on the base or on the crew. |
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

**The third slice: salvage, the galleries' own pay.**

- **What a cleared site holds that the factory cannot make.** Every cleared site pays salvage besides its credits, research and material: one from a first-tier site, one more a tier, two more from the rogue drill nest (`Operations.salvage`). A sortie too weak to clear a site takes its share of the rest, and no salvage. The site's row prints it.
- **What salvage buys.** Two lines of the research tree also cost salvage (`Economy`, `cost_salvage`):
  - **Salvaged Gearing**, new, in the Robotics branch: every machine works 5% faster a level, ten levels, from Core 2. Its first level is 4 salvage and 100 research;
  - **Rig Plating**, which now costs 2 salvage at its first level as well as its research.
  So a sortie's salvage goes to the factory or to the crew: the reference games' army-or-base choice.
- **Kept like Cores:** a collapse keeps unspent salvage; a save keeps it. The Core card's crew line says how much there is and what it buys; the research card shows its price beside the research.
- **The scripted player** buys Salvaged Gearing whenever it can, unless the crew needs Rig Plating first.

**Not yet:**

- a sprite for the Rig and the gallery mouths as rich as the machines';
- a second kind of Rig;
- one-time finds in the galleries (a schematic, a blueprint).

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

**The third slice, played** (salvage; the same new game and player):

| | without salvage | with salvage |
|---|---|---|
| Core 4 | 30 min 59 s | 30 min 09 s |
| Core 5 | 45 min 54 s | 43 min 49 s |
| Core 6 | 1 h 18 min 04 s | 1 h 23 min 25 s |
| Core 7 | 4 h 49 min | 7 h 15 min |
| Core 8 | 6 h 52 min | 10 h 05 min |
| Salvaged Gearing | -- | level 1 at 13 min, 3 at 30 min, 5 at 2 h 54 min |
| sites cleared | -- | 22 by 30 min, 28 by 1 h, 48 by 3 h, then none to 10 h |

- **Salvage turns the first half hour's sorties into the factory's speed:** 22 sites and three levels of Salvaged Gearing before Core 4, and Cores 4 and 5 two minutes sooner.
- **Core 7 came 2 h 26 min later, and it was the purchases that moved it.** The same game with salvage paid but Salvaged Gearing never bought reached Cores 2 to 7 at the same second as the game without salvage. With it, the Core 6 stage's stability row (80 machines running at working heat) took 5 h instead of 12 min. A faster machine makes no more heat, and the row counts only machines running. Measured in that game's Core 6 factory, every half hour for four hours: of the machines at working heat, 49-74 were running, 25-37 starved and 10-27 blocked, and one to six overheated at times. The row was short of fed machines, not of cool ones; why buying Gearing left more of them starved is not yet measured.
- **The crew stopped at 48 sites.** From about 3 h to 10 h the scripted player cleared no site, with eight to ten Rigs. Why is not yet measured; its sortie and repair rules are the next thing to look at before the galleries' late game is measured.

## 9. Proving the loop (measured, 26 September 2026, evening)

The owner's brief for this round: before a second kind of Rig or a
defence, prove that factory → Rig → sortie → reward → factory works, and
make the Core 8 → 10 measurement trustworthy.

### What stopped Core 9: the store and the Frame line

Two Core 8 factories of the scripted player, measured with a probe:

| | the first (the player before this round) | the second (the player now) |
|---|---|---|
| store: Components / Alloy | 11 / 85,899 for eight hours | 22,542 / 54,777, both full within 90 min |
| the Frame Jig | Alloy + Component → Frame, 0.7 cycles a second | the same |
| Alloy makers (White Heat) | 36-48, able to make 170-225 a second, making 68-76: blocked by the full store | the same shape |
| Component makers (Alloy Parts) | 1-3, none beside a Jig with Alloy | 2 beside the Core, 1 beside a Jig |
| Frames | 0 for eight hours | the row of 30,000 met within 30 minutes of Core 8 |

What each part was:

- **Simulation bug in the transfer: none.** Every unit moved by the rules the code states: a machine hands its output round robin to the neighbours that take it, and to the Core last while its store has room.
- **Production-chain design: sound.** A Frame is an Alloy and a Component, and a Component is an Alloy: two White Heat lines a Jig.
- **Storage architecture: the store only takes, by design.** It pays for levels, Overdrive, repairs, fuel and contracts, and feeds no machine. A player could not see that. A starved machine now says which input no neighbour makes, and, beside the Core, that the store feeds no machine.
- **Transfer rule: sound.**
- **Scripted player: the cause.** It never fed the store what Vault 9 is paid in (Components), took Alloy Parts beside a Jig for another job, and laid Alloy Parts beside the Core rather than beside a Jig. Fixed in the player, not the game.

What a person does: lays an Alloy Parts machine between a White Heat
Smelter and a Frame Jig that touches the Core.

**A simulation bug found on the way.** Every placement, sale, move, mode
and job change reset every machine on the board: its half-done cycle, its
status and its uptime (`Simulation.reset_progress`). Every progress ring
emptied at each placement; a Rig Frame, eleven seconds a cycle, could not
finish while a player kept building; and anything that read a status in
the same moment saw the whole board idle. The scripted player's tidy-up
read that and scrapped six Duplicators, the Core 6 row's, and forty
machines in an hour. Now only the edited tile forgets (`Simulation.forget`),
tested (`test_a_machine_placed_elsewhere_keeps_every_other_machines_cycle`).

### Why the crew stopped after three hours

Measured from a Core 6 save, every fifteen minutes:

1. **Repairs waited on Plates the Core's rows kept.** 20 Plates of 8,389 were kept for a row of 25,000 the store could not yet hold (the Vault's level comes first). The crew stayed worn for 75 minutes.
2. **Three sites the crew could not clear at once.** Three tier-2 sites of 114 against a crew of 80; the player sent a sortie that only takes a share only while a Core row asked for sites.
3. **Rig Plating only when a row asked for sites.**
4. **At Core 8, no fuel.** The factory of the Core 8 era makes crystal and Alloy, and few Ingots: 38 in the store, and a sortie of thirteen Rigs burns 173.

The game let a person go on in cases 1-3: the site row said "hard: a share
of it" and its Send key worked. What now? did not point at such a site;
it now does ("they bring home 70% of it and leave it weaker"). Case 4 was
the game's: **fuel now follows the era**, Ingots until Core 8 and Alloy in
it (`Operations.fuel_res`). The player now chips at sites, repairs from
Plates kept for a row the store cannot yet hold, and buys Rig Plating on
research no row waits for. From the same Core 6 save, 28 sites cleared in
all: the player before went to 48 and stopped; the player now reached 218
in three hours.

### Salvage, three ways

The same new game, the three ways the scripted player can spend salvage
(`LODEWORKS_CORE_SALVAGE`). B was the run carried on to Core 10 and was
cut at 24 h before it printed its report, so its times are read from the
hourly marks:

| | A: none (no Gearing) | B: Salvaged Gearing first | C: Rig Plating first |
|---|---|---|---|
| Core 4 | 25 min 44 s | by 30 min | 25 min 44 s |
| Core 6 | 1 h 14 min | between 1 h and 2 h | 1 h 08 min |
| Core 7 | 6 h 51 min | between 6 h and 7 h | 6 h 29 min |
| Core 8 | 8 h 26 min | between 8 h and 9 h | 8 h 32 min |
| income at Core 8 | 25.3K/s | 32.3K/s (9 h mark) | 38.7K/s |
| Rig Plating, at the 8 h mark | 4 | 3 (and Gearing 10) | 7 |
| sites cleared, at the 8 h mark | 718 | 664 | 817 |
| salvage unspent, at the 8 h mark | 1,483 | 623 | 1,410 |
| decisions, Core 6 → 7 | 366 in 122 of 338 min | not recorded | 440 in 133 of 322 min |

**The verdict: salvage is not yet a choice.** Every way reaches the eighth
hour with more than a thousand salvage unspent. What limits Gearing and Plating is
research and the Core's research caps, never salvage; the player who buys
Gearing first buys Plating too, and the reverse. A choice needs salvage to
be scarce: fewer a site, or dearer lines, so that a level of Gearing is a
level of Plating not bought. That is the next change to the galleries.

### Core 1 → 10 in one new game

A new game with every change of this round, the scripted player spending
salvage on Gearing (B above), carried on to 24 h; the stage figures are
scenario A's, the same game to Core 8 with its full report:

| stage | length (A) | only credits left (A) | minutes with a decision (A) | the row that came last | what the stage opens |
|---|---|---|---|---|---|
| Core 1 → 2 | 6 min 20 s | 4% | 7 of 7 | credits | the first gallery; Salvaged Gearing |
| Core 2 → 3 | 6 min 10 s | 23% | 7 of 7 | credits (a site cleared by then) | the Assembler |
| Core 3 → 4 | 13 min 14 s | 62% | 8 of 14 | credits | the Rig Frame, a crew of three, three galleries, Rig Plating |
| Core 4 → 5 | 11 min 09 s | 42% | 8 of 12 | credits (five sites by then) | the Condenser, the nest |
| Core 5 → 6 | 37 min 29 s | 1% | 35 of 39 | the Drill's level | Resonant Frames |
| Core 6 → 7 | 5 h 37 min | 0% | 122 of 338 | stability 80 (4 h 26 min) | Overdrive, the deep chain, doctrines |
| Core 7 → 8 | 1 h 35 min | 27% | 27 of 96 | credits | the Frame Jig, Alloy fuel |
| Core 8 → 9 (B) | 2 to 4 h (hourly marks) | -- | -- | Vault 9's Alloy, the doctrine, then stability 120 and the price; the Frame row went first | the Assay Bench |
| Core 9 → 10 (B) | not in 12 h | -- | -- | **four Assay Benches at work: 0 of 4** | the Core's export |

- **Cores 1 to 9 are now reached in one new game** (Core 9 between 11 h and 12 h), and the galleries run the whole way: 1,684 sites cleared by 24 h.
- **Core 10 is blocked by the same class as Core 9 was:** eight Assay Benches laid, every one starved: their Frame Jigs have no Alloy Parts or Alloy beside them, and three stand alone -- while the store holds 67,000 Frames. A person builds White Heat → Alloy Parts → Frame Jig → Assay Bench; the scripted player does not. Nothing feeds a machine from the store (above).
- **The long stage is still Core 6 → 7, and it is the stability row.** In A it took 4 h 26 min of the 5 h 37 min.
- **Core 9 and 10 each open something to do** (the Assay Bench, the export), but their rows are mostly more of the Core 8 era's chains; the Core 10 row is the first that asks for a four-stage line.

## 10. The robot loop against the reference model (design, not built)

**What a Rig does for the player today.**

| function | status | how |
|---|---|---|
| production | real | an Assembler on the Rig Frame job, from Plates (Core 4); the Foreman's Rig before it |
| capacity | real | the crew's room: the Core's level, and one more Rig every ten sites cleared, up to six |
| upgrade | real | Rig Plating: research and salvage |
| repair | real | Plates, at once; wear makes the crew weaker, never smaller |
| operation | real | sorties: strength against a site, a share when short, the site weaker for the next |
| reward | real | credits, research, a material, and salvage only a cleared site pays |
| risk and reward | real | wear by hazard; the nest pays more salvage and wears most |
| factory work | **for the eye** | service calls walk to the machines levelled; they change nothing |
| specialization | **missing** | one kind of Rig |
| technology | partial | one line (Rig Plating) |

**The largest gap in that table is the factory work.** The Rigs walk to the
machines, and the machines do not notice. The Core 8 finding (section 9)
points at the job the factory has for them: the store fills with what the
lines make, and nothing takes it out again.

**The next step, chosen: posting a Rig.**

- **What it is.** A Rig at the Core can be posted to a machine touching the Core. There it hauls one input the machine takes from the Core's store: Components to a Frame Jig, Plates to a Rig Frame.
- **What it costs.** A posted Rig does not go on sorties. A post takes a Rig for as long as it stands.
- **The decision it makes.** Crew in the galleries (pay, salvage, the crew's growth) or crew in the factory (a full store turned back into production), from the same Rigs.
- **The reference games.**

| mechanic | seen in | verdict | the Lodeworks version |
|---|---|---|---|
| Production draws its ingredients from storage | Township, Hay Day (A4: production starts when every ingredient is in the barn) | **ADAPT** | Only through a posted Rig, only beside the Core: the lines stay the puzzle, and the store becomes a supply the crew hauls from |
| A limited pool of workers assigned to jobs | CoC builders; WOS survivors assigned to buildings | **ADAPT** | The crew is the pool; a Rig posted is a Rig not in the galleries |
| Wounded units heal in a hospital | RoK 63; WOS Clinic (H10) | **ADAPT** (already) | Wear and Plates; no Rig is ever lost |
| Units that cost upkeep | BB F17 | **DEFER** | A drain while offline reads as a punishment |

**The second kind of Rig: research only.** A second kind has to answer a
property of the sites, not just add strength:

| role | reference | what it would answer | verdict now |
|---|---|---|---|
| heavy (strong, slow, costly) | BB Heavy; RoK infantry | tier-2 sites and the nest: need | DEFER until one Rig's loop is measured stable |
| support (lowers the crew's wear) | BB Medic | hazard | DEFER |
| hauler (carries more of the pay) | Township trains and ships | reward, not need | DEFER; overlaps posting |
| scout (deals a better site) | BB Radar, RoK scouts | target choice | DEFER |
| defence | CoC and BB defences | nothing attacks the factory yet | REJECT until there is an attack |

**Towards fights (architecture, not built).** Every link of the chain
factory → robot production → upgrade → composition → operation → target →
encounter → damage → repair → reward → factory already has a place in the
code, except composition:

| link | where it lives |
|---|---|
| production | `MachineDB.JOBS["assembler"]["rig"]`, the Core's crew room (`Sim.crew_cap`) |
| upgrade | `Economy` lines on effect `rig_power` (Rig Plating) |
| composition | **missing**: a sortie is *n* Rigs of one kind |
| operation, target | `Sim.send_sortie`, `Operations.deal` |
| encounter | `Operations.resolve(site, strength)`: decided when the sortie leaves (D5) |
| damage, repair | `rig_wear`, `Sim.repair_rigs` |
| reward | `Operations.reward`, `Operations.salvage` |

A rival factory later is one more kind of target: its need and hazard come
from a blueprint's machines (a share code, V4), and `resolve` stays the
encounter. Nothing in it needs a server; raids that take anything from a
player still do (V1/D3), and stay out.

## 11. Posts, a second kind of Rig, and Core 10 from a new game (27 September 2026)

The owner's brief for this round: robots that do real work in the factory,
the Core 10 blocker solved with a system a player understands, salvage a
choice, the Core and the ground that grow, a game's menu, the Foreman in
the world, sorties that are a strategy -- and every step measured.

### What a new game found, and whose it was

A new game played by the scripted player with posts and the Rig Bay (run
P) stood at Core 5 for four hours. Every cause, found by probing its Core 5
save, and whether the game or the scripted player owned it:

| cause | whose | the change |
|---|---|---|
| Two posted Rigs carried every Ingot to the Presses beside the Core; the Core 6 row's 8,000 Ingots stood at 0 | **the game** | A posted Rig leaves in the store what the Core's next level asks for (`Sim.haul_floor`); the Bay's screen says how much is kept |
| Sorties burnt the same Ingots as fuel | the player | Fuel the Core's rows keep is not burnt, at every level (it was from Core 7) |
| A blocked machine's Vault was sold for a new Vault 55 times in five minutes | the player | A blocked machine is given the time to show its Vault worked; a Vault is never sold for another |
| The Drills a Duplicator served were sold for room, and the Duplicator row fell to two of three | the player | What a Duplicator or Amplifier stands beside is not built "for income alone" |
| 67 tiles sold for heat were never built on again | the player | A tile is left bare for an hour, not for good |
| Smelters beside the Core counted as feeders while their Crushers were gone | the player | A feeder starved most of the time is not one, at every level |

Three more, found on the way to Core 10:

| cause | whose | the change |
|---|---|---|
| In the Core 8 era a maker laid beside the Core was read as starved before its first cycle and sold on the next beat, 120 times in five minutes; every placement disturbed its neighbours' heat, and the stability row stood at 0 | the player | A maker laid there is given five minutes |
| The Core 10 row asks the store for 300,000 Frames; a Vault 9 holds 274,878, and the floor kept all of them from the crew: no Rig fed an Assay Bench, and the row of four Benches at work stood at one for thirteen hours (run Q) | **the game** | A row the store cannot hold yet leaves the top 5% of a full store to the crew (`Sim.HAUL_TOP`): the Core takes nothing more until the Vault grows |
| Eight Benches laid with their chains, seven starved, none beside the Core; every dock fed Presses | the player | A starved machine a row asks for is moved beside the Core, and a Rig on a machine no row asks for is called home for it |

From the same Core 9 save after these: three Benches moved and posted in
an hour, the Benches' row met, and only the stability row left.

### Core 1 -> 10 in one new game

**Core 10 in 12 h 32 min of a new game** (run X: the code of this round,
salvage on Gearing first). The first to get there was run S, at 14 h 12
min, before Plates were fuel and before the Breaker; run R, with the
floor kept whole, stopped at Core 9 for fourteen hours. What each stage of
run X was, from the journey's own report (`tools/core_journey.gd`; the
table from its stage blocks):

| stage | length | only credits left | minutes with a decision | the row that came last | the crew: out / posted / at the Bay | sites an hour | salvage earned / spent | hauled | store at its limit |
|---|---|---|---|---|---|---|---|---|---|
| 1 -> 2 | 0:06:30 | 4% | 7 of 7 | research throughput_1 1 (0:06:15) | 1% / 0% / 99% of 1.0 | 0.0 | 0 / 0 | 0 | 9% |
| 2 -> 3 | 0:06:25 | 22% | 7 of 7 | research throughput_1 3 (0:04:50) | 83% / 0% / 17% of 1.0 | 74.8 | 8 / 6 | 0 | 38% |
| 3 -> 4 | 0:12:24 | 48% | 13 of 14 | stock Plate 800 (0:06:29) | 100% / 0% / 0% of 1.0 | 87.0 | 18 / 10 | 0 | 59% |
| 4 -> 5 | 0:10:59 | 33% | 12 of 12 | stock Plate 2500 (0:07:19) | 81% / 0% / 19% of 4.9 | 76.4 | 14 / 16 | 0 | 49% |
| 5 -> 6 | 1:01:45 | 0% | 62 of 63 | stable 60 (1:01:45) | 57% / 17% / 26% of 9.4 | 67.0 | 83 / 85 | 5356 | 84% |
| 6 -> 7 | 3:26:10 | 5% | 188 of 207 | stable 80 (3:15:35) | 35% / 27% / 38% of 11.0 | 65.2 | 284 / 229 | 42528 | 76% |
| 7 -> 8 | 1:39:29 | 20% | 92 of 100 | machine smelter 8 (1:19:09) | 31% / 35% / 34% of 12.0 | 71.2 | 153 / 114 | 21469 | 40% |
| 8 -> 9 | 3:32:22 | 16% | 190 of 214 | stock Alloy 100000 (2:58:39) | 33% / 35% / 31% of 12.0 | 61.3 | 276 / 352 | 63081 | 37% |
| 9 -> 10 | 2:15:49 | 9% | 125 of 136 | stock Frame 300000 (1:59:49) | 40% / 41% / 19% of 12.0 | 59.6 | 169 / 0 | 72122 | 19% |

What it says:

- **No stage is a wait with nothing to do.** Every stage from Core 5 has a
  decision in 90% or more of its minutes; sorties are 229 of the Core 6
  stage's 601 decisions. The crew is out on sorties a third of the time
  or more at every stage but the first, and from Core 6 a third of it is
  posted.
- **Credits alone are the last third of Cores 3 -> 5** (48%, 33% of the
  stage), with the crew's sorties the decisions of that wait; a quarter
  of an hour each.
- **The long stages are the eras' own work:** Core 6 -> 7 is 3 h 26 min,
  its last rows the Resonant Frames research (3 h 05) and stability 80
  (3 h 16); Core 8 -> 9 is 3 h 32 min, the last row 100,000 Alloy in the
  store.
- **Core 9 -> 10 took 2 h 16 min.** The four Assay Benches were at work
  after the first was moved beside the Core at 10 h 31 min; the Frames in
  the store were the last row. The Core 10 blocker of section 9 is gone.
- **Before Plates were fuel (run S)** the crew was out 2% of the Core 6
  era and cleared 1.9 sites an hour for 4 h 50 min; now 35% and 65 sites
  an hour, and the era took 3 h 26 min.

The same new game, salvage on Rig Plating first (run V; without this
round's last two scripted-player fixes; **Core 10 at 14 h 30 min**):

| stage | length | only credits left | minutes with a decision | the row that came last | the crew: out / posted / at the Bay | sites an hour | salvage earned / spent | hauled | store at its limit |
|---|---|---|---|---|---|---|---|---|---|
| 1 -> 2 | 0:06:30 | 4% | 7 of 7 | research throughput_1 1 (0:06:15) | 1% / 0% / 99% of 1.0 | 0.0 | 0 / 0 | 0 | 9% |
| 2 -> 3 | 0:06:30 | 23% | 8 of 8 | research throughput_1 3 (0:04:50) | 83% / 0% / 17% of 1.0 | 73.8 | 8 / 0 | 0 | 38% |
| 3 -> 4 | 0:12:59 | 48% | 13 of 13 | stock Plate 800 (0:06:44) | 100% / 0% / 0% of 1.0 | 87.7 | 19 / 0 | 0 | 60% |
| 4 -> 5 | 0:11:54 | 30% | 12 of 13 | stock Plate 2500 (0:08:19) | 70% / 0% / 30% of 4.9 | 85.6 | 17 / 10 | 0 | 46% |
| 5 -> 6 | 1:04:05 | 1% | 65 of 66 | stable 60 (1:02:50) | 72% / 6% / 22% of 9.6 | 115.2 | 147 / 42 | 1643 | 82% |
| 6 -> 7 | 3:09:55 | 3% | 180 of 190 | stable 80 (3:04:55) | 54% / 9% / 37% of 11.0 | 119.1 | 488 / 75 | 8316 | 49% |
| 7 -> 8 | 2:30:19 | 0% | 150 of 152 | doctrine 4 (2:30:14) | 34% / 32% / 34% of 12.0 | 75.4 | 232 / 41 | 48392 | 18% |
| 8 -> 9 | 2:23:29 | 22% | 132 of 144 | stock Alloy 100000 (1:47:29) | 31% / 46% / 23% of 13.0 | 59.4 | 177 / 479 | 30423 | 31% |
| 9 -> 10 | 4:44:44 | 0% | 273 of 286 | doctrine 9 (3:22:14) | 33% / 49% / 19% of 13.0 | 59.4 | 357 / 655 | 140324 | 5% |

- **The two ways reach Core 10 two hours apart** (12 h 32 min with Gearing,
  14 h 30 min with Plating), and they leave different crews: Plating first
  held 300 to 780 salvage unspent from the 3 h mark to the 11 h mark and
  put it into the Bay late; Gearing first never held more than 160 at an hourly mark.
- **Salvage on nothing (run X, `none`) did not get past Core 5 in 15 h**:
  the Core 6 row's 8,000 Ingots stood at 6,780. That is a scripted-player
  gap, not measured further.
- **What the bot measures is not what a player feels.** The scripted
  player tears down and lays again what a person would leave (hundreds of
  machines sold a stage); it never collapses, though a collapse at the
  start of Core 9 would have paid more than two hundred Cores; it plays
  every minute. Its hours are an upper bound on the systems' sense, not a
  forecast of a person's evening.

### Salvage: three sinks and a fourth

Salvage now pays for four things: the Rig Bay's levels, Salvaged Gearing,
Rig Plating, and (from Core 6) refitting a Rig as a Breaker. At one a
cleared site and two from the nest, the game that bought Gearing first
had earned 969 by the 12 h mark and never held more than 157 at an hourly mark
(run X) -- against a thousand and more unspent in every scenario of
section 9. No line can be bought to its end: ten levels of Gearing alone
cost about 1,100. The game that bought Plating first did hold salvage
(up to 780) and reached Core 10 two hours later: what salvage buys is a
choice with a price.

### The second kind of Rig: the Breaker (built)

| | a Rig | a Breaker |
|---|---|---|
| made | an Assembler on the Rig Frame job, from Plates | a Rig at the Bay refitted, 30 Components (growing with the Core) and 4 salvage, from Core 6 |
| rock (a drift's cave-in, a nest's shell; dealt from Core 6) | half its strength | 2.5 Rigs' |
| water (a flooded gallery) | whole | 1.0 Rig's (0.4 of its own) |
| a hall (the pump house) | whole | 2.5 Rigs' |
| the wear it brings home | the site's | the team's falls by half the share of strength its Breakers brought |
| fuel, repair | one | two |
| posted to a machine | yes | never: too heavy to haul |

- **The decision it makes.** Which Rigs to refit (a Breaker is a Rig not
  hauling and not cheap in water), and which team to send: the galleries'
  screen has a - and a + for each kind; the default is the fewest that
  clear the site, Breakers first on rock.
- **The reference games.** Boom Beach's Heavies and Tanks against
  defences, its Riflemen against the rest (**UYARLA**: two kinds, each
  good against one property of the target); Rise of Kingdoms' troop
  counters (**UYARLA**, one axis only); Clash of Clans' army composition
  (**UYARLA**: the team is chosen per target, not per battle-plan).
- **What it does not do yet.** No third kind, no losses, no attack on the
  factory: defence stays **ALMA** until something attacks (section 10).

### What it costs to draw

`tools/perf_probe.tscn` on this machine (Intel UHD, the compatibility
renderer, 1440x720, nothing else running), the round's first commit
(8eb9dbd) against this round's code, each in a checkout of its own with
no save:

| | before | after |
|---|---|---|
| idle, the default view | 7.05 ms median, 186 draw calls | 7.32 ms, 196 draw calls |
| the crew out | 8.07 ms, 188 | 7.80 ms, 197 |
| a 20 s soak | 8.15 ms, 206 | 7.79 ms, 212 |
| the late board, stratum 16, the whole yard in view | 21.4 ms, 229 | 20.7 ms, 232 |
| texture memory | 36.0 MB | 40.7 MB |

Ten more draw calls for the side menu's words and pictures, the land and
the Foreman on the board; 4.7 MB more for the Core's stage, the land (now
VRAM-compressed: 682 KB, not 5.5 MB) and the menu's pictures. A phone:
not measured.

## 12. The deep map: why a player goes on after Core 10 (28 September 2026)

The owner's brief for this round: Core 10 must not read as the end. What
comes after it is to open a new region, a new chain, a new kind of robot,
a new kind of sortie, a new resource, new research, a new danger and a
new decision, and each Core after it is to ask for at least five kinds of
work (economy, production, research, the crew, the world) -- not the same
rows with bigger numbers. Not Core 11 as a goal: one playable slice that
proves the loop, measured.

### Measured first

- **Core 10 -> 11 was the same rows with bigger numbers.** The formula
  past the table (`PROGRESSION.md`, "Core 10") asked for credits 1.5
  times, the store 1.6 times, two more Assay Benches, one more Overdrive
  step, one more doctrine level, stability +20 and the next five strata:
  every row a row Core 10 had already asked.
- **Core 10 opened one thing:** the Core's export. No region, resource,
  kind of robot, kind of sortie or research line came with it.
- **The crew at Core 10:** two kinds (the Rig and, from Core 6, the
  Breaker); three gallery slots dealt from the same table since Core 6.
- **The map:** the shaft's four bands, top to bottom. Nothing on it to
  choose or to open.

### What was built: one vertical slice

| the brief asked for | built | where |
|---|---|---|
| a new region | **the deep map**: three regions past the galleries -- the Sunken Works (water), the Resonite Caverns (rock), the Rogue Foundry (danger). Core 10 has room for one, Core 11 for two, Core 12 for all three | `Operations.REGIONS`, `region_slots` |
| a new kind of sortie | **the expedition**: a survey site in the region's mouth. Only a team with a Surveyor may go; it needs the region's own strength, the same at every Core (303 in the Sunken Works, 393 in the Caverns, 484 in the Foundry), is out 150 s, burns three times the fuel, and from the second region costs 200 Lenses for each region already open. It opens the region for good | `Operations.survey_site`, `Sim.send_expedition` |
| a new kind of robot | **the Surveyor**: a Rig refitted at the Bay from Core 10, for 60 Frames (growing with the Core) and 6 salvage. It alone leads an expedition (2 Rigs' strength there); each finds a quarter more Resonite (to double); a team of Surveyors alone is back sooner. On a site it does 0.8 of a Rig (half that on rock), and in danger it wears twice as fast. It is not posted | `Operations` "the Surveyor", `Sim.refit_rig` |
| a new resource | **Resonite**: only the regions' sites bring it home | `MachineDB.Res.RESONITE` |
| a new production chain | **the Lens**: an Assembler on its new job, the Lens Grinder, grinds 2 Resonite onto a Frame. Nothing on the board makes Resonite, so a Lens Grinder is fed from the store: beside the Core, with a Rig posted to it | `MachineDB` job "lens", `Res.LENS` |
| a new danger | **forges that fight back**: in the Foundry a team with no Breaker to lead it takes half the pay; Surveyors wear twice as fast there | `Operations.dangerous`, `Sim._send` |
| new research | **one line a region**, sealed until the region is open: Brine Coils (cooling +10% a level), Resonite Sounding (Resonite +25% a level), Reclaimed Hammers (a Breaker's strength +15% a level); 400K research, twice a level, four levels | `Economy`, branch "frontier" |
| a gift to the factory | each region, for good once open: the Sunken Works' brine cools every Coolant Cell and Condenser a quarter harder, and its Stranded Rigs, brought home, are room for one more Rig each (to three) and a mended crew; the Caverns pay half again every site's Resonite; the Foundry pays twice every cleared site's salvage | `Sim._recompute`, `Sim._sortie_home` |
| a new map target | the regions' mouths on the board, boarded until opened; the map's region cards with their ground, gift, research and state; a sealed mouth tapped opens the map, an open one the galleries | `IsoView.region_pos`, `Main._regions_box` |
| a reward that is seen | "A region opened!": the region's picture, its gift, its research, and what its Resonite is for, with the Foreman | `Main._on_region_opened` |

What now? from Core 10: a Surveyor refit while none is in the crew, then
an expedition into the next sealed region, right after the Core's own
rows (`Worklist._deep_map`).

### Core 11: five kinds of row

| row | kind | what it asks the player to do |
|---|---|---|
| 75M credits | economy | the Core's price |
| 10,000 Lenses in the store | production | build the new chain: a Lens Grinder beside the Core, a posted Rig, and Resonite coming home |
| a region open, whichever | the world | send an expedition |
| 2 levels of the open regions' research, whichever | research | buy the line the chosen region opened |
| a crew of at least 2 Rigs, 2 Breakers and 2 Surveyors | the crew | refit, and keep all three kinds |

Past the table the formula grows each kind in its own way, not only its
number: one more region a level while the map has one (Core 12 asks for
two, Core 13 for three), two more levels of the regions' research, one
more of each kind of crew (to four), and the rows of before
(`CoreLevels`; `test_deep.gd`, `test_regions.gd`).

### The loop after Core 10

The Core asks for Lenses. A Lens is ground from a Frame and Resonite.
Resonite comes only from a region's sites, and a region opens only to an
expedition led by a Surveyor, who is a Rig refitted for Frames. The
region's sites need the team their ground asks for: Rigs in water,
Breakers on rock and to lead into danger, Surveyors for more Resonite.
What comes home goes to the store; a Rig posted beside the Core feeds the
Lens Grinder from it; the Lenses fill the Core's row -- and are the price
of the next region's expedition. The region's research line opens with
it and strengthens the path chosen, and its gift changes the factory
(cooling, crew room, Resonite or salvage). Credits alone do not move any
of it.

### The decisions it adds

| decision | the choices | what changes |
|---|---|---|
| which region first | water, rock or danger | measured below: the Caverns fill the Lens row in 24 min, the Foundry in 36, the Sunken Works in two hours -- but the Works bring three Rigs home and cool the factory, and the Foundry doubles salvage (395 earned in the stage, against 65) |
| which Rigs to refit | a Rig hauls, is posted, goes out; a Breaker opens rock and leads into danger; a Surveyor opens regions and finds Resonite | every refit is a Rig less to post beside the Core, where the Lens Grinder needs one |
| the team for each site | Rigs, Breakers and Surveyors, each with a - and a + | on rock a Rig does half; in water a Breaker less than one Rig; in danger no Breaker is half the pay; Surveyors, more Resonite and faster home, but fragile |
| where the Frames go | the Core's store, the Assay Benches (research), Lenses, refits | a Surveyor costs 60 Frames; each Lens one |
| where the Lenses go | the Core's row or the next expedition | the second region costs 200, the third 400 |
| which research | only the open regions' lines | the path follows the map |

### Played

From the same Core 10 save of a new game (Core 10 at 12 h 31 min 57 s),
the scripted player took each region first
(`LODEWORKS_CORE_REGION=caverns|sunken|foundry`):

| | the Caverns first | the Sunken Works first | the Foundry first |
|---|---|---|---|
| Core 10 -> 11 | **0:54:19** | **1:58:24** | **1:26:04** |
| a region open | 0:03:19 | 0:03:19 | 0:04:19 |
| a crew of 2, 2 and 2 | 0:00:04 | 0:00:04 | 0:00:04 |
| 10,000 Lenses | 0:23:34 | 1:58:24 (last) | 0:36:29 |
| 75M credits | 0:39:54 | 0:53:39 | 0:40:19 |
| 2 levels of the region's research | 0:54:14 (last) | 1:04:24 | 1:15:39 (last) |
| only credits left | 0% | 0% | 12% |
| minutes with a decision | 54 of 56 | 118 of 120 | 85 of 88 |
| the crew: out / posted / at the Bay | 44% / 31% / 25% | 53% / 28% / 19% | 38% / 24% / 38% |
| sites an hour | 69.6 | 47.1 | 70.4 |
| salvage earned | 65 | 102 | 395 |
| Rigs rescued | 0 | 3 | 0 |

- **The three regions play differently.** Rock (with the Caverns' half
  again) is the fast way to Lenses; water is slow for Resonite but grows
  the crew and cools the factory; danger's way in is the hardest (the
  scripted player refitted a fourth Surveyor for it and bought Rig
  Plating) and doubles salvage. A player who wants salvage, crew or speed
  has a reason for each.
- **No stage of it is a wait.** Credits were the only row left for 0%,
  0% and 12% of the three stages, and a decision was taken in 96% or more
  of their minutes.
- **The first design was trivial and was changed:** at 0.4 Resonite for
  each point of a site's strength, 500 Lenses and research at 150K, the
  Caverns crew brought home 28,000 Resonite in 35 minutes and Core 11 fell
  in 38. Resonite is now 0.15 a point, the row 10,000 Lenses, the research
  400K; a region site is dealt from the lower tier only.
- **Two gaps of the scripted player were found and fixed on the way:** it
  sent every Rig on sorties and none was left to post to the Lens Grinder
  (now a Core row waiting on a post is served first), and it never sent an
  expedition while every Rig at home was posted (now it recalls one).

**From a new game (run W, the final code), Core 1 -> 12 in 17 h 21 min:**

| stage | length | the row that came last | only credits left | minutes with a decision |
|---|---|---|---|---|
| Cores 1 -> 10 | 12:31:57 | as in section 11 (run X), to the second | -- | -- |
| 10 -> 11 | 0:54:04 | 2 levels of the region's research (0:53:59) | 0% | 52 of 56 |
| 11 -> 12 | 3:54:34 | 4 levels of the regions' research (3:54:29) | 0% | 233 of 235 |

- **Cores 1 -> 10 did not move.** The scripted player's play before the
  deep map is kept as it was measured (its hourly marks match run X's to
  the credit): what this round adds starts at Core 10.
- **Core 11 -> 12:** the second region (the Foundry: the whole crew, six
  of them Breakers, matched its survey best) was open after 3 minutes,
  16,000 Lenses were in the store from the start, the credits after 30
  minutes, and the regions' research came last: 1.21M research made in
  the stage, all of it spent on those four levels. The store held 604,000
  Frames by the end and four of eight Assay Benches stood starved: a
  player who feeds them turns Frames into that research; the scripted
  player does not.
- **The crew grew from 12 to 16** once a Rig Frame was tried again on the
  hot rock of stratum 27, and cleared 287 sites in the stage (73 an hour).

**Three gaps of the scripted player, and one of the game, found on the way
to Core 12:**

| cause | whose | the change |
|---|---|---|
| A Rig Frame that overheated once kept any other off the board for the whole Core: at Core 11 the crew stood at 12 of 16 | the player | from Core 10 another is tried an hour later |
| With an expedition too weak, the crew kept going on sorties, so it was never home together | the player | the posts are held, and the sorties too when the whole crew would be strong enough; when it would not, a Rig at home is refitted as a Surveyor |
| The second region was chosen by the map's order, not by the crew | the player | the one the whole crew matches best |
| The survey grew with the Core (1.35 times a level): the Sunken Works' was 409 at Core 11 against a whole crew of 330 in water, and Core 12 was never reached | **the game** | a region's way in is its own and does not grow; what grows is its price in Lenses |

### What it still is not

- **Three regions, fixed.** No fog, no region generated per shaft, no
  region that grows (levels, a boss, a chain of sites). The Core 12 and 13
  rows ask for the second and third region; after that the map is spent.
- **No art of its own.** The Surveyor is the Rig's sheet in sea-glass
  paint at 0.85 scale, as the Breaker is the Rig's in rust-red; the
  regions' mouths are the galleries' pictures tinted. The Higgsfield
  connector was not connected this round, so no picture was generated.
- **Resonite has one use** (Lenses) and the Lens two (the Core's row, an
  expedition): by Core 12 the store held 191,000 Lenses against a row of
  16,000. A second sink (a machine, an Overdrive tier) is the obvious
  next step.
- **Core 11 -> 12 is held by research** (the regions' lines, 400K and
  twice as much a level) while Frames pile up for Assay Benches the
  scripted player leaves starved.

### What it costs to draw

`tools/perf_probe.tscn` (1440x720, Intel UHD, the compatibility
renderer), the round's first commit (a57152a) against this round's code,
in the same checkout one after the other:

| | before | after |
|---|---|---|
| draw calls: idle / a 20 s soak / the late board | 196 / 212 / 232 | 196 / 211 / 232 |
| texture memory | 38.8 MB | 38.8 MB |
| static memory over the soak | 52.5 MB | 53.1 MB |
| a sim tick, the reference board | 0.376 ms | 0.384-0.387 ms |

Frame times were not comparable this time: other sessions were running
on the machine, and the same code's idle p50 read 8.5 and 10.3 ms on two
runs. A phone: not measured (no device connected).
- **The bot is not a player** (section 11): its hours are an upper bound
  on the systems' sense. Human pace and anything on a phone: not measured.

## 13. Beacons: the Lens's second use, and the map past Core 12 (29 September 2026)

The owner's brief for this round: give the Lens a second, real use that
is a decision rather than a bonus; keep the map from running out at Core
12; make each region progress on its own (explored, held, its work);
make the crew's roles depend on the ground, the danger, the purpose and
the reward, so "send the strongest" stops being the answer; keep the
factory and the galleries competing for the same crew and materials; and
measure Cores 10 -> 13 against the round before.

### Measured first

- **The Lens was ground far past its use.** From a Core 11 save, one
  Lens Grinder, posted and fed, ground 23,464 Lenses in thirty minutes
  from 3,784 Resonite brought home: the factory's yield multiplies every
  output, a Lens too. The rows asked for 10,000 (Core 11) and 16,000
  (Core 12); a new game held 191,000 at Core 12 and 175,000 at Core 13.
- **Its only uses were one-offs:** the Core's row and 200 Lenses for
  each region already open, at an expedition.
- **The map was three regions**, each opened once and then only a board
  slot; Core 12's formula asked for the third, and after it nothing new.
- **Core 12 -> 13 under the formula** (from the new game's Core 11 save):
  1:21:09, "placed 2" machines in the stage -- the factory did not change
  -- and the rows the formula grew: credits, 25,601 Lenses (met at the
  start), a third region, two more research levels, a fourth of each
  crew.

### What was built: one vertical slice

| the brief asked for | built | where |
|---|---|---|
| the Lens's second use | **the Beacon** (Core 11): a lamp lit on an open region's high ground holds it. It costs 2,000 Lenses for each Beacon already lit and the first, one Surveyor who stays to keep it, and **1,500 Lenses an hour** from the store; with none, every Beacon goes dark and what they give stops until there are Lenses again. A Rig posted to a Grinder or a Cutter leaves the next hour of it in the store | `Operations` "Beacons", `Sim.send_beacon`, `Sim._upkeep`, `Sim.haul_floor` |
| a factory use as well | **the Prism Cutter** (Core 12): an Assembler job that cuts one Umbrite with two Lenses; Core 13 asks for 2,000 Prisms | `MachineDB` job "prism" |
| a Lens that is worth something | **the deep map's makers are crafted**: the factory's yield (15.3 on stratum 27) no longer multiplies a Lens, a Prism or the Resonant Bore's Resonite, so the Lenses a shaft has are the Resonite its crew and its Bores bring; a Lens and a Prism are no Dispatch good | `MachineDB` "crafted" |
| region progress, explored -> held -> its work | a held region's sites pay half again and are dealt from every tier, its research line goes two levels further, and it gives **its own work**: the Sunken Works' brine mains (cooling half again, not a quarter), the Caverns' **Resonant Bore** (a Drill job that makes Resonite on the board, at a tenth of a Drill's pace: about 1,500 an hour on stratum 27), the Foundry's reclaimed forges (three times a site's salvage, not two), the Dark Reach's lit paths (no Lenses for light) | `Operations.CONTROL_TECH`, `Sim.controlled` |
| a new region past Core 12 | **the Dark Reach** (Core 12, once two Beacons burn): new ground (dark), a new resource (**Umbrite**), a new danger (a team with no Surveyor to guide it is lost: half its strength; Shade Nests are danger and dark at once), a new crew need (a Surveyor to guide; Lenses for light, 3 a head a sortie, until a Beacon burns there); it takes none of the Core's room, new research (Umbral Lamps), a new factory result (the Prism Cutter, beside the Core, running cold on hot rock) | `Operations` "the Dark Reach" |
| roles by purpose, not strength | see the table below | `Operations.team_factor` |
| the factory against the galleries for the crew | **tuning**: a Surveyor from the Bay tunes a Lens Grinder or Prism Cutter to half its Resonite or Lenses -- and is then no keeper, no guide and no expedition leader | `Sim.tune` |
| the Lenses measured | a ledger by use: the Core, expeditions, Beacons, upkeep, light, the factory, contracts | `Sim.lens_spent` |

### Roles by what the team is for

| purpose | ground | Rig | Breaker | Surveyor |
|---|---|---|---|---|
| a site | open | 1 | 2.5 | 0.8 |
| | rock | 0.5 | 2.5 | 0.4 |
| | water | 1 | 1 (0.4 of its own) | 0.8 |
| | danger | 1; no Breaker to lead: half the pay | 2.5 | 0.8, wears twice as fast |
| | **dark** | 1; no Surveyor to guide: the team at half | 1 | **1.5** |
| an expedition | any | 1 | as its ground | **2** (and one is needed) |
| **a Beacon** | any | 1 | **its ground's, half again** | as on a site; one stays |
| tuning | the factory | -- | -- | **halves** a Lens's Resonite or a Prism's Lenses |
| a harvest | Resonite, Umbrite | -- | -- | a quarter more each (to double) |

So a Beacon in the Sunken Works wants Breakers that water makes weak,
the Dark Reach wants the Surveyors a Beacon, an expedition and a tuned
Grinder also want, and the Caverns reward Breakers everywhere.

### Where a Lens goes now

| use | how much | what it buys |
|---|---|---|
| the Core's row | 4,000 at Core 11 | the next level |
| an expedition | 200 for each region open | a region |
| a Beacon, lit | 2,000, 4,000, 6,000 | a region held: its pay, its tiers, its research, its work |
| a Beacon, kept | 1,500 an hour each | the same, for as long as the store pays |
| light in the dark | 3 a head a sortie | a sortie into the Dark Reach, until a Beacon burns there |
| the Prism Cutter | 2 a cycle (1 tuned) | Prisms: Core 13's row, and a Vault's 500 credits each |

### Cores 12 and 13

| Core 12 (era: The Beacons) | kind | Core 13 (era: The Dark Reach) | kind |
|---|---|---|---|
| 113M credits | economy | 170M credits | economy |
| 2 Lens Grinders at working heat | production | 2,000 Prisms in the store | production |
| 2 regions open | the world | 3 regions open | the world |
| 1 Beacon burning | the world, the crew, the Lenses | 2 Beacons burning | the world, the crew, the Lenses |
| 4 levels of the regions' research | research | 6 levels (the held regions' lines go further) | research |
| a crew of 3 of each kind | the crew | 4 of each kind | the crew |

Past Core 13 the formula grows each kind: Core 14 asks for all four
regions and three Beacons.

### Played

From the same Core 10 save of a new game (Core 10 at 12 h 31 min 57 s),
the scripted player took each region first
(`LODEWORKS_CORE_REGION=caverns|sunken|foundry`, `LODEWORKS_CORE_SKIP=1`),
to Core 13:

| | the Caverns first | the Sunken Works first | the Foundry first |
|---|---|---|---|
| Core 10 -> 11 | **1:02:19** | **2:02:39** | **2:34:34** |
| the row that came last | credits (4,000 Lenses at 0:57:49) | 4,000 Lenses | 4,000 Lenses (2:21:54) |
| Core 11 -> 12 | **1:58:54** | **3:37:24** | **2:05:44** |
| the row that came last | the Beacon (1:58:49) | the regions' research (3:37:14) | the regions' research (2:05:19) |
| Core 12 -> 13 | **3:20:35** | **1:43:30** | **2:41:15** |
| 2,000 Prisms | 2:06:19 | 1:35:35 | 1:14:34 |
| the row that came last | credits | the regions' research (1:43:25) | the regions' research (2:41:10) |
| Core 13 at | **18:53:47** | **19:55:32** | **19:53:32** |
| only credits left, the three stages | 7%, 0%, 37% | 0%, 0%, 0% | 8%, 0%, 0% |
| minutes with a decision, the three stages | 62 of 64, 117 of 120, 146 of 201 | 122 of 124, 213 of 219, 101 of 104 | 148 of 156, 125 of 127, 157 of 162 |

**From a new game, the same code** (no save; `LODEWORKS_CORE_SKIP=1`):

| stage | length | the row that came last | only credits left | minutes with a decision |
|---|---|---|---|---|
| Cores 1 -> 10 | 12:35:02 | as in section 11, to Core 9 (10:16:07) to the second | -- | -- |
| 10 -> 11 | 1:42:24 | 4,000 Lenses | 0% | 101 of 103 |
| 11 -> 12 | 1:50:44 | the regions' research (1:50:24) | 0% | 107 of 112 |
| 12 -> 13 | 2:57:50 | credits (2,000 Prisms at 2:11:34) | 26% | 149 of 179 |

Core 13 at **19:06:02**. The round before, the same new game reached Core
11 at 13:26:02 and Core 12 at 17:20:37, and Core 12 -> 13 under the
formula took 1:21:09 from its Core 11 save with two machines placed. Core
9 -> 10 took 3 min 5 s longer than run X's (12:31:57), not traced: two of
this round's changes run before Core 10 (a retasked machine drops what its
new job does not make; Dispatch no longer offers what only a region or a
Beacon makes). The hour mark at 1:00 is run X's, 6.63K/s.

**The Lenses, Core 10 -> 13** (the ledger `Sim.lens_spent`):

| | the Caverns first | the Sunken Works first | the Foundry first |
|---|---|---|---|
| ground | 28,200 | 33,000 | 35,400 |
| the Core's row | 4,000 (16%) | 4,000 (13%) | 4,000 (12%) |
| expeditions | 1,200 (5%) | 1,200 (4%) | 1,200 (4%) |
| Beacons lit | 6,000 (24%) | 6,000 (20%) | 6,000 (19%) |
| Beacons kept | 6,600 (26%) | 9,550 (32%) | 10,600 (33%) |
| light in the dark | 1,720 (7%) | 1,820 (6%) | 2,680 (8%) |
| the Prism Cutter | 5,700 (23%) | 7,400 (25%) | 7,830 (24%) |
| in the store at Core 13 | 3,000 | 2,990 | 3,070 |

The round before, a new game held 191,000 Lenses at Core 12 and 175,000 at
Core 13, against rows of 16,000 and 25,601. Now none of the six uses takes
more than a third, and the store ends each of these runs at the Beacons'
next hour, the floor a posted Rig leaves (the new game: 13,800).

**The crew on the deep map, from Core 10** (teams as Rigs/Breakers/
Surveyors, the most used first; minutes out by region):

| | the Caverns first | the Sunken Works first | the Foundry first |
|---|---|---|---|
| rock (veins, forges) | 0/4/0, 0/5/0, 0/6/0 | 0/5/0, 0/1/0 | 0/3/0, 0/4/0, 0/5/0 |
| water (cisterns, Stranded Rigs) | 0/6/1 (4 sorties) | 0/5/3, 0/2/3, 4/5/2 | 0/6/3, 0/6/2 |
| the dark (hollows, Shade Nests) | 0/6/2, 0/0/1, 0/5/1 | 2/5/3, 0/4/3, 0/4/2 | 0/6/3, 0/5/1, 0/6/2 |
| a Beacon | 0/5/1, 0/6/1 | 3/5/1 | 0/4/1 |
| minutes out: the first region, the Reach, the other two | 177, 81, 48 | 281, 65, 42 | 182, 115, 50 |

- **"Send the strongest" is not what the teams are.** On rock the team is
  Breakers alone; in water Surveyors go with them, and in the Sunken Works
  Rigs too (water halves a Breaker); in the dark a Surveyor always goes, or
  the team is at half; a Beacon's team is Breakers and its keeper. The
  Rigs, meanwhile, are at the posts: 29-50% of them posted in every stage.
- **The first region decides the run.** The Caverns first: the Lenses come
  easily (1:02 to Core 11), but the Beacon, not the Lenses, holds Core 12.
  The Sunken Works first: Lenses are slow, and the regions' research holds
  Core 12 for three and a half hours (the Assay Benches stood starved; see
  "What it still is not"). The Foundry first: salvage, and the research
  last again.
- **Where it is a wait:** only in the Caverns' Core 12 -> 13, 37% credits
  alone (the scripted player bought 181M of machine levels in the stage),
  and from the new game, Core 12 -> 13, 26%; elsewhere 0-8%.

**Found on the way, and whose it was.** Each was measured, changed, and
the journeys run again from the same Core 10 save:

| cause | whose | the change |
|---|---|---|
| The factory's yield multiplied Lenses: one posted Grinder ground 23,464 in thirty minutes from 3,784 Resonite | **the game** | a Lens and a Prism are crafted |
| The same for the Resonant Bore: at a yield of 15.3, two Bores made about 180,000 Resonite an hour and the store held 151,000 Lenses at Core 12; crafted alone, still 30,000 an hour | **the game** | crafted, and a tenth of a Drill's pace |
| Once the Core 13 row's Prisms were cut, the Rig posted to the Cutter hauled on: 25,800 Lenses into Prisms, the store at 0, both Beacons dark | **the game** | a posted Rig leaves the Beacons' next hour of Lenses in the store |
| The Dark Reach needed a third slot of the Core's room, already taken: no Core 13 | **the game** | the Reach takes none of the Core's room |
| A Shade Nest of 441 against a team of 218 in the dark stood an hour on the board | **the game** | a dark site's strength is 0.6 of its tier's |
| A Beacon at half again a site's strength was out of a Core 11 crew's reach; the Sunken Works paid too little Resonite (0.15 a point) to keep one | **the game** | a Beacon at a site's strength; 0.5 Resonite a point, Umbrite 0.3 |
| A Drill retasked as a Resonant Bore kept 7 Ore it could not hand on, and stood jammed | **the game** | a new job drops what it does not make |
| Every side of the Core held: the Prism Cutter was never laid, Prisms at 0 for nine hours with 19,000 Umbrite in the store; later, seven Lens Grinders laid for the Core 11 row held seven sides | the player | a deep-map machine no row asks for makes way, and, for the first of its kind when nothing else can, one of a kind with more than two there (only deep-map machines: letting any machine go took the Frame line's Presses, and Lenses stood at 1,280 for five hours) |
| With the Lens rows short, the crew cleared cisterns and galleries while the Prisms stood at 1,280 for two hours | the player | sites that pay Resonite first while a Lens row waits on it |
| Once the Core 12 row's Grinders were met, every dock went to the Prism Cutter and the Assay Benches: with 32,000 Resonite in the store the Lenses fell to 0 and both Beacons went dark | the player | while a Beacon burns, its Grinders are posted as a row's are, and a store short of an hour's upkeep sends the crew for Resonite |
| Then every dock stood at a Grinder with no Resonite to haul, and the Prism Cutter, with 7,850 Lenses and 12,000 Umbrite in the store, got no Rig | the player | a Rig posted where the store has nothing to haul is called over to a row's machine |
| 1,300 Lenses an hour went on light in the dark with 15,000 Umbrite in the store; the Beacons took the rest, and the Prisms stood at 1,704 for an hour | the player | no light burnt while the Beacons' hour is short and the store holds the Umbrite the Prisms want; the Surveyors kept as guides tune the Grinders instead |
| A held Foundry's third research level (the dearest) was saved for while the Caverns' first waited | the player | the cheapest level of the regions' lines first |
| Posts and sorties held for a Beacon no crew could reach; Surveyors refitted for roles they are weak in; four Surveyors tuning and none left to guide in the dark | the player | holds only when the whole crew is strong enough; Breakers for a Beacon's ground; two tuners at most and two guides kept |
| Assay Benches beside the Core starved while Rigs fed Lens Grinders, and the research rows took three hours, not one | the player | a research row's Assay Benches are row machines for the posts |

### What it still is not

- **The research the factory makes still holds the Sunken Works' and the
  Foundry's runs.** In four of the nine stages the regions' research came
  last, and in those runs the Assay Benches beside the Core stood at 0 of
  4 working for most of the hours: the scripted player feeds the Lens
  Grinders and the Prism Cutter first. A player who feeds the Benches turns
  the Frames in the store (50,000-280,000 at the hourly marks) into that
  research.
- **The Lens is tight now, perhaps too tight for a person.** Every run ends
  Core 13 with the Beacons' next hour in the store and no more; the
  Beacons' upkeep is the largest use. Whether that reads as a decision or
  a squeeze is for a playtest; the knobs are `BEACON_UPKEEP`, the Resonant
  Bore's rate and `RESONITE_PER_NEED`.
- **The scripted player needed the changes in the table above to get
  here**; each is a rule a player follows without thinking. Its hours are
  an upper bound, and the order it does things in is one of many.
- **The regions still have no art of their own**; a Beacon is a light
  drawn over the region's mouth and the Dark Reach's mouth is the
  galleries' tinted. The Breaker and the Surveyor now have sheets of
  their own.
- **The Dark Reach is one region**; after Core 14 the formula asks for
  more of the same kinds.

### What it costs to draw

`tools/perf_probe.tscn` (1440x720, Intel UHD, the compatibility
renderer), the round's base (2ebb397) against this round's code, in two
checkouts one after the other:

| | 2ebb397 | now |
|---|---|---|
| draw calls: idle / a 20 s soak / the late board | 195 / 212 / 232 | 195 / 212 / 232 |
| texture memory | 37.3 MB | 37.3 MB |
| static memory over the soak | 52.7 MB | 53.2 MB |
| a sim tick on the late board (308 machines), headless, the best of 11 runs each, alternating | 1.81 ms | 1.85 ms |

Frame times, and single tick readings, were noise this time: other
sessions loaded the machine, and the same code's late-board tick read
anywhere from 1.8 to 9.3 ms; with the order of the checkouts reversed,
neither was consistently faster. `tests/test_performance.gd` passes
(8 of 8). A phone: not measured (no device connected).

## 14. The Works: research as a line of the factory (29-30 September 2026)

The owner's brief for this round: make the Frame -> Assay Bench ->
research chain a decision the player can see and steer, not a list the
bot buys from; tie research to the factory, the crew, the sorties and the
regions; give it a tree with prerequisites and alternatives; let Cores 14
and up ask for several systems at once; and measure Cores 10 -> 15.

### Measured first

The round's base (2b68221), a new game, the scripted player with the
round's instruments only (`LODEWORKS_CORE_SKIP=1`, to 34 hours):

| stage | length | Assay Benches at work | waiting on research alone | only credits left | Frames made / taught to research / to contracts | minutes with a decision |
|---|---|---|---|---|---|---|
| 10 -> 11 | 1:42:24 | 42% of their time | 0 | 0% | 360K / 44.6K / 0 | 101 of 103 |
| 11 -> 12 | 1:50:44 | 36% | 0:28:50 (26%) | 0% | 387K / 35.9K / 265K | 107 of 112 |
| 12 -> 13 | 2:57:50 | 8% | 0 | 26% | 552K / 7.0K / 360K | 149 of 179 |
| 13 -> 14 | **not reached in 14:54** | **0%** | 2:11:30 | 0% | 3.29M / 0 / 935K | 111 of 895 |

- **The research the Frames made stopped at Core 13.** Past it the Assay
  Benches learnt from no Frame at all while 3.29 million were made and
  935,000 went to contracts; the Frames sold at the Vaults the Frame line
  ended in, and none reached the Benches.
- **Core 14 was never reached.** The formula's rows (the regions'
  research, three Beacons) were each met once, never together: the
  Beacons went dark at 22:00 with the store's Resonite at 0 and stayed
  dark to the end, twelve hours; the regions' eighth level came 9:38 into
  the stage.
- **Research was bought, not chosen**: the scripted player bought what the
  rows asked for the moment it could; nothing else asked for research.

### What was built

| the brief asked for | built | where |
|---|---|---|
| a Frame's opportunity cost, visible | the research screen, from Core 10, opens with **what a Frame is worth each way** -- its price at a Vault against the research it teaches an Assay Bench on this rock with this research -- the Frames an hour made, taught and ground into Lenses, the research an hour and the plan with its time; and, when the store's Frames are falling, **when they run out** | `main.gd` `_research_budget`, `Sim.frame_rates`, `Sim.frames_left`, `Sim.frame_sale_value`, `Sim.frame_research_value` |
| research as a plan, not a purchase list | **the plan**: a line's "?" sheet plans it; its next level is bought the moment research and Frames pay for it, then the plan is done and the next is the player's choice again. What now? asks for one while a research row is open and none is planned | `Sim.research_plan`, `Sim.plan_research`, `Sim._follow_plan`, `Worklist` "plan" |
| a tree with prerequisites | every line can open behind another line's level, Beacons burning, or machines at work ("requires"); a card that still needs one says what; `Economy.tree_problems` catches a line that needs itself, one that is not there, a level it does not have, one that opens later | `Economy`, `Sim.research_needs`, `Sim.research_blocker` |
| alternatives, one resource | **the Works**: six lines paid in research **and Frames from the store**, in two ways -- the factory's (Assay Racks: a Frame teaches more; Jig Lines: Frame Jigs faster; Store Chutes: Benches beside the Core draw Frames with no Rig) and the crew's (Hauling Harness: posted Rigs carry more; Bay Wing: two more docks; Survey Instruments: Surveyors stronger, behind a Beacon). The same Frames and research buy one or the other first | `Economy.WORKS` |
| research tied to the factory, the robots, the sorties, the regions | the factory's lines feed the research that buys them (more research a Frame, more Frames, no dock needed); the crew's move more of the store to the machines and make the Surveyors that hold regions stronger; the regions' own lines stay | the Works; `Operations.team_factor` (Surveyor power) |
| Cores 14 and up: several systems at once | **Core 14, The Works**: 255M, six Assay Benches at work, three levels of the Works (whichever), all four regions, eight levels of their research, three Beacons. **Core 15, The Deep Works**: 380M, eight Benches, six levels of the Works, ten of the regions', four Beacons, stability 150. Past it the formula grows each | `CoreLevels` |
| the Frames measured | a ledger by use -- the Core, the Works, refits, contracts, research (hauled or chuted), Lenses, other machines -- and the Frames made and learned from | `Sim.frame_spent`, `Simulation.made`, `Simulation.learned` |
| the store's Frames kept for what burns them | while Beacons burn, research leaves an hour of their Frames; a posted Rig leaves the next Beacon's price and hour of Lenses while the Core asks for one | `Sim.research_floor`, `Sim.haul_floor` |

### Played

A new game each way on the round's code, the scripted player choosing the
Works factory-first or crew-first (`LODEWORKS_CORE_TECH=factory|crew`,
`LODEWORKS_CORE_SKIP=1`), to Core 15 or 34 hours. Core 1 -> 10 is the
base's to the second (Core 10 at 12:35:02 in all three).

| stage | the base (2b68221) | the Works, crew first | the Works, factory first |
|---|---|---|---|
| Core 10 -> 11 | 1:42:24 | 1:31:19 | 1:31:19 |
| 11 -> 12 | 1:50:44 | 1:43:24 | 1:43:24 |
| 12 -> 13 | 2:57:50 | 2:00:49 | 2:22:14 |
| 13 -> 14 | **not in 14:54** | 2:24:50 | 1:34:20 |
| 14 -> 15 | -- | 2:56:30 | 2:33:50 |
| Core 13, 14, 15 at | 19:06:02, --, -- | 17:50:37, 20:15:27, **23:11:57** | 18:12:02, 19:46:22, **22:20:12** |
| the row that came last, 13 -> 14 | the Beacons (dark from 22:00) | the regions' research (2:24:45) | credits (1:34:20) |
| the row that came last, 14 -> 15 | -- | credits (2:55:35) | credits (2:33:25) |

Each stage, crew first / factory first (the base's in brackets):

| stage | only credits left | waiting on research alone | Assay Benches at work | minutes with a decision |
|---|---|---|---|---|
| 10 -> 11 | 4% / 4% (0%) | 29% / 29% (0%) | 41% / 41% (42%) | 90 of 92 / 90 of 92 (101 of 103) |
| 11 -> 12 | 5% / 4% (0%) | 0% / 0% (26%) | 46% / 46% (36%) | 101 of 104 / 101 of 104 (107 of 112) |
| 12 -> 13 | 5% / 0% (26%) | 29% / 0% (0%) | 23% / 34% (8%) | 119 of 122 / 140 of 144 (149 of 179) |
| 13 -> 14 | 0% / 31% (0%) | 9% / 15% (15%) | 40% / 76% (**0%**) | 144 of 146 / 88 of 95 (111 of 895) |
| 14 -> 15 | 2% / 1% | 1% / 0% | 96% / 89% | 166 of 177 / 143 of 155 |

**The Frames, each stage** (made; taught to research; what went out of the
store to the Works, contracts and Lens Grinders):

| stage | crew first | factory first | the base |
|---|---|---|---|
| 11 -> 12 | 362K; 51K; Works 15K, contracts 265K, Lenses 8K | 362K; 51K; Works 15K, contracts 265K, Lenses 7K | 387K; 36K; contracts 265K |
| 12 -> 13 | 439K; 24K; Works 30K, contracts 360K, Lenses 26K | 524K; 44K; Works 90K, contracts 360K, Lenses 21K | 552K; 7K; contracts 360K |
| 13 -> 14 | 561K; 66K; Works 180K, Lenses 20K | 416K; 69K; Works 135K, Lenses 24K | 3.29M; **0**; contracts 935K |
| 14 -> 15 | 881K; 209K; Works 270K, Lenses 30K | 651K; 157K; Works 345K, Lenses 24K | -- |

**The Works each way bought** (the plan's reasons, from the player's log).
Crew first: Hauling Harness 1 and 2 at Cores 11 and 12 ("capacity, crew
first"); at Core 13, with no Rig to post to the Benches the Core 14 row
asked for, Assay Racks 1-2 and Store Chutes 1-2; at Core 14 Hauling
Harness 3-4 and the Bay Wing 1-2 -- ten levels. Factory first: Assay Racks
1 and 2 at Cores 11 and 12, Assay Racks 3 and Store Chutes 1-2 at Core 13,
Hauling Harness 1, Assay Racks 4, Store Chutes 3 and Jig Lines 1 at Core
14 -- nine. Of the plans, ten of twenty-two (crew) and eleven of
twenty-one (factory) were for the regions' research the rows asked for,
six and four for the Benches, the rest for the Works' own way.

- **Core 14 and Core 15 are reached both ways**, where the base never
  reached Core 14: crew first at 20:15:27 and 23:11:57, factory first at
  19:46:22 and 22:20:12 -- Core 10 -> 15 in 10 h 37 min and 9 h 45 min.
- **The Benches work.** From Core 13 they were at work 0% of the time on
  the base; now 40% then 96% crew first, 76% then 89% factory first, and
  the research they make goes to the Works and the regions' lines.
- **Waiting is mostly gone**: only credits left 0-5% of every stage crew
  first; factory first 0-4%, and 31% once (Core 13 -> 14, where every
  other row was met in 1:05). A decision in 93-99% of the minutes of
  every stage from Core 10 both ways, against 12% of the base's last.
- **The two ways differ, and meet**: crew first spends its early research
  on the Rigs, comes to the Benches only when the Core 14 row asks, is
  slower through Core 13 (2:25) and buys docks and Rigs that carry more
  at the end; factory first teaches the Benches more from Core 11 and is
  through Core 13 in 1:34, and needs Store Chutes to feed them. The Core's
  rows take either.

**Found on the way, and whose it was.** The Works' first version, played
from a new game and from the Core 10 save (Caverns first), collapsed at
Core 13 and at Core 14 in the same way: the store's Frames and Lenses at
0, every Beacon dark, the Benches idle, 2.7 million research banked and
unspent. Each cause was measured, changed, and played again:

| cause | whose | the change |
|---|---|---|
| A credit-only wait was fast-forwarded with the store as it stood: an hour of three Beacons' upkeep and of the Benches' Frames went unburnt, and the fall showed only after | the measurement | from Core 10 the skip carries the store's measured trend, and stops while a falling store still holds half (`core_journey.gd` `_skip`) |
| The Frame line ended at its Vaults: past Core 14, 759,000 Frames made and the store's 3,390 down to 0, the Lenses with them, three Beacons dark and nine Benches idle for eleven hours -- and nothing on screen said it was coming | the player, and **the game** | **the store's Frames running out within two hours is a line in What now? and a warning on the research screen** (`Sim.frames_left`, `Worklist` "frames"); the scripted player keeps two Frame Jigs beside the Core, a Rig feeding them from the store's Alloy and Components, while the store is short or falling |
| Nine Benches took every Frame while the Lenses fell | **the game** | while Beacons burn, research leaves an hour of their Frames in the store (`Sim.research_floor`) |
| Contracts took 265,000 and 360,000 Frames in the Core 11 and 12 eras | the player | contracts leave 60,000 |
| Store Chutes asked for four Benches at work, and the docks that could feed four were taken | **the game** | two |
| The plan went to the regions' research while the Core's Bench row waited on docks | the player | a Bench row no Rig can reach plans Store Chutes (factory first) or the Bay Wing (crew first) |
| The Prism Cutter took every Lens over the Beacons' hour (11,300 into Prisms, the row's 2,000 long cut), and its Grinders handed it theirs before the store saw them: the 6,000 a third Beacon costs never gathered | **the game**, and the player | a posted Rig leaves the next Beacon's price and first hour while the Core asks for one (`Sim.haul_floor`); the Cutter grinds Lenses once no row asks for Prisms |
| Two Resonant Bores made 3,400 Resonite an hour against the 4,500 Lenses three Beacons burn | the player | a Bore more while Resonite is short, up to six, beside a Grinder or a side of the Core |
| 1,700 Lenses an hour went on light for Umbrite no row wanted | the player | no light while the store is under what the Beacons want |
| **A dark Beacon stopped its Resonant Bore, and with it the Resonite that would relight it**: four Beacons dark for thirteen hours | **the game** | the Bore bores while its Beacon stands, lit or dark |
| The fourth Beacon was lit with its 8,000 and little more, and all four were dark within the hour; later every post was emptied for a Beacon the store could not pay for | the player | lit with its price and the next hour in the store; no crew gathered before |
| The Frames short, Lens Grinders were retasked to Frame Jigs, a Bore laid for Resonite was sold for a Frame Jig, and the Frame Jigs laid stood starved with every dock at a Grinder or a Bench the Chutes also fed | the player | the Beacons' Grinders and Bores kept like a row's machines; Frames wanted from Core 10; a Bench's Rig called over to another row's machine once the Chutes feed it |
| Frame Jigs laid beside the Core with their chains -- White Heat Smelters beside them -- on the hottest sides overheated, were sold for the stability row and laid again: factory first did not reach Core 15 in thirteen hours, with 600,000 Alloy and 230,000 Components in the store | the player | a Frame Jig beside the Core with no chain, on the coolest side to be had, a Rig feeding it from the store (then Core 15 at 22:20:12) |

The game's changes are five: the Frames' warning, the Benches leaving the
Beacons' Frames, Store Chutes behind two Benches, the next Beacon's
Lenses kept from the Rigs, and the Bore in the dark. The rest was the
scripted player not doing what the screen now asks.

### What it still is not

- **The scripted player needed every change in the table to get past Core
  13**; each is a rule a player follows from the screen, and the order it
  follows them in is one of many. Its hours are an upper bound.
- **The Frame line is the Core 14 era's work, and it is the scripted
  player's hardest.** Eight Benches and four Beacons take more Frames than
  the line grown for Core 10 makes; one Frame Jig beside the Core, fed by
  a Rig from the store's Alloy and Components, on a side cool enough for
  it, covers them. Laid anywhere else it overheats. What now? and the
  research screen say when the Frames will run out; whether a person finds
  the Jig's place from that is for a playtest.
- **The Lens economy is tight.** Four Beacons burn 6,000 Lenses an hour;
  a Bore makes about 1,700 Resonite an hour on stratum 27, two per Lens
  untuned. Held, it works (about 24,000-30,000 ground in each run's last
  stage, the store at 10,600-11,000 at the end), but whether four to six
  Bores and the Grinders tuned reads as a plan or a chore needs a person.
- **The Works are six lines.** The factory's way and the crew's way differ
  in what they buy (research a Frame, faster Jigs, no docks for the Benches
  -- or Rigs that carry more, more docks, stronger Surveyors), but the
  Core's rows count either; a row asking for one of each is a later round.
- **Research past the rows piles up**: the Works and the regions' lines
  are the only things it buys late, and the Benches the rows ask for make
  more than they cost.

### What it costs to draw

`tools/perf_probe.tscn` (1440x720, Intel UHD, the compatibility
renderer), the round's base (2b68221) against this round's code, in two
checkouts, three times each, the order swapped for the third (60 s soak):

| | 2b68221 | now |
|---|---|---|
| draw calls: idle / the soak / the late board | 195-196 / 212 / 232 | 195-196 / 212 / 232 |
| texture memory | 37.3-40.7 MB | 37.3-40.7 MB (the same run to run) |
| static memory over the soak | 53.5-54.6 MB | 53.9-54.9 MB |
| a sim tick on the late board (308 machines) | 3.48, 4.48, 2.93 ms | 3.03, 3.82, 3.16 ms |
| frame p50 over the soak | 9.96, 9.97, 10.78 ms | 10.82, 11.24, 9.61 ms |

The frame times follow the order the checkouts ran in, not the code: the
one run second was the slower each time, and swapped, the base was. No
new draw call, texture or node; the Frames' warning is one label on the
research screen. A phone: not measured (no device connected).
