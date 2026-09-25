# Reference-game research for Lodeworks: Hay Day, Township, State of Survival (September 2026)

**How to read this.**
- Source keys are in square brackets and are listed in section 6. Official sources come first: Supercell support (HS) and Playrix Helpshift (PX). Wiki keys are HW, TW and SW. Press is PG, BS and LWN. LW is the Lodeworks repository's own docs.
- **Inference** marks my own reading of a design. **UNVERIFIED** marks anything I could not confirm.
- No number here was made up. Every number comes from its cited source. Where an adaptation needs a number, it is written as N and must be tuned with `tools/core_journey.gd`.
- Fit values are ADOPT, ADAPT, LATER and REJECT. "Conflicts with an existing decision" points to LW:AUDIT §2: D1 (more machines, strata or currencies), D2 (daily or weekly challenges and streaks), D3 (multiplayer, leaderboards and social), D4 (premium currency, packs, subscriptions and interstitials) and D5 (randomised hidden bonuses).

**Findings on the items you asked me to check**
- **Hay Day has no "Machine Upgrade Materials".** Its upgrade materials are for storage: Barn, Silo and Tackle Box [HS:storage]. Town service buildings also use materials [HS:service-upg]. Machines improve in three ways:
  - production slots bought with diamonds [HS:prod-bldg];
  - Mastery stars earned from hours of use [HS:prod-bldg][HW:Masteries];
  - a new "Building Mastery" workbench screen, added on 10 Aug 2026 and not yet rolled out to everyone. Its details are **UNVERIFIED** [HW:Update].
- **State of Survival "survivor/worker assignment": UNVERIFIED.** No wiki or press source I read describes survivors or workers being assigned to buildings. The closest verified systems are:
  - Hero Appointment: heroes placed in slots for bonuses [SW:Appointment];
  - hero-specific gathering bonuses [SW:Basics];
  - "Rescue Survivor" intel, which adds troops [SW:Intel].
- **State of Survival "chapter guidance": partly verified.** Growth and Side Missions exist [SW:Missions], as do Story Mode chapters [SW:Story]. A HUD "chapter task" panel is **UNVERIFIED**; press sources only say main missions matter early [PG:sos][LWN:sos].

---

## 1. Overview per game

**Hay Day (Supercell, 2012; patch notes up to v1.72 on 10 Aug 2026 [HW:Update])**
- **Areas:**
  - Farm: crops, animals and more than 50 production buildings, unlocked from level 2 to level 124 [HW:ProdBldg].
  - Fishing Lake from level 27 [HW:Fishing] and Mine from level 24 [HW:Mine].
  - Town from level 34, with its own Reputation level [HS:town].
  - Wildlife Sanctuary [HS:sanctuary].
  - Valley from level 25: 21-day seasons with about 60 players per map [HS:valley].
- **Social:** Neighborhoods of 1–30 players [HW:Neighborhood], a weekly Derby [HS:derby], and player trading through the Roadside Shop and the Daily Dirt newspaper [HS:roadside][HW:DailyDirt].
- **Core loop:**
  1. Plant one harvested crop to get two back [HW:Crops].
  2. Feed animals and run the output through production buildings.
  3. Fill truck, boat, visitor and town orders for coins and XP.
  4. Spend on buildings and fields.
  5. Upgrade Barn and Silo with upgrade materials.
  6. Level up to unlock more.
- **Currencies:** coins, diamonds (premium), four voucher colours, Valley tokens, puzzle pieces, gift cards, chick vouchers, golden keys and seasonal currencies [HW:Currencies][HS:surprise], plus the separate Reputation XP [HS:town].
- **Tagline:** "It never rains here, but the crops never die" [SC:hayday].

**Township (Playrix; iOS 2012 [TW:Township])**
- **Town and farm:** fields, animal farms, a feed mill and factories [TW:Factories][PX:farming].
- **Population:** houses raise population, and community buildings raise the population cap. Population in turn gates factories, fields and expansions [TW:Houses][TW:Community][PX:how-to-play].
- **Transport orders:**
  - helicopter, for coins and XP;
  - train, which returns construction materials;
  - plane, filled in rows;
  - ships to islands, which bring exclusive goods [PX:farming][TW:Ships].
- **Mine chain:** ore goes to the Foundry and becomes ingots, which pay for Academy of Industry upgrades [TW:Mine][TW:Foundry][TW:Academy].
- **Other systems:** City Market and a dealer [TW:Market]; Laboratory boosters bought with gems [TW:Lab]; a Match-3 layer with lives, feeding events and expeditions that use energy [TW:Match3][TW:Expedition]; Teams and the weekly Regatta [PX:teams]; card Collections [PX:collection].
- **Currencies:** coins, T-cash (premium), gems, clovers, ingots, construction materials, event and Regatta tokens, lives and energy [TW:Township][TW:HouseOfLuck][TW:Lab].

**State of Survival (FunPlus; the wiki names KingsGroup Holdings [SW:Intro]). What it adds beyond Whiteout-type builders:**
- **HQ as the universal cap:** "no other construction can be higher than your headquarters" [BS:sos].
- **Plasma levels after HQ 30:** each level has 5 sub-levels and costs rare Plasma Cores [SW:HQ][SW:PlasmaCores]. The Institute of Plasma adds plasma research [SW:InstPlasma].
- **Research Lab:** Development, Battle and Economic trees [SW:ResearchLab]. Research Tasks shorten research timers [SW:ResearchTask].
- **Missions:** up to 7 daily reward crates, plus Growth and Side missions [SW:Missions]. Story Mode has chapters [SW:Story].
- **Heroes:** Hero Appointment slots [SW:Appointment] and the Explorer Trail, which runs on squad stamina [SW:Explorer].
- **Intel map:** a radar level raises the quality tier of intel [SW:Intel]. Intel uses stamina [SW:Stamina].
- **Events:** state and world events with temporary stats, such as Cold Resistance at Frontier Outposts [SW:Frontier], and a roguelite "Underground Shadow Exploration" [SW:Underground].
- **Returning players:** a Recall event triggers after roughly 61 days offline [SW:Recall].
- **Currencies:** food, wood, metal, gas, biocaps (premium) and Plasma Cores [SW:Resources][SW:Biocaps].

---

## 2. Feature inventory

Every entry has the same parts: what it is and what problem it solves; what it adds to the core loop and which features it relates to; the challenges of building it in a small Godot game; the fit and the adaptation; and what it depends on, any conflict, and the source.

### A. Production chains and their UI

**A1. One building per product family, with recipes that mix tiers** (Hay Day, Township)
- **What it is / what it solves:**
  - Hay Day has more than 50 machines, each making one family of goods [HW:ProdBldg].
  - Township recipes mix tiers: Pizza is 2 wheat + 1 cheese + 2 tomato, and a Cheeseburger is 2 bread + 1 cheese + 1 tomato [TW:Goods].
  - A mixed recipe forces several chains to run in parallel instead of one straight line.
- **Core loop / related:** planning which lines to run. Related: A4, P1, P2 and C2.
- **Challenges:** with adjacency and no belts, a machine that takes two inputs needs two feeding neighbours. That is a layout puzzle, which is good, but the "starved" state must be readable.
- **Fit: ADAPT.** Do not add materials, because D1 refuses them. Where it makes sense, let an existing late machine (the Assembler) take one input from two tiers, for example a Plate and an Ingot. **UNVERIFIED** whether it already does.
- **Depends on / conflict / source:** the recipe table, the machine starved/blocked states and the Codex. Conflict only if it adds new materials (D1). [HW:ProdBldg][TW:Goods]

**A2. Production queue slots per machine** (Hay Day, Township)
- **What it is / what it solves:**
  - Hay Day machines start with 1–3 slots and go up to 9, bought with diamonds [HS:prod-bldg]. The first extra slot costs 6 diamonds, then 9, then 12 [HW:ProdBldg].
  - Township factories have up to 7 production boxes bought with T-cash [TW:Factories].
  - Queues let players load up before going offline.
- **Core loop / related:** queue management. Related: R9 and E5.
- **Challenges:** does not fit continuous adjacency production.
- **Fit: REJECT.** Lodeworks machines run continuously from their neighbours, and the queue exists to be sold.
- **Depends on / conflict / source:** nothing. Conflicts with D4 and with "no timers as gates". [HS:prod-bldg][TW:Factories]

**A3. Finished output held on the machine as storage** (Hay Day, Township)
- **What it is / what it solves:**
  - Hay Day finished products wait on the machine's "desk"; up to 52 can stack while the barn is full [HW:ProdBldg].
  - Township factory shelves (up to 8) are used as storage [TW:Barn].
  - It gives storage relief without upgrading the barn.
- **Core loop / related:** buffering. Related: B8 and A6.
- **Challenges:** showing how full a buffer is on a small isometric tile.
- **Fit: ADAPT.** Show each machine's output buffer as a small fill pip. A machine whose neighbour cannot take its output should say "holding N" rather than just "blocked".
- **Depends on / conflict / source:** the machine buffer model and the warning key. No conflict. [HW:ProdBldg][TW:Barn]

**A4. Long-press to see ingredients; production waits until every input is present** (Hay Day, Township)
- **What it is / what it solves:**
  - In Hay Day, press and hold a product to see its ingredient counts [HS:product].
  - In Township, "Production starts only if all required ingredients are available" [PX:factories], and tapping a product image shows its components [TW:Goods].
  - It makes the chain readable without a wiki.
- **Core loop / related:** readable chains. Related: A5 and K3.
- **Challenges:** touch and long-press conflicts with camera panning.
- **Fit: ADOPT.** Long-press any machine or material to open a small card: inputs, output, ideal heat, and which of its neighbours currently feed it.
- **Depends on / conflict / source:** the Codex data. No conflict. [HS:product][PX:factories][TW:Goods]

**A5. A jump to the factory that makes something, and back again** (Township, Dec 2025)
- **What it is / what it solves:** "Tap the magnifying glass to go to the factory you need, and you'll automatically return to your orders when you close the window" [TW:Upd2025]. It removes hunting around a big map.
- **Core loop / related:** closes the loop from goal to producer. Related: C1, B6, G6 and L2.
- **Challenges:** a camera tween plus a "back" chip. If no producer exists yet, point to where one could go.
- **Fit: ADOPT.** Every material name in a Core row, a contract or the store becomes a link. The camera flies to the machine that produces it, and a "← Contracts" or "← Core" chip returns to the panel. With no producer, ghost-highlight a valid spot next to its input.
- **Depends on / conflict / source:** "What now?" already has taps [LW:PROG §7]. No conflict. [TW:Upd2025]

**A6. Helpers that keep a stock quota** (Hay Day Rose & Ernest)
- **What it is / what it solves:**
  - Rose makes feed and collects animal goods; Ernest runs the Dairy and Sugar Mill.
  - Each keeps producing "until [he] has either met your quota or run out" of inputs, and each has its own storage [HS:helpers].
  - It automates the chores.
- **Core loop / related:** automation with targets. Related: B8, F4 and C7.
- **Challenges:** quota rules must not hide why the Vault stopped selling.
- **Fit: ADAPT.** Lodeworks is already automated; take only the quota idea. Each material in the Core store gets a "keep N" reserve. The Vault sells only what is above the reserve, and the Foreman shows "reserve met / short by N".
- **Depends on / conflict / source:** Vault selling logic and the Core store. No conflict: the hired and rented part is dropped (R8). [HS:helpers]

**A7. Exclusive inputs from outlying areas** (Township islands; Hay Day lake and mine)
- **What it is / what it solves:**
  - Township: five islands, each with three exclusive goods. Sending ingots with a ship raises the chance of the rarer goods [TW:Ships][PX:farming].
  - Hay Day: the lake and the mine supply inputs used elsewhere [HW:Fishing][HW:Mine].
  - It gives the map's periphery a purpose.
- **Core loop / related:** reasons to expand outward. Related: D1, D4 and P1.
- **Challenges:** balancing a new input without creating a new currency.
- **Fit: ADAPT (strong).** Give the unused world nodes a function, keeping it **deterministic** (D5):
  - a heat vent heats adjacent machines;
  - an ore seam enriches an adjacent Drill;
  - a crystal field feeds an adjacent Lab or Amplifier.
  This answers the pending "resource node function" decision [memory: P4 candidate].
- **Depends on / conflict / source:** the ring or plot expansion (D1) and the heat model. Conflict only if nodes add new currencies (D1). [TW:Ships][PX:farming]

**A8. A production chain whose product is the upgrade currency** (Township: Mine → Foundry → ingots → Academy)
- **What it is / what it solves:** 5 ore make 1 ingot; there are at most 3 Foundries; ingots pay for factory, train and island upgrades [TW:Foundry][TW:Academy]. Upgrades are fed by play, not by purchase.
- **Core loop / related:** production pays for progression. Related: E2 and B2.
- **Challenges:** none new.
- **Fit: ADOPT (already aligned).** Lodeworks' Core store pays for machine and Core levels [LW:PROG]. Keep it so: every level should cost produced materials, not credits only.
- **Depends on / conflict / source:** the Core store. No conflict. [TW:Foundry][TW:Academy]

**A9. Unlimited warehouse for raw ore** (Township mine)
- **What it is / what it solves:** ore sits in the mine's warehouse, which "has unlimited storage"; once smelted, ingots go to the barn [TW:Mine]. The base resource never clogs storage.
- **Core loop / related:** storage. Related: B8.
- **Challenges:** it weakens the Vault gate if it is applied to everything.
- **Fit: LATER.** Consider only if playtests show raw Ore crowding the Core store. Exempting only Ore from the store cap is a cheap test.
- **Depends on / conflict / source:** core_journey data. No conflict. [TW:Mine]

**A10. Temporary seasonal machines** (Hay Day)
- **What it is / what it solves:** the Gift Wrapping Station, the Halloween Treats Maker and similar [HW:ProdBldg][HW:Update]. Novelty during live events.
- **Challenges:** content cadence.
- **Fit: REJECT.** Conflicts with an existing decision (D1, the content treadmill, and D2). [HW:ProdBldg]

**A11. A mine that uses up tools instantly for random ores** (Hay Day)
- **What it is:** no production time; dynamite, TNT, shovels or pickaxes yield ores, with a diamond chance capped at 10 per day [HW:Mine].
- **Fit: REJECT.** It needs a tool currency (D1) and random output (D5). Lodeworks' shaft already covers extraction.

### B. Storage and capacity

**B1. Separate storage buildings** (Hay Day Barn/Silo/Tackle Box) **versus one barn with tabs** (Township)
- **What it is / what it solves:** the Silo holds crops, the Barn holds everything else, and the Tackle Box holds lures [HS:storage]. Township has one barn with category tabs [TW:Barn].
- **Challenges:** separate stores double the UI on a small screen.
- **Fit: REJECT the split. ADOPT the tabs** (see L6).
- **Source:** [HS:storage][TW:Barn]

**B2. Capacity bought with dedicated parts; the part count rises by one per level** (Hay Day)
- **What it is / what it solves:**
  - Capacity starts at 50, rises by 25 per level up to 1,000, then by 50; the maximum is 25,000.
  - Each upgrade needs equal numbers of three part types (Bolt, Plank and Duct Tape for the Barn), and the count rises by 1 each level [HW:Barn][HS:storage].
  - Township uses hammers, nails and paint [PX:barn-full].
  - A legible, linear gate.
- **Core loop / related:** a medium-term goal. Related: B5, B6 and C6.
- **Challenges:** keeping the rule printable in one line.
- **Fit: ADAPT.** Keep Vault levels paid in produced materials. Make the rule one printed sentence ("Vault N+1 costs N×k of X"); do not add a part currency (D1).
- **Depends on / conflict / source:** Vault levels [LW:PROG]. No conflict. [HW:Barn][HS:storage][PX:barn-full]

**B3. Upgrade parts as random drops from ordinary actions** (Hay Day)
- **What it is:** supplies come from doing tasks "several times", from mystery boxes and from the wheel [HW:Supplies]. A full barn blocks the drop [HW:Barn].
- **Fit: REJECT.** Conflicts with an existing decision (D5, random rewards). If parts are ever used, pay them deterministically: at milestones and from contracts (C6, C10). [HW:Supplies]

**B4. Upgrade parts take up the storage they upgrade** (Hay Day)
- **What it is:** by level 39, about 11.7% of the barn is the parts for the next upgrade [HW:Barn].
- **Fit: REJECT.** An anti-pattern: it tightens the squeeze the player is trying to escape. Items used for upgrades should not count against the store. [HW:Barn]

**B5. Storage fill shown in the world art** (Hay Day)
- **What it is / what it solves:** the barn shows up to five crates, the fifth appearing at 79% or more; its look changes with capacity stage [HW:Barn]. Township's barn also changes with level [TW:Barn]. Fill is read without opening a menu.
- **Core loop / related:** at-a-glance state. Related: B6 and L7.
- **Challenges:** five fill sprites per Vault or Core level.
- **Fit: ADOPT.** The Vault and Core sprite shows 0–5 crates, one per 20% of store fill.
- **Depends on / conflict / source:** art. No conflict. [HW:Barn][TW:Barn]

**B6. "Ready" and "close to ready" upgrade indicators** (Township; Hay Day Dec 2025)
- **What it is / what it solves:**
  - Township: "An upgrade icon shows up when you get enough materials" [TW:Barn].
  - Hay Day, Dec 2025: "Barn & Silo upgrade indicators: clearer hints when you're ready (or close!) to upgrade" [HW:Update].
  - Players miss upgrades they can already afford.
- **Core loop / related:** pulls the player to the next goal. Related: G6 and L2.
- **Challenges:** choosing the threshold for "close".
- **Fit: ADOPT.** A badge on the Vault, Core and machines: full colour when affordable, faint when at least N% there.
- **Depends on / conflict / source:** "What now?". No conflict. [TW:Barn][HW:Update]

**B7. Temporary capacity boosts** (Township Spacious Barn +20% for 2 days and Town Pass +30%; Hay Day Early Bird capacity extension)
- **What it is:** timed extra capacity [TW:Barn][PX:town-pass][HS:pass].
- **Fit: REJECT.** It sells storage and is on a timer (D4, no timers).

**B8. Rewards and production keep flowing when storage is full; relief valves** (Hay Day, Township)
- **What it is / what it solves:**
  - Hay Day wheel prizes go into the barn "even if they are full" [HW:Wheel], and fishing with lures works with a full barn [HW:Fishing].
  - Township lets you sell straight from the barn at a fixed price [PX:barn-full] and suggests leaving crops in fields as storage [TW:Barn].
  - It keeps the "full" state from becoming a dead end.
- **Core loop / related:** keeps the idle loop alive. Related: A3, A6, F4 and C7.
- **Challenges:** defining the overflow order.
- **Fit: ADOPT.** Rule: a full store never stops the factory. Machines hold their buffers, the Vault sells the surplus above the reserve, and rewards (contract payouts, offline) are always credited.
- **Depends on / conflict / source:** Vault logic. No conflict. [HW:Wheel][HW:Fishing][PX:barn-full]

**B9. A full barn blocks actions** (Township, Hay Day)
- **What it is:**
  - Township: a full barn means "you cannot perform most of the in-game actions" [TW:Barn].
  - Hay Day: a full barn blocks supply drops [HW:Barn] and production output ("production queue is full") [HS:product].
- **Fit: REJECT.** An anti-pattern; see B8.

### C. Orders and demand (the main candidate for Lodeworks' short-term goals)

**C1. Order board** (Hay Day truck)
- **What it is / what it solves:**
  - The board holds up to 9 orders [HS:truck]. Unlocks at Farm level 4 per the official article; the wiki says 3 [HW:Truck].
  - Orders ask for 1 to several units of items the player can make.
  - Ready orders get a checkmark. An order is completed all at once and replaced immediately.
  - Rewards are coins and XP; special Smelter and Jeweler orders also give vouchers [HS:truck][HW:Truck].
  - Orders have no expiry timer; only a discarded order waits 6–30 minutes to be replaced [HS:truck].
  - It supplies a steady stream of small goals with no energy.
- **Core loop / related:** the short-term goal layer between Core rows. Related: C2–C11, L1 and A5.
- **Challenges:**
  - a generator that only picks makeable materials at quantities fitting the store;
  - saving and loading the board;
  - adding a scripted "contract-filling" bot to core_journey.
- **Fit: ADOPT.** A "Dispatch board" with N contracts ("Deliver 120 Plates"), filled from the Core store with one tap. It is replaced on completion, has no expiry and no energy, and the rewards are printed.
- **Depends on / conflict / source:** the Core store, credits and the "What now?" list. No conflict (no timer). [HS:truck][HW:Truck]

**C2. Orders only ask for what you can make, including unlocked machines not yet built** (Hay Day)
- **What it is / what it solves:**
  - Boat orders include "products from machines they have unlocked but not built yet" [HW:Boat].
  - Town visitors can request from a building "even if you haven't built it yet" [HS:town-visitors].
  - Orders are always fair and nudge the player toward the next machine.
- **Core loop / related:** a gentle push to expand. Related: K4 and G6.
- **Challenges:** tagging materials as reachable.
- **Fit: ADOPT.** Contracts draw from materials that are unlocked by the Core level and the stratum reached. One slot can name a material from an unlocked but unbuilt machine, and it links to its placement (A5).
- **Depends on / conflict / source:** Core-level unlock tables. No conflict. [HW:Boat][HS:town-visitors]

**C3. Each order trades coins against XP** (Hay Day, Township)
- **What it is / what it solves:**
  - Hay Day: "orders that offer a high coin compensation will not earn as many experience points" [HW:Truck].
  - Township: some helicopter orders pay less than selling in the barn [TW:Helicopter].
  - Choosing which orders to fill becomes a real choice.
- **Core loop / related:** decisions. Related: C6 and G1.
- **Challenges:** keeping two reward kinds legible.
- **Fit: ADAPT.** Each contract states its payout type: credits at a premium over the Vault, or progress (research points or a Core-row credit). This must not become a new currency (D1).
- **Depends on / conflict / source:** research points and Core rows. No conflict. [HW:Truck][TW:Helicopter]

**C4. Multi-crate shipments with a choice of difficulty** (Hay Day boat; Destinations since Aug 2026)
- **What it is / what it solves:**
  - A shipment is 3–5 item types split into crates [HW:Boat].
  - Since Aug 2026 the player chooses one of 3 destinations (easy, medium or hard) and can refresh the options [HS:boat][HS:aug26].
  - Nautical Miles earned per destination: 40, 65 or 100 [HW:Boat].
  - The dock stays for 18 hours, and the next boat arrives 4 hours after it leaves [HW:Boat].
  - Players pick their own challenge.
- **Core loop / related:** a medium-term goal of about an hour. Related: C5, Q2 and G8.
- **Challenges:** balancing the three tiers; making sure refresh cannot be abused.
- **Fit: ADAPT.** A "Big contract" slot with three offered tiers, each showing its crates and payout. **Drop the 18-hour window and the 4-hour arrival timer.** A new big contract appears when the previous one is shipped.
- **Depends on / conflict / source:** C1. Keep no timers. [HS:boat][HW:Boat][HS:aug26]

**C5. Rows or crates with partial rewards** (Township plane, Hay Day boat)
- **What it is / what it solves:**
  - Township plane: 2–3 crates per row (6–9 in total); each completed row pays; a fully loaded plane adds a chest [TW:Airport].
  - Hay Day: "You'll always receive the indicated rewards for orders you did complete" [HS:boat].
  - A big order is never all or nothing.
- **Core loop / related:** steady progress feedback. Related: C4 and Q2.
- **Fit: ADOPT.** Every crate in a big contract pays on delivery; finishing all of them adds a fixed completion bonus. No chest (D5).
- **Source:** [TW:Airport][HS:boat]

**C6. Orders that pay in gating materials** (Township train)
- **What it is / what it solves:** train cars get XP but no coins, and the train "brings back" construction materials, barn tools and expansion tools [TW:Train][PX:expansions]. The order stream is the faucet for gate items.
- **Core loop / related:** ties orders to long-term gates. Related: B2, D1 and C3.
- **Challenges:** Township's drop is random [PX:farming]; Lodeworks must be deterministic.
- **Fit: ADAPT.** Some contracts pay a Core-row credit or a Vault-level discount instead of credits, printed up front, never random.
- **Depends on / conflict / source:** Core rows. No conflict. [TW:Train][PX:expansions]

**C7. Visitors who buy a share of what you have too much of** (Hay Day farm visitors)
- **What it is / what it solves:**
  - A visitor asks for about a third to a half of an item you hold [HW:Visitors], and pays 1.7–2.2× the base price.
  - At most 2 at a time; they wait forever [HW:Visitors].
  - Daily cap of up to 10, and the first few each day give Barn and Silo parts [HS:visitors].
  - Excess stock gets a quick outlet, and old chains stay valuable.
- **Core loop / related:** an outlet for overproduction. Related: P3, B8 and A6.
- **Challenges:** tuning the premium so the Vault is not obsolete.
- **Fit: ADAPT.** A "Bulk buyer" appears when a material is well over its reserve. It offers to buy a share at a premium and waits indefinitely. No daily cap and no parts drop.
- **Depends on / conflict / source:** A6 reserves. Conflict only if capped daily (D2). [HW:Visitors][HS:visitors]

**C8. Orders that need several stops** (Hay Day town visitors)
- **What it is:** each visitor needs 1–3 service buildings and up to 4 products; dragging one delivers all [HS:town-visitors].
- **Fit: LATER.** Two-stage contracts ("first 50 Ingots, then 20 Components") once C1 works.
- **Source:** [HS:town-visitors]

**C9. Discarding an order has a cooldown** (Hay Day 6–30 min; Township 30 min or 4 T-cash)
- **What it is:** [HS:truck][TW:Helicopter]. It stops players rerolling for the best order.
- **Fit: ADAPT.** Discarding is free. The replacement arrives after N units of any production, a production-based cooldown, never wall-clock time.
- **Conflict:** a wall-clock cooldown would be a timer gate.

**C10. A reward track for order count** (Hay Day Truck Track and Voyage Track)
- **What it is / what it solves:**
  - Truck Track, from level 12: rewards unlock at order counts and it "resets daily" [HS:truck-track].
  - The wiki's June 2026 table lists silo expansion materials at order counts [HW:Truck].
  - Voyage Track: Nautical Miles, reset every 3 days [HS:boat].
  - The count itself becomes a goal.
- **Core loop / related:** a medium-term meta goal. Related: C1 and I1.
- **Challenges:** a permanent track needs a finite design or a repeating tail.
- **Fit: ADAPT.** A permanent "Dispatch ledger": every N contracts fills a mark that never expires. **Reject the resets:** they conflict with an existing decision (D2).
- **Source:** [HS:truck-track][HS:boat]

**C11. Preview of the next order** (Hay Day dock, Township plane)
- **What it is / what it solves:** tapping the empty dock shows the next boat's items and arrival time [HW:Boat]; the next plane's goods can be previewed [TW:Airport]. Players can produce ahead.
- **Fit: ADOPT.** The board shows the next contract, greyed out, so the player can pre-produce.
- **Source:** [HW:Boat][TW:Airport]

**C12. Named order-givers** (Hay Day, Township)
- **What it is / what it solves:** Hay Day truck orders come from 10 named places (Church, Ben's Brewery and others) [HW:Truck]; Township customers are tied to buildings [TW:Helicopter]. Orders get faces.
- **Challenges:** character art.
- **Fit: ADAPT (low cost).** 3–4 off-board buyers, one per material tier ("Rail Yard wants Plates"), shown by an icon. No affection meters.
- **Source:** [HW:Truck][TW:Helicopter]

**C13. Asking other players for help with orders** (Hay Day, Township)
- **What it is:** [HS:truck][HS:boat][TW:Airport].
- **Fit: REJECT.** Conflicts with an existing decision (D3).

**C14. A rewarded ad that doubles one order** (Hay Day "2x")
- **What it is:** "tap the 2x button to watch an ad and double the Coins and XP" [HS:truck].
- **Fit: LATER.** It fits the Lodeworks rule that the value is printed before the ask [LW:MONET]. Add it only after the offline-panel placement has real data.
- **Conflict:** none if optional.

**C15. Order bonus events** (Hay Day truck and boat bonus days; Township "Double Reward")
- **What it is:** [HW:Events][TW:Events].
- **Fit: REJECT.** Timed obligation; conflicts with an existing decision (D2).

### D. Land and area expansion

**D1. Plot-by-plot expansion, where only plots next to owned land can open** (Hay Day)
- **What it is / what it solves:**
  - Each plot needs the same number of land deeds, mallets and marker stakes.
  - "Once a section has been unlocked all adjacent ones become unlockable" [HW:Expansion/Farm].
  - Farm expansion starts at level 22 [HS:land].
  - Space grows gradually and the player chooses the direction.
- **Core loop / related:** spatial progression. Related: A7, D2, D3 and D4.
- **Challenges:** grid regions on the 44×44 board, plot costs, and interaction with heat spread across plot borders.
- **Fit: ADAPT.** Grow the yard plot by plot, choosing plots adjacent to the current yard, costing credits plus materials. The Core level caps the total yard area.
- **Depends on / conflict / source:** the existing ring growth [memory]. No conflict. [HW:Expansion/Farm][HS:land]

**D2. Special plots that need a rarer permit** (Hay Day)
- **What it is:** special areas need Expansion Permits and hold exclusive decorations. Once all special areas are open, permits stop dropping [HS:permit].
- **Fit: LATER.** Plots containing world nodes (A7) open only at a stated Core level or stratum, not with a permit item (D1).
- **Source:** [HS:permit]

**D3. Expansion gated by a capacity stat** (Township: coins + tools + population)
- **What it is:** from expansion 20 shovels are also needed, from 34 axes, from 50 saws [TW:Expansions]; population is also required [PX:how-to-play].
- **Fit: ADOPT (already aligned).** Plot costs join the Core's multi-condition gate [LW:PROG].
- **Source:** [TW:Expansions]

**D4. Clearing obstacles on the land** (Hay Day tools)
- **What it is / what it solves:** axes clear bushes, dynamite clears rocks, shovels clear ponds [HW:Supplies]. The map has texture and small tasks.
- **Challenges:** clearing time must not be a timer gate.
- **Fit: ADAPT.** Rubble tiles in new plots are cleared by *production*: a Drill or Crusher placed next to the tile works it off after N units. Machines are used, not tools; deterministic.
- **Depends on / conflict / source:** D1. No conflict. [HW:Supplies]

**D5. New expansions arrive only with game updates** (Township)
- **What it is:** "New expansions are only available when advised in an update" [TW:Expansions][PX:expansions].
- **Fit: REJECT.** Live content cadence.

**D6. New zones opened by a repair** (Hay Day Town, Fishing Lake and boat dock; Township Port)
- **What it is:** the Town opens at level 34 by repairing the train station [HW:Town]; the Port opens at level 29 [TW:Ships].
- **Fit: LATER.** The outer world ring as a "zone" opened by restoring a derelict structure with materials, used once as a big spectacle.
- **Source:** [HW:Town][TW:Ships]

### E. Upgrades of production buildings

**E1. Mastery earned by using a building** (Hay Day)
- **What it is / what it solves:**
  - Stars are earned by hours of use. Bakery example: 35, 140 and 560 hours.
  - The three stars give +10% coins, +10% XP and 15% faster production (the Feed Mill gets 5/10/15% faster) [HW:Masteries].
  - The building may turn gold, and an (i) button shows progress [HS:prod-bldg].
  - The Aug 2026 workbench screen is **UNVERIFIED** [HW:Update].
  - Rewards long use of old machines.
- **Core loop / related:** long-term, keeps old machines valuable. Related: P3, I2 and L7.
- **Challenges:** tracking per machine type across collapse; avoiding just more numbers.
- **Fit: LATER, then ADAPT.** Mastery per machine type, counted in units processed and kept through collapse. Stars show in the Codex, and the machine gets a gold trim. The perks are small and deterministic, and at most one of them is economic.
- **Depends on / conflict / source:** the Codex and collapse rules (pending). Low risk against D1. [HW:Masteries][HS:prod-bldg]

**E2. Choosing an attribute at each upgrade** (Township Academy of Industry)
- **What it is / what it solves:**
  - Upgrades are bought with ingots. Since Dec 2015 "each level offers some attributes of which you choose one".
  - Attributes: time (5% per step, down to −50%), coins, XP; shelves at level 5 (+1) and level 10 (+2).
  - Factories go to level 53 [TW:Academy].
  - Hay Day service buildings have four upgrade categories capped by Reputation [HS:service-upg].
  - Upgrades become decisions.
- **Core loop / related:** build variety. Related: E1 and A3.
- **Challenges:** balancing choices whose effects multiply; showing the choice later.
- **Fit: ADAPT (LATER).** At milestone machine levels, offer one of two deterministic specialisations (throughput or heat tolerance). They can be changed on collapse.
- **Depends on / conflict / source:** machine levels. D1 risk if it multiplies; keep it to 2–3 milestones. [TW:Academy][HS:service-upg]

**E3. A second axis past the level cap, with 5 visible sub-levels** (State of Survival Plasma)
- **What it is:** after HQ 30, Plasma Cores buy plasma levels, each with 5 sub-levels that also give effects [SW:HQ][SW:PlasmaCores][SW:InstPlasma]. An endgame beyond the cap.
- **Fit: LATER.** Maps to AUDIT C1 ("something after the permanent tree"). Only with measured evidence that players reach the end.
- **Source:** [SW:HQ]

**E4. Paid production slots, Farm Pass extra slots, free-upgrade coupons** (Hay Day, Township)
- **What it is:** [HS:prod-bldg][HS:perks][TW:Coupons].
- **Fit: REJECT.** Conflicts with an existing decision (D4 and D1).

### F. Economy, currencies and sinks

**F1. Player-to-player shop and newspaper** (Hay Day Roadside Shop and Daily Dirt)
- **What it is:** [HS:roadside][HW:DailyDirt].
- **Fit: REJECT.** Conflicts with an existing decision (D3).

**F2. A price dial that trades speed of sale for price** (Hay Day roadside prices from 1 coin up to 3.6× default)
- **What it is:** [HW:Roadside]. The wiki strategy note says "Everything sells at maximum price eventually" (fan observation).
- **Fit: LATER.** A Vault "sell fast / sell high" toggle is a small decision without a new currency. Only if the Vault feels passive.
- **Source:** [HW:Roadside]

**F3. Random-stock NPC markets and hired fetchers** (Township City Market refreshing every 6 hours; the dealer Raja; Hay Day Tom and Greg's shop)
- **What it is:** [TW:Market][HS:tom][HS:greg].
- **Fit: REJECT.** Timer refresh, rental and premium currency.

**F4. Exchange surplus for scarce items at a fixed ratio** (Township Tool Exchange)
- **What it is / what it solves:** from level 60, 4–6 construction materials make 1 special tool, and the exchange is the only source [TW:ToolExchange][PX:expansions]. Converts overflow into progress.
- **Core loop / related:** a sink for surplus. Related: B8, A6 and C7.
- **Challenges:** a ratio that is neither exploit nor useless.
- **Fit: ADAPT.** An "Exchange" row on the Core card: turn surplus low-tier stock into credit toward a Core row at a printed ratio. Deterministic, no new item.
- **Depends on / conflict / source:** Core rows. No conflict. [TW:ToolExchange]

**F5. Many currencies** (Hay Day six or more; Township eight or more; State of Survival)
- **What it is:** [HW:Currencies][TW:Township][SW:Resources].
- **Fit: REJECT.** Conflicts with an existing decision (D1).

**F6. Buy a missing basic input for soft currency at a level-scaled price** (Hay Day, Mar 2026)
- **What it is:** "buy crops, axes, and saws with coins, with prices scaling with your Farm Level" [HW:Update].
- **Fit: LATER.** An emergency "buy 10 Gravel at a premium" might remove dead ends, but it risks trivialising chains.
- **Source:** [HW:Update]

**F7. Premium currency that earns interest** (State of Survival biocap incubator)
- **What it is:** [SW:ResearchLab][SW:Biocaps].
- **Fit: REJECT** (D4).

### G. Progression and levels

**G1. A level bar with rewards part-way through** (Hay Day level thresholds)
- **What it is / what it solves:** from level 15, the XP bar has 1–5 intermediate thresholds that pay supplies, diamonds or vouchers [HW:Experience][HW:Thresholds]. Long levels feel shorter.
- **Core loop / related:** fills the gaps between Core levels. Related: C3 and G2.
- **Fit: ADAPT.** Each Core row pays a small fixed reward (credits or research) when it turns green.
- **Depends on / conflict / source:** Core rows. No conflict. [HW:Thresholds]

**G2. One building that caps all the others** (State of Survival HQ; Township population)
- **What it is:** "no other construction can be higher than your headquarters" [BS:sos]; population gates factories and fields [TW:Houses].
- **Fit: ADOPT (already the Core)** [LW:PROG].

**G3. Showing the cap against the current value** (Township "pending additional population")
- **What it is / what it solves:** the game shows current population, the cap, and the difference [TW:Houses]. Players see headroom.
- **Fit: ADOPT.** The store reads "540 / 819 (Vault 3 → 2,621 at Vault 4)".
- **Source:** [TW:Houses]

**G4. A separate level per area** (Hay Day Town Reputation)
- **What it is:** Reputation "only affects your Town" [HS:town].
- **Fit: LATER.** A separate depth track only if the Core bar gets crowded.

**G5. Tasks that speed up research** (State of Survival Research Tasks)
- **What it is:** completing a task cuts the target research's timer. The tasks reset every 24 hours per the Research Task page, or every 2 days per the Missions page; the sources disagree [SW:ResearchTask][SW:Missions].
- **Fit: ADAPT.** Lodeworks Labs make research continuously. Add non-resetting "Field notes": fixed production feats that grant research points once.
- **Conflict:** the resets conflict with an existing decision (D2).

**G6. Growth missions with a "Go" button** (State of Survival)
- **What it is / what it solves:** a "Go" button "will guide you to the location/building" [SW:ResearchTask]. Growth and Side Missions exist [SW:Missions]. The player never wonders what to do.
- **Fit: ADOPT (already "What now?").** Add era titles to group rows by Core level, for example "Era 2: Processing".
- **Source:** [SW:ResearchTask][SW:Missions]

**G7. Story chapters** (State of Survival Story Mode: 13 chapters in the Joker story)
- **What it is:** [SW:Story].
- **Fit: LATER.** Short Codex chapters unlocked by Core levels and strata. No branching.

**G8. Completing opportunities raises the tier of future ones** (State of Survival Intel radar)
- **What it is / what it solves:** intel quality runs from Normal to Legendary and rises as more intel is completed [SW:Intel]. Orders scale with skill.
- **Fit: ADAPT.** A Dispatch "grade": every N contracts completed raises the size and payout tier of contracts. It is visible and never drops.
- **Depends on / conflict / source:** C1. No conflict. [SW:Intel]

**G9. Challenge trails** (State of Survival Explorer Trail: 12 trails × 12 challenges)
- **What it is:** [SW:Explorer].
- **Fit: LATER.** This is AUDIT C2 (challenge runs) [LW:AUDIT].

### H. Events and live-ops

**H1. Daily bonus and boost events** (Hay Day event board, from level 9, usually 24 hours)
- **What it is:** [HS:events][HW:Events].
- **Fit: REJECT.** Conflicts with an existing decision (D2). Stratum modifiers already provide variety.

**H2. Global community goals** (Hay Day)
- **What it is:** [HS:global].
- **Fit: REJECT** (D3, needs a server).

**H3. The County Fair's daily streak, with stamps bought in diamonds to keep it** (Hay Day)
- **What it is:** [HS:events].
- **Fit: REJECT.** Conflicts with an existing decision (D2, streaks).

**H4. Task events and pass seasons** (Hay Day Task Events and Farm Pass; Township Town Pass and Seasonal Adventures)
- **What it is:** [HS:task-events][HS:pass][PX:town-pass][TW:Events].
- **Fit: REJECT** (D2 and D4).

**H5. Temporary event stats checked against the environment** (State of Survival Frontier Outpost: Cold Resistance, mining output; bonuses removed at the end)
- **What it is:** [SW:Frontier].
- **Fit: ADAPT the display only, not the event.** A "stratum readiness" meter compares your heat tolerance and cooling with the next stratum's temperature and modifiers, before descending.
- **Related:** the strata system and Core rows.

**H6. A roguelite descent that offers 1 of 3 perks** (State of Survival Underground Shadow Exploration)
- **What it is:** 101 floors; filling the research bar offers 3 random choices [SW:Underground].
- **Fit: LATER.** A seeded challenge descent (AUDIT C2) whose choices are deterministic from the seed (D5).

**H7. Seasonal creatures to find** (Hay Day)
- **What it is:** they appear while harvesting or fishing and are added as stickers [HS:creatures].
- **Fit: REJECT as a random spawn** (D5). The deterministic version is I3.

### I. Collections and achievements

**I1. Tiered achievements that grow a landmark** (Hay Day: 50 achievements × 3 tiers, and the farmhouse changes; Township: the Town Hall grows every 5–10 achievements)
- **What it is / what it solves:** [HS:achv][HW:Achievements][TW:TownHall]. Pride without other players.
- **Fit: ADOPT.** The Ledger (marks never expire) [LW:GAP] plus a building that visibly grows with Ledger marks.
- **Related:** L5 and C10.

**I2. A collection book with medal tiers** (Hay Day Fishing Book)
- **What it is / what it solves:** 43 species with Bronze, Silver, Gold and Platinum weight medals worth 1–4 diamonds, plus lure hints [HS:fishbook]. Gives a reason to revisit.
- **Fit: ADAPT.** "Stratum records" (= AUDIT C3): the best credits per minute per stratum, with medal tiers and a hint of which modifier limits it. Personal bests replace leaderboards.
- **Depends on:** collapse persistence.

**I3. Finds gated by depth** (Township museum)
- **What it is / what it solves:** "New artifacts are available to be discovered after reaching certain depths within the mine"; 1, 2 or 3 of each artifact pays T-cash [TW:Museum][TW:Mine]. Depth becomes collectible.
- **Fit: ADAPT.** "Core samples": each stratum has a fixed specimen, earned the first time a stated condition is met there (for example, a Drill at ideal heat). Codex shelf, cosmetic payout, deterministic (D5).
- **Related:** strata, the Codex and I1.

**I4. Tapping an empty slot tells you how to get it** (Hay Day Decoration Collection)
- **What it is:** [HS:deco-coll].
- **Fit: ADOPT** for every Codex and Ledger slot, with a "Go" link (A5).

**I5. Style sets and a book of every part ever owned** (Hay Day Maggie)
- **What it is:** 3 objects × 3 parts; a full set pays diamonds; any past part can be rebuilt at 75% off [HS:style][HS:maggie].
- **Fit: ADAPT.** Cosmetic Core, Vault and Foreman skins, kept forever and swapped for free.
- **Related:** O1 and R10.

**I6. Puzzle-piece animals** (Hay Day Sanctuary: 36 pieces per animal, 56 animals)
- **What it is:** [HS:sanctuary].
- **Fit: REJECT** (random drops, D5).

**I7. Card collections** (Township: 15 sets × 10 cards, rarity from 1 to 5 stars, packs, online only; plus Zoo cards)
- **What it is:** [TW:Collection][PX:collection][TW:Zoo].
- **Fit: REJECT** (gacha, D3).

**I8. Hidden achievements, a badge wall and titles** (State of Survival)
- **What it is:** [SW:Achievements].
- **Fit: ADAPT.** A few hidden Ledger marks for clever builds, shown as "???" until earned.

**I9. Cosmetics that grant stats** (State of Survival HQ skins and collection sets)
- **What it is:** [SW:HQ].
- **Fit: REJECT.** Paying for stats is pay-to-win (D4).

### J. Social (brief; each with its single-player analogue)

**J1. Neighbourhood, Team and Alliance requests and chat** (Hay Day, Township, State of Survival)
- **What it is:** [HS:nbh-req][PX:teams][SW:Convoy].
- **Fit: REJECT** (D3).

**J2. Weekly group competitions** (Hay Day Derby; Township Regatta)
- **What it is:** [HS:derby][TW:Regatta].
- **Fit: REJECT** (D3).
- **Analogue:** stratum records (I2). Seeded challenge rocks from a library that never expires, rather than a weekly clock (the D2 caution applies).

**J3. Leaderboards** (Hay Day boat, Township plane points)
- **What it is:** [HW:Boat][TW:Airport].
- **Fit: REJECT** (D3). **Analogue:** I2.

**J4. Visiting a showcase farm** (Hay Day: Greg's farm "exhibits all Production Machines, Decorations, and Habitats")
- **What it is / what it solves:** [HS:greg]. Shows what is possible.
- **Fit: ADAPT.** A read-only "Showcase yard" in the Codex: a model late-game board to pan around. Factory Tours by share code later [LW:GAP].

**J5. Help letters and gift cards** (Hay Day Alfred)
- **What it is:** [HS:postman].
- **Fit: REJECT** (D3).

**J6. A shared world map with about 60 players** (Hay Day Valley)
- **What it is:** [HS:valley].
- **Fit: REJECT** (D3, plus fuel is an energy system).

### K. Units, characters and exploration

**K1. Characters as the faces of systems** (Hay Day Tom, Greg, Maggie, Alfred, Rose, Ernest, Mr. Wicker; Township Ernie and Raja)
- **What it is / what it solves:** each system has a person who introduces it [HW:Town][HS:greg][TW:Market]. Warmth and teaching.
- **Fit: ADAPT.** Keep the Foreman as the one teacher; the contract buyers (C12) are the only other faces. No rentals.

**K2. Heroes that specialise in a resource, and hero appointment slots** (State of Survival)
- **What it is:** Mike boosts food, Rusty metal, Ghost gas, Chef wood [SW:Basics]; Hero Appointment gives a bonus when all three slots are filled [SW:Appointment].
- **Fit: REJECT** heroes: gacha fragments, D1 and D4.
- **Analogue (LATER):** the Foreman can "stand at" one machine cluster for a small visible bonus, movable at any time. This is also the closest thing to the (UNVERIFIED) worker assignment.

**K3. Exploration maps that use stamina or energy** (State of Survival intel and Explorer Trail; Township Expeditions; Township Match-3 lives)
- **What it is:** [SW:Stamina][SW:Explorer][TW:Expedition][TW:Match3].
- **Fit: REJECT** (energy systems).

### L. Onboarding and guidance

**L1. Teaching a system by repairing it** (Hay Day)
- **What it is / what it solves:** the Barn and Silo "must be repaired during the tutorial" [HW:Barn]; the dock and train station are also repaired [HW:Boat][HW:Town]. One verb introduces one system.
- **Fit: ADAPT.** The first Vault starts derelict and is restored with the first Ingots, which teaches the store and the Vault in one action.

**L2. A guide at first contact** (Hay Day Mr. Wicker; Greg introduces seasonal creatures)
- **What it is:** [HW:Town][HS:creatures].
- **Fit: ADOPT.** The Foreman speaks once when each system is first touched (the GAP-AUDIT "teach at first contact" line).

**L3. Locked items say why** (Hay Day greyed shop items, hold to see criteria; Township factories tab shows the condition)
- **What it is:** [HS:shop][PX:factories].
- **Fit: ADOPT.** Every locked machine or research shows its unmet condition and a Go link.

**L4. Preview of the next level's unlocks** (Hay Day: tap the level star)
- **What it is:** [HW:Experience].
- **Fit: ADOPT.** The Core card shows "what Core N+1 unlocks" beside the rows.

**L5. A front-loaded early game** (Hay Day Mar 2026: cheaper and faster production buildings, more truck orders, more fields early)
- **What it is:** [HW:Update].
- **Fit: ADOPT as a tuning note.** Offer more and easier contracts before Core 2.

### M. UI/HUD and information design

**M1. A checkmark on orders that can be filled now** — [HS:truck]. **Fit: ADOPT** (for C1).

**M2. Direction indicators to the nearest thing needing attention** (Hay Day, Aug 2026 help-request indicators)
- **What it is:** [HS:aug26].
- **Fit: ADOPT.** Screen-edge arrows toward off-screen machines in trouble or ready to upgrade on the 44×44 board.

**M3. Scenic mode, which hides the HUD** — [HS:scenic]. **Fit: ADOPT.** Cheap, and good for store screenshots.

**M4. A confirmation step before spending** (Hay Day diamond double-tap; Township cash confirmation toggle)
- **What it is:** [HS:diamonds][TW:Settings].
- **Fit: ADAPT.** Confirm only irreversible actions: collapse and a bulk sell.

**M5. Stats and highlights** (Hay Day June 2025 "view your farming stats and fun milestones"; Township Town Hall shows goods produced and mine depth reached)
- **What it is:** [HW:Update][TW:TownHall].
- **Fit: ADOPT.** A "Factory record" page with lifetime totals, the deepest stratum and collapses.

**M6. Storage tabs and search** (Township barn tabs; Hay Day shop search)
- **What it is:** [TW:Barn][HS:shop].
- **Fit: ADOPT.** Store tabs by tier; search in the Codex.

**M7. Landmarks change look with level** (Hay Day barn stages; State of Survival HQ plasma appearance)
- **What it is:** [HW:Barn][SW:HQ].
- **Fit: ADOPT.** Partly present already: the Core's size shows its level [LW:PROG].

**M8. The bonus part of a payout shown in its own colour** (Hay Day pink doubled coins; Township pink bonus coins)
- **What it is:** [HW:Truck][TW:Helicopter].
- **Fit: ADOPT** for contract premiums and ad doubling.

**M9. Input never waits on reward animations** (Hay Day Aug 2026: queue truck orders without waiting; Dec 2025: tap through help popups)
- **What it is:** [HW:Update].
- **Fit: ADOPT.**

### N. Notifications

**N1. Notifications toggled per topic** (Township; State of Survival)
- **What it is:** [TW:Settings][SW:Basics].
- **Fit: ADAPT.** Opt-in, off by default, factual state only ("Research finished", "Store full"). Never "we miss you".
- **Challenges:** Android local notifications from Godot.

**N2. Rewards for returning after a long absence** (Hay Day after more than 31 days; State of Survival Recall after about 61 days; Township red blimp)
- **What it is:**
  - Hay Day, once per 365 days: a free Barn and Silo upgrade, and all animals fed [HS:return].
  - State of Survival Recall [SW:Recall].
  - Township's red blimp pays for 5 consecutive days [TW:Balloons].
- **Fit: ADAPT.** A long-absence recap card from the Foreman ("while you were gone") on top of the offline panel. **Reject the consecutive-days blimp:** a streak (D2).

### O. Quality of life

**O1. Cancel a queued item and get the ingredients back** (Hay Day Dec 2025, paid in diamonds or an ad)
- **What it is:** [HS:product].
- **Fit: ADAPT.** A free "undo last placement or level" with a full refund. Never behind an ad.

**O2. An edit mode with saved layouts** (Hay Day)
- **What it is / what it solves:**
  - Starts with 2 layout slots; layouts can be saved incomplete.
  - Paint to place many, store all items of a type, an eraser swipe, undo.
  - A layout can be activated only when every item is placed [HS:edit].
  - Dec 2025: rotate items "even if they don't fit yet" [HW:Update].
  - Re-layouts and planning.
- **Challenges:** a ghost layer, validation, and moving machines while heat is live.
- **Fit: ADAPT.** This is the pending **Blueprint** decision (P7): saved ghost layouts that fill in as you afford each machine.
- **Depends on:** the collapse decision.

### P. Customisation and decoration

**P1. Customising landmarks part by part** (Hay Day Maggie: 3 objects × 3 parts, rotating weekly offers)
- **What it is:** [HS:maggie][HS:style].
- **Fit: ADAPT, without rotation.** A good candidate for one of the two one-time purchases: a cosmetics pack that changes no number.

**P2. Decorations; decorations attract ambient animals** (Hay Day)
- **What it is:** [HS:pets].
- **Fit: LATER.** Ambient life near world nodes, for example steam birds at vents.

### Q. Endgame, and old stuff staying valuable

**Q1. A new raw material adds recipes to old machines** (Hay Day Chamomile, Dec 2024)
- **What it is / what it solves:** Chamomile brought new products to the Essential Oils Lab, the Sewing Machine and the Tea Stand, plus the Perfumerie [HW:Update]. Old machines stay relevant.
- **Fit: ADOPT (principle).** When a stratum introduces something new, give an existing machine a new mode rather than adding a machine. This is the anti-D1 way to add depth.

**Q2. The first factories get high-level recipes that use early goods** (Township)
- **What it is:** Bakery Pizza at level 22 and Potato Bread at level 26 (4 eggs) [TW:Goods]; eggs appear in 16 or more recipes [TW:Farming].
- **Fit: ADOPT.** Late Core rows and late recipes consume early materials. PROGRESSION already asks for "the new material and the one before it" [LW:PROG]; extend it two tiers back.

**Q3. Demand keeps old goods valuable** (Hay Day)
- **What it is:** orders pull from every unlocked item [HW:Truck]; visitors buy bulk wheat [HW:Visitors]; the Wheat Bundle uses 75 wheat [HS:sanctuary].
- **Fit: ADOPT.** Weight contracts (C1) and bulk buyers (C7) toward early materials at large volumes.

**Q4. Uncapped levels and storage** (Hay Day: storage to 25,000; XP formula past level 500)
- **What it is:** [HW:Barn][HW:Experience].
- **Fit: REJECT for now** (AUDIT C1: only if measured).

### R. Anti-frustration

**R1. Nothing dies from neglect** (official Hay Day line: "crops never die")
- **What it is:** [SC:hayday]. The counterexample: trees wilt after the 3rd harvest and need another player to revive them [HW:Trees].
- **Fit: ADOPT no-decay. REJECT wilting.**

**R2. Partial credit** — see C5. **ADOPT.**

**R3. Choice instead of chance** (Hay Day Choice Crate: pick 1 of 3, "No more random rewards!"; Surprise Boxes guarantee no duplicates)
- **What it is:** [HS:choice][HS:surprise].
- **Fit: ADOPT (principle).** Where a reward is granted, offer a visible choice (D5).

**R4. Never award an item with no use left** (Hay Day: permits stop dropping once all special areas are open)
- **What it is:** [HS:permit].
- **Fit: ADOPT.**

**R5. Contracts cannot fail** (Hay Day: a failed Derby task has no penalty)
- **What it is:** [HW:Derby].
- **Fit: ADOPT.** Contracts cannot fail; they only wait.

**R6. Energy, stamina and lives gates** (Township lives refill every 30 minutes up to 5; expeditions cap energy at 100; State of Survival stamina recovers 1 per 300 seconds; Hay Day Valley fuel)
- **What it is:** [TW:Match3][TW:Expedition][SW:Stamina][HS:valley].
- **Fit: REJECT** (vision: no energy).

### S. Monetisation (for the rejection analysis)

**S1. Premium time skips** (Hay Day diamonds; Township T-cash speeds up almost everything)
- **What it is:** [HW:ProdBldg][TW:SpeedUp].
- **Fit: REJECT** (D4; there are no timers to sell).

**S2. Season passes** (Hay Day Farm Pass is monthly, $4.99 per the wiki, plus Party and Festival passes; Township Town Pass)
- **What it is:** [HW:FarmPass][HS:pass][PX:town-pass].
- **Fit: REJECT** (D2 and D4).

**S3. Rewarded ads** (Hay Day)
- **What it is:**
  - Movie Tickets, up to 4 per day.
  - An ad halves the production wait.
  - An ad doubles one order (2x).
  - An ad cancels a queued item.
  - A free Diamond Shop reward plus one more for an ad.
  - A purchase in the last 90 days removes the ad but keeps the reward [HS:daily][HS:ads][HS:truck][HS:product].
- **Fit: ADAPT only the placements that print the value first** (C14).
- **REJECT:** time-skip ads (no timers), daily ticket caps (D2), and ads to undo mistakes (O1 should be free).
- **Owner decision:** "payers get the ad reward without the ad" would change an economy number for buyers. It conflicts with "purchases never change an economy number" unless the removal of ads also removes the bonus.

**S4. Ad frequency tied to spending** (Township fan observation: 3–5 per hour for non-payers, fewer after a purchase; "not the same for everybody")
- **What it is:** [TW:Helicopter].
- **Fit: REJECT.**

**S5. Personalised offers for the exact missing upgrade parts** (Hay Day Upgrade Offers)
- **What it is:** [HS:offers].
- **Fit: REJECT.** A dark pattern at the gate (D4).

**S6. Starter packs, chain offers, the daily deal, special offers** (Hay Day)
- **What it is:** [HS:offers].
- **Fit: REJECT** (D4).

**S7. Loot boxes with published odds** (Hay Day Surprise Boxes; Township card packs and House of Luck, where you pick 1 of 9 chests)
- **What it is:** [HS:surprise][TW:Collection][TW:HouseOfLuck].
- **Fit: REJECT** (gacha).

**S8. Rented helpers** (Tom: 15, 60 or 100 diamonds; Rose and Ernest; Raja: 300 T-cash per day)
- **What it is:** [HS:tom][HS:helpers][TW:Market].
- **Fit: REJECT.**

**S9. Paid slots and space** (production slots, market boxes up to 30 T-cash, roadside boxes)
- **What it is:** [HS:prod-bldg][TW:Market][HS:roadside].
- **Fit: REJECT.**

**S10. Cosmetic purchases** (Hay Day Maggie parts for coins, diamonds or vouchers)
- **What it is:** [HS:maggie].
- **Fit: ADAPT** as the one-time cosmetics purchase (P1).

**S11. VIP levels, subscription "daily drop", event one-time machines** (State of Survival: the Oxygen Machine produces event stamina)
- **What it is:** [SW:Stamina][SW:Underground].
- **Fit: REJECT** (D4 and subscription).

---

## 3. Features that work together, and how they would fit into Lodeworks

1. **Dispatch loop** (the short-term goal layer)
   - Parts: C1 board, C2 makeable-only, C11 next preview, M1 checkmark, A5 jump-to-maker, C5 partial credit, C4 three-tier big contract, C3 payout type, G8 grade, C10 permanent Dispatch ledger.
   - How it plays: the player always has 3–5 small printed goals that pull from the Core store. Each "Deliver X" links to the machine that makes it. Big contracts give a choice of effort. Grade and ledger turn the stream into long progress, with no timer anywhere.
   - Prerequisite: add a contract-filling bot to `core_journey`, because numbers only become trustworthy once played [memory].

2. **Storage as a gate you can read, which never blocks**
   - Parts: B5 fill crates, B6 ready and close badges, G3 cap versus current, B8 never-blocking overflow, A6 reserves, C7 bulk buyer, F4 Exchange.
   - How it plays: the Vault level stays the gate, but "full" becomes information and a choice (sell, exchange, fill a contract), never a dead end.

3. **Old stuff stays valuable**
   - Parts: Q1 new modes for old machines, Q2 late recipes using early materials, Q3 contracts weighted toward early goods, C7 bulk buyers, E1 mastery (later).
   - How it plays: an Ore → Gravel line built in the first ten minutes still earns and still matters at Core 5.

4. **Yard and world expansion**
   - Parts: D1 plots adjacent to the yard, D4 rubble cleared by machines, A7 world nodes with deterministic functions, D2 node plots opened by Core level or stratum, D6 one derelict-structure spectacle.
   - How it plays: answers the pending resource-node question and gives the board a spatial long game that reuses adjacency and heat.

5. **Collections without gacha**
   - Parts: I1 Ledger plus a growing building, I2 stratum records with medals, I3 Core samples, I4 tap an empty slot to see how, I8 hidden marks, M5 factory record, J4 showcase yard.
   - How it plays: pride and completion from deterministic feats that never expire.

6. **Guidance that points at things**
   - Parts: "What now?", G6 era titles, L3 locked items say why, L4 next-level preview, M2 edge arrows, L2 Foreman at first contact, A4 long-press cards.

7. **A respectful return**
   - Parts: the offline panel, N2 long-absence recap, N1 opt-in factual notifications, R1 no decay, and C14/S3 ads only where the value is printed first.

---

## 4. Top 15 for Lodeworks, ranked by value for effort

1. **Dispatch board (C1 + C2 + M1).** The biggest missing layer: a steady, timer-free stream of small goals that uses the existing Core store and credits.
2. **Jump to the maker, and back (A5).** Low effort, and it makes every material name in the UI actionable on a 44×44 board.
3. **Long-press input/output cards (A4).** The cheapest fix for chain readability on a small screen.
4. **Ready and close-to-upgrade badges plus Vault fill crates (B6 + B5).** A few sprites and a threshold, and players stop missing affordable upgrades.
5. **Edge arrows to off-screen trouble (M2).** Cheap, and it solves "where is the starved machine?" on a big board.
6. **Never-blocking overflow plus reserves (B8 + A6).** Turns the full-store dead end the reference games suffer from (B9) into a choice.
7. **Partial credit and three-tier big contracts (C5 + C4).** Medium effort once C1 exists; it gives optional depth without timers.
8. **Contracts that pay progress, not only credits (C3 + C6).** Links short goals to Core rows so contracts are never busywork.
9. **Bulk buyer for overstock (C7).** Small once C1 exists, and it keeps early lines valuable.
10. **New modes for old machines when a stratum brings something new (Q1 + Q2).** The anti-D1 way to add depth; content work, not systems work.
11. **World-node functions plus plot expansion plus rubble cleared by machines (A7 + D1 + D4).** High value and high effort; it resolves a pending owner decision.
12. **Factory record page plus a building that grows with the Ledger (M5 + I1).** Low effort, lasting pride, no server.
13. **Stratum records with medals (I2 = AUDIT C3).** Medium effort; a deterministic reason to re-descend.
14. **Choice instead of chance for every reward (R3).** A rule, not a feature; it keeps D5 intact everywhere.
15. **Blueprint layouts from the edit-mode model (O2).** High value, high effort; blocked on the collapse and blueprint decisions.

---

## 5. REJECT list

**Conflicts with an existing decision (LW:AUDIT §2)**
- **D2, daily or weekly chores and streaks:** H1 daily events, H3 County Fair streak, H4 task events and passes, C10 track resets (daily, or every 3 days), C15 order bonus days, G5 research-task resets, S2 season passes, N2 the consecutive-day blimp, Hay Day's Wheel of Fortune and Valley daily quests [HW:Wheel][HS:valley].
- **D3, multiplayer, leaderboards and social:** J1 requests and chat, J2 Derby and Regatta, J3 leaderboards, J5 help letters, J6 the Valley, C13 help on orders, F1 the player shop and newspaper, H2 global events, I7 card trading.
- **D1, more currencies and content treadmill:** F5 currency sprawl, A10 seasonal machines, D5 update-shipped expansions, E4 coupons, A11 tool-consuming mine, Q4 uncapped treadmill (until measured), and heroes (K2).
- **D4, premium currency, packs and subscriptions:** S1 time skips, S5 personalised gate offers, S6 packs and deals, S8 rentals, S9 paid slots and space, S11 VIP and subscriptions, B7 paid or timed capacity, F7 premium interest, A2 paid queue slots.
- **D5, random hidden bonuses:** B3 random part drops, H7 random creature spawns, I6 puzzle pieces, S7 loot boxes and House of Luck.

**Conflicts with the vision (no energy, timers, gacha or guilt)**
- R6 energy, stamina and lives.
- C9 wall-clock discard cooldowns.
- The Hay Day boat's 18-hour window and 4-hour arrival timer (keep the idea, C4, and drop the timers).
- The NPC market refreshing every 6 hours (F3).
- S4 ad frequency tied to spending.

**Anti-patterns to avoid even without a formal rule**
- B4: upgrade parts that take up storage.
- B9: a full store that blocks actions.
- R1: things that wilt or decay.
- B1: several separate stores on a small screen.

---

## 6. Sources

Wiki pages were read as raw wikitext through `https://<wiki>.fandom.com/api.php?action=parse&page=<Page>&prop=wikitext&format=json`. The page URL for each is `https://<wiki>.fandom.com/wiki/<Page>`.

**Official Hay Day**
- SC:hayday = https://supercell.com/en/games/hayday/
- HS:* = https://support.supercell.com/hay-day/en/articles/<slug>.html. Slugs:
  - storage = silo-barn-tackle-box
  - prod-bldg = production-building
  - product = product-making-2
  - truck = truck-orders-2-2
  - truck-track = truck-track
  - boat = boat-orders-3
  - land = land-expansion
  - permit = expansion-permit
  - visitors = farm-visitors-2
  - town = town-basics-2
  - town-visitors = town-visitors
  - service-upg = upgrade-service-building
  - choice = choice-crate
  - surprise = surprise-boxes-3
  - pass = about-farm-pass-3 (with goals-and-rewards and farm-pass-road-3)
  - perks = perks
  - daily = daily-rewards
  - ads = in-game-advertisements
  - return = re-engagement-rewards
  - events = regular-events
  - global = global-events
  - aug26 = hd-whats-new-aug-26
  - deco-coll = decoration-collection
  - style = style-book-collection-book (with the-basics)
  - maggie = maggies-offer
  - achv = achievements
  - fishbook = fishing-book
  - tom = tom
  - helpers = farm-helpers-rose-ernest
  - greg = greg
  - creatures = seasonal-creatures
  - scenic = scenic-mode
  - edit = edit-mode
  - boosters = boosters-2
  - sanctuary = wildlife-sanctuary-6-2
  - pets = farm-animals
  - shop = the-shop
  - offers = starter-packs, chain-offers, upgrade-offers, special-offers, daily-deal
  - diamonds = coins-diamonds
  - task-events = task-events
  - postman = alfred-the-postman
  - valley = about-valley (with daily-quests)
  - derby = about-the-derby
  - nbh-req = neighborhood-requests
  - roadside = roadside-shop-2-2

**Hay Day wiki (hayday.fandom.com):** Barn; Silo; Supplies; Expansion; Expansion/Farm; Truck; Boat; Roadside Shop (HW:Roadside); Newspaper, which redirects to Daily Dirt (HW:DailyDirt); Town; Valley; Derby; Fishing; Mine; Production Buildings (HW:ProdBldg); Masteries; Visitors; Tom; Farm Pass; Experience; Level Thresholds (HW:Thresholds); Wheel of Fortune (HW:Wheel); Events; Currencies; Voucher; Crates; Update (the patch-note archive, v0.4 to v1.72, 10 Aug 2026); Crops; Trees and Bushes (HW:Trees); Achievements; Neighborhood; Daily Reward, which redirects to Movie Ticket; Booster.

**Official Township (Playrix Helpshift)** = https://playrix.helpshift.com/hc/en/3-township/faq/<id>/:
- PX:how-to-play = 15991
- PX:farming = 15993
- PX:events = 16027
- PX:barn-full = 130
- PX:expansions = 157
- PX:factories = 10055
- PX:town-pass = 14823
- PX:mayors-duties = 16612
- PX:mayors-weekend = 16613
- PX:collection = 16587, 16588, 16589
- PX:teams = 16614, 16615
- also read: 11802 (Mayor's Cup) and 16698 (Frozen Fortune)

**Township wiki (township.fandom.com):** Barn; Construction Materials; Factories; Academy of Industry (TW:Academy); Helicopter; Train; Airport; Zoo; Mine; Ships; Regatta; Houses; Community Buildings; Expansions; Town Collection (TW:Collection); City Market (TW:Market); Foundry; Central Museum (TW:Museum); Coupons; Speed Up; Fields; Town Hall; Match-3; Tool Exchange; 2025 Updates (TW:Upd2025); 2026 Updates; Laboratory (TW:Lab); Goods; Expedition; House of Luck; Gift Balloons (TW:Balloons); Settings; Events; Achievements; Farming and Chicken Coop (TW:Farming); Township.

**State of Survival wiki (stateofsurvival.fandom.com):**
- Headquarters (SW:HQ); Plasma Cores; Institute of Plasma; Research Lab; Missions; Missions: Research Task.
- Story Mode; Official Guide: Beginner Basics (SW:Basics); Official Guide: Settlement Buildings.
- Hero Appointment; Hero Precinct; Explorer Trail; Intel Post (SW:Intel); Stamina.
- Underground Shadow Exploration; Icy Isolation - Frontier Outpost (SW:Frontier); Recall Event (Survivors Recall); Supply Convoy (SW:Convoy); Achievements; Biocaps; Resources; Game Intro (SW:Intro).
- Note: many "Official Guide" pages are written by the community guide team, so treat them as wiki-grade.

**Press**
- PG:sos = https://www.pocketgamer.com/state-of-survival/tips-cheats/
- BS:sos = https://www.bluestacks.com/blog/game-guides/state-of-survival/sos-beginners-guide-en.html
- LWN:sos = https://www.levelwinner.com/state-of-survival-beginners-guide-tips-cheats-strategies-to-survive-the-zombie-apocalypse/

**Lodeworks** (read only, not modified): `D:\Claude Projeleri\lodeworks\`
- LW:AUDIT = docs/AUDIT.md §2 (C1–C4, D1–D5)
- LW:GAP = docs/GAP-AUDIT.md §4 and §7
- LW:PROG = docs/PROGRESSION.md §2 and §7
- LW:MONET = docs/research/monetization-2026.md §3

**Where the sources disagree**
- Hay Day truck unlock: level 4 [HS:truck] versus level 3 [HW:Truck].
- Hay Day Expansion Permit unlock: level 25 [HS:permit] versus level 29 [HW:Expansion/Farm].
- Hay Day boat help requests: 3 per boat [HS:boat] versus 4 [HW:Boat].
- State of Survival Research Task refresh: every 24 hours [SW:ResearchTask] versus every 2 days [SW:Missions].
- In each case this report uses the official figure where one exists.