# Rise of Kingdoms: a reference study for Lodeworks (as of September 2026)

**How to read this.** Source keys are listed in section 6. Any number or fact without a source key comes from my own design judgement. That covers the columns Problem, Core, Fit, Adaptation, Depends, Challenges and Conflict. Treat those columns as **Inference** unless a cell carries a source key. I did not invent any numbers.

**Source quality.**
- **Official sites gave nothing I could fetch.**
  - rok.lilith.com and rok-club.lilith.com are rendered by JavaScript and returned no content.
  - riseofkingdoms.com returned HTTP 522.
  - rok.guide returned "Site Currently Unavailable".
- **Official facts therefore come from the two store listings.** The App Store page carries Lilith's own patch notes for 2026 in its version history.
- **The Fandom wiki API worked.** This differs from the HTTP 402 block recorded in `docs/research/progression-reference.md`. Many wiki pages date from 2019–2022, so their numbers may be out of date.
- **No files were modified.** I read `docs/PROGRESSION.md` and `docs/GAP-AUDIT.md` to use Lodeworks' own terms.

**Already covered (one line each):**
- The City Hall caps every building.
- Its prerequisites are the Wall plus one building that changes each level.
- The Academy is required at era boundaries.
- Resources arrive in stages: food and wood, then stone, then gold.

---

## 1. Overview of the game's structure

- **Modes**
  - **City:** City Hall levels 1–25, 15 civilizations, Academy research, troop tiers T1–T5, commanders, Blacksmith, Tavern.
  - **Kingdom map:** one shared map covered in fog, with barbarians, forts, gathering nodes, holy sites, passes and alliance territory.
  - **Shared kingdom timeline (the Monument):** leads into the Lost Kingdom / Kingdom versus Kingdom (KvK) seasons, Seasons 1–3, then the Season of Conquest "stories".
  - **Side modes:** Expedition, Sunset Canyon, Ark of Osiris, Ceroli Crisis, Lyceum quiz, Karuak, Shadow Legion.
  - **Live events:** a dense calendar [OFF-GP][F:Events][RG-HA][OFF-AS].
- **"The Lost Crusade"**
  - This is the game's subtitle on Google Play ("Rise of Kingdoms: Lost Crusade") [OFF-GP].
  - The Lost Kingdom's lore uses crusade terms: Eve of the Crusade, crusader flags, camps and fortresses [F:Lost_Kingdom][F:Lost_Kingdom_Chronicles].
  - **UNVERIFIED:** I found no separate mode called "The Lost Crusade".
- **Loops**
  - **Minute:** refill the timed queues, spend Action Points (AP, the game's energy) on barbarians, send out gatherers.
  - **Day:** daily objectives and activity chests, the VIP login chest, free Tavern chests, Expedition claims, alliance help.
  - **Week:** Mightiest Governor, Ark of Osiris, Sunset Canyon seasons, Ceroli Crisis.
  - **Season:** the timeline, 50-day KvK, the quarterly Zenith of Power.
- **Currencies**
  - Resources: food, wood, stone, gold. Premium: gems.
  - AP, VIP points, silver, golden and crystal keys.
  - Commander, starlight and universal sculptures; tomes of experience.
  - Alliance and individual credits; Expedition medals, canyon coins, Ceroli medals, season coins and crystals.
  - Iconic crystals; transmutation, conversion, swapping and honing stones; Sage's Testimony; event tokens [F:Items/Key][F:Expedition][TSG-FORM][OFF-AS][RG-HA][RG-ICON].
- **What transfers to Lodeworks (Inference)**
  - What transfers: a visible long timeline that unlocks systems; a fogged world with one-time and permanent discoveries; identity choices with free respec; a crafting ladder that turns surplus into power; many "nothing is lost" rules.
  - What does not: RoK's retention machinery (dailies, streaks, rankings, gacha, energy, timers). Lodeworks already rejects all of it.

---

## 2. Feature inventory

**Column key:**
- **Core** = what the feature adds to the moment-to-moment loop.
- **Related** = RoK rows it depends on or reinforces (row numbers).
- **Depends** = the Lodeworks systems it needs.
- **Decision codes** (recorded in GAP-AUDIT):
  - **D1:** more currencies, refused as a content treadmill.
  - **D2:** daily/weekly chores and streaks, refused.
  - **D3:** multiplayer, leaderboards, anything needing a server, refused.
- Where a row is marked "conflicts with an existing decision", it hits one of these.

### 2.1 Core loop & sessions
| # | Feature | What it is | Problem / adds | Core | Related | Src | Fit | Adaptation (Lodeworks) | Depends | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Parallel timed queues | 1 builder queue (a 2nd via item or VIP 6); 1 Academy research; training; healing; gatherers keep working offline | Each visit offers several independent choices | Refill every idle queue | 23, 39, 97 | F:Builder_queue, F:Resources, F:VIP | ADAPT | Keep "several parallel next steps" without timers. The Worklist shows up to 3 goals of different kinds (upgrade, research line, depth or survey) | Worklist | Ranking goals across kinds; clutter on a small screen | Copying timed queues literally = timers as gates |
| 2 | Action Points (energy) | Cap of 1,000, regenerates. A barbarian attack costs 50; each chained attack costs 2 less; travel costs 20 | Rations PvE, sells potions | Bursts | 53, 38 | F:Governor_Profile, F:Barbarians, TSG-FORM | REJECT | — | — | — | Energy is banned by the vision |
| 3 | One map, "infinite zoom" | One huge map; free zoom from the world down to a city, with no separate battle screen | The base feels part of a world | Zoom out to spot opportunities | 40, 48 | OFF-GP | ADAPT | One continuous camera: a single machine → the 44×44 board → the world ring (crystal fields, seams, vents) → optionally the shaft section | Camera; drawing the ring; Survey (40) | Level of detail and culling in Godot; legibility at full zoom-out on a phone | — |

### 2.2 City building & layout (city/region development)
| # | Feature | What it is | Problem / adds | Core | Related | Src | Fit | Adaptation | Depends | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 4 | Free placement, roads, decorations | Buildings placed anywhere; roads, trees and statues sold in the build menu; the layout does not affect defence | Ownership, self-expression | Low | 5, 103 | F:Buildings, HG-CITY | LATER | Decoration only on tiles no machine can use (the yard edge, the ring). Earned, never bought | Board tile rules, Ledger | Adjacency must ignore decoration; art volume | Decoration on functional tiles would fight the adjacency puzzle |
| 5 | City Editor with layout slots | Open the editor → pick a slot → rearrange buildings, roads and decoration → preview → save → apply. The layout does not change combat strength | Re-layout without dragging each building | Fast rebuild | 86 | HG-CITY | **ADOPT** | This is the precedent for the pending Blueprint screen (GAP-AUDIT A1): named slots, a ghost preview, "apply" places what is affordable and lists what is missing, heat warnings per stratum | `Sim.blueprints` (saved, unused), placement validation, Codex mini-boards | Partial apply when short of stock; heat varies by stratum; save migration | None, as long as slots are not an economy lever |
| 6 | Obstacles to clear | Main quest "Space Clearance: clear 5 trees in the city" | Early micro-goals | Tiny early actions | 74 | F:Quests/Main_Quest_Line | LATER | Rubble tiles at the yard edge, cleared with Gravel or credits; some hide a one-time find (44) | Board generator, Survey | Must never block the first half hour | — |
| 7 | A new building or system per level | Scout Camp from City Hall 2, Achievements 6, Monument 9, Lyceum 10 | A drip of novelty; each level teaches one verb | New verbs | 26, 64 | F:Buildings/Scout_Camp, F:Achievements, F:Buildings/Monument, F:Buildings/Lyceum_of_Wisdom | **ADOPT** | After depth 10 no machine is new (GAP-AUDIT E1). Let Core levels 3+ each open a *system*: Survey, Chronicle, Charter, Crystal Works, Fittings, Trials | `core_levels.gd` graph, Foreman | The graph checker must also cover system unlocks | — |
| 8 | Level-up reward mail | Each City Hall level mails a gift. Level 10 = a free Civilization Change; level 25 = a Master's Blueprint + 500 gems | Marks the moment; seeds the next system | Punctuation | 12, 9 | F:Buildings/City_Hall/Rewards | **ADOPT** | The Core level-up card names a gift tied to the new system: a Charter switch token, a first Fitting blueprint, a survey chart | Level-up card | Keep gifts from breaking BALANCE | — |
| 9 | Era Breakthrough | A permanent event from City Hall 4, paying at levels 4, 7, 10, 13, 16, 19, 21, 23, 25 | A long, visible target | Medium goal | 8, 64 | F:Events/Era_Breakthrough | ADAPT | Fold into the Chronicle (64) as Core milestones | Chronicle | — | — |

### 2.3 Specialisation (civilizations, talents)
| # | Feature | What it is | Problem / adds | Core | Related | Src | Fit | Adaptation | Depends | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 10 | Civilization choice | 15 civilizations. Each has its own architecture, starting commander, special unit and 3 perks (Spain: +20% resource production, +10% experience from neutral units, cavalry defence). The wiki says none is "necessarily better" | A meaningful first choice with no wrong answer | Colours every later choice | 11–13 | OFF-GP, F:Civilizations | **ADAPT** | **Charter** picked at the start of each run: 4–6 charters, each with 3 small perks aimed at a strategy (Thermal, Throughput, Deep, Survey) plus one variant machine (11). The first run uses a default until the first collapse | Collapse flow, balance, journey lab | Balance across 12 strata modifiers; journey-test every charter | — |
| 11 | Civ-specific unit | A unique unit replaces a generic line (Legionary for Long Swordsman, Chu-Ko-Nu for Crossbowman) | A visible signature of the choice | Changes one piece | 10 | F:Technology | ADAPT | Each Charter swaps one machine for a variant with a different heat/output profile, the same footprint and the same place in the chain | Machine DB, heat model, art | Balance and art multiply; start with 2 charters | — |
| 12 | Civilization change | An item. Free as the City Hall 10 reward, otherwise 10,000 gems or 2M credits. Unique troops convert automatically | No fear of an early wrong pick | — | 10 | F:Items/Civilization_Change, F:Buildings/City_Hall/Rewards | **ADOPT** | Charter free to change at every collapse, plus one mid-run switch token as a Core level gift (8); variant machines convert in place | Charter, save | Safe re-evaluation of heat mid-run | A paid respec would break "purchases never change an economy number" |
| 13 | Architecture per civ × Age | The City Hall and buildings are drawn per civilization and per Age | Visual payoff | — | 10, 26 | F:Civilizations/Arabia, F:Buildings | LATER | A trim/tint set per Charter, not full redraws | art_src, palette | Art multiplies (charters × eras × 12 machines) | — |
| 14 | Commander talent trees | Each commander has 3 of 15 specialties: red = troop type, yellow = role, blue = combat. Max level 60, 74 talent points; only the primary commander's talents count | Deep build identity; one unit, many roles | Spend points between visits | 15, 29, 30 | F:Commanders, F:Commander_Guide, RG-TAL | ADAPT | **Machine specialisations** per machine *type*: 3 branches from a shared pool (Yield, Cool-running, Heat-tolerant, Throughput, Synergy, Survey). Points come from mastery by use (29) | Machine DB, lifetime counters, Codex | Effects must use existing sim terms; tree UI in landscape; cap at ~5 nodes per branch | — |
| 15 | Talent reset and recommended builds | Talent Reset is bought with gems. Official commander guides in the game show "recommended talents" (a 2026 patch fixed their point counts) | Experiment without fear; guidance | — | 14 | F:Items/Talent_Reset, OFF-AS | **ADOPT** | Free, instant respec; each Codex machine page recommends a branch and says why | 14, Codex | — | Paid respec rejected |
| 16 | Primary + secondary commander | The secondary adds only its skills, not its talents | Combinations from a small roster | Pair choice | 14 | F:Frequently_Asked_Questions, RG-TAL | LATER | Lodeworks already pairs by adjacency. Name the best pairs as "pairings" in the Codex, with a small bonus when the condition is met | Adjacency engine, Codex | No hidden rules; badges on tiles | — |
| 17 | Formations and armaments | About 14 formations (e.g., Line: +10% gathering). 4 armament slots per formation, with random stats. Epic armaments get 1 inscription, Legendary 2. Transmutation stones reroll stats. Honing adds +0.2% per step, to +3.5%. Wishlist plus guaranteed-drop progress | Another build layer | Setup | 38, 36 | TSG-FORM, OFF-AS | ADAPT (patterns) / REJECT (random stats) | **Patterns:** recognised adjacency shapes (a Smelter ringed by Coolant Cells; Drills in a line along a seam) light up in the Codex with a named bonus. Deterministic and discoverable | Adjacency engine, Codex | Detect shapes incrementally on place/remove on 44×44; explaining shapes on a phone | Random stats and rerolls are gacha-like |

### 2.4 Economy, currencies & sinks (production & trade)
| # | Feature | What it is | Problem / adds | Core | Related | Src | Fit | Adaptation | Depends | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 18 | Map gathering and gathering specialists | Troops gather at map nodes, including offline; low-rarity gathering commanders and the Line formation raise the speed | Income outside the base | Send and forget | 19, 40 | F:Resources, F:Commander_Guide, TSG-FORM | ADAPT | Surveyed seams and crystal fields in the ring become harvestable by a machine at the board edge (possibly a Drill variant, not a 13th machine); output joins the chain | Survey, ring data, edge-tile rule | Edge placement rules; keep the roster lean | D1 risk if crystals turn into a shop currency. Keep them a machine input |
| 19 | Territory income | Territory enclosing a node's centre claims it; members get 50% of its hourly yield | Passive land income | — | 50 | F:Territory | ADAPT | Merge into Claims (50) | — | — | The multiplayer part conflicts with an existing decision (D3) |
| 20 | Raw vs item resources, plunder | Raw resources can be plundered; resources held as items cannot and have no cap; the Storehouse protects part | Risk management under player attack | — | 35 | F:Resources, F:Buildings/Storehouse | REJECT | — | — | — | No stealable resources |
| 21 | Production capacity, tap to collect | Farms produce per hour up to a cap and must be collected | Brings players back | Tap chore | — | F:Buildings/Farm | REJECT | Lodeworks already banks offline production | — | — | Punishes absence (the spirit of D2) |
| 22 | Special PvE inputs for upgrades | The Castle needs Books of Covenant, from barbarian forts; the Watchtower needs Arrows of Resistance | Gives PvE a hard, non-substitutable purpose | Links loops | 44, 48 | F:Items/Book_of_Covenant | **ADAPT** | One Core requirement row per level band needs a ring input (a vent sample, a crystal), so exploration joins the Core checklist | Core requirements, Survey | Must be reachable without luck; `CoreLevels.validate()` must prove no cycle | RoK sells these for gems. Never purchasable |
| 23 | Speedups and timed boosts | Universal and typed speedups; 8-hour production boosts; "Finish Now" auto-picks speedups | Monetises waiting | — | 1 | F:Items/Speedup, F:Items/Food_Boost, OFF-AS | REJECT | — | — | — | No timers, no paid speed-ups. Rewarded-video "boosts" would reintroduce timers |
| 24 | Mysterious Merchant and Trading Post | The merchant arrives at 0:00 UTC and more often after activity, with 16 discounted items and paid refreshes. The Trading Post ships resources to allies with a tax | Discount hooks; social trade | — | — | F:Buildings/Courier_Station, F:Buildings/Trading_Post | REJECT | — | — | — | A rotating shop is FOMO; trade conflicts with an existing decision (D3) |
| 25 | Currency sprawl | Keys, sculptures, tomes, medals, canyon coins, season coins, crystals, iconic crystals, various stones, Sage's Testimony, credits | Many parallel chases | — | — | F:Items/Key, F:Expedition, OFF-AS, TSG-FORM, RG-HA | REJECT | Every adaptation here reuses Ore→Component materials and the ring's crystals | — | — | Conflicts with an existing decision (D1) |

### 2.5 Progression (Ages, units & characters, research, equipment)
| # | Feature | What it is | Problem / adds | Core | Related | Src | Fit | Adaptation | Depends | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 26 | Ages as visual eras | Stone → Bronze (City Hall 4) → Iron (10) → Dark (16) → Feudal (21). The city's look changes; Feudal is the last full change. Achievements and timeline goals count "entering" an age | A level-up you can see | Big moment | 13, 64 | RG-AGES, F:Feudal_Age, F:Achievements, F:Buildings/Monument | **ADAPT** | Eras by Core band (e.g., timber & steam → iron → electric → atomic): the ground, the Core's shell and machine trims change; each era titles a Chronicle chapter | Art, level-up event, Chronicle | Art × 12 machines. Limit to the Core shell, ground and palette; keep machine silhouettes stable | — |
| 27 | Research trees in tiers | Economic tree 13 tiers, military 14; the Academy's level gates techs; research unlocks troop tiers and civilization units | A clear tech ladder | Research choice | 28 | F:Technology, F:Buildings/Academy | ADAPT (light) | Show the Lab tree in tier rows by Core level with prerequisites drawn; let a few nodes unlock machine variants or Patterns rather than only percentages | Lab UI, `economy.gd` | Tree space in landscape | — |
| 28 | Troop tiers and upgrading in place | T1–T5. Troops can be upgraded; total cost equals training the higher tier directly; events score the point difference | Old units are never dead weight | Upgrade, don't replace | 106 | RG-TROOP, F:Events/The_Mightiest_Governor | **ADOPT** | **Refit:** any machine can be raised to the current cap in place for the difference only, plus "Refit all of type" (95) | Machine levels, paid upgrades in `sim.gd` | Show the difference clearly | — |
| 29 | Commander experience from use | Commanders gain experience from barbarians, forts and guardians; also from tomes | Units grow by being used | Play → growth | 14 | F:Commanders/Experience, F:Items/Tome_of_Knowledge | ADAPT | **Mastery by use:** each machine type accumulates lifetime mastery from items processed, feeding specialisation points (14). Kept across collapses | Save counters | Pacing against the permanent tree | — |
| 30 | Skills by star; capstone skill | 4 skills unlock by star. Epic and Legendary commanders get a 5th "mastery" skill once all four are at level 5 | A finish line per unit | — | 14 | F:Commanders | LATER | When all of a type's branches are complete, a capstone upgrades one existing effect | 14, 29 | Late tuning | — |
| 31 | Upgrades by luck | Starlight sculptures add luck to star upgrades; sculptures level a random skill | Stretches the chase | — | 105 | F:Items/Starlight_Sculpture, F:Items/Commander_Sculpture | REJECT | — | — | — | Random progression, close to gacha |
| 32 | Blacksmith: blueprint + materials | Unlocks when the first equipment is received. Forging = blueprint + materials + gold (a Legendary weapon costs 10,000,000 gold). A blueprint = 30 fragments | A crafting chase that uses surplus | Crafting | 33–36 | F:Buildings/Blacksmith | ADAPT (LATER) | **Fittings:** one slot per machine, forged at the Assembler from Plates, Components and crystals. Blueprints come from discoveries (44, 45), never random drops | Assembler, Survey, Codex | A per-instance layer on a small screen; balance against Core caps | Must reuse existing materials, or it conflicts with an existing decision (D1) |
| 33 | Material quality ladder | 5 qualities. 4 identical combine into 1 of the next quality; 1 dismantles into 4 lower (costs gold) | No dead drops; a sink | Convert surplus | 32 | F:Buildings/Blacksmith, F:Buildings/Blacksmith/Combining_Materials | ADAPT | Lodeworks' chain *is* the ladder: refining is machine processing, not a menu | Chain | — | A combine menu adds a currency layer (D1) |
| 34 | Equipment sets | "Forest Guardian": 2 pieces = +20% troop load; 4 pieces = +5% extra gathered resources | Coherent builds | — | 32 | F:Buildings/Blacksmith | ADAPT | The set bonus applies when *adjacent* machines carry fittings of the same set, which turns sets into an adjacency puzzle | Adjacency, 32 | Tile markers | — |
| 35 | Special talent (+30% if matched) | A forged piece may roll a "special talent"; it is worth +30% if the commander's red specialty matches. Resetting it costs gems (2026 event) | Matching gear to unit | — | 14 | F:Buildings/Blacksmith, OFF-AS | ADAPT | Deterministic: the player forges a fitting *for* a named machine type and it gets +30% there | 32 | — | Random roll and paid reset rejected |
| 36 | Late gear growth | At most six iconic crystals obtainable; iconic stats grow with the kingdom's season (1/2/3). Equipment "awakened up to Tier 5". Armament honing to +3.5% | An endgame sink; old gear scales | — | 32 | RG-ICON, OFF-AS | LATER | "Temper" a fitting a few fixed steps with surplus Components; its bonus scales with the Core level | 32 | Balance ceiling | Scarce, event-only crystals rejected |
| 37 | Research that lasts one season | In the Heroic Anthem KvK: a season-only Crystal Mine produces crystals and a Crystal Research Center spends them on season tech plus seasonal currency. Players "won't be able to unlock all" | Fresh, bounded choices each season | Strategy within a run | 51, 52 | RG-HA | **ADAPT** | **Crystal Works:** a research tree for the current run, fed by crystals from the ring's fields. It resets at collapse and is too big to finish in one run, so each run picks a path. The permanent Lab tree is untouched | Crystal fields, 18, collapse | Two trees can confuse (distinct colour and place); reset value vs Cores | Seasonal currency and paid crystal supply conflict with an existing decision (D1) |
| 38 | State Forum: travel and dispatch | Travel costs 20 AP (×10 for 200). From level 10, "dispatch" a team to fetch a chosen reward; meeting all requirements makes success near-certain; duration depends on rarity; 15 dispatches = a guaranteed chest; choose 3 preferred formations | Idle rewards with agency | Pick → send → collect | 17 | TSG-FORM | ADAPT | **Commissions** without timers: 3 offers with explicit conditions ("3 Presses at level 4 at working heat, deliver 50 Plates"); pays when met; offers refresh with *progress* (Core level or stratum), not by day | Worklist data | Fair requirements per stratum; no chore feel | Daily chances, AP and timers conflict with an existing decision (D2) |
| 39 | VIP permanent buffs | The wiki table runs to VIP 18 (production up to ×1.65); VIP 6 = second builder | Monetised power | — | 115 | F:VIP | REJECT | — | — | — | Pay for power; streak (D2) |

### 2.6 Map, fog & exploration
| # | Feature | What it is | Problem / adds | Core | Related | Src | Fit | Adaptation | Depends | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 40 | Fog with a frontier rule | The kingdom is about 1,200 km square: 400×400 = 160,000 fog blocks. Only blocks bordering cleared fog can be scouted; scouts path around obstacles they cannot see | Curiosity; the world is earned | Scout → discover → act | 41–48 | F:Kingdom, F:Scouting | **ADAPT** | **Survey:** the ring starts fogged and its frontier grows from the yard edge. Progress is *paid by production* (Components delivered to a Survey tile/post, or survey charges from the Core), so it works offline and never waits on a clock | Ring data, fog layer, save | Fog render (TileMap layer or shader) at every zoom; seeded determinism; offline accrual | Clock-based marches would be timers |
| 41 | Scout Camp scaling and % meter | Starts with 1 scout and a 5×5 range; at most 3 scouts, 15×15, +125% speed. The camp shows % of fog cleared | Visible growth; a completion drive | — | 40 | F:Scouting | **ADOPT** | Survey reach grows with the Core level; the Codex shows "% surveyed" per ring band | 40 | — | — |
| 42 | One-tap Explore | "Explore" auto-picks the nearest unexplored block | Casual-friendly | — | 40 | F:Scouting | **ADOPT** | "Survey next" picks the nearest frontier cell, visible landmarks first; long-press to aim | 40, Worklist | — | — |
| 43 | Scouting Report | One message lists every discovery with "NEW!" tags and "Visit" buttons, updated in place | Nothing gets lost | — | 40, 94 | F:Scouting | **ADOPT** | A **Discovery log** Codex page: NEW badges, "Go" jumps the camera, claimed/unclaimed state | Codex, camera | — | — |
| 44 | Tribal villages (one-time gifts) | Rewards: 50 T1 troops, tomes, 5-minute speedups, kingdom maps, and rarely a level of economic tech (tiers 1–3) | Instant payoff; shortcuts research | A dopamine hit per reveal | 40, 27 | F:Tribal_village, F:Scouting | **ADOPT** | **Abandoned workings:** a one-time payout of credits/materials, a Fitting blueprint, or a free level of a Lab research line | 40, Lab | Reward tables per band | — |
| 45 | Mysterious caves (tiered, finite) | 3 levels; per kingdom about 220 low, 120 medium and 60 high; no risk to scouts | Rarity tiers | — | 44 | F:Items/Treasure_of_Cave, F:Scouting | ADAPT | Three tiers of **deep finds** per band, finite and seeded, better further out | 40 | — | RoK's random drop tables → fixed contents per tier |
| 46 | Landmarks visible through fog | Scouts know where passes and holy sites are before seeing them; revealing one clears a larger area around it | Gives exploration a direction | Aiming | 40 | F:Scouting | **ADOPT** | Vents and fields show as faint silhouettes in the fog; surveying one reveals its surroundings | 40 | — | — |
| 47 | Kingdom Map item | Clears a random 10×10; when all fog is gone, unused maps convert to 5-minute speedups | Bursts of reveal; no waste at the end | — | 111 | F:Items/Kingdom_Map | ADAPT | "Survey charts" as Core gifts reveal a *chosen* area; leftovers convert to credits once the ring is fully surveyed | 40, 8 | — | — |
| 48 | Holy sites: distinct, non-stacking buffs | Sanctums (e.g., +10% commander experience), Altars (+5% building speed, +10% production…), Shrines; buffs of the same type do not stack | Rewards spreading across *kinds* | Target choice | 22, 50 | F:Holy_Sites | **ADAPT** | **Site bonuses:** a surveyed vent, field or seam gives a distinct yard-wide bonus when a machine touches it (vent: heat for Boilers; field: crystals). Duplicates don't stack | Ring, heat model | Edge adjacency; vents vs Boiler balance | — |
| 49 | Zones and passes | Tier 1/2/3 zones separated by passes; zones open after timeline events | A staged world | — | 64 | F:Kingdom, F:Holy_Sites | ADAPT | Ring bands open by Core level, mirroring the depth cap | Core caps | — | Clock-based opening rejected |
| 50 | Territory chain | Flags must connect to a fortress; territory must touch a target to attack it | Expansion as a spatial puzzle | — | 19, 48 | F:Territory | LATER | **Claims:** a chain of cheap relay tiles from the board edge to a surveyed node claims it | 40 | Connectivity check; clutter | — |
| 51 | Fog returns each season | In Heroic Anthem, fog is cleared again to find the season's buildings | Late exploration stays fresh | — | 37, 52 | RG-HA | **ADAPT** | Each collapse re-rolls and re-fogs the ring; permanent finds (blueprints, research levels) stay | Collapse, seed | Fair seeds; save size | — |
| 52 | Bastions | Found in the fog; levelled by quests (15 a day; an accepted quest can't be cancelled; 14-hour wait); at level 6 a commander skill becomes a support skill. 2026 story: up to 3 unlockable, equip 1 | Late, choice-rich collection | — | 51 | RG-HA, OFF-AS | ADAPT | **Derelict works** in the ring: repair with materials (a sink) to unlock one of 3 support effects for the run; equip 1 | 40, collapse | Effect design | Daily quests and lockouts conflict with an existing decision (D2) |

### 2.7 PvE (combat, brief)
| # | Feature | What it is | Problem / adds | Core | Related | Src | Fit | Adaptation | Depends | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 53 | Barbarian ladder; search spawns a target | Level N+1 opens after beating N; the kingdom-wide maximum rises over days; searching for level ≤12 spawns one next to the city | Always a fitting target | — | 64 | F:Barbarians | ADOPT (the principle; it already exists) | The Worklist already guarantees a doable step. Keep "never an empty search" for Survey and Commissions | Worklist | — | — |
| 54 | Forts: reward by share; failure eases | Forts need rallies; rewards scale with damage dealt; after a failed attempt the troops needed go down | Failure stays productive | — | 58 | F:Fort, F:Barbarians/Fort/Rules | ADAPT | After a failed Trial, show the exact shortfall and ease the target slightly | Trials | — | Rallies conflict with an existing decision (D3) |
| 55 | Expedition | Staged AI battles, 1–3 stars. Uses troops even if deployed, with no hospital losses. Rewards once a day per mission; 3-star missions can be claimed daily without replaying. Allowed marches rise from 2 (stage 6) to 5 (stage 41). Medal Store | Solo, risk-free content; old stages keep paying | Short puzzles | 56, 58, 112 | F:Expedition | **ADAPT** | **Trials** (AUDIT C2): fixed-seed boards with 3 star goals (output target / never overheat / ≤N machines). Stars give a *permanent* small perk, played on a copy of the board | Sandbox sim, seed, Ledger | A second sim instance on a phone; content authoring | A daily claim would be a chore (D2) |
| 56 | Sunset Canyon | Everyone gets the same T3 troops; only commander gear, skills and talents count; 10 formation slots; 5 armies; 5 free attempts a day, more with tickets; 7-day ranked seasons | Skill over size | — | 55 | RG-SC | ADAPT | Trials with an **equal kit** (fixed machines, no permanent bonuses): pure layout puzzles | 55 | — | Attempts, tickets and the ladder conflict with existing decisions (D2/D3) |
| 57 | Ceroli Crisis | A co-op boss raid (you + 3): 5 bosses, 5 difficulties with power minimums, roles, telegraphed danger zones, medals for a shop. Opens at City Hall 10 (SN) | Readable threats | — | — | RG-CER, SN | REJECT (co-op) / LATER (telegraphs) | Borrow only the warning: a stratum hazard shows the affected cells before it acts, and only while the player is watching | Strata modifiers | Must never punish offline | Co-op conflicts with an existing decision (D3) |
| 58 | Karuak Ceremony | Pick a difficulty at the start (Easy → Hell); 50 waves; an elite every 10th; the final reward = the highest level completed | Self-chosen difficulty; reward by best result | — | 55 | F:Events/The_Karuak_Ceremony | **ADAPT** | **Deep run:** optionally stack extra strata modifiers before a run; the collapse pays a bonus by the deepest stratum reached with that stack | Collapse, modifiers | Collapse payout is still waiting on the owner | — |
| 59 | Lohar's Trial / Arms Training | Kill barbarians for necklaces → chance of relics → summon Lohar for 2 h → rally. 2026 "Arms Training": Lohar gets stronger with each battle | Boss chase | — | — | F:Events/Lohar's_Trial, OFF-AS | REJECT / ADAPT the escalation | An endless Trial whose target rises with each clear | 55 | — | Random relics and time windows |
| 60 | Shadow Legion Invasion | Started by the alliance leader: 25 waves at every member's city over about 50 minutes | Base-defence spike | — | — | F:Events/Shadow_Legion_Invasion | REJECT | — | — | — | Attacks, co-op (D3) |
| 61 | Ark of Osiris | 30 vs 30 for 1 hour; troops don't die permanently; up to 2,500 gems per Golden win (guide); replays added in 2026 | PvP without losses | — | 112 | GG-AOO, OFF-AS | REJECT | Keep only "no-loss" (112) and "replay" (73) | — | — | D3 |
| 62 | Guardians and runes | Guardians spawn at 00:00 and 12:00 UTC for 11 h and drop runes (temporary buffs up to 20%) | Timed PvE | — | — | F:Holy_Sites, F:Runes | REJECT | — | — | — | Wall-clock spawns; temporary buffs |
| 63 | Real-time combat, counters, hospital | A 5% counter triangle; badly wounded troops go to hospital or die depending on context; a full hospital means deaths | — | — | — | F:Commander_Guide, F:Buildings/Hospital | REJECT | No combat; strata modifiers already create "counters" between machine types | — | — | — |

### 2.8 Events & live-ops
| # | Feature | What it is | Problem / adds | Core | Related | Src | Fit | Adaptation | Depends | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 64 | **Kingdom timeline (Monument)** | Built at City Hall 9. Every kingdom runs the same ordered timeline, fully visible once built. Each event has a kingdom, alliance or governor goal ("20,000 governors enter the Bronze Age", "explore 30,000,000 fog blocks together", "defeat 200,000 barbarians"), a reward and an unlock (forts L1–5, sanctums, altars, passes L1–3, shrines, the Lost Temple, "clear all fog"). Events change at 0:00 UTC | The long game becomes legible and paced | Anticipation | 65, 49, 26 | F:Buildings/Monument | **ADAPT (key)** | **Chronicle**, a personal version: ~20 chapters visible from Core 2. Each = a goal ("survey 25% of band 1", "3 Smelters at working heat", "reach stratum 12") + a reward + an unlock (usable vents, ring bands, Trials, Charters, Crystal Works). Unlocks are keyed to *progress* (Core level, depth, collapses), never dates | Core graph, Worklist, Foreman chapters, Codex | Extend `CoreLevels.validate()`; avoid duplicating the Worklist | Date unlocks = timers; a shared schedule needs a server |
| 65 | Chapters unlock regardless | In the Lost Kingdom the next content activates "whether or not the objective is achieved"; the reward depends only on the goal | The schedule never stalls | — | 64 | F:Lost_Kingdom_Chronicles | **ADOPT (principle)** | Each Chronicle chapter has a **gate** (progress) and a separate **bonus goal** measured as "before stratum N"; missing the bonus never blocks | 64 | — | — |
| 66 | Content by world age | Some events open only where all kingdoms are at least 21 days old; rewards vary by season; iconic stats scale by season | Content fits the world's maturity | — | 64 | OFF-AS, RG-ICON | ADAPT | Scale ring rewards, Commissions and Trials by *run age* (depth) and *account age* (collapses) | Counters | — | Calendar age rejected |
| 67 | Mightiest Governor | 6 daily scoring stages (Mon–Sat), ranked; the top 50 get legendary sculptures (180 for 1st in the wiki) | Spending spikes | — | — | F:Events/The_Mightiest_Governor | REJECT | — | — | — | Leaderboard plus timed; conflicts with existing decisions (D2, D3) |
| 68 | Power and activity events | Tiles & Bricks, Boundless Wisdom, Clarion Call, Strategic Reserve (random supply boxes, ranked), and others | The same verbs re-sold | — | — | F:Events, F:Events/Strategic_Reserve | REJECT | — | — | — | Treadmill, ranks, random boxes (D2, D3) |
| 69 | Zenith of Power | Continent-wide power race about every 3 months. The prize skin carries a real buff (+20% infantry attack; one September run: +16% troop attack, +5% AP recovery). Top 20 keep it for good; top 100 for 15–30 days | Draws big spenders | — | 100 | HB-ZEN, OFF-X | REJECT | — | — | — | Leaderboard; stats on cosmetics |
| 70 | Holiday series and mini-games | Halloween, Qixi, Spring Festival, World Cup; jigsaw races, fishing, mural "restoration" | Calendar hooks | — | — | OFF-AS, F:Events | REJECT | — | — | — | Live-ops FOMO; often server-bound |
| 71 | 7-day new-player event | Quests for 7 days; on day 8 they lock and chests depend on quests done; "Emblems of Loyalty" are spent in the "Hero Returns" exchange | Early guided goals | — | 74 | F:Events/Rise_of_Kingdoms, F:Events/Hero_Returns | REJECT | The Foreman's first chapter already does this without a clock | Foreman | — | Time-limited (D2) |
| 72 | Lyceum quiz and newspaper | A monthly scheduled trivia contest with a gem pool; a newspaper for 1,000 gold that sometimes gives buffs | — | — | — | F:Peerless_Scholar, F:Buildings/Lyceum_of_Wisdom | REJECT | — | — | — | Scheduled, random |
| 73 | Yearbook | Anniversary 2026: "RoK Yearbook: look back on your journey" | Memory, attachment | — | 104 | OFF-AS | **ADAPT** | A **Run report** at each collapse (deepest stratum, items made, time) + a lifetime **Logbook**; a shareable image | Save counters, collapse card | Cheap counters | — |

### 2.9 Quests, chapters & guidance
| # | Feature | What it is | Problem / adds | Core | Related | Src | Fit | Adaptation | Depends | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 74 | Main quest line | One active quest at a time; later requirements are tracked and can be completed before they show; rewards grow; mixes building, fog, barbarians and "set your avatar" | Always one next step; no redundant work | Guidance | 75 | F:Quests/Main_Quest_Line | **ADOPT** | The Worklist and Foreman chapters credit already-met goals instantly (retroactive), with "already done" ticks | Worklist, Foreman | Evaluating conditions on load | — |
| 75 | Side-quest lines per building | One active quest per line; mostly upgrade, research and train goals | Medium goals per building | — | 74, 29 | F:Quests/Side_Quests, F:Buildings/Academy | **ADOPT** | **Mastery lines** per machine type (build 3, reach level 5, 5 at working heat, process 1,000 items), one active per line, shown on the Codex card; rewards feed specialisation | Codex, counters | Authoring × 12 types | — |
| 76 | Daily objectives and activity chests | Random daily tasks earn activity points; chests at 20/40/60/80/100; resets 00:00 UTC | Daily habit | — | — | F:Quests/Daily_Objectives | REJECT | — | — | — | Conflicts with an existing decision (D2) |
| 77 | Achievements and showcase | From City Hall 6: 7 categories plus "Child of Fate" (frames and plaques); points; badges; a showcase of 5 | Long-tail pride | — | 104 | F:Achievements | ADAPT | The planned **Ledger** (marks never expire) with a 5-mark showcase on the Core's plaque | Ledger | — | Public display needs a server; keep it local or in a share image |
| 78 | Chapter quests | **UNVERIFIED:** no source confirmed a separate chapter-quest system. Confirmed guidance = the main line + side lines + the 7-day event | — | — | 74 | — | — | The Foreman's chapters already fill this role | — | — | — |
| 79 | Info everywhere | An "i" icon in almost every window; rules pages gained a map-info tab in 2026 | Self-serve learning | — | 89 | F:Frequently_Asked_Questions, OFF-AS | ADOPT | Every panel's "?" opens its Codex page (probably partly done) | Codex | — | — |
| 80 | Onboarding | The scripted intro shows barbarians attacking a tribal village, which never happens outside the tutorial. The tutorial can be skipped (guide). Players start with a peace shield. Beginner teleports last 10 days or until City Hall 8. Store reviews complain about replaying a long forced intro | — | — | 71, 114 | F:Scouting, RG-BEG, SN, OFF-GP | ADOPT (the lessons) | Keep the first minute real (no fake threats), let it be skipped on a second profile, and add a free **reroll window** for the yard/ring seed until Core 2 | Foreman, seed | — | — |

### 2.10 Social / alliance / kingdom / competition (brief)
| # | Feature | What it is | Src | Fit | Single-player note | Conflict |
|---|---|---|---|---|---|---|
| 81 | Alliance economy | Each help cuts max(1% of remaining time, 1 min); 5 helps, +1 per Alliance Center level. Donations to alliance tech earn credits. Alliance gifts and an alliance shop | F:Buildings/Alliance_Center, F:Alliance_Technology, F:Alliance_Gift, F:Territory | REJECT | — | Conflicts with an existing decision (D3) |
| 82 | Territory wars, KvK, Season of Conquest | 50-day KvK seasons from City Hall 16; crusader flags; alliance crystal fields; Seasons 1–3 then Season of Conquest stories; camps, matchmaking votes, Rest Mode vote, kingdom-vs-kingdom rivalries | F:Lost_Kingdom, RG-HA, OFF-AS | REJECT | Analogue: the collapse run carries season-scoped systems (37, 51, 52) | D3 |
| 83 | Chat, translation, markers, notes | Live chat with translation, officer roles, map markers; 2026 alliance notes and coalition markers | OFF-GP, OFF-AS | REJECT | Personal map pins on the ring: LATER | D3 |
| 84 | Kingdom titles | The King and his officials grant buffs (Architect +10% building speed, Scientist +5% research) or debuffs (Traitor, Beggar, Exile); the title must be applied before an action starts | RG-TITLE, SN | REJECT | — | D3 |
| 85 | Rankings and profiles | 8 rankings (power, kills, City Hall level, gathering…); personal statistics | F:Governor_Profile | REJECT (rankings) / ADAPT (stats → 73) | Personal statistics only | D3 |
| 86 | Layout sharing | Layouts can be shared only as screenshots; others rebuild them by hand | HG-CITY | **ADAPT** | Blueprint **share code** (the Factory Tours proposal), imported into a slot. Challenges: versioning the code format, validating codes from others | — |

### 2.11 UI/HUD & information design
| # | Feature | What it is | Src | Fit | Adaptation / Challenges |
|---|---|---|---|---|---|
| 87 | All queues on one screen | The Builder's Hut shows every building queue, its target level and the time left | F:Buildings/Builder's_Hut | ADAPT | **Factory overview:** machine types with counts running / idle / too hot / too cold; tap to cycle through the problem machines. Needs sim state; keep the update cost low |
| 88 | Owned quantity on costs | 2026: blueprint and fragment descriptions show the quantity owned | OFF-AS | **ADOPT** | Every cost chip shows have/need and turns green when met |
| 89 | Bonus breakdown | The City Hall has an economy chart showing total speed bonuses | F:Buildings/Farm (editor note) | **ADOPT** | **Bonuses page:** every output/heat multiplier listed by source (research, charter, sites, fittings, mastery). Needs one source of truth in code |
| 90 | Tactical view | 2026 notes mention "City View and Tactical View" | OFF-AS | ADAPT | A heat/flow overlay toggle. Check `docs/research/factory-readability.md` for what already exists |
| 91 | Event calendar; pinned countdown mail | An in-game calendar; Ark registration mail is auto-pinned with a countdown | OFF-AS | REJECT | The Chronicle replaces a calendar; no clocks |
| 92 | Bulletin Board | A building that shows developer messages | F:Buildings/Bulletin_Board | LATER | An offline "What's new" note bundled with each update, shown once |

### 2.12 Notifications (systems that bring players back)
| # | Feature | What it is | Src | Fit | Adaptation | Conflict |
|---|---|---|---|---|---|---|
| 93 | Push notifications | **UNVERIFIED** (no source found for RoK's notification options) | — | ADAPT (with care) | Opt-in and off by default; only "production stalled" (store full, overheating), never "come back" nudges. Challenge: projecting the stall time offline | Risk of daily-login guilt |
| 94 | Mail as a persistent inbox | The scouting report updates in place; City Hall rewards and "Trial Complete" arrive by mail | F:Scouting, F:Buildings/City_Hall, F:Events/Lohar's_Trial | **ADOPT** | Logbook and Discovery log hold unclaimed gifts that never expire | — |

### 2.13 Quality of life
| # | Feature | What it is | Src | Fit | Adaptation | Conflict |
|---|---|---|---|---|---|---|
| 95 | Batch actions | Open all keys (10+), travel ×10, quick dispatch, "Finish Now" | RG-TAV, TSG-FORM, OFF-AS | **ADOPT** | "Upgrade all of type to cap", "Refit all", "Apply blueprint", "Claim all". Challenge: ordering when not everything is affordable | — |
| 96 | Auto-Peacekeeping | From City Hall 7: up to 5 marches, a chosen barbarian level range, up to 100 attacks per session. Bundled with the 30-Day Gem Supply, together with Auto-Help and chat translation | LB-AUTO | ADAPT (the automation) / REJECT (the paywall) | Automation earned in play: a research node or Chronicle reward unlocks "auto-refit to cap" or "rebuild blueprint after collapse" | Subscription |
| 97 | Second builder queue | Builder Recruitment gives a second queue for 2 days; VIP 6 makes it permanent | F:Builder_queue, F:Items/Builder_Recruitment | REJECT | — | Paid convenience on timers |
| 98 | Guard irreversible actions | 2026: a secondary password is required to inscribe or convert armaments | OFF-AS | ADOPT | Collapse, dismantle and respec each get a "you lose / you keep" card (the collapse card exists) | — |
| 99 | Visual presets per device | 2026: remastered troop models on by default for medium-graphics devices; a toggle under "Unit Visuals" | OFF-AS | ADOPT (probably exists) | Quality presets plus Reduce motion (B5 done) | — |

### 2.14 Customisation & collections
| # | Feature | What it is | Src | Fit | Adaptation | Conflict |
|---|---|---|---|---|---|---|
| 100 | City themes with stats; transmog | Skins carry stats. Since 1.0.77.21, "Little Brushes" put one skin's look on another of the same troop type while keeping its stats | TSG-TMOG, HB-ZEN | ADOPT (transmog) / REJECT (stats) | Wear any unlocked look regardless of Charter | Stats on cosmetics break the purchase rule |
| 101 | Legendary theme sets | 2026: the first legendary city theme set, with city and teleport effects | OFF-AS | LATER | Cosmetic sets (Core shell, ground, Vault sign) earned from the Chronicle or Ledger | Never sold with stats |
| 102 | Cosmetics with no stats | 2026: commander outfits and alliance cosmetics "will not provide any attribute bonuses" | OFF-AS | **ADOPT (principle)** | Matches Lodeworks' rule for its two one-time purchases | — |
| 103 | Event decorations | Holiday decor for 3 days, 7 days, or permanently via event currency | F:Items/City_Hall_Decor | REJECT (timed) / LATER (permanent) | Permanent decor as Ledger rewards | FOMO |
| 104 | Profile: avatar, frames, plaques, album | — | F:Governor_Profile, F:Achievements | LATER | Factory name, plaque and 5 showcase marks on the title screen and share image | — |
| 105 | Commander collection | 10 sculptures summon a commander; a duplicate from a chest becomes 10 sculptures; universal sculptures convert to any owned commander's | F:Items/Commander_Sculpture, F:Buildings/Tavern/Gold_Chests | ADAPT | A duplicate Fitting blueprint becomes a tempering step (36) | Chest acquisition rejected |

### 2.15 Endgame & keeping old stuff valuable
| # | Feature | What it is | Src | Fit | Adaptation |
|---|---|---|---|---|---|
| 106 | Old tiers keep jobs | Guides: keep T1/T2 for fast gathering; keep T4 for cheaper field fights after T5 | RG-TROOP | **ADAPT** | Give low-level machines a real niche: lower levels emit less heat, so in hot strata a level-2 Drill beside a vent beats a level-8 one. Must be true in the sim, and shown in the Codex |
| 107 | Cheap specialists max first | Low-rarity gathering commanders are easier to max; level 37 maxes "Superior Tools"; 5 marches at City Hall 22 | F:Commander_Guide | ADAPT | Specialisation points scale inversely with a machine's base cost, so Drill and Crusher max early and stay useful |
| 108 | Old units refreshed by updates | March 2026: the Attack/Defense/Support trees gained Smite/Combo modifiers so older commanders keep up (third-party summary of the official patch) | LB-PATCH | **ADOPT (principle)** | Each new modifier or machine also adds an interacting option to older machines' specialisations |
| 109 | Classic cosmetics return | 2026: classic themes return in the Zenith Shop; unused badges auto-convert to "Faded" badges | OFF-AS | ADOPT (principle) | Every cosmetic stays earnable forever; no expiring tokens |
| 110 | Endless season stories | After Seasons 1–3 the Season of Conquest runs one story after another; new stories are tried in select kingdoms first | RG-HA, OFF-AS | ADAPT | Collapse runs with a "story" (a modifier theme + ring layout + a Chronicle side-chapter, e.g., "Flooded seams"). Fits Rock of the Week with no server |

### 2.16 Anti-frustration
| # | Feature | What it is | Src | Fit | Adaptation |
|---|---|---|---|---|---|
| 111 | Anti-waste conversions | Kingdom Maps → speedups once all fog is cleared; Builder Recruitment → 60-min speedups after VIP 6; a duplicate commander → 10 sculptures; skipped VIP levels' daily chests mailed; unused Zenith badges → Faded badges | F:Items/Kingdom_Map, F:VIP, F:Items/Builder_Recruitment, F:Buildings/Tavern/Gold_Chests, OFF-AS | **ADOPT** | A rule for every system: obsolete items auto-convert to credits; skipped Core levels pay every skipped gift; leftover charts convert. Keep one conversion table |
| 112 | No-loss modes | Expedition has no hospital losses; Ark troops don't die permanently; caves are risk-free; barbarian losses heal on return | F:Expedition, GG-AOO, F:Scouting, F:Barbarians/Fort/Rules | **ADOPT** | Trials and blueprint/Charter previews run on a copy; the main save is untouched. Challenge: a second sim in memory |
| 113 | Rest Mode vote | 2026: kings vote whether to enable a season's Rest Mode | OFF-AS | (note) | Lodeworks has no obligations to rest from; keep it so |
| 114 | Lessons from store reviews | User reviews on the official store page: an account lost after ~59 days away; a long forced intro replayed; casuals crushed by strong players | OFF-GP | ADOPT (lessons) | Local saves never expire; intro skippable; no PvP |

### 2.17 Monetisation (for the rejection analysis)
| # | Feature | What it is | Src | Fit | Reason |
|---|---|---|---|---|---|
| 115 | VIP and Special Privileges | Paid chests per VIP level from $0.99 to $99.99 (wiki table). VIP points also come from a login streak (40 rising to 200 a day, reset if a day is missed) | F:VIP | REJECT | Pay for power; streak (D2) |
| 116 | Gems, shop, bundles, SVIP | Gems buy everything; small bundles appear at Crystal Mine milestones; the SVIP shop sells cosmetics | F:Resources, RG-HA, OFF-AS | REJECT | Purchases change the economy |
| 117 | Tavern chests and keys | Silver, golden and equipment chests; a free golden chest every 2 days (SN); the published odds for a Legendary commander from a gold chest are 0.80566% | F:Buildings/Tavern/Gold_Chests, F:Items/Key, SN | REJECT | Gacha |
| 118 | Wheels, prayers, red packets, betting, stealing | Wheel of Fortune (exclusive sculptures for gems), Esmeralda's Prayer/Collection, Lucky Red Packet, World Cup Betting, Melon Market with cross-kingdom stealing | F:Events/Wheel_of_Fortune, OFF-AS | REJECT | Gacha and gambling; stealable resources |
| 119 | Subscriptions | 30-Day Gem Supply (includes the automation); Premium Season Crystal Supply (priced like the 30-day supply; 3 million crystals over 50 days) | LB-AUTO, RG-HA | REJECT | No subscriptions |
| 120 | Paid respec and refund | 2026 events: reset a legendary piece's special talent, or dismantle one with a full material refund, for gems | OFF-AS | REJECT the paid form; ADOPT free versions (15, 111) | Purchase changes the economy |
| 121 | Store disclosures | Google Play shows "Contains ads", "In-Game Purchases (Includes Random Items)" and PEGI 18 "Simulated Gambling" | OFF-GP | (note) | Lodeworks, with rewarded video and 2 one-time purchases, should never need the "random items" label |

**Coverage of the coordinator's areas:**

| Area | Rows |
|---|---|
| Units and characters | 14–16, 28–31, 105 |
| Combat | 63 |
| Map and exploration | 40–52 |
| Quests | 74–80 |
| Events | 64–73 |
| Production and trade | 18–25 |
| City/region development | 4–9, 26 |
| Social | 81–86 |
| Competition | 56, 67–69, 85 |
| Collections | 100–105 |
| Rewards | 8, 44–47, 111 |
| Retention mechanics | 9, 64, 76, 93, 115 |
| Monetisation | 115–121 |
| UI/UX | 79, 87–92, 95 |
| Player motivation | 26, 73, 77 |
| Long-term progression | 14, 29–37, 106–110 |
| Systems that bring players back | 64, 93, 94 |

---

## 3. Complementary clusters, and how they would work together in Lodeworks

1. **The world round the yard** (40–48, 22, 18, 50, 51)
   - Survey clears the ring's fog outward from the yard edge, paid by production, so it works offline and needs no clock.
   - Silhouettes (46) give it a direction. The Discovery log (43) keeps every find.
   - Finds come in three kinds:
     - one-time workings (44), which can grant a free research level;
     - tiered deep finds (45);
     - permanent sites (48): vents feed Boiler heat and crystal fields yield crystals, and duplicates do not stack.
   - One Core requirement per level band then needs a ring input (22). Exploration stops being optional flavour, and the crystal fields, seams and vents finally get a job.
   - A collapse re-rolls the ring (51), so every run explores again.
2. **Run identity** (10–12, 58, 110, 100)
   - The collapse card gains two choices: a **Charter** (3 perks and a variant machine; free to switch, and machines convert in place) and an optional **Deep run** modifier stack that pays by the deepest stratum reached.
   - Story seeds (110) vary what the ring looks like. Transmog (100) keeps looks separate from perks.
   - Together these make collapse 5 onward feel different, which is where GAP-AUDIT E1 says the game runs out.
3. **Crystal Works** (37, 18, 48, 52)
   - Crystals harvested from surveyed fields fund a research tree for the current run that is too large to finish, plus repairable **derelict works** that give one of 3 support effects.
   - All of it resets at collapse. Cores and the permanent Lab tree stay.
   - This mirrors RoK's season buildings without a server or a shop currency.
4. **Mastery and specialisation** (29, 75, 14, 15, 30, 106–108)
   - Using a machine type builds mastery. Mastery lines on the Codex card set medium goals. Points buy branch nodes.
   - Respec is free and the Codex recommends a build.
   - Cheap and low-level machines keep niches, and every new modifier adds an option for old machines.
   - This gives the long game depth after the permanent tree is complete (about 4 collapses, 3 h 57 m of active play [LW]).
5. **Fittings** (32–36, 105, 44)
   - Blueprints come only from discoveries. Forging at the Assembler uses Plates, Components and crystals.
   - Sets are satisfied by *adjacency*. A fitting forged for a named type gets +30% there. Tempering is deterministic, and duplicate blueprints become tempering steps.
   - The payoff is a sink for surplus materials that deepens the adjacency puzzle instead of adding a currency.
6. **Chronicle** (64, 65, 7, 8, 9, 26, 66, 73)
   - A scroll of chapters visible from Core 2. Each chapter opens a system (Survey → Charter → Crystal Works → Trials → Fittings) behind a *progress* gate, with a separate bonus goal that never blocks.
   - Eras give chapters their titles and the yard's look. The level-up card hands out the chapter's gift. Each collapse writes a Run report.
   - The result is a planned, visible long game with no dates.
7. **Trials** (55, 56, 58, 54, 59, 112, 17)
   - Sandbox boards with a fixed seed and 3 stars; stars give permanent perks.
   - Equal-kit layout puzzles; a failure shows the shortfall and eases the next attempt; an endless escalating trial.
   - Patterns (17) are taught here first.
   - This fills the challenge runs (AUDIT C2) with no daily limits or leaderboards.
8. **Nothing lost, one tap** (111, 74, 95, 87–89, 5, 86, 96, 98)
   - Conversion rules, retroactive credit, batch actions, a factory overview, have/need on costs and a bonuses page.
   - Blueprint slots with share codes, automation earned in play, and a guard on irreversible actions.
   - Together they are the cheap quality-of-life layer that every new system above relies on.

---

## 4. Top 15 recommendations, ranked by value for effort

1. **Anti-waste conversion rule (111).** Almost no code, and it stops every future system from creating dead items or skipped rewards.
2. **Retroactive credit in the Worklist and Foreman (74).** A small condition-on-load change that removes redundant steps and matches how RoK's main quest tracks ahead.
3. **Have/need on every cost plus a Bonuses page (88, 89).** Low effort, a large gain in readability on a small screen, and a place to show every future multiplier.
4. **Blueprint slots with share codes (5, 86).** Closes the pending decision GAP-AUDIT A1 with RoK's City Editor as the precedent, and enables Factory Tours without a server.
5. **Refit: upgrade in place for the difference, plus "Refit all" (28, 95).** A small sim change that keeps old machines valuable and removes tap tedium.
6. **Run report and lifetime Logbook (73).** Cheap counters that make every collapse feel like an achievement.
7. **Chronicle, a personal kingdom timeline (64, 65).** The single biggest answer to the empty 10–50 hour band. It reuses the Worklist and Core graph, and its unlocks are progress-gated with bonus goals that never block.
8. **Survey the fogged ring, with a Discovery log (40–43, 46).** Gives the unused crystal fields, seams and vents a curiosity loop that works offline because production pays for it.
9. **Abandoned workings and site bonuses (44, 48, 22).** The payoffs that make Survey matter (free research levels, vent heat, Core rows needing ring inputs), and they tie exploration to the heat system.
10. **Charter per run with a free switch (10–12).** Replayability for collapse 5 onward, using perks the sim already expresses. Start with 2 charters.
11. **Mastery lines on Codex cards (75).** Medium-term goals per machine at low-to-medium effort, with no daily chores.
12. **Trials with stars on a sandbox board (55, 56, 112).** Makes the proposed challenge runs concrete: permanent perks, no limits, no leaderboard.
13. **Crystal Works, research for the current run (37).** Gives crystals a use and each run a strategic choice without a new shop currency.
14. **Visual eras by Core band (26).** Progress you can see; keep the art cost down with only the Core shell, ground and palette.
15. **Specialisation fed by mastery, with free respec (14, 29, 15).** The deepest long-term layer once the permanent tree is complete; the highest balance effort, so build it after the Charter.

Just outside the top 15: **Fittings (32–36)** at LATER; Patterns (17); Claims (50); Deep run (58).

---

## 5. Explicit REJECT list, with reasons

- **Conflict with existing decision D2 (daily/weekly chores and streaks):** daily objectives and activity chests (76); the VIP login streak (115); daily Expedition claims (55, replaced by permanent perks); bastion daily quests and lockouts (52); daily travel/dispatch chances (38); the 7-day new-player event (71); holiday series (70); Sunset Canyon daily attempts and tickets (56).
- **Conflict with existing decision D3 (multiplayer, leaderboards, server):** alliance help, tech, gifts and shop (81); territory wars, KvK and Season of Conquest (82); chat and markers (83); kingdom titles (84); rankings (85); Mightiest Governor (67); power events (68); Zenith of Power (69); Ark of Osiris (61); Ceroli co-op (57); Shadow Legion (60); Trading Post (24); calendar and pinned countdowns (91).
- **Conflict with existing decision D1 (more currencies):** keys, medals, canyon coins, season coins, the various stones, Sage's Testimony, credits (25); a separate combine menu for materials (33); seasonal currency (37).
- **Vision: no energy or timers as gates:** Action Points (2); speedups and timed boosts (23); timed queues and a second builder (1, 97); guardians on a clock and temporary runes (62); tap-to-collect production caps (21); Lohar relic windows (59).
- **Vision: no gacha, no random progression:** Tavern chests and keys (117); Wheel of Fortune, Esmeralda, red packets (118); luck-based stars and random skill upgrades (31); random armament stats, inscriptions and rerolls (17); random special-talent rolls (35); supply boxes (68).
- **Vision: no stealable resources:** plunder, storehouse protection, peace shields (20); Melon Market stealing (118); base attacks (60, 63).
- **Vision: purchases never change an economy number; no subscriptions:** VIP (39, 115); gems, shop and bundles (116); subscriptions including paid automation (96, 119); paid respec and refund (120); stats on cosmetics and skins (69, 100); SVIP (116).
- **FOMO, live service, or needing a server:** Mysterious Merchant refreshes (24); timed decorations (103); Lyceum quiz and newspaper (72); World Cup betting (118).

---

## 6. Sources

**Official**
- **OFF-AS:** Apple App Store listing, including Lilith's official version-history patch notes for 2026: https://apps.apple.com/us/app/rise-of-kingdoms/id1354260888
- **OFF-GP:** Google Play listing "Rise of Kingdoms: Lost Crusade" (store text updated 17 Sep 2026; user reviews also shown there): https://play.google.com/store/apps/details?id=com.lilithgame.roc.gp
- **OFF-X:** official @riseofkingdoms posts, seen only as search-result snippets: https://x.com/riseofkingdoms/status/1961383335399494062 and https://x.com/riseofkingdoms/status/2061764765098099041
- Tried and failed: rok.lilith.com and rok-club.lilith.com (JavaScript-only, no content); riseofkingdoms.com (HTTP 522).

**Community wiki**
- **F:Page** = https://riseofkingdoms.fandom.com/wiki/Page, fetched as wikitext through `https://riseofkingdoms.fandom.com/api.php?action=parse&page=…&prop=wikitext&format=json`.
- Pages used:
  - Buildings: Buildings; Buildings/City_Hall; Buildings/City_Hall/Rewards; Buildings/Academy; Buildings/Scout_Camp; Buildings/Monument; Buildings/Tavern (plus Silver_Chests, Gold_Chests); Buildings/Blacksmith (plus Combining_Materials); Buildings/Farm; Buildings/Storehouse; Buildings/Courier_Station; Buildings/Trading_Post; Buildings/Builder's_Hut; Buildings/Bulletin_Board; Buildings/Lyceum_of_Wisdom; Buildings/Alliance_Center; Buildings/Hospital; Builder_queue.
  - Civilizations and progression: Civilizations (plus Arabia, Spain, Vikings); Technology; Feudal_Age; Commanders; Commander_Guide; Commanders/Experience.
  - Map and PvE: Scouting; Tribal_village; Holy_Sites; Kingdom; Territory; Barbarians; Barbarians/Fort/Rules; Fort; Expedition; Runes.
  - Seasons and events: Lost_Kingdom; Lost_Kingdom_Chronicles; Lost_Kingdom/Eve_of_the_Crusade; Events; Events/The_Mightiest_Governor; Events/Lohar's_Trial; Events/Era_Breakthrough; Events/The_Karuak_Ceremony; Events/Shadow_Legion_Invasion; Events/Wheel_of_Fortune; Events/Strategic_Reserve; Events/Rise_of_Kingdoms; Events/Hero_Returns; Peerless_Scholar.
  - Quests: Quests/Main_Quest_Line; Quests/Side_Quests; Quests/Daily_Objectives; Achievements.
  - Items: Items/Treasure_of_Cave; Items/Kingdom_Map; Items/Civilization_Change; Items/Commander_Sculpture; Items/Starlight_Sculpture; Items/Tome_of_Knowledge; Items/Talent_Reset; Items/Book_of_Covenant; Items/Builder_Recruitment; Items/Beginner's_Immigration; Items/Speedup; Items/Food_Boost; Items/City_Hall_Decor; Items/Key.
  - Other: VIP; Resources; Governor_Profile; Alliance_Technology; Alliance_Gift; Frequently_Asked_Questions.

**Guides and press**
- **riseofkingdomsguides.com**
  - RG-AGES /rise-of-kingdoms-ages/
  - RG-SC /rise-of-kingdoms-sunset-canyon-guide/
  - RG-CER /rise-of-kingdoms-ceroli-crisis-guide/
  - RG-HA /heroic-anthem-season-of-conquest-new-kvk-guide/
  - RG-ICON /iconic-crystals-guide-and-priorities/ (Jan 2026)
  - RG-TAL /talent-tree/ (Aug 2026)
  - RG-TITLE /how-to-use-title-buffs-guide/
  - RG-TROOP /rise-of-kingdoms-upgrading-troops-guide/
  - RG-BEG /rise-of-kingdoms-beginners-guide/
  - RG-TAV /tavern/
- **TSG-FORM:** https://touchscreengaming.com/formations-guide/ (May 2025)
- **TSG-TMOG:** https://touchscreengaming.com/rise-of-kingdoms-city-hall-transmog-guide/ (Apr 2025)
- **HB-ZEN:** https://riseofkingdomshandbook.com/guides/riseofkingdoms-zenith-of-power-guide (Aug 2026)
- **HG-CITY:** https://heaven-guardian.com/rise-of-kingdoms-ultimate-city-design-guide/
- **LB-AUTO:** https://www.lootbar.com/blog/en/rise-of-kingdoms-auto-peacekeeping-guide.html (Jun 2026; a top-up seller's blog)
- **LB-PATCH:** https://lootbar.gg/blog/en/rise-of-kingdoms-new-update-is-here-huge-changes-to-talents-and-more.html (Mar 2026; the same seller)
- **GG-AOO:** https://www.gurugamer.ru/en/articles/ark-osiris.html (2026)
- **SN:** facts known only from search-result summaries, not opened. These are: Ceroli Crisis opening at City Hall 10 and its power minimums; the free golden chest every 2 days; beginner teleport rules; the external talent planners; "titles have no effect if applied after an action starts".

**Lodeworks context (read only)**
- **LW:** `D:\Claude Projeleri\lodeworks\docs\PROGRESSION.md` and `D:\Claude Projeleri\lodeworks\docs\GAP-AUDIT.md`. Decisions D1–D3, the Blueprint decision A1, the long-game gap E1, the Ledger, Factory Tours and Rock of the Week proposals, and the "4 collapses, 3 h 57 m" measurement all come from these.
