# Whiteout Survival: reference research for Lodeworks (September 2026)

**How the research went.** The Fandom wiki could not be read. Its pages sit behind a Cloudflare challenge, and its API returned 404/402. I did not try to get past the challenge. I used these instead:
- **Official sources:** the Century Games update pages (2 Mar 2026 and 6 Jul 2026) and the App Store listing (v1.33.9, 17 Aug 2026). The official site is rendered by JavaScript and returned no content.
- **The wiki.wosforge.org community wiki,** read through its public MediaWiki API. I downloaded 250 English pages. Some of them read like generic, machine-written text, and one page contradicts the others. I flag this where it matters.
- **whiteoutsurvival.wiki,** then press and guide sites.

**How to read the tags.** Source keys are listed in §6. **Inference** marks my own reasoning. **UNVERIFIED** marks a claim from one source only, or one that sources contradict. None of the numbers about Whiteout come from me. Any values I suggest for Lodeworks are labelled "tunable".

---

## 1. Overview of the game's structure

**Modes**
- **City:** the Furnace, 30 levels and then 10 Fire Crystal levels, plus about 35 buildings. The city is where survivors, heat, production, research and troops live [WF:Furnace][WSW:Buildings].
- **Exploration:** idle auto-battle stages with heroes and no troops. It pays idle rewards [WF:Explorers Cabin].
- **World map, one per "state" (server):** beasts, gathering marches, alliance territory, PvP and rallies [WF:Territory][WF:Beast Hunt].
- **Side zones:** Daybreak Island at Furnace 19 [WF:Daybreak Island], the Labyrinth at Furnace 19 [WF:The Labyrinth], the Arena at Furnace 8 [WF:Arena], and Dawn Academy treks [WF:Dawn Academy].
- **A constant stream of mini-games and events:** dice board, fishing, the Snowbuster plough game, hidden-object scenes, wheels, and more [WF:Events].

**Loops**
- **Moment to moment:** keep the build queue full, then research, then training [HG-DR].
- **Several times a day:**
  - Intel refreshes at 00:00, 08:00 and 16:00 [WF:Intel].
  - Stamina regenerates 1 point every 5 minutes up to 200 [WF:Stamina].
  - Exploration's idle store caps at 9 h [HG-EC].
- **Daily:** 7 activity chests [WF:Daily Missions] and the daily routine checklist [HG-DR].
- **Every 2 or 4 weeks:** rotating events [WF:Two-Day Events].
- **Across a server's life:** a state-age calendar releases hero generations and systems on fixed days. For example, Fire Crystal Age arrives around day 60, pets around day 55, and State vs State around day 80 [WF:Progression].

**Currencies**
- **Four base resources:** Meat, Wood, Coal, Iron.
- **Other materials:** Steel, Fire Crystals, Refined Fire Crystals [WF:Resources][WF:Refined Fire Crystal].
- **Premium:** Gems [WF:Gems].
- **Chief Stamina** [WF:Stamina] and **Contentment** [WF:Chief Orders].
- **More than 15 event and shop tokens.** Among them: Gems of Enigma, Thorns, Adventure Coins, Wish Sigils, Mystery Badges, Alliance Tokens, Arena Tokens, Marks of Valor, Fire Crystal Embers, Silver Shells, Talismans of Ice, Wonderstar Coins, Truck Vouchers, Dream Fishbits, Life Essence, Lucky Chips [WF:various][MMOC].

**What brings players back (motivation and retention map, Inference from the sources above)**

| Driver | Whiteout mechanism | Keep it for Lodeworks? |
|---|---|---|
| Growth | Furnace level and City Power number | Yes (Core level) |
| Care fantasy | warm, fed, healthy survivors | Yes (machines at working heat) |
| Collection | albums, pets, skins | Partly (Codex) |
| Social duty | Bear Hunt every 2 days, rallies | No |
| FOMO | timed events, state-age drops | No |
| Loss aversion | idle caps, stamina cap, raids | No |
| Payment pressure | 2nd builder, VIP, packs | No |

**Positioning.** The App Store listing says "Over 400M players", offers the free SSR hero Molly, and lists in-app purchases from $0.99 to $99.99. Its content descriptors include "Loot Boxes" [OF-AS].

---

## 2. Feature inventory

**Already covered, one line each:**
- Furnace level gates every other building's level, and the prerequisite chains run both ways [WF:Furnace].
- Resources are introduced in stages: Wood, then Meat, Coal and Iron [WF:Sawmill][WF:Coal Mine].
- Each Fire Crystal level takes 5 upgrades (F30-1…4 then FC1), which makes 50 upgrades from level 30 to FC10 [WF:Fire Crystal Age].

**Entry format.** Each entry reads: What it is · Problem it solves · Core-loop contribution · [source] → **FIT** · Adaptation · Depends on · Related · Conflict · Challenges.

**Lodeworks systems the entries refer to:** the heat sim, adjacency, Core levels, the Core store, strata and their modifiers, collapse, research/Lab, Vault/credits, the Foreman, "What now?", the Codex, the offline sim, and the `core_journey` measurement bot.

### 2.1 Core loop & sessions

**C1 · Session "exit ritual"**
- *What:* Guides tell players to send gathering marches before logging off, keep the builders busy, and collect exploration rewards [HG-DR].
- *Solves:* idle time.
- *Core:* frames each session as setting things up for the time away.
- → **ADAPT.**
- *Adaptation:* when the app goes to the background, the Foreman shows a "Before you go" card listing what will run out or stall while you are away. It gives no reward and applies no penalty.
- *Depends on:* the offline sim.
- *Related:* I3, U4.
- *Conflict:* must not become a daily chore.
- *Challenges:* the offline sim has to predict stalls cheaply.

**C2 · A single build queue, a second one paid**
- *What:* one builder by default. A second costs a pack, or 1,000 Gems per 2 days [WF:Construction][WF:New Players].
- *Solves (for Century Games):* monetisation.
- → **REJECT.** It is a timer gate and a paid queue.
- *Lesson:* Lodeworks places machines instantly, and that is a selling point.

**C3 · Construction timers and speedups**
- *What:* upgrade times from seconds up to 40+ days at Furnace 30 [WSW:Furnace]. Speedups come in 1m, 5m, 1h, 8h and 24h sizes [WF:Speedups].
- → **REJECT.** Timers as gates.

**C4 · Accelerated "Survivor Time" versus real time**
- *What:* edicts last in Survivor Time, the city's own faster clock, while their cooldowns run in real time [WF:Chief Orders]. The ratio between the two is **UNVERIFIED**.
- *Solves:* makes worksite output feel fast while keeping real-time pacing.
- → **LATER / lesson.**
- *Adaptation:* express offline and burst yields in "shifts" of production (for example "2 shifts of output"), not in hours.
- *Depends on:* the offline sim.
- *Related:* I4.
- *Challenges:* two clocks confuse players, so pick one.

### 2.2 Settlement building & layout

**S1 · Mutual prerequisites between the core building and "old" buildings**
- *What:* the dependencies run both ways. Furnace 2 needs Sawmill 1, Furnace 3 needs Shelter 2, Furnace 4 needs Coal Mine 3, and Furnace 5 needs Hero Hall plus Shelter 3 [WF:Sawmill][WF:Shelter][WF:Coal Mine][WSW:Furnace].
- *Solves:* stops the player from ignoring early buildings.
- *Core:* each core-level push sends the player back across the whole city.
- → **ADOPT** (partly present already).
- *Adaptation:* each Core level condition names specific early machine types, for example "2 Crushers at L4" or "a Drill at working heat", as well as new ones.
- *Depends on:* Core levels.
- *Related:* O1, O2.
- *Challenges:* the `CoreLevels.validate` reachability check. Re-measure with `core_journey`.

**S2 · Fixed building slots opened by core level**
- *What:* Shelter slots open at Furnace 1 (×2), then 4, 5, 6 and 7 [WF:Shelter]. The medievalfun guide adds that new building slots open after each Furnace upgrade [MF].
- *Solves:* staged complexity.
- → **ADAPT.** Lodeworks already grows its yard ring by ring.
- *Adaptation:* show the next ring's newly available tiles as a preview before the Core level-up.
- *Related:* Q1.
- *Challenges:* rendering the preview on an isometric board.

**S3 · Furniture inside buildings**
- *What:* each Shelter has 8 furniture pieces, Clinic 7, and resource buildings 6. Furniture goes up to level 20, and some pieces must be maxed before the building itself can level up [WF:Shelter][WF:Clinic][WF:Sawmill].
- *Solves:* adds upgrade depth without more buildings.
- → **REJECT as-is / LATER as "fittings".**
- *Adaptation:* at most 1–2 behaviour-changing fittings per machine, such as "insulation" (narrower heat spread) or "fins" (sheds heat). Never a stat treadmill.
- *Conflict:* an upgrade treadmill conflicts with the no-new-currencies stance.
- *Challenges:* the per-machine UI on a small screen.

**S4 · The Furnace's "warming radius" grows with level**
- *What:* upgrading increases "its warming radius and the stronger its power" [MUMU]. **UNVERIFIED** (one press source).
- *Solves:* makes the core's growth visible in space.
- *Core:* heat has a geography.
- → **ADAPT.**
- *Adaptation:* the Factory Core emits base heat that reaches further as its level rises. High-temperature machines then want to sit near the Core, where tiles are scarce.
- *Depends on:* the heat sim and Core levels.
- *Related:* H1, H6.
- *Challenges:* rebalancing the ideal-temperature bands. Heat-sim performance at 44×44 with 300 machines.

**S5 · Daybreak Island, a separate decoration zone**
- *What:* opens at Furnace 19 [WF:Daybreak Island].
  - Clearing trees gives Life Essence, which upgrades the Tree of Life.
  - Decorations give bonuses, subject to a per-type **Type Limit**.
  - Prosperity counts only decorations that are actually placed.
- *Solves:* a calm, customisable side sink with permanent buffs.
- → **LATER.**
- *Adaptation:* a small "surface camp" side screen or ring tiles for monuments. The **Type Limit** rule is the reusable idea: bonus-giving placeables stop stacking past a per-type cap.
- *Depends on:* the board.
- *Related:* P11, CU1.
- *Conflict:* none, provided it adds no new currency.
- *Challenges:* scope, and a second map screen.

### 2.3 Heat / temperature & survival needs (the key section)

**H1 · The Furnace as a settlement-wide heat source that runs on fuel**
- *What:* the Furnace keeps survivors warm through day, night and blizzards. Survivors left in the cold fall sick and stop working [WF:Furnace][WSW:Furnace][BS-F].
- *Fuel:* the Furnace burns Wood early and then Coal [WF:Sawmill]. Running out of fuel removes the city's main heat source [HG-W].
- *Contradiction:* one wiki page says heat "comes from the building's level, not from ongoing fuel" [WF:Snowstorm]. The majority of sources say fuel. **UNVERIFIED.**
- *Solves:* one clear survival anchor.
- *Core:* heat is a resource you have to keep supplying.
- → **ADAPT.**
- *Adaptation:* already native to Lodeworks, where Boilers make heat and heat spreads. Borrow the framing: heat has an input cost, and running dry is the classic failure.
- *Depends on:* the heat sim and Boiler inputs.
- *Related:* H2, H3.

**H2 · On/Off and Max Power (overdrive)**
- *What:*
  - The Furnace has an On/Off switch and a Max Power setting [HG-W][TG-F].
  - Max Power doubles fuel cost. Guides advise running it through nights and "double night" snowstorms and switching it off by day [MF][MUMU][GOP].
- *Solves:* a real-time lever that trades resources for safety.
- *Core:* **the central heat decision.**
- → **ADOPT.**
- *Adaptation:* a per-Boiler (or global) **Max Power** lever: more heat output for double input consumption. Optionally a global "all Boilers" switch in the HUD.
- *Depends on:* the Boiler input model and the offline sim.
- *Related:* H1, H4, W3.
- *Conflict:* none.
- *Challenges:*
  - Balance it so Max is not always optimal.
  - The offline sim has to respect the lever.
  - Teach it through the Foreman.

**H3 · Day / night / snowstorm ambient cycle**
- *What:* three weather states: day, colder night, and snowstorm (coldest) [HG-W]. Temperature rises and drops periodically [PG].
- *Solves:* stops a steady state from going stale.
- → **ADAPT (as a stratum modifier).**
- *Adaptation:* make it one of the 12 rule modifiers, for example "Tidal Heat: ambient swings in a visible cycle", not a global clock.
- *Depends on:* the strata modifiers and the offline sim.
- *Related:* H2, H7.
- *Conflict:* a global real-time cycle risks feeling like "timers".
- *Challenges:* a deterministic offline integration of a periodic ambient temperature.

**H4 · Temperature readout at the top centre of the HUD**
- *What:* "The current temperature is always displayed at the centre of the top screen" [PG]. Guides tell players to watch it and the Survivor status together [PG].
- *Solves:* the key variable is always visible.
- → **ADOPT.**
- *Adaptation:* a top-centre thermal chip showing stratum ambient °, plus counts of machines in band, too cold and too hot. Tapping it opens heat-overlay mode.
- *Depends on:* the heat sim.
- *Related:* U1, U4.
- *Challenges:* space on a landscape phone. Localisation of the units.

**H5 · Storm countdown with requirements and a "Ready" button**
- *What:* an incoming storm is tracked on the left of the screen with a countdown and the requirements to weather it. The player clicks "Ready" when they are met [PG].
- *Requirements and failure:* the requirements include producing supplies and reaching a Furnace level. Failing damages buildings and loses survivors [MF] (**UNVERIFIED**).
- *Solves:* turns a threat into a clear, planned goal.
- → **ADAPT.**
- *Adaptation:* a **Descent readiness preview.** Before Descend, show the next stratum's heat and modifiers and a checklist, for example "2 Coolant Cells touching Smelters". The player chooses when to descend, so there is no clock.
- *Depends on:* strata generation (must be previewable) and the modifiers.
- *Related:* Q1, H4.
- *Conflict:* none if it has no timer.
- *Challenges:* generating a readable checklist from 12 modifiers.

**H6 · Needs model: warmth, fullness, sleep quality, comfort, mood**
- *What:* five survivor needs [GOP][MUMU][GR]. Poor satisfaction lowers work rate; critical lacks cause illness [MUMU].
- *Solves:* depth in the care fantasy.
- → **ADAPT (minimal).**
- *Adaptation:* keep **heat as the only need** for machines, plus "starved" (no input) and "blocked" (no outlet). These are already implied by adjacency.
- *Related:* H8.
- *Conflict:* adding more needs would bloat a small-screen game.
- *Challenges:* stopping the Foreman's messages becoming noise.

**H7 · Heat affects city operations only**
- *What:* temperature affects only survivors and city operations, not troops, gathering or heroes [HG-W].
- *Solves:* stops the key constraint leaking everywhere.
- → **ADOPT (as a scoping rule).**
- *Adaptation:* heat touches machine throughput and states only. Research, credits and UI stay heat-free.
- *Related:* H1.
- *Challenges:* none.

**H8 · Two independent causes of sickness**
- *What:* poor meals cause sickness "independently of heating and housing … even when the Furnace is kept on Max Power" [WF:Cookhouse][WF:Clinic].
- *Solves:* diagnosis becomes a skill.
- → **ADOPT.**
- *Adaptation:* every stalled machine carries an explicit cause icon (cold, hot, starved, blocked, full). The Foreman names the cause and the fix.
- *Depends on:* the Foreman and the machine states.
- *Related:* SU1, U2.
- *Challenges:* ranking causes when several apply.

**H9 · Meal-tier selector (Cookhouse)**
- *What:* three meals: Healthy Gruel, Nutritious, Fancy. A richer meal restores more Fullness and drains Meat faster [WF:Cookhouse][TG-C].
- *Solves:* a single, cheap knob with a real trade-off.
- → **ADAPT.**
- *Adaptation:* a **mode dial** on a few machines only. For example, the Smelter gets Eco / Standard / Hot: more input for more output and more heat emitted.
- *Depends on:* the recipe model.
- *Related:* H2.
- *Challenges:* the combinatorial balance. Show the mode as an on-tile glyph.

**H10 · Sickness takes the worker out until recovery**
- *What:* a sick survivor cannot work until well. The Clinic (unlocks at Furnace 4) heals, and its furniture shortens healing; before the Clinic, the sick recover in Shelters [WF:Clinic][WSW:Clinic].
- *Solves:* makes neglect costly without deleting anything.
- → **ADAPT.**
- *Adaptation:* **stall and recover.** A machine outside its band stalls and resumes only after holding its band for a short recovery period, measured in ticks (tunable). A research line shortens recovery. Machines are never destroyed.
- *Depends on:* the heat sim.
- *Related:* A1, H8.
- *Challenges:* hysteresis must stay readable. Offline sim determinism.

**H11 · "Heal all" emergency action**
- *What:* the Comprehensive Care edict heals every sick survivor. It costs 150,000 Contentment and has a 4 h cooldown [WF:Chief Orders].
- *Solves:* recovery from a mistake.
- → **ADAPT.**
- *Adaptation:* a **Vent** action that sets every stalled machine back inside its band. It costs credits or material and has no real-time cooldown.
- *Related:* W3.
- *Challenges:* don't make it the default fix.

**H12 · Snowbuster, a heat mini-game**
- *What:* plough snow using fuel. Coal feeds a fire that regenerates health. Furnace upgrades "reduce fuel consumption and increase the playable area" [WF:Snowbuster].
- → **REJECT** as a live event.
- *Lesson:* bigger core means cheaper upkeep and more space. That matches Core-level ring growth.

### 2.4 Workers / population

**W1 · Survivors assigned to workstations**
- *What:* production buildings produce nothing without assigned survivors, up to 6 per building [WF:Sawmill][WF:Coal Mine][PG].
- *Solves:* population as a production constraint.
- → **REJECT.**
- *Reason:* adjacency already staffs machines. A second allocation layer is micromanagement on a small screen.
- *Lesson:* "no input, no output" is already true in Lodeworks.

**W2 · Housing capacity attracts population**
- *What:* 8 Shelters holding at most 32 survivors [WF:Shelter][WSW:Shelter]. The more space, the more survivors arrive [PG].
- → **REJECT / LATER.** Lodeworks already caps things by Core level.

**W3 · Boosts paid in wellbeing (edicts)**
- *What:*
  - Productivity Day: +100% output at all worksites for 24 h of Survivor Time, −10 Mood, 12 h cooldown.
  - Urgent Mobilization: forced work for 48 h, −10 Mood, 8 h cooldown.
  - Festivities: +50 Mood and +30 Comfort.
  - Double Time: 20% faster construction on anything started in the next 5 minutes.

  Sources: [WF:Chief Orders][WSW:Chief's House][HG-CO].
- *Solves:* bursts that carry a cost.
- *Changes in the Aug 2026 update:*
  - [TUL] says the orders were replaced by Crunch Time, Advanced Training and Dawn Alliance Commendation. **UNVERIFIED.**
  - [VG] describes an "Automation Max" order. **UNVERIFIED.**
- → **ADAPT.**
- *Adaptation:* **Overclock directive.** For example, +100% output board-wide for a while at the cost of added heat everywhere. Heat is the natural "mood" cost in Lodeworks. One directive slot, bought with credits, no real-time cooldown.
- *Related:* H2, I4.
- *Conflict:* must not use a new currency.
- *Challenges:* the duration model offline (measure it in production shifts).

**W4 · Contentment, a currency generated by working survivors**
- *What:* Contentment comes from staffed worksites and pays for edicts. It can be bought at 50,000 for 50 Gems [WF:Chief Orders][HG-CO].
- → **REJECT.**
- *Conflict:* **conflicts with an existing decision** (no more currencies).

**W5 · Survivor profiles (an identity for each survivor)**
- *What:* arrived in the Fire Crystal Age update: every survivor gets a unique identity [OF-AS][MMOC].
- → **LATER.**
- *Adaptation:* Codex flavour entries for machine models or strata.
- *Challenges:* writing, and EN+TR localisation.

### 2.5 Economy, currencies & sinks

**E1 · Production buildings consume their own product at higher levels**
- *What:* from level 11 the Hunter's Hut costs Meat. From level 11 the Sawmill costs Meat and Wood in equal amounts [WF:Hunter's Hut][WF:Sawmill].
- *Solves:* sinks for everything, and closed loops.
- → **ADOPT.**
- *Adaptation:* from some machine level (tunable), upgrades cost the machine's own output tier, for example Smelter upgrades cost Ingots.
- *Depends on:* the machine-level cost tables.
- *Related:* O2, S1.
- *Challenges:* early deadlocks (you need Ingots to upgrade the thing that makes Ingots). Run `core_journey`.

**E2 · Converter with asymmetric fixed rates**
- *What:* the alliance resource exchange, open from state day 45, converts at uneven rates (Meat→Iron 8:1, 16:1 via Coal) with a 100,000/day cap [WF:Territory].
- *Solves:* unsticks imbalanced chains.
- → **ADAPT.**
- *Adaptation:* a deterministic, lossy **Exchange** (Vault mode or Condenser recipe) between material tiers. No daily cap.
- *Related:* E4, O5.
- *Conflict:* no daily limit, per the vision.
- *Challenges:* it can undercut the chain puzzle if the rates are too kind.

**E3 · Escalating-cost refinement batches**
- *What (Crystal Laboratory):*
  - Base resources convert to Fire Crystals. Each exchange costs 5,000 of each resource at the 1st refinement and rises to 50,000 at the 8th.
  - Yield is 1–5, weighted random.
  - Super refinements are capped at 100 Refined Fire Crystals a week; the first super refinement each day is 50% off.

  Sources: [WF:Crystal Laboratory][WF:Refined Fire Crystal].
- → **ADAPT.**
- *Adaptation:* a high-tier recipe whose batch cost escalates within a Core level and resets on Core level-up (never on the clock). Fixed, not random, yield.
- *Related:* O2.
- *Conflict:* reject the daily/weekly caps and the randomness.
- *Challenges:* explaining the escalation in the UI.

**E4 · Material exchange unlocks after a threshold**
- *What:* once one Chief Gear piece reaches Mythic T2 3★, its materials can be traded for one another [WF:Chief Gears]. Charm materials become exchangeable once any charm reaches L11 [WF:Chief Charms].
- *Solves:* fixes bad luck and imbalance later on.
- → **ADAPT.**
- *Adaptation:* the Exchange from E2 unlocks at a Core level.
- *Related:* E2.

**E5 · Protected versus plunderable storage (Storehouse)**
- *What:* protects a fixed amount of each resource; the surplus can be raided. Coal produced in the city is "secured" [WF:Storehouse][WF:Coal Mine].
- → **REJECT.** No stealable resources.
- *Adaptation of the useful part:* a storage cap as the natural offline limit, which the Core store already provides.

**E6 · Premium Gems and speedups**
- *What:* Gems pay for recruitment, speedups, VIP, Contentment and shields [WF:Gems].
- → **REJECT.** Conflicts with an existing decision (currency treadmill) and with the vision.

**E7 · Chief Stamina**
- *What:* regenerates 1 point every 5 min up to a cap of 200. The Storehouse gives 240 a day; Stamina Cans cost 100 Gems [WF:Stamina][WF:Storehouse].
- → **REJECT.** Energy.

**E8 · Stacked event scoring (one action pays in several events)**
- *What:* speedup minutes count as points in many events at once [WF:Speedups].
- → **REJECT.** Live-ops chore, and it conflicts with an existing decision.

### 2.6 Progression (heroes, gear, research, pets, crystals)

**P1 · Three research trees gated by building level**
- *What:*
  - The trees are Battle, Growth and Economy [WF:Research].
  - Wood Output I opens at Research Center 3; Wood Output VI at Research Center 30, in six tiers of three levels [WF:Sawmill].
  - Meat Output starts at +4% [WF:Hunter's Hut].
- *Solves:* a permanent, legible power curve.
- → **ADAPT.**
- *Adaptation:* group the Lodeworks tree into Growth (Core/board), Economy (one output line per material) and **Thermal** (band width, recovery, spread). Tiers are gated by Lab level or Core level, which already exists.
- *Depends on:* the research tree.
- *Related:* H10.
- *Challenges:* the tree UI on a phone.

**P2 · Drill Camp: auto-levelling to the lowest of your top five**
- *What:* any hero in a drill slot rises to the lowest level among the 5 strongest heroes. Up to 15 slots open between Furnace 13 and 30 [WF:Drill Camp].
- *Solves:* the chore of re-levelling duplicates.
- → **ADOPT.**
- *Adaptation:* a **"Standard level" per machine type.** A new machine of a type is placed at the level of your N-th best machine of that type. It is free, or you pay the level difference (tunable).
- *Depends on:* machine levels.
- *Related:* P3, QL1.
- *Challenges:* balance, because it skips a credit sink. Measure with `core_journey`.

**P3 · Level reset with full refund**
- *What:* a hero's level can be reset, freeing the Hero EXP. There is a 24 h lock that Gems can shorten [WF:Drill Camp].
- → **ADOPT (without the lock).**
- *Adaptation:* moving or demolishing a machine refunds 100% of its level investment, or keeps the level on move. Layout experiments become free.
- *Related:* P2.
- *Conflict:* the lock is a timer, so drop it.
- *Challenges:* possible exploits with the Exchange.

**P4 · "Growth" heroes that boost one production building**
- *What:* Eugene adds up to +25% Sawmill output, Charlie +25% Coal Mine, Cloris +25% Hunter's Hut and Smith +25% Iron Mine [WF:Sawmill]. Heroes come from a gacha with daily free pulls [MUMU][OF-AS].
- → **ADAPT (no gacha).**
- *Adaptation:* **Specialists** unlocked by milestones, in a fixed order (see P10). Examples: "Smelter master: +X% Smelter output". A few active slots, freely swappable.
- *Depends on:* the milestone tracking.
- *Related:* P10, Q1.
- *Conflict:* gacha rejected.
- *Challenges:* power creep, and the UI.

**P5 · Hero Exploration and Expedition skill sets**
- *What:* two independent skill sets for the two combat modes [WF:Hero Skills].
- → **REJECT.** Combat.

**P6 · Affinity curve with an "Advancement" every 10th level**
- *What:* for every Expert, level 1 grants 10.5% of the maximum bonus, each ordinary level +0.5%, and every 10th level (Advancement) +4.5%, landing exactly on the maximum at level 100 [WF:Experts].
- *Solves:* long tracks with rhythmic milestones.
- → **ADOPT (as a curve pattern).**
- *Adaptation:* machine and research level curves where every Nth level is a big step with a visual change.
- *Related:* P1.
- *Challenges:* data only.

**P7 · Chief Gear set bonuses**
- *What:* unlocks at Furnace 22. Six slots. Three pieces of the same quality raise all troops' Defense; six raise all Attack [WF:Chief Gears].
- → **LATER.**
- *Adaptation:* a **matched cluster.** A connected group of 3 or more same-level, same-type machines gets a bonus. This is spatial, so it suits adjacency.
- *Related:* S1.
- *Challenges:* fights with the heat layout, and computing it (flood fill).

**P8 · Chief Charms**
- *What:* unlock at Furnace 25. 18 sockets (6 pieces × 3), three material types [WF:Chief Charms].
- → **REJECT.** Material treadmill; conflicts with an existing decision.

**P9 · Tier upgrades that apply instantly to everything existing**
- *What:* completing a Fire Crystal level "instantly upgrades every troop of that type, at no extra cost" [WF:Fire Crystal Age].
- *Solves:* no retraining or rebuilding chores.
- → **ADOPT (as a principle).**
- *Adaptation:* research and Core bonuses always apply to existing machines.
- *Challenges:* none (Inference: likely already the case).

**P10 · Fixed, sequential unlock chain (pets)**
- *What:* pets unlock in a fixed order. Each needs a state age and the previous pet at a set level: L15 up to Cave Lion, then L30 [WF:Pets][WF:Beast Cage].
- → **ADAPT.**
- *Adaptation:* the Specialists (P4) unlock in a fixed chain driven by depth and Core milestones, never by calendar days.
- *Conflict:* state-age gating rejected.
- *Challenges:* pacing.

**P11 · Collection album with permanent buffs (Tundra Album)**
- *What:* at the Monument (Furnace 8; albums from Furnace 10), themed missions pay puzzle pieces. Completing scenes and themes gives permanent buffs such as resource production [WF:Monument][WF:Tundra Albums]. 5★ pieces are scarce and pieces can be traded within the alliance [WF:Tundra Albums].
- → **ADAPT.**
- *Adaptation:* **Codex completion.** Discovering all modifiers, machine pairings and so on in a section grants a small permanent bonus or a cosmetic. No trading or scarcity mechanics.
- *Depends on:* the Codex.
- *Related:* CU2, O1.
- *Conflict:* trading and scarce pieces are social or gacha, so reject those parts.
- *Challenges:* bonuses must not trivialise the Core conditions.

**P12 · Old building gains a new function late (Suggestion Box → Wish Station)**
- *What:* in the Fire Crystal Age the Suggestion Box becomes the Wish Station [WF:Suggestion Box][MMOC]. The Storehouse also hands out Stamina and speedups [WF:Storehouse].
- *Solves:* keeps old buildings meaningful.
- → **ADOPT.**
- *Adaptation:* at depth milestones, early machines gain a new mode. For example the Drill gets "deep bore", which works only below stratum X; the Vault gets an "Exchange" mode (E2).
- *Related:* O3.
- *Challenges:* the UI for modes.

**P13 · Overflow sink after the maximum (Expert Research)**
- *What:* Sigils keep a use after affinity is maxed: Expert Research [WF:Experts].
- → **LATER.**
- *Adaptation:* Lab output beyond a maxed tree feeds a repeatable, tiny "Deep research" line. The `explore/endless-research` branch is parked on this idea.
- *Challenges:* it becomes an infinite treadmill if uncapped.

**P14 · State-age gating**
- *What:* systems and generations open on server days, for example Fire Crystal Age at about day 60 and pets at about day 55 [WF:Progression].
- → **REJECT.** Calendar gates are timers; pace by Core level instead.

**P15 · Hero generations and power creep**
- *What:* Legendary heroes arrive in generations; Generation 17 currently [WF:Heroes]. Lucky Wheel runs a new hero every 80–100 days [WF:Lucky Wheel].
- → **REJECT.** Gacha and treadmill.

### 2.7 Events & live-ops (nearly all REJECT; lessons noted)

**EV1 · Bear Hunt, Crazy Joe, Frostdragon Tyrant, SvS, Sunfire Castle, Foundry, Canyon Clash, Winter Siege**
- *What:* alliance and cross-state PvP or co-op events [WF:Bear Hunt][WF:Crazy Joe][WF:Frostdragon Tyrant][WF:State vs State][WF:Sunfire Castle][OF-CG-0706].
- → **REJECT.** Conflicts with an existing decision (multiplayer).
- *Lesson:* see A1 on failure without loss.

**EV2 · Hall of Chiefs / King of Icefield**
- *What:* 7-day themed daily goals [WF:Hall of Chiefs][WF:King of Icefield].
- → **REJECT.** Daily chores.

**EV3 · Board and gamble mini-events**
- *What:*
  - Tundra Adventure (dice) [WF:Tundra Adventure].
  - Wander Theater (random floors) [WF:Wander Theater].
  - Treasure Hunter [WF:Treasure Hunter].
  - Lucky Wheel: 1,500 Gems a spin [WF:Lucky Wheel].
  - Mia's Fortune Hut [WF:Mia's Fortune Hut].
  - Frosty Fortune [WF:Frosty Fortune].
- → **REJECT.** Gacha, randomness and currencies.

**EV4 · Journey of Light**
- *What:* 8 h flights; 3 chests merge into 1 [WF:Journey of Light].
- → **REJECT.** Timers.

**EV5 · Fishing Tournament**
- *What:* a monthly mini-game. The guidebook persists across editions. Line, Hook and Sinker upgrade to level 10 [WF:Fishing Tournament].
- → **REJECT** as an event.
- *Lesson:* collections that persist, adopted in A3.

**EV6 · Snowbuster permanent unlocks**
- *What:* Raid mode is permanent after Area 24 [OF-CG-0302]. "Superplow permanently unlocked if player previously reached Area 24" [OF-CG-0706].
- → **ADOPT (as a principle for collapse).**
- *Adaptation:* reaching a depth or Core milestone permanently unlocks a convenience that survives collapse. This speaks to Lodeworks' open question P6, what collapse should keep.
- *Depends on:* collapse.
- *Related:* O6.
- *Challenges:* choosing what persists without trivialising a rerun.

**EV7 · Labyrinth**
- *What:* six zones, each counting a different stat source (heroes, pets, charms, research, gear, everything). They rotate by weekday, with 5 attempts per zone per day [WF:The Labyrinth].
- → **LATER / ADAPT.**
- *Adaptation:* **Trial boards.** Fixed-layout puzzle boards that each test one system: heat only, adjacency only, research. They are replayable and on no schedule.
- *Challenges:* level design effort.

**EV8 · Endless Trials**
- *What:* a daily solo boss with up to 30 attacks [MMOC].
- → **REJECT.** Daily.

**EV9 · Symphony of Changes**
- *What:* its 15-mission puzzle "cannot be completed without spending" (a pack containing 2,500+ Gems) [WF:Symphony of Changes].
- → **REJECT.** An explicit pressure point.

**EV10 · Return to Tundra**
- *What:* catch-up events for players who were offline 10–31 days [WF:Return to Tundra].
- → **ADAPT** (see I5).

**EV11 · Crystal Reactivation, Supply Drop, Silver Shell Shop, Hero Rally**
- *What:* recurring paid or currency events [WF:Crystal Reactivation][WF:Supply Drop][WF:Silver Shell Shop][WF:Hero Rally].
- → **REJECT.**

### 2.8 Quests, chapters & guidance

**Q1 · Chapter Missions**
- *What:*
  - 10 chapters make up the campaign; each needs its missions done to unlock the next [WSW:Chapter Missions][GOP].
  - The missions are one-time and do not expire. Clicking a mission "will automatically take you to the mission location" [BS-B].
  - They sit behind a scroll icon at the bottom left [BS-B].
- *Solves:* onboarding and direction that never expire.
- *Core:* the chapter list is the moment-to-moment "next thing".
- → **ADOPT.**
- *Adaptation:* chapter = Core level, and main missions = the Core level's conditions. Every "What now?" row is tappable: it pans the camera to the tile and opens the build palette with the machine preselected.
- *Depends on:* "What now?" (`worklist.gd`) and Core levels.
- *Related:* Q2, SU1, U4.
- *Challenges:* camera pathing on the isometric board. Keep the EN/TR strings in `Loc.t`.

**Q2 · Main versus side quests**
- *What:* main quests unlock modes; side quests pay resources [BS-B].
- → **ADAPT.**
- *Adaptation:* main missions are the Core conditions. Side missions teach one mechanic each, for example "Place a Coolant Cell touching a Smelter", and pay a small, fixed reward.
- *Related:* Q1.
- *Challenges:* reward inflation.

**Q3 · Growth missions (Rookie's Growth, Trials)**
- *What:* milestone tracks separate from chapters [WF:New Players][MUMU].
- → **ADAPT.** Fold them into Q2 rather than adding another tab.

**Q4 · Daily Missions**
- *What:* Activity points fill 7 chests; 80 Mystery Badges a day [WF:Daily Missions].
- → **REJECT.** Conflicts with an existing decision (daily chores).

**Q5 · Wish Station: sequential requests**
- *What:*
  - Requests are completed "in a set order" across food, housing, healthcare, work and entertainment.
  - More wishes open as the Furnace rises and earlier wishes are done.
  - Completed wishes pay Wish Sigils, spent in the Wish Shop on materials for 9 entertainment facilities.

  Sources: [MMOC][WSCO][OF-AS].
- → **ADAPT.**
- *Adaptation:* **Commissions.** A sequential chain of concrete board goals, such as "keep 3 Smelters at working heat together", paying direct unlocks (a Specialist, a mode, a cosmetic) with no sigil currency.
- *Related:* P4, P12.
- *Conflict:* the currency part conflicts with an existing decision.
- *Challenges:* writing goals that the offline sim can check.

**Q6 · Tutorial that starts from a bonfire**
- *What:* the settlement "starts as a large bonfire but will quickly grow" [PG]. The tutorial unlocks features progressively [GOP].
- → **ADOPT.**
- *Adaptation:* the Core starts as a "pilot flame". Heat is introduced in the first minutes, for example through a guaranteed cold spot in stratum 1.
- *Related:* Q1, H5.
- *Challenges:* the first-session flow and measuring it.

### 2.9 World map & exploration

**M1 · Exploration idle stages**
- *What:* advancing stages raises the idle rate [HG-EC]. A chest appears above the Explorers Cabin when the offline maximum is reached [WSW:Explorers Cabin][WF:Explorers Cabin]. The cap is 9 h, up from 7 h [HG-EC]; an older press source says 7 h [MF].
- → **ADAPT.**
- *Adaptation:* depth already raises output. Show the offline rate explicitly in the away report (I5). Signal "storage full" with a chest-style badge on the Core.
- *Related:* I3, U2.
- *Conflict:* reject the hard cap as a return driver.

**M2 · Intel missions**
- *What:* at the Lighthouse (Furnace 7), missions refresh 3 times a day. The Searchlight levels up with use to a maximum of 20, surfacing more and better missions [WF:Intel][WF:Lighthouse].
- → **REJECT** the refresh.
- *Idea kept, LATER:* "levels up by use" as a stratum **Survey** that reveals richer pockets the more you mine.

**M3 · World map, gathering marches, beasts, territory, teleport**
- *Sources:* [WF:Beast Hunt][WF:Territory][WF:Teleport].
- → **REJECT.** Multiplayer.

**M4 · Arena**
- *What:* 5 free challenges a day. Defending never changes your points [WF:Arena].
- → **REJECT.** PvP.

**M5 · Local personal records (Inference; derived from the ranking systems)**
- → **ADOPT.**
- *Adaptation:* on-device records such as deepest stratum, fastest Core 5, and longest run at full working heat. No server needed.
- *Conflict:* leaderboards are rejected; these are local only.
- *Challenges:* none.

### 2.10 Social / alliance (brief)

**SO1 · Alliance help, technology, territory, shop, chat, rallies, reinforcement**
- *What:* alliances unlock at Furnace 7 [WF:Alliance][WF:Alliance Technology][WF:Territory].
- → **REJECT.** Conflicts with an existing decision.

**SO2 · Gift codes**
- *What:* redeemed in-game or at a web centre [WF:Gift Codes].
- → **LATER / REJECT.** Needs server validation or a marketing channel.

### 2.11 UI / HUD & information design

**U1 · Always-visible key variable**
- *What:* the top-centre temperature [PG].
- → **ADOPT** (see H4).

**U2 · Status icon above a building**
- *What:* a chest over the Cabin when idle rewards are full [WSW:Explorers Cabin].
- → **ADOPT.**
- *Adaptation:* on-tile badges: cold, hot, starved, blocked, storage full, upgrade affordable.
- *Challenges:* clutter at 300 machines, so show badges only at a zoom threshold or grouped.

**U3 · Survivor status overview**
- *What:* guides tell players to watch "Survivor status" alongside the temperature [PG].
- → **ADOPT.**
- *Adaptation:* counts by machine state (working, idle, stalled by cause), tappable to cycle through them.
- *Related:* U4.

**U4 · Task list / Overview panel**
- *What:* April 2026: "Task List navigation improved" [WT]. August 2026: a new "Daily tab in Overview interface" [TUL] (**UNVERIFIED** detail).
- → **ADOPT.**
- *Adaptation:* a **Board ledger.** Every machine grouped by type and state, each with a jump button.
- *Challenges:* list virtualisation and small-screen layout.

**U5 · Level and name labels on the map**
- *What:* July 2026: World Map shows facility level and name [OF-CG-0706].
- → **ADOPT.**
- *Adaptation:* a toggle that shows machine levels on the board.
- *Challenges:* legibility of isometric text.

**U6 · Separate tabs per camp**
- *What:* March 2026: separate troop camp tabs "for faster navigation" [OF-CG-0302].
- → **ADAPT.**
- *Adaptation:* tabs in the build palette by chain stage (extract / process / heat / meta).

**U7 · Batch actions**
- *What:* "Use All" became "Multi Recruit". Fishing got a one-tap daily claim. The Tundra Trading Station got quick exchange [WT].
- → **ADOPT.**
- *Adaptation:* "Upgrade all Smelters to max affordable" and "collect all".
- *Challenges:* respecting the Core caps.

**U8 · Pre-event reminders**
- *What:* the Lighthouse shows 24 h pre-event reminders [WT].
- → **REJECT.** FOMO.

### 2.12 Notifications & re-engagement

**N1 · Push notifications**
- *What:* reportedly configurable and focused on combat and alliance matters [BITT]. **UNVERIFIED.**
- → **LATER, opt-in only.**
- *Adaptation:* at most one local notification, "Core storage full", off by default.
- *Conflict:* guilt pushes are rejected.

**N2 · VIP login-day counting**
- *What:* March 2026 added a toggle between "consecutive and total login days" [OF-CG-0302].
- → **REJECT.** Conflicts with an existing decision (streaks).

### 2.13 Idle / offline

**I1 · City production while offline**
- *What:* offline income accumulates for "up to a 12-hour period" [MF]. **UNVERIFIED** (one press source).
- → **ADAPT.**
- *Adaptation:* Lodeworks already simulates offline. Let the Core store and Vault caps be the only limit. Show a projected "full in …" figure as information.
- *Conflict:* no hard cap intended to pull players back.

**I2 · Idle rewards scale with progress**
- *What:* see M1 [HG-EC].
- → **ADOPT** (already implied by depth).

**I3 · Online-only timers**
- *What:* Storehouse speedups accrue "on a timer that only runs while you are online" [WF:Storehouse].
- → **REJECT.**

**I4 · Rush Job: a lump of production**
- *What:* "Gives 5 days' worth of resources from all worksites", 24 h cooldown, 150,000 Contentment [WF:Chief Orders][WSW:Chief's House].
- → **ADOPT as the rewarded-video offer.**
- *Adaptation:* "Rush: N shifts of production now". Limit it **per Core level** (for example k uses each level, tunable) rather than by real-time cooldown.
- *Related:* W3.
- *Conflict:* fits the rewarded-video-only rule.
- *Challenges:* the AdMob integration already exists. Balance so it is a nice-to-have, not needed.

**I5 · Welcome-back catch-up**
- *What:* Return to Tundra runs 5 mini-events for players returning after 10–31 days away [WF:Return to Tundra].
- → **ADAPT.**
- *Adaptation:* an **Away report** on return: produced, sold, stalled (with causes), research finished. Nothing is lost and there is no guilt copy.
- *Related:* C1, M1.
- *Challenges:* the offline sim has to log stall events cheaply.

### 2.14 Quality of life

**QL1 · Drill Camp and level reset**
- See P2 and P3. → **ADOPT.**

**QL2 · Carry-over tokens and progress between events**
- *What:* Embers, Trading Station vouchers and Silver Shells carry over; the fishing guidebook persists [WF:Crystal Reactivation][WF:Tundra Trading Station][WF:Silver Shell Shop][WF:Fishing Tournament].
- → **ADOPT (principle).** Nothing earned ever expires.

**QL3 · Content trimming**
- *What:* Mercenary Prestige stages cut from 50 to 25 [WT]. Snowbuster fuel costs reduced from Area 24 [OF-CG-0302]. Wild Brawl mission requirements lowered with total rewards kept [OF-CG-0302].
- → **ADOPT (process lesson).** Prune the grind after measuring it, as `core_journey` already does.

**QL4 · Auto-join**
- *What:* Auto Join fills alliance rallies without an invitation [WF:Hero's Mission].
- → **REJECT.** Multiplayer.

### 2.15 Customisation

**CU1 · Skins**
- *What:* skins for city, march, portrait and so on. Four of the five families carry small permanent bonuses; nameplates are purely decorative [WF:Skins].
- → **ADAPT.**
- *Adaptation:* machine and Core skins earned from milestones or the one-time purchases, with **no stats**, because purchases never change economy numbers.
- *Conflict:* the stat part conflicts with the vision.
- *Challenges:* art budget.

**CU2 · Collection Gallery**
- *What:* permanent skins displayed together, earning Collection Points and a Collection Level [WT].
- → **ADAPT.**
- *Adaptation:* a Codex gallery page, cosmetic only.
- *Related:* P11.

**CU3 · Vinyl Shop jukebox**
- *What:* an entertainment facility where the player can "select and listen to various in-game music", with repeat [VG].
- → **ADOPT (cheap).**
- *Adaptation:* soundtrack tracks unlocked by depth.
- *Challenges:* needs music assets.

### 2.16 Endgame & keeping old stuff valuable

**O1 · Core conditions reference old buildings**
- See S1. → **ADOPT.**

**O2 · Base resources stay the bulk sink**
- *What:* Fire Crystal levels still cost Meat, Wood, Coal and Iron. The Crystal Laboratory turns base resources into crystals [WF:Fire Crystal Age][WF:Crystal Laboratory]. The four resource buildings stop at level 30 [WF:Sawmill].
- → **ADOPT.**
- *Adaptation:* deep recipes and Core levels demand Ore and Gravel in volume, so Drills and Crushers are never obsolete.
- *Related:* E1, E3.
- *Challenges:* throughput balance.

**O3 · Repurposed old buildings**
- See P12. → **ADOPT.**

**O4 · Global upgrades lift existing units**
- See P9. → **ADOPT.**

**O5 · Trading in obsolete items (Tundra Trading Station)**
- *What:* trade unwanted older-generation items for vouchers. A hero's shards become tradeable only once that hero has 5 stars [WF:Tundra Trading Station].
- → **ADAPT.**
- *Adaptation:* **Salvage.** Surplus low-tier stock or unneeded machines turn into credits or Exchange input at a fair rate.
- *Related:* E2.

**O6 · Late facilities that produce progression items**
- *What:* 9 entertainment facilities, each dropping random progression rewards daily [MMOC][OF-AS][VG].
- → **REJECT** the daily random drops.
- *ADAPT:* late machines whose output is meta progress, for example research data from depth.

### 2.17 Anti-frustration

**A1 · Failure without loss**
- *What:*
  - Bear Hunt: "the bear does not fight back, so all attacking troops survive".
  - Crazy Joe: "nothing is plundered".
  - Frostfire Mine: a "safe" PvP event where troops cannot be killed.

  Sources: [WF:Bear Hunt][WF:Crazy Joe][WF:Frostfire Mine].
- → **ADOPT.**
- *Adaptation:* heat failures stall machines and never destroy them or lose stock. Collapse is always voluntary.
- *Related:* H10.

**A2 · Unclaimed rewards are delivered automatically**
- *What:* unclaimed Daybreak Expedition rewards are mailed when the event ends [WF:Daybreak Expedition].
- → **ADOPT.** Auto-credit anything earned.

**A3 · Persistent collections across sessions and events**
- See QL2 and EV5. → **ADOPT.**

**A4 · Unskippable 24 h waits**
- *What:* a Drill Camp slot waits 24 h after a hero is removed and "cannot be shortened" [WF:Drill Camp].
- → **REJECT.** An anti-example.

**A5 · Wide early choices**
- *What:* guides advise leaving the Cookhouse, Shelters and Clinic around level 6–8 to save resources [WF:New Players].
- *Lesson (Inference):* survival buildings are "good enough" early, so the care layer is not a treadmill.
- → **ADOPT.** Heat bands wide early and narrowing with depth.

### 2.18 Monetisation (for rejection analysis)

All entries in this section are → **REJECT**; the specific pressure points are in §5.
- **MO1 · VIP:** levels 1–12 with permanent bonuses, a VIP Shop from level 2, and a free daily speedup. VIP points are sold in packs: 500 at $0.99 up to 20,000 at $99.99 [WF:VIP][WF:Frosty Fortune].
- **MO2 · Queue packs:** a Construction Queue Pack (2 builders) and a March Queue Pack. Guides call them must-buys on day 1 [WF:New Players].
- **MO3 · Cards and funds:**
  - Monthly and Weekly Cards and a Growth Fund [WF:New Players][WF:Spending Guide].
  - Named cards include the Ultra Value Monthly Card (50% off the first purchase), Building Benefits Card, Intel Monthly Card and Fire Crystal Shard Weekly Card.
  - The App Store lists "Daily Worship" and "Regular Pass" at $4.99 [OF-AS].
- **MO4 · Paid progression events:** Hero Rally (2,160 Gems per level), Hall of Heroes (Marks of Valor at 150 Gems), Lucky Wheel (1,500 Gems a spin), Crystal Reactivation (Ember packs from €5.99 to €59.99), and Frosty Fortune (daily packs from $0.99 to $99.99, the top one buyable 3 times) [WF:*].
- **MO5 · Must-pay completion:** Symphony of Changes [WF].
- **MO6 · Spend tiers:** guides describe "whales" spending above €1,000 a month and the strongest players €2,000–8,000 a month [WF:Spending Guide]. App Store reviews mention $300–500+ [OF-AS].
- **MO7 · The only compliant analogue:** a rewarded video for Rush (I4). The two one-time purchases must stay cosmetic or convenience with zero economy effect, for example skins or the jukebox.

---

## 3. Complementary clusters for Lodeworks

**A. Heat as a readable crisis loop.** Features: H4/U1 thermal chip, U2 badges, H8 cause icons, H10 stall-and-recover, H2 Max Power lever, H11 Vent, S4 Core warmth radius.
1. The HUD shows the problem.
2. The badge shows where it is.
3. The Foreman says why.
4. The player pulls a lever (Max Power or a mode) or re-lays tiles.
5. The machine recovers without loss.

Whiteout's core survival fantasy is exactly this, minus the micromanagement of survivors. In Lodeworks it can live entirely in the heat sim and adjacency.

**B. Guidance spine.** Features: Q1 chapters mapped to Core levels, tap-to-navigate "What now?", Q2 side lessons, Q5 Commissions, SU1 Foreman complaints, H5 descent readiness.
- Every piece answers "what next, and where" with one tap.
- Commissions give a sequential, never-expiring goal track in place of daily missions.
- The descent preview turns the 12 strata modifiers into planned puzzles rather than surprises.

**C. Idle and return loop without guilt.** Features: I1 offline sim capped only by storage, I5 Away report, M1/U2 "storage full" chest badge, I4 rewarded-video Rush limited per Core level, N1 opt-in single notification, C1 "before you go" card.

Whiteout pulls players back with caps, refreshes and FOMO. Lodeworks can pull them back with curiosity about what the factory did and what to fix next.

**D. Keep old stuff relevant.** Features: S1/O1 Core conditions citing early machines, E1 self-consuming upgrade costs, O2 base materials as the bulk sink, P12/O3 new modes for old machines at depth, E2/O5 Exchange and Salvage, P2 Standard level.

Early chain machines stay load-bearing through the late game, which is the pattern Whiteout uses with its four resource buildings.

**E. Meta and prestige that survives collapse.** Features: EV6 permanent milestone unlocks, P11 Codex completion bonuses, P4/P10 Specialists chain, M5 local records, CU1–3 cosmetics and jukebox.

This offers answers to the open decisions on what collapse keeps (P6) and on blueprints (P7). **Inference:** a saved layout "blueprint" pairs naturally with P2's Standard level. A rebuilt layout could snap to standard levels after collapse.

---

## 4. Top 15 recommendations (ranked by value/effort)

1. **Make every "What now?" and chapter row tappable, so it pans the camera to the tile and opens the palette with the machine preselected (Q1).** Whiteout's most praised onboarding trick, and very cheap because `worklist.gd` exists.
2. **Add a top-centre thermal chip plus on-tile cause badges (H4, U2, H8).** A heat game should show its key variable permanently, as Whiteout shows temperature.
3. **Add a Boiler Max Power lever: more heat for double input (H2).** It is the single most characteristic heat decision in Whiteout and fits Boilers directly.
4. **Have the Foreman voice complaints that name the cause and jump to the tile (Suggestion Box, H8).** This turns diagnosis into gameplay rather than frustration.
5. **Use a "Standard level" per machine type, so new machines arrive at your N-th best level (Drill Camp, P2).** It removes the most tedious chore in a factory game.
6. **Show a descent readiness preview and checklist before Descend (storm countdown and "Ready", H5).** It makes the strata modifiers into planned heat puzzles with no clock.
7. **Offer a rewarded-video "Rush: N shifts of production", limited per Core level rather than by real time (Rush Job, I4).** It is the one Whiteout monetisation mechanic compatible with the vision.
8. **Show an Away report on return: produced, stalled and why, finished (Return to Tundra and the idle chest, I5).** It re-engages through curiosity instead of guilt.
9. **Make upgrades cost their own output tier at higher levels, and make deep recipes need base Ore and Gravel in bulk (E1, O2).** A data-only change that keeps Drills and Crushers relevant forever.
10. **Let milestones permanently unlock conveniences that survive collapse (Snowbuster's permanent Superplow, EV6).** Directly addresses the open P6 question.
11. **Stall and recover, never destroy (sickness and Clinic plus no-loss events, H10, A1).** Real heat stakes without loss aversion.
12. **Add a Board ledger listing machines by state with jump buttons (Task List and survivor status, U3, U4).** Essential navigation for a 44×44 board on a phone.
13. **Add a mode dial on 2–3 machine types, such as Smelter Eco / Standard / Hot (Cookhouse meal tiers, H9).** A cheap trade-off knob that deepens heat play.
14. **Give Codex completion small permanent or cosmetic rewards (Tundra Album, P11).** Rewards exploring the 12 modifiers and pairings.
15. **Add an Exchange / Salvage for surplus materials at fixed lossy rates, unlocked by Core level (territory exchange and Trading Station, E2, O5).** Unsticks imbalanced chains without daily caps.

Just outside the list: Commissions (Q5), the Core warmth radius (S4), Specialists (P4), and the jukebox (CU3, cheap but low value).

---

## 5. REJECT list with reasons (Whiteout's pressure points)

**Timers as gates**
- Construction, research and training timers, and speedups (C3).
- The second builder at 1,000 Gems per 2 days (C2).
- The 24 h Drill-slot lock that cannot be skipped (A4).
- Online-only Storehouse timers (I3).
- 8 h flights (EV4).
- Edict cooldowns.

The pressure: waiting is converted into spending on speedups and queues.

**Energy**
- Chief Stamina (1 point per 5 min, cap 200), Stamina Cans at 100 Gems, and Fishing bait regeneration (E7).

The pressure: a cap wastes regeneration unless the player logs in often.

**Refresh and cap pressure**
- Intel refreshes 3 times a day (M2).
- The 9 h Exploration idle cap (M1).
- The 12 h city offline cap (**UNVERIFIED**).
- Weekly Refined Fire Crystal caps (E3).

The pressure: several sessions a day are needed to avoid "losing" value.

**Daily chores and streaks (conflicts with an existing decision)**
- Daily Missions with 7 chests (Q4).
- VIP login days (N2).
- Hall of Chiefs / King of Icefield themed days (EV2).
- Endless Trials (EV8).
- The daily-routine checklist culture [HG-DR].

**Gacha and randomness**
- Hero recruitment (the store lists "Loot Boxes").
- Lucky Wheel, Frosty Fortune, Mia's Fortune Hut, Wander Theater, Treasure Hunter, Tundra Adventure (EV3).
- Random Crystal Lab yields and random entertainment-facility drops (E3, O6).

**Currency treadmill (conflicts with an existing decision)**
- Gems, Contentment, and more than 15 event tokens (E6, W4, overview).
- Charms and gear materials (P8).
- Generation-bound Marks and Widgets (MO4, P15).

The pressure: each new currency is a new store page.

**Multiplayer, social and leaderboards (conflicts with an existing decision)**
- Alliance systems (SO1).
- SvS, Bear Hunt, Crazy Joe, Frostdragon Tyrant, Arena and every ranking (EV1, M4).
- Plunder and the Storehouse protection threshold (E5).

The pressure: social obligation and fear of theft. Lodeworks also has no stealable resources.

**Calendar and state-age gating**
- Pets around day 55, Fire Crystal Age around day 60, generations every 70–100 days (P14, P15).

The pressure: FOMO plus power creep, which makes old purchases obsolete.

**Explicit pay-to-complete and pay-to-keep-up**
- Symphony of Changes cannot be completed without buying (EV9).
- VIP stat bonuses, and cosmetics with stat bonuses (MO1, CU1).
- Must-buy day-1 queue packs (MO2).
- Monthly cards, Growth Fund and passes (MO3).
- Daily-reset packs up to $99.99, three times a day (MO4).
- The spending tiers guides describe: "whale" above €1,000 a month (MO6).

**Pre-event reminders and re-engagement pushes**
- (U8, N1): FOMO notifications.

---

## 6. Sources

**Official**
- [OF-AS] App Store listing: https://apps.apple.com/us/app/whiteout-survival/id6443575749 (v1.33.9, 17 Aug 2026; description, IAP list, content descriptors, user reviews)
- [OF-CG-0302] Century Games, "New Content Update" (2 Mar 2026): https://www.centurygames.com/whiteout-survival-new-content-update/
- [OF-CG-0706] Century Games, "Update" (6 Jul 2026): https://www.centurygames.com/whiteout-survival-wos-update/
- WOS_Global post on the Wish Station: https://x.com/WOS_Global/status/2087010538257858595 — seen only as a search snippet (the fetch returned HTTP 402), so none of its content is cited.
- The official site https://whiteoutsurvival.centurygames.com is rendered by JavaScript and gave no content. The Google Play page returned only truncated content.

**Community wikis**
- [WF:Page] wiki.wosforge.org, read through its MediaWiki API (`api.php?action=parse&prop=wikitext`), 250 English pages fetched on 25 Sep 2026. Pages cited: Furnace, Snowstorm, Game Mechanics, Shelter, Cookhouse, Clinic, Hunter's Hut, Coal Mine, Sawmill, Iron Mine, Storehouse, Explorers Cabin, Chief Orders, Chief's House, Suggestion Box, Progression, New Players – First Few Days, Beginner's Guide, Daily Missions, VIP, Intel, Lighthouse, Daybreak Island, Daybreak Expedition, Crystal Laboratory, Refined Fire Crystal, Fire Crystal Age, Crystal Reactivation, Experts, Dawn Academy, Construction, Speedups, Stamina, Research, Growth/Economy Research, Pets, Beast Cage, Chief Gears, Chief Charms, Monument, Tundra Albums, Widgets, Drill Camp, Hero Skills, Heroes, Skins, Events, Bear Hunt, Crazy Joe, Frostdragon Tyrant, Hall of Chiefs, King of Icefield, Two-Day Events, Tundra Adventure, Frosty Fortune, Lucky Wheel, Mia's Fortune Hut, Snowbuster, Fishing Tournament, Wander Theater, Tundra Trading Station, Supply Drop, Journey of Light, Hero's Mission, The Labyrinth, Arena, Tundra Trade Route, Spending Guide, Frostfire Mine, Return to Tundra, Symphony of Changes, Silver Shell Shop, Gems, Hero Rally, Hall of Heroes, Gift Codes, Alliance, Alliance Technology, Territory, State vs State, Peace Shield, Plunder, Mercenary Prestige.
  - *Caveat:* some pages are generic, and the Snowstorm page contradicts the fuel statements on Sawmill and Cookhouse.
- [WSW:Page] whiteoutsurvival.wiki: /buildings/, /buildings/furnace/, /shelter/, /cookhouse/, /clinic/, /chiefs-house/, /storehouse/, /sawmill/, /explorers-cabin/, /suggestion-box/, /research/, /chapter-missions-beginner-quest-overview/
- Fandom (whiteoutsurvival.fandom.com): **not reachable.** Pages sit behind a Cloudflare challenge; the API returned 404/402. Not bypassed.

**Press and guides**
- [PG] https://www.pocketgamer.com/whiteout-survival/guide/
- [MF] https://medievalfun.com/white-out-survival-beginner-guide-tips-and-tricks/
- [MUMU] https://www.mumuplayer.com/blog/basics-white-out-survival.html
- [GOP] https://gamingonphone.com/guides/whiteout-survival-beginners-guide-and-tips/
- [BS-F] https://www.bluestacks.com/blog/game-guides/white-out-survival/wos-furnace-guide-en.html
- [BS-B] https://www.bluestacks.com/blog/game-guides/white-out-survival/wos-beginner-guide-en.html
- [HG-W] https://heaven-guardian.com/whiteout-survival-weather-guide/
- [HG-CO] https://heaven-guardian.com/whiteout-survival-chiefs-house-orders-guide/
- [HG-DR] https://heaven-guardian.com/whiteout-survival-daily-routine/
- [HG-EC] https://heaven-guardian.com/whiteout-survival-explorers-cabin/
- [TG-F] / [TG-C] / [TG-S] https://theriagames.com/guide/whiteout-survival-furnace-guide/ (and cookhouse-guide, shelter-guide)
- [GR] https://gamerant.com/whiteout-survival-survivor-happiness-guide/
- [MMOC] https://mmoculture.com/2026/08/whiteout-survival-fire-crystal-age-expansion-and-new-updates/
- [TUL] https://www.topuplive.com/news/whiteout-survival-fire-crystal-age-guide.html
- [WSCO] https://www.whiteoutsurvival-community.com/tools/wiki/events/wish-station-wsco.html
- [VG] https://vortexgaming.io/en/postdetail/1246899 and https://vortexgaming.io/en/postdetail/1252451
- [WT] https://wostools.net/blog/april-15-2026-update
- [BITT] https://bittopup.com/article/whiteout-survival-notification-settings (weak source)
