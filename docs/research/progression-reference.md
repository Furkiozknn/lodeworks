# Progression architecture in long-lived base-builders

Research for the Factory Core's progression (docs/PROGRESSION.md), read on
25 September 2026 from official sources first: Supercell's news and Support
Portal for Clash of Clans and Boom Beach, the Century Games and Lilith pages
for Whiteout Survival and Rise of Kingdoms, and the Playrix and FunPlus
material for Township and State of Survival. Community wikis fill in the
level tables the publishers do not print, and are marked as such.

Two reports, kept as written. Each marks what a source says, what was
calculated from a source, what is the author's inference, and what could not
be verified (**UNVERIFIED**). Numbers change with game updates; the dates in
the tables say when they were read.

- Part 1: Clash of Clans and Boom Beach -- the Town Hall and Headquarters
  gates, level caps, builders, research, regions, and twenty principles for a
  single-player idle factory.
- Part 2: Whiteout Survival and Rise of Kingdoms (and what Township and State
  of Survival add) -- the Furnace and City Hall prerequisite chains, resource
  staging, parallel queues, and twenty cross-game patterns; with the
  monetisation pressure points not to copy.

What Lodeworks took from them, and why, is in docs/PROGRESSION.md.

---

# Part 1

## Progression architecture in Clash of Clans and Boom Beach, and principles an idle factory game can use

**Method.** Everything below was read on 25 Sep 2026.
- **[O]** marks an official Supercell source: supercell.com news or release notes, or the Supercell Support Portal (live pages that describe the game as it is now).
- **[W]** marks a Fandom wiki page, read as raw wikitext through the wiki API. Wiki facts are community data.
- **[D]** marks a number I calculated myself from wiki tables.
- **Inference** marks my own reading. It is not a claim made by any source.
- **UNVERIFIED** marks something I could not confirm.
- Reference keys (for example [S9], [W1]) point to the Sources list at the end.

---

## PART A: Clash of Clans (CoC)

### 1. The first minutes
- **Scripted tutorial [W4].** A Villager speaks each line:
  1. Goblins attack. You place a Cannon "in the center of the village. We must protect the Town Hall!"
  2. Wizards help you destroy the goblin camp.
  3. "Hiring a second builder will let you start two constructions simultaneously" (you must buy the second builder).
  4. You build an Elixir Collector, then an Elixir Storage, then a Gold Storage.
  5. You build a Barracks and train Barbarians, then attack the goblins.
  6. You name your village. "With the Gold we took from the goblins, we can afford to upgrade the Town Hall."
  7. The last screen points at the Builder menu: "Here you can find suggestions for what to build or upgrade next!"
- **Builder count at the start.** The Support Portal says "Everyone starts … with one Builder Hut" [S1]. The wiki says the tutorial leaves you with two, and the second is bought with starting gems [W6]. The tutorial line in step 3 fits both accounts.
- **How current is this?** The wiki script ends with "Starter Challenges". The Starter Pass was retired in September 2026 and replaced by the Gold Pass and Season Challenges from Town Hall 3 (TH3) [S10]. The exact current script is **UNVERIFIED**.
- **A risk-free practice space.** A 90-level Goblin campaign is open from the start. It has no time limit, does not affect your shield or trophies, and allows unlimited retries [S27].

### 2. The Town Hall (TH) at level 1
- **Official description:** it is "the heart of your village", and upgrading it "unlocks new defenses, buildings, traps and much more" [W1].
- **Level 1 statistics [W1]:** 400 HP. It stores 1,000 Gold and 1,000 Elixir, which can only be looted by destroying it. Destroying it gives the attacker one star.
- **What TH1 allows [W1]:** 1 Cannon, Gold Mine, Elixir Collector, Gold Storage, Elixir Storage, Army Camp and Barracks.
- **What TH1 caps [W1]:** Cannon at level 2 (in practice only reachable at TH2), mines and collectors at level 2, storages at level 1, Barracks at level 3.

### 3. Unlock order, TH1–TH5 (and the table for question 14)

| TH | Upgrade cost / time [W1] | New buildings (count data from [W1]) | Systems (official) |
|---|---|---|---|
| 1 | — | Cannon, Gold Mine, Elixir Collector, 2 storages, Army Camp, Barracks | — |
| 2 | 1,000 Gold / 10 s | +Cannon, Archer Tower, +Mine, +Collector, 25 Walls | — |
| 3 | 4,000 / 30 m | Mortar, +Mine, +Collector, +2 storages, +Army Camp, **Laboratory**, **Clan Castle** (rebuilding costs 10,000 Elixir [S30]); 2 Bombs; 50 Walls | Gold Pass and Season Tasks [S8, S10] |
| 4 | 25,000 / 3 h | +Archer Tower, Air Defense, +Mine, +Collector; Spring Traps; 75 Walls | **Hero Hall** and Barbarian King (usable only; he can be upgraded from TH7) [S3, O3] |
| 5 | 150,000 / 6 h | +Cannon, +Archer Tower, Wizard Tower, +Mine, +Collector, +Army Camp, **Spell Factory**; 100 Walls | — |
| 6 | 500,000 / 12 h | +Mortar, +Wizard Tower, +Air Defense, Air Sweeper, +Mine, +Collector; 125 Walls | Builder Base boat [S19]; Forge and Clan Capital (clan must be XP level 2) [S14, S16]; Clan Games [S12]; Trader [S22] |
| 7 | 1,000,000 / 18 h | +2 Cannons, +Archer Tower, +Mortar, +Air Defense, 2 Hidden Teslas, **Dark Elixir Drill and Storage**, Dark Barracks, +Army Camp; 175 Walls | Ranked Leagues [S23]; Hero Journey; Barbarian King upgrades [S3] |
| 8 | 2,000,000 / 1 d | +Archer Tower, +Mortar, +Wizard Tower, +Hidden Tesla, Bomb Tower, +storages, +Drill, Dark Spell Factory, **Blacksmith** [S4]; 225 Walls | Archer Queen (Hero Hall level 2) [O2, W2] |

- **Total buildings allowed [W1]:** 13 → 17 → 25 → 29 → 36 → 42 → 54 → 64 (TH1 to TH8; the count includes the TH and 5 Builder's Huts).
- **A stale wiki cell.** The wiki's TH table still lists the Hero Hall at TH7. The Support Portal and the wiki's own Hero Hall page say TH4 [S3, W2].
- **Later levels, in summary [W1, S2, S3, O2, O5, S7, S6]:**
  - TH9: X-Bows, Helper Hut (Lab Assistant), Minion Prince, second hero slot.
  - TH10: Inferno Towers, Builder's Apprentice, B.O.B's Hut.
  - TH11: Eagle Artillery, Alchemist, Grand Warden.
  - TH12: Workshop (siege machines); the Town Hall gains a weapon.
  - TH13: Scattershot, Royal Champion, fourth hero slot.
  - TH14: Pet House; Builder's Huts can be armed.
  - TH15: Spell Towers, Monolith, Dragon Duke.
  - TH16: first merged defenses; Fancy Shop.
  - TH17: Inferno Artillery (the Town Hall merged with the Eagle), Firespitters.
  - TH18: Guardians, Revenge Tower, Crafting Station.

### 4. Which resource feeds which system [W8, W9, S3, S16]
- **Gold:** defenses, traps, Walls, **Elixir Collectors and Elixir Storages**, Workshop.
- **Elixir:** troops, army buildings, Laboratory research, **Gold Mines and Gold Storages**, Dark Elixir buildings, Hero Hall, Blacksmith, Guardians.
- **Dark Elixir (from TH7):** heroes (except the Grand Warden), dark troops and spells, pets, Monolith.
- **Walls:** from level 5 they accept Gold *or* Elixir [W9].
- **Ore (three kinds):** Hero Equipment only [S4].
- **Capital Gold:** Clan Capital only. It is made in the Forge from home-village and Builder Base resources [S16].
- **Builder Gold and Builder Elixir:** Builder Base only.

### 5. Level caps
- **The TH caps the count and maximum level of every building [W1].** Example: Cannon maximum 2, 3, 4, 5, 6, 7, 8, 10 for TH1–TH8.
- **There is a second layer of caps: TH → hub building → items.**
  - **Hero Hall caps hero levels.** Official: "Maximum Hero upgrade levels now depend on the level of the Hero Hall" [O2].
    - The Barbarian King's cap is 10 / 20 / 30 / 40 / 50 / 65 at Hero Hall levels 1–6 [W2].
    - Hero Hall level N needs TH (N+6) from level 2 up; level 12 needs TH18 [W2].
  - **Laboratory caps troop levels; the TH caps the Laboratory.**
    - Laboratory level 1 needs TH3, level 16 needs TH18 [W3].
    - Barbarian level 2 needs Laboratory 1, level 4 needs Laboratory 5, level 8 needs Laboratory 9 [W11].
  - **Pet House caps pets.** Example: Diggy levels 11–15 need TH18 *and* Pet House level 12 [S10].
  - **Blacksmith level controls which equipment is available,** not how far it can be upgraded [O6].

### 6. When the TH can be upgraded
- **The inputs are Gold, time and a builder.**
  - Costs run from 1,000 Gold / 10 s at TH2 to 25,000,000 / 12 days at TH18 [W1].
  - The TH upgrade occupies one builder. The wiki advises timing it so the other builders finish at the same moment [W1].

### 7. Are resources enough?
No.
- **"Placing all available buildings at a Town Hall level is required to upgrade the Town Hall"** [W1]. Things bought with gems are exempt. Builder's Huts are not required, because requiring them "would unfairly hinder progression for players who do not buy Gems" [W1].
- **A rushed-base warning, not a block.** Official: "If your Village is 'rushed', attempting to upgrade your Town Hall will give you a notification recommending you upgrade your offensive abilities" [O4].
- **A built-in cost to rushing.** Loot is reduced when attacking lower-level Town Halls, "because of this, players should upgrade as much as possible at the current Town Hall level" [W1].

### 8. Prerequisites on other buildings' levels (all [W1])
- TH8 and above require the Hero Hall at its maximum level for your current TH, and every Hero Banner placed.
- TH17 and above require every available merge to be done. Merging itself requires both buildings to be at maximum level [O5].
- TH18 requires a maxed Inferno Artillery.

### 9. Research prerequisites
- **Chain:** TH → Laboratory level → troop and spell levels (see 5) [W3, W11].
- **One research job at a time.** Research uses no builder [W3].
- **Parallel research only through a paid event helper:** the Goblin Researcher, hired for gems during "Work for Hire" events [S28].

### 10. District and region prerequisites (Clan Capital)
- **Capital Hall unlocks districts.** "Upgrading the Capital Hall in the main District, 'Capital Peak', will unlock more Districts"; "Upgrading the District Hall unlocks more Ruins" [S15].
  - Each Capital Hall level from 2 to 9 opens one district. Level 2 also enables Raid Weekends [W7].
  - Capital Hall level caps District Hall level [O7, W7]. Example: at Capital Hall 5 the maximum District Hall levels are 3, 2, 2, 1 across the districts open so far.
- **Capital Hall needs a total of building upgrades done in the Capital** [W7]:
  - CH3: 65 upgrades (50 of them new)
  - CH5: 285 (120 new)
  - CH8: 1,090 (420 new)
  - CH10: 2,000 (500 new)
- **Builder Base second stage** opens at Builder Hall 6 [S19].

### 11–12. Why several resources, and the resource graph
- **The one official statement of intent** is about the Builder Base: "attacking well gives you Builder Gold to build a stronger defense and defending well gives you Builder Elixir to build a stronger offense" [O9].
- **Inference for the home village:**
  - Gold is the defense budget and Elixir is the offense budget.
  - Each one also pays for the other's production buildings, so neither can be ignored.
  - Dark Elixir arrives at TH7 as a scarcer third currency that gates the highest-value items (heroes, pets).
  - Ore is separate so that Hero Equipment grows through activity (Star Bonus, wars, Hero Journey), not through mining [S4].
- **The graph:**
  - Mines, collectors and loot → Gold / Elixir / Dark Elixir → buildings, research, heroes.
  - The Star Bonus pays Gold / Elixir / Dark Elixir plus Ore [S26].
  - Wars pay loot plus Ore [S25].
  - The Forge turns Gold / Elixir (TH9+), Dark Elixir (TH13+) and Builder Base resources (Builder Hall 8+) into Capital Gold. The Capital Gold is contributed to Capital buildings [S16].
  - Raids pay Capital Gold and Raid Medals. Raid Medals buy Magic Items (Books, Hammers, Runes, Potions) at the Trader, and those speed up the home village [S18, S22].
  - The Alchemist (TH11) converts between Gold, Elixir and Dark Elixir [S2].

### 13. Why upgrade the same building again and again
- **Every new TH raises every cap** (see 5).
- **Official design value, "Meaningful Progression":** "Leveling up is not just a matter of strength, but of meaningful additions on attack and defense" [O1].
- **Storages must grow to afford the next TH** [D from W1 and W10]:
  - At TH4, two maxed TH3 Gold Storages hold 2 × 45,000 and the TH4 Town Hall holds 50,000: 140,000 in total.
  - TH5 costs 150,000, so at least one storage must be upgraded first.
- **Late game adds reasons to keep going:** merges require maximum level [O5], and only maxed buildings can be Supercharged [S5].

### 14. What each TH opens
The table in section 3 covers TH1–TH8; later levels are summarised below it.

### 15, 23, 24. How new systems keep old ones valuable
- **Walls.** 25 to 325 segments, upgraded instantly, paid in Gold or Elixir, or with Wall Rings. They are an unlimited sink for spare resources [W1, W9, S22].
- **Old defenses become inputs.**
  - Two maxed Cannons or two maxed Archer Towers merge into a Ricochet Cannon or Multi-Archer Tower (TH16) [O5].
  - The Eagle Artillery merges with the Town Hall (TH17) [O2].
  - Builder's Huts become armed defenses at TH14 [S1].
  - Supercharges add charge levels "at a fraction of the cost of a full upgrade" to maxed buildings [S5].
- **Nothing invested is wasted.**
  - Supercharges that expire when new levels arrive, and Crafted Defenses at the end of each crafting phase, become Sparky Stones for cosmetics [S5, S6, S31].
  - "Don't worry about your progress going to waste!": re-Supercharging a building later costs half [S5].
- **Builder Base 2.0 (2023) pays back into the home village.**
  - Completing Builder Base tasks earns B.O.B, a sixth home-village builder. One task is "Gear Up 3 Buildings in Home Village" [O10, S20].
  - Builder Base resources can be forged into Capital Gold [S16].
- **Clan Capital.** It absorbs late-game Gold, Elixir and Dark Elixir plus spare builder time (a builder is busy for the whole Forge job). Its Raid Medals buy speed-ups for the home village [S16, S22].
- **Hero Hall (2024).** It replaced separate hero altars because "things are getting a little cramped" [O2].

### 16. How "what should I do now?" is answered
- **Builder menu** with suggested upgrades; tapping an entry moves the camera to that building [W5, W4].
- **Research tooltip** that "will show suggested research options along with their upgrade costs" [O4].
- **Rushed-TH notification** [O4].
- **A dedicated Events button** [O4], and an Event Hub listing current and upcoming events [S21].
- **Season Tasks** [S9], **Star Bonus** stars shown on the Attack button [S26], **Clan Games** [S12], **Hero Journey** [S3].
- **Achievements**, which pay XP and gems [W6].

### 17. How many sub-goals one TH upgrade involves
- **Hard gate:** place every new building (+4 to +13 per TH [W1]). From TH8, also max the Hero Hall.
- **Soft set, if you want to avoid rushing** [D]: new building level-ups unlocked by each TH (placing a building counts as level 1; heroes and research not included):

| TH | New building level-ups | New wall level-ups |
|---|---|---|
| 3 | +52 | +100 |
| 4 | +53 | +150 |
| 5 | +84 | +200 |
| 6 | +57 | +250 |
| 7 | +107 | +475 |
| 8 | +145 | +575 |

- **On top of that:** Laboratory research and hero levels.

### 18. How builders shape progression
- **The builder is the core pacing unit.**
  - Two builders early. Builders 3, 4 and 5 cost 500, 1,000 and 2,000 gems [W6]. B.O.B is the sixth [S1].
  - Heroes, Walls and Forge jobs also need a free builder [W5, S16].
  - Idle builders show sleeping "z"s over their hut [W5].
- **Helpers** [S2]:
  - The Builder's Apprentice (TH10, 500 gems) and Lab Assistant (TH9) each work 1 hour per 23-hour "work day" and remove 1 hour × their level from a timer.
- **Magic Items and gem helpers** [S22, S28]:
  - Book of Building finishes a building upgrade; Hammer of Buildings instantly upgrades a building and needs a free builder.
  - Builder Potion makes builders 10× faster for 1 hour; Research Potion makes research 24× faster for 1 hour.
  - The Goblin Builder is a gem-paid extra builder during events.
- **Scale of the job:** according to the wiki, 5 builders working 24/7 would need about 2 years 308 days to max every building [W5].

### 19. Research as a long-term goal
- **The Laboratory becomes the slowest track.** Its own upgrades reach 16 days (level 16) [W3]. The wiki warns that from TH8 up, research takes much longer than building upgrades [W1].
- **So the player has to choose** which troops to research [W3].
- **Speed-ups exist** (potions, Lab Assistant, Goblin Researcher) [S2, S22, S28].
- **Heroes work the same way through the Hero Journey:** every hero level is one point on a reward track [S3].

### 20. Daily, weekly and long-term goals, and how they link
- **Daily.**
  - Star Bonus: 5 stars, then a 24-hour timer. Up to two can stack, so a missed day is not lost [S26].
  - Season Task cards: 4 on day one, then "one additional card unlocks each day automatically, even if you don't log in". Each card has 8 tasks, 7 are needed, and there are up to 31 cards per season [S9].
- **Weekly.**
  - Ranked tournaments (Mondays 05:00 UTC) [S23].
  - The Trader refreshes every Tuesday [S22].
  - Raid Weekends: 5 attacks, plus one bonus attack for finishing off a district [S13].
- **Monthly.**
  - Clan War Leagues: a week-long season each month [S24].
  - The season track, with resource rewards scaled to TH level [S9].
  - Hoggy Bank payout at season end: 5× for Gold Pass holders [S29].
- **Long-term:** the next TH, the Hero Journey, Achievements.
- **Inference:** a single attack advances loot, the Star Bonus, task stamps and Clan Games at the same time, so every session moves several meters at once.

### 21. Why the player must do other things while saving
- **Storage caps.** Example: rebuilding the Clan Castle costs 10,000 Elixir and the support page says "Ensure your storages are upgraded" [S30].
- **Stored loot can be stolen.** Collectors and storages are both lootable [S26].
- **Resources cannot be hidden in upgrades.** Cancelling refunds only 50%, "to prevent 'banking'" [S11].
- **Idle builders are wasted capacity** [W5].
- **Inference:** when resources pile up and builders are busy, the answer is Walls, research or the Forge.

### 22. Why a new TH level does not feel like starting over
- **Nothing resets.**
- **Temporary boosts on upgrading, for 3–5 days** [W1]:
  - Troops and spells are powered to the maximum for the new TH.
  - Collectors produce 2×.
  - The Star Bonus is 4×.
  - From TH8, heroes and pets are also powered up.
- **New units start at a sensible level.** In Builder Base 2.0, "Troops will be automatically upgraded to their minimum level when they are unlocked" [O10].
- **The first hero came earlier on purpose.** It moved from TH7 to TH4 because "players who pushed all the way to TH7 wished they'd met their first Hero way sooner" [O3].
- **UNVERIFIED:** a third-party claim that the TH4 Barbarian King has 50% of level-1 stats. The official post does not say this.

---

## PART B: Boom Beach (BB)

### 1. The first minutes
- **Tutorial, according to the wiki [BW6]:** you land, build a Sniper Tower, survive a scripted enemy attack, load Riflemen into two Landing Craft, destroy a Blackguard base and "save the local islanders".
- **Starting base [BS1]:** HQ, Sawmill and Gunboat.
- **Boom Academy (HQ1–HQ7), an extended tutorial [BW11].** Four stages of missions, and every stage ends with "Upgrade Headquarters". Examples: destroy 2 bases, explore 2 map regions, build the Vault, build the Radar, "Check Helper's Suggestions", do 1 Armory upgrade, reach XP level 9.

### 2. The Headquarters (HQ) at level 1
- **Official [BS1]:** "Upgrading the HQ unlocks new Buildings, and your HQ Level determines the maximum level of those Buildings."
- **Damage mechanic [BS1, BW1]:** the HQ takes damage whenever other buildings are destroyed; together they add up to 70% of its health. Losing the HQ loses the battle and all resources not protected by the Vault.
- **HQ1 statistics [BW1]:** 10,000 HP. It unlocks Residence, Sawmill, Gold Storage, Sniper Tower, 2 Landing Craft, Gunboat, Radar, Rifleman and Artillery.

### 3 and 14. Unlock order, HQ1–HQ8 (all [BW1] unless marked)

| HQ | Cost / time / XP level needed | Opens |
|---|---|---|
| 2 | 600 Wood / 3 s / XP 1 | Quarry (Stone), Vault, Wood Storage, Heavy, +3 Mines |
| 3 | 1,900 Wood / 15 m / 1 | Iron Mine, Stone Storage, Flare |
| 4 | 5,900 Wood / 30 m / 1 | Iron Storage, Machine Gun, Mortar, **Armory**, **Hero Hut** (Sgt. Brick [BS9]), +1 Landing Craft |
| 5 | 13,000 Wood / 45 m / 9 | **Sculptor** [BS4], Zooka, Boom Pass [BS13] |
| 6 | 25,000 Wood / 1 h / 11 | Cannon, **Task Force** [BS6], Sonar Ops [BS12] |
| 7 | 33,000 Wood + 5,800 Stone / 1 h 30 m / 14 | Squad Leaders and Recruitment, Gadgets, Shock Bomb, Dr. Kavan |
| 8 | 49,000 Wood + 9,800 Stone / 2 h / 16 | Warrior, more storages and defenses |

- **Later levels, in summary:**
  - HQ9 Submarine.
  - HQ10 Warships and Barrage; Iron enters the HQ cost.
  - HQ11 Proto Troops. HQ12 Boom Cannon. HQ13 layouts. HQ15 Weapon Lab.
  - HQ19–24 late troops and heroes.
  - HQ26 Bunkers [BO1]. HQ27 Engraver [BS14]. HQ29 Garrison, released 16 June 2026 [BO3]. The HQ29 upgrade costs about 9 million each of Wood, Stone and Iron and takes 3 d 18 h.
- **The XP-level column may be outdated.** In April 2024 Supercell reduced the XP requirements for HQ4–7 [BO1], and the wiki values may or may not reflect that. They are **UNVERIFIED** as current.

### 4. Which resource feeds which system [BW5, BS3]
- **Gold is the offense currency:** training troops, Armory research, hero levels, starting attacks, exploring the map, submarine dives.
- **Wood, Stone and Iron are the construction currencies.** They are phased in: HQ costs are Wood only up to HQ6, add Stone from HQ7 and add Iron from HQ10 [BW1].
- **Gold also comes from the map:** Native Islanders pay Gold according to how many villages you have freed. Resource Bases on the map produce Wood, Stone and Iron [BS1, BW5].
- **Power Stones** build Statues. **Hero Tokens** upgrade hero abilities (Trader only). **Intel** starts Operations [BS3, BS4, BS7, BS9].

### 5. Level caps
- **HQ level caps building levels** [BS1].
- **Radar and Landing Craft maximum = HQ level** (for levels 1–20) [BW2].
- **Armory level N needs HQ N** (Armory 1 at HQ4, Armory 29 at HQ29), and Armory level caps unit levels [BW3]. Example: Rifleman maximum 2 at Armory 1, 29 at Armory 29; Tanks from Armory 9.
- **Hero abilities** are capped by HQ level and hero level [BS9].

### 6–8. When the HQ can be upgraded
- **Inputs:** Wood (plus Stone and Iron later), time, the single build queue, and an **experience-level requirement** [BW1].
- **XP comes from finishing upgrades** (every upgrade table has an XP column) [BW1, BW3].
- **The XP curve is tuned so that maxing every building and Armory item at an HQ level gives about 3 XP levels** [BW4]. So the XP gate is effectively a "finish most of this tier" gate.
- **Specific building prerequisites, according to the wiki (not re-checked for the current game) [BW1]:**
  - HQ4 needs the Radar built.
  - HQ5 needs Radar level 2.
  - HQ6 needs one troop at level 2.
  - HQ7 needs a Landing Craft at level 4.
  - HQ8 needs the Sculptor built.

### 9. Research: the Armory
- **Gold-funded** [BW3].
- **Runs in parallel with construction and needs no builder** [BW3].
- **One job at a time** [BW3].
- **The Engraver (HQ27)** adds a second, partly random research track. It uses Power Stone Shards and gives Research Tokens to aim at a chosen Engraving [BS14].

### 10. Regions and Radar
- **Map expansion.** "You can expand your map using Gold… Upgrade your Radar to explore even further!" Expansions are instant [BS2].
- **Growth by Radar level [BW2]:**
  - Radar 1 opens 8 regions; Radar 20 reaches 149 in total.
  - Opponent cap rises from 2 bases at Radar 1 to 34 at Radar 20.
  - Region prices rise with the Radar level they require.
- **Tribes** need their whole map area explored: Radar 18 for the first tribe, Radar 20 for all six [BW9].

### 11–12. Why several resources, and the graph
- **No official design statement was found.**
- **Inference:**
  - Splitting Gold (offense) from building materials (defense and economy) keeps attacking and base-building as separate budgets.
  - Adding Stone at HQ7 and Iron at HQ10 lengthens the curve and gives Resource Bases and exploration a job.
- **The graph:**
  - Radar and Gold → regions → Resource Bases and freed villages → Wood, Stone, Iron and Gold income [BS1, BS2].
  - Attacks → loot, Victory Points (VP), Intel, Power Stones [BS8].
  - Power Stones → Statues, which boost production, buildings or troops [BS4].
  - Intel → Operations → rewards [BS5, BS7].

### 13. Why repeat upgrades
- **XP from upgrades gates the HQ** (see 6–8).
- **Storage capacity rises with HQ level** [BS3].
- **Sculptor level adds Statue slots** [BS4].
- **Radar level adds regions and targets** [BW2].

### 15, 23, 24. How old systems and resources keep their value
- **Tribes.** Surplus Gold, Wood, Stone and Iron are turned into Raw Crystals. The first 100 crystals cost 500,000 of a resource, and each later 100 costs 500,000 more. The price resets every two weeks. Crystals pay for tribe boosts [BW9].
- **Warships (a separate game mode from HQ10).** It has a seasonal Tech Tree [BS15], and its rewards flow back to the main game: Intel, Power Powder, Trader Tickets [BS7, BS4, BS3].
- **Engraver.** It gives Shards and Power Powder a new use [BS14].
- **Shop of Evil.** Event rewards were consolidated into Evil Coins. The shop "always sells gold and building materials in unlimited amounts" [BO2].

### 16. How "what now?" is answered
- **Green-arrow signs** on buildings you can afford whenever the builders are idle; grey signs on ones you cannot afford [BW6].
- **A hammer menu** listing every building "along with their unlock requirements" [BS1].
- **Boom Academy** missions (HQ1–7) [BW11].
- **Boom Pass season missions:** 9 at the start of a season plus 6 each week, 39 in total [BW12].

### 17. Sub-goals per HQ step
- **About 3 XP levels of upgrades per HQ** [BW4].
- **Plus one named prerequisite** for HQ4–8 [BW1].
- **Boom Academy packages this as 4–5 missions per stage**, ending in "Upgrade HQ" [BW11].

### 18. Builder capacity
- **"Normally, only one project can be in progress at once"** [BW6].
- **Parallel queues:** the Armory and the Sculptor run alongside construction [BW3, BW10].
- **Extra capacity is a reward:** Build Tokens, Time Savers and Build Optimizers come from the Boom Pass [BW12]; "Unlimited Builders" can be bought in the Sonar Shop [BS11].

### 19. Research as a long-term goal
- The Armory repeats the Clash of Clans chain: **HQ → Armory → unit level** [BW3].

### 20. Goals by cadence
- **Daily.** A daily reward once you hold at least 25 VP, scaled by rank [BW8].
- **Continuous.** A Supply Chest per 5 VP; up to 8 stack, one every 6 hours [BO1, BW8].
- **Weekly.** The Cycle of Evil is a 7-day cycle with a different event each day [BS8]. Intel resets weekly [BS7]. The Trader visits weekly [BS3].
- **Task Force Operations.** One attack per member, 23 h 55 m long [BS5].
- **Seasonal.** The Boom Pass [BS13].

### 21. Why the player cannot just save
- **Losing a defense costs 1 VP and every unprotected resource** [BS10].
- **The Vault protects the stored amount plus 50% of the resources outside it** [BS3].
- **Attacking costs Gold, and the cost rises with XP level** [BW4].

### 22. Why a new HQ is not a restart
- **Unlocks are incremental:** mostly +1 building and new levels per HQ [BW1].
- **Troop Mania gives HQ5 players reduced-stat access to featured troops** [BO3].

### Boom Beach specifics
- **Victory Points.** +1 or +2 for a computer-controlled (Blackguard) base, +2 for a player base, +5 for a boss base, −1 for losing a defense [BW7]. VP drive matchmaking and rank, and rank drives rewards [BW7, BW8].
- **Power Stones and the Sculptor [BS4]:**
  - 4 elements × 3 sizes of stone. A Statue costs 7 stones of one size.
  - The boost type is random.
  - Salvaging a Statue returns a stone one size up.
- **Operations.** Force Points = buildings destroyed. The reward scales with Force Points, HQ level and Task Force size [BS5, BW13].

---

## PRINCIPLES (for a single-player idle factory)

1. **One number sets the tier.** A central level caps every other building's count and level (TH [W1]; HQ [BS1]), so the player's progress reads from one place.
2. **Put hub caps under the tier cap.** Tier → hub level → item level (Laboratory and troops; Hero Hall and heroes; Armory and units [W3, W2, BW3]) gives medium-length goals inside each tier.
3. **Gate the next tier with a checklist that finishes, not only with a price.** "Place all buildings", max the Hero Hall, finish merges [W1]; or XP that is only earned by upgrading [BW4].
4. **Warn instead of block when the player can go wrong but not break the game.** The rushed-base notification leaves the choice with the player [O4].
5. **Make the next tier cost more than the storage you arrive with.** Storage upgrades then become real prerequisites (TH5 costs 150,000; the arrival cap is 140,000 [D]).
6. **Give each resource one main job, then add cross-costs.** Gold for defense, Elixir for offense, and each pays for the other's producers [W8]; "attacking well gives you Builder Gold to build a stronger defense…" [O9].
7. **Introduce resource types in stages** (Dark Elixir at TH7 [W1]; Stone at HQ7, Iron at HQ10 in HQ costs [BW1]), so each new tier adds a new kind of complexity.
8. **Scarce parallel workers set the pace.** Builders and single research queues make every session a prioritisation decision [W5, BW6].
9. **Run research on its own queue**, so construction and research are two goal lines that move in parallel [W3, BW3].
10. **Always answer "what now?" in one tap:** suggestion lists, idle-worker signs, green arrows, suggested research [W5, BW6, O4].
11. **Stack goals by cadence and let them accumulate rather than punish absence.** Task cards arrive even when you do not log in; Star Bonuses stack to two [S9, S26].
12. **New systems should consume old surpluses:** Forge to Capital Gold [S16], Tribes' escalating Raw Crystal costs [BW9], Walls as an unlimited sink [W9].
13. **New systems should use old buildings as inputs:** merges and Supercharges need maxed buildings [O5, S5]; B.O.B's tasks need Gear Ups in the home village [O10].
14. **Never delete investment; convert it.** Expired Supercharges and Crafted Defenses become Sparky Stones [S31]; later re-Supercharging costs half [S5].
15. **Side systems should pay back into the core loop:** Builder Base gives a sixth builder [S20]; Raid Medals buy speed-ups [S22]; Warships give Intel and Power Powder [BS7, BS4].
16. **Soften each new tier.** Temporary boosts after a TH upgrade [W1]; new units start at their minimum sensible level [O10].
17. **Move a delight earlier when research says players wait too long** (first hero from TH7 to TH4 [O3]).
18. **Show locked content as a visible place:** ruins [S15], clouded regions bought region by region [BS2], a broken Clan Castle [S30].
19. **Early tiers take minutes, later tiers take days** (TH2 in 10 s, TH8 in 1 d; HQ2 in 3 s, HQ29 in 3 d 18 h [W1, BW1]), so the first session is full of completions.
20. **Refresh the endgame with rotating side-grades,** not only higher caps: crafting phases [S6], Supercharges [S5], a two-week tribe reset [BW9].

---

## Sources

**Official: Clash of Clans news**
- O1 Design Values: https://supercell.com/en/games/clashofclans/blog/news/fpo-clash-of-clans-design-values/
- O2 Town Hall 17 update: https://supercell.com/en/games/clashofclans/blog/game-updates/the-town-hall-17-update-is-here-2/
- O3 May 2026 update: https://supercell.com/en/games/clashofclans/blog/release-notes/may-update/
- O4 October 2023 patch notes: https://supercell.com/en/games/clashofclans/blog/release-notes/october-update-full-patch-notes-2/
- O5 Building Merging: https://supercell.com/en/games/clashofclans/blog/game-updates/building-merging-th16/
- O6 Hero Equipment: https://supercell.com/en/games/clashofclans/blog/news/introducing-hero-equipment/
- O7 Clan Capital and Forge: https://supercell.com/en/games/clashofclans/blog/game-updates/capital-forge/
- O8 Builder Base 2.0, Staying Small: https://supercell.com/en/games/clashofclans/blog/news/builder-base-2-0-staying-small-going-deeper-2/
- O9 Builder Base 2, Builders: https://supercell.com/en/games/clashofclans/blog/news/builder-base-2-balancing-attacking-defending-and-builders-2/
- O10 Builder Base 2.0 and B.O.B: https://supercell.com/en/games/clashofclans/blog/news/builder-base-2-0-layouts-troop-levels-and-bob/

**Official: Clash of Clans Support Portal** (prefix https://support.supercell.com/clash-of-clans/en/articles/)
- S1 builders-4.html
- S2 helpers-2.html
- S3 about-heroes-pets-9.html
- S4 hero-equipment-ore-5.html
- S5 supercharge-2-2.html
- S6 crafted-defenses-3.html
- S7 guardians.html
- S8 gold-pass-4.html
- S9 season-tasks-3.html
- S10 whats-new-september-2026.html
- S11 canceling-an-upgrade.html
- S12 clan-games.html
- S13 raid-weekends-3.html
- S14 what-is-the-clan-capital-3.html
- S15 building-in-the-capital-3.html
- S16 the-forge.html
- S18 rewards-2.html
- S19 builder-base-the-basics-2.html
- S20 builder-base-getting-master-builder-to-home-village-3.html
- S21 events-2.html
- S22 magic-items-and-the-trader.html
- S23 ranked-leagues-4.html
- S24 about-cwl-3.html
- S25 clan-war-rewards-2.html
- S26 about-multiplayer-and-trophies-2.html
- S27 single-player-attacks-2.html
- S28 work-for-hire-event.html
- S29 hoggy-bank.html
- S30 joining-a-clan-3.html
- S31 the-fancy-shop.html

**Wiki: Clash of Clans** (https://clashofclans.fandom.com/wiki/)
- W1 Town_Hall
- W2 Hero_Hall
- W3 Laboratory
- W4 Villager
- W5 Builder
- W6 Builder's_Hut
- W7 Capital_Hall
- W8 Resource_Buildings/Home_Village
- W9 Wall/Home_Village
- W10 Gold_Storage/Home_Village
- W11 Barbarian/Home_Village

**Official: Boom Beach news**
- BO1 HQ 26: https://supercell.com/en/games/boombeach/blog/updates/hq-26/
- BO2 Summer update 2025: https://supercell.com/en/games/boombeach/blog/updates/summer-update/
- BO3 HQ 29 ("Patrolling the beach"): https://supercell.com/en/games/boombeach/blog/blog/patrolling-the-beach/

**Official: Boom Beach Support Portal** (prefix https://support.supercell.com/boom-beach/en/articles/)
- BS1 buildings-boats-2.html
- BS2 the-great-archipelago.html
- BS3 resources-the-trader.html
- BS4 the-sculptor-statues-power-stones.html
- BS5 operations.html
- BS6 intro-to-task-forces.html
- BS7 intel.html
- BS8 the-cycle-of-evil-weekly-events.html
- BS9 heroes.html
- BS10 attacking-defending.html
- BS11 black-markets.html
- BS12 sonar-ops-3.html
- BS13 boom-pass.html
- BS14 the-engraver-2.html
- BS15 the-tech-tree.html

**Wiki: Boom Beach** (https://boombeach.fandom.com/wiki/)
- BW1 Headquarters
- BW2 Radar
- BW3 Armory
- BW4 Experience
- BW5 Resources
- BW6 Builder
- BW7 Victory_Point
- BW8 Rank
- BW9 Tribes
- BW10 Sculptor
- BW11 Commander's_Crash_Course
- BW12 Build_Token (redirects to Season Missions)
- BW13 Operation

**Notes on method.** Fandom pages returned HTTP 402/403 when opened in a browser, so they were read through the wiki's api.php. The [D] figures come from a scratch script over the Town Hall tables; no project files were edited.

---

# Part 2

## Progression Architecture Research: Whiteout Survival, Rise of Kingdoms, plus Township and State of Survival

**How to read this report**
- Every mechanic carries a source code like [W1] or [R1]. The codes resolve to URLs in the Sources list at the end.
- Text marked **Inference:** is my own analysis. Everything else restates what a source says.
- **Where the sources come from:**
  - Official pages were used where they could be reached: the Century Games help center (Whiteout Survival) and the Playrix help center (Township). Some of the Century Games help pages returned 404 when fetched directly. For those I cite the text from search results and mark it "(excerpt)".
  - The Rise of Kingdoms Fandom wiki blocked direct fetching (HTTP 402). Its claims come from search-result excerpts and are marked "(excerpt)".
  - All other tables come from community wikis and guides.
- **Conflicts between sources** are flagged where they occur. The main ones:
  - **whiteoutsurvival.wiki Furnace table [W1].** Its first cost column for levels 11–30 is labelled "Fire Crystal". BlueStacks [W5] and other guides give the same numbers as **Meat**, so I treat that column as Meat.
  - **mobi.gg [W4]** says Fire Crystal-era upgrades "no longer use standard resources". The wiki's Fire Crystal table [W6] shows they still do, and I follow the table.
  - **One guide (WSCO) [W7]** lists no server-age gate for Fire Crystal content. The official help center [W8] and the server timeline [W11] both say there is one.

---

## 1. Whiteout Survival (Century Games): the Furnace

**Q1. First minutes.**
- The Furnace is "your town HQ and the first construct you open". The Cookhouse is the second building, followed by the Sawmill, Hunter's Hut, Coal Mine and Iron Mine [W15].
- Each production building takes up to 6 Survivors as workers. A town can have at most 8 Shelters and at most 32 Survivors [W15].
- The Furnace makes heat. If fuel runs out, Survivors get sick, and they can die [W15][W5]. Poor food lowers their mood and can also make them sick [W15].
- At the start only the Chapter and Growth mission tabs exist. The Daily missions tab opens at Furnace 7 [W16].

**Q2. The Furnace at level 1.**
- It has no prerequisite. Its level sets "the max level you can upgrade other buildings to along with which buildings you can open up" [W1].
- Going from level 1 to 2 costs 180 Wood and takes 6 seconds [W1][W5].

**Q3 and Q12. What each Furnace level unlocks, and what it takes to reach it.**
The unlock list comes from mobi.gg, which appears to be machine-translated [W4]. I cross-checked it where possible: Research Center at 9 [W18], Embassy at 8 [W30], Infantry Camp at 7 [W20], Iron Mine at 5 [W2].

| Furnace level | Unlocks [W4] | Required buildings to reach this level [W1] | Cost to reach [W1] | Base time [W1] |
|---|---|---|---|---|
| 1 | Shelters 1–2, Sawmill, Cookhouse | – | – | – |
| 2 | Hunter's Hut | Sawmill 1 | 180 Wood | 6 s |
| 3 | Coal Mine | Shelter 1 at level 2 | 805 Wood | 1 min |
| 4 | Shelter 3, Hero Hall, Explorer's hut, "Clinic" | Coal Mine 3 | 1,800 Wood, 360 Coal | 3 min |
| 5 | Shelter 4, Iron Mine | Hero Hall, Shelter 3 at level 3 | 7,600 Wood, 1,500 Coal | 10 min |
| 6 | Shelter 5, Chief's House | Iron Mine 5 | 19k Wood, 3.8k Coal, 960 Iron | 30 min |
| 7 | Shelter 6, Infantry Camp, Barricade, Lighthouse | Hunter's Hut 6 | 69k Wood, 13k Coal, 3.4k Iron | 1 h |
| 8 | Embassy, Marksman Camp, Infirmary, Arena | Infantry Camp 7 | 120k Wood, 25k Coal, 6.3k Iron | 2 h 30 |
| 9 | Research Center, Lancer Camp, Storehouse | Embassy 8, Infirmary 1 | 260k Wood, 52k Coal, 13k Iron | 4 h 30 |
| 10 | Shelters 7–8, Command Center | Marksman Camp 9, Research Center 1 | 460k Wood, 92k Coal, 23k Iron | 6 h |

Later milestones:
- Hero gear at 15 and Mastery Forging at 20 [W2].
- Dock / Daybreak Island at 19 (official) [W9].
- Chief Gear at 22 and Chief Charms at 25 [W3].
- Fire Crystal upgrades after 30 [W2][W3].

**Q4. Resources and what each one feeds.**
- **Wood** (Sawmill) goes into every upgrade.
- **Coal** (Coal Mine) fuels the Furnace's heat [W15]. It enters Furnace costs at level 4 [W1].
- **Iron** enters Furnace costs at level 6 [W1].
- **Meat** (Hunter's Hut) is food for Survivors through the Cookhouse [W15]. "You won't need meat until reaching level 10 for upgrading the Furnace" [W2]. It appears in the level 11 cost [W5].
- **Steel** enters research later [W18].
- **Fire Crystals** come after Furnace 30, **Refined Fire Crystals** from FC5, and **Fire Crystal Shards** feed War Academy research [W3][W22]. The island has its own currency, **Life Essence** [W9].

**Q5. Does the Furnace cap other buildings?** Yes.
- Infantry Camp levels 1–7 need Furnace 7, and after that each camp level needs the same Furnace level [W20].
- The Embassy needs Furnace 8 for its levels 1–8 [W30].

**Q6. Furnace prerequisites for levels 11–30** [W1]:
- **The pattern:** every level needs **Embassy at level N−1**, plus one building from a rotating set, also at N−1.
- **The examples:** Furnace 11 needs Lancer Camp 10. Furnace 12 needs Command Center 1. Furnace 13 needs Infantry Camp 12. Furnace 14 needs Marksman Camp 13. Furnace 15 needs Lancer Camp 14. Furnace 16 needs Research Center 15. Furnace 20 needs Research Center 19. Furnace 24 needs Research Center 23. Furnace 28 needs Research Center 27. Furnace 30 needs Embassy 29 and Marksman Camp 29.

| Furnace level | Meat / Wood / Coal / Iron to reach it | Base time |
|---|---|---|
| 20 | 21M / 21M / 4.3M / 1M | 3 d 10 h |
| 25 | 81M / 81M / 16M / 4M | 18 d 8 h |
| 30 | 300M / 300M / 60M / 15M | 40 d 4 h 27 min |

**Inference:**
- From Furnace 13 to 30 the rotating slot cycles every four levels: Infantry → Marksman → Lancer → Research Center.
- Coal is always about 20% of Wood and Iron about 5%. For example, Furnace 10 costs 460k / 92k / 23k, and Furnace 30 costs 300M / 60M / 15M. The fixed ratio quietly tells the player what production mix to aim for.

**Fire Crystal era** [W6][W35]:
- **Sub-steps:** reaching FC1 takes five construction stages (30-1 through 30-4, then FC1).
- **Cost:** each stage costs 132 Fire Crystals + 67M Meat + 67M Wood + 13M Coal + 3.3M Iron, and takes 7 days.
- **Prerequisites:** stage 30-1 needs Embassy 30 and Research Center 30.
- **FC5 and later:** Refined Fire Crystals are added (10 at FC5-1, rising to 140 by FC10). Costs rise to 160M Meat/Wood, 33M Coal and 8.4M Iron, and stages take 13–20 days [W3][W6].
- **Community totals** for Furnace 30 to FC10: about 11k+ Fire Crystals, "hundreds of RFC", and "billions of RSS". These are estimates [W7].

**Q7. Is having resources ever enough on its own?**
- No. From level 2 onward, every Furnace level names at least one required building [W1].
- In the Fire Crystal era, "Crystals alone do not unlock the next Furnace step — building prerequisites do" (excerpt) [W35]. The state also has to be old enough (see Q9) [W8].

**Q8. Research.**
- The Research Center opens at Furnace 9 [W18]. It has three trees: Growth, Economy and Battle [W19].
- "Each level of the Research Center … unlocks higher tiers of technology." Research costs Wood, Meat, Coal, Iron and later Steel [W18].
- The Research Center is itself a Furnace prerequisite at Furnace 10, 16, 20, 24, 28 and 30-1 [W1][W6].
- **Troop tiers** unlock by camp level: T2 at camp 4, T3 at 7, T4 at 11, T5 at 13 (which also enables promotion), T6 at 16, T10 at 30. This is community data only (excerpt) [W21].
- **War Academy** (Fire Crystal era, server day 220 [W11]) runs "Helios" research. Its inputs are Fire Crystal Shards, Steel, Fire Crystals and Refined Fire Crystals [W22]. Finishing level 5 of the final track "flips T12 troops to trainable" [W22].
- The Helios chains are deep. Example: Helios Infantry 1 needs Flame Tomahawk 12, which needs Flame Strike 8, which needs Flame Squad 5 (excerpt) [W23].

**Q9. World-age and map gates.**
- **Official:** Fire Crystal content unlocks at Furnace 30 "and the server has been activated for a certain amount of time" (excerpt) [W8].
- **Community timeline** [W11]:
  - Day 60: Fire Crystal Age, through a Monument mission
  - Day 80: State vs State (SvS)
  - Day 150: FC5 plus the Laboratory
  - Day 220: War Academy
  - Day 315: FC8
  - Day 500: FC10
- **Monument missions** set personal, alliance and state-wide goals. Examples: "Kindling Embers: 2000 Chiefs in State reach Furnace level 7", and "Final Hope: Reach Furnace level 9" [W14].

**Q10. Why several resources, and the second-tier resource.**
- The base resources enter costs one at a time: Wood, then Coal at level 4, Iron at 6, Meat at 11 [W1][W2].
- The Fire Crystal tier stacks **on top of** the base resources rather than replacing them (see the 67M-Meat steps above) [W6].
- The **Crystal Laboratory** turns base resources into Fire Crystals every day [W12]:
  - Each exchange takes equal amounts of Meat, Wood, Coal and Iron, from 5,000 each up to 50,000 each.
  - It yields 1–5 Fire Crystals (40% chance of 1, 30% of 2, 15% of 3, 10% of 4, 5% of 5).
  - The player gets 5–8 exchanges a day depending on progression.
- **Super Refinement** turns Fire Crystals into Refined Fire Crystals [W13]:
  - 100 refinements per week, in five tiers of 20.
  - Each costs 20 to 160 Fire Crystals and yields 1–12 Refined Fire Crystals.
- Steel converts to shards: 50K Steel buys 1 shard, up to 20 times a day. 10 Fire Crystals convert to 13 shards (excerpt) [W24].
- **Inference:** this is a conversion ladder, base resources → Fire Crystals → Refined Fire Crystals, with Steel feeding shards. Because of it, early production never becomes worthless.

**Q11. Why the same buildings are upgraded again and again.**
- They are recurring prerequisites: the Embassy at every level, the three camps and the Research Center in rotation [W1].
- Each upgrade also buys something. Embassy levels add ally assists and reinforcement capacity [W30]. Camp levels unlock troop tiers [W21].
- The same buildings are upgraded again with Fire Crystals: the Furnace first, then the three troop camps and the Embassy [W7].

**Q13, Q21, Q22. How new systems keep old ones valuable.**
- The Laboratory consumes base resources [W12].
- Fire Crystal steps still cost base resources [W6].
- Fire Crystal camp upgrades keep the same troop tier but improve its stats. For example, T8 becomes Fire Crystal T8 (excerpt) [W21].
- Promotion charges only the cost difference between tiers, "so no resources are wasted" (excerpt) [W21]. The wiki confirms that promotion exists [W20].
- **Daybreak Island** (Furnace 19) is a side base with its own central building, the Tree of Life [W9][W33]:
  - Its currency is Life Essence. Prosperity comes from decorations, with a per-type limit [W9].
  - Tree levels need both Life Essence (500 to 100,000) and Prosperity (150 to 20,000) [W33].
  - Its buffs feed back into the main city, reaching "Troops Lethality +5%" at level 10 [W33].

**Q14. How "what now?" is answered.**
- **Chapter missions:** one-time and never expiring. Tapping a mission auto-navigates to its location [W17]. There are 10 chapters [W36].
- **Growth missions:** Main missions pay Gems, Side missions pay hero materials [W16].
- **Daily missions:** Activeness points unlock 7 chests [W16]. 800 personal points also unlock an alliance chest (excerpt) [W34].
- **Monument goals** [W14].
- **Event day themes:** SvS preparation Day 1 counts Fire Crystal use and construction/research/training speedups. Day 4 counts troop training and promotion [W28].

**Q15. Sub-goals per central upgrade.**
- Furnace 11–30: 2 required buildings + 4 resources + a timer. Furnace 2–8: 1 building + 1–3 resources.
- Each Fire Crystal level is five sub-steps. Each sub-step has 2 required buildings + 5 resources [W1][W6].

**Q16. Builders and speed-ups.**
- There is one construction queue by default. A second one costs "1000 gems for 2 days", or is permanent through a paid pack [W16][W26][W27]. There is "no documented free method" [W26].
- Guides advise keeping queue 1 on the Furnace and queue 2 on its prerequisites [W26].
- **Time reductions** [W25]:
  - "Double Time" Chief Order: −20% for 5 minutes, once a day
  - Tooling Up research: 27.80%
  - Two hero skills: 15% each
  - Alliance technology: 5%
  - Vice-President buff: 15%
- The Embassy increases the number of ally assists [W30]. At Embassy 30 that is 30 assists of 97 seconds each (excerpt).

**Q17. Research as a long-term goal.**
- Late research "can take weeks or even over two months" without speedups [W18].
- One full T11 branch takes about 13,421 shards and about 271 days of base research time (excerpt) [W23].

**Q18. Daily, weekly and long-term goals.**
- Daily missions and chests [W16].
- SvS roughly every 4 weeks, alternating with King of Icefield (excerpt) [W29].
- State Monument missions [W14], and a server timeline measured in months [W11].

**Q19. What the player does while saving.**
- Exploration: an idle PvE squad of up to 5 heroes that keeps earning rewards [W16].
- Alliance help and daily chores [W31].
- "Do not burn speedups blindly; save for events" [W31][W32].
- "Anything above warehouse protection can be looted" [W31].
- Island lumber camps keep producing while the player is offline [W9].

**Q20. Why a new Furnace level does not feel like starting over.**
- Officially, Fire Crystal buildings get "a brand-new appearance" (excerpt) [W8].
- **Inference:** a new Furnace level only raises caps and adds unlocks. Nothing resets, and the Fire Crystal sub-steps keep the reward rhythm going.

---

## 2. Rise of Kingdoms (Lilith Games): the City Hall

**Q1. First minutes.**
- The player chooses one of 14 civilizations, each with its own bonuses, units and starting commander, then plays a short tutorial [R11].
- The main quest starts during the tutorial (excerpt) [R12].
- The exact tutorial steps are **UNVERIFIED**.
- **Inference:** Farm #1, Hospital #1, Wall, Barracks and Storehouse exist from the start. They are prerequisites or "2nd" copies before any level unlocks them [R1].

**Q2. The City Hall at level 1.** It has no requirements and gives 2,000 troop capacity [R1][R4]. It "dictates the maximum level of every other building" [R4]. Its levels are grouped into Ages [R4][R5]:
- Stone Age: levels 1–3
- Bronze Age: 4–9
- Iron Age: 10–15
- Dark Age: 16–20
- Feudal Age: 21–25

**Q3 and Q12. City Hall unlocks and requirements** [R1]. Pocket Gamer shows the same level-2 unlocks [R2]. One search excerpt credits those level-2 unlocks to level 1; this is a table-labelling difference between sources.

| City Hall level | Unlocks | Required buildings | Cost (Food / Wood / Stone) | Time |
|---|---|---|---|---|
| 1 | – (2,000 troop capacity) | – | – | – |
| 2 | Lumber Mill #1, Archery Range, Scout Camp | none | 3.5K / 3.5K | 2 s |
| 3 | Farm #2, Alliance Center | Wall 2 | 6.5K / 6.5K | 5 min |
| 4 | Quarry #1, Academy, Stable, Hospital #2 | Wall 3 | 11.8K / 11.8K | 20 min |
| 5 | Lumber Mill #2, Shop, Siege Workshop, 2nd march queue | Wall 4, Hospital 4 | 21.3K / 21.3K | 1 h |
| 6 | Farm #3, Courier Station | Wall 5, Scout Camp 5 | 36.3K / 36.3K / 12K | 2 h |
| 7 | Quarry #2, Castle | Wall 6, Storehouse 6 | 54.4K / 54.4K / 19.2K | 5 h |
| 8 | Lumber Mill #3, Monument, T2 troops | Wall 7, Barracks 7 | 81.8K / 81.8K / 30.8K | 10 h |
| 9 | Hospital #3, Farm | Wall 8, Alliance Center 8 | 122.8K / 122.8K / 49.2K | 15 h |
| 10 | Quarry #3, Goldmine #1, Trading Post | Wall 9, Academy 9 | 184.3K / 184.3K / 78.7K | 1 d |

Later levels [R1][R3]:
- **Troop tiers:** T3 at 16, T4 at 21, T5 at 25.
- **March queues:** 3rd at 11, 4th at 17, 5th at 22.

**Q4. Resources.**
- **Food and Wood** go into buildings, research and troops [R6].
- **Stone** (Quarry at City Hall 4) enters City Hall costs at level 6 [R1]. It is also used for walls and advanced technology [R6].
- **Gold** (Goldmine at City Hall 10) "is required to research all technologies unlocked after Academy level 10, as well as the training/upgrade of all Tier 3 and higher troops, though it is not used in any building upgrades" (excerpt) [R7]. Pocket Gamer agrees [R6].
- **Gems** buy instant completion and acceleration [R6].
- **Master's Blueprints** are needed to take any building from 24 to 25 [R19].

**Q5. Caps.** "City Hall sets the ceiling for your city" [R3]; no building can outlevel it [R4].

**Q6. Required buildings for later City Hall levels** [R1]:
- **The pattern:** every level from 3 to 25 needs **Wall at level N−1**, plus usually one rotating building at N−1.

| City Hall level | Required buildings | Extra cost / time |
|---|---|---|
| 11 | Hospital 10 | |
| 12 | Storehouse 11 | |
| 14 | Alliance Center 13 **and** Trading Post 13 | |
| 16 | Academy 15 | 2.1M / 2.1M / 912.5K, 4 d |
| 19 | Stable 18 | |
| 20 | Alliance Center 19 | |
| 21 | Academy 20 | 11 d |
| 24 | Siege Workshop 23 | 36 d |
| 25 | Trading Post 24 | 82.2M / 82.2M / 36M + 1 Master's Blueprint, 126 d 8 h |

**Q7. Are resources enough?**
- Only for City Hall 2, the one level with no required building [R1].
- City Hall 25 also needs a Master's Blueprint [R1][R19].
- Several guides warn that a level's direct prerequisites don't include all of their own dependencies [R3].

**Q8. Research.**
- The Academy (unlocked at City Hall 4) has two trees. Economic covers gathering, production, build and research speed. Military covers troop tiers and combat stats [R8].
- Academy level gates access to troop research: level 8 for T2, 16 for T3, 25 for "Level V" nodes. Each Academy level also adds research speed, from 0.5% up to 25% [R8].
- The Academy is a City Hall prerequisite at 10, 16 and 21 [R1].
- Troop tiers need City Hall 8 for T2, 16 for T3 and 21 for T4, "each with the appropriate Academy research" [R3].
- T5 requires City Hall 25 and Academy 25, and in practice about 16 buildings at level 25 [R19][R21].

**Q9. Map zones and KvK.**
- A kingdom has six Zone 1 areas, three Zone 2 and one Zone 3 [R13].
- Entering Zone 2 requires the alliance to hold a level-2 pass [R13]. Tier 1 passes become capturable 24 hours after the "Rising of Heroes" timeline event. Tier 2 areas open 24 hours after "Wild Competition" (excerpt) [R14].
- Zone 3 holds the Lost Temple, and the leader of the alliance that controls it becomes King [R13].
- **Kingdom timeline events** are tracked in the Monument (City Hall 8). Examples: "Pandora's Box" (control a level-2 pass) and "The Last Golden Apple" (take the Lost Temple) [R16].
- **Lost Kingdom (KvK)** is a multi-phase event lasting more than two months. One guide says City Hall 16+ is needed to take part (community claim) [R15].

**Q10. Why several resources.**
- Food and Wood run through everything. Stone comes in during the mid game.
- **Gold** is the second-tier resource. It appears at City Hall 10 (Iron Age) but opens a new **sink branch** (research and T3+ troops) instead of inflating building costs [R7].
- **Inference:** keeping gold out of building costs stops the old build loop from becoming a gold grind.

**Q11. Why repeat upgrades.**
- The Wall is required at every level, and 5–10 other buildings rotate through as prerequisites [R1].
- The Alliance Center raises the help count from 5 at level 1, by one per level, to 30 at level 25 [R17].

**Q13, Q21, Q22. How new systems keep old ones valuable.**
- T5 requires rebuilding many old buildings to level 25: at least 16 Master's Blueprints, or 31 if resource buildings and hospitals are included [R19].
- The Mightiest Governor event's gathering stage scores "primarily from farming gold" [R18].
- In the Lost Kingdom, alliances can build only fortresses and Crusader Flags; the home city carries on [R15].

**Q14. Guidance.**
- **Main quest** from the tutorial onward.
- **Side quests:** "upgrade buildings, research technologies, defeat barbarians, and train troops".
- **Daily objectives:** activity chests at 20, 40, 60, 80 and 100 points, resetting at 00:00 UTC (excerpt) [R12].
- **Era Breakthrough:** a permanent event that rewards City Hall milestones [R4]. Gems at City Hall 16 (100), 21 (200) and 25 (500) [R5].
- The Monument timeline [R16].

**Q15. Sub-goals per upgrade.**
- City Hall 3–4: 1 building + 2 resources.
- City Hall 6–24: 2 buildings + 3 resources. City Hall 14 needs 3 buildings.
- City Hall 25: 2 buildings + 3 resources + 1 Blueprint [R1].

**Q16. Queues and speed-ups.**
- One builder by default. A second is temporary through a Builder Recruitment item, or permanent at VIP 6, or through gems [R9][R10].
- Each alliance help removes 1% of remaining time or 1 minute, whichever is greater (up to 3 minutes with research). Helps apply to building, research and healing (excerpt) [R17].
- Guide advice: "Use universal speedups only for technology" [R10].

**Q17. Research as a long-term goal.** T4 research alone takes about 20–30 days (excerpt) [R20].

**Q18. Linked goals over time.**
- Daily objectives [R12].
- The Mightiest Governor: six 24-hour stages (the final one 48 hours) covering training, barbarians, gathering, power from buildings and research, kills, and a final sprint [R18].
- KvK seasons [R15], and the kingdom timeline [R16].

**Q19. While saving.**
- Research and training run in parallel. Gather on the map. Join an alliance for help [R10].
- "Save your speedups and resources to win events like the Mightiest Governor" [R10].
- The Storehouse protects part of your resources [R6].

**Q20. Why a new level does not feel like starting over.**
- The Age changes and the upgrade rewards [R4][R5].
- **Inference:** each Age is a visible "era" marker, so a new level reads as advancement.

---

## 3. Township (Playrix) and State of Survival: only what they add

**Township: player level and population as a two-building gate.**
- Factories unlock at "a specific town level" or when you "have enough population". If you are short, the game tells you to build houses [T2].
- Community buildings raise the population cap, and houses fill it: "First expand the cap with community buildings, then grow your population by building houses!" [T1].
- Community buildings cost coins and produced materials: brick, glass and slabs, with tools later on. Examples [T4]:
  - Grocery Store (level 5): 25 coins, +10 population cap, 1 brick
  - Fire Station (level 8): 75 coins, +35 population cap, 2 glass, 2 bricks, 1 slab
- Some community buildings also need a base population, which comes from houses (excerpt) [T5].
- Production "only begins once all required ingredients are available" [T2].
- The Academy of Industry (level 22) upgrades factories with **ingots made in foundries**, and "upgrades apply to all stats gradually" [T3].
- **What this adds:** the central constraint is a derived quantity (population) that two building types produce between them, and the upgrade currency is itself a factory product. Both fit an idle factory game directly.

**State of Survival: a copy of the Fire Crystal pattern with one explicit rule.**
- After HQ 30, "plasma levels" begin. Each has five sub-levels at 132 cores each for the HQ (660 total) [T6].
- "You won't be able to upgrade the plasma levels of your other buildings until [the HQ] has reached the star level you're trying to obtain" [T6].
- Cores come from daily crates, events and intel missions, about 12–16 a day [T6].
- **What this adds:** it states outright that the central-building cap extends into the second-tier track.

---

## 4. Monetisation pressure points (do NOT copy)

- **A paywalled second builder:** WoS gem rental or a paid pack [W16][W26]; RoK VIP 6 or Builder Recruitment [R9]. A single queue creates constant scarcity.
- **Very long timers:** Furnace 30 takes 40 days and City Hall 25 takes 126 days [W1][R1]. They exist so speedups have something to sell.
- **A hard requirement buyable with premium currency:** the Master's Blueprint at 2,000 gems [R19]. Fire Crystals are also sold in packs (official, excerpt) [W8].
- **Events that score speedup burning:** SvS gives 30 points per minute of speedups (excerpt) [W29], and the Mightiest Governor has a power stage [R18]. Both push players to buy speedups.
- **Refund penalty:** reverting a Fire Crystal building refunds only half the crystals [W10], which punishes experimenting.
- **Server-age gates:** **Inference:** they make late joiners pay to catch up.
- **Monthly and weekly subscription cards** [W27], and resources left unprotected above storage get looted [W31].

---

## 5. CROSS-GAME PATTERNS

1. **One central building sets the ceiling for everything else.** Evidence: WoS [W1], RoK [R4], SoS plasma [T6].
2. **Each central level names 1–3 supporting buildings at level N−1.** So progress is a small dependency tree rather than a single bar (Furnace 10 needs Marksman Camp 9 + Research Center 1; City Hall 16 needs Wall 15 + Academy 15) [W1][R1].
3. **One "spine" prerequisite recurs at every level while a second slot rotates.** Embassy in WoS, Wall in RoK [W1][R1]. **Inference:** this makes each cycle predictable but still varied.
4. **A newly unlocked building quickly becomes mandatory.** The Coal Mine unlocks at Furnace 3 and is required at 4; the Iron Mine unlocks at 5 and is required at 6 [W1][W4].
5. **The research building is required at era boundaries.** WoS: Furnace 10, 16, 20, 24, 28 and 30-1. RoK: City Hall 10, 16 and 21 [W1][R1]. This ties research depth to base depth.
6. **Resource types enter costs one at a time.** WoS: wood, then coal (4), iron (6), meat (11). RoK: food/wood, then stone (6), then gold, which goes only into research and troops [W1][R1][R7].
7. **A fixed cost ratio signals the production mix to aim for.** **Inference**, computed from [W1]: Wood : Coal : Iron stays at about 1 : 0.2 : 0.05 at every level.
8. **The second-tier currency sits on top of base resources, not instead of them.** Fire Crystal steps still cost 67M Meat [W6], and SoS plasma follows the same pattern [T6].
9. **Conversion buildings turn surplus base output into the scarce tier.** Base resources → Fire Crystals [W12], Fire Crystals → Refined Fire Crystals [W13], Steel → shards [W24], ore → ingots → factory upgrades [T3].
10. **Late central levels are split into visible sub-steps.** Five per Fire Crystal or plasma level [W6][T6]. This keeps feedback coming as timers stretch into weeks.
11. **Timers grow geometrically until time becomes the binding constraint.** Furnace 2 takes 6 seconds, Furnace 20 takes 3 days, Furnace 30 takes 40 days, City Hall 25 takes 126 days [W1][R1]. This is exactly where monetisation attaches.
12. **Content gates on the world's age as well as the player's level.** Fire Crystal Age on day 60, FC10 on day 500; RoK zone passes after timeline events [W11][R14].
13. **Collective milestones turn individual upgrades into shared progress.** "2000 Chiefs reach Furnace 7" [W14]; the kingdom timeline [R16].
14. **A layered guidance stack answers "what now?".** One-time chapter missions with auto-navigation, then growth/side quests, then daily chest ladders, then themed event days, then month-long seasons [W16][W17][R12][R18].
15. **Themed event days tell the player when to spend what they saved.** SvS Day 1 is construction [W28]; the Mightiest Governor has a building/research power stage [R18].
16. **Parallel queues keep the player busy while the builder is locked.** Research, training, idle exploration, and island lumber [W16][W9][R10].
17. **Past investment is upgraded in place, not replaced.** Troop promotion charges the difference; Fire Crystal camps keep the tier with better stats [W21][W20].
18. **Side bases with their own central building widen progression.** The Tree of Life needs Life Essence + Prosperity, and its buffs return to the main city [W9][W33].
19. **Visual eras make a new level feel like advancement.** RoK Ages [R4]; WoS Fire Crystal buildings get a new appearance [W8].
20. **Capacity gates split into a "cap raiser" and a "filler".** Township community buildings raise the cap and houses fill it; factories need the population [T1][T2].

---

## Sources

**Whiteout Survival**
- W1 https://www.whiteoutsurvival.wiki/buildings/furnace/
- W2 https://whiteoutdata.com/buildings/furnace/
- W3 https://wostools.net/wiki/buildings/furnace
- W4 https://mobi.gg/en/tips/whiteout-survival-furnace-upgrade-requirements/
- W5 https://www.bluestacks.com/blog/game-guides/white-out-survival/wos-furnace-guide-en.html
- W6 https://www.whiteoutsurvival.wiki/buildings/fire-crystal-furnace/
- W7 https://www.whiteoutsurvival-community.com/tools/wiki/events/fc-furnace-wsco.html
- W8 (official, excerpt) https://centurygames.helpshift.com/hc/en/64-whiteout-survival/faq/6598-how-do-i-unlock-fire-crystal-content/ ; https://centurygames.helpshift.com/hc/en/64-whiteout-survival/faq/6601-how-do-i-obtain-fire-crystals/
- W9 (official) https://centurygames.helpshift.com/hc/en/64-whiteout-survival/section/1457-daybreak-island/
- W10 https://www.pocketgamer.com/whiteout-survival/fire-crystals/
- W11 https://www.whiteoutsurvival.wiki/server-timeline-server-age/
- W12 https://www.whiteoutsurvival.wiki/buildings/crystal-laboratory/
- W13 https://www.whiteoutsurvival.wiki/refinement-in-crystal-laboratory/
- W14 https://whiteoutdata.com/buildings/monument/
- W15 https://www.whiteoutsurvival.wiki/newbie-building-guide/
- W16 https://medievalfun.com/white-out-survival-beginner-guide-tips-and-tricks/
- W17 https://www.bluestacks.com/blog/game-guides/white-out-survival/wos-beginner-guide-en.html
- W18 https://www.bluestacks.com/blog/game-guides/white-out-survival/wos-research-center-guide-en.html
- W19 https://theriagames.com/guide/whiteout-survival-research-center-guide/
- W20 https://www.whiteoutsurvival.wiki/buildings/infantry-camp/
- W21 (excerpt) https://heaven-guardian.com/whiteout-survival-infantry-camp-upgrade-requirements/
- W22 https://wostools.net/wiki/buildings/war-academy
- W23 (excerpt) https://whiteoutdata.com/data/helios-research-requirements-and-chart/
- W24 (excerpt) https://www.whiteoutsurvival.wiki/items/fire-crystal-shard/
- W25 https://whiteoutdata.com/guides/how-to-reduce-construction-time/
- W26 https://heaven-guardian.com/whiteout-survival-is-the-extra-construction-queue-worth-it/
- W27 https://www.bluestacks.com/blog/game-guides/white-out-survival/wos-spending-guide-en.html
- W28 https://www.whiteoutsurvival.wiki/events/svs-state-of-power/
- W29 (excerpt) https://wostools.net/svs-prep-phase-guide
- W30 https://www.whiteoutsurvival.wiki/buildings/embassy/
- W31 https://www.whiteoutsurvival-community.com/tools/beginners-guide.html
- W32 https://wostools.net/beginners-guide
- W33 https://onechilledgamer.com/whiteout-survival-daybreak-island-guide/
- W34 (excerpt) https://outof.games/realms/whiteoutsurvival/guides/476-alliance-activity-triumph-in-whiteout-survival/
- W35 (excerpt) https://whiteoutsurvivalhandbook.com/guides/whiteoutsurvival-fire-crystal-furnace-guide-fc1-fc10
- W36 https://www.whiteoutsurvival.wiki/chapter-missions-beginner-quest-overview/

**Rise of Kingdoms**
- R1 https://riseofkingdomsguides.com/rise-of-kingdoms-city-hall-requirements-and-cost/
- R2 https://www.pocketgamer.com/rise-of-kingdoms/city-hall/
- R3 https://riseofkingdomshandbook.com/guides/riseofkingdoms-city-hall-requirements
- R4 https://theriagames.com/guide/rise-of-kingdoms-city-hall-guide/
- R5 https://gamerempire.net/rise-of-kingdoms-city-hall-guide-upgrade-requirements-rewards/
- R6 https://www.pocketgamer.com/rise-of-kingdoms/resources/
- R7 (excerpt) https://riseofkingdoms.fandom.com/wiki/Resources
- R8 https://heaven-guardian.com/rise-of-kingdoms-academy-guide/
- R9 https://theriagames.com/guide/rise-of-kingdoms-builders-hut-guide/
- R10 https://riseofkingdomsguides.com/rise-of-kingdoms-beginners-guide/
- R11 https://www.bluestacks.com/blog/game-guides/rise-of-kingdoms/rok-beginnners-guide-en.html
- R12 (excerpt) https://riseofkingdoms.fandom.com/wiki/Quests/Daily_Objectives ; https://riseofkingdoms.fandom.com/wiki/Quests
- R13 https://riseofkingdomsguides.com/rise-of-kingdoms-zones-guide/
- R14 (excerpt) https://riseofkingdoms.fandom.com/wiki/Kingdom
- R15 https://theriagames.com/guide/rise-of-kingdoms-lost-kingdom-guide/
- R16 https://theriagames.com/guide/rise-of-kingdoms-monument-guide/
- R17 https://riseofkingdomsguides.com/alliance-center/ ; (excerpt) https://riseofkingdoms.fandom.com/wiki/Buildings/Alliance_Center
- R18 https://riseofkingdomsguides.com/the-mightiest-governor-event/
- R19 https://theriagames.com/guide/rise-of-kingdoms-masters-blueprint-guide/
- R20 (excerpt) https://www.ajackof.com/games/rise-of-kingdoms-lost-crusade/rok-t4-rush-guide-in-rise-of-kingdoms/
- R21 (excerpt) https://riseofkingdomsguides.com/how-to-unlock-tier-5-units-fast/

**Township and State of Survival**
- T1 (official) https://playrix.helpshift.com/hc/en/3-township/faq/15054-how-to-increase-population/
- T2 (official) https://playrix.helpshift.com/hc/en/3-township/faq/10055-how-do-i-find-and-unlock-factories/
- T3 (official) https://playrix.helpshift.com/hc/en/3-township/faq/15071-academy-of-industry-and-upgrades/
- T4 https://simplegameguide.com/township-community-buildings/
- T5 (excerpt) https://township.fandom.com/wiki/Community_Buildings
- T6 https://www.pockettactics.com/state-of-survival/plasma
