# Progression: the Factory Core's levels

The design source for Lodeworks' long-term progression. A feature that cannot
be connected to the graph below waits.

- Reference study: [`research/progression-reference.md`](research/progression-reference.md)
  (Clash of Clans, Boom Beach, Whiteout Survival and Rise of Kingdoms, with
  Township and State of Survival; official sources first).
- Code: `scripts/core/core_levels.gd` (the levels and the graph checker),
  `scripts/core/machine_db.gd` (machine levels, the store's capacity, the
  Lab), `scripts/core/economy.gd` (research opened and capped by the Core),
  `scripts/sim/sim.gd` (the store, paid upgrades), `scripts/sim/worklist.gd`
  ("What now?").
- Measured with `tools/core_journey.gd` (a scripted player on the real game);
  the numbers in this file come from the run named beside them.

Status, 25 September 2026: the vertical slice (sections 10 and 11) is built
and tested. Core levels 1-5 are measured with the scripted player; levels 6-8
are designed and graph-checked, but no played run has reached them yet. The
features that come next are in [`research/feature-pool.md`](research/feature-pool.md).

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
| **5 Research** | Strata 10-12: Condenser (stratum 10). Machine levels up to 6, store up to 8,389. | 10M credits; 2,500 Components and 2,500 Plates (Vault 5); 4 Labs at working heat; Assembler 5; Field Notes 2; Tighter Tolerances 6; 40 machines at working heat with none overheating; stratum 9 |
| **6 Amplification** | Strata 13-15. Machine levels up to 7. | 60M credits; 8,000 Components and 8,000 Ingots (Vault 6); a Duplicator serving 3; Tighter Tolerances 8; Drill 6; stable 60; stratum 12 |
| **7 Deep works** | Strata 16-19. Machine levels up to 8. | 1B credits; 25,000 Components and 25,000 Plates (Vault 7); a Condenser serving 3; Deeper Bore 6; Smelter 7; stable 80; stratum 15 |
| **8 The Abyss** | Strata 20-24. Machine levels up to 9. | 15B credits; 80,000 Components and 80,000 Plates (Vault 8); an Amplifier serving 4; Field Notes 5; Assembler 8; stable 100; stratum 19 |
| **9 and up** | 5 more strata each; machine limit +1 each. | Level 8's pattern, with rising numbers: credits ×15 a level; store ×2.2 (capped at what the Vault can then hold); stable +20; one production machine at the limit, rotating; one research line, rotating |

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
| Plate | Press (stratum 3, Core 2) | Assembler: 1 → 1 Component | Sold (11.5). **Store**: machine levels 3-9, Core levels 3, 4, 5, 7, 8. **Lab**: 0.5 research each | Core 3 |
| Component | Assembler (stratum 5, Core 3) | — | Sold (24). **Store**: machine levels 4-9, Core levels 4-8. **Lab**: 1.0 research each | Core 4 and later |
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
| Drill | stratum 0 | — | Ore | yes | level 4 (for Core 4), 6 (Core 6) |
| Crusher | 0 | 2 Ore | Gravel | yes | level 2 (Core 2) |
| Vault | 0 | anything | sells it | **its level is the store**: 25, 80, 256, 819, 2,621, 8,389… of each material | a level whenever a store row exceeds it |
| Smelter | 1 | Gravel, warmth | Ingot | yes | 2 at working heat (Core 2); level 3 (Core 3); level 7 (Core 7) |
| Boiler | 1 | — | heats its neighbours; material passes through | — | (makes the Smelter rows possible) |
| Coolant Cell | 2 | — | cools its neighbours; material passes through | — | (makes the Press and Assembler rows possible) |
| Lab | 2 | Ingot, Plate or Component | research: 0.25, 0.5 or 1.0 per cycle | yes | 4 at working heat (Core 5) |
| Press | 3 | Ingot, kept cool | Plate | yes | 2 at working heat (Core 3); level 4 (Core 4) |
| Amplifier | 4 | — | speeds its neighbours | — | serving 3 (Core 4), serving 4 (Core 8) |
| Assembler | 5 | Plate | Component | yes | 3 at working heat (Core 4); level 5 (Core 5); level 8 (Core 8) |
| Duplicator | 8 | — | sometimes doubles a neighbour's output | — | serving 3 (Core 6) |
| Condenser | 10 | — | cools hard, speeds a little | — | serving 3 (Core 7) |

**Machine levels.**

- **Credits:** 150 for level 2, then 12 times more each level (1,800, 21,600,
  259,200…), the same for every type.
- **Materials from the store:**
  - level 2: 10 Ingots;
  - level 3: 30 Plates and 30 Ingots;
  - level 4 and up: Components and Plates (90, 270, 810…).
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
| Tighter Tolerances (speed) | 1 | Research | level 1 (Core 2), 3 (Core 3), 6 (Core 5), 8 (Core 6) |
| Night Shift (offline hours) | 1 | Research + Cores | — |
| Deeper Bore (yield) | 2 | Research | level 2 (Core 3), 4 (Core 4), 6 (Core 7) |
| Standing Orders (offline rate) | 2 | Research + Cores | — |
| Drafting Table (blueprints; hidden) | 2 | Research + Cores | — |
| Refinery Contracts (value) | 3 | Research | level 2 (Core 4) |
| Ceramic Lining (heat tolerance) | 3 | Research + Cores | — |
| Seismic Survey (collapse yield) | 3 | Research + Cores | — |
| Field Notes (Lab output) | 4 | Research | level 2 (Core 5), 5 (Core 8) |

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
| 13+ | 6 and up | (new layers here are future work: P5) | 2.3+ | +1 ring every 3 strata |

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
reports **330 tests passed (126,679 assertions)**.

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

**Heat control on the hot strata** ([`research/feature-pool.md`](research/feature-pool.md),
FP-08 and FP-11). Played, the Core stops at the stability row from
stratum 12: something is always overheating.

- **What the player lacks:** a lever. Today a heat problem can only be
  solved by moving tiles.
- **FP-08:** machines that name their heat cause.
- **FP-11:** a Coolant and Boiler mode that trades output for heat.
- **Measured:** by the scripted player reaching Core 6.

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
- **P4 Regional and depth gates.** *Partly done: the Core caps depth.*
  - **Next:** strata bands with their own resources and nodes, for example
    the crystal and heat-vent nodes that are already on the map and unused
    (`ResourceNodes`).
  - **Touches:** Strata, BuildArea, ResourceNodes.
  - **Player gains:** "the next era", not a bigger number.
  - **Links:** new materials into store rows.
- **P5 Long-term.**
  - **Why:** level 9 and up are a formula today.
  - **Next:** give levels 6-12 their own identities, with a new material or
    production layer each (one resource per era, never for length alone),
    each graph-checked before it ships.
  - **Links:** P4 and P6.
- **P6 Collapse integration.** See "Collapse" below.
  - **Why:** a collapse throws away the whole Core progression today.
  - **Next:** decide what a collapsed shaft keeps, for example a Core-level
    floor or kept machine levels, measured against the 4-hour pace.
- **P7 Blueprint integration.** See "Blueprint" below.
  - **Why:** the scripted player rebuilds the same three Core lines every
    shaft.
  - **Next:** blueprints of Core lines, once P6 decides what a new shaft
    looks like.
- **P8 QA, balance and mobile.**
  - **Next:** a human playtest of the first hour on a phone; tuning the Core
    card's length on small screens; an analytics event per Core level (in
    the allowed vocabulary) to measure real pace.

## Collapse: where it conflicts with the new progression

(Recorded now, changed later: P6.)

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

Blueprint becomes a real need if the Core lines have to be rebuilt after
every collapse, and the scripted player shows that they do. It stays
quality-of-life until P6 decides what a new shaft keeps; if machine levels
or a Core floor survive, blueprints of Core lines become the obvious next
step.
