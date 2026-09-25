# How Clash of Clans tells a player what to do next — and what Lodeworks should learn from it

Research date: 25 September 2026. Written for the Lodeworks owner. The aim is to learn from Clash of Clans (Supercell) how it teaches, paces and socialises, not to copy it.

**How to read this document**

- Each fact carries a source number from the list at the end. **[O]** = official Supercell (supercell.com, the Support Portal, talks by Supercell developers). **[S]** = secondary (Fandom wiki, press, analysts).
- Support Portal articles are undated living pages; they describe the game **as of September 2026**, when they were read.
- **Not verified** marks what could not be checked. Quotes are one sentence at most; the rest is paraphrase.
- Lodeworks context is from its README (source 75): Foreman advisor, 8-step first chapter, Descend-key preview, Core card, Codex, offline banking; rewarded video only, one IAP, "no energy, no timers, no gacha, no subscription, no daily-login guilt"; no server.

---

## 0. Key dates and versions (these change; check before quoting)

| Fact | Value | Source |
|---|---|---|
| iOS launch / Android launch | 2 Aug 2012 / 7 Oct 2013 | [S] 72 |
| Clan Wars added | 9 Apr 2014 | [S] 58 |
| Clan XP and Clan Perks added | 24 Feb 2015 | [S] 58, 53 |
| Legend League (tournament) added | Jul 2015 | [S] 58 |
| Friendly Challenges / Friendly Wars | 24 May 2016 / 12 Oct 2016 | [S] 58 |
| Builder Base launched (then unlocked at TH4) | 22 May 2017 | [S] 58 |
| Clan Games and Magic Items added | 18 Dec 2017 (Magic Items "late 2017") | [S] 58, 70 |
| Clan War Leagues added | 23 Oct 2018 | [S] 58 |
| Season Challenges and Gold Pass added | 2 Apr 2019 | [S] 58, 69 |
| Practice Mode added | Jun 2019 | [S] 57 |
| Clan Capital and Raid Weekends added | 1–2 May 2022 | [O] 12, 13 |
| Troop training costs removed | Jun 2022 | [S] 53, 58 |
| Builder Base 2.0 and the 6th builder B.O.B | 15 May 2023 | [O] 14, 15 |
| Hero Equipment and the Blacksmith (TH16 update) | 12 Dec 2023 | [S] 58; [O] 38 |
| Town Hall 17, Hero Hall and Helper Hut | 25 Nov 2024 | [O] 3 |
| "Clash Anytime": troop training *time* removed | 24 Mar 2025 | [O] 7 |
| Battle vs Ranked split | 6 Oct 2025 | [O] 8, 9 |
| **Town Hall 18** | 17 Nov 2025 | [O] 2 |
| Legend League split into three tiers | Apr 2026 | [O] 45; [S] 58 |
| First Hero moved from TH7 to TH4; extra Builder Base builder | 26 May 2026 | [O] 6 |
| Starter Pass retired; Gold Pass and Season Challenges from TH3 | 30 Aug 2026, test rollout in September | [O] 4, 5 |

**Maximum Town Hall.** The highest level in official material up to the 30 Aug 2026 update is Town Hall 18 [O] 2, 4, 5. Whether there is no Town Hall 19 is not verified.

---

## 1. The first minutes of a new player

### (a) What Clash of Clans does

- **A scripted story, not a menu tour.** A Villager speaks every tutorial line [S] 50 (Fandom record; the current script is **not verified**):
  1. The Goblin King attacks at once; you place a Cannon "in the center of the village" and win.
  2. Wizards arrive and you take out the goblin camp.
  3. You buy a second builder ("Hiring a second builder will let you start two constructions simultaneously." [S] 50).
  4. You build an Elixir Collector, an Elixir Storage and a Gold Storage.
  5. You build a Barracks, train Barbarians, attack a Goblin base, name your village and upgrade the Town Hall.
- **The tutorial ends by opening the two "what next" tools:** the Builder list ("Here you can find suggestions for what to build or upgrade next!" [S] 50) and the challenge list with its rewards [S] 50.
- **Guidance style.** Guides describe big arrows on what to tap [S] 51; the Goblin King is the named antagonist [S] 52. Exact highlight styles are **not verified**.
- **The threat is withheld.** Guides describe a 3-day starting shield [S] 51, 76; shields were reworked in Oct 2025 [O] 8, so the current length is **not verified**. The 90-level Goblin campaign is open at once, with no time limit, no trophy or shield effect and unlimited retries: "a great way of learning in a risk-free environment!" [O] 42.
- **Social and side content wait as visible wrecks:**

  | Wreck on screen | How it is restored | Source |
  |---|---|---|
  | Abandoned Clan Castle | "Rebuild" for 10,000 Elixir, then join a Clan | [O] 47 |
  | Broken boat to the Builder Base | Repaired at TH6 | [O] 44 |
  | Airship to the Clan Capital | Appears at TH6 once your Clan is level 2 | [O] 29, 35 |
  | Clan Capital buildings | Built up from Ruins | [O] 12, 36 |

- **Later features teach themselves on first entry.** Clan Wars, Clan War Leagues, the Builder Base and the TH7 season screen each run a short tutorial then [S] 50. Practice Mode gives step-by-step guided attacks per Town Hall level [S] 57. New mechanics get a three-panel card, one sentence per panel, one Continue button (Supercharge, Dec 2024) [S] 60.
- **The first Hero was moved earlier on purpose** (TH7 to TH4, May 2026), because players said they wished they had met one sooner [O] 6.

### (b) Why it works

- **A story beat makes the first action obvious.** Something attacks, you defend, you win. The first building has a reason, and the first attack is a win.
- **Everything taught is used within seconds**, on the player's own village. There is no sandbox.
- **Withholding is shown, not hidden.** A broken castle or boat says "this exists, and you will get it". That creates anticipation without a locked menu.
- **Deeper systems are taught at the moment they become relevant** (wars, leagues, second base), so the first session stays short.
- **A risk-free place to practise** (the goblin campaign, Practice Mode) lowers the cost of learning combat.
- **Honest caveat.** The tutorial also teaches the premium currency. The Villager suggests spending gems to speed things up, and a paid-for builder is part of the script [S] 50. That part is monetisation onboarding, and it conflicts with Lodeworks' stance (section 10.3).

### (c) Sources

[S] 50, 51, 52, 57, 60, 76; [O] 6, 8, 12, 29, 35, 42, 44, 47.

---

## 2. Town Hall progression: one building gates everything

### (a) What Clash of Clans does

- **The Town Hall is the gate for almost everything.** The wiki's in-game description calls it the heart of the village: upgrading it unlocks new defenses, buildings, traps and more [S] 54.
  - Each new Town Hall level raises the maximum level of everything else.
  - Some systems start at a fixed level:

    | Town Hall | Unlocks |
    |---|---|
    | TH3 | Season Challenges and Gold Pass (Aug 2026 onward) |
    | TH4 | Hero Hall |
    | TH6 | Clan Games; Clan Capital (Clan must be level 2) |
    | TH7 | Ranked Battles; Hero Journey |
    | TH8 | Blacksmith |
    | TH9 | Helper Hut |
    | TH14 | Pet House |
    | TH16 | Fancy Shop |

    Sources: [O] 4, 5, 8, 17, 24, 29, 34, 37, 38, 41.
- **Advancing requires finishing the current level.** You must place every building available at your Town Hall level before you can upgrade the Town Hall [S] 54.
  - There are deliberate exceptions for anything bought with gems. The five Builder's Huts are not required, because requiring them would penalise players who do not buy gems [S] 54.
  - From TH17 all merged defenses must also be merged [S] 54.
- **A warning, not a wall.** Since Oct 2023 the game shows a notification when a "rushed" village (weak offense) tries to upgrade its Town Hall. It recommends upgrading offense first, but it does not block the upgrade [O] 11.
- **Each level looks different.** Every Town Hall level has distinct art. From TH12 to TH17 the Town Hall even becomes a weapon; at TH18 it is guarded by Guardians [S] 54; [O] 2. The next level is therefore a visible, desirable object.
- **The trade-off is explicit.** A higher Town Hall means less loot from lower-level opponents [S] 54. Upgrading is not free of consequences, which makes it a decision.
- **Experience level is vanity, not a gate.** XP shows in the top-left corner. Its only effect is unlocking some decorations [S] 55. Progress is always read from the Town Hall.

### (b) Why it works

- **One number answers "how far along am I?"** Everyone, including clanmates and matchmaking, reads the same number.
- **"Finish this level first" gives a checklist that ends.** The player always knows what is left before the next big step.
- **The next Town Hall is a visible reward** (new art, a new weapon, new unlocks), so anticipation builds while the current level is being finished.
- **Warnings respect autonomy.** The rushed-village notice explains a consequence instead of forbidding a choice.

### (c) Sources

[S] 54, 55; [O] 2, 4, 5, 8, 11, 17, 24, 29, 34, 37, 38, 41.

---

## 3. Buildings, resources, the upgrade loop and the Builder

### (a) What Clash of Clans does

- **Collectors and storages.** Mines, collectors and drills fill by themselves; storages hold what you collect. Uncollected resources and part of storage can be stolen in raids [O] 49. Walls are a near-bottomless gold sink [S] 51. Cancelling an upgrade refunds half, "to prevent “banking.”" [O] 18b: parking resources in an upgrade would hide them from raiders.
- **The Builder is the pacing device.** "Builders are crucial to the progression of your Village." [O] 16
  - One hut at the start; more are bought with gems [O] 16. The wiki counts five [S] 53; a sixth, B.O.B, is earned through four Builder Base tasks (May 2023) [O] 14, 16.
  - One builder, one building at a time [S] 53. Starting one upgrade means not starting another.
  - Idle builders show "z"s above their hut [S] 53; a "1/5"-style builder counter sits at the top of the HUD [S] 59.
- **Time is the cost, and gems buy it back.** Gems speed up construction [S] 50, 51. Magic Items finish upgrades (Books, Hammers) or speed builders 10x and research 24x for an hour (Potions) [O] 33. A gem-paid Goblin Builder appears in events [O] 36. Helpers shave about an hour per 23-hour "work day" [O] 17.
- **Timers were removed from the fun part.** Troop training costs went in June 2022 [S] 53, 58; training *time* and Hero healing went in March 2025 [O] 7. Waiting now sits on construction and research.
- **Celebration.** The "building finished" fanfare is widely recognised (it circulates as a meme sound) [S] 71. Clan level-ups are posted in Clan Chat "for the whole Clan to celebrate." [O] 20 Upgrade-completion particles and animation are **not verified**.
- **The end game keeps growing:** merged defenses (TH16+) and Supercharges, which later convert to Sparky Stones for cosmetics [O] 2, 34; [S] 60.

### (b) Why it works

- **Scarce builders force a decision every session:** which one upgrade matters most now?
- **An idle builder is an alarm.** The "z"s and the counter say capacity is being wasted: the strongest "come back" signal in the game.
- **Filling collectors give short sessions a purpose.** Deconstructor of Fun (2013): whenever the app opens there is something to collect, and a short session can be only that [S] 67.
- **Removing the training timer kept combat instant** while construction timers kept long-term pacing: keep waiting away from the fun verb.
- **Caveat.** The builder is also a top monetisation item: buying one doubles parallel construction, and each hut costs more [S] 68. Timer-plus-skip is the core of Clash's revenue and must not come to Lodeworks.

### (c) Sources

[O] 2, 7, 14, 16, 17, 18b, 20, 33, 34, 36, 49; [S] 50, 51, 53, 58, 59, 60, 67, 68, 71.

---

## 4. Goals at every time scale

### (a) What Clash of Clans does

- **Minutes.**
  - *Builder menu:* "Suggested upgrades", then "Other upgrades", each with its cost; unaffordable costs in red; identical buildings grouped ("Gold Mine x4") [S] 59. Tapping an entry moves the camera to the building [S] 53.
  - *Laboratory:* suggested research since Oct 2023 [O] 11.
  - *Star Bonus:* five stars on the Attack button mean it is ready. Five won stars pay extra loot, then a 24-hour cooldown starts; up to two can stack, so a missed day is not lost [O] 49.
- **Day and week.**
  - *Season Tasks:* four cards on day one, then one per day "even if you don’t log in" [O] 27. Cards do not expire within the season; each has eight tasks and needs seven, repeats allowed; up to 31 per season [O] 27.
  - *Weekly clocks:* the Trader restocks every Tuesday [O] 33; Raid Weekends run Friday to Monday [O] 13, 18; Ranked runs weekly tournaments [O] 44.
- **Month.**
  - *Season:* a calendar month [S] 56, with a free (Silver) and a paid (Gold) reward track scaled to Town Hall level [O] 26, 27.
  - *Clan War Leagues:* a week-long season once a month [O] 30.
  - *Clan Games:* a caravan at the village edge offers shared challenges. You take one at a time, each with a time limit; an expired one can be revived with gems or discarded [O] 24, 25.
  - *Hoggy Bank:* earned loot is matched into a bank paid out at season end, multiplied by five for Gold Pass holders [O] 40.
- **Long term.** Achievements (the wiki counts 54, three levels each, paying XP and gems; moved into the profile when an Events button replaced them in Dec 2016 [S] 61). The Hero Journey (TH7+): every Hero level is a point on a reward track [O] 41. Also the next Town Hall, B.O.B's tasks [O] 14 and Legend League [O] 45.
- **Events are always visible.** An Event Hub icon sits bottom-left next to the Season Challenges button and lists current and upcoming events [O] 26 (a dedicated button since Oct 2023 [O] 11). Some sell an Event Pass [O] 26.

### (b) Why it works

- **There is always an answer at three distances:** one tap (Builder menu), today and this week (task cards, Star Bonus, weekend raid), and this month or year (season, leagues, Town Hall).
- **Several goals move together.** One attack advances loot, the Star Bonus, task stamps and Clan Games at once. A single session feels productive on many tracks.
- **The newer systems are designed not to punish absence.** Task cards arrive even if you do not log in and pile up. Star Bonuses stack to two. Supercell chose accumulation over streaks here, and that is the part worth learning.
- **Rewards are shared with the group** (Clan Games tiers, Raid Medals), so personal goals also create social pull (section 7).

### (c) Sources

[O] 11, 13, 14, 18, 24, 25, 26, 27, 30, 33, 40, 41, 44, 45, 49; [S] 53, 56, 59, 61.

---

## 5. UI/UX information architecture

### (a) What Clash of Clans does (as far as it could be verified)

- **HUD corners.** XP level top-left; tapping it opens the profile [O] 47; [S] 55. Attack bottom-left, with the Season Challenges shield to its right [S] 56 and the Event Hub beside that [O] 26. Settings near the bottom-right [S] 62. Across the top: builder counter ("1/5"), helper counter and shield timer with a "+" [S] 59, each with a small "i" info badge [S] 59. The exact position of the resource bars and the Shop is **not verified**.
- **The building is the menu.** Tapping it opens its actions. The Town Hall gives Magic Items, Scenery and, at TH18, the Guardian menu [O] 2, 33; [S] 63. Helpers are assigned by tapping the building they help [O] 17. Troop info screens got animated previews in Oct 2023 [O] 11.
- **Status lives on the world.** Sleeping builders [S] 53, the Loot Cart after a defense [S] 64, the Clan Games caravan [O] 24, five stars on Attack [O] 49, villagers running into the Town Hall during an attack [S] 50.
- **Locked states** are either diegetic (ruins, broken castle, broken boat) [O] 12, 44, 47 or greyed options, such as troops you cannot donate [O] 19.
- **Warnings, not blocks** (rushed Town Hall) [O] 11, and a confirmation before any Magic Item is used or bought [O] 33.
- **Noise filters:** "Show Only Relevant Reinforcement Requests" hides requests you cannot fill [O] 19; the pass has an "Unclaimed rewards only" filter [O] 27.

### (b) Why it works

- **Each corner answers one question.** Who am I (top-left), what can I spend (resources), what is working (counters at the top), what should I do (Attack, season, events at the bottom-left).
- **The world is part of the interface.** A sleeping builder or a waiting caravan says "there is something here" without a notification badge.
- **One tap on the building is the only way in.** Players never hunt through menus for building-specific actions.
- **Red costs and grouped suggestions turn the upgrade decision into a readable list.**

### (c) Sources

[O] 2, 11, 12, 17, 19, 24, 26, 27, 33, 44, 47, 49; [S] 50, 53, 55, 56, 59, 62, 63, 64.

---

## 6. Builder Base: a second progression track

### (a) What Clash of Clans does

- **Launch.** It launched on 22 May 2017, reached by a boat. At first it needed TH4 [S] 58; now it needs TH6 [O] 44.
- **Its own world.** It has its own Builder Hall, its own resources (Builder Gold and Builder Elixir), the Master Builder and its own leagues [O] 44.
  - The launch notes stressed ease of management: troops trained automatically and you could not be attacked while away [S] 58.
- **Bridges between the two bases.**
  - "Gear Up" lets the Master Builder upgrade selected Home Village defenses with Builder Base abilities [S] 58.
  - Since May 2023, B.O.B becomes a permanent 6th builder for the Home Village once four Builder Base tasks are done [O] 14, 16. B.O.T.O later adds help back in the Builder Base [O] 44.
  - In May 2026 the Builder Base got an extra builder once all Home Village builders are unlocked [O] 6.
- **Builder Base 2.0 (15 May 2023) was a full rework** aimed at more tactical attacks and rewards for both attacking and defending [O] 14, 15. Attacks became two-stage from BH6; defending earns Builder Elixir; a Star Bonus replaced the old daily three-win cap, with attacking allowed after it; new troops start at useful levels instead of level 1 [O] 14.

### (b) Why it works

- **A second track gives a player something to do while the main track is waiting** (on builders, in Clash's case).
- **Separate currencies stop one track trivialising the other.**
- **Bridge rewards (Gear Up, B.O.B) make the side track matter to the main one,** so it is not ignored.
- **The 2.0 rework is also a warning (my inference, not Supercell's words):** a side mode needs its own hook, or it becomes a chore.

### (c) Sources

[O] 6, 14, 15, 16, 44; [S] 58.

---

## 7. Social systems

For each system: purpose, inputs, outputs, player benefit, social benefit, and how it is asynchronous.

### 7.1 Clans

- **Purpose.** A persistent group of up to 50 players with roles (Member, Elder, Co-leader, Leader) [O] 47, 48.
- **Inputs.** Rebuilding the Clan Castle (10,000 Elixir) and applying to or creating a clan [O] 47.
- **Outputs.** Chat, donations, wars, Clan Games, Capital, and perks.
- **Player benefit.** Help, advice and troops.
- **Social benefit.** Identity and obligation: "Clans are designed to be independent communities." [O] 48 Supercell does not overrule leaders [O] 48.
- **Survives absence.** A leader inactive for 60 days triggers an automatic hand-over [O] 48.
- **Guard rails.** Search by labels, language, war frequency and minimum Town Hall; family-friendly clans for young players [O] 47; a one-hour cooldown on clan-wide leader messages [O] 48. A Clan Notice Board arrived in Sep 2024 and global chat in Jun 2026 [S] 58.

### 7.2 Donations (troop and spell requests)

- **Purpose.** Clanmates fill each other's Clan Castle.
- **Inputs.**
  - A request with an optional specific unit [O] 19. Requests are standardised at a 10-minute cooldown, which Gold Pass perks can shorten [O] 7; [S] 53.
  - Since Mar 2025, donating costs the donor Elixir or Dark Elixir [O] 7.
- **Outputs.** The recipient gets units for one attack or for defense [O] 19. The donor gains XP, season Challenge Points (via a daily donation task) and achievement progress [O] 19.
- **Player benefit.** A stronger attack than you could build alone.
- **Social benefit.** Small, frequent acts of generosity that are visible in chat.
- **Asynchronous.** Requests wait in chat until filled.

### 7.3 Clan Wars and Clan War Leagues (CWL)

- **Purpose.** Clan versus clan competition.
- **Inputs.**
  - Clan Wars: a lineup chosen by leaders (members signal opt-in or opt-out), a 23-hour Preparation Day (scout, donate to war bases), then a Battle Day with two attacks each [O] 28, 39.
  - CWL: a monthly week of daily wars in groups of eight, one attack per player per day, 15v15 or 30v30 [O] 30, 31; [S] 58.
- **Outputs.** Loot, Ore, a war-win bonus in the Treasury, and Clan XP [O] 32. In CWL, League Medals scale with placement; players who score at least 8 stars get the full share [O] 31.
- **Player benefit.** Rewards that do not risk your own resources or trophies [S] 58.
- **Social benefit.** Coordinated planning and replays of every battle [O] 28.
- **Asynchronous.** Attacks happen whenever you like within Battle Day. They are simultaneous only in the sense of sharing a deadline.

### 7.4 Clan Capital and Raid Weekends

- **Purpose.** A shared base the whole clan builds and fights with. Support calls it the place where "the Clan can build together and battle together!" [O] 35
- **Inputs.** Capital Gold, made in the Forge from home resources (a builder is busy for the whole conversion) and looted in raids, contributed to any Capital building [O] 12, 23, 35, 37. Leaders mark up to three priorities per district [O] 36; the Builder Menu shows what others are funding [O] 29, 36.
- **Outputs.** A building levels up the moment it is funded: "A Building levels up instantly once there are enough Contributions to a Building." [O] 36 Contributors earn Reputation and keep it if they leave [O] 23; Capital Peak houses are customised with earned parts [O] 35.
- **Raid Weekends** (Friday to Monday; five attacks per player for the weekend plus one bonus) [O] 13, 18. Damage persists: "The damage you do in your attack will stay in the District for the next attacks." [O] 18 Clans do not fight head-to-head; Raid Medals are split equally among everyone who attacked; the defense bonus pays only if your clan also destroyed an enemy district, which "encourages Clans to always also attack" [O] 22, 23.
- **Capital Leagues** reward turnout: "Activity and participation are the most important factors" [O] 20a.
- **Player benefit.** Anyone can help at any level, because raid troop levels come from the clan, not the player [O] 18.
- **Social benefit and asynchrony.** One visible shared project; contributions and attacks fit anywhere in the window.

### 7.5 Clan Games and clan events

- **Clan Games.**
  - Shared challenges whose points unlock reward tiers for everybody [O] 24, 25.
  - "To be eligible for rewards, you need to complete at least one challenge." [O] 26a
  - Maxing your own point cap earns an extra reward pick [O] 26a.
- **Clan Gold Rush.**
  - Members contribute Gold Nuggets, earned 1:1 alongside normal Gold (spending no Gold). Milestones unlock rewards for all contributors [O] 37a.
  - A leaderboard shows individual contributions. Support says "No contribution is too small." [O] 37a

### 7.6 Visiting, friendly challenges and friends

- **Visiting.** You can visit clanmates' villages and see their traps [S] 58. Since Jun 2018 you can copy a clanmate's layout while visiting (TH4+) [S] 58.
- **Friendly Challenges.** Your own base is posted as a challenge in clan chat. Anyone can attack it with no trophy or loot risk, others watch live or later, and optional difficulty modifiers apply [O] 23a.
- **Friends.** Up to 100 in-game "Clash Friends" [O] 39a.

### 7.7 Leaderboards, Legend League, Ranked

- **Leaderboards.** Clan score comes from the top 30 members' league placements [O] 21. Ranked runs weekly group tournaments with promotion and demotion; four inactive weeks bring demotion, then decay to a Town Hall floor [O] 44. Legend League has had three tiers since Apr 2026, with local and global boards [O] 45.
- **Why the split.** One matchmaking system could not serve farmers and competitors alike [O] 9: "Casual players will prefer the relaxed, laid-back style of regular Battles, while dedicated players will love the competition and intensity of Ranked Battles." [O] 43

### 7.8 Clan XP and perks

- **Inputs.** Clan XP comes from wars, Clan Games tiers and Raid Weekends [O] 21; [S] 53.
- **Outputs.** Perks are cumulative and shared by all members: Treasury size, donation limits, donated-troop upgrades, war bonus loot [O] 20.
- **Social benefit.** A clan's level is a visible reputation, and a reason to recruit and stay.

### Why the social layer works

- **Every social system turns your normal play into a gift to others.** Your troops, your gold, your attack on a half-damaged district.
- **Everything is asynchronous inside a generous window,** so people in different time zones and schedules can all take part.
- **Equal sharing (Raid Medals) and "at least one challenge" thresholds reward participation over power,** which keeps weaker players welcome.
- **Leaders get tools to steer, not to force.** Priority marks, lineups and bonus medals.

### (c) Sources

[O] 7, 9, 12, 13, 18, 19, 20, 20a, 21, 22, 23, 23a, 24, 25, 26a, 28, 29, 30, 31, 32, 35, 36, 37, 37a, 39, 39a, 43, 44, 45, 47, 48; [S] 53, 58.

---

## 8. Retention structure

### (a) What Clash of Clans does

- **Seasons.** A calendar month [S] 56, with stacking task cards [O] 27 and a Hoggy Bank paid at the end [O] 40. Consecutive Gold Pass purchases earn loyalty bonuses [O] 26, 27 (one extra stamp from May 2026 [O] 6).
- **Events.** A rolling calendar of themed challenges and temporary rule changes [O] 26: Work for Hire [O] 36, Clan Games, Super Troop events, Gold Rush [O] 37a, licensed collaborations such as WWE in Sep 2026 [O] 5.
- **Collections.** Hero Equipment (TH8+; common from the Blacksmith, epic from events or the Hero Journey, upgraded with three Ores) [O] 38; Hero Skins [O] 26; Sceneries (a default, more at TH14 and TH15, others sold and repurchasable a year later) [S] 63; decorations gated by XP or league, or limited editions [S] 65; Capital Peak house parts [O] 35; Fancy Shop cosmetics bought with Sparky Stones from end-game upgrades [O] 34.
- **Long-term progression.** Recent Town Hall levels came roughly yearly (TH16 Dec 2023, TH17 Nov 2024, TH18 Nov 2025) [S] 58; [O] 2, 3, with cost cuts for older levels [O] 3, 8.
- **Returning players** [O] 39. After 35+ days away, a 7-day Login Calendar (135-day cooldown). After 90 days, a 48-hour shield and village boosts worth about half of what regular play would have earned: "Logging in and playing on a regular basis is the quickest way to make progress, so there's no need to rely on returning rewards." The Loot Cart is "overloaded" after 3+ days away [S] 64; new and returning players may get larger Ore drops [O] 41.
- **Design intent.**
  - The 2017 design values: depth, playstyle diversity, simplicity, meaningful progression (each level brings new play) and social play ("best played with others") [O] 1.
  - 2026: several viable paths, not equal ones [O] 10.
  - Jonas Collaros (GDC 2015): a long-running game's essential needs keep changing [S] 74.
  - Eino Joas (GDC 2020) on 2017–2019: an exponential economy, a content gap for maxed players, social barriers and weak conversion, answered with Magic Items, TH12, CWL and the Gold Pass; the lessons were understand the fundamentals, be generous, think long-term [S] 66, 70.

### (b) Why it works

- **Nested clocks (session, day, week, month, year) mean that whenever a player opens the game, some clock has just ticked.**
- **Collections and cosmetics give maxed players something that never "finishes".**
- **Returning players are welcomed rather than shamed,** but the catch-up is deliberately smaller than steady play, so it cannot be gamed.
- **Caveat.** Much of this retention layer is also monetisation: Gold Pass perks, the Hoggy Bank multiplier, Event Passes and gem revives. Deconstructor of Fun argues the pass worked in Clash because its resource-depletion economy has many sinks for pass rewards [S] 69a. Sensor Tower estimated spending rose about 145% in the week after the Gold Pass launched in April 2019 [S] 69.

### (c) Sources

[O] 1, 2, 3, 5, 6, 8, 10, 26, 27, 34, 35, 36, 37a, 38, 39, 40, 41; [S] 56, 58, 63, 64, 65, 66, 69, 69a, 70, 74.

---

## 9. Why Clash of Clans is good at "what next"

This section is a synthesis of the sections above.

1. **One gate, always visible.** The Town Hall level is the answer to "where am I?". The requirement to place everything before advancing is the answer to "what is left?".
2. **An idle resource is an alarm.** A sleeping builder, a full collector, five stars on Attack, a caravan at the edge: the world itself says "something is waiting".
3. **A suggestion list sits one tap away,** ranked, costed, with unaffordable costs in red, and jumps the camera to the target [S] 53, 59.
4. **Many small goals move together,** so any session advances something.
5. **Teaching happens at first contact.** Tutorials on first entry to a feature, three-panel cards for new mechanics, guided practice per level.
6. **Absence is not punished in the newer systems.** Task cards accumulate, bonuses stack, the Hoggy Bank banks, and returning players get a catch-up.
7. **The group is a goal generator.** Requests to fill, a district half-destroyed by a clanmate, a clan tier two points away.
8. **Warnings rather than walls, and choice between modes** (Battle versus Ranked), so different motivations each get a path [O] 9.
9. **Waiting was moved off the fun verb.** Supercell removed army training costs and times but kept construction pacing. Note that Clash still runs on timers-for-sale; Lodeworks should take the first half of that lesson only.

---

## 10. Translating to Lodeworks

### 10.1 Already there: Lodeworks does these, so do not rebuild them

| Clash of Clans | Lodeworks today (per README, source 75) |
|---|---|
| Villager advisor with scripted lines | The Foreman, who speaks for the 8-step first chapter and then only at a new stratum and at the first overheat |
| Arrows on what to tap | Pulsing outlines and a bobbing arrow |
| Town Hall "next unlocks" | The Descend key shows the next stratum's machines; holding it previews rules and ground; the Core card shows "what the next stratum brings" |
| New-mechanic intro card | Unlock card with the new machines "big and working" |
| Troop info screens | Codex pages running a live mini-board |
| Returning player | Offline production banked and shown on return |

**Where Lodeworks is already better:**

- **The Codex runs the rule instead of describing it.** Clash's help cannot do that.
- **The simulation is deterministic and headless.** The same stratum is the same for everybody, so any score can be re-computed from a layout. Clash's PvP cannot offer that. It is the key to cheat-resistant competition (10.2.12).

### 10.2 Proposed equivalents

Each entry lists purpose, input, output, player benefit, social benefit, economy impact, progression impact, UI needs and what not to copy. "Server" marks the ones that need a backend Lodeworks does not have today.

#### 10.2.1 Factory Core as the gate (from the Town Hall)

- **Purpose.** Keep the Core as the one "how far am I" number and the home of the next-unlock preview.
- **Input / output.** Descending grows the Core and the ring (already so); out come machine unlocks, ring growth and the Core card.
- **Player benefit.** One card answers "where am I" and "what is next".
- **Social benefit.** Later, Core level is the number shown to other players, as Town Hall level is.
- **Economy impact.** None.
- **Progression impact.** A soft version of Clash's "place everything before advancing": the Core card lists machines unlocked but never built. It is a checklist, not a requirement.
- **UI needs.** A Core-card row "Unlocked, not yet built" with tap-to-place. An optional descend notice in the spirit of Clash's rushed-village warning [O] 11 ("Two unlocked machines were never built — descend anyway?"), one confirm, never a block.
- **Do not copy.** The name, the per-level Town Hall art ladder, the weapon or Guardian idea, Clash's unlock tables.

#### 10.2.2 The Worklist and a visible crew (from the Builder menu and idle builders)

- **Purpose.** Answer "what now?" in one tap, with no timers.
- **Input.** State the simulation already has: stalled machines, heat problems, quota progress, affordable research and machines, unbuilt unlocks.
- **Output.** A ranked list of 3–5 lines in a fixed, deterministic order (problems, then quota blockers, then research, then machines). Each line glides the camera to its tile, as the warning key already does; unaffordable lines are dimmed with the shortfall, like Clash's red costs [S] 59.
- **Player benefit.** Clash's strongest "what next" tool without its timer.
- **Social benefit.** None.
- **Economy impact.** None; it only points.
- **Progression impact.** Fewer stuck sessions.
- **UI needs.** One HUD key near the credits readout. Optionally two or three Foreman's workers stand at the top item's tile. This follows Telfer's "animations over timers" [S] 68a and replaces the sleeping-builder signal with a figure that points somewhere.
- **Builders as a mechanic: reject.** Builders only matter because construction takes time. Adding build time to Lodeworks just to make builders meaningful breaks "no timers". Tiles, heat, credits and the quota already force the decisions builders force in Clash.
- **Do not copy.** Builder figure, hut, "z" animation, "x/5" counter, the "Suggested upgrades / Other upgrades" wording and layout.

#### 10.2.3 Yard and strata expansion (from village growth)

- **Purpose.** Add Clash's diegetic locked state to the existing ring growth.
- **Input / output.** Depth in; out come sealed ground (already there for crystals and seams) plus one covered crate at the Core's edge per coming unlock band, tappable for its name and depth.
- **Player benefit.** Anticipation without reading, as with the broken castle and boat.
- **Social benefit.** None.
- **Economy / progression impact.** None.
- **UI needs.** One world prop per band.
- **Do not copy.** Ruins and moss art, boats and airships.

#### 10.2.4 Drills and the Vault (from collectors and storages)

- **Purpose.** Drills on seams already play the collector role. Lodeworks' Vault is a *seller*, so the suggested "storage → Vault" mapping would collide with an existing machine. Do not rename.
- **Input / output.** Unchanged.
- **Player benefit.** No chores: **do not add storage caps or tap-to-collect.** In Clash, filling collectors (mild guilt) and theft (loss) are return pressure [O] 49. The offline banking window, plus 4 hours with the licence, is already the collector-cap analogue; keep it the only cap.
- **Social benefit.** None.
- **Economy impact.** None.
- **Progression impact.** None.
- **UI needs.** Optionally make the return summary a one-tap "haul" moment (sound, numbers flying to the credit readout): a celebration, not a chore.
- **Do not copy.** Collector and storage art, the gold/elixir pair, the anti-banking refund rule (there is no raiding to guard against).

#### 10.2.5 Research (from the Laboratory)

- **Purpose.** Keep research instant; borrow only Clash's suggested research (Oct 2023) [O] 11.
- **Input / output.** The simulation marks the one card that would raise output most on the current board. It already computes green and red rule arrows per machine, so this is deterministic.
- **Player benefit.** Less guesswork.
- **Social benefit.** None.
- **Economy impact.** None.
- **Progression impact.** Smoother mid-game.
- **UI needs.** One highlight on the research grid.
- **Reject.** Research timers, a one-at-a-time queue, assistants and potions; they exist in Clash to be skipped [O] 17, 33.
- **Do not copy.** Lab art or wording.

#### 10.2.6 The Ledger (from Achievements and the Hero Journey, without the paid half)

- **Purpose.** Medium- and long-term goals that work offline.
- **Input.** Deterministic milestones with three marks each: "run a 5-step chain", "hold every machine in its band for 10 minutes", "reach stratum 10/20/30", "collapse for 50/200/1,000 Cores".
- **Output.** Cosmetics (Core plating, board-edge props, Foreman outfits), optionally mirrored as Google Play Games achievements [S] 73.
- **Player benefit.** Goals that never expire.
- **Social benefit.** Shown on a future profile.
- **Economy impact.** None if rewards stay cosmetic, which keeps the "only play moves the economy" tests true.
- **Progression impact.** Points players at under-used machines and rules. Clash's achievements track the same things as its challenges [S] 61.
- **UI needs.** A Ledger page; the main screen shows only the closest-to-done line.
- **Monthly track.** Adapt only with Clash's anti-guilt parts: cards that pile up "even if you don’t log in" [O] 27, no expiry within the month, fixed rewards, no paid side. Otherwise reject.
- **Do not copy.** Star and shield icons, "Season", "Gold Pass", "Hoggy Bank", Clash's task names and point values.

#### 10.2.7 Rock of the Week (from events)

- **Purpose.** A reason to open the game this week, with no obligation.
- **Input.** Strata are generated from depth, so a weekly seed can pick one special stratum and modifier pair that everyone gets identically.
- **Output.** A fixed cosmetic for reaching a stated output, a personal best, and later a leaderboard.
- **Player benefit.** New puzzles from existing data (the README's "one modifier is one row of data").
- **Social benefit.** Everyone plays the same rock, so results compare.
- **Economy / progression impact.** None; it is a side board.
- **UI needs.** A card on the Descend key or Core card showing the window. The deadline is a calendar window, not a timer on the player's factory.
- **Do not copy.** Event names, Event Pass, event currencies.

#### 10.2.8 Union (from Clans) — server

- **Purpose.** A persistent group.
- **Input.** Join or create; roles (e.g. Foreman, Shift Lead, Member). Size is a design choice (say 20–30), not Clash's 50.
- **Output.** A roster showing Core levels, a feed ("Ada reached stratum 20"), and the shared projects below.
- **Player benefit.** Help and belonging.
- **Social benefit.** Retention through people.
- **Economy impact.** Only through 10.2.9 and 10.2.11.
- **Progression impact.** Optional; nothing in the main game should need a Union.
- **UI needs.** Roster, feed, automatic leader hand-over after long inactivity (Clash: 60 days [O] 48). **Start without free-text chat.** Clash needs a word filter, family-friendly clans and young-player handling [O] 47. Preset signals ("Need Components", "Thanks", "Nice layout") give most of the value with no moderation. Google Play's user-generated-content rules were **not researched** and must be checked before any chat.
- **Do not copy.** "Clan", badges, castle, role names, the 50 cap.

#### 10.2.9 Requisitions (from donations) — server

- **Purpose.** Small, frequent generosity.
- **Input.** A member posts **one open request at a time** (no cooldown timer) for a material they cannot make yet. A helper fills it from their own production.
- **Output.** A fixed-size crate delivered once into a chosen machine's input; the helper earns Ledger progress and a "helped N times" stat.
- **Player benefit.** An early chain unblocked.
- **Social benefit.** The everyday social verb.
- **Economy impact.** Real but bounded. Cap crate size by the receiver's depth (Clash down-levels donations for lower Town Halls [O] 19) and make the helper pay from real output (Clash made donations cost resources in 2025 [O] 7). Run the econ tools first.
- **Progression impact.** Slightly faster early chains.
- **UI needs.** A request card in the feed and a fill button that shows its cost.
- **Do not copy.** Troop and spell requests, housing bars, "Donate".

#### 10.2.10 Factory Tours (from visiting) — no server needed

- **Purpose.** Learn from other layouts, and show off.
- **Input.** A share code: layout, depth and seed. (Correction, from the gap audit: blueprints do *not* save and load yet; only an empty slot list is saved. See docs/GAP-AUDIT.md A1 and B-5.)
- **Output.** A read-only board running in the viewer's own simulation, like a Codex page, plus "Copy to blueprint" (Clash has let you copy clanmates' layouts since 2018 [S] 58).
- **Player benefit.** Inspiration.
- **Social benefit.** The code travels through any messenger.
- **Economy impact.** None; a toured board earns nothing.
- **Progression impact.** Faster learning.
- **UI needs.** Share and import keys, a "Touring" banner, an exit key.
- **Do not copy.** The Visit UI and layout-link format.

#### 10.2.11 Union Works (from the Clan Capital) — server

- **Purpose.** A cooperative plant everyone builds.
- **Input.** Components and other products contributed straight from production. No conversion building and no crafting time: Clash's Forge ties up a builder for the whole conversion [O] 37, the timer to avoid.
- **Output.** Sections level up **instantly** when funded, as Clash's Capital does [O] 36. Each level gives a shared perk. A personal "Works reputation" survives leaving, as in Clash [O] 23.
- **Player benefit.** Surplus becomes something visible.
- **Social benefit.** One shared progress bar; leaders can mark a few priorities.
- **Economy impact.** Perks must not multiply output, or solo players fall behind. Keep them cosmetic or convenience (a blueprint slot, a Union plating), mirroring the rule that the IAP cannot move economy numbers.
- **Progression impact.** None on the main shaft.
- **UI needs.** Works screen with a funding bar per section and "what others are funding" (Clash's Builder Menu does this [O] 29, 36).
- **Do not copy.** Capital, districts, ruins, Capital Gold, Raid Medals, the Forge, houses.

#### 10.2.12 Output Trials (from Clan Wars / CWL; production, not combat)

- **Purpose.** Competition that compares rather than destroys or steals.
- **Input.** Every entrant builds on the **same seeded board** with the same budget and unlocks. The score is output over N *simulated* minutes: no waiting. The Union version: one layout per member in a week-long window; the sum decides, with a tie-breaker such as lowest heat loss.
- **Output.** Cosmetic placement medals, a Union rank, a board of top layouts anyone can Tour.
- **Player benefit.** A puzzle with a fair comparison.
- **Social benefit.** Strategy talk around layouts.
- **Economy / progression impact.** None with cosmetic rewards.
- **Anti-cheat.** The simulation is deterministic, so a server can re-run any layout and recompute its score. A no-server start can use Google Play Games leaderboards (daily, weekly and all-time versions, tamper protection built in [S] 73), which cannot re-run layouts.
- **UI needs.** A Trial card, an editor locked to the trial's machines, submit, results with Tour links.
- **Cadence.** A week-long window. Clash's CWL has one attack a day [O] 31, a daily obligation to avoid.
- **Do not copy.** War maps, stars, preparation and battle days, league names, "War".

#### 10.2.13 Second shaft (from the Builder Base)

The latest commit mentions "the path to more than one factory".

- **Purpose.** Something to do between main-shaft goals.
- **Input.** Its own rock and rule set (for example permanently cold or cramped) and its own quota.
- **Output.** Bridge rewards into the main shaft (a machine variant, a permanent small unlock), as B.O.B and Gear Up do in Clash [O] 14; [S] 58.
- **Player benefit.** Variety.
- **Social benefit.** None needed.
- **Economy impact.** Separate currencies, as in Clash, so one shaft cannot flood the other.
- **Progression impact.** Show the bridge rewards from day one, or the shaft gets ignored.
- **UI needs.** A shaft switcher on the Core card.
- **Do not copy.** Boat, Master Builder, versus battles, multi-stage attacks.

#### 10.2.14 Celebrations and the returning player

- **Purpose.** Mark real milestones; welcome people back without a streak.
- **Input / output.**
  - The loudest synthesised fanfare goes to four moments: Core growth, a new stratum, the first placement of a new machine, and Works level-ups (posted to the Union feed, as Clash posts clan level-ups [O] 20).
  - After a long absence (tune it; Clash uses 35 days [O] 39): one "while you were away" card, and optionally a catch-up gift claimed **all at once**. Clash's 7-day calendar needs daily logins [O] 39.
- **Player benefit.** Clear peaks; no shame for being away.
- **Social benefit.** Shared moments in the feed.
- **Economy impact.** Keep any catch-up below steady play, Clash's own rule [O] 39.
- **Progression impact.** None.
- **UI needs.** One return card; reuse the existing unlock card and Juice hooks.
- **Do not copy.** Login Calendar, Loot Cart, Magic Shield, the upgrade fanfare.

### 10.3 Clash mechanics that conflict with the Lodeworks stance

| Clash mechanic | Conflict | Recommendation |
|---|---|---|
| Upgrade timers + gem skips; Books, Hammers, Potions [O] 33 | "No timers"; nothing sold back | **Reject.** Keep instant placement and research. |
| Limited builders sold for gems [O] 16; tutorial pushes buying one [S] 50 | IAP must not move economy; no timers | **Reject.** Use the Worklist and crew signposting (10.2.2). |
| Helpers with a 23-hour work day [O] 17 | Daily ritual plus timer | **Reject.** |
| Gold Pass perks (cheaper, faster upgrades), paid track, Hoggy Bank x5 [O] 26, 40; [S] 56, 58 | One IAP; ads and IAP cannot touch the economy | **Reject the paid pass.** A free, stacking Survey track is optional (10.2.6). |
| Event Pass, Clan Gifts (buying gems for clanmates) [O] 26, 20b | Extra IAPs; paid social pressure | **Reject.** |
| Random chests on the free track [O] 27 | Deterministic rules, no gacha | **Reject.** Use fixed rewards only. |
| Clan Games challenge expiry + gem revive [O] 25 | Timer plus premium skip | **Adapt.** No per-challenge timer inside the event window; no revive. |
| Star Bonus 24-hour cooldown [O] 49 | Daily cadence | **Adapt or reject.** If used, make it stack generously (Clash stacks two); better, tie bonuses to milestones instead of the clock. |
| Login Calendar needing 7 consecutive days [O] 39 | Daily-login guilt | **Adapt.** Claim everything at once (10.2.14). |
| CWL one attack per day [O] 31 | Daily obligation | **Adapt.** One submission per week-long window (10.2.12). |
| Ranked inactivity demotion and decay [O] 44 | Punishes absence | **Adapt.** No decay, or show "inactive" without losing rank. |
| Raiding, loot theft, shields, revenge [O] 46, 49 | Nothing is taken away to be sold back; not a combat game | **Reject.** Production contests only. |
| Collector fill-up and storage caps as return pressure [O] 49 | Mild guilt | **Reject** beyond the existing offline window. |

### 10.4 Suggested order

Cheapest first, no server needed for the first two steps.

1. **Worklist and crew signposting (10.2.2), plus the Ledger with cosmetic rewards (10.2.6).** All client-side and deterministic. Together they close the gap where Clash is strongest: "what next" beyond the first chapter.
2. **Factory Tours by share code (10.2.10) and Rock of the Week (10.2.7).** Optionally add Play Games leaderboards. No backend.
3. **Unions, Requisitions, Union Works and Output Trials (10.2.8–10.2.12).** Only after deciding to run a backend. Start chat-less, and re-run the econ tools on Requisitions before shipping.
4. **Second shaft (10.2.13)** when the multi-factory work is ready, with bridge rewards designed first.

### 10.5 General "do not copy" rules

- **No Clash names.** Town Hall, Builder, Clan, Clan Castle, Capital, Raid, Gold Pass, Hoggy Bank, Trader, Chief, Villager, Goblin, Elixir, Gems, Magic Items.
- **No Clash art or art style cues.** Characters, huts, ruins, boats, airships, badges, star or shield icons.
- **No UI layouts, wording or sounds.** Including the upgrade fanfare.
- **No numbers.** Clan size 50, 5 builders, 10-minute cooldowns, 5 raid attacks, 7-day calendars, 35 and 90-day thresholds, reward tables. Tune every Lodeworks number with its own balance tools.
- **Copy principles, not surfaces.** One gate, a ranked worklist, world-state signals, teaching at first contact, accumulation instead of streaks, participation-based shared rewards, and competition that compares rather than takes.

---

## Not verified

- The current, post-2025 tutorial script and exact onboarding UI (arrow and highlight style). The dialogue quoted comes from the Fandom wiki, and its revision date is unknown [S] 50.
- The current starting-shield length. Guides say 3 days, but shields were reworked in Oct 2025.
- Exact HUD positions of resource bars and the Shop.
- Upgrade-completion animation and particle details.
- Clan Games scheduling (how often it runs, and its dates).
- Whether a Town Hall 19 exists as of 25 Sep 2026.
- The content of the GDC talks beyond the published summaries (the video transcripts were not retrieved).
- Google Play user-generated-content policy requirements for in-game chat.

---

## Sources

Official = Supercell (supercell.com, Supercell Support Portal, Supercell developers' own talks). Secondary = everything else. Support Portal articles are undated living pages, read 25 Sep 2026.

1. Clash of Clans Design Values — Supercell — https://supercell.com/en/games/clashofclans/blog/news/fpo-clash-of-clans-design-values/ — 6 Mar 2017 — official
2. TOWN HALL 18 Crash Lands! - Update — Supercell — https://supercell.com/en/games/clashofclans/blog/release-notes/town-hall-18-crash-lands-update/ — 17 Nov 2025 — official
3. THE TOWN HALL 17 UPDATE IS HERE! — Supercell — https://supercell.com/en/games/clashofclans/blog/game-updates/the-town-hall-17-update-is-here-2/ — 25 Nov 2024 — official
4. August Update — Supercell — https://supercell.com/en/games/clashofclans/blog/release-notes/august-update-3/ — 30 Aug 2026 — official
5. What's New? (September 2026) — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/whats-new-september-2026.html — Sep 2026 — official
6. May Update — Supercell — https://supercell.com/en/games/clashofclans/blog/release-notes/may-update/ — 26 May 2026 — official
7. Welcome to Clash Anytime Update! — Supercell — https://supercell.com/en/games/clashofclans/blog/release-notes/welcome-to-clash-anytime-update/ — 24 Mar 2025 — official
8. Get Ready for Ranked! - Update — Supercell — https://supercell.com/en/games/clashofclans/blog/release-notes/get-ready-for-ranked-update/ — 6 Oct 2025 — official
9. Battle and Ranked Modes Are Coming to Clash! — Supercell — https://supercell.com/en/games/clashofclans/blog/news/battle-and-ranked-modes-are-coming-to-clash-/ — 2 Sep 2025 — official
10. The State of Gameplay and What's Ahead — Supercell (Clash of Clans Design Team) — https://supercell.com/en/games/clashofclans/blog/news/the-state-of-gameplay-and-whats-ahead/ — 24 Mar 2026 — official
11. October Update Full Patch Notes — Supercell — https://supercell.com/en/games/clashofclans/blog/release-notes/october-update-full-patch-notes-2/ — 9 Oct 2023 — official
12. Clan Capital Full Release Notes — Supercell — https://supercell.com/en/games/clashofclans/blog/release-notes/clancapital-releasenotes/ — 2 May 2022 — official
13. Clan Capital Raids — Supercell — https://supercell.com/en/games/clashofclans/blog/game-updates/clan-capital-raids/ — 1 May 2022 — official
14. Builder Base 2.0: Layouts, Troop Levels and B.O.B! — Supercell — https://supercell.com/en/games/clashofclans/blog/news/builder-base-2-0-layouts-troop-levels-and-bob/ — 3 May 2023 — official
15. Full Patch Notes (Builder Base 2.0) — Supercell — https://supercell.com/en/games/clashofclans/blog/release-notes/full-patch-notes-bb2/ — 15 May 2023 — official
16. Builders & Builder's Huts — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/builders-4.html — official
17. Helpers & The Helper Hut — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/helpers-2.html — official
18. Raid Weekends — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/raid-weekends-3.html — official
18b. Canceling an Upgrade — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/canceling-an-upgrade.html — official
19. Clan Castle Troops & Spells — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-castle-troops-and-spells-2.html — official
20. Clan Perks — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-perks-3.html — official
20a. Capital Leagues — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/capital-leagues.html — official
20b. Clan Gifts — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-gifts.html — official
21. Clan Score and XP — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-score-and-xp.html — official
22. Defending the Capital — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/defending-the-capital-2.html — official
23. Rewards (Clan Capital) — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/rewards-2.html — official
23a. Friendly Challenges — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/friendly-challenges-3.html — official
24. About Clan Games — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-games.html — official
25. Clan Games Challenges and Points — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-games-challenges-and-points.html — official
26. Events & Event Pass — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/events-2.html — official; and Gold Pass — https://support.supercell.com/clash-of-clans/en/articles/gold-pass-4.html — official
26a. Clan Games Rewards — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-games-rewards.html — official
27. Season Tasks — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/season-tasks-3.html — official
28. Intro to Clan Wars — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/about-clan-wars-2.html — official
29. Clan Capital FAQ — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/frequently-asked-questions.html — official
30. About Clan War Leagues — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/about-cwl-3.html — official
31. Clan War Leagues Rewards — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-war-leagues-rewards-2.html — official; and The Week of Wars — https://support.supercell.com/clash-of-clans/en/articles/cwl-week-of-wars.html — official
32. Clan War Rewards — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-war-rewards-2.html — official
33. Magic Items & The Trader — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/magic-items-and-the-trader.html — official
34. The Fancy Shop — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/the-fancy-shop.html — official
35. What Is the Clan Capital? — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/what-is-the-clan-capital-3.html — official
36. Building the Capital — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/building-in-the-capital-3.html — official; and Work for Hire Event — https://support.supercell.com/clash-of-clans/en/articles/work-for-hire-event.html — official
37. The Forge — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/the-forge.html — official
37a. Clan Gold Rush — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-gold-rush.html — official
38. The Blacksmith: Hero Equipment & Ore — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/hero-equipment-ore-5.html — official
39. Login Calendar & Returning Boosts — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/login-calendar.html — official; and Participating in a Clan War — https://support.supercell.com/clash-of-clans/en/articles/participating-in-a-clan-war.html — official
39a. Clash Friends & the Social tab — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/using-the-social-tab.html — official
40. Hoggy Bank — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/hoggy-bank.html — official
41. About Heroes & Pets (Hero Hall, Hero Journey) — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/about-heroes-pets-9.html — official
42. Single Player Attacks — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/single-player-attacks-2.html — official
43. Battle vs Ranked Battle - What's the Difference? — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/battle-vs-ranked-battle-whats-the-difference.html — official
44. Ranked Leagues — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/ranked-leagues-4.html — official; and About Builder Base — https://support.supercell.com/clash-of-clans/en/articles/builder-base-the-basics-2.html and Sending Builders to Home Village — https://support.supercell.com/clash-of-clans/en/articles/builder-base-getting-master-builder-to-home-village-3.html — official
45. Intro to Legend League — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/legend-league-4.html — official
46. Revenge — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/revenge.html — official
47. Creating/Joining a Clan — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/joining-a-clan-3.html — official
48. Clan Roles — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/clan-roles-3.html — official
49. Loot and Star Bonus — Supercell Support — https://support.supercell.com/clash-of-clans/en/articles/about-multiplayer-and-trophies-2.html — official
50. Villager (tutorial and feature-tutorial dialogue) — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Villager — revision date unknown — secondary
51. Flammy's Strategy Guides / Total Newbie Guide — Clash of Clans Wiki (Fandom, community guide) — https://clashofclans.fandom.com/wiki/Flammy's_Strategy_Guides/Total_Newbie_Guide — date unknown (older) — secondary
52. Goblin King — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Goblin_King — secondary
53. Builder; Clan Perks — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Builder and https://clashofclans.fandom.com/wiki/Clan_Perks — secondary
54. Town Hall — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Town_Hall — secondary
55. Experience — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Experience — secondary
56. Season Challenges — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Season_Challenges — secondary
57. Practice Mode — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Practice_Mode — secondary
58. Version History (2012–2026 pages) — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Version_History — secondary
59. File: Suggested Upgrades.png (Builder menu screenshot) — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/File:Suggested_Upgrades.png — uploaded 19 Feb 2026 — secondary
60. File: Supercharge Interface.jpg (three-panel intro card) — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/File:Supercharge_Interface.jpg — uploaded 23 Dec 2024 — secondary
61. Achievements — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Achievements — secondary
62. Clans; FAQ and Support; Galadon's Strategy Guides/Tips and Tricks — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Clans , https://clashofclans.fandom.com/wiki/FAQ_and_Support , https://clashofclans.fandom.com/wiki/Galadon's_Strategy_Guides/Tips_and_Tricks — secondary
63. Scenery — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Scenery — secondary
64. Loot Cart — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Loot_Cart — secondary
65. Decorations — Clash of Clans Wiki (Fandom) — https://clashofclans.fandom.com/wiki/Decorations — secondary
66. Level up your live game with lessons from Supercell's Clash of Clans at GDC (Eino Joas, "Bigger, Better, Battle Pass") — Game Developer — https://www.gamedeveloper.com/production/level-up-your-live-game-game-with-lessons-from-supercell-s-i-clash-of-clans-i-at-gdc- — 25 Nov 2019 — secondary; talk itself: GDC Vault https://gdcvault.com/play/1026741/-Clash-of-Clans-Bigger (not viewed)
67. Mid-Core Success Part 1: Core Loops — Deconstructor of Fun (Jared Gibbons) — https://www.deconstructoroffun.com/blog//2013/10/mid-core-success-part-1-core-loops.html — 21 Oct 2013 — secondary
68. Free to Play Monetization: Making The First Purchase — Mobile Free To Play (Adam Telfer) — https://mobilefreetoplay.com/free-to-play-monetization-making-the-first-purchase/ — 7 Nov 2015 — secondary
68a. 3 Tips for Better Pacing — Mobile Free To Play (Adam Telfer) — https://mobilefreetoplay.com/3-tips-for-better-pacing-in-mobile-games/ — 29 Sep 2015 — secondary
69. Clash of Clans Earns $27 Million in One Week as Revenue Grows 145% Following Season Pass Debut — Sensor Tower (Randy Nelson) — https://sensortower.com/blog/clash-of-clans-gold-pass — Apr 2019 — secondary (estimate)
69a. Supercell's Battle Pass Clash: A Tale of Two Economies — Deconstructor of Fun (Jared Gibbons) — https://www.deconstructoroffun.com/blog/2020/7/16/8jsjtv3v25nfmw9x177ampscr836m0 — 2020 — secondary
70. Clash of Clans Game Lead Eino Joas' Design Talk explains the game roadmap — GamingOnPhone — https://gamingonphone.com/editorial/eino-joas-clash-of-clans-design-talk/ — 27 Apr 2020 — secondary
71. Clash of Clans upgrade sound (fan soundboard entry) — Myinstants — https://www.myinstants.com/en/instant/clash-of-clans-upgrade-sound-36691/ — date unknown — secondary (shows only that the sound is widely recognised)
72. Clash of Clans — Wikipedia — https://en.wikipedia.org/wiki/Clash_of_Clans — read 25 Sep 2026 — secondary
73. Leaderboards; Achievements — Android Developers (Google Play Games Services) — https://developer.android.com/games/pgs/leaderboards and https://developer.android.com/games/pgs/achievements — secondary for Clash, official for Google Play
74. Video: Making games you play for years — A Clash of Clans postmortem (Jonas Collaros, GDC 2015) — Game Developer — https://www.gamedeveloper.com/design/video-making-games-you-play-for-years---a-i-clash-of-clans-i-postmortem — 26 May 2015 — secondary coverage of an official Supercell talk
75. Lodeworks README — Lodeworks repository (Furkiozknn/lodeworks, branch visual/landscape-iso, commit 9f51cf0) — local file README.md — internal
76. Firedragon III's Strategy Guides / Town hall 2 — Clash of Clans Wiki (Fandom, community guide) — https://clashofclans.fandom.com/wiki/Firedragon_III's_Strategy_Guides/Town_hall_2 — date unknown — secondary
