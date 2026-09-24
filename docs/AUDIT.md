# Lodeworks, audited as a game somebody keeps

## 0. Landscape / isometric round -- the state it started from

23 September 2026, before any code of this round. Measured, or UNKNOWN.

**What this repository is.** `main` at `1c57304`, 17 commits, private
GitHub repository `Furkiozknn/lodeworks` (created this round; before it the
only remote was `gecici/lodeworks.bundle`). 246 tests / 2004 assertions pass
locally on Godot 4.7.2 (`tests/test_runner.gd`).

**What it is not.** The Cowork branch `visual/perspective-main-view`
(`06e5b3b`, reported as 257 tests and a 39.9 MB sprite art folder) and the
commit `9a524fe` are **in none of**: this clone, `gecici/lodeworks.bundle`
(heads `9825ac3`), `gecici/lw-inc.bundle` (`052ec5e`), or GitHub. Their
content is UNKNOWN. What survives of that round is its raw output: 43
generated PNGs (232 MB) in `D:\Claude Projeleri\lodeworks_art\gen` and the
Higgsfield generation history, both of which this round rebuilds from.
`ba6371f` exists (this round).

### A -- critical defects

| | defect | evidence | state |
|---|---|---|---|
| A1 | The Android export had never worked from a clean checkout | first `android` run: "Android build template not installed in the project" | fixed `ba6371f` (`--install-android-build-template`) |
| A2 | The APK check failed on its own report | "grep: write error: Broken pipe", exit 2, under `pipefail` | fixed `e397458` |
| A3 | The build report could not read the package | "aapt2 not found": a glob over several build-tools | fixed `1c57304` |
| A4 | No signed bundle can be built | no `ANDROID_KEYSTORE_*` secrets | **needs a person** (docs/CI.md) |

First green `android` run (`35909824939`): APK without plugins
162,857,140 B, with plugins 174,309,375 B, debug AAB 67,656,927 B. The
debug APK carries x86_64 as well as arm64 and unstripped libraries; a
release size is UNKNOWN until a release build exists.

### B -- visual gaps

- The whole game is `_draw()` rectangles; `assets/` holds one SVG icon. The
  sprite round built in Cowork is not in the repository.
- Portrait 720x1440, an axis-aligned square grid filling a panel, no world
  around it, no Factory Core, no expansion ground.

### C -- camera gaps

- There is no camera. The board fits itself to its control; no pan, zoom,
  pinch, wheel or bounds.

### D -- UX gaps

- A portrait stack of panels; the tutorial is a text line above the board;
  cell size is whatever the layout leaves (about 57 dp on a 1080p phone in
  portrait, computed, never measured on hardware).
- Moving a machine is "drag any machine", which collides with "drag to pan"
  the moment there is a camera.

### E -- performance risks

- Bitmaps arrive: VRAM, load time and import settings become real costs.
- `*.import` is ignored, so per-texture compression cannot be set and would
  be lost on every clone.
- The AdMob addon packs its demo scenes, two logos and a CJK font into the
  APK (seen in the build report's asset list).

### F -- release blockers (unchanged, in docs/PLAY.md)

- Play Console account, keystore and secrets, AdMob ids, hosted privacy
  policy, 12 testers x 14 days, one real device run: all need a person.
- Store screenshots are portrait 1080x1920 and would no longer show the
  game once it is landscape.

### G -- monetization gaps

- Palettes were colour tables on procedural machines. Sprites need one
  sheet per palette (and per upgrade tier) or a bought palette silently
  stops showing. No new product is justified by any measurement; none is
  added.

### Order of work

Repository/CI -> landscape -> camera -> world -> board -> machines ->
connections -> heat -> UI -> Foreman -> animation -> asset budget -> tests
-> device validation -> store. Each step measured; everything unmeasured is
written as UNKNOWN.

### What this round did, and what it did not

Branch `visual/landscape-iso`. The simulation, economy, progression, save
format, monetization and tests of all of those are untouched; the new
screen reads the simulation and writes to it only through the three
gestures it always had (place, move, sell).

**Done**

- Private repository, CI green on `main`; the Android chain fixed three
  times until it produced debug APKs and a debug AAB on every push (A1-A3).
- Landscape 1440x720, sensor landscape. The main screen is a 2:1 isometric
  world: canyon painting with parallax, rock island, 12x12 slab, the 7x10
  board, the Factory Core (on the slab, off the board), a fenced expansion
  plot, props, depth-band tint and a descent effect.
- Camera: 1:1 pan, fling, pinch, wheel, zoom key, bounds that never show
  the void; a machine must be selected before it can be dragged.
- 12 machines x 6 palettes x 2 tiers generated in one isometric style;
  Core, props, island, world, HUD icons, Foreman poses. Palette purchases
  keep working and now show their own sprites; the shop's palette strips
  and the Codex boards draw the same sprites.
- Pipes drawn only where the simulation can move material; flow beads on
  seams that actually moved something; the selected machine's links on top.
- Badges after 1.5 s, only at the root of a jam; the heat language (tint,
  glow, embers, flame badge, the Foreman once per stratum at critical).
- Landscape HUD in the corners; detail panel in the tray's place.
- Tools: `art_build.py`, `asset_budget.py`, `layout_check.tscn`,
  `perf_probe.tscn`, `visual_compare.py`, audit captures in `shots.tscn`.
- Tests: 246 -> 262 (2904 assertions); plus the layout check, the art
  budget, the audit capture and a six-resolution smoke test in CI.

**Not done, and why**

| | not done | why |
|---|---|---|
| N1 | Signed release AAB | no keystore secret; needs a person (docs/CI.md) |
| N2 | Any device run | no Android device attached to this machine |
| N3 | Separate paintings for Surface, Deep and Abyss | one painting tinted per band is the stated interim; four paintings are four generations and 3 x 2.4 MB of budget -- worth it once the Workings screen is approved |
| N4 | Pipes readable at the default zoom on a dense board | in a 45-degree view the seam between two machines is behind the nearer one; beads and the selected-machine links carry connections instead (see item 7 below) |
| N5 | Per-part machine animation (the drill bit turning, the ram falling) | sprites are single frames; the machines breathe and glow on their real cycle instead. Frames would be 12 x N more generations |
| N6 | Store screenshots, feature graphic, preview video in landscape | the directive puts store work after the main screen; the capture tool already renders at 1920x1080 |
| N7 | Codex and shop redesigned for landscape | they work (scroll, full width) and draw the new sprites; their layout is still the portrait one widened |
| N8 | `visual/perspective-main-view` (06e5b3b) and 9a524fe | not in any place this machine can reach; content UNKNOWN |
| N9 | Removing `MachineArt` | still draws the store icon in `tools/brand_painter.gd`; goes with N6 |

### Old renderer against new, same machine

Windows 11, Intel UHD Graphics, `gl_compatibility`, frames uncapped (vsync
off). The same 36-machine board (the audit's reference board, stratum 7).
Old = `main` at `1c57304`, portrait; new = this branch, 1440x720. Device
column: UNKNOWN.

| | old (procedural, portrait) | new (sprites, landscape iso) |
|---|---|---|
| frame p50 / p95 / p99, idle | 2.0 / 9.4 / 12.3 ms | 12.3 / 17.9 / 20.4 ms |
| frame p50 / p95 / p99, panning | -- (no camera) | 10.9 / 14.5 / 16.3 ms |
| frame p50 / p95 / p99, zooming | -- | 10.4 / 14.0 / 18.5 ms |
| 600 s soak p50 / p95 / p99 | not run | 12.1 / 15.8 / 18.5 ms, memory 45.1 -> 45.7 MB, nodes 181 -> 181 (build `3f8df0b`) |
| draw calls (renderer counter) | 92 | 132 on the bare board (world 37, HUD 95), 150-185 with the Foreman and badges up |
| texture memory (renderer counter) | 9.0 MB | 33.9 MB |
| video memory (renderer counter) | 15.3 MB | 40.5 MB |
| sim tick | 0.98 ms | 1.0 ms (budget 3 ms) |
| scene load, warm | 1.2 ms | 1.1-2.0 ms |
| art load, uncached | -- | 110-135 ms (8 files) |
| palette switch to an unloaded sheet | -- | 55-86 ms |
| descend, to the first frame after | -- | 46-48 ms |
| committed art | 0 | 6.76 MB (budget 40 MB); 15.5 MB imported |
| colourfulness (Hasler-Suesstrunk) | 17.3 | 28.0 (reference concept: 30.3) |
| readability, closest pair at 44 px | colour 20.8, grey 16.0 (from the old ART.md) | colour 18.9 (free palette), grey 11.8 (Slate); floors 9.0 / 6.0 |
| board share of the screen | 48% (a 691x987 rectangle) | 21.5% at the default zoom on 2:1 (a diamond; the rest is world); 11.8% before the reframing below |

**Decision.** The new renderer replaces the old on the main screen and
`GridView` is deleted: it is the only one of the two that is the requested
game, it is consistent (one camera for every sprite), and it costs 12 ms a
frame on the weakest desktop GPU at hand, inside a 16.7 ms frame. It is
five to six times the old renderer's frame time and four times its texture
memory, and whether a mid-range phone holds 60 fps with it is **UNKNOWN**
until the probe or the self test runs on one. `MachineArt` stays only for
the store icon (N9).

### Measured on eleven screen shapes

`tools/layout_check.tscn`, the real main screen, three safe areas each (none,
a 96/48 side notch, a 40/36 top and gesture bar). No overlap, nothing
outside the safe area, the whole board visible between the panels, on all
33. Cell height is in dp for a device of that shape at the density given.

Before -> after the reframing described in the next section.

| screen | canvas | cell, default zoom | cell, closest zoom | board share |
|---|---|---|---|---|
| 16:9 1920x1080 @420 | 1440x810 | 24.7 -> 32.6 dp | 52.0 dp | 14.2 -> 24.7% |
| 16:9 1280x720 @320 | 1440x810 | 21.6 -> 28.5 dp | 45.5 dp | 14.2 -> 24.7% |
| 18:9 2160x1080 @400 | 1440x720 | 25.1 -> 33.9 dp | 61.4 dp | 11.8 -> 21.5% |
| 19.5:9 2340x1080 @420 | 1560x720 | 23.9 -> 32.3 dp | 58.5 dp | 10.9 -> 19.9% |
| 20:9 2400x1080 @405 | 1600x720 | 24.8 -> 33.5 dp | 60.7 dp | 10.7 -> 19.4% |
| 21:9 2520x1080 @420 | 1680x720 | 23.9 -> 32.3 dp | 58.5 dp | 10.2 -> 18.5% |
| 16:10 2560x1600 @300 | 1440x900 | 52.5 -> 60.8 dp | 97.1 dp | 16.6 -> 22.2% |
| 4:3 2048x1536 @264 | 1440x1080 | 59.4 -> 55.3 dp | 88.3 dp | 21.4 -> 18.5% |

The Cowork estimate of "about 32 dp at normal zoom, 51 dp close" holds now,
after the reframing: 32-34 dp on the phones that matter. That is still
under Android's 48 dp, so aiming at one cell precisely still means zooming
in (52-61 dp at the closest zoom). 4:3 is the one shape that lost: the
width binds there, and the Core beside the board's left corner makes the
framed rectangle wider (21.4 -> 18.5%, cells 59 -> 55 dp, still above
48 dp). Every HUD
key is 96 canvas units: 48 dp or more on every shape except the 720p xhdpi
16:9 phone, where they measure 43-44 dp (reported, not enforced).

### The default view

The first measurement of this round: at the default zoom the board was
11.8% of a 2:1 screen with 24-25 dp cells, and the world, not the factory,
was the main object. Two things set that zoom. The framed rectangle
carried two cell-heights of margin above the board and 0.35 of a cell
either side, and the Factory Core stood behind the board's back corner, so
the view had to be tall enough for the Core's whole tower.

Framings measured on the 2:1 canvas with its real free rectangle (a scratch
probe; same numbers for 16:9 and 20:9 in the same order):

| framing | zoom | cell | board share | Core |
|---|---|---|---|---|
| A: board + whole Core (as it was) | 0.655 | 25.1 dp | 12.2% | whole |
| B: board only, old margins | 0.772 | 29.6 dp | 17.0% | cut |
| C: board only, tight margins | 0.883 | 33.9 dp | 22.2% | cut |
| D: tight + the Core's lower 60% | 0.812 | 31.2 dp | 18.8% | cut |
| E: tight + Core moved to slab (1, 8) | 0.883 | 33.9 dp | 22.2% | whole |
| F: tight + a 2x2 Core at slab (1, 8) | 0.883 | 33.9 dp | 22.2% | whole |

**E** is what shipped: C's zoom with the Core still in view and at its
size. The Core now stands on slab (1..3, 8..10), beside the board's left
corner, where it no longer sets the height; the expansion plot takes slab
(1..3, 1..7). The margin above the board is exactly how far the tallest
machine sprite rises above the back corner (58 units, read from the sheet
by `IsoView.board_frame_rect`), plus 6. The board, the cell and the sprite
scale are unchanged -- only the camera's default moved.

Framing tighter uncovered one case the free rectangle cannot see: with a
96-unit side notch the resources panel, top right, reached the board's
right corner. The default view now steps back 3% at a time (to 0.6 of the
fit at most) while any HUD panel covers part of the board
(`IsoView.board_under_panel`); the layout check passes 11 screens x 3 safe
areas with it.

Cost: none measured. Idle p50 / p95 / p99 10.8 / 14.9 / 16.9 ms, panning
11.3 / 15.8 / 18.9 ms, zooming 11.0 / 16.1 / 17.9 ms, draw calls 176-184,
a 60 s soak 12.7 / 18.4 / 22.4 ms with memory flat (45.1 -> 45.1 MB) --
same machine and GPU as the table above; a phone: **UNKNOWN**.

### Touch: a tap takes the machine it is on

A machine's picture stands well above its own tile: the upper half covers
the tiles behind it. The board used to pick by the tile under the finger
alone, so a tap on the upper part of a machine selected the machine behind
it, or the empty tile behind it. `tools/pick_rate.gd` measures it on the
hero board, headless:

| | tile rule (before) | picture rule (after) |
|---|---|---|
| visible picture pixels that reach their own machine | 37.3% | 100% (by definition) |
| taps aimed at a machine, finger spread 1.0 mm | 32.7% | 96.8% |
| same, 1.5 mm | 33.1% | 86.0% |
| same, 2.0 mm | 32.3% | 70.5% |

The finger spread is a normal scatter on each axis at the default zoom of an
18:9 phone (2160x1080 at 400 dpi, zoom 0.883). The spreads are assumptions,
not a measured finger. What matters is the difference between the two rules
under the same spread.

`IsoArt.pick` is the new rule:
- Machines are tried front to back, in the order the board draws them, and
  only where their picture is opaque. A tap through the clear gap beside a
  tower still reaches what is behind it.
- Where no machine is drawn, the tile under the finger is picked, as before.
- While a machine is armed for placing, an empty tile under the finger is
  still where it goes. Placement did not change, even where a picture in
  front overlaps the tile; `test_placing_still_puts_the_machine_on_the_tile_under_the_finger`
  checks that over the whole board.

Unarmed, a tap on the 12.6% of empty-tile floor that a picture covers now
selects that machine instead of doing nothing.

Cost:
- Nothing per frame. The pick runs on a finger going down and coming up.
- About 0.29 ms per pick on the desktop (headless, 4,950 points).
- The atlas image, 3.4 MB, is read from the GPU on the first tap.

On a phone, that read uses Godot's GLES3 framebuffer readback. It has not
run on a device. If it returned nothing, the pick would fall back to the
tile rule, which is also tested.

### The 12-point comparison with the reference

Reference: the user's concept `ref2.png` and the generated target mock
`r2_target.png` (both portrait mock-ups). Compared with
`01_main_landscape.png`. Each row says what it is measured by; a row that
can only be judged says so.

| # | item | result | evidence |
|---|---|---|---|
| 1 | Camera | **PASS** | 2:1 isometric, 45 degrees, as the directive asked (`test_the_projection_is_two_to_one`); pan, fling, pinch, wheel, bounds tested. The reference mock-ups are a front-facing 3/4 view; the directive's Clash-style 45 degrees was followed instead |
| 2 | Perspective | **PARTIAL** | board, machines, island, props and Core share one camera; the world painting is a front-facing 3/4 view (the image model did not rotate it), softened by parallax |
| 3 | World feel | **PASS** | island over a canyon, Core, expansion plot, props around the board; the board itself is 21.5% of the default 2:1 screen (11.8% before the reframing) and the rest is world. The old screen had no world |
| 4 | Grid placement | **PASS** | whole board in the free area on 11 shapes x 3 safe areas, no panel over it (layout check) |
| 5 | Machine scale | **PARTIAL** | plate = 76% of a cell; 32-34 dp cells at the default zoom (24-25 before the reframing) are under the 48 dp floor, 52-61 dp at the closest zoom |
| 6 | Colour | **PARTIAL** | colourfulness 28.0 against 30.3 / 30.7; saturation 0.44 against 0.54-0.57 (`tools/visual_compare.py`) |
| 7 | Light | **PARTIAL** | brightness 0.40 against 0.37-0.40 (matched), contrast 0.22 against 0.26; additive glows, no bloom (the compatibility renderer has no HDR 2D) |
| 8 | Depth | **PASS** | back-to-front drawing tested; parallax, cliffs, contact shadows, raised slab. Connections behind nearer machines: see N4 |
| 9 | UI | **PASS** | corners and edges as the reference; keys 96 units; no overlap on 33 layouts |
| 10 | Animation | **PARTIAL** | breathing and core glow on the real cycle, steam, embers, flow beads, crystals, dust, descent; no per-part motion (N5) |
| 11 | Atmosphere | **PARTIAL** | the painting is still (waterfalls and mist do not move); dust and lamp light move; other depth bands are a tint (N3) |
| 12 | Overall premium feel | **UNKNOWN** | a judgement, and nobody but the author has looked. The four audit screens are in CI's `screenshots` artifact; the "before" screen was captured from `1c57304` on the same machine |

---


23 September 2026. Every claim below is a number one of the tools in this
repository prints, or it is marked UNKNOWN. Reproduce with:

```sh
godot --headless --path . --script res://tools/journey_lab.gd    # the journey
godot --headless --path . --script res://tools/strategy_lab.gd   # the choices
godot --headless --path . --script res://tools/money_lab.gd      # the money
```

---

## 1. The player journey, measured

| window | what actually happens | verdict |
|---|---|---|
| **0–10 s** | The tutorial hands over a Drill. A lone Drill **earns nothing, ever** — it has nowhere to sell. Drill + Vault pays its first credit at **2.1 s**. | **Sufficient.** The second machine is not a suggestion, so adjacency is taught by necessity rather than by a tooltip. |
| **10 s – 1 min** | Machine three costs 17 credits and is affordable **17 s** after the first. Gaps between purchases over the first 38: 19, 28, 8, 8, 11, 6, 8 … 14, 15 s. | **Sufficient.** The gap never grows. There is no wait anywhere in this game. |
| **1–3 min** | First descent at **179 s**, unlocking Smelter and Boiler. Heat becomes a decision the moment a Smelter exists (optimum 3.0 against a Drill's 0.0). | **Sufficient.** |
| **3–10 min** | **Five descents**, each unlocking a machine: Smelter/Boiler, Coolant, Press, Assembler, Amplifier. 66 machines placed. | **Sufficient.** |
| **10–30 min** | Stratum 5, board full at 70 machines, first collapse available for **7 Cores**. | **Sufficient after this round.** It paid 25 before the Core rebalance, which made the first prestige a formality. |
| **first day** | Offline banking: 4 h capped at 45% of the measured live rate = 1.8 h of production waiting. | **Sufficient.** |
| **first week** | The permanent tree costs **372 Cores**; a strong run pays **85**. Four collapses at the ceiling, many more in practice. | **Improved, still finite.** See C1. |

**The opening was never the problem.** Everything that was wrong was in the
middle and the end, and none of it needed new content to fix.

---

## 2. Classification

Evidence for every row is a measurement, not a judgement.

### A — must exist, was missing, **implemented this round**

| | finding | evidence | what was done |
|---|---|---|---|
| **A1** | **Two stratum modifiers did nothing.** Brittle Rock's "Drills run 35% faster" and Resonant Strata's "Amplifiers are twice as strong" were computed and read by nobody. | Brittle scored *below* a clean stratum in **all 32** board-by-condition cells. Resonant measured **identical to clean, to the last credit**, on every board including one built entirely of Amplifiers. | Both wired. `Strata.apply()` is now the only way to configure a simulation from a stratum, and `test_nothing_configures_a_simulation_by_hand` fails the build if any file sets those fields directly again. |
| **A2** | **Four of twelve machines were decoration.** Boiler, Coolant Cell, Duplicator, Condenser. | Spending the board's fourteen spare tiles on any of them scored **within 1% of leaving them empty** (1069–1077 against 1077); spending them on more chain scored 1167 and won 24 of 32 conditions. | Two rules: a support machine **bridges rather than blocks** (material passes through, one hop), and is **worth what it touches** (`1 + 0.5 × (n−1)`, stacking at 1 / 0.6 / 0.36 / 0.22). |
| **A3** | **The prestige layer had no sink.** | One 77-minute run to stratum 20 paid **774 Cores against a tree costing 88 in total**. Every collapse after the first was a strict loss, because a collapse also takes the Research. | Credits enter the Core formula logarithmically instead of as a square root; depth exponent 1.25 → 1.1; costs rise 1.2 per level instead of 0.6 on tripled bases. Tree 88 → **372**, best run 774 → **85**. |
| **A4** | **The discovery was invisible.** A support machine's whole value is how many neighbours it ends up with, and that could not be known until after paying. | — | The placement preview draws **"serves N ×F"** under the finger before the tile is bought, from the same function that grants the effect, and two Codex pages teach both rules with running boards. |

### B — worth doing now, **implemented**

| | what | why now |
|---|---|---|
| **B1** | Machine descriptions rewritten for the Amplifier, Duplicator, Boiler, Coolant Cell and Condenser. | Three of them described rules that had just changed, and one ("stacks with other Amplifiers") became false. A card that lies is worse than no card. |
| **B2** | `tools/journey_lab.gd` and `tools/strategy_lab.gd`, both wired into CI. | The four findings above were invisible for three releases because nothing asked these questions. They now get asked on every push. |

### C — defensible to add later, **deliberately not added**

| | what | the measurement that would justify it |
|---|---|---|
| **C1** | **Something after the permanent tree.** It is now a four-collapse goal at the ceiling rather than a one-collapse formality, but it still ends. | If real players finish it and stop, that is the number that justifies an endless tier. Inventing one now is the content treadmill. |
| **C2** | **Challenge runs** — a stratum entered under a stated restriction, in the shape of Antimatter Dimensions' Challenges, where the restriction *is* the content. | Cheapest real mid-game structure in the genre and it adds no machines. Worth doing only once C1 is proven to be the binding constraint. |
| **C3** | **Stratum records** — a persistent best rate per depth, surviving collapse. | A reason to re-descend a stratum you have already cleared. Needs evidence that players want to. |
| **C4** | **Novelty past stratum 10.** The last machine unlocks at depth 10; over 60 strata there are 41 distinct modifier sets and **18 repeats**. | Real. But the honest first answer was to make the existing twelve machines produce three distinct winning boards instead of two, which is what A2 did. |

### D — refused

| | what | why |
|---|---|---|
| **D1** | More machines, more strata, more currencies. | The content treadmill. Sourced: adding volume is the documented substitute for depth, and the genre's own negative reviews are "a spreadsheet pretending to be a game" and "after 100 hours I STILL don't feel stronger". |
| **D2** | Daily / weekly challenges. | A retention mechanic that punishes absence. This game has no wait and no streak; adding a reason to feel bad for missing a day would be the first one. |
| **D3** | Multiplayer, leaderboards, social. | Nothing in the measured journey needs another person, and it would add an account, a server and a privacy surface to a game that currently has none of the three. |
| **D4** | Premium currency, starter packs, subscriptions, interstitials. | Unchanged from the monetization round, and the reason is the same: this game has no wait to sell back. |
| **D5** | Randomised hidden bonuses to create "discovery". | Output randomness produces "phantom skill" — the player cannot tell whether they were clever or lucky. Every combination A2 opened up is deterministic and derivable from a rule printed on the tile. |

---

## 3. What is still UNKNOWN

Updated 24 September 2026, after the landscape round:

- No signed release AAB has been built (no keystore secret). Debug APKs and
  a debug-signed AAB are built by CI on every push.
- Nothing has run on a real Android device. Every frame-time, memory, battery,
  input-latency and touch figure is UNKNOWN.
- No purchase has ever been made in a real store, and no ad has ever been
  served.

Everything in this document was measured in the headless simulation, which is
the same code the game runs, on hardware that is not a phone.
