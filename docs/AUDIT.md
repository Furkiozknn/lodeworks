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
- Store screenshots were portrait 1080x1920 from before the landscape
  game. **Fixed** (GAP-AUDIT A4): rendered at 1920x1080 and 2560x1440 by
  CI, the listing rewritten, a Turkish listing added.

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
| N7 | Codex and shop redesigned for landscape | done 25 September 2026: the Codex is filed by machine group with big pictures, and the shop puts its two products side by side with 96-unit keys |
| N8 | `visual/perspective-main-view` (06e5b3b) and 9a524fe | not in any place this machine can reach; content UNKNOWN |
| N9 | Removing `MachineArt` | done 25 September 2026: the store icon and feature graphic draw the game's own sprites |

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

### The first minute

`LODEWORKS_CAPTURE=first` makes `tools/shots.tscn` play the first minute of a
fresh install, the way the tutorial asks for it:
1. It opens a new game.
2. It does the first thing the game asks for.
3. It buys a Drill and a Vault where the tutorial points.
4. It waits ten seconds.

Before this round it ended with **0 credits and 0 machines**. A new game
opened with an empty purse, and the first Drill cost 15. Nothing gave the
player credits, so the Drill the tutorial pointed at could not be bought.
Every shaft after a collapse opened the same way. The tests never saw it
because the playthrough set its credits by hand.

The Factory Core now starts every shaft:
- **The Core starts dark.** A new game, and every shaft after a collapse,
  opens with the Core dark, a target pulsing on its body, and the Foreman
  saying "Tap the FACTORY CORE to bring it online."
- **The first tap pays its reserve.** `Sim.power_core` pays out exactly the
  price of a first Drill and a first Vault: 40 credits. That is the fewest
  credits a shaft can start earning with. The reserve is not counted as
  earnings, so a collapse's Cores do not change. It pays once per shaft.
- **Online, a tap explains the Core.** A card says what the Core is and
  where descending leads.
- **Older saves stay sane.** A save written before this has no
  `core_online`. A shaft with machines, or with the price of a Drill in its
  purse, loads running. One with neither was the dead end, so its Core
  starts dark and pays its reserve.

After: the same run ends with 8 credits, a Drill and a Vault earning 1 per
second, and the tutorial on its next step.

The tests now cover:
- a new game (`test_a_new_game_can_start_the_core_pays_for_the_first_two_machines`)
- a collapse
- the save round trip, including older saves
- the Core's hit test

The playthrough now starts the game the way a player does.

Tried and taken back: keeping the Core clear of the stratum card when
framing. The default view stepped back until the board was 14.1% of a 2:1
screen instead of 21.5%, and the layout check's 18% floor failed. The
Core's top still touches the stratum card. The card has to shrink, not the
board.

### The 44 x 44 board

The user asked for the 7 x 10 board to become 44 x 44, the size of a
base-building map. It is now:
- **The board.** `Grid.W` and `Grid.H` are 44, on a 48-cell slab.
- **The Core.** The Factory Core stands on the 4 x 4 block in the middle
  (`BuildArea.CORE`), like a town hall. Nothing is built there.
- **The yard.** The yard is the ring of ground round the Core, and it
  replaces the corner yard described below. It is one tile wide (20 tiles)
  in a new shaft, two at stratum 1 (48 tiles) and three from stratum 2 (84
  tiles). From stratum 10 it gains another ring every four strata.
- **Obstacles.** The ground outside the yard is strewn with 52 crystals,
  ore veins, rubble piles, crates and vents, as obstacles. A tile the yard
  reaches is cleared of its obstacle. Eight lamps stand on the slab's edge.
- **Old saves.** A 7 x 10 board moves in beside the Core (`Grid.LEGACY_SHIFT`).

**Room paces a shaft, so the yard is held near the old board.** With the
whole 44 x 44 open, the journey lab's competent player never runs out of
room. After half an hour it had 130 machines at stratum 13; on the 7 x 10
board it had 70 at stratum 5. So the yard is held at 84 tiles, near the old
board's 70, until stratum 10. (Changed in the overnight round: the lab
player behind these numbers paid for machines it could not place, which
hid the real pace. See "Descend: the pace".)

| descend to | 7 x 10 board | 44 x 44, this yard |
|---|---|---|
| stratum 1 | 176 s | 178 s |
| stratum 2 | 312 s | 334 s |
| stratum 3 | 386 s | 412 s |
| stratum 4 | 463 s | 493 s |
| stratum 5 | 554 s | 561 s |
| after 30 minutes | stratum 5, 70 machines | stratum 7, 84 machines |

The half hour ends two strata deeper, because 84 tiles are more than 70.
That is the one measured change to the pace.

**The camera now bounds on the world, not on the painting.** Its centre
stays over the slab. The painting slides at 0.12 of the camera's speed and
is never drawn smaller than covers the screen from where it is looked at,
so there is no void anywhere. It zooms out to 0.22, enough to see the
whole board on a phone.

The default view frames the Core and the yard. It stops at zoom 0.55 for a
yard too big to see whole, where a tile is about 21 dp on 2:1, and the rest
is a pan away.

**The ground is drawn once and kept.** The island, the slab and all 1,936
tiles are redrawn only when what they show changes. Panning and zooming
move that drawing without redrawing it.

Measured back to back on the same machine, on the desktop probe:

| | before | after |
|---|---|---|
| idle frame p50 | 15.7 ms | 15.3 ms |
| sim tick | 1.42 ms (36 machines) | 1.30 ms (42 machines) |
| draw calls | 184 | 137 |

The machine was running slower than in the earlier rounds' 9.8 ms
measurements, which is why the comparison is back to back.

The layout check now checks a deep shaft (stratum 14):
- the Core is in view and clear of every panel
- a tile is at least 19 dp at the default zoom

It also runs the yard at strata 0, 1 and 3 as before. On 2:1 a new game
opens with the 6 x 6 yard square (the Core and its ring) centred, at 40 dp
tiles.

### The yard: a small start that grows

(Superseded by the ring round the Core above. It is kept for the
measurements that sized the steps.)

A new shaft no longer hands the player all seventy tiles. The shape of it:
- **Where it starts.** A 4 x 4 yard at the board's corner, beside the
  Factory Core, is lit and outlined. The rest of the board is darker ground
  the factory has not reached yet.
- **How it grows.** Every stratum of the first shaft widens the yard (16,
  35, 48, 56, then all 70 tiles). The Foreman says so when it happens.
- **What a tap outside it does.** A tap there says at which stratum that
  ground opens (`BuildArea.opens_at`).
- **After the first collapse.** The whole board is open from the start.
- **Older saves.** A machine an older save left outside the yard keeps
  working, and can be sold or moved inward.

**Growth is an event you see.** When a descent widens the yard, the new
ground lights up in a wave that spreads out from the old yard, and the view
glides out to take it in. A descent usually opens a "new machine" card
first. The wave, the glide and the Foreman's line wait until that card is
closed, so the player sees the ground grow instead of it happening behind
the card. The screenshot tool's `first` capture records it
(`first_04_yard_grows`, `first_05_bigger_yard`).

While the yard is smaller than the board, the default view frames the Core
and the yard instead of the whole board. That puts the thing to build on,
and the thing to tap first, at the centre of the first screen.

**Sized so it never holds a player back.** `tools/journey_lab.gd`
(`LODEWORKS_JOURNEY=first`) plays a competent player through the first half
hour. Without the yard (`LODEWORKS_NO_YARD=1`), that player had built 14,
31, 42, 53 and 64 machines when it descended from strata 0 to 4. Each yard
step is at least that many tiles.

Measured on the same model:

| descend to | without the yard | with the yard |
|---|---|---|
| stratum 1 | 176 s (14 machines) | 191 s (14 machines) |
| stratum 2 | 312 s | 331 s |
| stratum 3 | 386 s | 406 s |
| stratum 4 | 463 s | 488 s |
| stratum 5 | 554 s | 559 s |

The yard's corner shape makes the model's reading-order placement a little
less efficient early on (+15 s to the first descent). By stratum 5 the two
are within 1%.

A first try with a 3 x 3 yard was measured and dropped. The first descent
took 564 s instead of 176 s, and after half an hour the player was only at
stratum 1.

The layout check now also checks a new game on every screen shape and safe
area:
- the whole yard is on screen and no panel covers it
- no panel covers the point on the Core the game asks the player to tap

At the default zoom of a new game, a tile is now 39–41 dp on the phone
shapes instead of 32–34. On tablets the view stops at zoom 1.15 so the
world stays in sight. A shaft with the whole board open frames exactly as
before: 21.5% of a 2:1 screen.

### The Core grows with its shaft

The Factory Core now has a level, from 1 as a shaft opens to 5 at the
fourth stratum. The level reads the depth the shaft has already reached, so
it asks nothing new of the player. It only changes how the Core looks:
- **Size.** A level-1 Core is 84% of the full picture, and each level adds 4%.
- **Level 2.** A halo at the Core's base, and lit conduits with light running
  along them from the Core into the tiles beside it. One conduit at level 2,
  up to three from level 4.
- **Level 3.** Motes of energy circle the Core, one more for each level
  above.
- **Level 5.** A slow flare from the Core's crystal.

Tapping an online Core names its level and the stratum at which it grows
next.

(Changed in the overnight round, 25 September 2026. Five levels by
stratum 4 left the Core the same for the rest of a shaft, and a shaft now
runs much longer. The Core now has eight levels, one for each ring of
yard round it: level 5 at stratum 7 and level 8 at stratum 16, so each
widening of the yard is also the Core growing. It stops growing in size at
level 5, so it never covers its ring. From level 6 a column of light rises
from its crystal, taller each level. From 7 a second orbit circles its
top, and at 8 the crystal never goes dark (`ui_core_level8.png`).
`test_the_core_grows_with_its_yard_all_the_way_down` checks that every
level is reached, on a stratum where the yard widens.)

**The dark Core stays clear of every panel; an online one may not.** Only
the dark Core, the thing a new game asks the player to tap, is kept clear
of every panel. Keeping an online Core clear as well cost too much: a
four-strata yard came out at 27 dp tiles instead of 36 on 18:9.

The layout check now runs the yard at three sizes. On 18:9 at the default
zoom:

| state | yard | tile |
|---|---|---|
| a new game | 4 x 4, 8% of the screen | 44 dp |
| stratum 1 | 5 x 7 | 42 dp |
| stratum 3 | 7 x 8 | 36 dp |
| whole board | 7 x 10 | 35 dp |

### The world's colour

Measured with `tools/visual_compare.py` against three panels of the
reference concept (the start, processing and growth panels):

| | saturation | warmth | colourfulness |
|---|---|---|---|
| reference panels | 0.55-0.58 | 0.12-0.16 | 24.5-25.9 |
| new game, before | 0.39 | 0.04 | 22.0 |
| new game, after | 0.47 | 0.085 | 27.0 |
| mid-game board, before | 0.46 | 0.065 | 30.4 |
| mid-game board, after | 0.51 | 0.099 | 34.3 |

Two things were making the screen cool and flat. A blue-grey haze sits
over the painting, and the Surface band's tint leans blue.

The fix is a grade in the shader the world is already drawn with:
- saturation ×1.28 and a warm tint on the painting
- saturation ×1.30 and a warm tint on the ground the factory stands on
- nothing on the machines, the lights or the interface

It adds no pass and no draw call: draw calls stayed at 128 on the
reference board, and idle frame p50 at 9.8 ms. Brightness and contrast did
not move (0.33 / 0.20 new game, 0.40 / 0.22 mid-game).

It stops short of the reference on purpose. The reference is a poster; a
screen looked at for an hour should not be as loud.

### The interface steps back

The panels covered 26% of a 2:1 screen, on a new game as much as on a deep
one. The layout check now prints the share (`hud%`), for a shaft with the
whole board and for a new game.

| | new game, 2:1 | whole board, 2:1 | whole board, 16:9 | board share, 2:1 |
|---|---|---|---|---|
| before | 26.0% | 26.0% | 23.1% | 21.5% |
| after | 11.6% | 16.9% | 20.2% | 22.6% |

**Parts appear when they first mean something.** A new game shows the
stratum, the credits, the settings key, the zoom key, the Codex, the tray
and Descend. The rest appears when it first matters, and stays:
- **Research** (the counter and the key): once there is any research, a Lab,
  an upgrade, or a collapse behind the player.
- **Cores and Collapse**: once a collapse is possible or has happened.
- **The heat view**: from the tutorial step that asks for it.
- **The problem list**: once there is a machine that could have one.

**The tray is as wide as what is in it.** Three machines make a short tray,
and the world shows either side of it. It scrolls by dragging, with no
scroll bar to make it taller.

**Everything is a little smaller, and no key is.** The bottom bar is 110
units instead of 124, and Descend 204 wide instead of 236. Pictures, type
and panel margins are smaller. Every key is still 96 units square, the 48 dp
floor the layout check enforces.

The whole-board figure depends on how many machines the tray holds. It is
measured at stratum 0.

### Machines at work

A running machine used to have one movement, a 1.2% breath. Each type now
shows its own job:

| machine | what it does on screen |
|---|---|
| Drill | shudders, kicks up rock dust at its bit |
| Crusher, Press | stamp: a 3.5% squash at the end of every cycle, with chips flying out |
| Smelter | throws sparks out of the melt |
| Coolant | cold mist sinks off the tank |
| Vault | coins rise while material is arriving to be sold |
| Assembler | a welding flicker |
| Lab, Amplifier, Duplicator, Condenser | a pulse in the machine's own light colour |

How it is built:
- **Timed from the simulation.** A stamp lands when the machine's cycle
  completes, and a vault's coins only rise while a pipe into it is carrying
  something.
- **Light only.** Every effect is drawn in the additive layer, from the one
  glow texture, so it batches with the light already there. Draw calls
  stayed at 126 on the reference board.
- **A zoom threshold.** Below zoom 0.55 nothing is drawn but the glow: from
  far out, a factory is its lights.

Cost on the desktop probe: idle frame p50 9.35 to 9.82 ms, pan and zoom
within 0.5 ms. A still screenshot cannot show any of this. Seeing it takes
running the game.

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

### Overnight round: what already existed (24 September 2026)

Read before any code of the overnight round: the docs, `layout.json`, the
scripts and the 22 commits this branch is ahead of `main` (`015fc85` to
`b8643f0`). The overnight brief repeats requests from earlier rounds, so
each one is sorted here first. Nothing marked DONE was rebuilt.

| brief item | state | evidence |
|---|---|---|
| P0 first minute: dark Core, power it, first income, first machine, first goal | DONE | `568a859`, `da2f1e2`, `f017d41`; "The first minute" above. Re-measured below, not rebuilt |
| P1 the world as the screen: HUD share, board share, safe areas | DONE | `99c2393`; the layout check prints `hud%` and checks 11 shapes x 3 safe areas |
| P2 camera: pinch, pan, fling, wheel, invisible bounds | DONE | `c10ae71`, `fbc9ad5`, `c6124a9`; `tests/test_iso.gd` |
| P2 touch: the tap takes the machine it is on | DONE | `848bad3`, 86.0% at a 1.5 mm finger spread |
| P2 the +/- key | PARTIAL | one key that toggles between the framed view and 1.6x zoom; decided this round |
| P3 the Factory Core as the centre that grows | DONE | `c3dc4fe`: five levels by stratum, size, light, conduits |
| P3 locked ground that shows the future | DONE | `c6124a9`, `a22dbbb`: the ring round the Core, grey tiles, the stratum shown on a tap |
| P4 placing: preview, move, remove, undo | DONE | placement preview with heat and boost numbers (`test_the_placement_preview_tells_the_truth`) |
| P4 machine categories | MISSING | the tray is in unlock order; this round |
| P5 pipes: seams, flow beads, light over machines, stall tint, selected links on top | DONE | `3f8df0b`, `iso_view._pipe`, `_selected_links` |
| P6 progressive HUD | DONE | `99c2393` |
| P6 warning escalation | MISSING | a count on the key, dimmed at zero; nothing grows with the count |
| P6 the flame key | PARTIAL | toggles the heat view; its picture never changes |
| P7 Research as picture cards, three to a row | DONE | `b8643f0`, this round |
| Collapse as a card | PARTIAL | icons since `9d82995`; the card this round |
| P8 Codex | PARTIAL | 12 concept pages with running boards and long sentences; no page per machine |
| P9 Settings | PARTIAL | one column with sound, haptics, statistics, ad privacy, shop, Codex and self test; no groups |
| P10 Descend | PARTIAL | a 1.4 s dive, a tint per depth band, next unlocks on the key; the pace between descents gets faster, not slower (measured below) |
| P11 machines at work | DONE | `b33c28a`: each type has its own movement |
| P12 world colour | PARTIAL | saturation 0.467 against 0.55 in the reference (`d0af932`) |
| the unlock as a reward moment | DONE | `e1735f0`, the NEW! card |
| 55 x 55 world | SUPERSEDED | the owner chose 44 x 44 (`c6124a9`) |

Duplicates and dead systems found:
- **Two machine renderers.** `MachineArt` drew machines from rectangles.
  The game draws them from the sprite sheets, and `MachineArt` was left
  only in the icon and feature graphic tool (`tools/brand_painter.gd`), so
  the launcher icon showed machines the game no longer has. Later that
  night the icon and feature graphic were redrawn from the Core and the
  machine sheet, and `MachineArt` was removed (below, "The store icon").
  Its leftovers in `Palette` went too (`d9e3574`): the glyphs, silhouette
  families, resource marks and the face/block lighting helpers, about 200
  lines that nothing called. Two unused dialogs in `main.gd` went as well.
- **Blueprints.** The simulation, a research line and the Licence all add
  blueprint slots, but no screen saves or loads a blueprint. It is listed
  under "What is still UNKNOWN" as the owner's decision.

**The brief used Clash of Clans as a reference for habits, not content.**
This is how its habits map onto the factory, and where each one stands.

| habit | in Lodeworks | state |
|---|---|---|
| a central building everything grows round | the Factory Core in the middle of the 44 x 44 board | DONE |
| building level readable from the picture | the Core's five levels; machine upgrade marks in the sheets | DONE |
| locked land that shows what is coming | the yard ring, grey tiles, "reaches here at stratum N" | DONE |
| select, then information, then action | tap a machine: the sheet with its picture, recipe, gauges and "?" | DONE |
| a big main action where the thumb is | DESCEND, bottom right, with the next unlocks on it | DONE |
| a small goal always in view | the quota bar and the tutorial line | DONE |
| a new building as a reward | the NEW! card, then the machine waiting in the tray | DONE |
| upgrades as picture cards | Research grid | DONE this round |
| builder-style categories | machine groups in the tray and the Codex | this round |
| alerts that grow with the trouble | the problem key | this round |

### Overnight round: where it ended (25 September 2026)

The same items, at the end of the round. The reasons and measurements are
in the sections below.

| brief item | state | commit |
|---|---|---|
| P0 first minute | DONE, plus a tutorial arrow and two tutorial lines corrected | `110c0b8`, `816cc1b` |
| P2 the +/- key | DONE: off by default, an Accessibility switch | `fd5e69d`, `22306ae` |
| P3 the Factory Core | DONE: 8 levels, one per yard ring, to stratum 16 | `d8fbf2f` |
| P4 machine groups | DONE: 7 groups, read off each machine's data | `828e581` |
| P4 the Remove key on the machine sheet | DONE (added) | `ab5dcef` |
| P6 warning escalation | DONE | `fd5e69d` |
| P6 the flame key | DONE: reads the board's heat badges | `fd5e69d` |
| P6 the stratum card explains its rules | DONE (added) | `d15ae35` |
| P6 the Descend key calls when ready | DONE (added) | `14a3799` |
| P7 Research | DONE | `b8643f0` |
| Collapse | DONE | `cd2944f` |
| P8 Codex | DONE | `e2e1920` |
| P9 Settings | DONE | `22306ae` |
| P10 descent pace | DONE: slower middle and late game, measured | `532ce97` |
| P10 the plunge and the band's name | DONE | `532ce97` |
| P10 a different look per depth beyond the band tint | PLANNED: props and ground per band need art |  |
| P12 world colour | PARTIAL: tried and put back; needs multi-hue ground art | `20ab97b` |
| P13 store icon and feature graphic | DONE, and `MachineArt` removed | `9d0dae3` |
| P13 shop layout | DONE | `7cac861` |
| things the game said that were not true | FIXED: Deeper Bore, blueprint offers hidden, research after a collapse | `b8643f0`, `98b919e`, `0cca9c9` |
| the journey lab's player | FIXED: it paid for machines it could not place | `532ce97` |

**The brief's five questions.** Each feature was checked against them.
None of this was asked of a real player, so the first three columns are a
judgement from the screenshots. The last column is measured.

| feature | easier to understand | fewer taps | livelier | more factory | frame cost |
|---|---|---|---|---|---|
| Research grid | yes: picture, state and price in one card | same (one tap to buy) | yes | yes (machines on the cards) | none at rest |
| Collapse card | yes: gains and losses as pictures | same | yes | yes | none at rest |
| Codex by group | yes | fewer to find a machine (one tab) | yes (moving machines) | yes | only while open |
| Machine groups | yes (same sign in tray and Codex) | same | no | yes | none |
| Alarm and flame keys | yes: state before a tap | fewer (no need to open the heat view to know) | yes | yes | 0.25 ms twice a second |
| Settings | yes | fewer (every row is one tap) | no | no | none |
| Tutorial arrow | yes | fewer wrong taps | yes | no | one small draw |
| Remove key | yes: it can be found at all | same as the long press | no | no | none |
| Descend halo | yes | no | yes | no | a stylebox change |
| Core levels 6-8 | yes (the Core keeps changing) | no | yes | yes | a few glows |
| Slower middle game | not about understanding | no | no | yes (more building per stratum) | no change |

The whole round cost 0.2 ms of idle frame and 17 draw calls on the
desktop probe ("What the overnight round cost the frame").

**The first five minutes, re-measured** with the journey lab's first half
hour (`LODEWORKS_JOURNEY=first`) and the `first` screenshots:

| time | what the player has | what tells them the next step |
|---|---|---|
| 0-10 s | a dark Core in the middle of the rock | the Core glows and the tutorial line says to tap it |
| 10-30 s | the Core running, 40 credits banked | the lit ring round the Core and the pulsing Drill in the tray |
| 30-60 s | Drill and Vault; the first credit 2.1 s after both stand | the next tutorial line, and the counter rising |
| 1-3 min | 3 machines at 1 min, 14 at 3 min | the quota bar filling; the first descent at 178 s |
| 3-5 min | stratum 1, a wider yard, Smelter and Boiler | the NEW! card, then the machines waiting in the tray |

Nothing in it blocked the first descent, so the opening was not rebuilt.
The pace after it is not right, and is the Descend item below.

**One thing was added to it: an arrow.** A fat yellow arrow bobs over the
next thing to tap. It points at the dark Core first. During a tutorial
step about the board, it points at one lit tile, the one beside the Core's
right-hand corner, clear of the Foreman and the toasts. For the heat and
descend steps, it points at the key. It goes away when the tutorial ends
or a panel opens. "Reduce motion" stops the bob. The move step's line
says "Tap the Vault", but it lit every machine, so it now lights the Vault
(`test_every_tutorial_step_is_satisfied_by_doing_the_thing`). The `first`
screenshots place their machines where the arrow points, as a player
would.

Two tutorial lines told the player something untrue:
- **"Tap DRILL below, then tap a lit tile"** was wrong because the Drill
  is already armed for them. Tapping its key un-arms it, so doing what the
  line said broke the step. It is now "Tap a lit tile by the Core to build
  a DRILL."
- **"Reach the quota at the top right"** pointed at the wrong corner. The
  quota bar is on the stratum card, top left. It is now "Build more until
  the bar at the top left is full."

### The panels, shown before they are read

The rule for this pass: the player should see a panel before reading it.
Each panel below was rebuilt on it. `LODEWORKS_CAPTURE=ui` renders them
into the audit folder, and the smoke test opens each one and checks it
against the simulation.

**Every panel.** The title row carries a close key in the corner, 96
units square. The word "Close" at the bottom is gone. Every "?" key is 96
units, the 48 dp floor, and so is a panel's action key. A panel is as tall
as what it holds, up to the screen, instead of always 700 units.

**Research** (`ui_research.png`) is a grid of cards, three to a row on a
landscape phone. It drops to two where three would not fit 330-unit
cards. Each card shows these things:
- **A picture of what the line acts on**, with a sign of what it does in
  the corner. For example, a Vault with a coin, a Lab with a flask, or the
  Core with a Core crystal.
- **The name and one short line**, such as "Every machine works faster".
  The full sentence is behind the "?".
- **Pips for the level**, and the count.
- **The price on the key that buys it.** A number the player cannot pay
  yet is red.

Each card has one of four states, set from the simulation. The smoke test
checks each card's state against `Sim.can_buy_upgrade`.

| state | how it looks |
|---|---|
| can be bought | violet edge, lit key |
| short of research | plain edge, dim key, the missing number red |
| needs Cores first | the picture grey, with a lock over it |
| finished | gold edge, a tick and MAX |

What there is to spend sits beside the title, as the same two pictures.

Deeper Bore's sentence was wrong. It said only machines that produce from
nothing yield more, but the multiplier is on every machine's output
(`Simulation.yield_mult`). The sentence now says so.

Drafting Table sells blueprint slots. No screen in the game saves or
loads a blueprint, so the slots exist in the simulation and the store but
nothing uses them. A card that takes research and changes nothing the
player can see is a fake, so the grid no longer offers it
(`HIDDEN_RESEARCH`). The upgrade stays in the data, and a save that has
bought it keeps its level. For the same reason the Licence's shop page no
longer lists "Two more blueprint slots", though the grant is kept. Both
come back with a blueprint screen, which is the owner's decision.

**Collapse** (`ui_collapse.png`, `ui_collapse_locked.png`) is one card.
- **Open**, it shows the trade: the Core, an arrow, and the Cores it pays,
  big. Under that, what goes is crossed out: the machines, credits,
  research points and depth. What stays is ticked: the Cores and the
  researched upgrades. That is exactly what `Sim.collapse` resets and keeps.
- **Locked**, it shows the Core grey behind a lock, and one Descend step
  for each stratum up to the one it opens at, lit as they are passed.
- **The Collapse key** is disabled when there is nothing to collapse for
  (`Sim.can_collapse`). Before, it could be pressed and did nothing.

The smoke test checks the card's state against the Sim. The mechanics did
not change.

**Machine groups.** Every machine is in one of seven groups, shown with
the same picture in the tray and the Codex. The groups come before the
Codex here because the Codex is filed by them.

| group | picture | machines |
|---|---|---|
| Diggers | pickaxe | Drill |
| Makers | gear | Crusher, Smelter, Press, Assembler |
| Sellers | coin | Vault |
| Heaters | flame | Boiler |
| Coolers | snowflake | Coolant Cell, Condenser |
| Boosters | lightning gear | Amplifier, Duplicator |
| Research | flask | Lab |

A machine's group is read off what it does, not from a list. `source`
makes a Digger, `sink` a Seller, and a recipe with an input and an output
a Maker. The test `test_every_machine_is_in_the_group_that_says_what_it_does`
checks each group against the machine's own data. For example, a Heater
has to emit heat and a Cooler has to remove it.

The brief suggested groups for collecting and for storage. No machine
collects, and the Vault sells rather than stores, so those groups were not
made. No machine was renamed.

The tray is in group order, with a thin seam between groups and the
group's picture in each key's corner. Each group is in unlock order, so a
new game's tray is still Drill, Crusher, Vault. Every machine also has a
short line now, such as "Crushes ore into gravel", which the Codex shows.

**The Codex** (`ui_codex_makers.png`, `ui_codex_boosters.png`,
`ui_codex_rules.png`) was twelve pages of rules, each a running board
with two sentences under it. It is now filed by group. A row of keys
along the top has one key per group, with the tray's picture, and one for
"How it works".
- **A group's page** shows its machines as cards. Each card has the
  machine big and moving (200 units, the unlock card's size), its name,
  one short line such as "Melts gravel into ingots", and a flame or
  snowflake if it wants heat or cold. The flame appears when the machine's
  best heat is 1 or more, the snowflake when it chokes past 3 heat.
- **The flow row** at the bottom of each card shows what goes in, the
  machine, and what comes out, in the board's own gem colours. A machine
  with no recipe shows what it does to its neighbours instead: heat, cold,
  speed, or x2.
- **A machine not reached yet** is a dark shape with a lock and the
  stratum it opens at. The Codex also shows what is coming.
- **How it works** keeps the running boards, 96 units a tile instead of
  64. Each page has a title of a few words and one plain line, such as
  "Too much heat slows a Press down". The old two sentences are behind the
  "?".
- **The unlock card** now names the new machine and gives its one line.

Tests check that every page has a short line and a short title. The smoke
test checks one key per group, every machine on its own group's page
exactly once, and every reached rule page shown.

### Descend: the pace

The brief asked for quick early descents and noticeably longer ones in the
middle and late game, with no waiting for its own sake. The pace was
measured first, with the journey lab's player over its first hour
(`LODEWORKS_JOURNEY=first LODEWORKS_JOURNEY_SECONDS=3600`).

**The lab had a bug that hid the real pace.** Its player paid for a machine
before looking for a tile, so once the yard was full it threw its credits
away every half second. That read as a wall at stratum 7, which the game
does not have: `Sim.try_place` refuses a closed tile without charging.
With the bug fixed, the real curve got faster, not slower, in the middle:

| stratum reached | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| before, seconds taken | 178 | 155 | 79 | 81 | 68 | 131 | 73 | 46 | 17 | 23 | 33 | 47 | 338 |
| after, seconds taken | 178 | 156 | 117 | 123 | 122 | 246 | 144 | 187 | 333 | 495 | 732 | | |

There were two causes:
- **The yard stopped at 84 tiles from stratum 2 to 10.** Once it was full
  there was nothing to spend on, so credits piled up.
- **The quota grew more slowly than income.** It grew 1.55x a stratum.
  Deeper rock pays more (`Strata` richness), so a full yard cleared each
  new quota faster than the one before.

What changed:
- **The quota grows 1.8x a stratum** (`Strata.quota_for`). The first quota
  is unchanged.
- **The yard keeps growing through the middle.** It is three rings at
  stratum 2, four at 4, five at 7, then one more every three strata from
  10 (`BuildArea.RINGS`). A descent gives ground as well as a machine, so
  a longer stratum has building in it, not waiting.
- **The default view stops at zoom 0.6, not 0.55.** The wider yard at
  stratum 14 otherwise made a tile 17.9 dp on a 16:9 1080p phone. The
  layout check's floor is 19 dp.

After the change, the first three strata still take two to three minutes.
Strata 4 to 8 take two to four minutes each, and from stratum 9 each takes
five minutes or more. The lab's player reaches stratum 11 in its first
hour, where before it reached 17.

The cost is paid in the prestige loop:

| lab's full run (raw lines) | before | after |
|---|---|---|
| time to the end of a run | 49 min | 1 h 30 min |
| depth reached | 14 | 12 |
| lifetime credits | 374K | 1.29M |
| Cores for collapsing there | 46 | 46 |

A collapse pays the same Cores for a run about 1.8 times as long, so Cores
per hour fall by roughly 45%. Raising the collapse payout would restore
them. That is an economy decision this round did not make, and it is
listed under "What is still UNKNOWN". The test that stops the curve walling
out (`test_the_curve_does_not_wall_out_by_depth_twenty`, under 12 hours
at stratum 20) still passes. Both changes are single constants and can be
put back.

**The plunge itself.** A descent used to plunge the world for 1.4 s at
every depth. Now it takes 1.4 s near the surface and up to 2.0 s deep
down. Going into a new band (the Workings, the Deep, the Abyss) takes
2.6 s, and the band's name crosses the screen in its own light
(`ui_band_banner.png`). The plunge waits while the NEW! card covers the
world, so the player sees it instead of it happening behind the card. The
board keeps running and takes taps throughout; `test_a_descent_into_a_new_band_takes_longer_than_one_inside_it`
caps it at 2.6 s.

### The three keys on the right edge

**The Problems key grows with the trouble** (`StatusBadges.alarm_*`).
It was a count on a key that dimmed at zero. Now it escalates with the
number of problems:

| problems | what the key does |
|---|---|
| 0 | dimmed |
| 1-2 | the count, nothing more |
| 3-5 | a slow swell in size and a warm light behind the sign |
| 6-11 | a faster, larger swell and a stronger light; the warning tone once, lower |
| 12 and more | red light, the count in red, the fastest swell |

The swell's speed and size come from the count: 0.45 swells a second
plus 0.07 per problem, and 3% bigger plus 0.6% per problem. It is capped
at 1.25 swells a second and 10% bigger. That is a smooth swell, not an
on-off flash, and it stays well under the three flashes a second that
photosensitivity guidance draws the line at.
`test_the_problem_alarm_grows_with_the_count_and_never_flashes` checks
that it never calms down as the count rises and never passes either cap.
The tone reuses the heat warning's sound, a little lower, and shares its
twenty-second gap. The two never stack.

**The zoom key is gone by default.** It did one thing, jump between the
framed view and 1.6x, which pinch, the mouse wheel and the trackpad all
already do. Removing it gives the world back about one point of the
screen:

| hud share, 2:1 | with the key | without |
|---|---|---|
| new game | 12.8% | 11.8% |
| stratum 1 yard | 15.6% | 14.6% |
| stratum 3 yard | 19.6% | 18.6% |
| deep shaft | 23.2% | 22.3% |

A player who cannot pinch can turn it back on under Settings,
Accessibility. Nothing replaces it: the brief said not to add a key just
to fill the gap.

**The flame key shows the board's heat before it is opened**
(`StatusBadges.heat_state`). It has no gauge of its own. It reads the same
badges the board shows, so the key and the board cannot disagree, and the
badges' 1.5 s hold means it cannot flicker.

| state | when | the key |
|---|---|---|
| calm | every machine within a tenth of its best | grey |
| warm | some machine giving up a little (MILD) | lit, faint glow |
| hot | a machine badged too hot or too cold | warm glow, slow flicker |
| critical | a machine choking, under 40% | red glow, faster flicker |

When cold is what costs, the flame becomes the snowflake. The flicker is
at most one a second. `test_the_heat_key_tells_the_boards_heat_before_it_is_opened`
builds a calm board, a Press between two Boilers, and a Smelter against a
Coolant Cell, and checks the key on each.

The cost was measured. Reading the badges takes 0.245 ms for 180
machines on the desktop, so the key reads them twice a second, not ten
times. The alarm's arithmetic is 0.5 microseconds a frame. The perf probe
(`LODEWORKS_SOAK=20`) was run back to back on the hero board, before and
after:

| | before | after |
|---|---|---|
| idle frame p50 | 11.82 ms | 11.84 ms |
| 20 s soak p50 | 11.46 ms | 11.60 ms |
| draw calls | 163 | 163 |

The difference is inside the run-to-run spread. "Reduce motion" in
Settings stills both the swell and the flicker, and keeps the light.

**The Descend key calls when it is ready.** Before, it went from dim to
bright when the quota was met, and that was all. Now it gives one punch
at that moment, and while the way down stays open a warm halo swells
round it once every two seconds. The halo is drawn as the key's own
shadow, so it costs no extra node. "Reduce motion" holds the halo still.
Building games make the one big action do this: the player sees that it
is ready without reading anything.

### Settings

Settings was one column: the shop, sound, haptics, statistics, ad privacy,
a Codex button and the self test. It is now a landscape panel, with five
groups down the left and the chosen group's rows on the right
(`ui_settings_*.png`). A row is one key, 96 units tall, with its sign, a
few words and its switch.

| group | rows |
|---|---|
| Game | Codex, Supply Office, anonymous statistics, ad privacy (only when the ad plugin is present), device self test |
| Audio | sounds, ambience, volume in five steps with a key either side |
| Graphics | machine effects, battery saver |
| Controls | vibration |
| Accessibility | zoom key, reduce motion |

Every row changes something real, applied in one place
(`main._apply_settings`):
- **Ambience** is its own switch now. It is the shaft's hum, which used
  to go on and off with the sounds.
- **Volume** is the master bus, and 0 mutes it.
- **Machine effects** turns off the dust, sparks, steam and coins round
  working machines. That is the light layer's heaviest part.
- **Battery saver** caps the game at 30 frames a second instead of 60.
- **Zoom key** brings back the key taken off the right edge.
- **Reduce motion** stills the Problems key's swell, the flame key's
  flicker, the tutorial's pulse and the plunge on descending, and (since
  the gap audit, B5) the bobbing marks over a selected machine and on
  status badges, the Foreman's idle bob, the new-machine card's bob, the
  hot machines' flicker and the punch on Descend and the stratum card;
  the camera cuts to where it was going instead of gliding. The lights,
  colours and fades stay, and so do the beads that show material moving
  along a link: they are the information, not decoration. Machine
  animation has its own switch, Machine effects.

The smoke test flips nine of these switches (with Sounds, Anonymous
statistics and Reduce motion since) and checks that each one changes
what it names, and that flipping it back restores it; it presses
Volume's - and + and checks the master bus moves and comes back. Things the
brief listed but the game does not have got no row: music, notifications,
language, an account or cloud save, and camera sensitivity. The version
number sits under the groups.

**The shop** (`smoke/05_shop.png`) keeps every word it had, because a
shop is where copy has to be exact. It is laid out for landscape now: the
two products sit side by side on a screen 1,100 units wide or more, and one
above the other on a narrower one. Its close key and its Buy key are 96
units, where they were 52. Restore purchases is 80 units, where it was 46.

**The machine sheet has a Remove key** (`04_machine_closeup.png`). A
machine could only be removed with a long press, which a new player has
no way to discover. Selecting a machine now shows a bin key beside its
"?". It opens the same Remove card as the long press, with the machine,
an arrow and the credits that come back. Builder games do it the same
way: select, see, then act.

**The stratum card opens** (`ui_stratum.png`). The card in the top left
named the stratum's modifiers, such as "Dense Seam", and nothing in the
game said what they do. A comment claimed the Codex did, but it never had
a page for them. A tap on the card now opens a card of its own:
- the band, in its own colour
- the credits against the quota, with a bar
- each modifier with a star, its name and its one-sentence effect from
  `Strata.MODIFIERS`, or "Plain rock" when there are none

The card's own quota line is now a coin and the number, where it used to
say "descend at 3.95K".

### The store icon

The launcher icon (`store/brand/icon-192.png`, the adaptive foreground) and the
store icon and feature graphic were still the rectangle machines from
before the art. That icon is the first picture of the game anyone sees,
on the phone's home screen, and it showed a game that no longer exists.
They are now drawn from the game's own pictures:
- **The icon** is the Factory Core, lit, with a Drill and a Vault at its
  feet, on the canyon painting darkened so it holds at 48 dp.
- **The adaptive foreground** keeps the same picture inside the middle 60%
  that every launcher mask leaves visible.
- **The feature graphic** has the name, the five resource colours, and two
  plain lines on the left. The Core and its first four machines stand on
  the right.

`tools/check-store-assets.py` passes: the icon is 512 x 512, 24-bit, 498
KB, and the feature graphic is 1024 x 500 with no alpha. With the icon
redrawn, nothing used `MachineArt` any more. It was removed, and its test
now checks that every machine has a picture in the machine sheet.

### Planned: a different look per depth

The brief asked for each depth to differ in camera, colour, light,
ground, crystals, decoration, danger, resources and machine behaviour, or
at least in some of them. Today a depth differs in these ways:
- **Colour and light.** Each of the four bands tints the world, the ground
  and the props, and the plunge into a new band is longer, with the band's
  name.
- **Rules.** Each stratum has its own modifiers, now explained on the
  stratum card.
- **Room.** The yard widens, and the Core gains a level.

The rest needs new art, so it is planned rather than done:

| band | ground | props | what it costs |
|---|---|---|---|
| Surface (0-3) | today's tiles | today's crystals, crates, lamps | nothing |
| Workings (4-9) | worn tiles with timber and rail | lanterns, carts, copper ore | one prop sheet, one tile sheet |
| Deep (10-16) | dark red rock, glowing cracks | red crystals, lava vents | one prop sheet, one tile sheet |
| Abyss (17+) | black basalt, violet veins | violet crystals, bone-white rock | one prop sheet, one tile sheet |

Each sheet would go through `tools/art_build.py` like the existing ones,
from a prompt that references the current sheet's job so the camera and
light hold (`docs/ART.md` section 1). At the last round's prices that is
six Higgsfield images, about 17 to 26 credits. `layout.json` would gain a
sheet per band, and `IsoView` would pick the sheet by `Palette.band_at`.
The same new art is what would close the colour gap measured below,
because it brings more than one hue into the ground.

### What the overnight round cost the frame

The perf probe (`LODEWORKS_SOAK=20`, hero board) was run on `9d82995`,
where the round started, and on `d15ae35`, back to back on the same
desktop:

| | 9d82995 | d15ae35 |
|---|---|---|
| idle frame p50 / p95 | 11.68 / 15.19 ms | 11.86 / 15.66 ms |
| 20 s soak p50 | 11.32 ms | 11.57 ms |
| draw calls, idle | 148 | 165 |
| nodes | 185 | 209 |
| static memory | 46.1 MB | 47.2 MB |
| texture memory | 34.0 MB | 33.4 MB |

Most of the extra draw calls come from the wider yard at stratum 7, which
has more lit tiles, and from the tray's group signs. The frame is 0.2 ms
slower, which is inside the probe's run-to-run spread on this machine. A
phone is still UNKNOWN.

At the end of the round (the Core's levels 6 to 8, the Descend halo, the
cleanups), measured again the same way:

| | 9d82995 | end of round |
|---|---|---|
| idle frame p50 / p95 | 11.68 / 15.19 ms | 12.03 / 15.77 ms |
| 20 s soak p50 | 11.32 ms | 11.65 ms |
| draw calls, idle | 148 | 165 |
| nodes | 185 | 210 |

That is about 0.35 ms, or 3%, on this desktop. The Descend halo redraws
its key, so it updates fifteen times a second rather than every frame.

### World colour: tried and put back

The world's saturation is 0.40 to 0.43, and the reference concepts sit at
0.57 to 0.68. The grade shader was tried with more saturation and some
contrast (`tools/visual_compare.py`, back to back):

| | saturation | contrast | warm-cool |
|---|---|---|---|
| now, hero board | 0.429 | 0.164 | 0.212 |
| saturation 1.46, contrast 1.14, same warm tint | 0.468 | 0.168 | 0.251 |
| saturation 1.40, contrast 1.14, neutral tint | 0.424 | 0.166 | 0.209 |
| `ref2.png` | 0.571 | 0.263 | 0.021 |

The first try moved saturation toward the reference, and warmth away
from it: the ground is one warm hue, so more saturation made it more
salmon. The second, without the warm tint, gave the saturation back. The
reference's colour comes from many hues side by side, such as green moss,
blue crystal and gold, not from a stronger one. The grade was put back.
Closing the gap means ground tiles and props with more than one hue in
them. That is art generation, and it was left for a round that can afford
it.

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

### The ground round the Core (25 September 2026)

**The cells behind the Core.** The Core picture is taller than its block,
so at stratum 1 it covers four open yard cells: (19,19) all of it, (18,18)
90%, (20,19) 74%, (19,20) 66% (share of the cell's diamond under an opaque
pixel of the Core, `IsoView.cells_behind_core()`). A player could buy
them and not see them, and a machine placed there could not be tapped:
the Core took the tap. The camera and the Core were not moved; moving
either changes every screen the layout check measures. Instead:
- while a machine is armed or dragged, the hidden cells outline themselves
  and the Core thins to 40%, so the finger can see where it lands;
- a machine standing on one is drawn again over the Core as a pale blue
  ghost, and a tap on that ghost selects the machine, not the Core;
- the list is worked out per Core level, because the picture grows.

**The Core's foundation.** The Core's own 4 x 4 block was drawn like
locked ground, and its front and side cells show 23-52% of their diamond
beside the Core picture. They are now the Core's grey plinth with a brass
outline, and a tap on them is a tap on the Core.

**The props.** They were 60 hand-placed props, 4.5% of the ground in
reach 3 to 10 of the Core, spread evenly. `tools/props_layout.py` now
writes them (docs/ART.md, "Props"): 92 props with the lamps, 6.8% of
that ground, in one-kind clusters by region, with two clearings in front
left bare. No new art, no new kinds. Measured by `tools/layout_check.tscn`
(props whose picture is on screen at the default view, and how many of
them are nodes):

| view | before | after |
|---|---|---|
| stratum 0, 18:9 | 12 (9 nodes) | 10 (9 nodes) |
| stratum 0, 16:9 | 14 (10 nodes) | 11 (10 nodes) |
| stratum 1, 18:9 | 14 (10 nodes) | 11 (11 nodes) |
| stratum 1, 16:9 | 9 (6 nodes) | 9 (9 nodes) |
| stratum 3, 18:9 | 13 (7 nodes) | 16 (14 nodes) |
| stratum 3, 16:9 | 11 (7 nodes) | 11 (11 nodes) |

At the default view the count barely moves, because most of the new
props stand further out; what changes is what is seen: clutter near the
Core gave way to nodes, and the ground in front of it is bare. The yard,
the Core and the cells on screen did not change: 20 / 48 / 84 yard cells
at strata 0 / 1 / 3, 16 Core cells, on every shape.

**What it cost the frame.** The perf probe (`LODEWORKS_SOAK=20`, hero
board, the same desktop, back to back) on `531a9ed` and on this round:

| | 531a9ed | first try | this round |
|---|---|---|---|
| idle frame p50 / p95 | 11.98 / 15.68 ms | 13.13 / 17.47 ms | 10.94 / 14.68 ms |
| 20 s soak p50 | 11.67 ms | 12.96 ms | 10.71 ms |
| draw calls, idle | 165 | 180 | 174 |
| static memory | 47.2 MB | 50.5 MB | 47.4 MB |

The first try was 1.2 ms slower, and the cost was not the drawing. Every
frame, every prop was asked where it stands and whether the yard had
cleared it, and each answer is a few dictionary lookups in GDScript: 11
microseconds a prop, measured, so about a millisecond for 92 props. The
props do not move, so those facts are now worked out once, and again only
when the yard grows (`IsoView._props_now()`). The frame ends up a
millisecond faster than before the round. The first try also read the
Core's whole picture into memory for its tap test (3.3 MB). The Core's
and the props' tap tests now keep one bit per pixel. The other nine draw
calls come from the Core's outline, the machines drawn over the Core,
and more props between the machines. A phone is still UNKNOWN.

### Resource nodes

Four prop kinds are **resource nodes**: the purple and the blue crystal,
the ore vein and the heat vent (`scripts/core/resource_nodes.gd`). A tap
on one opens a small card over it: its name, one line, what uses it, and
the stratum at which the yard reaches it. The card follows the node when
the world moves and closes on any other tap. Rubble, crates and lamps are
clutter and take no tap. A machine keeps the tap where a machine and a
node overlap, and nothing is picked while a machine is armed.

The card says only what is true. There is no resource-node economy: a
Drill digs ore from any tile, and the yard clears a node when it reaches
it. So the ore vein says "Drills dig ore." with the Drill beside it, and
the crystals and the vent say that no machine uses them yet. A node has
no link to the Core, so the same nodes can later serve a second factory.

Making nodes matter is a new mechanic, and it is left for the owner to
decide. For example, a Drill on or beside an ore vein could dig faster,
or a crystal could be mined for Research. Either one changes the economy
and the balance labs.

### The Factory Core's card

A tap on the running Core used to open three sentences. It now opens a
card, in the way a base-building game's main building shows its level
and its base:
- the Core's picture, its level as eight pips, and the stratum;
- four numbers: machines, working, need help, credits per second. "Need
  help" is the warning key's own count (`Simulation.problem_counts`), and
  working is every other machine, so the card and the key never disagree;
- how much of the yard is built, as a bar: machines out of the tiles a
  machine can stand on (open, not this stratum's rubble);
- what the next widening brings: "Stratum 10: level 6, and the yard grows
  to 16 x 16";
- with anything in trouble, a **Show me** key that goes to the first one,
  the same as a tap on the warning key.

The old sentences are behind its "?". The numbers come from
`scripts/core/factory_report.gd`, which reads a board, its simulation and
a depth and nothing else. A second factory, or another player's, can be
summed up with the same call. On the hero board the card reads 42
machines, 24 working, 18 need help, +166/s, 42 of 180 tiles (screenshot
`field_h_core`, `LODEWORKS_CAPTURE=field`). The UI smoke test opens it
and checks its numbers against the board and the warning key.

**The tray's "?".** The "?" on a tray key is 40 units, under the 48 dp
floor on a small phone, and it cannot grow inside a 98-unit key without
covering it. Holding the whole key for half a second now opens the same
words, a 96-unit target. A press that moves is still the tray
scrolling, and the release that ends a hold arms nothing (smoke test).

### A stratum's rules, on the machines they move

A stratum's modifiers were words on its card. "Every one of them should
make you want to move a tile" (`scripts/core/strata.gd`), but nothing
said which machine a rule moves, or at the moment the player chooses one.
Now:
- a tray key carries an arrow when this stratum helps its machine (green,
  up) or holds it back (red, down), by 5% or more against plain rock at
  the same depth;
- its "?" names the rule and what it does ("Helped here: Brittle Rock.");
- the stratum's card shows, under each rule, the machines it moves with
  the same arrows.

The arrow is `Strata.effect_on`: one machine alone on this rock, its
speed, yield, sale value or research, and its own tile's heat, which is
what `Strata.apply` and `Grid` give it. A test puts each of the twelve
machines alone on every stratum from 1 to 59 and checks every arrow
against the simulation's own numbers. The arrows say more than the
words did. On stratum 1 (Thermal Vent, "Your smelters will love it. Your
presses will not.") the rock's heat also costs a Drill 14% and a Vault
7%, and the tray says so. A rule that changes the whole board (Unstable,
Cramped, how far heat spreads) gives no machine an arrow. Screenshots
`field_i_rules` and `field_j_stratum` (stratum 8, Brittle Rock).

Arriving at a stratum, the Foreman now names its rules and says where to
look: "Stratum 8: Cramped and Brittle Rock. The arrows on the tray show
what changes." He mentions the arrows only when a rule moves a machine
the player has; otherwise he points at the stratum's card. The old line,
"Richer rock, stranger rules.", is kept for a stratum with no rules.

**The Research key counts what can be bought.** The Foreman's Research
nudge is said once per game. After that, nothing said an upgrade had
become affordable. The key now carries a count in its corner, the
research lines that can be bought this moment (`main._research_ready`).
It is gone at zero, so it is never a standing reminder. It is the same
rule the Research panel's cards use to show "ready". The hero board shows
7. The smoke test gives the player everything, expects the count of every
line, then nothing, and expects no count.

**What lies below.** A stratum's rules used to be learned by arriving,
and by then the board had been built for the stratum above. A tap on
Descend before the quota is met now opens the next stratum instead of a
toast. So does holding Descend at any time. The card shows:
- the band and how far off the quota is;
- its rules, with the machines they will move and their arrows;
- the machines it opens;
- the ground the yard gains.
With the quota met, a tap still goes straight down, and the card has a
Descend key. The rule rows are the same code as the current stratum's
card (`main._rule_rows`). The hold is the same as a tray key's
(`main._on_hold`), so a press that moves never counts, and the release
that ends a hold does not descend. The smoke test checks all three
(`11_below`). The Codex's "Deeper is different" page says both.

This round also put back seven line breaks that a shell had turned into
runs of tabs in earlier rounds (`main.gd`, `tools/smoke.gd`). The code
ran the same; it was unreadable.

### The smallest text on the interface

`tools/layout_check.gd` now reports the smallest shown text on the main
screen in dp on each screen shape, and fails on any under the floor. The
floor is `main.TEXT_MIN`. The first measurement:

| screen | before (13 units) | after (16 units) |
|---|---|---|
| 18:9 2160x1080, 400 dpi | 7.8 dp | 9.6 dp |
| 20:9 2400x1080, 405 dpi | 7.7 dp | 9.5 dp |
| 16:9 1920x1080, 420 dpi | 6.6 dp | 8.1 dp |
| 16:9 1280x720, 320 dpi | 5.8 dp | 7.1 dp |
| 16:10 tablet, 300 dpi | 12.3 dp | 15.2 dp |

Before, the smallest text was 13 units: the captions under Research,
Collapse and Codex, the credits per second, and the stratum's rules on
its card. 14 units was the stratum's band and quota, Descend's line and
every price on the tray, and "next:" was 12. All of them are now 16.
Every screen shape and safe area still passes the layout check. 9.6 dp is
still under Android's 12 sp body text. Reaching 12 sp would take 20 units
everywhere, and that means redrawing the keys, not changing a number.
It is a follow-up. How the text reads on a real phone at arm's length is
UNKNOWN (DEVICE-TEST `text`).

**Settings, Accessibility, "Larger text".** It makes every word the
interface writes a quarter bigger. On the reference phone the smallest
text goes to 20 units, 12.0 dp, which is Android's body text size. Every
label goes through `Palette.text_px`: the main screen's, the panels', the
Codex's and the Supply Office's. Words already on screen are resized when
the switch changes, without a restart. The layout check runs the deep
shaft a second time with the switch on: all 11 shapes x 3 safe areas pass,
and the smallest text is 11.4-12.0 dp on the landscape phones. The smoke
test flips it and checks that a caption grows. Key glyphs ("?", "✕") and
the words on the few keys that set their own size are not scaled. They
are 22-32 units already.

### What the Cores open, and three sentences that said too much

The collapse card showed the Cores a collapse pays, and nothing said what
Cores are for. It now shows the research lines whose Core price the new
total reaches and today's does not, as the research grid's own pictures:
"These Cores open these research lines." They still cost Research, which
a collapse takes, so the card says "open", not "buy". On the hero board
with 2 Cores, +5 opens Ceramic Lining, Night Shift and Standing Orders
(`ui_collapse`, `LODEWORKS_CAPTURE=ui`).

Three texts said more than the game does:
- Deeper Bore said "Every machine makes more" and "Every machine makes
  20% more of whatever it makes". Yield multiplies what a Digger or a
  Maker turns out. A Lab's research and a Vault's sale do not change. It
  now says so, and `test_deeper_bore_does_what_its_words_say` holds it.
- The Lab said "Research is the only thing that survives a collapse".
  Unspent Research is lost at a collapse; what it bought is kept. It now
  says "What Research buys survives a collapse".
- After a collapse the Foreman's card said "Cores are the only thing that
  survives a collapse". Every researched upgrade survives too. The README
  said the same. Both are corrected.

### Where a machine would work, while it is being placed

The whole game is adjacency: a machine works when something beside it
feeds it and something beside it takes what it makes. While a machine was
armed, the board outlined every empty yard tile that touched a machine,
whether or not placing it there would connect it. Now the tiles where the
armed machine would be fed and could hand its work on are filled green.
Put it there and it works.

The answer is `Simulation.links_if_placed`. It asks the same rule the
simulation moves material by (`_takers`: a Vault takes anything, anything
else what it has as an input, and a support tile passes it through)
before the machine exists. A test places every machine on every
candidate tile of twelve random boards (4,476 placements). It then asks
`_takers` of the real placement, and the answers must agree. A support
machine keeps its own mark ("serves N"). The set is worked out again only
when the armed machine or the board changes. On the hero board an armed
Vault has 15 such tiles and an armed Crusher none: no empty tile there
touches both a Drill and a buyer, and a green tile would be a promise the
board cannot keep (`field_n_linked`).

**The captures now start from a new player's settings.** An earlier
capture turned on "Larger text" and the save kept it. The next captures,
including the README pictures committed in `c15708e`, were taken with
larger text. `tools/screenshot.gd` now clears the switches a capture may
flip before it starts, and saves the setting back as it found it. The
README pictures were taken again.

### What the night cost the frame

The perf probe (`LODEWORKS_SOAK=20`, hero board, the same desktop, Intel
UHD) on `531a9ed`, where the night started, and at its end:

| | 531a9ed | end of the night |
|---|---|---|
| idle frame p50 / p95 | 11.98 / 15.68 ms | 11.06 / 14.68 ms |
| 20 s soak p50 / p95 | 11.67 / 15.63 ms | 10.80 / 14.63 ms |
| draw calls, idle (stratum 7) | 165 | 179 before the glyph change below, 177 after |
| draw calls, soak (stratum 8) | 165 | 205 before, 193 after |
| static memory | 47.2 MB | 47.5 MB |
| nodes | 210 | 218 |

The frame is faster than when the night started, because the props'
fixed facts are no longer worked out every frame. The draw calls are
higher. The soak runs at stratum 8, where Brittle Rock puts an arrow on
seven tray keys, and each arrow is its own canvas item. Drawing the
arrow's ring as two discs instead of an antialiased arc took the soak
from 205 to 193. The rest is the Core's outline, the machines drawn over
the Core, the Research count and more props between the machines. A
phone is still UNKNOWN.

### Languages: English and Turkish (25 September 2026)

Before this, every word the player reads was written into the code in
English: 0 calls to `tr()`, no translation files. Now:

- **How it works.** Every message goes through `Loc.t("...")` or
  `Loc.tn("one", "many", n)` (`scripts/services/loc.gd`). The English text
  is the key. A language that has no translation for a message shows the
  English. The data tables (machines, research, strata, the tutorial, the
  Codex, the shop, themes) keep their English, and the interface
  translates them where it shows them (`MachineDB.name_of`,
  `Strata.modifier_name`, `MonetizationDB.title_of`...). Translations are
  gettext files: `locale/tr.po`, registered in project.godot and included
  in the export. The interface turns Godot's auto-translation off, so a
  word never gets translated twice.
- **The messages.** `tools/loc_extract.gd` finds 369 messages: the
  `Loc.t` calls in the code, and the fields of the data tables
  (`tools/loc_catalog.gd`). It writes `locale/messages.pot` and keeps each
  language's file in step. A new message is added empty, and a message no
  longer used is kept, commented out. Turkish: 369 of 369, 4 of them with
  singular and plural forms. The first Turkish was seeded from a
  glossary (`tools/loc_tr_seed.py`). From now on `tr.po` itself is the
  translation.
- **Choosing.** Settings, Game, **Language** (the first row, with a
  globe): "Device language" or a language, each written in itself. The
  default is the device's language when it is translated, and English
  otherwise (`Loc.pick`). A change rebuilds the interface on the spot, with
  no restart. The game itself lives in `Sim` and is not touched.
- **Turkish capitals.** `Loc.upper` writes "i" as "İ" (the band banner).
  Godot's `to_upper` does not.
- **What stays English on purpose.** The game's name and version. Each
  language's own name. The device self test (`diagnostics.gd`,
  `selftest.gd`): it is a technical report, and it reads the same from
  every phone. Number suffixes (K, M) are kept too.
- **Checks.**
  - `tests/test_localization.gd` (6 tests) checks that every message has
    Turkish, with the same format signs in the same order. It checks
    plural forms, the English fallback, the dotted capital, the language
    choice rule, and that the font draws every letter (ç ğ ı İ ö ş ü).
    It also lints the interface scripts for text handed to a label, key,
    toast, the Foreman or a panel without going through Loc.
  - `tools/loc_check.tscn` opens 31 screens: the board, every Settings
    tab, the language list, Research, Collapse locked and ready, the Core,
    what lies below, the stratum, new machines, welcome back, the machine
    sheet and its words, removing, a resource node, every Codex tab, the
    shop. It runs in two languages:
    - in Turkish it fails on any English word Turkish translates;
    - in a pseudo-language it fails on any word without the bracket every
      translated word gets. That pseudo-language is a third longer and
      accented, which catches a word written past Loc and a word too wide
      for its key.
    In both it fails on any word off the screen or wider than its key.
    It passed in both languages, with and without Larger text, at
    1440x720, 1280x720, 2400x1080 and 720x1440. CI runs it in the smoke
    job on all six shapes.
  - The layout check runs a second time in Turkish (11 shapes x 3 safe
    areas, passed).
- **Found and fixed by the checks.** "DERİNE İN" ran off the Descend key.
  Turkish now says "İNİŞ", and the key reads "kota %67". At a third longer
  with Larger text, "Research" and "Collapse" were wider than their
  96-unit keys and "DESCEND" ran off its key. Words on a fixed-size key
  now shrink a step at a time to fit (`main._fit`, never under 11). Keys'
  words (`_button`, the actions under a panel, the shop's Buy and
  Restore), the board's numbers and the shop's drawn words now follow
  Larger text as well. The panel words that were 14-15 units are now
  16.
- **Not done.**
  - Right-to-left: `Loc.is_rtl` knows Arabic, but nothing mirrors the
    layout yet.
  - CJK and Arabic need a fallback font. Open Sans draws Latin, Greek and
    Cyrillic only.
  - The store listing and the data-safety text are English only.
  - A `language_change` event waits for the analytics sink decision (no
    event leaves the device today).
  - German, French, Spanish, Brazilian Portuguese, Russian, Japanese,
    Korean, Simplified Chinese and Arabic are on the list, not ready. A
    new language is a `locale/<code>.po` file, its code in
    `loc_extract.gd` `LANGS`, and `ready: true` in `Loc.LANGUAGES`.

### What now? (the Worklist)

After the Foreman's first chapter nothing said what to do next; each
answer lived on its own key (the warning count, Descend's glow, the
Research number, the tray, the green tiles). `Worklist.of` puts them in
one fixed order, at most five lines:

1. machines in trouble, with the warning key's own count;
2. the way down, when the quota is met;
3. research that can be bought, with the Research key's own count;
4. a collapse, only when its Cores open a research line;
5. a machine unlocked and never built, first in the tray's order;
6. a step further along the chain that works nowhere yet but would be fed
   on a tile with an open tile beside it: that step there, and a Vault
   beside it (a tap outlines both);
7. the machine furthest along the chain that would work (fed, and
   handing its work on) on some empty tile right now, and on how many
   (a Vault only when nothing else would);
8. otherwise, how many credits are left to the quota.

A key at the top of the right-hand column (a clipboard with ticks)
opens them as rows; a tap on a row does what it says: goes to the first
machine in trouble, opens what is below, opens Research or the Collapse
card, or arms the machine so the green tiles show where it works. The
first line also sits in Welcome back, under what was banked. Nothing in
it changes a number of the economy; it only points at what the
interface already offers.

- Tests: `tests/test_worklist.gd` (the order, each line against the
  rule it quotes, never more than five); the smoke test opens the card
  and taps its first row; `loc_check` has a "What now?" screen in
  Turkish and in the pseudo-language with Larger text.
- The tools that run the game (`smoke`, `layout_check`, `screenshot`,
  `perf_probe`) now read English unless `LODEWORKS_LOCALE` names a
  language: on a Turkish computer they had started the game in Turkish
  and failed their English checks.

### Collapse after collapse, played (25 September 2026)

The long-game numbers above were one run and a projection. The collapse
lab plays them (`LODEWORKS_JOURNEY=collapses godot --headless --path .
--script res://tools/journey_lab.gd`, about 25 minutes of one core for
four runs): every run from a dark Core and its reserve, a player who
builds what "What now?" names where it says it works (and, when a step
further along is unlocked but works nowhere, that step where it is fed
with a Vault beside it), Research spent as it arrives, Cores spent the
moment they buy a level, and a collapse after a 15-minute stall. Lines
the game does not offer (Drafting Table) are neither bought nor counted:
the tree on offer is 8 lines, 351 Cores.

| run | length | deepest | lifetime credits | Cores | Cores/hour | tree levels (lines maxed) | played |
|---|---|---|---|---|---|---|---|
| 1 | 1h 18m | 15 | 5.96M | 76 | 58 | 20 (0/8) | 1h 18m |
| 2 | 54m | 19 | 69.2M | 167 | 184 | 34 (4/8) | 2h 12m |
| 3 | 53m | 19 | 76.6M | 236 | 265 | 42 (6/8) | 3h 06m |
| 4 | 51m | 19 | 69.4M | 301 | 354 | 45 (8/8) | 3h 57m |

**The permanent tree is finished after 4 collapses and 3h 57m of active
play**, not after about 6 collapses and 9 hours as projected. Each run
after the first is shorter and pays more (x2.2, then x1.4, then x1.3),
because the tree it bought compounds, and Seismic Survey makes the Cores
themselves compound. The depth plateaus at stratum 19: past it the quota
outruns a board the yard can hold. The boards held 257 to 372 machines,
every one of them placed again by hand after each collapse.

Against the reference games (docs/research/prestige-pacing.md): the
first collapse at 78 active minutes and the growth per run sit inside
genre norms, and the second collapse's +220% is just above the one
primary-source reset rule (+50-200%). The outlier is the tree's size:
351 Cores is 4.6 first payouts, where the reference trees are priced
across many orders of magnitude or open a next layer. **PROPOSED, the
owner's decision** (an economy change): (1) repeatable or geometric top
nodes so the tree outlasts the payout; (2) a root on the Cores formula,
which slows the growth without changing the first run; (3) a second
layer that opens near the tree's end. The lab is the check for any of
them. Blueprints (GAP-AUDIT B-5) would shorten every rebuild and so
finish the tree sooner still.

What the model is not: it is active play without offline earnings, one
seed, one fixed collapse rule, and a builder no smarter than the list it
follows. A player who collapses earlier, or builds better, finishes
sooner; one who plays in short sessions takes more calendar days.

### What the gap-audit round cost the frame

The perf probe (`LODEWORKS_SOAK=10`, hero board, the same desktop, Intel
UHD), each commit in a worktree of its own:

| | 9f51cf0 (end of the night) | 2d40375 (languages) | 7464359 ("What now?") | f15c9d9 (now) |
|---|---|---|---|---|
| idle frame p50 / p95 | 10.82 / 14.77 ms | 10.82 / 14.66 ms | 12.96 / 18.32 ms* | 10.91 / 14.94 ms |
| draw calls, idle | 177 | 177 | 189 | 189 |
| draw calls, soak | 193 | -- | -- | 205 |
| static memory | 48.0 MB | -- | -- | 49.1 MB |

*One run; the next commit measured 10.93 ms with the same draw calls, so
it was the machine, not the code. The languages cost nothing. The twelve
draw calls are the "What now?" key's drawn clipboard, and the frame did
not move. One run on the working copy measured 280 draw calls and
15.3 ms; it could not be reproduced (189 three times since), so the probe
now writes "NOT the bare screen" on a row measured with a card open or
the Foreman talking. The chain lines, the per-band dust and the rest of
the round draw nothing on the idle screen. A phone is still UNKNOWN.

### Toward more than one factory (not built)

Nothing tonight builds a second factory or talks to a network (D3 still
stands). The pieces added were written so they would not need rewriting
if one comes:
- `ResourceNodes` knows kinds and words, and nothing of any Core.
- `FactoryReport.of(grid, sim, max_depth, blocked)` sums up whichever
  board it is handed.
- `Strata.effect_on` and `Simulation.links_if_placed` are pure: a
  stratum and a board in, an answer out. Strata were already the same
  for every player at a given depth, so two players' stratum 14 and its
  arrows are the same and can be compared.
- `Grid` and `Simulation` were already per instance: the Codex runs a
  dozen at once.

What ties the game to one factory is `Sim`. It holds one board, its
depth, its Core and tutorial state, and also the player's credits,
research, Cores, upgrades and settings, all in one save (`"v": 1`).
Beside it, `BuildArea.CORE` is a constant, and `IsoView` reads `Sim`
directly. If the owner wants more than one factory, the order that keeps
every step testable and reversible is:
1. Split the save into the player and `factories[0]`, with a v1 to v2
   migration and a round-trip test. Whether credits belong to the player
   or to each factory is an economy decision, and it comes first.
2. `Sim` exposes the active factory, and the interface reads through it.
3. `IsoView` draws a factory it is given, and `BuildArea` takes the
   Core's block from that factory.
4. Only then a second factory. Visiting another player's factory, read
   only, would be a `FactoryReport` plus a board snapshot, and it needs a
   server.

### Follow-ups from the audits

- **Resource nodes with a use**: needs the owner's decision (above).
- **The collapse payout** and **blueprints**: the owner's decisions, noted
  in the master audit.
- **Portrait store screenshots**: the game is landscape-only; the store
  listing needs landscape shots or a decision.

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
- The descent pace (above) makes a run about 1.8 times as long for the
  same Cores. Whether the collapse payout should rise to match is the
  owner's decision.
- Blueprints: the simulation, a research line and the Licence all carry
  blueprint slots, and there is no screen to save or load one. The
  research card and the shop bullet are hidden until there is. Whether to
  build the screen or drop the slots is the owner's decision.

Everything in this document was measured in the headless simulation, which is
the same code the game runs, on hardware that is not a phone.
