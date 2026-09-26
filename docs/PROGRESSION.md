# Progression: the Factory Core's levels

The design source for Lodeworks' long-term progression. A feature that cannot
be connected to the graph below waits.

- Reference study: [`research/progression-reference.md`](research/progression-reference.md)
  (Clash of Clans, Boom Beach, Whiteout Survival and Rise of Kingdoms, with
  Township and State of Survival; official sources first).
- Code: `scripts/core/core_levels.gd` (the levels and the graph checker),
  `scripts/core/machine_db.gd` (machine levels, the store's capacity, the
  Lab), `scripts/core/economy.gd` (research opened and capped by the Core),
  `scripts/sim/sim.gd` (the store, paid upgrades, doctrines, the
  collapse's foundation, blueprints), `scripts/sim/worklist.gd` ("What
  now?"). Jobs -- a machine's second recipe -- are `MachineDB.JOBS`.
- Where the loop stands against the benchmark games: [`BENCHMARK.md`](BENCHMARK.md).
- Measured with `tools/core_journey.gd` (a scripted player on the real game);
  the numbers in this file come from the run named beside them.

Status, 26 September 2026: the vertical slice (sections 10 and 11) is built
and tested. Core levels 1-8 are measured with the scripted player; Core 7
was redesigned from a price into a stage (section "Core 7"), Cores 5 and 6
after it (section "Cores 5 and 6"), and the Core 7 era with the deep
chain, doctrines, the collapse's foundation and blueprints (section "After
Core 7"). Level 9 is designed and graph-checked, not yet played. The features that come next
are in [`research/feature-pool.md`](research/feature-pool.md).

---

## What the reference games do, in one page

Full tables and sources are in the reference study. What Lodeworks takes:

1. **One central level sets the ceiling for everything else.** The Town Hall,
   Headquarters, Furnace and City Hall each cap how far every other building
   may be upgraded.
2. **Hub caps sit under the tier cap.** For example, the Town Hall caps the
   Laboratory, and the Laboratory caps troop levels. This gives medium-length
   goals inside each tier.
3. **The next tier needs a checklist that finishes, not only a price.** The
   Town Hall asks for every building to be placed and the Hero Hall to be
   maxed. The Furnace and City Hall ask for one to three named buildings at
   level N-1, one of which recurs at every level.
4. **The next tier costs more than the storage you arrive with.** The storage
   upgrade then becomes a real prerequisite: Town Hall 5 costs 150,000 Gold,
   but Town Hall 4 storage holds 140,000.
5. **Resources are introduced in stages.** Dark Elixir arrives at Town Hall 7,
   Stone at Headquarters 7, Iron at Headquarters 10, Coal at Furnace 4. Each
   new tier adds a new kind of complexity, and old resources keep their use.
6. **Parallel queues keep the player busy while the main one waits.**
   Builders, a single research queue and training run side by side, so every
   visit is a choice of what to do first.
7. **"What now?" is answered in one tap.** Builder suggestions, idle-worker
   signs and green arrows all do this.
8. **Goals come at every cadence.** Players have a short task, a
   medium-length milestone, the next tier, and a permanent layer.
9. **Nothing invested is wasted.** Old buildings become inputs through merges
   and Supercharges, and surplus resources get a sink.
10. **Early tiers take minutes, later tiers take days.**

What Lodeworks does **not** take: timers as the gate (the game has no
timers, energy or gacha, by design), stealable resources, multiplayer and
paid speed-ups.

---

## 1. Final progression graph

```
                        ┌───────────────── the Factory Core, level L ─────────────────┐
                        │ caps: depth (strata), machine levels, research levels,       │
                        │       and through the Vault's level, the store               │
                        └──────────────────────────────────────────────────────────────┘
                                   ▲ grows when EVERY row of level L+1 is met
   ┌──────────────┬───────────────┼──────────────┬──────────────┬──────────────┐
 CREDITS        STOCK          WORKING        MACHINE        RESEARCH       DEPTH / SERVES / STABLE
 (paid)      (paid from       (n machines    (a type at     (a line at     (rock reached; a support
   ▲          the store)       RUNNING at     level k)       level k)       machine serving n; n at
   │            ▲              working heat)     ▲              ▲           working heat, none overheating)
 Vaults sell    │                  ▲             │              │               ▲
 materials   machines TOUCHING   Boilers /     credits +      Labs learn      strata heat
   ▲         the Core hand it    Coolant       materials      from Ingot /    (ambient +
   │         materials, up to    beside them   from the       Plate /         modifiers)
   │         the Vault's level   (heat)        store          Component
   │            ▲                                ▲              ▲
   └──────── the production chain:  Drill → Ore → Crusher → Gravel → Smelter → Ingot
                                     → Press → Plate → Assembler → Component
             found by depth (stratum), which only the Core's level lets the shaft reach
```

There is no cycle anywhere in the graph. Every requirement of Core level L can
already be met at level L-1. `CoreLevels.validate()` proves this for forty
levels, and a test runs it on every build (section 11).

---

## 2. Core level requirements

"Found" means the stratum at which a machine is first found. Credits and
store materials are **paid** when the Core grows. The Vault level a store
requirement needs is shown in brackets.

| Core level | Opens | Requires |
|---|---|---|
| **1 Extraction** | Strata 0-2. Drill, Crusher and Vault (stratum 0); Smelter and Boiler (1); Coolant Cell and Lab (2). Machine levels up to 2, a store of up to 80 of each material. Research: Tighter Tolerances, Night Shift. | (start) |
| **2 Processing** | Strata 3-4: Press (Plates, stratum 3) and Amplifier (4). Machine levels up to 3, store up to 256. Research: Deeper Bore, Standing Orders, Drafting Table. | 1,000 credits; 40 Ingots in the store (Vault 2); 2 Smelters at working heat; Crusher at level 2; Tighter Tolerances 1; stratum 2 |
| **3 Fabrication** | Strata 5-6: Assembler (Components, stratum 5). Machine levels up to 4, store up to 819. Research: Refinery Contracts, Ceramic Lining, Seismic Survey. | 60,000 credits; 250 Plates and 250 Ingots (Vault 3); 2 Presses at working heat; Smelter at level 3; Deeper Bore 2; Tighter Tolerances 3; stratum 4 |
| **4 Assembly** | Strata 7-9: Duplicator (stratum 8). Machine levels up to 5, store up to 2,621. Research: Field Notes. | 1.2M credits; 800 Components and 800 Plates (Vault 4); 3 Assemblers at working heat; Press 4 and Drill 4; an Amplifier serving 3; Refinery Contracts 2; Deeper Bore 4; stratum 6 |
| **5 Research** | Strata 10-12: Condenser (stratum 10). Machine levels up to 6, store up to 8,389. | 2M credits; 2,500 Components and 2,500 Plates (Vault 5); 4 Labs at working heat; Assembler 5; Field Notes 2; Refinery Contracts 4; 40 machines at working heat with none overheating; stratum 9 (see "Cores 5 and 6") |
| **6 Amplification** | Strata 13-15. Machine levels up to 7. Research: Resonant Frames. | 3M credits; 8,000 Components and 8,000 Ingots (Vault 6); a Duplicator serving 3; a Condenser serving 2; Field Notes 4; Drill 6; stable 60; stratum 12 |
| **7 Deep works** | Strata 16-19. Machine levels up to 8. **Overdrive** (3 steps). | 15M credits; 25,000 Components and 25,000 Plates (Vault 7); Assembler 7; Coolant Cell 7; Resonant Frames 2; a Condenser serving 3; stable 80; stratum 15 (see "Core 7") |
| **8 The Abyss** | Strata 20-24. Machine levels up to 9 (paid in Alloy and Components). 3 more Overdrive steps. The **Frame Jig** job. | 40M credits; 25,000 Alloy and 50,000 Components (Vault 8); a Smelter driven 3 Overdrive steps; Smelter 8; 4 levels of the shaft's doctrine; stable 100; stratum 19 (see "After Core 7") |
| **9 The Forge** | Strata 25-29. Machine levels up to 10. 3 more Overdrive steps. | 160M credits; 30,000 Frames and 100,000 Alloy (Vault 9); an Assembler driven 6 steps; 8 doctrine levels; Drill 9; stable 120; stratum 24 (designed and graph-checked, not played) |
| **10 and up** | 5 more strata each; machine limit +1 and 3 Overdrive steps each. | Level 9's pattern, with rising numbers: credits ×4 a level; store ×2.2 (capped at what the Vault can then hold); stable +20; doctrine +2; one production machine at the limit and driven to the Overdrive limit, rotating; one research line, rotating |

**Why these rows.**

- **Credits** are the price: it is paid, but it is never the only row (the
  checker rejects a level that is only credits).
- **Store** rows are the storage gate. From level 2 on, every level asks for
  more than the Vault holds when the player arrives, so a Vault level comes
  first (principle 4).
- **Working** rows are the heat gate. A machine counts only while it is
  producing at 90% of its speed or more (the warning key's own threshold), so
  the player must actually heat or cool the new layer.
- **Machine** rows make the old layer matter: the Crushers for level 2, the
  Smelters for level 3, the Presses for level 4.
- **Research** rows tie the Lab to the spine at every era boundary
  (cross-game pattern 5).
- **Depth** means the rock has been reached.
- **Serves** and **stable** ask for control of the whole factory, not of one
  line.

---

## 3. Resource dependencies

| Resource | Source | Process | Use | Next unlock |
|---|---|---|---|---|
| Ore | Drill (stratum 0) | Crusher: 2 Ore → 1 Gravel | Sold (1); Crusher input | — |
| Gravel | Crusher | Smelter: 1 → 1 Ingot | Sold (2.4); Smelter input | Smelter (stratum 1) |
| Ingot | Smelter | Press: 1 → 1 Plate | Sold (5.4). **Store**: machine level 2 and 3, Vault levels, Core levels 2, 3, 6. **Lab**: 0.25 research each | Core 2 (with the Crushers' level and the first research) |
| Plate | Press (stratum 3, Core 2); from stratum 16 also a Press on **Alloy Sheet** (1 Alloy) | Assembler: 1 → 1 Component | Sold (11.5). **Store**: machine levels 3-8, Core levels 3, 4, 5, 7. **Lab**: 0.5 research each. Overdrive (with Ingots) | Core 3 |
| Component | Assembler (stratum 5, Core 3); from stratum 16 also an Assembler on **Alloy Parts** (1 Alloy) | Frame Jig: with an Alloy → 1 Frame | Sold (24). **Store**: machine levels 4 and up, Core levels 4-8. **Lab**: 1.0 research each | Core 4 and later |
| Crystal | a Drill on **Deep Bore** (stratum 16; +10% a stratum) | White Heat Smelter: 1 → 1 Alloy | Sold (3) | Core 7's strata |
| Alloy | a Smelter on **White Heat** (runs faster the hotter it is) | Alloy Parts: 1 → 1 Component; Frame Jig | Sold (12). **Store**: Core 8 (25,000), Core 9 (100,000); machine levels 9 and up (with Components). **Lab**: 2.0 research each. Dispatch | Core 8 |
| Frame | an Assembler on **Frame Jig** (Core 8): Alloy + Component | — | Sold (50). **Store**: Core 9 (30,000). **Lab**: 4.0 research each. Dispatch | Core 9 |
| Credits | Vaults selling materials | — | Machines, machine levels, Core levels, the quota to descend | every level |
| Research | Labs learning from materials | — | The research tree (permanent) | Core rows from level 2 |
| Heat | Machines, Boilers, strata (ambient and modifiers) | Coolant Cells and Condensers take it away | Working-heat and stability rows | Core 2 (the Smelters), 3 (the Presses), 4 (the Assemblers), 5 and up (stability) |
| Cores | A collapse (depth 3 or more) | — | The tree's Core-priced lines | none of the Core's rows; see "Collapse" |

No material exists only to be sold. Every one is also paid into the store and
fed to the Lab. A later level always asks for the newest material *and* the
one before it (Plates with Ingots, Components with Plates), so an old line is
never idle.

---

## 4. Machine dependencies

| Machine | Found | Needs | Makes / does | Level (speed +10% a level) | The Core asks for it |
|---|---|---|---|---|---|
| Drill | stratum 0 | — | Ore; **Deep Bore** job (stratum 16): Crystal, safe to 6.5 | yes | level 4 (for Core 4), 6 (Core 6), 9 (Core 9) |
| Crusher | 0 | 2 Ore | Gravel | yes | level 2 (Core 2) |
| Vault | 0 | anything | sells it | **its level is the store**: 25, 80, 256, 819, 2,621, 8,389… of each material | a level whenever a store row exceeds it |
| Smelter | 1 | Gravel, warmth | Ingot; **White Heat** job (stratum 16): Crystal → Alloy, faster the hotter, safe to 9.0 | yes | 2 at working heat (Core 2); level 3 (Core 3); level 8 and 3 Overdrive steps (Core 8) |
| Boiler | 1 | — | heats its neighbours; material passes through | strength | (makes the Smelter rows possible) |
| Coolant Cell | 2 | — | cools its neighbours; material passes through | strength | level 7 (Core 7); makes the Press and Assembler rows possible |
| Lab | 2 | Ingot, Plate, Component, Alloy or Frame | research: 0.25, 0.5, 1.0, 2.0 or 4.0 per cycle | yes | 4 at working heat (Core 5) |
| Press | 3 | Ingot, kept cool | Plate; **Alloy Sheet** (stratum 16): Alloy → Plate, safe to 6.5 | yes | 2 at working heat (Core 3); level 4 (Core 4) |
| Amplifier | 4 | — | speeds its neighbours | — | serving 3 (Core 4) |
| Assembler | 5 | Plate | Component; **Alloy Parts** (stratum 16): Alloy → Component, safe to 6.5; **Frame Jig** (Core 8): Alloy + Component → Frame | yes | 3 at working heat (Core 4); level 5 (Core 5); level 7 (Core 7); 6 Overdrive steps (Core 9) |
| Duplicator | 8 | — | sometimes doubles a neighbour's output | — | serving 3 (Core 6) |
| Condenser | 10 | — | cools hard, speeds a little | strength | serving 2 (Core 6), serving 3 (Core 7) |

**Machine levels.**

- **Credits:** 150 for level 2, then 12 times more each level to level 6
  (1,800, 21,600, 259,200, 3.1M), and 3.5 times more from level 7 (10.9M,
  38M…); the same for every type. The late rate is from the Core 7 audit:
  at twelve times, a level 7 was 1.7 hours of the Core 6 factory's income.
- **Overdrive** (from the Core's level 7): a type at the level the Core
  before allowed takes steps past it, half a level each, paid in Ingots,
  Plates and research (section "Core 7").
- **Materials from the store:**
  - level 2: 10 Ingots;
  - level 3: 30 Plates and 30 Ingots;
  - level 4 to 8: Components and Plates (90, 270, 810…);
  - level 9 and up: Alloy and Components (`MachineDB.DEEP_LEVEL_FROM`).
  - The Vault pays 30% of the materials, so its current store always pays for
    its next level.
- **Limit:** the Core's machine limit.

A machine that could only be bought with credits would be the "resource
purchase" the reference games avoid. Here, an upgrade needs a production
line that fills the store and a Vault big enough to hold the materials.

---

## 5. Research dependencies

| Line | Opens at Core | Cost | The Core asks for it |
|---|---|---|---|
| Tighter Tolerances (speed) | 1 | Research | level 1 (Core 2), 3 (Core 3) |
| Night Shift (offline hours) | 1 | Research + Cores | — |
| Deeper Bore (yield) | 2 | Research | level 2 (Core 3), 4 (Core 4), 6 (Core 7) |
| Standing Orders (offline rate) | 2 | Research + Cores | — |
| Drafting Table (blueprint slots) | 2 | Research + Cores | — |
| Refinery Contracts (value) | 3 | Research | level 2 (Core 4), 4 (Core 5) |
| Ceramic Lining (heat tolerance) | 3 | Research + Cores | — |
| Seismic Survey (collapse yield) | 3 | Research + Cores | — |
| Field Notes (Lab output) | 4 | Research | level 2 (Core 5), 4 (Core 6) |
| Resonant Frames (Boosters push harder) | 6 | Research | level 2 (Core 7) |
| **Doctrine lines** (one doctrine a shaft: Deep Survey -- Crystal Lattice, Survey Charges; Heat Engineering -- Cryo Lines, Thermal Mass; Precision Works -- Frame Jigs, Lab Benches) | 7 | Research | 4 levels of the shaft's doctrine (Core 8), 8 (Core 9) |

**How the Core limits research.** Each line may go up 2 levels for every Core
level since it opened. For example, Tighter Tolerances can reach 2 under
Core 1, 4 under Core 2, and so on; a line that opens at Core 3 can reach 2
under Core 3. This is the Town Hall → Laboratory → troop chain. Every Core
level opens new research levels, and some Core levels ask for them back.

**No cycles.**

- A Core row asks only for levels that the level before already allows.
- No Core row asks for a line paid in Cores: that would make a collapse a
  requirement.
- The checker enforces both rules.

**The Lab.**

- **Found early:** stratum 2, 180 credits.
- **Learns from any refined material,** and most from the best one. The first
  research line comes from Ingots within the first quarter hour.
- **Competes for material:** every Ingot learned from is an Ingot not sold or
  stored. Research is a production decision, not a menu.

---

## 6. Strata dependencies

The shaft goes down only as far as the Core's level allows (Descend needs the
quota **and** room under the Core). When the quota is met but the Core is at
its limit, Descend says so and opens the Core card.

| Strata | Under Core | New | Heat | Yard |
|---|---|---|---|---|
| 0-2 | 1 | Drill, Crusher, Vault; Smelter, Boiler; Coolant, Lab | ambient 0-0.36; one modifier from stratum 1 | 1 → 3 rings round the Core |
| 3-4 | 2 | Press, Amplifier | 0.54-0.72: a Press next to a Smelter chokes without Coolant | 3-4 rings |
| 5-6 | 3 | Assembler | 0.9-1.08; two modifiers possible from stratum 4 (for example, Coolant Seep can make Assemblers too cold) | 4 rings |
| 7-9 | 4 | Duplicator (8) | 1.26-1.62 | 5 rings |
| 10-12 | 5 | Condenser (10) | 1.8-2.16 | 6 rings |
| 13-15 | 6 | (no new machine) | 2.3-2.7 | +1 ring every 3 strata |
| 16-19 | 7 | **Crystal** (the Deep Bore job) and White Heat and Alloy Parts; the doctrines | 2.9-3.4: a Drill, a Lab and a Press overheat from the rock alone | +1 ring every 3 strata |
| 20-24 | 8 | the Frame Jig (Core 8); more crystal a stratum | 3.6-4.3 | +1 ring every 3 strata |

Every stratum is still rock that is richer and stranger than the one above
(`Strata`: richness, ambient heat, 12 modifiers). What changes is that a
stratum can only be reached by growing the Core, so the next stratum feels
like a new industrial era rather than a bigger number.

---

## 7. Short, medium, long-term and permanent goals

| Layer | Timescale (measured, section 11) | Example | Linked to |
|---|---|---|---|
| Short | seconds to minutes | A machine starved, blocked or off its heat (the warning key); a new line; the next quota | The Core's Working and Stable rows |
| Medium | 5-20 minutes | A machine level (credits and materials); a Vault level (a bigger store); a research level; a stratum | The Core's Machine, Store, Research and Depth rows |
| Long | 10 minutes (Core 2) to hours (Core 5+) | The next Core level | Every row above; it opens the next era |
| Permanent | runs | The research tree and Cores (a collapse) | Research rows: a tree bought in one shaft meets them in the next |

**What the player does each time they come back.** The steps below are
provided by the code, not by a daily reward.

1. **Looks at the factory.** The board, the warning key, and the Core's
   picture, whose size is its level.
2. **Checks what was running.** Offline earnings, the store filled by
   machines touching the Core, research made while away.
3. **Sees one or more goals.**
   - "What now?" lists them in order: machines in trouble; the Core can grow;
     the way down; **the Core's next open row, with its action**; **a machine
     level that can be bought**; research ready; the chain.
   - The Core card lists every row of the next level, with how far along it
     is, and a tap that goes to do it.
4. **Completes a missing resource or chain.** A tap on a store row arms the
   machine that makes the material. A store row that is too big goes to the
   Vault.
5. **Optimizes the factory.** A tap on a working row goes to the machine in
   trouble, or to the heat view.
6. **Opens a prerequisite.** A machine level, a Vault level or a research
   level.
7. **Moves closer to the Core.** The rows turn green one by one.
8. **Opens a new system.** The Core grows: new strata, new machines and
   materials, higher machine and research limits, a bigger possible store.
9. **Sees a new target.** The next level's rows, which ask for the new
   material and the one before it.

---

## 8. Current Lodeworks systems replaced

- **The Core's level as a readout of the depth.** It is now a stored level
  the player grows, and the Core's picture follows it.
- **Descend as the only gate** (one number: credits ≥ quota). Descend now
  also needs room under the Core.
- **"Every material exists to be sold".** Materials are now also paid into
  the store and fed to Labs.
- **Machines without levels.** Every production machine has a level (speed),
  and the Vault's level is storage.
- **Late research** (the first Lab at stratum 6, fed only Components). The
  Lab is now found at stratum 2 and learns from any refined material; the
  Core opens and caps research lines.
- **Machine unlock order.** The Assembler moved from stratum 4 to 5 and the
  Amplifier from 5 to 4, so that each Core era opens its own layer.

## 9. Current systems kept

Unchanged:

- camera, landscape isometric view, machines, material flow, heat and its
  spread, pipes, groups, the tray;
- quotas, strata and their modifiers, the yard's rings, collapse and Cores,
  the research tree's effects, offline earnings;
- save (version 1: new keys with defaults), localization, UI style, visual
  pipeline, performance caches.

The simulation gained two things: the Core as a consumer (last in each
machine's round robin, only for machines touching it, only while the store
has room), and per-type machine speed levels.

**Old saves.**

- A save from before Core levels starts at the lowest Core level whose limit
  covers the strata it had reached. Nothing it had reached is taken away.
- A save from the first round of Core levels moves what the Core had taken
  in into the store.

---

## 10. First implementation: the vertical slice

The slice, as the design asked for it:

```
NEW PLAYER → Core Lv.1 → first resource → first processing chain
→ first storage constraint → first machine upgrade → first research
→ second production dependency → multi-condition Core Lv.2
→ Core Lv.2 opens a new capability → new target appears
```

What it is in the game:

1. **First resource and first processing chain.** The Core comes online (its
   reserve buys the first Drill and Vault), and Ore becomes Gravel in a
   Crusher.
2. **The Smelter.** At stratum 1, Gravel becomes Ingots. A Smelter touching
   the Core fills its store.
3. **First storage constraint.** The Core's level 2 asks for 40 Ingots, but a
   level-1 Vault holds 25. The row says "Vault first".
4. **First machine upgrade.** The Vault's level 2 costs 150 credits and 3
   Ingots; the Crushers' level 2 costs 150 credits and 10 Ingots. Both are
   paid from the store the line filled.
5. **First research.** A Lab at stratum 2 learns from Ingots: 40 research for
   Tighter Tolerances 1.
6. **Second production dependency.** Research, the store and the Vault all
   compete for the same Ingots, and two Smelters must run at working heat (a
   Boiler beside each). The first line is no longer enough, and a second
   line is built.
7. **Core level 2 (multi-condition).** Six rows: credits, store, working
   Smelters, Crusher level, research, stratum. Credits alone never grow it
   (tested).
8. **New capability.** Strata 3-4 with the Press (a new material, Plates)
   and the Amplifier; machine level 3; three new research lines; a store of
   up to 256.
9. **New target.** Level 3's rows, which ask for Plates *and* Ingots, cooled
   Presses, the Smelters at level 3, and two research levels.

**Interface.**

- **The Core card:** its level and era; its store with each material's count
  and the Vault's limit; every row of the next level (✓ or 🔒, have / need,
  a tap to go and do it); what the level opens; and a "Grow the Core" key.
- **The machine sheet:** a level key with the price in credits and material
  gems (red while short), or the reason it cannot go up: "Core first" or
  "Vault first".
- **Descend:** when the Core is the limit, it says "Core level N first"; a
  tap opens the Core card, and the Foreman says it once.
- **Research cards:** a line past its Core limit shows a lock and "Core
  level N".
- **"What now?":** Core lines (grow; the next open row; a machine level).
- **Translation:** every new message has its Turkish translation.

---

## 11. Test results

**Tests.** `godot --headless --path . --script res://tests/test_runner.gd`
reported **330 tests passed (126,679 assertions)** when the slice was built;
the suite now has 368 (see the latest round's section).

`tests/test_core_levels.gd` has 23 tests:

- **The graph:** no cycle and nothing unreachable for 40 levels.
- **The checker catches:**
  - cycles;
  - impossible asks: a line past its end, a machine that does not exist, a
    support machine serving 5;
  - a level that is only credits;
  - a stratum below its own limit;
  - a store no Vault can yet hold;
  - research the Core has not opened, or not let go far enough;
  - research paid in Cores.
  - It also found a real overflow at Core level 36, which is now capped.
- **Openings:** every level opens something new and asks for four or more
  kinds of thing; every machine and research line is reached by some level.
- **The store:** only machines touching the Core fill it, and only while it
  has room; it holds what the Vault's level allows (insufficient storage).
- **Each row blocks the Core on its own:**
  - missing material;
  - missing machine level;
  - missing research;
  - heat (Boilers removed);
  - one credit short;
  - one stratum short.
  - Credits alone never grow it.
- **Growing the Core:** it spends credits and materials, opens depth,
  machine limit and research, and the next level asks for the new material.
- **Machine levels:** paid in credits and materials, with the reasons
  "stock", "core", "storage", "none" and "locked"; speed only for that type;
  the Vault's level is storage, not speed.
- **The Lab:** it learns from any material, and from the best first.
- **The Core caps research** and opens new lines.
- **"What now?":** it names the Core, its next open row and a machine level.
- **Saves:** save/load of the Core, machine levels and the store; a collapse
  resets them; an old save keeps its strata and its intake; a new game starts
  at level 1.

`tests/test_playthrough.gd` plays a fresh game through the real `Sim`:

- a level-1 Core stops at stratum 2, and credits alone do not grow it;
- it builds the line, then the Vault's level 2, the Crushers' level 2, and
  the Lab's first research;
- Core 2, then strata 3-4, with the Press and the Amplifier found;
- reload, and collapse.

**UI checks.**

- `tools/smoke.tscn` at 1440×720 passed: 19 passed, 0 failed, 0 orphaned
  nodes.
- `tools/loc_check.tscn` passed in Turkish and in the pseudo-language with
  larger text. The first pseudo run found a store row too wide for its key;
  the words were shortened.
- `tools/layout_check.tscn` passed in English and Turkish (11 screens × 3
  safe areas).
- The portrait smoke (360×720) used to fail two Descend checks, and so did
  the commit before these changes. The cause was timing: the board earns in
  real time, so on some runs the quota was already met. The smoke now
  empties the quota before that check, and reads the Core card's counts in
  the frame the card is built. Both resolutions pass.

**Played pace.** `godot --headless --path . --script res://tools/core_journey.gd`
is a scripted player. It plays pre-solved layouts for the first three
Core-level lines; after that it lays whole self-fed lines, clears machines
that barely run, and works from the Core's rows and "What now?". It plays
actively for six hours (`LODEWORKS_CORE_HOURS=6`); a human plans slower
and has offline time on top.

Firsts (run of 25 September 2026, with the Dispatch board, and a
scripted player that stops repairing and building while it saves for the
Core):

| Core level | Reached | Earning then |
|---|---|---|
| Core 2 | 6 min 45 s | 35/s |
| Core 3 | 15 min 10 s | 411/s |
| Core 4 | 30 min 39 s | 2.0K/s |
| Core 5 | 1 h 18 min | 4.2K/s |

Snapshots:

- **30 min:** Core 3, stratum 6, 125 machines, 2.0K/s. Open: credits only
  (1.14M of 1.2M).
- **1 h:** Core 4, stratum 9, 164 machines, 4.0K/s. Open: credits (5.5M of
  10M).
- **2-6 h:** Core 5, stratum 12, about 145 machines, 3.8K/s. Open: 60M
  credits (28.6M saved by 6 h), a Duplicator serving 3, and stable 60. The
  stability row stays at 0: stratum 12 (ambient heat 2.2) is hot enough
  that something is always overheating.
- **Contracts:** 13 filled in 6 h. The scripted player fills one only when
  the Core's next level does not need that material, and from Core 4 the
  Core wants the same Plates and Components the contracts ask for.
- **Longest stretch with no new first:** 1 h 59 min, at the end.

An earlier run in the same round measured Core 5 at 2 h 07 min. Its
scripted player kept repairing and re-laying machines while it saved, and
the churn ate its income; the table above is the player that saves.

**What the six hours say.**

- **Nothing to do?** Something was always open: the Core's next level and
  more than 20 research levels.
- **The wall is heat.** Past Core 5 the scripted player stops at the
  stability row on the hot strata. It is the first row that asks the
  player to rebuild a hot factory, not add to it, and no played run has
  cleared it yet.
- **Credits after Core 5.** At 3.8K/s, Core 6's 60M is about four hours of
  income. If a human's factory earns no more than this, Core 6 needs a
  lower price or more to do while saving.
- **Unmeasured:** a human's time at any level; levels 6-8.

**Balance history** (all from `core_journey` runs):

- **First run:** machine levels at +25% speed for a sixth of today's price.
  Every machine was at its limit two minutes after each Core level, and
  Cores 2, 3 and 4 fell at 12, 15 and 26 minutes.
- **Change:** levels now give +10% for 150 credits ×12 a level, with
  materials ×3 a level, and Core prices were raised and paced against the
  income measured at each level.
- **Stability:** 60 machines at working heat for Core 5 was out of reach
  of a factory that the scripted player judged reasonable (35-50 counted of
  about 110). It is now 40 for Core 5, and 60, 80 and 100 for Cores 6-8.
- **Core 5's price:** 6M left the player with nothing but stability to do.
  15M left over an hour of saving. It is now 10M.
- **Contracts:** at first a credit contract paid at least 45 seconds of
  the factory's income. Played, a factory that filled contracts as fast as
  its store refilled earned more from them than from all its Vaults. The
  floor is now 12 seconds, and a research contract pays 1.25 times what a
  Lab would learn.

**Core rows that say what holds them back** (built in the same round).

- **Each row names what holds it back.** A working-heat or stability row
  that is not met lists why its machines do not count. For example: "2 / 4
  · 1 starved, 1 too cold".
- **A tap walks to the next machine.** It focuses the machine, opens its
  sheet and turns the heat view on when heat is the cause.
- **Logic and tests.** The logic is `CoreLevels.why_not_working` and
  `CoreLevels.holding_back`, tested in `tests/test_core_levels.gd`.

---

## 12. Next single priority

See the end of "Core 7", below.

---

## Heat: a factory decision

Heat is one of the systems that carry the long game. The rock's heat rises
with every stratum, so every Core era meets hotter rock than the last. The
player answers it with layout, modes, levels and the Coolant Cells, and a
factory that answers it well earns more than one that does not.

### The audit (25 September 2026)

`tools/heat_lab.gd` builds the Core's first three lines and a dense Drill
field on plain rock at strata 0-24. It measures what overheats, what counts
as working and what the line earns. The scripted player's factory was
audited at stratum 12 and 15.

**What was wrong:**

1. **Two heat lines, one of them invisible.** A machine counted as working
   only at 90% of its speed. The comfortable band faded to 80% at the
   tolerance, so the 90% line sat halfway to the tolerance. For a machine
   that wants no heat (Drill, Press, Lab) the rock's heat alone crossed it
   from stratum 8. Every line in the lab lost its "working" machines there,
   while nothing was near overheating. The warning key counted them all as
   "off temperature", and the Core's stability row could not be met with
   any layout short of a Coolant Cell beside nearly everything.
2. **Heat never followed work.** A level-9 Press gave off the heat of a
   level-1 one. Upgrading was output for free, with no trade-off.
3. **Nothing scaled against the rock.** The rock gains 0.18 a stratum
   forever. Tolerances were fixed, a Coolant Cell never grew stronger, and
   the one research line for heat (Ceramic Lining) is paid in Cores, so a
   first shaft had no answer but more Coolant Cells.
4. **An early answer became a late trap.** A Boiler that warmed a Smelter
   at stratum 2 overheats the Drill or Lab beside it from stratum 6. The
   game showed a hot machine, never the Boiler behind it.
5. **Stuck at Core 5.** At stratum 12, 5 of 77 levelled machines
   overheated, all beside Boilers, and 24 counted as working. Stability
   needs none overheating, so the row stayed at 0.

### The heat model now

- **One safe range.** The comfortable band fades only to 90%, so a
  machine's safe range is exactly where it counts as working:
  - from the warmth it needs (warm machines only) to its tolerance;
  - past the tolerance it chokes;
  - below the range it runs slow.
  - `MachineDB.safe_range`; the sheet draws its end as a red mark.
- **Heat follows work.**
  - **Makers:** a maker's own heat grows 10% a level, as its speed does
    (`MachineDB.heat_factor`), so an upgrade makes more and runs hotter.
  - **Heat supports:** the Boiler, Coolant Cell and Condenser now have
    levels. Each level moves 25% more heat.
  - **The Core's limit:** machine levels are capped by the Core, so the
    Core that reaches hotter rock also allows stronger cooling. The heat
    tests show a Press at its limit, with three Coolant Cells at theirs,
    stays safe at the deepest stratum of every Core level from 4 to 8.
- **Modes (opened by Core level 3).** Any maker can run Cool (three
  quarters of the speed, half its own heat) or Hot (a quarter faster, 60%
  more heat); a Boiler can run Low (half its heat). A mode belongs to the
  machine: it is saved and travels with it.
- **The heat card.** A tap on a machine's heat bar shows where its heat
  comes from, as the simulation adds it up: itself, each neighbour, the
  rock. It gives the safe range and what would change it, each line a tap
  that goes and does it:
  - run the Boiler beside it Low, or move it;
  - run it Cool;
  - a Coolant Cell beside it, or, when there is no free tile, the Vault
    beside it swapped for one (material passes through it);
  - the Coolant Cells a level up;
  - its own level's extra heat.
- **The Core's rows** say what holds them back ("2 / 4 · 1 too hot"), and a
  tap walks to each machine, with the heat view on when heat is the cause.

### Heat by era

| era | strata | rock | what heat asks |
|---|---|---|---|
| Core 1-2 | 0-4 | 0-0.7 | a light signal: Smelters want a Boiler; nothing overheats in the Core's lines |
| Core 3 | 5-6 | 0.9-1.1 | modes open; a Press beside a Boiler is the first overheat |
| Core 4-5 | 7-12 | 1.3-2.2 | a lone Press overheats from stratum 8; old Boilers overheat their other neighbours: run them Low or take them away (the rock keeps the Smelters warm by stratum 10) |
| Core 6-7 | 13-19 | 2.3-3.4 | the rock alone overheats a Drill from 15, a Lab from 16, a Crusher from 19: Cool mode, Coolant Cells and their levels, a denser factory re-laid round them |
| Core 8+ | 20+ | 3.6+ | every low-tolerance machine needs cooling: levels, Condensers, layout |

Measured by `tools/heat_lab.gd`:

- **Every line answered.** The player's answers are a Boiler Low, Cool
  mode, Coolant Cell levels and a Coolant Cell on a free tile. With them
  every reference line runs with nothing overheating to stratum 24.
- **Answered lines earn more.** At stratum 15 the Press line, every maker
  at its limit, earns 20.3 credits a second answered against 16.9 as
  built. At 24 it is 22.2 against 6.9.
- **Density costs.** The dense Drill field cannot be answered in place from
  stratum 15; it has to be re-laid with room for cooling.

### What the scripted player does with it

`tools/core_journey.gd` answers heat the same way, in the heat card's
order. It reaches:

| Core level | Reached |
|---|---|
| Core 5 | 1 h 17 min |
| Core 6 | 4 h 00 min |

What happened at each wall:

- **Stability at Core 5 and 6.** The Core 6 row (60 at working heat,
  stratum 12) no longer blocks it. The Core 7 row (80, stratum 15) was met
  by 5 h, after two Crushers boxed in by the first line had a Vault
  swapped for a Coolant Cell.
- **Income on hotter rock:** 6.8K/s at stratum 12, 5.3-5.5K/s at stratum
  15.
- **The next wall is not heat.** Core 7 costs 1B credits, about 50 hours
  of the measured income, with its other rows met.

### Not done in this round

- **A research line for heat in the first shaft.** Ceramic Lining is paid
  in Cores, and changing that moves the collapse economy.
- **A mark on the board for a machine's mode.** The sheet and the heat card
  show it.

---

## Cores 5 and 6: the same disease, the same cure

The round of 26 September 2026 (`BENCHMARK.md`, section 6). Measured on the
old table, the two stages before Core 7 were mostly waiting:

- **Core 4 → 5:** the other rows were met at 8 min, then 36 min of saving for 10M (82%).
- **Core 5 → 6:** the other rows were met at 16 min, then 2 h 42 min of saving for 60M (91%).

Each also asked for a research level the Core two levels down already
allowed: Tighter Tolerances 6 and 8, open since Cores 3 and 4.

**What changed, in the Core 7 model.**

- **Core 5:** 2M credits, and Refinery Contracts 4 in Tighter Tolerances 6's place.
- **Core 6:** 3M credits, Field Notes 4 in Tighter Tolerances 8's place, and a Condenser serving 2. The Condenser is the machine Core 5 opens; a newly opened building is asked for at the next level (pattern 4).

Every other row stays. A test now checks every row of every written level
for new work (`tests/test_core7.gd`), from Core 2 to Core 8.

**Played (scripted player, a new game, credit-only waits fast-forwarded):**

| | old table | new table |
|---|---|---|
| Core 4 → 5 | 44 min 31 s; 82% only credits | 12 min 34 s; 43% saving (5 min 25 s); a decision in 9 of 13 minutes |
| Core 5 → 6 | 2 h 59 min; 91% only credits | 34 min; 52% saving (17 min 40 s, the Drill level and the Core); a decision in 23 of 35 minutes |
| Core 6 reached | 4 h 17 min | 1 h 20 min |
| Core 6 → 7 | 6 h 40 min; 2% only credits | 5 h 35 min; 4% only credits; a decision in 95 of 337 minutes |
| Core 7 reached | 10 h 57 min | **6 h 55 min** |

**The second shaft, after a collapse at Core 7** (the research tree and
111 Cores kept):

| | old table | new table |
|---|---|---|
| Core 6 reached | 3 h 50 min | 42 min |
| Core 7 reached | not in 16 h | not in 16 h |

In both runs the second shaft stalled at stratum 15's stability row.

**The Core 7 era, as played on the new table.**

- **Income:** it fell from 8.4K/s at Core 7 to 2.9K/s on stratum 19.
- **Overdrive:** 14 steps were taken.
- **Core 8's rows:** its Amplifier and stratum were met. Nine hours in, stability stood at 38-42 of 100, and the store's Components at 6.7K of 80K.
- **Resonant Frames 4:** 937K research.

That is the next wall: the rock's heat takes away more than the Core 7
era adds (`BENCHMARK.md`, section 6).

---

## Core 7: a stage, not a price

The round of 25 September 2026. Core 7 used to be reached by saving 1B
credits: about 46 hours of the income a Core 6 factory makes, after every
other row was met. It is now reached by growing the Core 6 factory in the
ways the Core 7 era needs. Credits are one part of that.

### How it is measured

`tools/core_journey.gd` plays a new game with the scripted player
(`tools/core_journey_player.gd`) and reports each Core level as a stage:

- what the stage opened, and what was open to do at its start;
- when each row of the next level was first met;
- how long only credits were left;
- the player's decisions (machines placed and sold, modes, levels, research, contracts, strata), and in how many minutes of the stage at least one was made;
- the income at both ends, and where the earned credits went: machine levels, the Core, machines.

`LODEWORKS_CORE_SKIP=1` fast-forwards a credit-only wait once the factory
has sat unchanged in it for 20 minutes. The run earns at the rate it
measured over those 20 minutes, and says how much it skipped.

`LODEWORKS_CORE_DUMP=7:<file>` writes the factory at the moment every row
of Core 7 is met. `tests/fixtures/core7_ready.json` is that save, from the
run below.

### The audit: the Core 1 → 7 graph, as played

Old table, scripted player, 25 September 2026:

| stage | length | only credits left | minutes with a decision | what the player did |
|---|---|---|---|---|
| Core 1 → 2 | 7 min 30 s | 15 s (3%) | 8 of 8 | the first line; the Vault's and Crushers' levels; the first research |
| Core 2 → 3 | 8 min 50 s | 1 min 30 s (17%) | 10 of 10 | Presses (Plates); levels 3; two research lines |
| Core 3 → 4 | 16 min 49 s | 5 min 5 s (30%) | 15 of 18 | Assemblers (Components); an Amplifier; levels 4 |
| Core 4 → 5 | 44 min 31 s | 36 min 36 s (82%) | 8 of 45 | Labs at working heat, Assembler 5; then saving |
| Core 5 → 6 | 2 h 59 min | 2 h 42 min (91%) | 17 of 180 | a Duplicator, Drill 6, stability 60; then saving |
| Core 6 → 7 | not reached | -- | -- | see below |

**What old Core 7 asked for:**

- 1B credits;
- 25,000 Components and 25,000 Plates;
- a Condenser serving 3;
- Deeper Bore 6;
- Smelter 7;
- stability 80;
- stratum 15.

**How the non-credit rows went, played.**

- Deeper Bore 6 was met 5 seconds into the stage (the Core 5 era had allowed it).
- The Condenser was met at 1 minute, stratum 15 at 5.
- 3 h 43 min into the stage, the rest was still open. The Vault and the Smelters' level 7 were 37.3M each; the bot had not got stability to 80.
- In a longer run, 24 h in, the stage was still stuck. Stability was at 0 of 80 and the Condenser at 2 of 3. Credits stood at 35.7M of 1B, because the player spent them on everything else.

**The credits alone.** At the measured 5.9-6.1K credits a second, the 1B
was about 46 hours. That puts Core 7 at about 50 hours of active play.

### Why Core 6 → 7 was a credit wall

1. **Every price past Core 5 assumed an income that did not come.**
   - Core prices grew ×60, ×20, ×8, ×6 and then ×17 (60M to 1B). Machine levels grew ×12 a level.
   - In the first eras each Core level brought a new material or research line, and income grew about tenfold an era: 47/s, 457/s, 2.0K/s.
   - From Core 4 on, income grew about 1.4× an era: 4.4K/s at Core 5, 6.1K/s at Core 6, 5.9K/s on stratum 15.

   **Prices in hours of the income of the era that pays them:**

   | what | price in that era's income |
   |---|---|
   | machine level 3 | 38 s |
   | machine level 4 | 47 s |
   | machine level 5 | 2 min |
   | machine level 6 | 12 min |
   | machine level 7 | 1.7 h |
   | machine level 8 | 18 h or more |
   | Core 5 | 83 min |
   | Core 6 | 3.8 h |
   | Core 7 | 45 h |
2. **The graph ran out after Core 5.**
   - The last material (Components) arrives at Core 3.
   - The last machine (the Condenser) arrives with Core 5.
   - Every research line paid in research is at its end by Core 6: Tighter Tolerances 8 and Deeper Bore 6 under Core 4, Refinery Contracts 6 under Core 5, Field Notes 5 under Core 6. The Labs had banked 124K research by Core 6, with nothing to spend it on.
   - Core 6 opened no machine, material or research line: only three strata and a machine level.
3. **Rows the factory already had.** Old Core 7's research row was met on the first beat. So were Core 5's Tighter Tolerances 6 (allowed since Core 3) and Core 6's Tighter Tolerances 8 (allowed since Core 4).
4. **One queue left.**
   - The reference games keep a player busy with parallel queues: builders, the laboratory, storage (cross-game pattern 16).
   - Lodeworks has three: credits, the store's materials, and research.
   - After Core 5 the research queue had run dry, and the store filled in minutes with nothing to spend it on.
   - Credits were the only queue left, so the Core's price became the whole requirement.

### What the reference games do here

| principle (`research/progression-reference.md`) | reference | Lodeworks Core 7 |
|---|---|---|
| the central level caps everything | TH, HQ, Furnace, City Hall | the Core caps depth (19), machine levels (8), Resonant Frames (4), Overdrive steps (3) |
| named buildings at N-1 (pattern 2) | Furnace 10: Marksman Camp 9 + Research Center 1 | Assembler 7 and Coolant Cell 7, the Core 6 limit |
| a spine that recurs (pattern 3) | the Embassy, the Wall | the store: every level asks for the newest material and the one before, past the Vault's limit |
| research building at era boundaries (pattern 5) | Furnace 10/16/20; City Hall 10/16/21 | Resonant Frames 2, the Core 6 era's own line |
| what opened becomes a row next (pattern 4) | the Coal Mine opens at 3, is required at 4 | Overdrive opens at 7, is asked for at 8 |
| parallel queues (pattern 16, principle 8) | builders, laboratory, training | credits (levels, the Core), store materials (Vault, Overdrive), research (Resonant Frames, Overdrive) |
| a tier's resources go into its buildings | a TH costs a fraction of its era's upgrades | Core 7's own price is 15M; its stage's levels took 106M |
| surplus into the scarce tier (pattern 9) | the Forge; Fire Crystal conversion | Overdrive turns store materials and research into speed |
| supercharge the maxed (CoC #50) | Supercharge levels past the cap | Overdrive past the Core 6 limit |

### The new Core 7

Each row asks for something the Core 6 era has to build. No factory that
Core 5 allowed has any of them: `tests/test_core7.gd` checks this for every
row of Core 7 and 8.

| row | why this row | what the player does for it |
|---|---|---|
| **15M credits** | The Core's own price. Most of the stage's credits go into the levels it asks for (below). Played, the Core's price was ready 3 h 34 min into the stage, before the last other row. | Earns while doing the rest. |
| **25,000 Components and 25,000 Plates in the store** | The storage gate, as at every level. A level-6 Vault holds 8,389. Overdrive, which Core 7 opens, is paid from this store. | A level-7 Vault, and the lines touching the Core. |
| **Assembler at level 7** | The chain's end at the Core 6 limit. Components are what the store rows, the levels and the Labs are paid in. | A machine level: 10.9M credits and 2,430 Components and Plates. |
| **Coolant Cell at level 7** | The rock of strata 16-19, which Core 7 opens, overheats a Drill, a Lab and a Crusher on its own. A Coolant Cell at the Core 6 limit moves 150% more heat than at level 1. | A machine level. |
| **Resonant Frames at level 2** | The research gate at the era boundary. Every other research-paid line is complete by Core 6; this is the Core 6 era's own, and it changes what a layout of Boosters is worth. | Labs fed with Components: 210K research in all. |
| **A Condenser serving 3** | The Core 5 era's machine, used where it matters. | A Condenser among three machines, or in a Coolant Cell's place. |
| **80 machines at working heat, none overheating** | The whole factory under control on stratum 15. Played, this was the longest row. | Heat work and growth, a balance: a new line is what overheats. |
| **Stratum 15** | The rock under the Core 6 limit, reached. | Descending. |

**What went out of the old row set, and why:**

- **1B credits:** 46 hours of the measured income, and the only real ask.
- **Deeper Bore 6:** allowed since Core 4, and met on the first beat.
- **Smelter 7:** a credit row with no reason in the Core 7 era. From stratum 10 the rock itself keeps Smelters warm.

A row asking for 8 Assemblers at working heat was tried and taken out. On
stratum 15 an Assembler at level 6 overheats alone, and the scripted player
could not get past 3 in 5 hours. The stability row already asks for the
same kind of work across the whole factory.

**Machine levels past 6.**

- Up to level 6 a level still costs twelve times the one before.
- From level 7 it costs 3.5 times the one before (`MachineDB.LATE_LEVEL_GROWTH`).
- A level 7 is now 10.9M credits, about half an hour of the Core 6 factory's income, against 1.7 hours at twelve times. A level 8 is 38M.

**Resonant Frames (opened by Core 6).**

- It has four levels. Core 7 asks for level 2 and Core 8 for level 4.
- Each level gives every Amplifier, Condenser and Duplicator's neighbours 15% more of its boost.
- Every Booster is warm, so a layout dense with them is a trade against heat.
- It costs 60K research for the first level, growing 2.5 times a level.

### What Core 7 opens: Overdrive

- **Which types:** a machine type that has reached the limit the Core before allowed (level 7) can be driven past it.
- **How many steps:** three for Core 7, three more for every Core level after it (`CoreLevels.overdrive_cap`).
- **What a step does:** half a level of speed, with the heat that follows work. On a Coolant Cell or a Condenser, a step is strength.
- **What it is paid in:** Ingots and Plates from the Core's store, and research. Never credits.
  - Step 1: 4,000 of each and 25K research.
  - Step 2: 5,900 of each and 37K research.
  - Step 3: 8,700 of each and 54K research.
  - Each Core level's steps cost 3.2 times the last level's, as the store at the Vault's limit grows, so every step fits its store.
- **In the interface:** the machine sheet has an Overdrive key under the level key, with its price in gems and research. "What now?" names a step that can be taken.

**Why Overdrive, of what the pool has for the late game (FP-12):**

- **It answers the audit.** After Core 5 only the credit queue was left. Overdrive gives the store's materials and the Labs' research a use that grows the factory: the Core 7 era runs three queues at once.
- **It keeps the old tiers in use.** Ingots and Plates are what it is paid in; since Core 4 they had only been sold or paid into store rows. The lines touching the Core feed it. The target moves from "Components for credits" to "materials and research for power".
- **It is a new decision, not a bigger number.** A step makes a type hotter on the hottest rock so far, so every step is weighed against the cooling the Core 7 row asked for.
- **It stays in bounds.** No new resource, machine or art (this round's limits).

**Played:** one minute after Core 7, the scripted player drove its
Assemblers, then its Presses, Smelters and Crushers, three steps each, in
25 minutes: 12 steps, from the store and the research it had banked.
Research then set the pace: five more steps in the next 2 h 15 min.

What else Core 7 opens: strata 16-19, machine level 8, Resonant Frames to
its end, and a store of up to 85,899 of each material.

### Before and after

Scripted player, a new game to Core 7. Credit-only waits before Core 6 are
fast-forwarded in both runs (2 h 15 min in all).

| | old table | new table |
|---|---|---|
| Core 6 reached | 4 h 17 min | 4 h 17 min (the same run to here) |
| Core 7 reached | not reached; about 50 h by credits alone | **10 h 57 min** |
| Core 6 → 7 stage | ~46 h, nearly all saving for 1B | 6 h 40 min |
| only credits left in the stage | ~95% (estimated) | **6 min 45 s (2%)** |
| minutes with a decision | -- | 139 of 401 |
| the Core's own price | 1B | 15M |
| credits into machine levels in the stage | -- | 106M (16 levels, every type to 7) |
| income through the stage | 6.1K/s → 5.9K/s | 6.1K/s → 6.9K/s |

**When each new row was first met, from the stage's start:**

| row | first met after |
|---|---|
| Condenser serving 3 | 5 s |
| stratum 15 | 2 min |
| Resonant Frames 2 | 42 min |
| the store: Components | 1 h 9 min |
| the store: Plates | 1 h 12 min |
| Assembler 7 | 1 h 34 min |
| Coolant Cell 7 | 2 h 9 min |
| the Core's 15M | 3 h 34 min |
| stability 80 | 4 h 13 min |

The Core grew at 6 h 40 min. The stability row reached 80 at 4 h 13 min
and came and went: every new line is a new source of heat. Played again
from the same Core 6 save, the stage took 4 h 35 min. The stability row is
the stage's longest part, and the one a human will vary on most.

**The factory at Core 7** is 175 machines:

| type | count |
|---|---|
| Coolant Cell | 57 |
| Vault | 47 |
| Drill | 21 |
| Crusher | 13 |
| Lab | 10 |
| Smelter | 9 |
| Press | 8 |
| Assembler | 5 |
| Boiler | 3 |
| Condenser | 1 |
| Duplicator | 1 |

35 of them run in a mode. A third of the board is cooling. Coolant Cells
cost 1.2 times more with every one owned, so on hot rock cooling is also a
credit sink (FP-21 made their levels the cheaper answer).

### After Core 7, as first measured

(Superseded by the section "After Core 7: deeper is stronger".)

**Played, the first three hours of the Core 7 era:**

- **Overdrive:** 12 steps in the first 25 minutes, then paced by research.
- **Descent:** the player went down to 19 in 25 minutes.
- **Income:** it fell from 6.9K/s to 3.7K/s. The rock of strata 16-19 overheats the old layout, and the player was re-laying it, placing 245 machines and selling 248 in three hours.
- **Core 8:** of its rows, Overdrive and stratum 19 were met. Open were:
  - the 60M credits;
  - the store at 80,000 (a Vault 8);
  - an Amplifier serving 4;
  - Resonant Frames 4;
  - Assembler 8;
  - stability 100.

**Core 8 is designed and graph-checked, not measured.**

- It asks for what Core 7 opened: an Assembler driven 3 steps, and Resonant Frames 4.
- Its credits are four times Core 7's.
- Past Core 8 the levels are still a formula:
  - credits grow four times a level (it was fifteen);
  - every level asks for one production machine at the limit, and that machine's Overdrive steps.

**The long chain, checked against what exists:**

| link | Core 1-7 | after Core 7 |
|---|---|---|
| Core → machine progression | caps; levels to 8; Overdrive | yes: the level and Overdrive caps grow with the Core |
| machine progression → production chains | Ingots, Plates and Components feed levels, store rows and Overdrive | **no new chain after Components (Core 3)**; a new material waits for the owner's D1 decision (crystal, FP-18) |
| production → research | Labs learn from the chain; Resonant Frames and Overdrive spend research | **no research line opens after Core 6** |
| research → strata | research rows gate Core levels, which gate depth | yes |
| strata → factory expansion | a ring every three strata from stratum 10 | yes, to the whole board at stratum 52 |
| expansion → advanced systems | modes (Core 3), Overdrive (Core 7) | the pool's next candidates: Core modules, the Core's reach (O5), bulk buyers (FP-15) |
| advanced → late progression | -- | Core 9 and up are a formula (P5) |
| late → collapse / permanent | the research tree survives; nothing of the Core does | **not connected**: the owner's decision P6 |

### Collapse and Blueprint, measured against it

**Collapse.**

- **What a collapse costs.** At Core 7 it throws away 11 hours of active play of the Core's progress: its level, the machine levels, Overdrive and the store.
- **What it keeps.** The research tree, Resonant Frames among it. So a second shaft meets Core 7's research row the moment Core 6 opens it, as it already did the earlier research rows.
- **What the Cores it pays buy.** Only the Core-priced research lines, and none of those is a Core row.
- **So collapse is still the short reset loop the brief warns against,** not a permanent layer over the factory. Nothing was built for it this round.
- **The owner's decision (P6), now with a measured price:** which of the Core's progress a collapse keeps. For example:
  - a Core-level floor;
  - Overdrive steps as the permanent layer (a step survives, and a new shaft's types start driven);
  - standard levels (FP-19).

**Blueprint.**

- **What reaching Core 7 took.** Its factory has 175 machines of 11 types. The scripted player placed 643 machines and sold 467 on the way.
- **What a collapse would ask.** A second shaft would need those 175 placements again, most of them the same lines. On hot rock the layout is the hard part: a third of it is cooling.
- **So Blueprint becomes a real progression dependency** the moment P6 keeps anything of the Core's progress. Until then it is quality of life. This is recorded in P7.

### Not done in this round

- **Core 5 → 6.** It is still 91% credit-only: a 60M price at 4.4K/s, with its other rows met in 16 minutes. It is the same disease one level earlier, and it was out of this round's scope.
- **Core 8 and later** are designed, not played.
- **Overdrive's picture.** There is no glow on a driven machine, and no pips on the Core card.

### Next single priority

**Late-game income.** Every stage from Core 4 on is paced by an income
that grows about 1.4 times an era, while the rock's heat takes it back:

- at Core 7 the income fell from 6.9K/s to 3.7K/s on strata 16-19;
- Core 5 → 6 is still 91% credit-only.

Overdrive is the first growth that is not paid in credits. The next round
should measure it and the Core 7 era, and re-derive Core 5 → 6 and Core 8
from what that factory earns.

## After Core 7: deeper is stronger

The round of 26 September 2026. The brief: the long-term progression after
Core 7 -- the deep strata, the research tree, collapse, Blueprint, a new
production layer, Core 8 -- measured before and after, built on the systems
that exist.

### Measured first: what the rock of strata 16-19 does

**The Core 7 era as played before this round** (run a1: the scripted
player on the table of 26 September, `BENCHMARK.md`, section 3):

| | Core 7 (6 h 55 min) | stratum 17 (7 h) | stratum 19 (8 h) | 9-16 h |
|---|---|---|---|---|
| income | 8.39K/s | 5.97K/s | 2.82K/s | 2.5-2.9K/s |
| makers at working heat | -- | 26 | 18 | 21-26 |
| Assemblers at working heat | 3 | 1 | 0 | 0 |
| stability (of 100) | -- | 0 | 0 | 38-42 |
| Components in the store | -- | 8,852 | 8,852 | 6,665-8,852 |

- **Decisions:** 803 in 296 of 546 minutes; 384 machines sold and 370 placed.
- **Research:** 506K made and 526K spent, all of it on 14 Overdrive steps. No research level was bought.
- **Waiting:** none. No row was ever left to credits alone, and Core 8 was not reached in 9 hours.

**The same factory, moved down unchanged** (`tools/deep_lab.gd`). This is
the factory of the moment Core 7's rows were met (the fixture
`tests/fixtures/core7_ready.json`), with its levels and research, set on
each stratum and run with no player:

| stratum | credits/s | research/s | makers overheating / working / all |
|---|---|---|---|
| 15 | 8.38K | 34 | 0 / 46 / 69 |
| 16 | 7.30K | 16 | 1 / 43 / 69 |
| 17 | 10.0K | 18 | 11 / 25 / 69 |
| 19 | 13.0K | 19 | 3 / 41 / 69 |
| 21 | 11.2K | 16 | 6 / 38 / 69 |
| 24 | 9.18K | 18 | 16 / 28 / 69 |

(Credits move with each stratum's modifiers, not only with depth.)

So the rock alone does not take the income: a stratum's richness grows
faster than the heat costs a factory left alone. What the rock takes is:

- **the Labs.** From stratum 16 research falls by about half. A Lab takes 3.0 heat, and the rock alone is 2.9-3.4.
- **stability.** From stratum 17, Drills, Labs and Presses overheat from the rock alone (a Drill takes 3.0; the rock's 3.4 and its own 0.6 are past it). The stability row stays at 0 until every one of them is cooled or gone.
- **and, played, the factory.** The player answered the stability row by selling what overheated, and a chain with a machine sold from its middle starves. Run a1's income fall was that teardown: 384 machines sold in nine hours.

**The problem, then:** on deep rock the old chain gains nothing and has
everything to fight. Every stratum only added heat to cool, and Core 8 asked
for more of the same chain (80,000 Components) on the rock that stops it.

### What was built

One connected plan on the systems that exist: no new machine, no new
currency.

**1. The deep chain, on jobs** (`MachineDB.JOBS`). A job is another recipe
for a machine the player already has, set tile by tile as a mode is.

- **Deep Bore** (a Drill, from stratum 16) digs **Crystal**. It is built for hot rock: safe to 6.5, where a Drill is safe to 3.0. The rock holds 10% more crystal every stratum from 16 (`Strata.vein`).
- **White Heat** (a Smelter, from stratum 16) turns Crystal into **Alloy**, and runs on heat (`MachineDB.drive_efficiency`):
  - the hotter its tile, the faster it works, in proportion to its heat, from its optimum (5.0) up to its tolerance (9.0), where it is 1.8 times as fast;
  - past the tolerance it chokes four times as hard as any other machine.
  So the rock's heat, a Boiler, Hot mode and Overdrive, which choke the old chain, feed this one. How close to the edge to run it is the player's call.
- **Alloy Sheet** (a Press, from stratum 16) rolls an Alloy into a Plate, and **Alloy Parts** (an Assembler, from stratum 16) makes a Component from one. Both are safe to 6.5, where the old chain's Press takes 2.5 and its Assembler 4.0.
  - So the Plates and Components that every machine level and the Core's store still ask for come from either chain: cooled ore, or hot crystal.
  - An Alloy rolled or worked is an Alloy not sold, not learnt from and not stored, and a Plate sells for less than the Alloy it was rolled from. So this is a choice, not a replacement.
  - Both were added after plays in which the store's Plates and Components stopped for hours on stratum 19 (see "Played").
- **Frame Jig** (an Assembler, from the Core's level 8) joins an Alloy and a Component into a **Frame**.

**2. Every new material ties into systems that exist:**

| material | made by | used by |
|---|---|---|
| Crystal | Deep Bore (stratum 16; more with depth) | White Heat; Vaults (3) |
| Alloy | White Heat | Alloy Sheet; Alloy Parts; Frame Jig; the store (Core 8: 25,000; Core 9: 100,000); machine levels from 9 (with Components); Labs (2 research, twice a Component's); Dispatch; Vaults (12) |
| Frame | Frame Jig (Core 8) | the store (Core 9: 30,000); Labs (4 research); Dispatch; Vaults (50) |

**3. Research: branches and doctrines** (`Economy.BRANCHES`,
`Economy.DOCTRINES`).

- Every research line has a branch: production, efficiency, heat, deep mining, logistics, the Core. The grid shows the lines branch by branch.
- From Core 7 a shaft follows **one doctrine**, chosen once. Each doctrine opens two research lines the others do not have, and only the chosen doctrine's lines are bought or count:

| doctrine | its lines | what it changes |
|---|---|---|
| Deep Survey | Crystal Lattice (Deep Bores +20% a level); Survey Charges (quotas −8% a level) | more of the deep chain, and deeper sooner |
| Heat Engineering | Cryo Lines (coolers +15% a level); Thermal Mass (+0.4 tolerance a level) | the old chain lives on hot rock |
| Precision Works | Frame Jigs (Frames and Components sell for 20% more a level); Lab Benches (Labs learn 25% more a level from Alloy and Frames) | parts and research |

- **The player cannot have everything.** In a shaft there is one doctrine. Its lines go two levels a Core level from Core 7, up to six at Core 9.
- **A doctrine is the shaft's.** A collapse clears the choice and the research bought in its lines. So each shaft's Core 7 era has research to spend and a choice to make again. (Kept, the doctrine's research met the next shaft's doctrine row the moment the doctrine was chosen.)

**4. Core 8 from the measurement** (`CoreLevels.LEVELS`).

- **It asks for:**
  - 25,000 Alloy and 50,000 Components in the store (a Vault 8);
  - a Smelter driven 3 Overdrive steps, and Smelter 8;
  - four levels of the shaft's doctrine's research;
  - stable 100;
  - stratum 19;
  - 40M credits.
- **It opens:** the Frame Jig, machine level 9 (paid in Alloy and Components) and strata 20-24.
- **Core 9** is written out, designed and graph-checked but not played: 30,000 Frames, 100,000 Alloy, an Assembler driven 6 steps, eight doctrine levels, Drill 9, stable 120, stratum 24.

**5. The collapse keeps a foundation** (`Sim.foundation`).

- **The Core:** a new shaft's Core starts at half the best level any shaft reached. A collapse at Core 8 starts the next shaft at Core 4.
- **Kept:** the research tree, Cores, blueprints and the foundation.
- **Reset:** the board, credits, research points, depth, machine levels, Overdrive, the store, and the doctrine with its research.

**6. Blueprints** (`Sim.save_blueprint`, `blueprint_report`,
`lay_blueprint`, `fill_pending`; the Core card).

- **A slot saves the board:** every machine, with its mode and its job.
- **Laid in another shaft, it is checked first against that ground:**
  - machines not found yet;
  - tiles outside the yard or under rock;
  - tiles taken;
  - jobs not open yet;
  - with the whole blueprint standing on this stratum's rock, what would overheat or run cold.
  A key shows each flagged tile.
- **It goes down from each line's end.** A seller goes down with the maker that feeds it, and a maker only once something beside it takes what it makes. So what goes down first earns. The first version put a Drill down first, alone, and a played second shaft never earned a credit.
- **What cannot go down yet waits** for credits, ground or its job.
- Drafting Table, which sells blueprint slots, is back in the research grid.

### Played, after

The scripted player (`tools/core_journey.gd`) was extended for the era:

- it chooses a doctrine at Core 7;
- it retasks a Drill the rock overheats (one built for income alone) to the Deep Bore;
- it lays deep units (a Deep Bore, a White Heat Smelter, a Vault) away from the old chain;
- it lays research units (a Deep Bore, a White Heat Smelter, a Coolant Cell and a Lab);
- on hot rock it lays a line with a Coolant Cell where the rock has a machine at its edge, and prefers the jobs built for heat;
- it spends on repairs at most a fifth of what it earns;
- it keeps the Core's price once it has saved it;
- it keeps in the store what the Core's Overdrive and machine rows are paid in, so contracts and spare levels do not take it;
- it buys no spare level while something overheats;
- it goes a stratum down only while nothing overheats.

It is still a model: the numbers are its, not a person's.

**A new game, to Core 8** (Deep Survey):

| | before (a1) | after |
|---|---|---|
| Cores 1 → 7 | 6 h 55 min | 6 h 55 min (the same run: nothing before Core 7 changed) |
| Core 7 → 8 | not reached in 9 h 04 min | **1 h 55 min** (Core 8 at 8 h 50 min) |
| income over the stage | 8.39K/s → 2.82K/s on stratum 19; 2.8K/s average | 8.39K/s → 23.4K/s on stratum 19 (8 h) → 27.6K/s; 21.5K/s average |
| decisions | 803 in 296 of 546 minutes (384 machines sold) | 401 in 53 of 116 minutes (187 sold) |
| saving | 0% (nothing could be met) | 14% (16 min) |
| research made / spent | 506K / 526K, all on Overdrive | 17.5K / 341K: Overdrive 191K, doctrine 150K (Core 6's banked research) |

**Its rows, first met after** (stage start 6 h 55 min):

| row | met after |
|---|---|
| a doctrine's 4 levels | 14 s |
| 25,000 Alloy | 20 min |
| stratum 19 | 41 min |
| a Smelter driven 3 steps | 53 min |
| 50,000 Components | 1 h 11 min |
| stable 100 | 1 h 12 min |
| Smelter 8 | 1 h 25 min |
| 40M credits | 1 h 55 min |

The last two rows are credits (a level at 38M and the Core at 40M), met in
the half hour after the rest. That is the Core 7 model.

**The three doctrines, from the same Core 7 factory** (the new game's,
kept at 6 h 55 min):

| doctrine | Core 7 → 8 | saving | decision minutes | income, average | research made / spent | stable 100 met after |
|---|---|---|---|---|---|---|
| Deep Survey | 1 h 49 min | 2% | 41 of 110 | 25.0K/s | 16K / 366K (doctrine 150K) | 48 min |
| Heat Engineering | 1 h 47 min | 20% | 46 of 108 | 24.7K/s | 56K / 470K (doctrine 180K; Overdrive 290K, 9 steps) | 2 min |
| Precision Works | 1 h 52 min | 31% | 55 of 113 | 22.5K/s | 131K / 516K (doctrine 300K) | 56 min |

- **The pace is close, but each doctrine plays differently.** Heat Engineering met stability at once. Precision Works made eight times the research of Deep Survey (Lab Benches) and bought twice the doctrine levels. Deep Survey saved least: its deep chain paid the credits while the rest was met.
- **No doctrine is a trap,** and none is the only answer. That is the choice the brief asks for.
- **The Labs go quiet on the hot rock** in every doctrine. Research is paid from what Core 6 banked.

**The collapse at Core 8, and the second shaft** (a Deep Survey game,
collapsed the moment Core 8 was reached):

- **The collapse:** 154 Cores, the tree kept, a blueprint of 245 machines, and a Core foundation at level 4.
- **The blueprint, checked on the new shaft's ground:** 225 of its machines outside the yard, 5 ready, 15 that would run cold at stratum 0. It filled in as the yard grew.

| | first shaft | second shaft, after the collapse |
|---|---|---|
| Core 5 | 46 min | **13 min** |
| Core 6 | 1 h 20 min | **37 min** |
| Core 7 | 6 h 55 min | **2 h 32 min** |
| Core 8 | 8 h 50 min | **4 h 35 min** |
| Core 9 | -- | not reached in 11 h 54 min (Core 9 asks for Frames, which this player does not make) |

- **Why the second shaft is faster.** The foundation skips Cores 1-3, and the blueprint lays 200 machines in its first 13 minutes.
- **Where it still waits:** Cores 5 → 6 and 6 → 7 were 84% and 61% saving. The machine levels the rows ask for have to be bought again with credits, and the shaft's income there is the first shaft's.
- **Its Core 7 → 8** took 2 h 03 min. A first measurement of this second shaft stopped there for 13 h 53 min, because the player spent the Ingots and Plates of the Overdrive step the Core asked for on contracts and spare levels. It keeps them now.

**Tried and not kept: Standard Tooling.** The two saving stages above are
the pool's FP-19 (a) problem, and two answers paid in Cores were built and
played on the same second shaft:

- **Every machine type starts a shaft levels up.** The second shaft stayed at Core 5, with stability at 15-20 of 60, and income fell to 1.8K/s.
- **Every machine level costs 12% fewer credits a level.** The second shaft stayed at Core 5 for the six hours watched, stability 0 of 60.

Both failed the same way. A level is heat as well as speed. Cheaper or free
levels came before the lines laid for Cores 1-5 could take the heat, and on
stratum 12 those lines overheated where no Coolant Cell fits. What a
collapse keeps must not add heat before the layout can take it. The tree's
existing Core-priced line for heat, Ceramic Lining, already does the
opposite. Neither answer was kept; the second shaft's saving stages are
still open (`BENCHMARK.md`, section 11).

**Performance** (desktop, Intel UHD; the perf probe's late board: 308
machines, a headless tick, best of 5 × 300):

- before this round: 1.80 ms a tick;
- with jobs, every tile asking for its job: 2.32 ms;
- with what a machine takes worked out once per board (`Simulation._taker_candidates`): 1.78 ms.

The journey to Core 5 is the same to the last credit. A phone is still
UNKNOWN.

### What the deep strata do now

`tools/deep_lab.gd`, machines at level 7, the fixture's research.
Credits a second a tile:

| stratum | the Core 3 Assembler line, cooled | a block of Deep Bores, White Heat Smelters and Vaults | a Deep Bore's, and a White Heat Smelter's, cycles a second |
|---|---|---|---|
| 16 | 64 | 102 | 3.30, 3.85 |
| 17 | 64 | 102 | 3.62, 3.97 |
| 19 | 63 | 102 | 4.24, 4.19 |
| 21 | 63 | 102 | 4.85, 4.42 |
| 24 | 62 | 100 | 5.74, 4.76 |

- **Per tile, the deep block pays 1.6 times the old line and needs no cooling.**
- **Deeper, its machines are faster:** from stratum 16 to 24, +74% for the Bore and +24% for the Smelter.
- **Its per-tile income does not rise with depth,** because a Vault sells one buffer (six units) a cycle and is the limit. So depth pays in more outlets -- Vaults, Labs, the store -- which is a layout decision.

### Not done in this round

- **The second shaft saves for machine levels again** (84% and 61% of Cores 5 → 7). Two answers were tried and dropped (above).
- **Labs on deep rock.** Labs still go quiet on strata 17-19. Research units with a Coolant Cell help, but this player keeps few. The Core 7 era ran on the research Core 6 banked.
- **Core 8 → 9.** A second shaft at Core 8 was not in Core 9 after 11 h 54 min: Core 9's Frames need the Frame Jig, which the player does not lay, and its income fell from 26.2K/s to 17.6K/s on strata 23-24.
- **Core 9** is designed and graph-checked, not played; **Core 10 and up** are a formula.
- **No picture yet:** no ghost of a blueprint on the board, no mark for a tile's job, no Overdrive glow.
- **World nodes** still draw nothing (FP-18).

---

## Plan P0-P8

For each step: why, what it touches, what the player gains, and what it links.

- **P0 Foundation.** *Done in this slice.*
  - **Why:** a spine the other systems can hang on.
  - **Touches:** CoreLevels, Sim, Simulation, save.
  - **Player gains:** one number that says how far the factory has come.
  - **Links:** everything below.
- **P1 Core prerequisites.** *Done in this slice.*
  - **Why:** a level is proof, not a purchase.
  - **Touches:** the Core card, "What now?", Descend.
  - **Player gains:** a checklist of real factory goals.
  - **Links:** store, heat, research, depth.
- **P2 Machine and resource dependencies.** *Done in this slice.*
  - **Why:** upgrades need production, so old materials keep a use.
  - **Touches:** MachineDB levels, the store, the Vault as storage.
  - **Player gains:** medium goals between Core levels.
  - **Links:** the store and the Core's machine rows.
- **P3 Research gates.** *Done in this slice.*
  - **Why:** research is a gate, not a bonus menu.
  - **Touches:** the Lab (stratum 2, any material), Economy caps, research
    cards.
  - **Player gains:** research from the first session, and a reason to split
    material.
  - **Links:** the Core's research rows.
- **P4 Regional and depth gates.** *Partly done: the Core caps depth, and strata 16 and down hold crystal (the Deep Bore job).*
  - **Next:** strata bands with their own resources and nodes, for example
    the crystal and heat-vent nodes that are already on the map and unused
    (`ResourceNodes`).
  - **Touches:** Strata, BuildArea, ResourceNodes.
  - **Player gains:** "the next era", not a bigger number.
  - **Links:** new materials into store rows.
- **P5 Long-term.** *Core 8 and 9 written out (26 Sep 2026).*
  - **Why:** level 10 and up are a formula today.
  - **Next:** give levels 6-12 their own identities, with a new material or
    production layer each (one resource per era, never for length alone),
    each graph-checked before it ships.
  - **Links:** P4 and P6.
- **P6 Collapse integration.** *Partly done (26 Sep 2026): a Core foundation, blueprints and a doctrine chosen again.* See "Collapse" below.
  - **Why:** a collapse throws away the whole Core progression today.
  - **Next:** decide what a collapsed shaft keeps, for example a Core-level
    floor or kept machine levels, measured against the 4-hour pace.
- **P7 Blueprint integration.** *Done without ghosts or share codes (26 Sep 2026).* See "Blueprint" below.
  - **Why:** the scripted player rebuilds the same three Core lines every
    shaft.
  - **Next:** blueprints of Core lines, once P6 decides what a new shaft
    looks like.
- **P8 QA, balance and mobile.**
  - **Next:** a human playtest of the first hour on a phone; tuning the Core
    card's length on small screens; an analytics event per Core level (in
    the allowed vocabulary) to measure real pace.

## Collapse: where it conflicts with the new progression

(Recorded before the round of 26 September 2026, which answered the first
point with the Core's foundation: see "After Core 7".)

1. **A collapse resets everything the Core progression built.** The Core
   level, machine levels and the store all go. That is the "reset, start
   over" feeling the design warns against.
2. **Research is permanent.** A second shaft meets the research rows of Core
   levels 2-4 at once. This is the intended "stronger foundation", but it
   also makes those rows no longer rows.
3. **A collapse needs stratum 3, which is under Core 2.** The first collapse
   is possible about 12 minutes in and pays little.
4. **No Core row asks for Core-priced research** (the checker forbids it), so
   the permanent tree's Core-priced half stays outside the spine.

## Blueprint

Blueprint became a real need once a collapse kept a Core floor: a second
shaft starting at Core 4 has four levels' worth of lines to lay at once.
It is built (see "After Core 7"): a slot saves the board with every
machine's mode and job; laid, it is checked against the new ground and put
down as credits, the yard and the jobs allow.
