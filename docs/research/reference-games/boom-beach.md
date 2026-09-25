# Boom Beach (Supercell), a reference study for Lodeworks (state as of 25 Sep 2026)

**How to read this.** Source keys are in brackets and listed in §6. The **Fit**, **Adaptation**, **Depends on**, **Related** and **Challenges** cells are my own design proposals for Lodeworks. Treat them as **Inference** unless a cell carries a source key. Facts that the sources flag as unconfirmed, or on which the sources disagree, are marked **UNVERIFIED**. Every number comes from a source. I invented none.

**Rows marked "conflicts with an existing decision".** These clash with a choice Lodeworks has already made: no daily or weekly chores and no streaks; no multiplayer, leaderboards or social features that need a server; no new currencies as a content treadmill.

**Already covered (one line each).** The HQ caps every other building's level [W:Headquarters]. XP level gates the next HQ level [W:Experience]. The Armory is the upgrade chain for troops and abilities [W:Armory]. Radar level equals the HQ level cap; you unlock fog regions with Gold, and there are 149 regions in total [W:Radar][W:Archipelago].

---

## 1. Overview: structure, modes, loops, currencies

- **Modes.**
  - **Home island + Archipelago.** Asynchronous. You build a base, then attack NPC "Blackguard" bases and real players' "Mercenary" bases on a map you uncover yourself. Single-player campaign and multiplayer share the same world map [PR-WP].
  - **Cycle of Evil.** A fixed 7-day rotation of PvE events: Hammerman Strikes Back (Mon), Dr. T Tropical (Tue), Dr. T Volcano (Wed), War Factory (Thu), Imitation Game (Fri), Dr. T Tropical (Sat), Dr. T Volcano (Sun). Each lasts 24 h from 08:00 GMT [W:Events][OF-S:cycle-of-evil].
  - **Mega Crab.** Monthly, 3 days, infinite stages [OF-S:mega-crab].
  - **Task Force Operations.** Co-op; each Operation lasts 23 h 55 m [W:Operation].
  - **Warships.** Seasonal real-time PvP, 21 or 28 days per season, with its own tech tree [W:Warships].
  - **Sonar Ops.** A 10-day Battleship-style minigame [W:Sonar Ops].
  - **Leader Deployment.** An event pass, June 2026 onward [W:VH 2026-06-22].
  - **Blitz.** A leaderboard Leader event announced for 2 Oct 2026 [OF-B:blitz][OF-S:whats-new-9].
- **Loops.**
  - **Minute to minute:** scout, attack (troops, Gunboat energy, Flare), destroy the HQ, collect loot.
  - **Session:** collect producers and the Resource Boat, start upgrades, clear map targets, open Supply Chests.
  - **Mid term:** HQ, Radar and Armory upgrades, exploring regions, taking Resource Bases, Statues.
  - **Long term:** Statues/Engravings, Tribes, Mystical Monument (800 levels), threat ladders, HQ 29 (June 2026) [W:VH].
- **Currencies.** The June 2026 update added HQ 29 [W:VH].
  - **Build/action resources:** Gold (for actions: exploring, attacking, diving) plus Wood, Stone and Iron (for building) [W:Residence].
  - **Premium:** Diamonds.
  - **Stones and boosts:** Power Stones (4 elements × 3 sizes) and Power Powder.
  - **Tokens and tickets:** Intel, Victory Points (a score), Trader Tickets, Hero Tokens, Prototype Modules, Proto Tokens, Raw Crystals, Research Tokens, Time Savers, Build Tokens, Camo Tickets, Keycards, Card Pieces, Circuit Blocks, Field Manuals / Action Reports, Evil / Sonar / Event Coins [W:Resources][OF-S:black-markets][W:VH 2026-03-17].
  - **What this means for Lodeworks:** Boom Beach is a textbook currency treadmill. Most of these currencies are therefore REJECT for Lodeworks.

---

## 2. Feature inventory

**Column legend:**

- **What** — what the feature is.
- **Solves / adds** — the problem it solves or what it adds.
- **Core** — what it adds to the core loop.
- **Src** — source key.
- **Fit** — ADOPT / ADAPT / LATER / REJECT.
- **Adaptation** — the proposal in Lodeworks terms.
- **Dep** — depends on.
- **Rel** — related features (F-numbers).
- **Conflict** — conflict with the Lodeworks vision, if any.
- **Challenges** — difficulties of building it in a small single-player Godot game.

### 2.1 Core loop & sessions

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F1 | Resource Boat | A boat south of the docks piles up Gold from freed villages and Wood/Stone/Iron from Resource Bases. No cap. Can't be stolen from home | One tap on return collects "world" income | Payoff that opens a session | [W:Freed Village][W:Native Islander][OF-S:buildings-boats-2] | ADOPT | A **Haul Dock** at the yard edge collects output from world sites (F27) while offline. One tap to collect, and it shows its contents | F27 | F28, F99 | None | Offline catch-up maths for many sites; saving pending hauls |
| F2 | Capped producers | Residence/Sawmill produce until full, then stop [W:Residence] | Reason to come back; caps the idle-gain curve | Collect → spend | [W:Residence] | ADOPT (Lodeworks already has offline production) | Keep the caps visible; tie them to F40 | Store/Vault | F40 | None | None new |
| F3 | Loot locked at first scout | An enemy's loot is fixed the first time you scout it and never changes afterwards | Stops "stalking" for better loot; lets you plan | Informed choice | [W:Loot System] | ADOPT | Every world site, challenge and crate shows its exact reward before you commit, and that reward is seeded and saved | Seeded RNG | F49, F110 | None | Save the seed per site so reloading can't reroll it |
| F4 | Supply Chests | Every 5 VP earned fills a chest; up to 8 bank; one regenerates per 6 h; pick 1 of 3 rewards [W:Rank]. Surplus VP rolls into the next chest [W:VH 2024-06] | Rewards progress; the 1-of-3 pick adds agency | Short reward beat | [W:Rank][W:VH] | ADAPT | **Milestone crates** earned from output milestones (credits sold, Core-store deliveries), not from time. Bank up to N; choose 1 of 3 | Worklist/Core stats | F79, F85 | Its 6-h regeneration is a timer, so drop it | Picking milestones that don't spike pacing |
| F5 | Daily Reward boat | One per day, scaled by rank; starts at 25 VP [W:Rank] | Daily login | Retention | [W:Rank] | REJECT | — | — | F65 | **Conflicts with an existing decision (daily chores)** | — |
| F6 | Battle Fast Forward | Speed-up button in PvE battles. Automatic after the HQ falls. Option to stop fast-forwarding when the player acts [W:VH 2023/2025] | Cuts dead time | Tempo | [W:VH] | ADAPT | A 2×/4× sim-speed toggle in challenges and stress tests (F66–F70) and in the offline-catch-up replay | Deterministic sim | F66–F70 | None | Sim must stay stable at higher tick rates (heat diffusion) |

### 2.2 Base building & layout

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F7 | Builder limit | One builder. A second one is a subscription; Build Tokens skip the queue [W:Builder][W:Seasonal Missions] | Monetised waiting | Pacing | [W:Builder] | REJECT | — | — | F117 | Timers as gates, subscription | — |
| F8 | Obstacles | Trees and rocks cost Gold to clear and give Wood/Stone. Cheaper ones pay better per Gold. Trees regrow: 40% chance per 13 h, capped at 60. Rocks never return [W:Obstacles] | Early resources; opens space | Micro-goals | [W:Obstacles] | ADOPT (no regrowth) | Rubble/boulders on the 44×44 board and on world sites. Pay credits, get Ore/Gravel, free a tile. Optional: regrow per Collapse only | Board tiles | F9, F22 | Regrowth on a clock = timer | Pathing/placement rules; save cleared tiles |
| F9 | Layout editor / saved layouts | Save, edit and load several layouts (HQ 13+). Store buildings one by one, by type, or all at once; autosave; "apply" places everything [OF-S:buildings-boats-2][W:VH 2023]. Troop Loadouts (HQ 10+) save army presets | Rebuilding is tedious; lets you experiment | Layout experimentation | [OF-S:buildings-boats-2][W:VH] | ADOPT | **Blueprints (P7).** Save named layouts of Core lines. Apply after a Collapse; missing machines appear as ghosts to buy. "Store all by type" | P6 decision | F98, F19 | None | Ghost placement, applying partially when unaffordable, saving layouts in the save file; handling heat/strata differences |
| F10 | Upgrade arrows | Green arrow = affordable upgrade; grey = not affordable. The grey ones can be turned off [W:Builder][W:VH 2023] | "What can I do now?" at a glance | Faster decisions | [W:Builder] | ADOPT | Small iso-offset badge over each machine: green = affordable, grey = not. Toggle in options | Machine DB | F11, F97 | None | Iso overlay clutter on a small screen; batch the redraws |
| F11 | Building suggestions / Helper / Standing Orders | Recommended buildings in order of importance, affordable first. Tap to jump the camera to the building. A Helper icon reminds you of open tasks; the hint text can be turned off [W:VH 2023-11, 2024-09] | Guidance without a tutorial | Direction | [W:VH] | ADOPT (already have What now?/Foreman) | Add **tap → camera focus** and "affordable first" sorting to What now? | Worklist | F60, F85 | None | Camera pan in iso; stable ordering |
| F12 | Visual evolution per level | Radar is redesigned at levels 2, 6 and 9; the Vault changes at many levels [W:Radar][W:Vault] | Progress you can see | Motivation | [W:Radar] | ADOPT | Each machine gets a visual step at level milestones, not every level | Art | F101 | None | Art budget; plan sprite tiers |
| F13 | Villagers/workers | They walk to construction sites, carry resources from storage, cheer on completion, hide at raids [W:Builder][W:Worker] | A living base | Juice | [W:Builder] | ADOPT | A few tiny miners walk between machines and the Core; they cheer at level-ups | — | F88 | None | Pathing on the iso grid; perf on low-end Android |
| F14 | Occlusion transparency | Trees go see-through when a defence stands behind them [W:Obstacles] | Readability in iso | Clarity | [W:Obstacles] | ADOPT | Tall machines fade when they hide a selected or smaller machine | Iso renderer | F15 | None | Sort/alpha in Godot's 2D y-sort |
| F15 | Prototype Defenses | Weapon Lab builds strong defences from modules. Each week 6 of 12 are available; they self-destruct after 10/8/6 days (Mk I/II/III) [W:Weapon Lab] | Rotating variety; a module sink | Meta variety | [W:Weapon Lab] | LATER / ADAPT | **Prototype machines:** strong one-offs built from Components. They burn out after N production cycles, not after N days; the available set changes each Collapse | Components | F16 | Real-time expiry = timer | Burnout UI; balance of powerful temporary machines |
| F16 | Gadgets | Attach to a building to change it, e.g. Nature's Boon raises production. Rarity tiers; merge duplicates to rank up; scrap for modules; saved into layouts [W:Nature's Boon][OF-S:whats-new-9] | Customising buildings | Build choice | [W:VH 2026-03][W:Recruitment] | ADAPT | **Machine modules** crafted from Components, deterministically. Slot one per machine (heat sink, overclock, adjacency extender) | Components, Press/Assembler | F9, F51 | Their source in Boom Beach is gacha, so the gacha part is rejected | Stat-modifier plumbing in the sim; UI on a small screen |
| F17 | Garrison upkeep | Garrisoned troops cost Gold per hour, taken from Residence production. You can't garrison more than production allows [W:VH 2024-06] | A sink proportional to income | Trade-off | [W:VH] | LATER | Amplifier/Duplicator consume a share of adjacent output as "upkeep" instead of an up-front cost | Sim rates | F40 | None | Readability of net-rate maths |
| F18 | Hold-to-confirm | 3-second countdown before salvaging a statue or destroying a prototype [W:Statue][W:Weapon Lab] | No accidental loss | Safety | [W:Statue] | ADOPT | Hold-to-confirm for scrap, Collapse, salvage and site release | — | F111 | None | None |

### 2.3 Map, exploration & world (the priority area)

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F19 | Two-scale world | Home base ↔ Archipelago map via a compass button. The map shows bases, Resource Bases, events, dive points, tribes [OF-S:the-great-archipelago] | A world beyond the base | Second screen | [OF-S:great-archipelago] | ADOPT | **World view:** zoom out from the yard to the surrounding land with crystal fields, ore seams and heat vents (`ResourceNodes`) | ResourceNodes | F20–F32 | None | Second scene or camera LOD; memory; touch navigation in landscape |
| F20 | Fog regions paid with Gold, Radar-gated | Unlock cloud regions with Gold; a higher Radar allows more. Bigger or farther regions cost more. All 149 cost 79,960,800 Gold in total [W:Radar][W:Archipelago] | Exploration as a sink and a goal | Spend → discover | [W:Radar] | ADOPT | **Survey** regions for credits. The Core level (or a Survey machine) gates the ring distance. Cost rises with ring | Core levels | F21–F24 | None | Fog rendering; region data; balancing the credit sink |
| F21 | Throttled offer | If too many regions are unexplored, not all allowed ones are offered [W:Radar] | Avoids an overwhelming map | Focus | [W:Radar] | ADOPT | Offer 2–3 surveyable regions at a time | F20 | F23 | None | None |
| F22 | Teasers through fog | Resource Bases, Hammerman HQs and hero distress beacons are visible through clouds; tapping says "This region has a resource base" [W:Radar][W:Resource Base] | Curiosity; a reason to explore | Pull | [W:Radar] | ADOPT | Silhouettes of vents, seams and landmarks show through fog, with a one-line hint | F20 | F29 | None | Fog shader with cut-outs |
| F23 | Exploration chests | Small chests appear as you explore: 1–30 Diamonds plus a VP; they respawn later without the VP [W:Archipelago] | A small surprise for exploring | Reward beat | [W:Archipelago] | ADOPT (no respawn) | **Salvage caches** in surveyed regions: one-time credits/materials/Codex scraps | F20 | F36 | Respawn is optional; if kept, only per Collapse | Placement generator |
| F24 | Biomes set drops | Ice north → Ice stones; volcanic → Magma; tropical → Life [W:Power Stone][W:Archipelago] | Geography matters | Targeting | [W:Power Stone] | ADOPT | Site type decides its output: crystal fields → crystal; seams → high-grade ore; vents → heat. This feeds relics (F51) | F27 | F51 | New materials risk the treadmill: keep it to 1 per site type | Material design (P5: "one resource per era") |
| F25 | Resource Bases | Capture and they ship Wood/Stone/Iron to your boat. Each island's producer level is fixed (2–8); farther from home = higher. Max 14 of each type. You can rearrange them. Statues and tribe boosts apply. Other players can take them [W:Resource Base] | Passive income from the world; distance = richness | Expansion | [W:Resource Base] | ADAPT (core recommendation) | **Claimable world sites:** pay or meet a condition to claim a seam/field/vent. It produces at a fixed richness set by distance/stratum and delivers to the Haul Dock. Never lost | F19, F20 | F1, F24, F42 | Losing sites to other players (stealable) is rejected | Rates offline; UI for many sites; balance vs the yard |
| F26 | Freed villages | Each conquered base frees villagers, who send Gold. Per-village rate depends on the total number freed [W:Freed Village] | A reward for liberating/claiming | Accumulating trickle | [W:Freed Village] | ADAPT | Each developed site adds a small credit stipend that scales with the site count | F25 | F1 | None | Keep the stipend small next to the factory |
| F27 | Boss Bases | 11 unique bases that never respawn. Fixed rewards, guaranteed stones, 5 VP. Beating them unlocks heroes and Cycle of Evil events [W:Boss Base] | Handmade milestones on the map | Big goals | [W:Boss Base] | ADOPT | **Landmark sites:** sealed vault, collapsed mine, cold reactor. One-time "cracks" that need specific deliveries or a heat setup; they unlock a machine, challenge or blueprint | F20 | F28, F66 | None | Scripting a few bespoke puzzles |
| F28 | Derelict Hero Hut | A ruined hut at the base corner is repaired at HQ 4 and unlocks heroes and the Trader [W:Hero Hut][OF-S:resources-the-trader] | A visible promise at the base edge | Anticipation | [W:Hero Hut] | ADOPT | Derelict structures at the yard edge or in the world (old pump by a vent) to repair with materials; each unlocks a feature | Materials | F27, F45 | None | Art for ruined and repaired states |
| F29 | Clue-trail boss | Hammerman HQ 8 appears only after attacks reveal clues [W:Boss Base] | Mystery / discovery | Curiosity | [W:Boss Base] | ADAPT | Codex fragments from caches (F23) point to a hidden landmark | F23 | F36 | None | Tracking clue flags |
| F30 | Submarine dives | Dive points spawn (up to 3 open, 16 locations). Each shows 3 reward slots, some "???". Deeper = longer, costlier, better; 6 h to 2+ days; each Sub level +100 m. Button to cycle between sites [W:Submarine][W:VH 2023] | Expeditions; previewed rewards; a Gold sink | Offline goal | [W:Submarine] | ADAPT | **Probe expeditions** to world spots: pay materials, rewards shown. Duration counts **production ticks** (or is instant with a cost); never a real-time gate | F19 | F3, F92 | A real-time wait = timer as a gate | Tick-based duration offline; preview UI |
| F31 | Invasions & caps | New targets spawn up to a cap set by Radar level. Since June 2024 on visible fixed timers, not random. Clearing more shortens them. Timers pause after 14 h without a login [W:Radar][W:VH 2024-06] | A fresh target supply that never piles up | Replayability | [W:VH] | LATER | Surveyed seams replenish small pockets up to a cap. **Pause while away** so nothing piles up | F25 | F100 | Visible spawn timers edge towards chores | Keep it optional |
| F32 | Activity / Attack Log | Tap an entry to jump to the place. Daily report. Shows rewards to claim [W:Archipelago][OF-S:great-archipelago] | "What happened while I was away?" | Re-entry | [W:Archipelago] | ADOPT | **Logbook:** offline report (produced, sold, research done, caches found), each line jumps to the machine or site | Save events | F1, F94 | None | Event log size in the save |
| F33 | Base notes | Players write notes on map bases [W:VH 2023] | Memory aid | Planning | [W:VH] | LATER | Pin a note to a machine or site | — | F32 | None | Text input on mobile |
| F34 | Messages in a bottle | Bottles wash up with serialized Blackguard lore chains [W:Loading Screen Hints][W:Blackguard] | Environmental story | Flavour | [W:Blackguard] | ADOPT | **Tailings finds:** scraps of the old mine's logs turn up in caches or at the dock and fill Codex chains | Codex | F23, F29 | None | Writing; localisation (TR/EN) |
| F35 | Easter eggs | A rare Dr. T turtle on the beach; tapping the eggs 90 times gives 1 Diamond [W:Dr. T] | Delight | Discovery | [W:Dr. T] | ADOPT | A rare critter in the crystal field; a tap secret gives a Codex entry | — | F34 | None | Tiny |
| F36 | Richness by distance | Resource Base producer level is fixed by distance; NPC bases get harder as you beat more [W:Resource Base][W:Blackguard Base] | Pull outward | Expansion gradient | [W:Resource Base] | ADOPT | Farther rings have richer sites but cost more to survey, claim and link | F20, F25 | F59 | None | Tuning curves |

### 2.4 Economy, currencies & sinks

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F37 | Action currency vs build materials | Gold pays for actions (explore, attack, dive, clear); Wood/Stone/Iron pay for building [W:Residence] | Two spend channels | Choices | [W:Residence] | ADOPT (already: credits vs materials) | Credits pay for world actions (survey/claim/probe); materials pay for machines | — | F20 | None | None |
| F38 | Cap hygiene | Resources at cap show in orange. Shop/Trader purchases that would exceed the cap are blocked. Safes now give a full storage amount [W:VH 2024-09, 2025-06, 2026-04] | No wasted rewards | Trust | [W:VH] | ADOPT | Orange at cap; warn before collecting a haul or crate that would overflow; offer "sell overflow" | Store caps | F2, F99 | None | None |
| F39 | Raw Crystal Mine | Trade any basic resource for 100 crystals. Cost starts at 500,000 and rises 500,000 per trade, separately per resource. Resets every two weeks. No Diamond top-up. Storage grows with tribe levels [W:Tribes] | A surplus sink with diminishing returns | Converts overflow into power | [W:Tribes] | ADAPT | **Refinery at a crystal field:** convert surplus credits or any material into crystal at escalating cost per input. **Resets on Collapse**, not biweekly | F25, P6 | F40 | A biweekly reset = calendar chore | Explaining the escalation clearly |
| F40 | Tribes | 6 regional tribes. Each unlocks by fully exploring its region (Radar 18 for the first, 20 for all). Each specialises (support, defence, attack, production). Boosts cost Raw Crystals, 50 then +50 each; boost count capped by tribe level. Boosts reset and rotate every two weeks; upgrades are permanent; they stack additively with statues [W:Tribes] | A late-game surplus sink; a reason to finish regions | Build variety | [W:Tribes] | ADAPT | **Region guilds / claims:** finishing a region's survey unlocks its bonus menu (heat, adjacency, ore grade). Spend crystal on chosen boosts that **last one shaft**; guild levels are permanent | F20, F39 | F41, F51 | Calendar rotation rejected; the player chooses per Collapse | Many bonus types stacking in the sim |
| F41 | Tribe militia | Tribes auto-clear enemy bases in their region for reduced loot (full loot at tribe level 5); fragments only; exact yield shown before you confirm [W:Tribes][W:Loot System] | Automates repetitive chores | Old content stays useful | [W:Tribes] | ADAPT | **Auto-harvest** a developed region's caches/pockets at reduced yield; full yield at max guild level | F40 | F31 | None | None major |
| F42 | Mystical Monument | Ornamental building from HQ 20 [W:VH 2024-02], 800 levels [OF-B:frontline]. Each level offers 4 random payment options (any resource/item); reroll for 20 Diamonds. A random small bonus about every 20 levels, capped per type (e.g. wood production 3% each, max 18%); visuals change at milestones; its bonuses "do not affect combat balance" [W:Mystical Monument][W:VH] | An endless sink for everything | Endgame | [W:Mystical Monument] | ADAPT (endgame) | **Headframe / Monument** by the Core: endless levels; each offers a choice of payment in any material or credits; small, capped, non-core bonuses; visual stages | Late game | F105 | Paid reroll rejected: make it free or credit-based | Payment generator; cap table |
| F43 | Trader | Visits weekly, Friday to Tuesday. First crate free, then 3 tickets each. The crate rarity **cycle is fixed and predictable**. 3 exchange offers refresh every 24 h or when sold out; reroll for 20 Diamonds [W:Trader] | Converts surplus; drip of rare items | Exchange | [W:Trader] | ADAPT | A **Tinker/Trader** arrives on production milestones (not weekdays) and offers conversions (surplus material ↔ scarce material). The crate cycle is deterministic | Materials | F38, F110 | Weekly visits = calendar | Offer generation that doesn't break the economy |
| F44 | Many shops & currencies | Black Markets: Shop of Evil, Sonar, Card Piece, Circuit Block and Event shops; each has its own coin, some expire [OF-S:black-markets][W:Black Markets] | Monetisation / event reward sinks | — | [OF-S:black-markets] | REJECT | — | — | F117 | **Conflicts with an existing decision (currency treadmill)** | — |
| F45 | Classified Items | Attack Plan / Building Blueprint instantly finish an upgrade; Safes fill a storage type; max 5 of each; from dives, the pass, the Trader [W:Classified Items] | Rare power spikes | — | [W:Classified Items] | LATER | Rare cache find: "Stockpile" fills one material store | F23 | F38 | Timer-skips are N/A | None |
| F46 | Transparent reward formulas | e.g. Dr. T stage n Wood = 2000n²+10000n+2000; Stone 2/3, Iron 1/3 of Wood [W:Dr. T] | Predictable, easy to balance | Planning | [W:Dr. T][W:Imitation Game] | ADOPT | Challenge and crate rewards use published formulas shown in the Codex | — | F3 | None | None |

### 2.5 Progression

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F47 | Sculptor & Statues | Sculptor from HQ 5; 3 to 13 statue slots by level. 7 stones of one size → statue (Idol/Guardian/Masterpiece); the boost type and value are random and only revealed after building. Elements: Life = production, Ice = building HP/damage, Magma = troops, Dark = Gunboat energy/loot/stone chance. Stacking is additive; placement doesn't matter; boosts also apply to Resource Bases. One Masterpiece per bonus type. The info popup shows the max possible value [W:Sculptor][W:Statue][OF-S:sculptor][W:VH 2023] | Permanent, collectable power from the world | Long-term collection goal | [OF-S:sculptor][W:Statue] | ADAPT (high value) | **Resonator & Relics:** world material (F24) → relic with a random value **inside a visible band** (the category is chosen by the player's input element, not random). Slots come from Core/Resonator level. One top-tier relic per bonus type. **Relics survive Collapse:** an answer to P6 "what is kept" | F24, F25 | F48–F50, F105 | "Random roll" must not become gacha: no purchase, visible odds | Relic stats hooking into production/heat/research multipliers; roll seeding |
| F48 | Stone sizes & 7:1 conversion | Fragments → Shards convert for free; Shards → Crystal costs 10 Diamonds per 7. Salvaging a statue gives one stone a size up [W:Power Stone][OF-S:sculptor] | Stops low tiers going dead | Ladder | [W:Power Stone] | ADAPT | Salvage a relic → a guaranteed higher-tier shard; free 7:1 conversion | F47 | F105 | Paid conversion rejected | None |
| F49 | Statue Storage | Keep rolled statues without activating them; salvage from storage (HQ 13) [W:Statue Storage] | Frees the Sculptor; lets you compare | Inventory | [W:Statue Storage] | ADOPT | A relic shelf for rolled but inactive relics | F47 | F18 | None | UI list on a small screen |
| F50 | Power Powder | Doubles one statue's effect for a set time; more powder extends it; boosts pause during maintenance. Sources: Masterpiece salvage (7), Sculptor upgrade (1), Mega Crab, Warships, shops. "Boost all" button [W:Power Powder][W:VH 2023] | Burst power; a sink for top-tier salvage | Spike moments | [W:Power Powder] | ADAPT | **Overcharge:** double one relic for N production cycles. Earned from top-relic salvage or **one rewarded video per relic per shaft** | F47, F79 | F98 | A real-time duration = timer; use cycles | Keeping cycle-based durations right offline |
| F51 | Engraver | HQ 27. Shards fund 8-h research in 4 parallel queues; each extra parallel queue costs more (5 → 7 → 15 → 30 shards). The target Engraving is random but biased toward the stone type. A 1-in-2 chance of a quality upgrade, otherwise a Research Token; tokens buy chosen upgrades (cap 999). Activation costs Power Powder [W:Engraver] | A late sink for old currency; pity through tokens | Late depth | [W:Engraver] | ADAPT (the pattern only) | Any random roll in Lodeworks (relics, caches) gives **tokens on a bad roll**; tokens buy a chosen outcome. Lab research stays a deterministic tree | F47 | F109 | The 8-h research is a timer | None |
| F52 | Heroes via landmarks | Hero Hut repaired at HQ 4; heroes unlock by beating specific Boss Bases [W:Hero Hut][W:Boss Base] | Big goals give new abilities | Power growth | [W:Boss Base] | LATER | **Specialists** (a rigger, a heat engineer) from landmarks. Each gives one passive yard ability (Foreman variants) | F27 | F88 | None | Scope |
| F53 | Warships Tech Tree | A per-season tree: unlocking a node opens the adjacent nodes. Choice nodes pick 1 of 3 and can be switched for Diamonds. Negative nodes cost 1 token but carry a penalty; trade nodes swap token types; everything resets each season [W:Tech Tree][W:Warships Boosts] | Fresh builds every season; trade-offs | Build-crafting | [W:Tech Tree] | ADAPT | **Shaft tree** (per Collapse): small adjacency tree with 1-of-3 choice nodes and optional "negative" nodes (cheap, with a strata penalty). The permanent Lab tree is untouched | P6 | F40, F66 | Diamond switching rejected; switch with credits | UI for a tree on a phone; balance |
| F54 | Front-loaded bonus pool | A hidden pool of 200 bonus VP; the chance of a second VP per Blackguard base falls as the pool drains [W:Blackguard Base] | Fast early game without a permanent inflation | Early pace | [W:Blackguard Base] | ADAPT | A first-shaft "fresh seam" bonus (e.g. extra research yield) that decays as it's used | — | F55 | None | Invisible systems confuse; show it |
| F55 | Early compression & "unlock when useful" | Jan 2026: large cuts to early upgrade times (e.g. HQ level 3: 1 h → 15 min). Feb 2024: "unlocking buildings only when they become useful" [W:VH 2026-01, 2024-02] | Faster first hour | Onboarding pace | [W:VH] | ADOPT (principle) | Measure with core_journey; show a machine only once its input exists | Core table | F84 | None | None |
| F56 | Path of Glory | A list of which buildings, troops and features unlock at each stage, reached from the Building Suggester [W:VH 2024-06] | "What's ahead?" | Long-term motivation | [W:VH] | ADOPT | A **Roadmap** tab in the Codex: Core levels → machines, strata, world rings | Codex | F11, F85 | None | None |
| F57 | Achievements | Three-star tiers (e.g. explore 25/75/149 regions); 3,240 Diamonds in total [W:Achievements] | Long tail of goals | Collection | [W:Achievements] | ADOPT | 3-tier achievements; rewards are trophies/cosmetics/Codex, not economy | — | F102 | None | None |
| F58 | Victory Points & Ranks | VP from wins; rank thresholds scale chest and daily reward size; you can be demoted [W:Rank][W:Victory Point] | A single measure of strength | Status | [W:Rank] | LATER | A "Factory rating" that scales milestone-crate size; no demotion | F4 | F57 | Ties into leaderboards: keep it local | None |

### 2.6 Combat (brief, mostly N/A)

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F59 | Troops, Gunboat, Flare, defences | Real-time assault with troop AI; Gunboat energy from destroyed buildings; defences, mines [W:Gunboat][W:Training Grounds] | Boom Beach's core skill | — | [W:Training Grounds] | REJECT | N/A. Lodeworks' "combat" equivalent is heat/throughput pressure (F63) | — | F63 | Out of genre | — |
| F60 | Squad Leaders & Gadgets (units & characters) | 2026 characters with talents unlocked by duplicates; through Recruitment [W:VH 2026-03] | Character collection | — | [W:Recruitment] | REJECT | Named Specialists come deterministically from landmarks (F52) | — | F115 | Gacha | — |

### 2.7 PvE events & live-ops

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F61 | Cycle of Evil schedule | A fixed weekday rotation, 24 h each [W:Events] | Daily reason to log in | Retention | [W:Events] | REJECT (schedule) | Challenges exist permanently; no calendar | — | F62–F66 | **Conflicts with an existing decision (daily/weekly chores)** | — |
| F62 | Dr. T Threat Stages | 7 stages; clearing all 7 raises next time's starting Threat by 1. A **Downgrade** button lowers it by 7. Rewards stop increasing after Threat 26. Nov 2025: stages 1–5 made much easier, rewards unchanged. HQ 4–11 stay at Threat 1 [W:Dr. T Threat Stages][W:VH 2025-11] | Self-scaling difficulty with an escape hatch | Replayable PvE | [W:Dr. T Threat Stages] | ADAPT | **Pressure Trials:** 7-step generated boards (reuse the 12 strata modifiers). Pressure rises on a full clear; you can downgrade; rewards plateau so the climb is optional | Strata modifiers | F6, F46, F63 | Calendar removed | Generating fair boards; making sure they're solvable |
| F63 | Hammerman Strikes Back | Defend **your own base** against scripted waves. Preview troops, order and statues; waves and deploy points are the same for everyone; unlimited retries; no resource loss on defeat [W:Hammerman Strikes Back (Threat)]. **UNVERIFIED unlock:** wiki says HQ 5, support says HQ 15 + Weapon Lab [OF-S:cycle-of-evil] | Tests your layout; no-loss failure | Layout mastery | [W:HSB] | ADAPT (high value) | **Stress Test:** a previewed scripted surge hits **your real yard**: heat wave from a vent, rush order, coolant failure. Pass by holding throughput/temperature; retry freely; no loss; rewards per step | Deterministic sim | F9, F62 | None | A sandbox copy of the yard; determinism; a result screen |
| F64 | Imitation Game | Hammerman copies real players' bases [W:Imitation Game] | Fresh human-made layouts | — | [W:Imitation Game] | REJECT / LATER | Later: challenge against **your own past blueprint** ("beat your old line") | Blueprints | F9 | Needs a server for other players' data | — |
| F65 | War Factory | 5 attacks on one 150-building base; damage carries over; reward thresholds shown on screen [W:The War Factory] | Partial credit; a multi-attempt project | Persistence | [W:The War Factory] | ADAPT | **Big Order:** a large contract fed over several sessions, with visible thresholds that pay partial rewards | Store | F46, F108 | Attempt cap = energy: drop it | Contract UI |
| F66 | Mega Crab | Monthly, 3 days; infinite stages; 40 attacks, refunded when a stage clears; damage persists; 14 themes each with a rule twist; trophies at stages 10/20/40/60/70; record stage 1007 [W:Mega Crab][OF-S:mega-crab] | A skill-ceiling showcase; rule variety | Endgame PvE | [W:Mega Crab] | ADAPT | **Deep Trial:** an endless themed descent (theme = one strata modifier) available anytime; progress persists; **depth trophies as decorations**; no attempt cap | F62 | F102 | Calendar, attempt limit and leaderboard rejected | Endless generation; scaling |
| F67 | Try-before-unlock | Troop Mania (June 2026) lets even players who haven't unlocked a featured troop use it at reduced stats; Elite Leader Trials [W:VH 2026-06][OF-B:frontline] | Lower commitment risk; teases content | Anticipation | [W:VH] | ADOPT | Trials may hand the player a not-yet-unlocked machine for that board | F62 | F56 | None | Machine availability rules per board |
| F68 | Sonar Ops | Battleship minigame: 3×3 to 10×10 zones; charges from main-loop battles (first 5 per day give 3); an ad gives 2 charges; sinking a sub reveals tiles around it; loops forever; coins → shop, and they expire [W:Sonar Ops][W:VH 2025-08] | Low-stakes variety that feeds on the core loop | Side activity | [W:Sonar Ops] | ADAPT | **Seismic survey:** spend charges (earned from ore mined) to ping a hidden grid and find **ore-seam and crystal pockets** that become claimable sites (F25) | F25 | F79 | Expiring coins, event window and daily caps rejected | Grid generator; charge economy |
| F69 | Difficulty labels | Operation difficulty shown as "Too Easy / Easy / Normal / Hard / Impossible" for **your** Task Force [W:Operation] | Choosing well | Choice | [W:Operation] | ADOPT | Each trial or stress test is rated against the current yard (throughput, heat headroom) | Sim stats | F62, F63 | None | A decent estimator |
| F70 | Community events, Blitz | Community-wide shared goals; Blitz leaderboards [W:VH 2026-03][OF-S:whats-new-9] | Social live-ops | — | [W:VH] | REJECT | — | — | F81 | **Conflicts with an existing decision (server)** | — |

### 2.8 Passes & rewards

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F71 | Boom Pass | Free + premium track ($8); 92 tiers; optimizers, skins, extra Sculptor slot, Build Tokens; bought pass points [W:Seasonal Missions][OF-S:boom-pass] | Monetised season | — | [W:Seasonal Missions] | REJECT | — | — | F117 | Subscription-like season, FOMO | — |
| F72 | Mission board mechanics | 9 missions at the start, +6 weekly (39 in total). Progress bars; **pin** missions; progress indicators on base and map after actions; reroll cost rising 5, 10… [W:Seasonal Missions][W:VH 2024-06] | Clear short goals | Direction | [W:VH] | ADAPT | What now?: add **pin**, progress bars, a toast on the map when an action advances a goal, and a free reroll of optional goals | Worklist | F11, F85 | Weekly drip rejected | None |
| F73 | Leader Deployment pass + Event Shop | $4.99 event pass; coins expire [W:Leader Deployment Event] | — | — | [W:LDE] | REJECT | — | — | F44 | Currency treadmill, FOMO | — |
| F74 | Claim All | A button when several chests are claimable [W:VH 2023-11] | Fewer taps | QoL | [W:VH] | ADOPT | Claim all crates/hauls | F4 | F98 | None | None |
| F75 | Rewarded-ad placements | Second pick from a Supply Chest; speeding up one troop; extra reward on the daily chest; a "beach chest" of random rewards; battle-end ads; 2 Sonar charges [W:VH 2023-11, 2024-02, 2024-11][W:Sonar Ops] | Optional value for time | Monetisation | [W:VH] | ADOPT (pattern) | Rewarded video only at **natural, optional** moments: second pick of a milestone crate, doubling one haul, one overcharge. Never needed to progress; offer it once, no nagging | Ad plugin (AdMob) | F4, F50 | Keep ad value small and capped | Ad SDK consent/age flow (F113), offline fallback |

### 2.9 Social (Task Forces, chat, leaderboards)

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F76 | Task Forces / chat / Intel / Operations / Force Points / Sabotage / Friendly Challenges | Sizes 5/10/25/50; Intel pays to start Operations; Force Points decay 5% per day; Sabotage costs 3 Intel, then +2 each; replays [W:Task Force][W:Intel][W:Operation][W:Force Point][OF-S:social] | Co-op retention | — | [W:Task Force] | REJECT | — | — | — | **Conflicts with an existing decision (server/social)** | — |
| F77 | Leaderboards | Six boards (VP, Task Force, Warships, Mega Crab, Monument, Cycle of Evil); decorated badges; a Crystal bounty on the top 3 [W:Leaderboard] | Competition | — | [W:Leaderboard] | REJECT | Local "personal bests" page instead (F90) | — | F90 | **Conflicts with an existing decision** | — |
| F78 | Friends / visits / others' profiles | Visit bases, invite; reports [W:Leaderboard][OF-S:player-profile] | — | — | [OF-S:player-profile] | REJECT | — | — | — | Server | — |
| F79 | Player-made enemy bases | External Base Builder; Hall of Fame bases added to the game; designers credited (now closed) [W:Blackguard Base Builder] | UGC | — | [W:BBB] | LATER (share codes only) | Offline **blueprint share codes** (text) to import someone's layout. No server | F9 | F64 | A server version is rejected | Code format; validation |

### 2.10 Onboarding

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F80 | Tutorial redesign + skip | Apr 2026: a new first-time tutorial; log in before the tutorial so returning players skip it; the mock battle was removed [OF-B:frontline][W:VH 2026-06] | Smoother start; no forced repeat | First hour | [OF-B:frontline] | ADAPT | Short guided first line (Drill → Crusher → Vault); a "Skip, I've played" button | — | F81, F82 | None | Scripting in Godot; localisation |
| F81 | Boom Academy | A mission checklist for HQ 1–7 with rewards and a final reward; **vanishes at HQ 8, and unclaimed rewards are lost**; its button was moved into the HUD [W:Boom Academy][OF-B:frontline] | An expanded tutorial via goals | Early goals | [W:Boom Academy] | ADOPT (minus the vanishing) | **Apprentice ledger:** 15–20 early goals with small rewards; never expires | Worklist | F72 | Losing unclaimed rewards is rejected | None |
| F82 | Training Grounds | 21 lessons, each a small crafted base teaching one mechanic, with rewards (10 Time Savers each, 20 for the last two) [W:Training Grounds][W:VH 2026-03] | Teaches skills safely | Mastery | [W:Training Grounds] | ADOPT | **Drills:** tiny 6×6 boards teaching adjacency, heat spreading, ideal temperature, Coolant, Amplifier; each pays a little | Mini-board scene | F62 | None | Authoring 10–15 puzzles |
| F83 | Loading hints | Tips on the loading screen, e.g. "Check the shore!" [W:Loading Screen Hints] | Passive teaching | — | [W:LSH] | ADOPT | Rotating tips and Codex teasers | — | F34 | None | Localisation |
| F84 | Narrative voice | A villager narrates milestones; the native islander's story unfolds over the first 8 liberations; Dr. T taunts after stages [W:Builder][W:Native Islander][W:Dr. T] | Personality; story drip | Motivation | [W:Native Islander] | ADOPT | The Foreman comments at milestones; a lore drip over the first N sites claimed | Foreman | F34 | None | Writing and TR/EN localisation |

### 2.11 UI/HUD & information design

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F85 | Events sidebar | Lists active events and **how to unlock** each, a completed state, and an arrow that jumps to it [W:VH 2024-09, 2024-11] | Hidden features become discoverable | Direction | [W:VH] | ADAPT | A **Locked** panel: every locked system (world ring, trial, Resonator) with its exact unlock condition | Core levels | F56 | Calendar part dropped | None |
| F86 | Resource breakdown | Tap a resource to see its production, capacity and protection [OF-S:resources-the-trader] | Transparency | Understanding | [OF-S:resources] | ADOPT | Tap a material → per-machine rates, the heat-efficiency loss, cap | Sim stats | F38 | None | Collecting rates cheaply |
| F87 | Honest info popups | The statue popup shows the **maximum possible** percentage ("It was not obvious you could get better"); range and boost totals shown [W:VH 2023] | Players understand the ceiling | Informed goals | [W:VH] | ADOPT | Relic/machine cards show the current value, the max, and the source of each bonus | F47 | F86 | None | None |
| F88 | Cycle-sites button | Switch between dive sites with one button [W:VH 2023] | Navigation on a big map | QoL | [W:VH] | ADOPT | "Next site" button in the world view (next ready haul or next surveyable region) | F19 | F30 | None | None |
| F89 | "Next ready" indicator | The Landing Craft shows when the next troop is ready, not only when all are [W:VH 2024-09] | Granular feedback | Clarity | [W:VH] | ADAPT | Each machine shows its next-output progress; the Core row shows the next unmet condition | Sim | F86 | None | None |
| F90 | Player profile & stats | Loadouts, records, Cycle of Evil best runs, best seasons; tracked from June 2026 [OF-S:player-profile][W:VH 2026-06] | Personal history | Pride | [OF-S:player-profile] | ADOPT (local) | Stats page: shafts collapsed, deepest stratum, best trial, total output | Save stats | F57, F77 | None | None |
| F91 | Shop UX | Category tabs; bought/claimed offers stay visible with a status label; skins you own are hidden [OF-B:frontline] | Clarity; no confusing offers | — | [OF-B:frontline] | ADOPT | The 2 one-time purchases show "Owned" with the date; never re-offered | Billing plugin | F116 | None | Restoring purchases offline |

### 2.12 Notifications

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F92 | Push set | Supply Chest ready; Trader arrived/leaving; statue boost ends in 30 min; Mega Crab attacks full; prototype expired; "Commander, your troops are waiting" after 3 days away [W:Notifications] | Re-engagement | Retention | [W:Notifications] | ADAPT | **Opt-in local notifications only:** "Haul Dock full", "store at cap", "relic roll ready". **No absence nags** | Godot local notifications | F1, F38 | The 3-day guilt message conflicts (daily-login guilt) | Android 13+ permission; exact alarms |

### 2.13 Quality of life

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F93 | Gameplay Options | Toggles: grey arrows, full-health health bars, camera shake, **dark-mode clouds** "for players who play in the dark", hint text, enemy gadgets shown by default [W:VH 2023-11, 2024-09, 2024-11, 2026-09][OF-B:blitz] | Personalisation / accessibility | — | [W:VH] | ADOPT | Options: markers, heat-overlay intensity, camera shake, dark overlay, Foreman chatter | Settings save | F10 | None | None |
| F94 | Batch actions | Boost all statues from the Sculptor; remove buildings by type; Claim All [W:VH 2023] | Fewer taps | — | [W:VH] | ADOPT | Collect all; upgrade all affordable of one type; store all by type | F9 | F74 | None | Clear confirmation text |
| F95 | Safe collect | The Resource Boat needs two steps to collect, shows how much it holds, and has a larger hitbox [W:VH 2023] | No accidental collects; shows the value | — | [W:VH] | ADOPT | The Haul Dock shows its contents; a large tap target | F1 | F38 | None | None |
| F96 | No pile-up while away | Invasion timers pause after 14 h without a login [W:VH 2024-06] | Returning is not overwhelming | Trust | [W:VH] | ADOPT (principle) | Anything that spawns in the world pauses while you're away; only production continues | — | F31 | None | None |
| F97 | Free queues | Extra Sculptor queue slots (Boom Pass / Sonar Shop) [W:Sculptor] | Less waiting | — | [W:Sculptor] | ADAPT | A free relic queue of 2–3 | F47 | — | Paywalled in Boom Beach | None |

### 2.14 Customisation

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F98 | Skins | Skins for buildings, troops, island and villagers, changed from the HQ paint icon; from the pass or Camo Tickets [W:Skins][OF-S:buildings-boats-2] | Expression | — | [W:Skins] | ADAPT | Machine and yard skins earned from achievements and landmarks; **one of the two one-time purchases can be a cosmetic pack** | Art | F57, F116 | Pass/ticket sources rejected | Art cost |
| F99 | Trophies & decorations | Mega Crab trophies (Stone/Iron/Gold/Diamond/Legendary with a numeral); Warships trophies; decorations have no gameplay effect and can be stored [W:Decoration][W:Mega Crab] | Show-off; long-term goals | Collection | [W:Decoration] | ADOPT | Depth, trial and stress-test trophies placed in the yard; storable | F66 | F57 | None | Placement rules on the 44×44 board |
| F100 | Date-based flavour | Frosted pines in winter; villager birthday hats in March; free Beachmas tree [W:Obstacles][W:Builder][W:Decoration] | Freshness | — | [W:Decoration] | ADOPT (flavour only) | Snow on yard props in December, from the device date; nothing to collect or miss | — | — | Must not give rewards (FOMO) | Device-clock tampering doesn't matter |
| F101 | Emblem builder | Task Force logo from 3 layers: 3,360 combinations [W:Task Force] | Identity | — | [W:Task Force] | LATER | A company emblem/name on the Core | — | F98 | None | Tiny |

### 2.15 Endgame & old-stuff-stays-valuable

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F102 | Salvage ladder | Salvaging an Idol gives a Shard; a Guardian gives a Crystal; a Masterpiece gives 7 Powder [W:Statue] | Duplicates and weak rolls are never worthless | Collection loop | [W:Statue] | ADOPT | Relic salvage → next-tier shard / overcharge | F47 | F48, F50 | None | None |
| F103 | Late systems eat early currency | Engraver (HQ 27) runs on Shards; Monument accepts any resource; Raw Crystals consume basics [W:Engraver][W:Mystical Monument][W:Tribes] | Early materials stay relevant | Economy health | [W:Engraver] | ADOPT (principle, matches P2) | Late sinks (Monument, Refinery, Big Orders) ask for Ore/Gravel/Ingot too | F39, F42 | F65 | None | None |
| F104 | Reward plateau | Threat rewards stop growing after 26; old difficulties can be downgraded [W:Dr. T Threat Stages] | Climbing is for prestige, not required | Fairness | [W:Dr. T Threat Stages] | ADOPT | Trial rewards plateau; past that point only trophies | F62 | F99 | None | None |

### 2.16 Anti-frustration & fairness

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F105 | No-loss failure & persistent progress | Losing to Hammerman costs no resources and allows retries; damage persists across attempts at Crab/War Factory/Imitation [W:HSB][W:Mega Crab] | Failing without punishment | Experimentation | [W:HSB] | ADOPT | Trials and stress tests never cost your factory anything; progress carries over | — | F63, F65 | None | None |
| F106 | Pity / guarantees | Recruitment guarantees (Rare Gadget at 10 pulls, Epic at 55, Sergeant at 40, Lieutenant at 80); Research Tokens [W:Recruitment][OF-S:drop-chances][W:Engraver] | Caps bad luck | Trust | [OF-S:drop-chances] | ADOPT (for earned rolls) | Relic rolls show their odds; a guaranteed top band after N rolls | F47 | F51 | Gacha itself rejected | Save the counter |
| F107 | Predictable crate cycle | The Trader crate rarity follows a fixed, repeating cycle that players can track [W:Trader] | Removes surprise-driven frustration | Planning | [W:Trader] | ADOPT | Milestone crates follow a visible fixed cycle | F4 | F3 | None | None |
| F108 | Cancel refunds | Cancelling a statue refunds its stones [W:Statue] | Undo | Safety | [W:Statue] | ADOPT | Cancel any relic or queued upgrade for a full refund | — | F18 | None | None |
| F109 | Vault / Insurance | Protects a share of resources from raids (50% outside the Vault at level 1 after Jan 2026) [W:Vault][W:VH 2026-01] | Softens PvP loss | — | [W:Vault] | REJECT | N/A: nothing can be stolen in Lodeworks | — | — | Vision: no stealable resources | — |

### 2.17 Accounts / settings / accessibility

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F110 | Supercell ID | Cloud save; switch accounts from the profile; log in before the tutorial [OF-B:frontline][OF-B:blitz] | Device changes | — | [OF-S:saving-your-account] | ADAPT | Local **save export/import** (file/code); optionally Google Play Games saved games (a third-party service, not our own server; **Inference**) | Save format | F80 | Your own server rejected | Save versioning; tamper tolerance is fine offline |
| F111 | Age prompt | Old accounts without an age are prompted [W:VH 2025-06] | Compliance | — | [W:VH] | ADAPT | **Inference:** an age/consent step is likely needed for AdMob (UMP, families policy) | F75 | — | None | Consent SDK integration |
| F112 | PC version | A Windows launcher (2026) [W:VH 2026-04][OF-B:frontline] | Reach | — | [W:VH] | LATER | Godot desktop export is cheap later | — | — | None | Input and UI scaling |

### 2.18 Monetisation (for rejection analysis)

| # | Feature | What | Solves / adds | Core | Src | Fit | Adaptation | Dep | Rel | Conflict | Challenges |
|---|---|---|---|---|---|---|---|---|---|---|---|
| F113 | Diamonds | Premium currency to finish timers, buy missing resources, reroll, convert [OF-S:resources-the-trader][W:Builder] | Monetised impatience | — | [OF-S:resources] | REJECT | — | — | F114–F117 | Premium currency; changes economy numbers | — |
| F114 | Subscriptions | Extra Builder; Instant Training; an auto-renewing subscription was removed at one point [W:VH][W:Builder] | Recurring revenue | — | [W:VH] | REJECT | — | — | — | Vision: no subscription | — |
| F115 | Recruitment gacha | Keycards; banners; a free pull every 22 h; pity; duplicates → talents/Circuit Blocks [W:Recruitment][OF-S:drop-chances] | Collection monetisation | — | [W:Recruitment] | REJECT | — | — | — | Vision: no gacha | — |
| F116 | Offers / web store / event passes | IAP bundles, Supercell Store, a $4.99 event pass, an $8 Boom Pass [W:VH 2026-04][W:LDE][W:Seasonal Missions] | Revenue | — | [W:VH] | REJECT (except 2 one-time cosmetic/QoL buys that don't touch economy numbers) | e.g. "Supporter skin pack" + "Extra blueprint slots / theme" (**Inference**: check that blueprint slots don't affect economy) | Billing | F98 | — | Restore purchases |
| F117 | Paid rerolls / conversions | Trader 20 Diamonds; Monument 20 Diamonds; missions 5, +5; shards→crystal 10 Diamonds; module conversion; Warships node switch 100 Diamonds [W:Trader][W:Mystical Monument][W:Power Stone][W:Weapon Lab][W:Tech Tree] | Revenue from RNG | — | several | REJECT (paid) → ADAPT free or credit-based | Credits reroll with a rising cost | — | F42, F43 | Premium currency | None |

**Addendum coverage map:**

- Units & characters: F52, F60
- Combat: F59
- Map & exploration: F19–F36
- Quests: F72, F81, F29
- Events: F61–F70
- Production & trade: F1, F2, F25, F26, F39, F43
- Region development: F40, F41, F36
- Social: F76–F79
- Competition: F77, F66
- Collections: F47–F50, F57, F99
- Rewards: F4, F23, F74, F75
- Retention mechanics: F1, F4, F5, F61, F92
- Monetisation: F113–F117, F75
- UI/UX: F85–F91, F93–F95
- Player motivation: F12, F56, F84, F87
- Long-term progression: F42, F47, F53, F103
- Systems that bring players back: F1, F4, F32, F92, F96

---

## 3. Complementary clusters (how they would work together in Lodeworks)

1. **The world beyond the yard.** This fills the unused `ResourceNodes` (answers P4, "kaynak düğümü").
   - **Flow:** World view (F19) → survey fog rings for credits, 2–3 offered at a time (F20, F21), with vents, seams and landmarks showing through the fog (F22) → surveying reveals caches (F23) and lore scraps (F34, F29) → you claim sites (F25), whose type sets their output (F24) and whose distance sets their richness (F36) → output flows to the Haul Dock (F1, F95) plus a small stipend (F26) → finishing a region's survey unlocks its guild (F40) → a developed region can be auto-harvested (F41) → an optional seismic minigame finds extra pockets (F68) → the Logbook reports all of it (F32).
   - **Why it fits:** everything is single-player, deterministic, and has no real-time gates.
2. **Permanent power from the world (Collapse-proof).** Answers P6, "what does a collapsed shaft keep".
   - **Flow:** site materials (F24) → Resonator relics (F47) with visible bands and max values (F87) → a relic shelf (F49) → salvage ladder (F102, F48) → overcharge (F50, with a rewarded-video hook F75) → pity (F106).
   - **Why it fits:** relics and guild levels survive Collapse, while the shaft, the Core store and the per-shaft tree (F53) reset. That gives every new shaft a "stronger foundation" without keeping Core levels.
3. **Replayable PvE without a calendar.**
   - **Flow:** Pressure Trials (F62, which reuse the 12 strata modifiers) + Stress Test on your own yard (F63) + Big Orders (F65) + Deep Trial (F66).
   - **Shared rules:** preview first (F3); difficulty labels relative to the player (F69); fast-forward (F6); no-loss retries (F105); plateaued rewards (F104); trophies (F99); try-before-unlock machines (F67).
   - **Result:** this replaces Boom Beach's Cycle of Evil and Mega Crab with always-available content.
4. **Guidance stack.**
   - **Flow:** affordable markers (F10) → What now? with tap-to-focus, pin and progress toasts (F11, F72) → Apprentice ledger (F81) → Drills for adjacency and heat (F82) → Roadmap / Path of Glory (F56) → Locked-features panel (F85) → Foreman voice (F84) → honest info cards (F86, F87).
5. **Rebuild speed after Collapse (P7).** Blueprints (F9) + batch actions (F94) + the early-compression principle (F55) + a first-shaft bonus pool (F54). Later: blueprint share codes (F79) and "beat your old line" (F64).
6. **Surplus sinks & economy hygiene.** Cap feedback (F38) + a Refinery that resets per Collapse (F39) + guild boosts (F40) + Monument (F42) + milestone-triggered Trader exchange (F43) + rubble clearing (F8). Principle: late sinks accept early materials (F103).
7. **Monetisation that fits the vision.** Rewarded video only at optional, capped moments (F75: second crate pick, double a haul, one overcharge), a consent flow (F111), and one cosmetic pack (F98/F116). Never premium currency, subscriptions or gacha (F113–F117).

---

## 4. Top 15 recommendations (ranked by value ÷ effort)

1. **Affordable-upgrade markers + tap-to-focus in What now? (F10, F11).** Tiny effort, and it answers "what can I do now" on every screen.
2. **Cap hygiene + Claim All + hold-to-confirm (F38, F74, F18).** A few UI rules that stop waste and accidents, which builds trust in an idle game.
3. **Blueprints / saved layouts (F9).** Medium effort. They cut the repetitive rebuild after every Collapse that the scripted player already shows (P7).
4. **Claimable world sites + Haul Dock (F25, F1).** The single biggest fix for the empty world around the yard, and a natural "come back to collect" loop with no timers.
5. **Survey fog rings with teasers and one-time caches (F20–F23).** Turns the world into a credit sink and a curiosity engine, gated by Core level.
6. **Milestone crates, choose 1 of 3, with a rewarded-video second pick (F4, F75).** Low effort; rewards progress rather than time, and it's the cleanest ad hook that fits the monetisation rules.
7. **Resonator & Relics that survive Collapse (F47–F49, F102).** Gives collected world material permanent, capped, additive power and answers P6 without keeping Core levels.
8. **Stress Test on your own yard (F63).** High-value PvE that tests the real adjacency/heat layout, with a preview, free retries and no loss. Medium effort because it needs a sandboxed deterministic sim.
9. **Pressure Trials with a downgrade button and plateaued rewards (F62, F104, F69).** Reuses the 12 strata modifiers for endless optional challenge without a calendar.
10. **Drills (F82).** Cheap mini-boards that teach heat and adjacency, the concepts players most likely misunderstand.
11. **Apprentice ledger + Roadmap (F81, F56).** Low effort; clear early goals and a "what's ahead" view that never expires.
12. **Logbook with jump-to (F32).** Low effort; makes offline production readable and turns each return into a satisfying summary.
13. **Refinery + Region guilds, reset per Collapse (F39, F40, F41).** A medium-effort surplus sink that makes each shaft play a bit differently and automates old chores later.
14. **Landmark sites & derelict repairs (F27, F28).** Handcrafted big goals in the world that unlock machines or trials; a few bespoke scripts give a lot of identity.
15. **Monument endless sink (F42).** Late-game catch-all for surplus with visual milestones; low risk because its bonuses are small and capped.

---

## 5. Explicit REJECT list (with reasons)

| Feature | Reason |
|---|---|
| Daily Reward boat (F5), Cycle of Evil weekday schedule (F61), weekly Trader timing (F43, calendar part), weekly mission drip (F72, drip part), biweekly tribe/crystal resets (F39/F40, calendar part) | **Conflicts with an existing decision (daily/weekly chores, streaks)**; daily-login guilt |
| Task Forces, chat, Intel, Operations, Force Points, Sabotage, Friendly Challenges (F76); leaderboards of all six kinds and top-player bounty (F77); friends/visits (F78); Community events, Blitz (F70); Imitation Game (F64, server version); online Base Builder (F79, server version) | **Conflicts with an existing decision (multiplayer/social/leaderboards need a server)** |
| Black Markets and their coins (Evil/Sonar/Card/Circuit/Event, expiring) (F44); Time Savers (F47); Build Tokens, Camo Tickets, Keycards and the rest | **Conflicts with an existing decision (currencies as a content treadmill)** |
| Diamonds / premium currency, instant finish (F113) | Changes economy numbers; the vision forbids it |
| Subscriptions: Extra Builder, Instant Training (F7, F114) | No subscription; builder limits are timer gates |
| Recruitment gacha: Keycards, banners, pity pulls (F60, F115) | No gacha |
| Boom Pass and Event Pass (F71, F73) | Season pass = FOMO/subscription-like; paid tracks change the economy |
| Paid rerolls and conversions (F117) | Premium currency; make them free or credit-based instead |
| Vault / Insurance (F109) | Nothing can be stolen in Lodeworks |
| Mega Crab attempt cap (40 attacks) and monthly window (F66, those parts) | An energy-like limit plus a calendar |
| Real-time expeditions and expiring prototypes (F30, F15, time parts) | Timers as gates; use production-tick or instant versions |
| Absence notifications ("troops are waiting" after 3 days) (F92, that part) | Daily-login guilt |
| Troop/Gunboat combat (F59) | Out of genre |

---

## 6. Sources (retrieved 25 Sep 2026)

**Official: Supercell blog [OF-B]**
- [OF-B:archive] https://supercell.com/en/games/boombeach/blog/ (post list up to "September Maintenance", 24 Sep 2026)
- [OF-B:blitz] https://supercell.com/en/games/boombeach/blog/blog/september-update-blitz/ (15 Sep 2026)
- [OF-B:sept] https://supercell.com/en/games/boombeach/blog/blog/this-september-on-boom-beach-2/ (28 Aug 2026)
- [OF-B:frontline] https://supercell.com/en/games/boombeach/blog/blog/frontline-improvements/ (22 Apr 2026)

**Official: Supercell Support Portal [OF-S]** (content extracted from the page's embedded data)
- [OF-S:sculptor] …/boom-beach/en/articles/the-sculptor-statues-power-stones.html
- [OF-S:great-archipelago] …/articles/the-great-archipelago.html
- [OF-S:resources] (also cited as [OF-S:resources-the-trader]) …/articles/resources-the-trader.html
- [OF-S:buildings-boats-2] …/articles/buildings-boats-2.html
- [OF-S:cycle-of-evil] …/articles/the-cycle-of-evil-weekly-events.html
- [OF-S:mega-crab] …/articles/mega-crab.html
- [OF-S:drop-chances] …/articles/drop-chances.html
- [OF-S:boom-pass] …/articles/boom-pass.html
- [OF-S:player-profile] …/articles/player-profile.html
- [OF-S:whats-new-9] …/articles/whats-new-9.html
- [OF-S:black-markets] …/articles/black-markets.html
- [OF-S:social] …/articles/social.html
- [OF-S:saving-your-account] …/articles/saving-your-account-to-supercell-id.html (title seen in the portal index only; content not read)
- Base URL for all of the above: https://support.supercell.com/boom-beach/en/

**Fandom wiki [W:Page]**
- Pattern: https://boombeach.fandom.com/wiki/<Page>, fetched through https://boombeach.fandom.com/api.php?action=parse&page=<Page>&prop=wikitext&format=json
- Pages used: Archipelago, Resource Base, Radar, Sculptor, Statue, Power Stone, Statue Storage, Engraver, Power Powder, Tribes, Freed Village, Native Islander, Mystical Monument, Nature's Boon, Recruitment, Trader, Submarine, Sonar Ops, Boom Academy, Victory Point, Rank, Intel, Task Force, Operation, Force Point, Mega Core, Dr. T, Dr. T Threat Stages, Terror Stages, Events, Black Markets, Leaderboard, Seasonal Missions (Boom Pass), Mega Crab, Mega Turtle, Attackable Statue, Hammerman Strikes Back (Threat) [W:HSB], Imitation Game, The War Factory, Leader Deployment Event [W:LDE], Warships, Tech Tree, Warships Boosts, Loot System, Builder (Villager), Worker, Obstacles, Notifications, Time Saver, Insurance, Experience, Achievements, Vault, Classified Items, Decoration, Skins, Weapon Lab, Training Grounds, Boss Base, Blackguard Base, Blackguard Base Builder [W:BBB], Residence, Hero Hut, Blackguard, Loading Screen Hints [W:LSH], Supply Buildings, Starter's Tips.
- Abbreviations used in the tables: [W:HSB] = Hammerman Strikes Back (Threat); [W:LDE] = Leader Deployment Event; [W:BBB] = Blackguard Base Builder; [W:LSH] = Loading Screen Hints.
- [W:VH <date>] = https://boombeach.fandom.com/wiki/Version_History, the wiki's dated transcription of official patch notes and maintenance posts. The cited dates include 2023 (undated entries), Nov 2023, Feb 2024, Jun 2024, Sep 2024, Nov 2024, Jun 2025, Aug 2025, Nov 2025, Jan 2026, Mar 2026, Apr 2026, Jun 2026 and Sep 2026.

**Press / reference**
- [PR-WP] https://en.wikipedia.org/wiki/Boom_Beach

**UNVERIFIED / conflicting points**
- **Hammerman Strikes Back unlock:** HQ 5 per [W:HSB], but "HQ 15 + Weapon Lab" per [OF-S:cycle-of-evil]. The support text may be outdated.
- **Tribe areas:** rearranged in June 2025 and "reverted between Oct 2025 and Mar 2026". The wiki itself flags this "Confirmation needed" [W:Tribes].
- **Blitz:** its details beyond "week-long, multiple stages, global/local leaderboards, starts 2 Oct 2026" are not yet published [OF-S:whats-new-9].
