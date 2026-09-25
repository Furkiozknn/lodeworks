# Clash of Clans: full feature inventory for Lodeworks (state as of September 2026)

**How to read this**

- **Source keys.** [O#] are official Supercell sources: supercell.com release notes and blog, and the Support Portal. [W#] are Fandom wiki pages, read through the API on 25 Sep 2026. Press was used only to find official URLs; no fact rests on it.
- **Inference** marks my own reasoning. **UNVERIFIED** marks what I could not confirm.
- **Fit ratings.**
  - **ADOPT:** take as is.
  - **ADAPT:** reshape for Lodeworks.
  - **LATER:** needs a system Lodeworks has not built yet.
  - **REJECT:** conflicts with the vision or adds clutter.
  - **REJECT (existing decision):** conflicts with something Lodeworks has already ruled out: daily or weekly chores and streaks; multiplayer, leaderboards or social features that need a server; extra currencies as a content treadmill.
- **Overlap with the existing research.** `docs/research/clash-ux.md` (25 Sep 2026) already covers onboarding, "what next", the social layer, and proposals named Worklist, Ledger, Factory Tours, Second shaft and Celebrations. I refer to those by name instead of repeating them.
  - Under the existing decisions, its server-based ideas (Union, Requisitions, Union Works, Output Trials) and its weekly "Rock of the Week" now count as rejected.
  - Factory Tours shares layouts by code with no server, so it survives.
- **Numbers.** All numbers below are Clash's, given for context. Do not copy them; tune every Lodeworks number with its own tools (clash-ux.md §10.5).

---

## 1. Overview

**Modes**

- **Home Village.** The main base, Town Hall 1–18. Town Hall 18 arrived on 17 Nov 2025; no source up to Sep 2026 mentions a Town Hall 19 [W2][O10].
- **Builder Base.** A second village with its own builders, lab and economy, reached by boat. Its battles are asynchronous and nothing is stolen [W4].
- **Clan Capital.** A mountain of 8 districts plus Capital Peak, shared by a clan, built from pooled Capital Gold and raided on weekends [W26].
- **Solo play against the computer.** A 90-level Goblin campaign, 19 Practice levels and limited-time Attack Challenges [W35].

**Loops by time scale**

- **Minutes.** Attack, loot, spend on upgrades, attack and defend better.
  - Since Mar 2025 armies need no training time and heroes need no healing [W2][O7].
  - Since Oct 2025 a no-stakes "Battle" mode sits beside a limited "Ranked" mode [O6].
- **Day.**
  - Builder timers finish: 5 Builder's Huts, the robot builder B.O.B, the Builder's Apprentice and event goblins [O17][O15][W19].
  - The Star Bonus: win 5 stars for a bonus; up to 2 can stack [W22].
  - One 23-hour workday for the helpers [O15].
  - One new season task card [O14].
- **Week.** Ranked tournament, starting Monday 17:00 UTC since Apr 2026 [W1]. Raid Weekend, Friday to Monday [W26]. The Trader's stock refreshes [W10].
- **Month.**
  - A season with a free Silver track, a paid Gold Pass and a "Hoggy Bank" [O14].
  - Clan War Leagues (CWL) [W28] and Clan Games [W25].
  - One or two medal events [W5].
- **Year.**
  - One new Town Hall a year: Town Hall 16 in Dec 2023, 17 in Nov 2024, 18 in Nov 2025.
  - About five feature updates a year [W1–W4].
  - A year-in-review recap in 2026 [O3].
- **Live content in September 2026.** A WWE-themed season: a clan "Money in the Bank Rush" event (1–5 Sep), a John Cena Attack Challenge unlocked through contracts found in chests, and an Equipment Blast medal event from 9 Sep [O8][W40][W35].

**Currencies (Sept 2026)**

- **Spendable, permanent:** Gold, Elixir, Dark Elixir, Builder Gold, Builder Elixir, Capital Gold, Raid Medals, League Medals, three Ores (Shiny, Glowy, Starry), Sparky Stones and Gems.
- **Score-like:** Season Points, Trophies, Builder Base trophies, Capital Trophies, Capital Reputation, Clan XP and player XP.
- **Per event:** every medal event adds 2 temporary currencies.
- **Stockpiled items:** 25 kinds of Magic Items, plus Wall Rings and Magic Snacks [W5][W7][W8][W15][W26][W28][W32][O19].
- **Inference:** about 13 spendable currencies after 14 years. This is the sprawl Lodeworks has already decided against.

**What moves Clash players (Inference, drawn from the systems above)**

- **Usable in Lodeworks:** mastery (attacks, layouts), progression (the Town Hall as the one number), collection (skins, equipment) and self-expression (layouts, sceneries, decorations).
- **Not usable:** social duty (war attacks, donations, raids), competition (leagues) and obligation clocks (daily bonus, streaks, event deadlines). Each needs a server, an obligation, or both.

**Friction keeps being removed (Inference, from [W38] plus later release notes).**

- Supercell's old "ruled out" list included several ideas it later shipped:
  - a resource converter (the Alchemist, 2025);
  - walls upgraded without a builder (Wall Rings, Aug 2026);
  - the return of Global Chat (2026);
  - Town Hall leaderboards (2026);
  - heroes usable while upgrading (in friendly battles, 2026).
- "Queue upgrades" is still on the ruled-out list [W38][W2][W1][O2].
- The long-term direction is less friction, so Lodeworks, which starts with none, is on the right side of it.

**Already covered elsewhere (one line each)**

- Town Hall caps and prerequisites: `progression-reference.md`.
- Builders as pacing: `clash-ux.md` §3.
- Storages as Town Hall gates: `progression-reference.md`.
- The Laboratory chain: `progression-reference.md`.
- Goals by cadence: `clash-ux.md` §4.

---

## 2. Feature inventory (150 features)

**Column guide**

- **Core role:** what the feature adds to the moment-to-moment loop.
- **Related:** row numbers it depends on or reinforces.
- **Challenges:** likely difficulties for a small, single-player Godot game.
- **Conflict:** clash with the Lodeworks vision, if any.

**Abbreviations used in the tables**

| Short | Meaning |
|---|---|
| TH | Town Hall (TH18 = Town Hall level 18) |
| BB / BH | Builder Base / Builder Hall |
| CWL | Clan War Leagues |
| DE | Dark Elixir |
| DPS | damage per second |
| SCID | Supercell ID (the account system) |
| B.O.B | the robot builder unlocked through the Builder Base |
| "L3→L4" | from level 3 to level 4 |

### 2.1 Core loop & session shape

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Clash Anytime | No training time for troops, spells or siege machines, and no hero healing, since Mar 2025; the Training Potion was removed | Waits of 15+ minutes between attacks; stated aim: remove frictions | "Play again" is instant | 2, 3 | W2, W30, O7 | ADOPT (principle) | Supports "no timers as gates". Check that no Lodeworks action (reroll, Descend, research) hides a wait | — | None; a design discipline | None |
| 2 | Battle / Ranked split | Oct 2025: unlimited regular Battles matched by Town Hall level, for farming; separate Ranked mode with limited weekly attacks and leagues | One matchmaking system could not serve different motivations; heavy play forced unwanted promotions | A casual loop with no stakes | 1, 98 | O6, W29 | ADAPT (principle) | Keep the main shaft stakes-free. Harder content (challenge boards #104, harsh strata) is optional and sits beside it | #104 | Another mode means more UI on a small screen | Ranked itself needs a server (#98) |
| 3 | Match Anytime clone bases | When a player gets a Shield, a clone of their base enters matchmaking; the attacker loots, the owner loses nothing | Keeps opponents available now that armies are instant | Endless opponents | 1 | W2, W30 | REJECT | — | — | Needs a server | Multiplayer |
| 4 | Fast Forward | A 4× speed button appears after 120 s of a battle; can be switched off in Advanced Settings (Aug 2026) | Dead time once the outcome is clear | Shorter sessions | 33 | W1, O2 | ADAPT | 4× only in the test-run sandbox and on challenge boards (#33, #104). The live factory already skips time through offline production | #33 | Same results at any speed; frame budget on low-end phones | None if limited to the sandbox |
| 5 | Star Bonus + Treasury | Win 5 stars to get bonus loot (plus Ore from Town Hall 8) paid into a protected Treasury; resets 24 h after completion; up to 2 can stack; a Town Hall upgrade gives a 4× Star Bonus for 3–5 days | Daily goal; income floor; celebrates reaching a new Town Hall | Daily anchor | 118, 56 | W22 | REJECT (existing decision) | Salvage one idea: a one-time payout when the Core levels up, not a timed boost | — | — | Daily cadence |
| 6 | Work continues while away | Resource collectors and construction keep running offline and during server maintenance; only some boosts pause | No lost time | Returning always pays | 121 | O25 | ADOPT (already built) | Offline production exists. Keep the rule: anything the player cannot use while away is paused, never wasted | Offline simulation | Already built | None |
| 7 | Loot economy | Most income comes from raiding other players; less loot from lower Town Halls, a bonus from higher ones (Oct 2025); a Loot Cart gives back 10% of what raiders took | Tension; a reason to defend | The core risk and reward | 130, 131, 122 | W2, W21 | REJECT | — | — | Needs a server | Stealable resources |

### 2.2 Units & characters

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | Villagers | Villagers wander about, clap at buildings, hide in the Town Hall during attacks, speak the tutorial and, since 2025, clear obstacles | Life on screen; a guiding voice; a sign that someone is working | The world feels alive | 103, 116, 126 | W41, W2 | ADAPT | 2–3 crew figures walk between machines, gather at the top "What now?" item and step back from overheated tiles (clash-ux 10.2.2) | Worklist, heat | Pathfinding on a crowded board; draw-call budget | None |
| 9 | Menu characters | The Trader, the Strongman (Clan Games), 4 Helpers, the Master Builder and the Goblin King; each one fronts a menu | Gives menus a face | Low | 38, 47, 63 | W10, W25, O15 | REJECT (clutter) | Keep the Foreman as the only voice | — | Art for each character | None |
| 10 | Heroes & Hero Hall | 6 heroes. The Hero Hall sets their level caps and gives 1–4 slots; attacking and defending heroes are chosen separately; Hero Banners mark where defenders stand | Build identity; separate attack and defence setups | Heart of the army | 45 | O32, W31, W3 | ADAPT (through #45) | Core slots that hold modules (#45); no hero units | #45 | — | Combat itself does not apply |
| 11 | Guardians | At Town Hall 18, choose one defender, Smasher or Longshot (Logger added Apr 2026); only one defends at a time; tapping it shows its patrol route | A choice at the top level that defines the base | Identity at the cap | 50–52 | W2, W1 | ADAPT | "Core Aspect": at the top Core level, pick 1 of 2–3 Core behaviours (for example a heat sink or a sale bonus); switch freely | Core levels | Keeping every aspect worth picking; test with core_journey | None |
| 12 | Pets | Companions that attach to heroes, raised in a Pet House (up to level 12) | More upgrade lines | Minor | 10 | O32, W1 | REJECT (clutter) | — | — | — | Only adds upgrade lines |

### 2.3 Combat & army (brief, mostly not applicable)

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 13 | Army roster | Elixir and Dark troops, Super Troops (3-day boosts), temporary event troops, siege machines, spells, troops donated to the Clan Castle | Variety in attacks | The heart of player-vs-player | 66 | W2, W5, W7 | REJECT (not applicable) | — | — | — | Not a combat game |
| 14 | Defences, traps & Town Hall weapons | Towers and traps; the Town Hall 12–15 weapon levels were removed in Oct 2025 to make progression smoother | Cuts filler levels | Base design | 40 | W2 | ADOPT (principle) | A machine level that changes nothing visible is a candidate to cut | Balance tools | — | None |
| 15 | Builder Base battles | Two-stage attacks, reinforcement troops, healing between stages, troop abilities you trigger; attacking earns Builder Gold, defending earns Builder Elixir; nothing is stolen | Short tactical battles; defending pays | A second loop | 17 | W4 | REJECT (not applicable) | Note only: "defending pays and nothing is stolen" matches Lodeworks' no-theft rule | — | — | Combat |
| 16 | Battle modifiers / Tournament Mode | Stat changes per league (for example defence damage per second +10% to +25%); an optional Hard Mode for friendly battles, now called Tournament Mode | Harder content without new content | Challenge | 98 | W1, W2 | ADOPT (already built) | Lodeworks' 12 strata modifiers already do this. At most, add an optional "hard" flag on challenge boards (#104) | #104 | — | None |

### 2.4 Map, regions & exploration

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 17 | Second village | The Builder Base, reached by repairing a boat at Town Hall 6: its own builders, lab and economy; tasks there unlock B.O.B for the main village; an extra Builder Base builder since May 2026 | Something to do while the main builders are busy; variety | A parallel track | 49 | W4, O17, W41, W1 | LATER | clash-ux 10.2.13 "second shaft": same material types (no new currencies), and one link reward visible from day one | Saves for several factories; a shaft switcher | Two offline simulations; save size; switching UI | Separate currencies would conflict |
| 18 | Second-stage caps | At Builder Hall 6 a second stage opens with its own hall; defences, walls and traps are capped per stage (at Builder Hall 10: 14, 100 and 12) | Growth without sprawl | A layout constraint | 17 | W4 | REJECT (clutter) | — | — | — | Extra rules for a single board |
| 19 | Fixed district terrain | Each Capital district has fixed rivers, cliffs, bridges and bushes that shape placement and paths | Every map is its own puzzle | A placement puzzle | 43 | W26 | ADAPT | Fixed terrain generated from a seed for each band of strata (vents, cracks, cold pools) that blocks or changes tiles. Fits plan P4, including the resource nodes already generated but unused | Strata generation, P4 | Old saves; terrain readable when zoomed out | None |
| 20 | Visible ruins | The Clan Castle, boat, Clock Tower and Gem Mine start as ruins you repair | Shows what is coming without text | Anticipation | 105 | W23, W41 | ADOPT (already proposed) | clash-ux 10.2.3: covered crates at the Core's edge | — | One prop per band of strata | None |
| 21 | Goblin campaign | 90 hand-made levels, 270 stars in total, loot you can take once, no time limit, retries allowed | Risk-free content that lasts | A ladder of solo levels | 104, 73 | W35 | ADAPT | A "survey map" that links challenge boards (#104) into a path | #104 | Level design time | None |
| 22 | Community dungeon event | Feb 2026: all players worked through a maze of doors together to free a new hero | Excitement around a launch | Event | 70 | W1 | REJECT (existing decision) | — | — | Needs a server | Server |

### 2.5 Base building & layout tools

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 23 | Village Edit Mode | Clear the base into an inventory and rearrange it; saves automatically; recovers after a disconnect | Redesign without tedium | Layout craft | 24–28 | W13 | ADAPT | Blueprint editor (plan P7): stash machines to the tray, place, save, recover after a crash | Blueprint saving (GAP-AUDIT A1) | Undo; a big board on a small screen | None |
| 24 | Layout slots | 3 home layouts and 6 war layouts; war slots 4–6 cost 1,000, 1,500 and 2,000 Gems | Several plans; preparing the next tier | Planning | 23 | W13 | ADAPT | Free blueprint slots; the Foreman's Licence's 2 extra slots (README) stay a convenience only | #23 | Converting old saves | Paid slots are fine only as the existing one-time purchase |
| 25 | Move-all & photo mode | Edit tools added May 2016: move everything, walls-only view, scout view, hide the interface for screenshots | Speed; showing off | Low | 23, 95 | W13 | ADOPT | "Shift the whole layout" plus a photo mode that hides the interface | #23 | Cheap | None |
| 26 | Copy a layout | Copy a clanmate's base (within 1 Town Hall level); missing buildings show as gaps, extra buildings go to the inventory | Learn from others | Learning | 27 | W13 | ADAPT | When importing a code, missing machines show as faint "ghost" outlines and extras stay in the tray | #27 | Players have different unlocks | None |
| 27 | Layout links | Share a snapshot of a base as a link; links expire if unused | Sharing outside the game | Showing off | 26 | W13 | ADAPT | Factory Tours share code (text or QR) sent through the Android share sheet; no server (clash-ux 10.2.10) | #23 | Code versioning and length | None without a server |
| 28 | Planned vs active layout | A defence layout separate from the one visitors see (Builder Base 2024, Capital, Ranked snapshots) | Stops copying; a layout ready in advance | Planning | 23 | W3, W13, W29 | ADAPT | "Draft overlay": plan the next layout as ghosts while the factory runs, then apply it when affordable | #23 | Drawing ghosts; previewing costs | The anti-copying purpose does not apply |
| 29 | Tactical Overview | Before attacking, tap a building: every building of that type lights up with its range, mode, level and loot; also in edit mode since Sept 2024 | Read a base at a glance | Readability | 30, 110 | W3 | ADOPT | Tap a machine: every machine of its type lights up, with how far its heat reaches and its temperature against its ideal range; a heat overlay while placing | Heat model | Overlay cost on a 44×44 board | None |
| 30 | Building modes | Some buildings switch behaviour (Inferno Tower single or multi-target, X-Bow ground or air, Multi-Gear Tower long range or fast); the Crafting Station can cycle between defences | Choice without new buildings | Tactical choice | 52 | W3, W2, O29 | LATER | Machine modes unlocked by research (for example a Smelter "hot and fast" vs "cool and slow") | Research, heat | The number of combinations to balance grows fast | Clutter if there are many |
| 31 | Army Recipes & Cookbook | Save and share armies (Mar 2025); a Cookbook of starter armies for each Town Hall from Town Hall 4, plus featured and creator armies from Town Hall 10 (June 2025) | "What should I bring?" | Lowers the entry barrier | 23, 28 | W2 | ADAPT | "Line recipes": one starter production line per Core level, stamped onto the board as a ghost blueprint | #23, #28 | Recipes must fit the seeded terrain | Featured and creator recipes need live operations, so drop them |
| 32 | Obstacles & Shovel | Up to 45 obstacles; plants regrow at 1 per 8 h; 0–6 Gems each, and a Gem Box worth 25; a Shovel turns one into a movable decoration; seasonal obstacles are kept | Clutter to clear; small rewards; keepsakes | Small tasks | 79 | W36, W7 | LATER | Debris on each stratum, cleared once (no regrowth); a rare rock can become a decoration | Strata generation | — | Regrowth is a chore, so drop it |
| 33 | Attack your own base | A friendly challenge against your own village (Dec 2023) | Test a layout safely | Experimentation | 4, 104 | W4 | ADAPT | "Test run": copy the board into a sandbox, run N simulated minutes at 4×, report output, stalls and heat peaks; the save is untouched | Headless simulation (the tools already run it) | Keeping the sandbox separate; matching live results | None |

### 2.6 Production, economy, trade & sinks

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 34 | Collectors that fill up | Mines and collectors fill, stop at capacity and must be tapped to collect | Pressure to come back | Check-ins | 6 | W23 | REJECT | clash-ux 10.2.4: no tap-to-collect; the offline production window is the only cap | — | — | Mild guilt |
| 35 | Boosts & Runes | Double collector output for a day (Gems or a Resource Potion); a Rune fills one storage | Speed-ups to sell | Monetisation | 143 | W7, O9, W42 | REJECT | — | — | — | Timed boosts; sells economy |
| 36 | Converters | The Alchemist (Town Hall 11, 100 Gems) converts between Gold, Elixir and Dark Elixir with a bonus; the Prospector (from the Gold Pass) converts one Ore into another; each once per 23-hour workday | Fixes lopsided stock | A safety valve | 47 | O15, W18 | REJECT | Conversion stays a job for machines on the board | — | — | Daily cooldown; Gems |
| 37 | Forge | Makes a free batch of Capital Gold every 23 h; crafts more from resources over 3 days, using a builder | Feeds the clan project | Sink for surplus | 43 | W26 | REJECT | — | — | — | Timer; an extra currency |
| 38 | Trader | Weekly Magic Item offers for Gems or Raid Medals; free Glowy Ore every week; weekly limits | A weekly check-in | Sink for medals | 35 | W10, W32 | REJECT (existing decision) | — | — | — | Weekly cadence; a Gem shop |
| 39 | Refund rules | Cancelling an upgrade refunds 50%, officially to stop players hiding loot from raiders; cancelling obstacle removal refunds 100% | Stops exploits | — | 7 | O16, W36 | ADAPT | With no raiding there is nothing to hide loot from: moves are free and the last action can be fully undone. Keep a small loss only on selling, if sell-and-rebuy loops appear | Undo | Testing for exploits | None |
| 40 | Waves of cost cuts | Repeated cuts to cost and time across many Town Hall levels; 15 hero levels moved from Town Hall 15 to 14 (Oct 2025) | New and returning players catch up | Keeps the middle game moving | 132, 14 | W2, W3, W4 | ADOPT (practice) | When a Core level is added at the top, re-run core_journey and make the lower tiers cheaper, rather than making the new one harder | Balance tools | Old saves will feel different | None |
| 41 | "Storage full" signs | A "Full!" bubble on the Blacksmith when Ore storage is full; a red keyhole over the Clan Castle when the Treasury is full | Explains a silent stall | Readability | 42 | W3, W22 | ADOPT | A bubble over the Core or a Vault when a store is full or a chain is blocked, linked to the warning key | Warning system | At most one bubble per group of machines | None |
| 42 | Overflow is never lost | Extra loot waits in collectors, the Treasury or the Loot Cart; the Hero's Journey switch-over let storage overflow once; a temporary storage keeps items for 24 h, then sells them for Gems | No punishment for being full | Trust | 41, 132 | W21, W22, W17, W9, W3 | ADOPT | Rewards or offline output above the Core's store capacity go to a holding tray that never expires | Core store | Where it sits on a small screen | Drop Clash's 24-hour expiry |
| 43 | Shared builds, finished when funded | Clan members pour Capital Gold into any build; it completes instantly once fully funded; leaders flag up to 3 priorities per district | A shared goal with no timers | Sink for surplus | 44, 19 | W26 | ADAPT | Solo "Surface Works" monument: pour spare materials into sections that finish instantly and survive a collapse | Collapse rules (P6) | Must not become a required multiplier | The server part is dropped |
| 44 | Capital Treasury | June 2026: once the Capital is fully upgraded, all Capital Gold can go into a clan total that earns Reputation; the total resets when new content ships | Ends "fully upgraded, nothing to spend on" | An endless sink | 43 | W1, O2 | ADAPT | Once the Works are finished, further contributions raise a displayed tonnage record that earns cosmetic marks | #43 | — | None |

### 2.7 Progression beyond the Town Hall

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 45 | Hero Equipment | Each hero carries 2 of many items, some triggered and some always on; Common items unlock with Blacksmith levels, Epic ones come from events; items upgrade instantly with 3 kinds of Ore, and Gems can make up a shortfall (1, 5 or 35 Gems per Ore) | Build variety; a long sink | Choosing a loadout | 10, 46 | W4, W32 | ADAPT | Core modules: 2–3 Core slots filled with modules unlocked by research and strata, raised instantly with existing materials (Plates, Components), with no Ore | Core, research | Slot interface on a small screen; balance | Ore-like currencies would conflict |
| 46 | Hero's Journey | June 2026: a reward track filled by the total of all hero levels (1 point per level); pays Epic equipment, skins, resources and quests; bigger Ore rewards for players "very far behind"; existing players were placed on it with what they had already earned | Rewards progress already made | Every upgrade also moves the track | 77, 132 | O1, W17, O2 | ADAPT | A track filled by the total of all machine levels, with fixed rewards (cosmetics, a blueprint slot, Codex lore); old saves receive the rewards they have already reached at once | Machine levels (built) | Track interface; testing the switch-over | 14-day quests dropped (#62) |
| 47 | Helpers | The Lab Assistant (free, Town Hall 9) and the Builder's Apprentice (500 Gems, Town Hall 10) each speed up one job for 1 hour per 23-hour workday; at level N a helper saves N hours; option "keep assigned until complete" | Daily control over timers | A daily ritual | 36, 48 | O15, W18, W3 | REJECT | — | — | — | Timers; a daily ritual |
| 48 | Goblin workers | "Work for Hire" events: hire an extra builder or lab slot for Gems (40 Gems per day of work) | Bursts of progress | Monetisation | 47 | W19 | REJECT | — | — | — | Timers; Gems |
| 49 | B.O.B | A 6th builder for the main village, unlocked through Builder Base tasks (3 "Gear Up" upgrades, a Builder Base troop at level 18, a defence at level 9, 45 hero levels) | A reason to play the second village | A link between the two villages | 17 | O17, W4 | LATER | A reward from a second shaft (#17) that helps the main one | #17 | Designing a link reward worth having | None |

### 2.8 Endgame & "old stuff stays valuable"

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 50 | Supercharge | Fully upgraded buildings get extra, cheaper and shorter upgrades: 2 for defences, 3 for collectors; boosted stats show in cyan and the building glows; they are removed when a new level ships (with a warning first) and were later compensated with Sparky Stones | "Fully upgraded" still has something to do | A late-game sink | 51, 53, 54, 135 | W16, O28, W2 | ADAPT | "Overdrive": 2–3 permanent extra tiers for each machine type once it reaches its Core cap, paid in materials from shallower strata, with a visible glow | Machine levels, Core caps | Must not use up the room meant for the next Core level | Drop the removal on each update |
| 51 | Merged defences | From Town Hall 16, two fully upgraded defences merge permanently into one stronger building (Ricochet Cannon, Multi-Archer Tower, Multi-Gear Tower, Super Wizard Tower) | Frees space; a new step up in power | Changes layouts | 50 | W4, W2 | ADAPT | "Twin machines": two neighbouring fully upgraded machines of the same type merge into one machine with higher output, freeing a tile; permanent | Machine levels, adjacency | Adjacency and heat rules for the merged tile | None |
| 52 | Crafted Defences | From Town Hall 17, a Crafting Station offers 3 defences per phase, 1 active and swappable at any time; each has 3 modules up to level 10; phases last 4 months (first announced as 3); old ones turn into Sparky Stones | Stats the player shapes; novelty | A customisable endgame | 30, 53 | W14, O29, W2 | ADAPT | "Prototype bay": one modular machine at the top Core level; the player chooses which of its 3 modules to raise; variants swap without losing module levels; permanent | Core cap, #50 | Module interface; balance against normal machines | Seasonal rotation dropped (existing decision) |
| 53 | Fancy Shop & Sparky Stones | 10 stones per Supercharge and 8 per crafted-module level (holding cap 5,000); they buy a builder skin, a decoration and glowing effects | A cosmetic payoff for endgame work | Motivation at the cap | 50, 52 | W15, W2 | REJECT (existing decision) | Overdrive tiers unlock their cosmetic directly, with no currency in between | — | — | An extra currency |
| 54 | Mastery visuals | Supercharged buildings glow more with each step; boosted stats show in cyan; decorations can carry the same effect, which can be switched off | Status at a glance | Pride | 50 | W16, W15, W1 | ADOPT | Overdriven machines glow; the Core shows one pip per overdriven machine type | #50 | Cost of the glow on phones; an off switch | None |
| 55 | Old buildings, new roles | Builder's Huts become turrets that repair defences (Town Hall 14); the Eagle Artillery was folded into the Town Hall 17 weapon | Old investments stay useful | Depth | 51 | O17, W3 | ADAPT (principle) | Give early machines late-game roles, for example deep seams that only a high-level Drill can open | Strata generation | Making the new roles readable | None |

### 2.9 Quests, tasks & reward tracks (passes)

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 56 | Season task cards | 4 cards at the start of a season, then 1 more a day even if you do not log in; cards pile up for the whole month (up to 31); each has 8 tasks, 7 to finish | Monthly points without punishing missed days | Daily goals | 57–59 | O14, O5 | REJECT (existing decision) | Only its rule "cards pile up and never expire" should shape any future track | — | — | Daily cadence |
| 57 | Choice nodes | Points on the season track where you pick 1 of 2 rewards (for example the current or a classic skin, a Rune of Gold or of Elixir); defaults to the first | Rewards that fit the player | Small decisions | 46, 77 | O5 | ADAPT | Reward points on the Journey or Ledger offer 1 of 2 fixed rewards (two decorations, or a blueprint slot vs an outfit) | #46, #77 | — | None |
| 58 | Gold Pass | A monthly paid track: a skin; up to 20% off build and research time and cost; shorter donation-request wait; donations for 1 Gem; an extra Forge slot; the Prospector; bonuses for late and repeat buyers (2026); on sale from Town Hall 3 since Aug 2026 | Revenue; a monthly goal | A monthly frame | 56, 59 | W6, O5, W1, O10 | REJECT | — | — | — | A repeat purchase that changes economy numbers |
| 59 | Hoggy Bank | Loot you earn is matched into a bank that pays out at the end of the season; the Gold Pass multiplies it by 5 | Playing pays twice | End-of-month reward | 58 | O27, O5 | REJECT | — | — | — | Monthly cadence; a paid multiplier |
| 60 | Starter Challenges | Town Hall 2–6: 60 challenges and 26 reward tiers with no time limit; unclaimed rewards are claimed automatically at Town Hall 7 | Early goals without deadlines | Early goals | 103 | W12 | ADAPT | Extend the Foreman's 8-step first chapter into a starter list with no deadlines up to Core 3–4; claim leftovers automatically at the end | Foreman chapter | Writing the tasks | None |
| 61 | Starter Pass | A paid premium side to the starter track (tested from Feb 2025, retired Aug 2026) | Early revenue | — | 60 | W2, O10 | REJECT | — | — | — | An extra purchase |
| 62 | Hero Quests | Points on the Hero's Journey that ask for 15 stars in 14 days with a given hero or item; one retry paid in Gems; a substitute item if you lack the one asked for | Gets players to try items | Directed play | 46 | W17, O2 | ADAPT | Deadline-free "use it" quests ("run an Amplifier at its ideal heat for 10 simulated minutes") that fall back to a machine the player owns | #46 | Tracking conditions in the simulation | Drop the deadline and the Gem retry |
| 63 | Clan Games | The clan shares 12 challenges (8 Home Village, 4 Builder Base); dropping one means a 10-minute wait (Gems skip it); a personal cap, usually 10,000 points; pick 1 reward from each tier reached | A clan goal; a choice of reward | Clan loop | 57 | W25 | REJECT (existing decision) | "Pick your reward" lives on in #57 | — | Needs a server | Server; timers |

### 2.10 Events & live operations

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 64 | Events Hub | A button at the bottom left listing current and upcoming events | Shows the calendar | A reason to return | 65 | O18 | REJECT (existing decision) | — | — | — | Calendar cadence |
| 65 | Medal events & Event Pass | About monthly: a token won in battles fills a reward track; medals buy exclusive items from the Trader; a paid Event Pass (for example $4.99); leftover medals turn into Gold after a grace period | Monthly content; revenue | Directed play | 64 | W5, W40, O18 | REJECT | — | — | — | Extra currencies; a purchase; fear of missing out |
| 66 | Temporary rule events | Temporary troops; free troops added to armies (for example 30 Electro Dragons for one day); buildings reskinned with new effects (meteors, piñatas) | Novelty | Breaks up the usual play | 13 | W5 | REJECT | New rules already live in the strata modifiers | — | — | Time-limited |
| 67 | Treasure Hunt | A chest hidden in 1 of 3 marked enemy buildings; 3–4 chests per day, which can pile up | Turns battles into a hunt | Variety | 148 | W34 | REJECT | — | — | — | Random chests |
| 68 | Streak Event | 7 daily tasks; a broken streak can be bought back with Gems | Daily return | Obligation | 64 | W33 | REJECT (existing decision) | — | — | — | Streak |
| 69 | Clan Rush events | A side resource earned alongside Gold or stars is pooled by up to 100 contributors per clan for tiered rewards (Gold Rush in 2025, up to Money in the Bank Rush in Sep 2026) | Clan co-operation without wars | A co-op goal | 63 | W5, W40 | REJECT (existing decision) | — | — | Needs a server | Server |
| 70 | Community goals | The whole player base works toward one target (Clash for Nature 2023, Unlimited Heroes 2024) | A shared moment | Excitement | 22 | W5 | REJECT (existing decision) | — | — | Needs a server | Server |
| 71 | Jam events | Discounts on time and cost before a new Town Hall; the 2025 "Summer Jam" boosted one resource per week | Catch-up before new content | Bursts | 40 | W5 | REJECT (existing decision) | Use the permanent cost cuts (#40) instead | — | — | Time-limited |
| 72 | Battle Options | Sep 2026: at 33%, 66% and 100% destruction the battle pauses and offers 3 choices (a temporary troop or resources); one is picked automatically after about 10 s | A choice in the middle of a run | Choices that shape a run | 11, 57 | W5 | ADAPT | "Shaft boons": at set depths, pick 1 of 3 perks drawn from a seed, lasting until the next collapse; no timer on the choice | Strata, collapse | Balance; a repeatable seed | Drop the automatic-pick timer |
| 73 | Attack Challenges | Event levels with a given army, unlimited retries and a reward for 3 stars; a variant where you steer a hero directly; the Sep 2026 challenge has an online fastest-time board | Puzzle content | Mastery | 21, 104 | W35 | ADAPT | Permanent challenge boards with no calendar and no leaderboard (#104) | #104 | Level design | Drop the time limit and the leaderboard |
| 74 | Clash of Cards | Aug 2026: card packs from battles, the Trader and the store; duplicates traded in clan chat; rewards at 10 to 60 cards collected; pack odds published | Collecting; trading with others | Collection | 148 | O4, O26 | REJECT | — | — | — | Random packs; server |
| 75 | Chief's Chronicles | Aug 2026: a year-in-review "museum" of your statistics; 6 player types (Lone, War, Clan, Loyal, Comeback, Fresh); a personal statue; shareable | Reflection; identity | Pride | 84, 95 | O3 | ADAPT | "Shaft chronicle" after each collapse or on request: 4–5 statistics, a player type (for example Heat Tamer, Deep Diver), a statue at the board's edge and an image to share | Statistics tracking; share sheet | Fair rules for the player types | None |
| 76 | Seasonal themes | Winter trees stamped with the year, Halloween looks for obstacles, event obstacles you keep | Seasonal flavour; keepsakes | Atmosphere | 32 | W36, W2 | LATER | Cosmetic looks for board decorations chosen by the device date, with no rewards attached | Art | Art cost | Must not turn into fear of missing out |

### 2.11 Achievements, collections & cosmetics

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 77 | Achievements | 54 achievements, most with 3 stars; they pay Gems and XP and are mirrored to Game Center and Google Play Games; all together worth 21,222 Gems; "Unbreakable" was cut from 5,000 to 500 defences in 2026 | Long-term goals; they teach the systems | Direction | 46, 78 | W24, W1 | ADOPT | The Ledger (clash-ux 10.2.6) with cosmetic rewards and optional Play Games mirroring; keep targets reachable | Statistics | Play Games optional | None |
| 78 | XP level | Earned from many actions; unlocks only decorations; highest level 500 | A sense of progress with no power attached | Collection | 77 | W37 | ADAPT | No XP number; Ledger stars unlock decorations directly | #77 | — | Would be another number if copied |
| 79 | Decorations | Decorations from the shop, events and war leagues; can be stashed; storage limits raised in 2026; national flags removed and refunded in 2022 | Self-expression | Pride | 78, 80 | W36, W1 | ADAPT | Earned decorations for the board's edge and the yard rings | #77 | Placement rules next to machines | None |
| 80 | Sceneries | The landscape around the village: a default one, free ones at Town Hall 14 and 15, paid ones sold again 12 months later; war and Builder Base versions; the "Legendary" scenery (Sep 2024) is more than 6 times larger and has cutscenes | Self-expression; revenue | Pride | 79 | W36, W3 | ADAPT | Earned surroundings for the board (for example one per stratum theme). Reject paid and Legendary versions | #77 | Art cost | Paid versions rejected |
| 81 | Skins & outfits | Hero skins (the top Gold Pass reward; some sold for Gems about a year later) with a 3D viewer; one builder skin applied to all builders (Fancy Shop) | Self-expression | Pride | 58, 53 | W6, W36, W15 | ADAPT | Outfits for the Foreman and crew, earned from the Ledger and the Journey | #77, #46 | Art for each outfit | Paid skins rejected |
| 82 | Clan House | Each member's house in the Capital, customised with roof, wall, floor and decoration parts | A personal spot in a shared place | Belonging | 96 | W26 | REJECT (existing decision) | — | — | Needs a server | Server |
| 83 | Showing what you don't own | Since Feb 2026 the Blacksmith shows equipment you do not have, and the selection screens show locked heroes and pets | Players learn what exists | Curiosity | 111 | W1 | ADOPT | The Codex shows machines and cosmetics not yet seen as silhouettes, each saying how to get it | Codex | — | None |
| 84 | Player profile | Player ID tag, XP, labels, league, army levels, best rank, war stars; switches for clan invites and war participation | Identity; comparison | Pride | 75 | W37 | ADAPT | A local "factory record" page (deepest stratum, Cores, collapses, best chain), reused by #75 and #95 | Statistics | — | Drop the online part |

### 2.12 Social: clans, chat, donations, co-op, friends, sharing

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 85 | Clans | Up to 50 members; roles of Leader, Co-leader, Elder and Member; open, invite-only or closed; Town Hall and league requirements; a badge, labels, a language and a location | Belonging | The social glue | 86–97 | W27 | REJECT (existing decision) | — | — | Needs a server | Server |
| 86 | Clan chat | Pinned messages (up to 20 since Apr 2026), reactions, @clan and @leaders tags; shared replays, layouts and armies; automatic clan news | Coordination | The social glue | 85 | W3, W1, W27 | REJECT (existing decision) | — | — | Server; moderation | Server |
| 87 | Donations | Members request troops, optionally specific ones; since Mar 2025 donating costs Elixir or Dark Elixir; 10-minute wait between requests (the Gold Pass shortens it); received levels capped by the Clan Castle level | Everyday generosity | The everyday social action | 88 | W27, W2 | REJECT (existing decision) | — | — | Needs a server | Server |
| 88 | Clan XP & perks | Clan XP from wars, Clan Games and raids unlocks perks: higher donation limits, Treasury capacity in +10% steps, extra war loot | Shared progress | A group goal | 87 | W27 | REJECT (existing decision) | — | — | Needs a server | Server |
| 89 | Notice Board & clan search | Leaders publish a recruitment notice (10,000 Gold for 24 h) that is shown to players who fit; search by name, tag or filters; bookmarks | Matching players with clans | Getting into a clan | 85 | W3, W27 | REJECT (existing decision) | — | — | Needs a server | Server |
| 90 | Automatic leader handover | After 90 days of Leader inactivity (warnings at 60, 74 and 83 days) the longest-serving active Co-leader or Elder takes over | Abandoned clans recover | — | 85 | O20 | REJECT (existing decision) | — | — | Needs a server | Server |
| 91 | Clan Gifts | Some Gem packs also drop Gems for clanmates in chat, first come first served | Paid generosity | Social and revenue | 145 | O21, W39 | REJECT | — | — | — | Purchase; social |
| 92 | Friends | Up to 100 in-game friends plus up to 300 Supercell ID friends in the Social tab | Keeps friends in view | Social | 93 | O22 | REJECT (existing decision) | — | — | Needs a server | Server |
| 93 | Global Chat | Back in June 2026 after being removed in 2019 over harassment: Groups of up to 800, Communities of up to 50,000 with 12 hours of history, a "Town Square" where official guests speak; no links, spam limits, every message reportable | Community at scale | Social | 92 | W1, O23, W30 | REJECT (existing decision) | — | — | Server; moderation | Server |
| 94 | Visiting & scouting | Visit any player's village from their profile, in scout view (traps hidden) | Curiosity; learning | Social | 26, 27 | W37 | ADAPT (through #27) | Factory Tours: a shared code opens a read-only board in your own simulation | #27 | — | Live visiting needs a server |
| 95 | Replays & share cards | Battle replays shareable in chat (waiting time cut from 5 to 2 minutes in 2026); the Ranked battle log redesigned with a summary card made for screenshots | Showing off; learning | Showing off | 75 | W1 | ADAPT | A shareable image of the board and its key statistics, sent through the Android share sheet; no replays | #84 | Rendering the image off-screen | None without a server |
| 96 | Clan Capital & Raid Weekends | The shared mountain built with Capital Gold; weekly raids from Friday to Monday (5 attacks, plus 1 bonus); damage to a district carries over between members' attacks; Raid Medals | Building together; a weekly co-op battle | Co-op loop | 43, 44 | W26, O19 | REJECT (existing decision) | The solo version is #43 | — | Needs a server | Server; weekly |
| 97 | Friendly Challenges & Wars | Attack clanmates' bases for practice; Friendly Wars including 2 vs 2 and 3 vs 3 (2025); optional Tournament Mode | Practice with friends | Social play | 33 | W2, W3 | REJECT (existing decision) | The solo version is #33 | — | Needs a server | Server |

### 2.13 Competition

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 98 | Ranked leagues | Weekly tournaments in groups of 100; a limited number of battles (6 in the lowest leagues, up to 30); no skipping opponents; defence uses a saved copy of your layout; each Town Hall level has a lowest league; demotion after 4 weeks inactive, with a countdown warning | Fair competition; separates casual and competitive play | Competition | 2, 16 | W29, W1 | REJECT (existing decision) | — | — | Needs a server | Leaderboards; server |
| 99 | Legend League tiers | Since Apr 2026: Legend III (weekly, 24 battles), Legend II (weekly, 30), Legend I (4-week tournaments, 8 battles a day, anyone below rank 10,000 is demoted); a top-200 board; missed defences are filled with an average | Competition at the very top | Competition | 98 | W1 | REJECT (existing decision) | — | — | Needs a server | Leaderboards; daily |
| 100 | Clan Wars & CWL | Clan Wars with 2 attacks each; Clan War Leagues: groups of 8 clans, 7 wars, 1 attack per day; a shop for League Medals; leaders hand out bonus medals; 4 new top leagues in Apr 2026 | Team competition | Social competition | 85 | W28, W1 | REJECT (existing decision) | — | — | Needs a server | Server; a daily attack |
| 101 | Capital & Builder Base leagues | Capital Trophies from raid results; trophy leagues for the Builder Base | Side competitions | Competition | 96 | O19, W4 | REJECT (existing decision) | — | — | Needs a server | Server |
| 102 | Leaderboards | Global and local rankings for players and clans; a Town Hall leaderboard added in Apr 2026 | Status | Competition | 98 | W1, W27 | REJECT (existing decision) | — | — | Needs a server | Leaderboards |

### 2.14 Onboarding & teaching

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 103 | Scripted tutorial & advisor | A villager voices a scripted first battle and first buildings, ending on the builder list and the challenges | The first minutes | Teaching | 8, 60 | W41 | ADOPT (already built) | The Foreman's 8-step chapter exists (clash-ux §1 and 10.1) | — | Already built | None |
| 104 | Practice Mode | 19 levels, each teaching one strategy with a guided step-by-step first attempt (skippable, repeatable); loot taken once; no trophies at stake; no time limit | Safe teaching | Mastery | 21, 33, 73 | W35 | ADAPT | Small hand-made boards that each teach one idea (heat spread, adjacency, one modifier); the Foreman guides the first attempt; a fixed reward, earned once; permanent | Preset boards; simulation | Level design; saving completion | None |
| 105 | Chief's Journey | A button on the Town Hall and Builder Hall listing what each level unlocked and what the next ones will unlock; locks on future items, "New" badges on fresh ones; returning players see markers; built because new players did not know some features existed | Shows the whole road ahead | Anticipation | 20, 111 | W11 | ADAPT | A Core timeline on the Core card: what each level unlocked and will unlock, locks ahead, "New" badges | Core levels, Codex | Fitting it on a small screen | None |
| 106 | Rushed-village warning | Upgrading a Town Hall whose attack side lags behind shows a warning that suggests upgrading it first; it does not block (Oct 2023) | Stops players hurting themselves | Guidance | 112 | W4 | ADOPT (already proposed) | clash-ux 10.2.1: one confirmation before Descend or a Core level-up when unlocked machines sit unbuilt or machines are far below their cap | Core card | Defining "rushed" | None |
| 107 | Signature system early | The first hero moved from Town Hall 7 to Town Hall 4 (May 2026) because players wanted to meet a hero sooner | Hooks players sooner | The hook | 10 | W1, O32 | ADOPT (principle) | Keep heat and the Lab in the first session (plan P3 already does this) | — | — | None |
| 108 | Teaching at first contact | Each feature's tutorial runs the first time it is opened (for example a villager in a Viking helmet explains Clan Wars) | No teaching up front | Teaching | 103 | W41 | ADOPT (already built) | Unlock cards and the Foreman at a new stratum exist; extend them to every new machine and modifier | — | Already built | None |

### 2.15 UI/HUD & information design

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 109 | Suggestion menus | The builder list suggests what to build next; the research tooltip suggests research with its costs (Oct 2023) | "What next?" | Direction | 112 | W4 | ADOPT (already built) | "What now?" exists; add the research highlight (clash-ux 10.2.5) | Worklist | Already built | None |
| 110 | Info screens | Unit info with animated previews; progress bars restored (Feb 2024) showing how close an item is to the highest level at your current Town Hall | A clear goal for every item | Readability | 29 | W4, W3 | ADOPT | Every machine card shows a level bar against its current Core cap and the next cap | Core caps | Cheap | None |
| 111 | Lock reasons | Since Feb 2026, locked icons can be tapped and say why they are locked; the Super Sauna shows which troop level a Super Troop needs | No more "why can't I?" | Clarity | 83, 105 | W1 | ADOPT | Every locked machine, research card or Core row says exactly what unlocks it (Core level N, stratum N, research X) | Core levels | Cheap | None |
| 112 | Pre-upgrade checklist | The Town Hall upgrade confirmation lists recommended unfinished upgrades (for example Army Camps not yet maxed) | Stops players advancing too early | Guidance | 106, 109 | W3 | ADOPT | The Core level-up confirmation lists the unfinished rows at this level, each tappable to jump to its tile | Core card | Cheap | None |
| 113 | Spending safety | Upgrade buttons tied to one specific resource or item (Feb 2024); the Gem prompt says exactly how much is missing; confirmations before risky actions | Prevents spending the wrong thing | Trust | 129 | W3, W4 | ADOPT | Where two stocks could pay, show separate buttons; always show the shortfall | Store | Cheap | None |
| 114 | Results screen | Aug 2026: the end-of-battle screen rebuilt with a new victory banner and a clearer breakdown of loot and bonuses | Makes the payoff readable | Reward | 118 | O2 | ADOPT | The Descend, collapse and offline-return screens break down what was earned and why | Celebration effects | Cheap | None |
| 115 | Declutter switches | Hide obstacles and decorations in the enemy base during attacks (Oct 2025); switch off decoration effects (Feb 2026) | Readability; performance | Readability | 54, 79 | W2, W1 | ADOPT | Settings to hide decorations, glow effects and the ambient crew | Settings | Cheap | None |
| 116 | State shown in the world | Barracks and factories animate only when their unit is in your army (2025); the sleeping "Zzz" over builder huts matches whether the builder works (2024) | State shown without text | Readability | 8 | W2, W3 | ADOPT (check) | Machines animate only while actually producing; stalled ones visibly stop | Simulation state | Probably built already; verify | None |
| 117 | Badges only when there is something to do | A badge on the Events button when an event reward is complete (2024); the Shop button flags special offers (2025) | Draws attention | A nudge to return | 119 | W3, W2 | ADAPT | Badges only for things the player can do now (a Ledger reward to claim, a new Codex page); never for offers | — | Discipline about badges | Shop badges rejected |
| 118 | Level-up cinematic | Upgrading to Town Hall 18 plays a one-time meteor cinematic; you then tap the meteorite away | A big milestone moment | Celebration | 114 | W2 | ADAPT | A short Core level-up moment (clash-ux 10.2.14) that can be replayed from the Codex | Celebration effects | Keep it short and skippable | None |

### 2.16 Notifications, retention & systems that bring players back

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 119 | Push notifications | Exist; notifications for clan-chat tags can be switched off (Settings > More Settings > Notification Settings); delivery reworked in 2026; full list of types UNVERIFIED | Pulls players back | Return | 117 | W3, W1 | ADAPT | At most one optional notification sent from the phone itself, off by default: "offline storage is full" | Android local notifications | When to ask for permission | Must not become guilt |
| 120 | Login Calendar for returners | After 35+ days away, 7 days of login rewards, one per day; can recur only after 135 days | Hooks returning players again | Return | 121 | O11 | REJECT (existing decision) | clash-ux 10.2.14: one return gift, claimed all at once | — | — | Needs daily logins |
| 121 | Returning boosts | After 90+ days away: a 48-hour Shield and village boosts worth about half of what regular collecting would have earned | Helps returners without rewarding absence | Return | 6, 120 | O11 | ADOPT (principle) | Any return gift stays below what steady play would have earned (clash-ux 10.2.14) | Offline simulation | Tuning | None |
| 122 | Overloaded Loot Cart | After 3+ days away the Loot Cart grows with the days away (up to 90), whatever was lost | A welcome-back gift | Return | 7 | W21 | REJECT | Offline production already plays this role | — | — | Rewards absence; tied to theft |
| 123 | What's new for returners | Chief's Journey markers show returning players the new content | Catching up on changes | Return | 105 | W11 | ADAPT | After an update or a long absence, one "What's new" card linking to the new Codex pages | Codex | Tracking versions | None |
| 124 | Inactivity demotion | Ranked demotes a player after 4 weeks of inactivity, with a countdown warning | Keeps leagues active | Pressure | 98 | W1 | REJECT | — | — | — | Punishes absence |

### 2.17 Quality of life

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 125 | Upgrade many at once | Wall Upgrader: pick a wall, then add walls of the same level 1 or 10 at a time, up to all 325, within what your resources or Wall Rings allow | Hundreds of taps become one | Flow | 127 | W2 | ADOPT | "Upgrade every Drill from level 3 to 4 that I can afford", closest to the Core first | Machine levels | Upgrade order; a preview | None |
| 126 | Small jobs need no builder | Obstacles no longer need a builder (Feb 2025; villagers clear them); Wall Rings no longer need one (Aug 2026) | Scarce builders go to real decisions | Flow | 8 | W2, O2 | ADOPT (principle) | No action in Lodeworks should wait behind another for no reason | — | — | None |
| 127 | Partial completion | Quick Train fills as much of a saved army as fits instead of refusing (Dec 2023) | Not all-or-nothing | Flow | 125 | W4 | ADOPT | Stamping a blueprint places what is affordable and leaves ghosts for the rest | #23 | Placement order | None |
| 128 | Edit where you are | Change a hero's skin, turn heroes and reorder them straight from the army screen (June 2025) | Fewer trips between menus | Flow | — | W2 | ADOPT (principle) | Act from where the player is: a machine's card can raise, move, copy it or open its Codex page | — | Button space on a small screen | None |
| 129 | Warnings before risky actions | A warning before a Capital raid when Capital Gold storage is over 90% full; a confirmation when leaving unsaved clan settings | Avoids waste and lost work | Trust | 113 | W4, W3 | ADOPT | Confirm before a collapse and before a sale that loses materials; warn when an action would overflow the store | — | — | None |

### 2.18 Anti-frustration & fairness

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 130 | Shields, Guard, forced breaks | A Shield for 8 h after losing 30%+ of your loot; Shields for sale (1, 2 or 7 days) with waiting periods before rebuying; a 15-minute Guard after a Shield; the forced "Personal Break" removed in 2023 | Protection from repeated raids | Safety | 7, 131 | W20, W30 | REJECT (not applicable) | — | — | — | Nothing can be stolen in Lodeworks |
| 131 | Revenge | Within 12 h, attack a copy of the raider's base to win back loot | A way to act after a loss | Recovery | 130 | O33, W2 | REJECT (not applicable) | — | — | — | Player-vs-player |
| 132 | Catch-up & switch-over | Bigger Ore rewards for players "very far behind"; existing players moved onto new tracks with the rewards they had already reached and a one-time storage overflow | New systems punish neither veterans nor late starters | Fairness | 40, 46 | W17, O1 | ADOPT (principle) | For every new track or cap, old saves immediately receive the rewards they already qualify for (the same pattern as save version 1) | Save versioning | Testing the switch-over | None |
| 133 | Compensation when things are removed | Removed Supercharges and Crafted Defence upgrades became Sparky Stones; Training Potions were sold automatically; expiring Magic Items pay Gems; national flags were refunded | Trust through changes | Trust | 135 | W2, W7, W3, W36 | ADOPT (principle) | Removing or reworking anything refunds what the player paid for it | Save conversion | Recording what was paid | None |
| 134 | Transparency | Chest odds published (Common 58%, Rare 32%, Epic 8%, Legendary 2%); an info button in the Shop about what offers are worth; personalised offers can be switched off | Trust; legal requirements | Trust | 145, 148 | O12, O13, W2 | ADOPT | The shop says plainly what each purchase does, and that it never changes an economy number | Shop screen | Wording | None |
| 135 | Warning before investing | Buildings that will soon get a new level show a warning, so players skip Supercharges that will be removed | No wasted investment | Trust | 50 | W16 | ADOPT (principle) | If an update will change a machine, its card says so before the player invests in it | Content pipeline | — | None |

### 2.19 Accounts, saves, settings, accessibility

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 136 | Supercell ID | Login with an emailed code; many accounts per device that can be switched and reordered; progress carries across devices | Safe saves; several accounts | Continuity | 137 | W43, W3 | ADAPT | Backup through Google Play Games Saved Games plus an export/import save code; no server of our own | Play Games plugin | Resolving conflicts between devices | A server of our own would conflict |
| 137 | Guest accounts & new game | A guest Supercell ID is created after the tutorial (2025); a fresh game starts by logging out and playing without an account | Low friction; restarting | — | 136 | W2, O34 | ADAPT | Local save slots: starting a "new factory" never deletes the old one | Save system | Slot interface | None |
| 138 | Young players | Accounts under 16 get no personalised offers or ads and restricted social features; "Supercell ID Family" lets one adult manage up to 8 children's accounts | Child safety | — | 93 | O30, O31 | Not applicable | Lodeworks has no chat or player-made content. Whether its rewarded ads need rules for a child audience is UNVERIFIED | — | — | None |
| 139 | Settings switches | Turn Fast Forward off; hide obstacles and decorations; switch off decoration effects and clan-tag notifications; turn off personalised offers; a link to chest odds | Player control | Comfort | 115 | O2, W2, W1, W3, O13 | ADOPT (some) | Switches for decorations, glow and crew; one notification switch; a link to "what purchases do" | Settings | — | None |
| 140 | Languages & platforms | Polish added in 2025; a PC version through Google Play Games with mouse wheel and keyboard shortcuts; Amazon Appstore support ended | Reach | — | — | W2, W3 | LATER | A desktop build with mouse-wheel zoom and keys; English and Turkish already exist | Input mapping | A Godot export per platform | None |
| 141 | Accessibility | No colour-blind or text-size options found in Clash (UNVERIFIED) | — | — | — | — | ADOPT anyway (**Inference**) | Heat is colour-coded, so add a colour-blind-safe palette plus numbers or shapes | Heat display | Testing the palette | None |
| 142 | Name change | One free change, then a Gem price that rises by 500 each time, up to 10,000 | Identity; a Gem sink | — | — | W42 | REJECT | — | — | — | Gems |

### 2.20 Monetisation (listed so the rejections are explicit)

| # | Feature | What it is | Solves / adds | Core role | Related | Src | Fit | Lodeworks adaptation | Depends on | Challenges | Conflict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 143 | Gems & skipping timers | Premium currency: buys resources, finishes timers, buys Magic Items and Shields; earned slowly from achievements, obstacles, the Gem Mine (at most about 5 Gems a day) and events | The core of monetisation | An economy built on timers | 144–149 | W42, O24 | REJECT | — | — | — | Premium currency; timers |
| 144 | Builders sold for Gems | Builder's Huts 2 to 5 cost 250, 500, 1,000 and 2,000 Gems; the Apprentice costs 500 | Paying for parallel work | A pacing lever | 143 | O17 | REJECT | — | — | — | A purchase that moves the economy |
| 145 | Offer machinery | Resource packs, starter packs for each Town Hall, bundles, personalised offers, Chain Offers (June 2026), regional pricing tests | Targeted revenue | — | 91 | W39, O13, W1, W2 | REJECT | — | — | — | Many purchases; economy |
| 146 | Passes | Gold Pass (monthly), Event Pass, Starter Pass | Recurring revenue | A monthly frame | 58, 61, 65 | W6, W40, W2 | REJECT | — | — | — | Repeat purchases; economy |
| 147 | Cosmetics for money | Sceneries and skins sold, older ones sold again later | Revenue without power | Self-expression | 80, 81 | W36 | ADAPT (narrow) | The only compatible pattern in Clash: one one-time cosmetic bundle could be one of Lodeworks' two allowed purchases (the owner's call) | #79–#81 | Art budget | None if one-time |
| 148 | Paid randomness | Chests whose rarity can rise over 4 taps (58/32/8/2%) in tracks and events; card packs; event medals for sale | Excitement; revenue | Rewards | 67, 74 | O12, W9, O26, W40 | REJECT | — | — | — | Gacha |
| 149 | Other Gem sinks | Shields, war layout slots, name changes, buying back a streak, skipping reward tiers (for example 90 Gems per event tier), topping up Ore | Revenue | — | 143 | W20, W13, W42, W33, W40, W32 | REJECT | — | — | — | Premium currency |
| 150 | Ads | No evidence that Clash shows ads (UNVERIFIED) | — | — | — | — | Not applicable | Lodeworks' rewarded video has no Clash precedent to copy | — | — | — |

---

## 3. Complementary clusters

**A. "Maxed never means done"** (#50, #51, #52, #53, #54, #55, #43, #44)

- **In Clash:**
  - A fully upgraded building takes small Supercharge steps.
  - Two fully upgraded defences merge into a new tier and free a slot.
  - The Crafting Station adds one slot the player shapes.
  - Sparky Stones turn that endgame work into cosmetics, and glow effects show it off.
  - The Capital Treasury absorbs the last surplus.
- **In Lodeworks:**
  - Overdrive (#50) on each machine type at its Core cap.
  - Twin machines (#51) that need two overdriven neighbours.
  - A Prototype bay (#52) at the top Core level.
  - Surface Works and its tonnage record (#43, #44) take surplus forever and survive collapse.
  - Glow and Codex pips (#54) show mastery.
- **Rules:** everything is paid in existing materials, so shallow strata keep a use (fits plan P5, "one resource per era"). No stones currency.

**B. "What next, and why not yet"** (#109, #105, #110, #111, #112, #106, #83, #29, #41)

- **In Clash:** the builder and research suggestions, Chief's Journey, progress bars to the current cap, tappable lock reasons, the pre-upgrade checklist, the rushed warning and "Full!" bubbles together answer "what can I do, what's blocked, and why".
- **In Lodeworks:**
  - "What now?" as the entry point.
  - Core timeline, cap bars and lock reasons as the "why".
  - A checklist on the Core level-up confirmation.
  - The type highlight and full-store bubble as world signals.
- **Rule:** all of it reads data the Core rows already hold.

**C. "Layout craft"** (#23–#28, #31, #33, #4, #104, #125, #127)

- **In Clash:** the edit mode, layout slots, copying, links, a separate defence layout, army recipes and attacking your own base let players plan, borrow and test.
- **In Lodeworks:**
  - A blueprint editor with a draft overlay.
  - Line recipes stamped as ghosts, placed partly when not all is affordable.
  - A 4× test run in a sandbox.
  - Share codes with ghost outlines for missing machines.
  - Bulk upgrades.
- **Why it matters:** this makes collapse rebuilds cheap in effort, which plan P7 needs.

**D. "Rewards that follow play"** (#46, #77, #78, #57, #60, #62, #132, #75)

- **In Clash:** Hero's Journey turns upgrades already done into a reward track. Achievements run alongside with long thresholds. XP unlocks only decorations. Choice nodes let players pick. The switch-over pays veterans at once.
- **In Lodeworks:**
  - A Journey track filled by the total of all machine levels, plus the Ledger.
  - 1-of-2 choice nodes.
  - A starter list with no deadlines, and "use it" quests with no deadline.
  - A shaft chronicle.
- **Rules:** all deterministic and cosmetic or convenience rewards; old saves receive what they have already earned.

**E. "Choice and identity at the top"** (#11, #10, #45, #52, #72, #30)

- **In Clash:** Guardians, hero slots, equipment loadouts, crafted modules, Battle Options and building modes.
- **In Lodeworks:** a Core Aspect, Core module slots, the Prototype bay's modules, shaft boons at set depths, and later machine modes.
- **Inference:** these give each post-collapse run a different shape without adding a currency.

**F. "Trust"** (#39, #42, #113, #129, #132, #133, #134, #135, #121)

- **In Clash:** refund rules, overflow kept, spending safety, warnings, the switch-over, compensation, published odds, warnings before investing, and return gifts that stay below steady play.
- **In Lodeworks:**
  - An undo and refund policy.
  - An overflow tray that never expires.
  - A rule that nothing is removed without a refund.
  - A plain-language shop page.
  - Every return gift worth less than steady play.

**G. "Absence and return"** (#6, #121, #123, #114, #119)

- **In Lodeworks:** offline production (built), a return screen that breaks down earnings, a "What's new" card and at most one optional notification.
- **Deliberately excluded:** no calendar and no absence-scaled gift.

**H. "Regions and a second track"** (#17, #19, #20, #49, #21)

- **In Lodeworks:**
  - Seeded fixed terrain per band of strata (P4).
  - Covered crates for coming unlocks.
  - A survey map of challenge boards.
  - Later, a second shaft with one link reward, in the spirit of B.O.B.

**I. "Celebration"** (#118, #114, #75, #95, #54)

- **In Lodeworks:** a Core level-up moment, results breakdowns, the shaft chronicle with a player type, a share image and machine glow.

**J. "Social and competitive meta"** (#85–#102, #63–#70)

- All rejected under the existing decisions.
- Only two pieces survive, both without a server: the share code (#27) and the share image (#95).

---

## 4. Top 15 recommendations (ranked by value against effort)

1. **Highlight all machines of a type (#29).** Tapping a machine lights up every machine of that type with its heat reach and temperature against the ideal. It is the cheapest large gain in readability for an adjacency-and-heat board on a small screen.
2. **Lock reasons and cap bars (#111, #110).** Every locked or capped item says exactly which Core level, stratum or research opens it. This turns the Core system into readable goals at almost no cost.
3. **Upgrade many at once (#125, #127).** "Upgrade every Drill I can afford" removes dozens of taps a session on a 44×44 board.
4. **Pre-level-up checklist with a non-blocking warning (#112, #106).** It reuses the Core row data and teaches the Core system at the exact moment of decision.
5. **Overflow is never lost, and changes are compensated (#42, #133).** A holding tray and a refund rule are little code and protect trust through every balance change.
6. **Results breakdowns (#114).** Descend, collapse and return screens that say what was earned and why make the idle payoff readable.
7. **Overdrive tiers with a glow (#50, #54).** A few permanent levels past the Core cap give fully upgraded machines a job and create a sink for shallow-strata materials.
8. **Test run in a sandbox (#33, #4).** The deterministic headless simulation already runs in the tools, so a 4× preview of the current board is mostly interface work, and it makes experimenting risk-free.
9. **A Journey track from total machine levels, with choice nodes (#46, #57, #132).** It pays for progress already made, needs no timer, and old saves carry over cleanly.
10. **Practice and challenge boards (#104, #73, #21).** Permanent hand-made boards teach heat, adjacency and modifiers, and add content with no calendar.
11. **Blueprint editor, draft overlay and line recipes (#23, #28, #31).** These unlock plan P7 and make rebuilding after a collapse painless.
12. **Core modules (#45).** Two or three Core slots filled with modules raised by existing materials give build variety and a long sink with no new currency.
13. **Shaft chronicle and share image (#75, #95, #84).** Cheap once statistics are tracked; it celebrates each collapse and lets players share without a server.
14. **Share codes, i.e. Factory Tours (#27, #26, #94).** Layouts travel through any messenger, with ghosts for missing machines and no backend.
15. **Twin machines (#51).** Merging two fully upgraded neighbours is the most on-theme endgame idea for an adjacency game, but the costliest in simulation and heat rules, so it comes last.

Runners-up: Core Aspect (#11), shaft boons (#72), Surface Works (#43, #44), Core timeline (#105).

---

## 5. Explicit REJECT list

**Conflicts with a hard constraint**

- **Timers as gates:** helpers (#47), goblin workers (#48), the Forge (#37), converters with daily cooldowns (#36), timed boosts and Runes (#35), temporary items that expire (#42's 24-hour rule), Clock Tower-style daily speed bursts.
- **Gacha:** Treasure Hunt chests (#67), random chests in tracks and events (#148), card packs (#74).
- **Subscription-like repeat purchases:** Gold Pass (#58), Hoggy Bank multiplier (#59), Event Pass (#65), Starter Pass (#61).
- **Purchases that change economy numbers:** Gems and timer skips (#143), builders for Gems (#144), offer machinery (#145), other Gem sinks (#149), Clan Gifts (#91), name changes (#142).
- **Stealable resources and player-vs-player:** the loot economy (#7), clone bases (#3), Shields, Guard and breaks (#130), Revenge (#131), the Loot Cart and its absence growth (#122), the army and combat systems (#13, #15).
- **Daily-login guilt:** Login Calendar (#120), inactivity demotion (#124).

**Conflicts with an existing decision**

- **Daily or weekly chores and streaks:** Star Bonus (#5), season task cards (#56), Streak Event (#68), Trader (#38), Events Hub, medal and rule events (#64, #65, #66), Jam events (#71).
- **Server-based multiplayer, leaderboards or social:**
  - Clans, chat, donations, perks, notice board, leader handover, friends, Global Chat (#85–#93).
  - Clan Capital and Raid Weekends, Clan House (#96, #82).
  - Friendly Challenges and Wars (#97).
  - Clan Games (#63), Clan Rush events (#69), community goals and the dungeon event (#70, #22).
  - All competition (#98–#102).
  - clash-ux.md's Union, Requisitions, Union Works, Output Trials and Rock of the Week.
- **Extra currencies as a content treadmill:** Sparky Stones and the Fancy Shop (#53), Ores as a new currency (#45 is adapted without them), event medals and tokens (#65), separate currencies for a second shaft (#17 is adapted without them).

**Clutter**

- Pets (#12).
- More menu characters (#9).
- Second-stage caps (#18).
- Obstacles that grow back (#32).
- Troop abilities triggered by the player (#15).
- Magic Items as a whole category (Books, Hammers, Potions, Runes, Wall Rings, Star Jars) [W7]: every one of them exists to skip a timer or a resource cost.

---

## 6. Sources

**Official Supercell sources**

- O1 The Anime Fury Update release notes (June 2026): https://supercell.com/en/games/clashofclans/blog/release-notes/the-anime-fury-update-is-here/
- O2 August Update release notes (30 Aug 2026): https://supercell.com/en/games/clashofclans/blog/release-notes/august-update-3/
- O3 Chief's Chronicles Are Here! (5 Aug 2026): https://supercell.com/en/games/clashofclans/blog/news/chiefs-chronicles-are-here/
- O4 Clash of Cards Event (1 Aug 2026): https://supercell.com/en/games/clashofclans/blog/news/clash-of-cards-event/
- O5 Big Changes are coming to Gold Pass (Feb 2026): https://supercell.com/en/games/clashofclans/blog/news/big-changes-are-coming-to-gold-pass/
- O6 Battle and Ranked Modes Are Coming To Clash (2025): https://supercell.com/en/games/clashofclans/blog/news/battle-and-ranked-modes-are-coming-to-clash-/
- O7 Welcome to Clash Anytime Update (Mar 2025): https://supercell.com/en/games/clashofclans/blog/release-notes/welcome-to-clash-anytime-update/ (not fetched directly; content confirmed through W2 and W30 and a search summary)
- O8 Clash of Clans blog index (posts to 9 Sep 2026): https://supercell.com/en/games/clashofclans/blog/

**Supercell Support Portal** (base address https://support.supercell.com/clash-of-clans/en/articles/; read on 25 Sep 2026)

- O9 Magic Items & the Trader: magic-items-and-the-trader.html
- O10 What's New (Sept 2026): whats-new-september-2026.html
- O11 Login Calendar & Returning Boosts: login-calendar.html
- O12 Chest Drop Chances: chest-drop-chances.html
- O13 Information About Discounts and Offers: info-cc.html
- O14 Season Tasks: season-tasks-3.html
- O15 Helpers & The Helper Hut: helpers-2.html
- O16 Canceling an Upgrade: canceling-an-upgrade.html
- O17 Builders & Builder's Huts: builders-4.html
- O18 Events & Event Pass: events-2.html
- O19 Clan Capital Rewards: rewards-2.html
- O20 Losing Leadership Status: clans-automated-leader-rotation-2.html
- O21 Clan Gifts: clan-gifts.html
- O22 Clash Friends & the Social tab: using-the-social-tab.html
- O23 Global Chat: global-chat.html
- O24 How Can I Get Free Gems and Resources: how-can-i-get-free-gems-and-resources.html
- O25 Maintenance Breaks: maintenance-breaks-2.html
- O26 Card Pack Drop Chances: card-pack-drop-chances.html
- O27 Hoggy Bank: hoggy-bank.html
- O28 Supercharge: supercharge-2-2.html
- O29 Crafted Defenses: crafted-defenses-3.html
- O30 Young Players: younger-players.html
- O31 Supercell ID Family: supercell-id-family.html
- O32 About Heroes & Pets: about-heroes-pets-9.html
- O33 Revenge: revenge.html
- O34 How to Start a New Game: how-to-start-a-new-game.html

**Fandom wiki** (https://clashofclans.fandom.com/wiki/ plus the page name; read through the API on 25 Sep 2026)

- W1 Version_History/2026
- W2 Version_History/2025
- W3 Version_History/2024
- W4 Version_History/2023
- W5 Events
- W6 Season_Challenges
- W7 Magic_Items and Magic_Items/List
- W8 Magic_Snacks
- W9 Treasure_Chests
- W10 Trader
- W11 Chief's_Journey
- W12 Starter_Challenges
- W13 Village_Edit_Mode
- W14 Crafting_Station
- W15 Fancy_Shop
- W16 Supercharge
- W17 Hero's_Journey
- W18 Helper_Hut, Alchemist, Prospector, Builder's_Apprentice, Lab_Assistant
- W19 Goblin_Workers
- W20 Shield and Guard
- W21 Loot_Cart
- W22 Star_Bonus and Treasury
- W23 Clock_Tower and Gem_Mine
- W24 Achievements
- W25 Clan_Games
- W26 Clan_Capital, Forge, Raid_Weekends, Clan_House
- W27 Clans and Clan_Perks
- W28 Clan_War_Leagues
- W29 Ranked_Battles
- W30 Removed_features
- W31 Hero_Hall
- W32 Ores and Blacksmith
- W33 Streak_Event
- W34 Treasure_Hunt
- W35 Practice_Mode, Single_Player_Campaign, Attack_Challenges
- W36 Scenery, Hero_Skins, Decorations/Home_Village, Obstacles/Home_Village
- W37 Player_Profile and Experience
- W38 Suggested_Updates (the "Ruled Out" list, preserved from archived Supercell forums)
- W39 In-App_Purchases
- W40 Money_in_the_Bank_Rush and Awesome_Medal_Event
- W41 Villager
- W42 Gems
- W43 Supercell_ID

**Internal cross-references (not sources about Clash):** `docs/research/clash-ux.md`, `docs/research/progression-reference.md`, `docs/PROGRESSION.md`, `README.md`.

**UNVERIFIED**

- The full list of push-notification types.
- Whether any in-game accessibility options exist (colour-blind mode, text size).
- Whether Clash shows ads at all.
- Whether a Town Hall 19 exists (no source up to Sep 2026 mentions one).
- The Clash Anytime release notes were not fetched directly.
- The "Ruled Out" list is historical forum material; its current status is unknown.
- The current tutorial script (as already noted in clash-ux.md).
- Whether Lodeworks' rewarded ads need rules for a child audience (outside Clash's scope).
