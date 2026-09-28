# The product target, against the game as it is

The round of 26 September 2026. The owner sent two images as the product
target, not only a style reference: `lodeworks_art/vision_a.png` (a poster
of the game's loop, machines, depths, progression, shop and world) and
`lodeworks_art/vision_b.png` (key art, the gameplay screen, the research
tree, the shop, a reward screen, missions and the helper robot). They set
the category the game is to reach: a living underground industrial world
with characters and robots, production, research, exploration and
operations, fights later, and long-term strategic progression, as a
premium-looking mobile game. Not a board of machines and numbers.

This document compares the game with that target and says what each part
of the target is, what the game has, and what comes next. The systems
themselves are classified in `GAME-LOOP.md` (section 2); the Core's
measurements are in `PROGRESSION.md`.

## 1. How far the game is from the target

| part of the target | the game now | status |
|---|---|---|
| **stylized 3D, toy-like industrial machines**, readable silhouettes, one glowing core each | the machine sheets (`assets/art/machines/*.webp`), generated in the target's register, six palettes, two tiers | **DONE** |
| **the Factory Core as the world's landmark** | the Core on its three-cell plate, pulsing, seen through when it hides machines, **in four stages**: a young furnace-drum with scaffolding (Cores 1-3), the tower (4-6), the tower with brass rings and pylons (7-9), the citadel with satellite towers and a column of light (10 and up) (`world/core_t1.webp`, `core.webp`, `core_t3.webp`, `core_t4.webp`; `IsoView.core_info`) | **DONE** (27 September) |
| **a helper robot, working in the factory** | the **Rig**, drawn from its own pose sheet (`crew/rig.webp`: idle, driving, welding, carrying, worn): it parks at the **Rig Bay**, drives to the machines levelled and welds them, drives out of the Rig Frame that made it, is repaired at the Bay, drives to the galleries and home carrying its find | **DONE** (this round) |
| **the world around the factory**: rock, cliffs, crystals, veins, water, steam, passages | the canyon painting and the floating island; props (crystal, ore veins, vents, lamps, crates, rubble); **gallery mouths** (open, boarded, the nest) and the **Rig Bay** (`world/galleries.webp`); **land for each band** beyond the yard and under its unbuilt tiles -- a grass meadow at the Surface, rocky mine ground in the Workings, cooled lava with glowing cracks in the Deep, violet crystal ground in the Abyss (`tiles/land_*.jpg`) -- and only the tiles a machine stands on, with a one-tile apron, paved | PARTIAL: no water or cliffs on the board itself; the props are one set |
| **each depth a new world** (the poster's "Derinlikler") | **a painting and a floor for each band** (`world/surface.jpg`, `workings.jpg`, `deep.jpg`, `abyss.jpg`, `tiles/floor_*.jpg`), crossfading on the dive into a new band | **DONE** (this round) for the painting and the yard's floor; the island's rock and the props are still one set |
| **the Foreman as a character** | five poses, speaking the tutorial and the game's news in the screen's margin -- **and on the board**: he stands at the front of the Core's plate, walks to a machine the moment it is laid, jumps at the Core when it grows, cheers there when a machine is found, and now and then walks over to a working machine to look it over | **DONE** (27 September) |
| **operations that are not a menu** | Rigs drive to mine entrances past the yard, weld there with sparks, drive home with a crate; what they bring flies into the Core; **the team is the player's choice**: more Rigs come home less worn and burn more fuel, fewer leave Rigs for a post and take a share | PARTIAL: no map of regions; three sites at a time; one kind of Rig |
| **reward feedback** | toasts; gems flying from the Bay into the Core; the Core's pulse on a level; **a reward card for each Core level**: the Core's new picture, the era's name, the Foreman cheering, what the level opened and the next level's first rows, each a tap that goes to do it; the NEW! card with the Foreman for a machine found | **DONE** for the Core and machines; a site's find is still a toast |
| **UI: big icons, strong cards, a menu of Machines / Research / Shop / Missions** | **a side menu** of picture keys with their words: Tasks (What now?), Core (its stage's picture), Crew (the Rig Bay), Sorties (the galleries), Heat, Problems; Research, **Map**, Collapse and Codex at the bottom left | PARTIAL: the shop is still in Settings; the research screen is a grid of cards, not a tree |
| **the research tree** as a graph of branches | cards by branch | PARTIAL |
| **missions ("Görevler")** | What now? points at the next thing; the Core's rows are the goals | PARTIAL: no list of goals with rewards |
| **map ("Harita")** | **the shaft's map**: the four bands top to bottom, each with its painting, its strata, the machines found there (a lock until found), where the factory is, how far the Core lets it go, and the galleries' sites | PARTIAL: a map of the bands, not yet of regions to explore |
| **shop** with the two one-time purchases | Settings holds them | PARTIAL: no shop screen of its own |
| **daily rewards, daily and weekly goals** | none, by decision D2 | **owner's call**: the images show them; D2 rejects daily and weekly loops |
| **gems (a premium currency) and energy (12/20)** | none, by decisions D4 and V3 | **owner's call**: the images show both; D4 and V3 reject them |

**Overall:** the art register, the machines and now the crew and the
depths are in the target's category. What still reads as "a board of
machines" is the ground beyond the yard, the Core that never grows, and a
UI that is a tool panel rather than a game's menu.

## 2. The reference games, for the target's systems

Each chain is judged by whether it answers a decision in the Robot →
Operation → Reward loop or in the target's screens. AL = take, UYARLA =
adapt, ERTELE = defer, ALMA = reject.

| mechanic | reference | verdict | the Lodeworks version |
|---|---|---|---|
| early game teaching by a character | CoC, Hay Day, Township | **AL** (done) | the Foreman's tutorial; the first sortie at minute 7 |
| a main building that gates everything | CoC Town Hall, WOS Furnace | **AL** (done) | the Factory Core's levels |
| the main building grows on screen | CoC, WOS | **UYARLA** (next) | the Core's picture grows with its level (Core 1, 4, 7, 10) |
| builders / workers you can see | CoC builders, WOS survivors | **UYARLA** (done) | the Rigs' service calls and repairs |
| unit production from the base | CoC barracks | **UYARLA** (done) | the Rig Frame job |
| unit upgrades | CoC laboratory | **UYARLA** (done) | Rig Plating |
| repair and healing | RoK hospital, WOS clinic | **UYARLA** (done) | wear and Plates, at the Bay |
| missions to targets that pay | BB operations, RoK barbarians | **UYARLA** (done) | the galleries' sites |
| expeditions of hours | BB submarine | **ERTELE** | a sortie is a minute or two (V3) |
| a map of regions, explored | BB radar, RoK map | **ERTELE** (next big one) | the galleries as a map of sites by depth |
| attack and defence against players | CoC, BB | **ALMA** now (V1/D3) | a rival factory from a share code, later |
| rewards only a battle brings | CoC loot, BB power stones | **UYARLA** (done) | salvage |
| research as a tree | WOS, RoK | **UYARLA** | the research screen as a graph (the image) |
| goals with rewards | CoC achievements, Township quests | **UYARLA** | a Missions screen from the Core's rows and What now? |
| daily and weekly goals, streaks | WOS, RoK, Hay Day | **ALMA** by D2 | owner's call (the images show them) |
| events | all | **ERTELE** | needs a calendar or a server |
| clans, chat, trade | CoC, RoK | **ALMA** by V1/D3 | -- |
| a reward screen with a character | Township, Hay Day | **AL** | the Foreman cheering, for a new machine, a Core level, a site's find |
| premium currency and energy | the images, RoK, WOS | **ALMA** by D4/V3 | owner's call |

## 3. The vertical slice

The target's one screen, and where the slice stands:

- **Factory Core, a real factory floor, a few strong machines:** in place.
- **A helper robot and the Foreman:** the Rig works in the world (this round); the Foreman is in the margin.
- **Production, heat, resource feedback:** pipes that light with what moves, heat overlay, badges.
- **Upgrade:** the Rigs drive to the machines levelled and weld them (this round).
- **Research:** the card grid.
- **Robot workshop:** the Rig Bay, with the crew parked at it (this round).
- **A small operation and its reward:** the galleries, the crates, the gems flying home (this round).
- **Environment, lighting, depth:** a painting and a floor per band (this round); glow, motes, contact shadows.

**Next, in order:** the Core that grows with its level (four pictures); the
ground beyond the yard as terrain (grass, rock, water at the Surface; basalt
and lava in the Deep); the side menu (Machines, Research, Shop, Missions)
and a Missions screen; the reward screen with the Foreman.

## 4. Art, and what it cost

Seven images this round, all from `gpt_image_2_5` on Higgsfield, recorded
in `art_src/sources.json`: the Rig's poses and the galleries' sheet (2k,
no reference attached), three world paintings (4k, the Workings painting
as reference), three floors (2k, the Workings floor as reference): 26.5
credits, the account going from 251.03 to 224.53. The target images are not in the
repository; they are kept beside the raw art.
