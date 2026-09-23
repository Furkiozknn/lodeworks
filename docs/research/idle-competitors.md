# Idle / Incremental Competitor Research for **Lodeworks**

**Compiled:** 23 September 2026
**Scope:** The idle/incremental side of the genre — top-grossing and top-rated idle games on Google Play and their PC counterparts.
**Subject under design:** Lodeworks — Godot Android idle/factory game. 7×10 grid, machines feed orthogonal neighbours, heat as the spatial constraint, descend strata, prestige for Cores.

---

## 0. Method, and how to read this document

Every factual claim below is tagged with the source it came from. I have followed three rules:

1. **No invented figures.** Where a number appears, a URL is attached. Where I could not confirm something, it says **UNKNOWN**.
2. **Primary sources preferred.** Developer postmortems, official store listings, developer FAQs/press kits, and player threads outrank listicles. I have used no SEO content farms for any numeric claim.
3. **Source vs. inference is marked.** Lines beginning **[SOURCE]** are things I read. Lines beginning **[INFERENCE]** are my own reasoning from them.

**Two important limitations, stated up front:**

- **reddit.com was not reachable** from this research environment (fetches returned `SITE_BLOCKED`). The brief asked for reddit threads specifically; I substituted Steam Community discussions, Steam reviews, Google Play and App Store review text, and developer forums. This is a real gap — r/incremental_games sentiment is **UNVERIFIED** here and should be checked manually before any decision rests on it.
- **Store review quotes** are the reviews that were surfaced on the store page at fetch time. They are genuine verbatim text but they are **not a statistically representative sample** — store pages surface a curated/rotating subset. Treat them as evidence that a complaint *exists and is articulated in these words*, not as evidence of its frequency.
- **Revenue figures** for private companies (Kolibri, Auxbrain, LoadComplete) are **UNKNOWN**. Third-party estimates exist but I have not treated estimate-vendor numbers as fact. The only revenue-adjacent figures I report are ones a developer stated themselves or that a named analyst attributed and published.

---

## 1. Games actually examined, with evidence

### 1.1 Summary table

| Game | Platform / model | Verified key facts | Evidence source |
|---|---|---|---|
| **AdVenture Capitalist** (Hyper Hippo) | Mobile F2P + Steam; ads + IAP | "65% Lifetime D1 Retention"; 17M installs; 1B+ sessions; 100M+ ads served; "4.5 Average Lifetime Rating on All Platforms"; push notification CTR "5% – 10%"; launched Kongregate May 2014, mobile/Steam Q1 2015 | [GDC 2016 postmortem, Matthew Augustine, full text](https://archive.org/stream/GDC2016Augustine/GDC2016-Augustine_djvu.txt) |
| " | " | Opening business "Lemonade Stand": Buying Price **$3.74**, Profit per Unit **$1**, Profit Speed **0.5 second**, manager "Cabe Johnson ($1,000)", price increase modifier **1.07** | [AdVenture Capitalist Wiki – Lemonade Stand](https://adventure-capitalist.fandom.com/wiki/Lemonade_Stand) |
| " | " | Play Store: **4.5 stars, 1.65M reviews, 10M+ downloads**, contains ads | [Google Play](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google) |
| " | " | Ad-escalation complaints: *"Ads have become too intrusive...just even opening a menu would bring up an ad"*; *"I have to watch an ad to avoid an ad."* | [Google Play reviews](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google) |
| " | " | Endgame decay: *"I barely have to sign in once a day now"*; *"Logged in after 12 hours to click..... 1 oil rig"*; *"I need only around 10 years of playtime, to double my angels"* | [Steam discussion: "Nearing end-game... BORING"](https://steamcommunity.com/app/346900/discussions/0/490123938442169349/) |
| " | " | Angel Investors = prestige; each angel gives 2% profit bonus; community advises resetting at ~50–300 angels | [Steam discussion: "Angel Investors"](https://steamcommunity.com/app/346900/discussions/0/618459405712024885/) |
| **Idle Miner Tycoon** (Kolibri) | Mobile F2P; ads + IAP | Prototype **D1 retention 63%–81%** vs industry ~40%; **"60% of our revenue comes from ads"** (~40% IAP); players watch **"eight ads per session, per day"**; session length **~10 minutes**; 160+ updates since July 2016; staged rollout 1%/5%/20%/100%; event mines sometimes "doubling revenue for a weekend" | [GameAnalytics — "Making a Hit Idle Game: Eight Lessons from Kolibri Games" (Nate Barker)](https://www.gameanalytics.com/blog/making-a-hit-idle-game-eight-lessons-from-kolibri-games) |
| " | " | Core loop shown on ONE screen — Mine → Transport → Sell → Upgrade — with visible "choke points" between each stage | same |
| " | " | Play Store: **4.6 stars, 5.37M reviews, 100M+ downloads**, contains ads, IAP includes random items | [Google Play](https://play.google.com/store/apps/details?id=com.fluffyfairygames.idleminertycoon) |
| " | " | Pop-up load complaints: *"It takes me nearly a full minute to hit X's on all of the pop up offers this game is trying to sell me."*; *"You have to close 20+ ads when you open the game to even get to the game itself...every, single, time."* | [Google Play reviews](https://play.google.com/store/apps/details?id=com.fluffyfairygames.idleminertycoon) |
| **Egg, Inc.** (Auxbrain) | Mobile F2P; opt-in ads + IAP | Play Store **4.7 stars, 1.31M reviews, 10M+ downloads**; App Store **4.8/5, 561K ratings** | [Google Play](https://play.google.com/store/apps/details?id=com.auxbrain.egginc) / [App Store](https://apps.apple.com/app/993492744) |
| " | " | Full IAP ladder: **Pro Permit $9.99**; Crack open Piggy $5.99; Break Open Piggy $3.99; ULTRA Pro $7.99; ULTRA $3.99; Truckload of Golden Eggs $19.99; Pallet $9.99; Crate $4.99; Ticket Roll $7.99; Ticket Stacks $3.99 | [App Store IAP list](https://apps.apple.com/app/993492744) |
| " | " | Developer on prestige: *"Soul eggs increase the earnings bonus which allows one to progress further in the game."* | [Auxbrain official support](https://auxbrain.freshdesk.com/support/solutions/articles/47001170226-what-are-soul-eggs-for-) |
| " | " | Prestige resets to first egg and forfeits cash, but **retains** golden eggs, soul eggs, eggs of prophecy and epic research; released 14 July 2016 | [Wikipedia: Egg, Inc.](https://en.wikipedia.org/wiki/Egg,_Inc.) |
| " | " | Ads framed as purely opt-in: *"you don't have to watch an ad every 5 minutes, infact you arent forced for any ad"* | [Google Play review, SirGiraffe Bob](https://play.google.com/store/apps/details?id=com.auxbrain.egginc) |
| " | " | Paywall friction: *"youre kind of cornered into paying to make tangible progress after a certain point, and a lot of basic QoL features are locked behind a Pro Permit."* | [Google Play review, kris](https://play.google.com/store/apps/details?id=com.auxbrain.egginc) |
| " | " | Contracts (the day-7+ retention engine): require **1,000+ Soul Eggs**, co-op pools all participants' eggs, graded **C/B/A/AA/AAA**; wiki notes players report needing to *"disrupt their sleep schedule"* for competitive play | [Egg Inc Wiki — Contracts](https://egg-inc.fandom.com/wiki/Contracts) |
| **Melvor Idle** (Games by Malcs) | Steam **$9.99** premium, no ads | 3 DLC at **$4.99 each** (Into the Abyss, Atlas of Discovery, Throne of the Herald); **92% of 8,610** reviews positive; released 18 Nov 2021 after EA from 19 Nov 2020 | [Steam store page](https://store.steampowered.com/app/1267910/Melvor_Idle/) |
| " | " | Official wiki: *"Offline Progression time is currently capped at 24 hours."* Farming does **not** progress offline; combat works offline since v0.21 | [Melvor wiki — Offline Progression](https://wiki.melvoridle.com/w/Offline_Progression) |
| " | " | Historic caps of **12h then 18h** are referenced in player threads — cap has been raised over time | [Steam discussion](https://steamcommunity.com/app/1267910/discussions/0/3192493998739513526/) |
| " | " | Offline-cap backlash: *"This means that you are REQUIRED to interact with this game EVERY SINGLE DAY in order to maintain character progression."*; *"The cap sucks if you have a life."*; *"I paid MONEY for the game. I should be able to play it how I want."*; *"I've finally lost interest in the game because of the minuscule offline time gains"* | [Steam: "Offline Progress Maxed at 18 Hours"](https://steamcommunity.com/app/1267910/discussions/0/4665175132461478006/) / [Steam: "Maximum offline progression - WHY?"](https://steamcommunity.com/app/1267910/discussions/0/3192493998739513526/) |
| " | " | Onboarding friction + monetisation praise: *"Hard game to get into, however once you get into it the game gets addicting."*; *"The number of systems may initially feel overwhelming"*; *"No Pay-to-win, no pay-to-skip, no pay-to-progress faster"* | [Steam reviews](https://steamcommunity.com/app/1267910/reviews/) |
| **Idle Slayer** (Pablo Leban) | Mobile F2P + Steam F2P; opt-in ads | Press kit: *"No upfront cost, and no forced ads interrupting your adventure"*; *"Earn rewards even when the game is closed"*; **10M+ downloads, 60K+ Discord, 30K+ Reddit**; 4.7 Google Play / 4.8 App Store / 86% Steam | [Idle Slayer press kit](https://idleslayer.com/press-kit) |
| " | " | App Store: **4.8, 28,000 ratings**. **Remove Ads $9.99**; **Remove Ads 1 Month $3.99**; Jewels of Soul tiers **$1.99 / $4.99 / $9.99 / $19.99 / $34.99 / $49.99 / $99.99**; Slayers Starter Pack $4.99 | [App Store](https://apps.apple.com/us/app/idle-slayer-addictive-clicker/id1526599527) |
| " | " | Ad framing, stated on the store listing: *"There are no forced ads in this game, every advertisement that you can watch helps double your offline earnings"* and gives "second chances in bonus stages" | same |
| " | " | Long-horizon prestige works: *"It took me 108 days to Ultra Ascend, and it was worth it. I rarely play a mobile game for this long, but this one has me hooked."* | [Google Play review](https://play.google.com/store/apps/details?id=com.pabloleban.IdleSlayer) |
| " | " | But event grind backfires: one reviewer objects to weekly challenges requiring *"FIFTY FIVE separate hours within a week to complete"*, which gate story progression | same |
| " | " | Steam: free-to-play, **78% of 4,297** reviews positive, 651 achievements | [Steam store page](https://store.steampowered.com/app/1353300/Idle_Slayer/) |
| **Antimatter Dimensions** (Hevipelle / Kajfosz) | Steam F2P; mobile F2P | Steam **Very Positive, 91% of 3,399**; released 17 Dec 2022; describes *"An obscene amount of automation, including a custom scripting language"* | [Steam store page](https://store.steampowered.com/app/1399720/Antimatter_Dimensions/) |
| " | " | Play Store **4.8, 35.5K reviews, 1M+ downloads**, contains ads | [Google Play](https://play.google.com/store/apps/details?id=kajfosz.antimatterdimensions) |
| " | " | Player on the ad model: *"No forced ads, but you can multiply the antimatter earning rate by 2x, but progress with no spending and no ad watching is 100% doable at a reasonable rate."* Another reports finishing in **110 days at 15–30 min/day** | same |
| " | " | Mid-game pacing complaint: *"good but too slow after 3rd col in infinity"*; onboarding complaint: *"I did not understand anything"* | [Steam reviews](https://steamcommunity.com/app/1399720/reviews/) |
| **NGU IDLE** (Somethingggg) | Steam F2P | **95% of 10,900** reviews positive. Developer's stated monetisation ethic: *"Premium currency you can PASSIVELY OBTAIN at a decent pace, without paying a cent. Only toss me some cash because you want to, not because you need to."* Positioned as *"A mix of Idle and Active play"* | [Steam store page](https://store.steampowered.com/app/1147690/NGU_IDLE/) |
| " | " | Extreme retention in evidence: reviewers with **8,449 hrs** and **18,034 hrs** logged | [Steam reviews](https://steamcommunity.com/app/1147690/reviews/) |
| **Leaf Blower Revolution** (Humble North) | Steam F2P + paid DLC | **94% of 22,591** reviews positive; DLC **$3.99–$24.99**; 30+ leaves, 38+ shops, 40+ areas, 32+ pets | [Steam store page](https://store.steampowered.com/app/1468260/Leaf_Blower_Revolution__Idle_Game/) |
| " | " | **The single most important prestige quote found in this research:** *"Restarting the game for the rewards felt like a stake to the heart every single time."* | [Steam reviews](https://steamcommunity.com/app/1468260/reviews/) |
| " | " | Also: *"The only real way to advance is by having gems."*; *"It feels much better to play it for a short amount of time rather than a long time because it is the same slop over and over again."*; counterpoint: *"you dont have to spend a cent on this game, as all paid progression rewards are obtainable otherwise, fairly easily."* | same |
| **Bitburner** (danielyxie) | Steam F2P, open source | **94% of 6,025** reviews positive; *"Write scripts in JavaScript to automate your gameplay"*; 100+ Augmentations serve as the prestige layer | [Steam store page](https://store.steampowered.com/app/1812820/Bitburner/) |
| **Cookie Clicker (mobile)** (Orteil & Opti / DashNet) | Two SKUs: free w/ ads, paid ad-less | Free: **4.4, 38K reviews, 5M+ downloads**, contains ads. Ad-less: **4.5, 479 reviews, 10K+ downloads**. *"Saves can be exported from one version to the other!"* **Exact ad-less price: UNKNOWN** (not displayed on the fetched listing) | [Google Play free](https://play.google.com/store/apps/details?id=org.dashnet.cookieclicker) / [Google Play ad-less](https://play.google.com/store/apps/details?id=org.dashnet.cookieclickeradless) |
| " | " | Ads described by players as unobtrusive: *"minimal ads. (There are non invasive banner ads at the bottom.)"*; *"banner ads at the bottom of the screen but they're unobtrusive."* | same |
| " | " | Endgame drop-off: *"The game is great, right up till you get to the last 10% of progress then it slows down to such an extent it stops being fun."* | [Google Play ad-less reviews](https://play.google.com/store/apps/details?id=org.dashnet.cookieclickeradless) |
| **Realm Grinder** (Divine Games) | Steam + mobile | Developer diary shows continual pacing relief: *"A lot of time-based requirements have been reduced throughout all game stages"* (21 Mar 2025); *"Reincarnation gems requirement and Coins required per Gem have been streamlined throughout all Ascensions except Ascension 0"* (21 Mar 2025); design ethic *"we are players ourselves first and foremost"* (20 May 2025) | [Divine Games developer diary](https://www.divinegames.it/discuss/viewtopic.php?id=395&p=8) |
| " | " | Complexity backlash: *"you have to read the wiki to find out how to unlock them"*; *"I do not have the free time to datamine and figure out which builds do what"* (1,500+ hr player); *"a slog through near-identical reincarnations, following a script from the wiki. Almost every unlock is a simple time gate."* | [Steam negative reviews](https://steamcommunity.com/app/610080/negativereviews/) |
| " | " | Daily-login monetisation backlash: *"we have reached 'Give us ten bucks so you can get bonusses when logging in every day'—so... paying for dailies."* | same |
| **Idle Planet Miner** (Tech Tree Games) | Mobile F2P; ads + IAP | App Store **4.7 (9.8K ratings)**. IAP: **Remove Ads $9.99**; Miner Pass $14.99; Starter Pack $9.99; Epic Pack $29.99; Manager Pack $19.99; Merchant Pack $29.99; Dark Matter packs $4.99–$9.99 | [App Store](https://apps.apple.com/us/app/idle-planet-miner/id1441880123) |
| " | " | **Offline capacity is itself an upgrade**: *"At first it can harvest for 2 hours before needing checked then as you progress you can unlock more time to that."* | [Boris Plays Games player review](https://borisplaysgames.wordpress.com/2019/03/26/mobile-idle-planet-miner/) |
| " | " | Opt-in ads read as generosity: *"Developers like these deserve our money when they don't force ads"* | [App Store reviews](https://apps.apple.com/us/app/idle-planet-miner/id1441880123) |
| **Legend of Slime** (LoadComplete) | Mobile F2P; ads + IAP | Play Store **3.9 stars, 177K reviews, 10M+ downloads**, contains ads, IAP with random items. Note this is **the lowest-rated game in this sample** | [Google Play](https://play.google.com/store/apps/details?id=com.loadcomplete.slimeidle) |
| " | " | Dominant complaint is misleading UA creative: *"Just make the game in the ads...OR show real gameplay. If I'd seen real gameplay for this one, I'd have tried it out."* Plus ad fatigue: *"20 ads for Cell Survivor in an hour makes me want to download it less and less."* | same |
| **Universal Paperclips** (Frank Lantz) | Free web; no monetisation | **450,000 players completed it within the first 11 days** of launch. Three phases: manual clicking → market/AI takeover → space probes and value drift | [Wikipedia: Universal Paperclips](https://en.wikipedia.org/wiki/Universal_Paperclips) |
| " | " | Opens on literally *"Paperclips: 0"* and a single clickable button; *"Introducing new currencies, systems, or rules at key milestones gave players new things to strategize about"* | [if50 essay: 2017 Universal Paperclips](https://if50.substack.com/p/2017-universal-paperclips) |
| " | " | Lantz on why the genre works: *"There's no external reason you would want to make this number go up in any clicker game, except that it's fun to make this number go up."* | [Y Combinator interview with Frank Lantz](https://www.ycombinator.com/blog/frank-lantz-director-of-nyus-game-center-and-creator-of-universal-paperclips/) |
| **Kittens Game** (bloodrizer) | Free web; donation | Opens with the single line *"You are a kitten in a catnip forest."* Self-described tagline: *"a Dark Souls of incremental gaming"* | [kittensgame.com](https://kittensgame.com/web/) |
| **Trimps** (Greensatellite) | Free web | Designer-reviewer's onboarding verdict: *"The first hour of gameplay was just me figuring out what all the buttons on my screen do."* | [Game Developer — Incremental Game Review: Trimps](https://www.gamedeveloper.com/design/incremental-game-review-trimps) |
| **Idle Theme Park Tycoon** (Digital Things) — *added; direct structural analogue* | Mobile F2P | Designer's minute-by-minute teardown: *"I was not able to interact with the game for the first minute, but it helped me to understand the core principle."* NPC "Investor Johnson" walks the visitor journey (parking → tickets → attractions → revenue). UI verdict: one word, *"FRICTION."* On rewarded video: reward value is unreadable ("33 visitors"), and an ad should yield **more than one minute of natural gameplay** | [Martin Jurasek — "900 seconds with Idle Theme Park Tycoon"](https://martinjurasek.substack.com/p/900-seconds-with-idle-theme-park) |
| **Idle Bank Tycoon** (Kolibri) — *added; same studio, documented ad design* | Mobile F2P | *"2x Ad Boost. Doubles the player's income for 2 hours per ad view"*; *"Welcome Back. Offers a choice to the returning player: increase idle income by 2x for watching an RV or 3x for spending hard currency"*; lootbox "up to 5 times, with a new chest available every 2 hours"; **players retain soft currency across prestige** | [PocketGamer.biz deconstruction](https://www.pocketgamer.biz/game-analysis-deconstructing-idle-bank-tycoon-by-kolibri-games/) |
| **Hybrid-casual / Survivor.io cohort** — *added for monetisation benchmarks* | Mobile F2P | Revenue splits: **Dreamdale 63/37 in favour of ads**; **Mob Control ≈$9M ad vs ≈$1.65M IAP (July, worldwide)**; **Survivor.io 65/35 in favour of IAP** (≈$40M IAP vs est. $15–30M ads, October). **D30 retention (iOS US): Dreamdale 2.64%, Survivor.io ~3–4%, Mob Control ~4–5%.** Dreamdale sells "Reward Tickets" at **$6.99 for 40** to skip ads — ~6% of store revenue | [Naavik — The Evolution of Hybridcasual](https://naavik.co/deep-dives/evolution-of-hybridcasual-deepdive/) |
| **Genre benchmarks** | — | Idle games show **18% stickiness vs 10.5%** for other hyper-casual titles; average session **~8 minutes** | [GameAnalytics — How to Make an Idle Game](https://www.gameanalytics.com/blog/how-to-make-an-idle-game-adjust) |
| **Academic grounding** | — | CHI 2018 taxonomy of 76 idle games (Alharthi et al.). Defines the genre as one where *"waiting is playing"*; identifies that idle games uniquely *"reward players for waiting"*; notes Trimps and Kittens *"gradually unlock features to prevent interface overwhelming"*, while poorly designed games *"were often unplayable despite sound mechanics"* | [par.nsf.gov/servlets/purl/10061230](https://par.nsf.gov/servlets/purl/10061230) |
| " | — | FDG '19 study of 11 idle games (Villareale et al., Drexel). Core cycle = **Active Participation → Inactive Progress → Return Rewards**. *"Highlighting how the game state has changed since the last time the player left"* appeared in **all 11 games examined** | [par.nsf.gov/servlets/purl/10188033](https://par.nsf.gov/servlets/purl/10188033) |

### 1.2 What I could not verify

| Question | Status |
|---|---|
| Revenue / DAU for Kolibri, Auxbrain, LoadComplete, Tech Tree Games | **UNKNOWN** — private; no developer-stated figures found |
| Exact price of Cookie Clicker ad-less Android SKU | **UNKNOWN** — not displayed on the listing fetched |
| Idle Miner Tycoon's exact offline-earnings duration/cap and rate | **UNKNOWN** — the official Kolibri help centre pages fetched did not state it; the fan wiki does not either |
| Egg, Inc. offline-earnings cap and silo capacity numbers | **UNKNOWN** — not stated in the developer FAQ pages fetched |
| Whether r/incremental_games consensus matches these findings | **UNVERIFIED** — reddit.com inaccessible from this environment |
| Melvor's *current* cap: wiki says 24h, player threads cite 18h and 12h | **PARTIALLY RESOLVED** — wiki (24h) is the most current source; the lower figures are historical |
| AdVenture Capitalist's current ad-removal subscription price | **UNKNOWN** — a Play review mentions "$15/month" but this is a player's claim, not a store-listed price, and I have not treated it as confirmed |

---

## 2. The ten patterns that recur across the successful games

### Pattern 1 — The first screen is one loop, fully visible, with no menus
**[SOURCE]** Kolibri's stated lesson #4 is literally "Show the Core Gameplay Loop on One Screen": Idle Miner Tycoon displays all four stages — Mine, Transport, Sell, Upgrade — with visible *"choke points"* between each ([GameAnalytics](https://www.gameanalytics.com/blog/making-a-hit-idle-game-eight-lessons-from-kolibri-games)). Universal Paperclips opens on *"Paperclips: 0"* and one button ([if50](https://if50.substack.com/p/2017-universal-paperclips)). Kittens Game opens on one sentence ([kittensgame.com](https://kittensgame.com/web/)).
**[INFERENCE]** The visible bottleneck is the teaching device. A player who can *see* where throughput is being lost knows what to buy next without being told.

### Pattern 2 — First meaningful purchase lands in the first ~10 seconds, and it is cheap and obvious
**[SOURCE]** AdVenture Capitalist's Lemonade Stand costs **$3.74**, returns **$1 per 0.5 second cycle** ([wiki](https://adventure-capitalist.fandom.com/wiki/Lemonade_Stand)). The player can afford a second unit almost immediately.
**[INFERENCE]** The opening price point is deliberately set below the first few seconds of manual output, so the first upgrade is a formality rather than a decision. The *decision* comes later.

### Pattern 3 — Automation is the first emotional beat, and it is sold as a named, one-time unlock
**[SOURCE]** AdVenture Capitalist's first manager is a *person* with a name — "Cabe Johnson ($1,000)" ([wiki](https://adventure-capitalist.fandom.com/wiki/Lemonade_Stand)). Kolibri's whole loop is built around managers ([IdleMinerTycoon wiki](https://idleminertycoon.fandom.com/wiki/Mining_Strategies): *"Always use Super Managers and Managers"*). Antimatter Dimensions advertises *"An obscene amount of automation, including a custom scripting language"* as a headline feature ([Steam](https://store.steampowered.com/app/1399720/Antimatter_Dimensions/)); Bitburner's entire pitch is *"Write scripts in JavaScript to automate your gameplay"* ([Steam](https://store.steampowered.com/app/1812820/Bitburner/)).
**[INFERENCE]** The moment a player stops tapping is the moment the game becomes an idle game. Successful titles make that a *purchase with a name attached*, not a silent threshold.

### Pattern 4 — The return screen is a celebration, present in literally every game studied
**[SOURCE]** The FDG '19 study found *"highlighting how the game state has changed since the last time the player left"* in **all 11** idle games analysed ([par.nsf.gov](https://par.nsf.gov/servlets/purl/10188033)). The CHI 2018 taxonomy frames the genre's defining move as rewarding players *for waiting* ([par.nsf.gov](https://par.nsf.gov/servlets/purl/10061230)). Idle Bank Tycoon's is explicit: *"Welcome Back. Offers a choice to the returning player: increase idle income by 2x for watching an RV or 3x for spending hard currency"* ([PocketGamer.biz](https://www.pocketgamer.biz/game-analysis-deconstructing-idle-bank-tycoon-by-kolibri-games/)).
**[INFERENCE]** This is the single most universal mechanic in the genre. It is also the natural home of the least-resented ad.

### Pattern 5 — Offline capacity is treated as a progression resource, not a fixed constant
**[SOURCE]** Idle Planet Miner: *"At first it can harvest for 2 hours before needing checked then as you progress you can unlock more time to that"* ([player review](https://borisplaysgames.wordpress.com/2019/03/26/mobile-idle-planet-miner/)). Melvor raised its cap from 12h → 18h → 24h over time ([wiki](https://wiki.melvoridle.com/w/Offline_Progression), [Steam threads](https://steamcommunity.com/app/1267910/discussions/0/3192493998739513526/)).
**[INFERENCE]** Making the cap upgradeable converts the genre's most-hated constraint into a reward track. Melvor demonstrates the opposite: a cap presented as a fixed rule generates sustained, articulate anger (see Complaint 1).

### Pattern 6 — Prestige keeps something visible and permanent, and the retained thing has its own display
**[SOURCE]** Egg, Inc. resets cash and eggs but **retains golden eggs, soul eggs, eggs of prophecy and epic research** ([Wikipedia](https://en.wikipedia.org/wiki/Egg,_Inc.)), and the developer describes soul eggs in pure upside terms: *"Soul eggs increase the earnings bonus which allows one to progress further in the game"* ([Auxbrain](https://auxbrain.freshdesk.com/support/solutions/articles/47001170226-what-are-soul-eggs-for-)). Idle Bank Tycoon lets *"players retain their soft currency when advancing to a new Prestige level"* ([PocketGamer.biz](https://www.pocketgamer.biz/game-analysis-deconstructing-idle-bank-tycoon-by-kolibri-games/)). AdVenture Capitalist's angels each give a flat, legible 2% ([Steam](https://steamcommunity.com/app/346900/discussions/0/618459405712024885/)).
**[SOURCE — the counter-example]** Leaf Blower Revolution, where prestige is not cushioned: *"Restarting the game for the rewards felt like a stake to the heart every single time."* ([Steam reviews](https://steamcommunity.com/app/1468260/reviews/))
**[INFERENCE]** The difference between a beloved prestige and a hated one is whether the player can see the permanent gain *before* confirming the reset.

### Pattern 7 — New systems are drip-fed at milestones, never presented at once
**[SOURCE]** The CHI 2018 taxonomy singles out Trimps and Kittens for *"gradually unlock[ing] features to prevent interface overwhelming"*, noting other games *"were often unplayable despite sound mechanics"* ([par.nsf.gov](https://par.nsf.gov/servlets/purl/10061230)). The Universal Paperclips analysis: *"Introducing new currencies, systems, or rules at key milestones gave players new things to strategize about"* ([if50](https://if50.substack.com/p/2017-universal-paperclips)).
**[SOURCE — failure mode]** Where this is skipped, players bounce: Trimps' *"first hour ... was just me figuring out what all the buttons on my screen do"* ([Game Developer](https://www.gamedeveloper.com/design/incremental-game-review-trimps)); Melvor's *"The number of systems may initially feel overwhelming"* ([Steam](https://steamcommunity.com/app/1267910/reviews/)); Antimatter Dimensions' *"I did not understand anything"* ([Steam](https://steamcommunity.com/app/1399720/reviews/)).

### Pattern 8 — The highest-rated games make every ad opt-in, and say so in the store listing
**[SOURCE]** Compare ratings against ad policy:
- Idle Slayer — *"There are no forced ads in this game, every advertisement that you can watch helps double your offline earnings"* → **4.8 App Store** ([App Store](https://apps.apple.com/us/app/idle-slayer-addictive-clicker/id1526599527)); press kit repeats *"no forced ads interrupting your adventure"* ([press kit](https://idleslayer.com/press-kit)).
- Egg, Inc. — *"you don't have to watch an ad every 5 minutes, infact you arent forced for any ad"* → **4.7 Play / 4.8 App Store**.
- Antimatter Dimensions — *"No forced ads"* → **4.8 Play**.
- Idle Planet Miner — *"Developers like these deserve our money when they don't force ads"* → **4.7 App Store**.
- Against: AdVenture Capitalist — *"just even opening a menu would bring up an ad"* → **4.5 Play**. Legend of Slime, whose reviews are dominated by ad complaints → **3.9 Play**, lowest in the sample.
**[INFERENCE]** The correlation across this sample is striking and consistent, though the sample is small and other factors (genre, age, UA strategy) are uncontrolled. The *stated policy* appears to be worth rating points in itself, because players quote it back approvingly.

### Pattern 9 — Ads are monetised at ~60% of revenue by volume leaders, but the placement is the whole game
**[SOURCE]** Kolibri state plainly: *"60% of our revenue comes from ads"*, with players watching *"eight ads per session, per day"* across ~10-minute sessions ([GameAnalytics](https://www.gameanalytics.com/blog/making-a-hit-idle-game-eight-lessons-from-kolibri-games)). Naavik's hybrid-casual data shows the split is a design *choice*, not a genre constant: Dreamdale 63/37 toward ads; Survivor.io 65/35 toward IAP ([Naavik](https://naavik.co/deep-dives/evolution-of-hybridcasual-deepdive/)).
**[SOURCE]** The quality bar for a rewarded ad is stated concretely by Jurasek: the reward should exceed **one minute of natural gameplay**, and the reward value must be *legible* — "33 visitors" fails because the player cannot price it ([900 seconds](https://martinjurasek.substack.com/p/900-seconds-with-idle-theme-park)).
**[INFERENCE]** Eight opt-in ads per session is not what players complain about. Twenty pop-ups at cold-start is. The same volume of advertising can produce a 4.8 or a 3.9 depending entirely on whether the player chose it.

### Pattern 10 — Day-7 retention is carried by a *social or timed layer* bolted on top of the idle loop
**[SOURCE]** Egg, Inc. gates Contracts behind **1,000 Soul Eggs** — i.e. they unlock only after the player has already prestiged repeatedly — then pools co-op production and grades players C→AAA ([Egg Inc Wiki](https://egg-inc.fandom.com/wiki/Contracts)). Kolibri run limited-time event mines that sometimes **double weekend revenue**, plus season passes, across 160+ updates ([GameAnalytics](https://www.gameanalytics.com/blog/making-a-hit-idle-game-eight-lessons-from-kolibri-games)). Idle Slayer runs weekly challenges ([Play Store](https://play.google.com/store/apps/details?id=com.pabloleban.IdleSlayer)).
**[SOURCE — the tax]** This layer is also where the manipulation complaints concentrate: Egg Inc players *"disrupt their sleep schedule"*; Idle Slayer's weekly challenge demands *"FIFTY FIVE separate hours within a week"*; Realm Grinder players resent *"paying for dailies"* ([Steam](https://steamcommunity.com/app/610080/negativereviews/)).
**[INFERENCE]** The timed layer is the strongest D7 tool in the genre *and* the most reliable source of resentment. Games that survive it make the layer optional and non-gating; games that gate content behind it get punished in reviews.

---

## 3. The five most common player complaints

### Complaint 1 — Offline caps that force a daily login (most articulate anger found)
**[SOURCE]** Melvor Idle: *"This means that you are REQUIRED to interact with this game EVERY SINGLE DAY in order to maintain character progression."*; *"The cap sucks if you have a life."*; *"I've finally lost interest in the game because of the minuscule offline time gains"*; *"I paid MONEY for the game. I should be able to play it how I want."* ([Steam](https://steamcommunity.com/app/1267910/discussions/0/4665175132461478006/), [Steam](https://steamcommunity.com/app/1267910/discussions/0/3192493998739513526/))
**[INFERENCE]** The grievance is not the cap's *length* — it is that a cap shorter than a sleep-plus-workday cycle converts an idle game into a chore with a deadline. 24h is defensible; 12–18h is not, because it drifts out of sync with a human day.

### Complaint 2 — Ad walls at cold-start, and pop-up stacks before the game is reachable
**[SOURCE]** Idle Miner Tycoon: *"It takes me nearly a full minute to hit X's on all of the pop up offers this game is trying to sell me."*; *"You have to close 20+ ads when you open the game to even get to the game itself...every, single, time."* ([Play Store](https://play.google.com/store/apps/details?id=com.fluffyfairygames.idleminertycoon)). AdVenture Capitalist: *"Ads have become too intrusive...just even opening a menu would bring up an ad"*; *"I have to watch an ad to avoid an ad."* ([Play Store](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google)). Legend of Slime: *"20 ads for Cell Survivor in an hour"* ([Play Store](https://play.google.com/store/apps/details?id=com.loadcomplete.slimeidle)).
**[INFERENCE]** Note the specific structure of the grievance: it is about ads and offers appearing *between the player and the game*, at the moment of return — precisely the moment Pattern 4 says should be a celebration.

### Complaint 3 — Hitting a wall where progress stops being legible
**[SOURCE]** AdVenture Capitalist: *"Logged in after 12 hours to click..... 1 oil rig"*; *"I need only around 10 years of playtime, to double my angels"*; *"It's not possible to get to the end of the earth campaign, without cheating"* ([Steam](https://steamcommunity.com/app/346900/discussions/0/490123938442169349/)). Cookie Clicker: *"great, right up till you get to the last 10% of progress then it slows down to such an extent it stops being fun"* ([Play Store](https://play.google.com/store/apps/details?id=org.dashnet.cookieclickeradless)). Antimatter Dimensions: *"too slow after 3rd col in infinity"* ([Steam](https://steamcommunity.com/app/1399720/reviews/)). Clicker Heroes: *"nothing I do boosts my damage enough to matter"* ([Steam](https://steamcommunity.com/app/363970/discussions/0/6361980659850940161/)).
**[INFERENCE]** In the Clicker Heroes thread, the community's answer to the wall is always *"you should have prestiged"*. The wall is therefore usually a **signposting failure**, not a tuning failure — the game did not tell the player that the reset was the intended move.

### Complaint 4 — Tedium and sameness; prestige that feels like punishment
**[SOURCE]** Leaf Blower Revolution: *"Restarting the game for the rewards felt like a stake to the heart every single time."*; *"It feels much better to play it for a short amount of time rather than a long time because it is the same slop over and over again."*; *"As time passed, it became extremely boring. It started to feel like I was doing the same thing over and over again."* ([Steam](https://steamcommunity.com/app/1468260/reviews/)). Realm Grinder: *"a slog through near-identical reincarnations, following a script from the wiki. Almost every unlock is a simple time gate."* ([Steam](https://steamcommunity.com/app/610080/negativereviews/)). Idle Miner Tycoon: the game *"gets old after a while endlessly trying to upgrade mines"* ([Play Store](https://play.google.com/store/apps/details?id=com.fluffyfairygames.idleminertycoon)).
**[INFERENCE]** "Near-identical reincarnations" is the key phrase. Prestige fails when loop N+1 is mechanically identical to loop N but numerically larger. It succeeds when the reset unlocks a *rule change*.

### Complaint 5 — Unreadable numbers, and opaque systems that force wiki use
**[SOURCE — numbers]** A developer and their players arguing it out in public: *"I understand the numbers when I use a search engine to look it up but to be honest not even Google understood what 1.10e9 meant the first search!!!"* The developer's counter: *"The game just gets to real big numbers quickly, you might recognize 1M, B, T, Q, Qi etc but will you recognize 1Ttc?"* Other players defend scientific notation: *"Scientific notation is extremely common in incremental games, using a non-scientific notation is just torturing yourself"* ([Unnamed Space Idle, Steam](https://steamcommunity.com/app/2471100/discussions/0/7004880943562415594/)). In Idle Champions the resolution is a **settings toggle** — players *"can turn it off in the Settings"*, hotkey `Y` ([Steam](https://steamcommunity.com/app/627690/discussions/0/1737715419906222938/)).
**[SOURCE — opacity]** Realm Grinder: *"you have to read the wiki to find out how to unlock them"*; *"I do not have the free time to datamine and figure out which builds do what."* ([Steam](https://steamcommunity.com/app/610080/negativereviews/))
**[INFERENCE]** The notation argument is genuinely split between player segments, and the only answer that satisfies both camps is a toggle. Opacity, by contrast, has no constituency — nobody defends needing a wiki.

---

## 4. Recommendations for Lodeworks

### 4.1 Against each of the ten patterns

| # | Pattern | Recommendation for Lodeworks (one sentence) | Impact |
|---|---|---|---|
| 1 | Loop visible on one screen | Keep the entire 7×10 grid, the ore/second readout and the heat gauge on a single unscrolled screen at all resolutions, so the feeding chain and its hottest bottleneck cell are readable without opening any menu. | **High** |
| 2 | First purchase in ~10 seconds | Price the second machine so it is affordable from roughly ten seconds of the first machine's output, making the first placement a reflex rather than a decision. | **High** |
| 3 | Automation as a named unlock | Give the first machine that feeds a neighbour without player input a proper name and a one-time unlock moment, so "the grid runs itself" is an event the player remembers rather than a threshold they cross silently. | **High** |
| 4 | Return screen as celebration | Build a "Welcome Back" panel that shows ore mined, a per-stratum breakdown and any machine that overheated and stalled while away — with the optional 2× ad offer placed *on* that panel and nowhere else. | **High** |
| 5 | Offline capacity as progression | Make offline accumulation duration an explicitly upgradeable stat (e.g. a Core node raising it 4h → 8h → 16h → 24h) rather than a fixed constant. | **High** |
| 6 | Prestige retains something visible | Show the exact number of Cores the player will bank, and the resulting permanent multiplier, on the confirmation dialog *before* they commit to descending. | **High** |
| 7 | Drip-feed systems | Keep heat mechanics, coolant, and multi-output machines hidden until the grid is roughly half-filled, introducing exactly one new rule per stratum. | **High** |
| 8 | Opt-in ads, stated publicly | Ship zero forced interstitials and write "no forced ads" into the Play Store description and the first-run screen, since players in this genre quote that policy back as a reason for five stars. | **High** |
| 9 | Ad reward must beat a minute of play | Make every rewarded video worth clearly more than sixty seconds of current production and label it in the player's own units ("+2h 30m of ore"), never in an abstract token. | **Medium** |
| 10 | D7 social/timed layer | Add a weekly stratum-depth leaderboard or a shared co-op dig that is purely additive — never gating a machine, stratum or Core behind it. | **Medium** |

### 4.2 Against each of the five complaints

| # | Complaint | Recommendation for Lodeworks (one sentence) | Impact |
|---|---|---|---|
| 1 | Offline cap forces daily login | Set the baseline offline cap at no less than 24 hours so a player who sleeps, works and commutes never loses ore, and let Cores extend it beyond that. | **High** |
| 2 | Ad walls at cold-start | Guarantee that the first interactive frame after launch is the grid — no offer popups, no interstitial, no cross-promo ever precedes it. | **High** |
| 3 | Walls where progress stops being legible | When ore/second growth flattens below a threshold, surface an explicit in-grid prompt that descending now will bank *N* Cores, so the player is never left guessing that a reset was the intended move. | **High** |
| 4 | Tedium and punishing prestige | Make each descent change a *rule* — a new machine type, a different heat-dissipation law, an altered grid constraint — so stratum N+1 is never a numerically larger copy of stratum N. | **High** |
| 5 | Unreadable numbers and opaque systems | Ship a notation toggle (suffix ↔ scientific) in settings, and put a tap-to-inspect tooltip on every machine showing its exact input, output and heat contribution, so no player ever needs a wiki. | **Medium** |

### 4.3 The three things I would do first

**[INFERENCE — my own prioritisation, not from any source]**

1. **The Welcome Back panel** (Patterns 4, 5, 9; Complaints 1, 2). It is the only mechanic present in *all eleven* games in the FDG study, it is where the genre's least-resented ad lives, and for Lodeworks it has a unique twist no competitor has: **heat means a machine can overheat and stall while the player is away.** A return screen that says "Smelter at C4 overheated after 6h and stalled — you lost 40% of potential output" turns offline time into a *readable spatial puzzle* rather than a number. That is a genuine differentiator and I would build it before anything else.

2. **Descend-prompt + pre-commit Core preview** (Pattern 6; Complaints 3, 4). The single most damning quote in this entire research is *"Restarting the game for the rewards felt like a stake to the heart every single time."* Lodeworks has the advantage that descending a stratum is thematically a *move forward*, not a reset — lean hard on that framing, and never use the word "reset" in the UI.

3. **A written no-forced-ads policy** (Pattern 8; Complaint 2). Across this sample every 4.7+ game has opt-in-only ads and every ad-complaint-dominated game sits lower. Idle Planet Miner's **Remove Ads at $9.99** and Idle Slayer's **$9.99 permanent / $3.99 monthly** are the two confirmed price points to anchor against.

---

## 5. Source index

**Developer / primary**
- [GDC 2016 AdVenture Capitalist postmortem — full text](https://archive.org/stream/GDC2016Augustine/GDC2016-Augustine_djvu.txt) · [GDC Vault entry](https://www.gdcvault.com/play/1023486/-Adventure-Capitalist-Postmortem-or)
- [GameAnalytics — Eight Lessons from Kolibri Games](https://www.gameanalytics.com/blog/making-a-hit-idle-game-eight-lessons-from-kolibri-games)
- [Auxbrain official support — soul eggs](https://auxbrain.freshdesk.com/support/solutions/articles/47001170226-what-are-soul-eggs-for-)
- [Idle Slayer press kit](https://idleslayer.com/press-kit)
- [Realm Grinder developer diary, Divine Games](https://www.divinegames.it/discuss/viewtopic.php?id=395&p=8)
- [Frank Lantz — Y Combinator interview](https://www.ycombinator.com/blog/frank-lantz-director-of-nyus-game-center-and-creator-of-universal-paperclips/)
- [Melvor Idle official wiki — Offline Progression](https://wiki.melvoridle.com/w/Offline_Progression)

**Store listings (prices, ratings, counts)**
- [Idle Miner Tycoon](https://play.google.com/store/apps/details?id=com.fluffyfairygames.idleminertycoon) · [Egg, Inc. Play](https://play.google.com/store/apps/details?id=com.auxbrain.egginc) · [Egg, Inc. App Store](https://apps.apple.com/app/993492744) · [Idle Slayer App Store](https://apps.apple.com/us/app/idle-slayer-addictive-clicker/id1526599527) · [Idle Slayer Play](https://play.google.com/store/apps/details?id=com.pabloleban.IdleSlayer) · [Idle Planet Miner](https://apps.apple.com/us/app/idle-planet-miner/id1441880123) · [Legend of Slime](https://play.google.com/store/apps/details?id=com.loadcomplete.slimeidle) · [AdVenture Capitalist](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google) · [Antimatter Dimensions Play](https://play.google.com/store/apps/details?id=kajfosz.antimatterdimensions) · [Cookie Clicker](https://play.google.com/store/apps/details?id=org.dashnet.cookieclicker) / [ad-less](https://play.google.com/store/apps/details?id=org.dashnet.cookieclickeradless)
- Steam: [Melvor Idle](https://store.steampowered.com/app/1267910/Melvor_Idle/) · [Antimatter Dimensions](https://store.steampowered.com/app/1399720/Antimatter_Dimensions/) · [NGU IDLE](https://store.steampowered.com/app/1147690/NGU_IDLE/) · [Leaf Blower Revolution](https://store.steampowered.com/app/1468260/Leaf_Blower_Revolution__Idle_Game/) · [Bitburner](https://store.steampowered.com/app/1812820/Bitburner/) · [Idle Slayer](https://store.steampowered.com/app/1353300/Idle_Slayer/)

**Player threads / reviews**
- [Melvor offline cap (18h)](https://steamcommunity.com/app/1267910/discussions/0/4665175132461478006/) · [Melvor "Maximum offline progression - WHY?"](https://steamcommunity.com/app/1267910/discussions/0/3192493998739513526/) · [Melvor reviews](https://steamcommunity.com/app/1267910/reviews/)
- [AdVenture Capitalist endgame](https://steamcommunity.com/app/346900/discussions/0/490123938442169349/) · [Angel Investors](https://steamcommunity.com/app/346900/discussions/0/618459405712024885/)
- [Leaf Blower Revolution reviews](https://steamcommunity.com/app/1468260/reviews/) · [NGU IDLE reviews](https://steamcommunity.com/app/1147690/reviews/) · [Antimatter Dimensions reviews](https://steamcommunity.com/app/1399720/reviews/)
- [Realm Grinder negative reviews](https://steamcommunity.com/app/610080/negativereviews/) · [Clicker Heroes "I hit a wall"](https://steamcommunity.com/app/363970/discussions/0/6361980659850940161/)
- [Number notation — Unnamed Space Idle](https://steamcommunity.com/app/2471100/discussions/0/7004880943562415594/) · [Number notation — Idle Champions](https://steamcommunity.com/app/627690/discussions/0/1737715419906222938/)

**Analysis / academic**
- [CHI 2018 — Playing to Wait: A Taxonomy of Idle Games (Alharthi et al.)](https://par.nsf.gov/servlets/purl/10061230)
- [FDG '19 — Enhancing Social Exergames through Idle Game Design (Villareale et al.)](https://par.nsf.gov/servlets/purl/10188033)
- [Martin Jurasek — 900 seconds with Idle Theme Park Tycoon](https://martinjurasek.substack.com/p/900-seconds-with-idle-theme-park)
- [PocketGamer.biz — Deconstructing Idle Bank Tycoon](https://www.pocketgamer.biz/game-analysis-deconstructing-idle-bank-tycoon-by-kolibri-games/)
- [Naavik — The Evolution of Hybridcasual](https://naavik.co/deep-dives/evolution-of-hybridcasual-deepdive/)
- [GameAnalytics — How to Make an Idle Game](https://www.gameanalytics.com/blog/how-to-make-an-idle-game-adjust)
- [Game Developer — Incremental Game Review: Trimps](https://www.gamedeveloper.com/design/incremental-game-review-trimps)
- [if50 — 2017: Universal Paperclips](https://if50.substack.com/p/2017-universal-paperclips)
