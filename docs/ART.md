# The Lodeworks visual system

Written before the assets, because the thing that makes twelve machines look
like one factory is not the quality of any one of them.

The whole game is still drawn by `_draw()`. There is not one bitmap in the
project outside the store folder. What changed is that a rectangle is no
longer a flat colour — it is one face of a solid, lit by one light, and the
game builds everything out of faces.

---

## 1. Master art direction

**Warm machines in cold rock.**

Everything the player built is metal, lit from inside, and warm. Everything
they have not built yet is stone, unlit, and cold. Production is literally
light: a working factory glows and a stalled one goes dark, so "is this
working" is answered by brightness before it is answered by any number.

The register is toy-like industrial — chunky proportions, heavy bases, visible
mechanisms — rather than either technical-diagram or cute. A machine should
look like something you could pick up.

## 2. Colour system

| role | colour | used for |
|---|---|---|
| shaft | `#0d1219` → `#1a2331` | background and empty rock |
| panel | `#161d29` / `#222c3b` | UI surfaces |
| credits | `#4fc3f7` | the primary number and primary action |
| research | `#a780ff` | the second currency |
| cores | `#ffd479` | the permanent currency, and every premium surface |
| working | `#5ddba0` | green, and only ever "this is fine" |
| blocked | `#ffb454` | amber — look **downstream** |
| starved | `#ff6b6b` | red — look **upstream** |
| too hot | `#ff8a3d` | thermal, above optimum |
| too cold | `#5aa9e6` | thermal, below optimum |

Status colours are **not themeable and not reusable**. Amber on this board
means one thing. A purchased palette repaints the machines, the ore and the
rock, and leaves the four status colours exactly where they are.

Each machine also owns a **light signature** — the hue of its emissive core —
and the twelve are held apart by `test_machine_light_colours_are_distinct`.
That test found three yellows on top of each other the first time it ran.

## 3. Material system

Every solid is drawn as three faces plus two thin extras:

- **top** — the face pointing at the light, lifted and inset, tinted towards
  the key light rather than towards white
- **front** — the machine's actual colour
- **side** — turned away, pushed towards the shaft's ambient blue rather than
  towards black, because nothing in a lit room is truly black
- **rim** — a one-pixel line along the top-left corner. The single cheapest
  thing that makes a flat shape look machined.
- **contact** — a dark pad under the body. A block with no shadow floats.

Six rectangles, in `Palette.block()`. A machine is three or four stacked.

## 4. Lighting system

One key light, warm (`#ffe9c4`), fixed at upper-left. One cool ambient fill
(`#2b3a52`) from the shaft. Neither ever moves, which is what makes seventy
separate drawings look like one scene.

Emissive elements ignore all of it: `Palette.emissive()` draws four falling
haloes sized off the element's short edge, then a core that goes white-hot in
the middle. That is the only thing on the board that is brighter than the key
light, so it is where the eye goes.

## 5. Camera system

The grid stays square and axis-aligned. A true isometric projection would cost
the thing the whole design is built on — knowing instantly which cell is which
— and would break hit-testing, layout and the 7×10 readability.

Depth comes from the **objects**, not the projection: each machine is drawn as
a block with a visible top face, standing on a bevelled platform, with a
contact shadow. The read is "a steep camera over a diorama", which is what the
brief asked for, without a single change to how a tap maps to a cell.

## 6. Machine design language

Four parts, the same four for every machine:

- **PLINTH** a dark foot, so nothing floats
- **MASS** one or two body blocks in the machine's metal colour
- **MARK** the part that says what it *does* — a bit, a ram, a chimney, a fin,
  a tube. This is the silhouette, and it is what has to survive greyscale at
  44 pixels.
- **LIGHT** the emissive core, in the machine's own signature hue

| machine | mark | light |
|---|---|---|
| Drill | tapered bit that strokes downward | warm lamp |
| Crusher | toothed rollers biting across the top | friction orange |
| Vault | double-walled box with a lock disc | money green |
| Smelter | wide arched mouth, chimney offset | molten orange |
| Boiler | banded pressure tank, tall stack, valve | furnace red |
| Coolant Cell | finned column under a frost cap | ice blue |
| Press | frame with a ram that visibly comes down | cold steel |
| Assembler | stepped tiers with a moving arm | assembly blue |
| Amplifier | pylon between two reaching dishes | power yellow |
| Lab | narrow tower with a crystal in glass | violet |
| Duplicator | two mirrored halves, the copy between them | pink |
| Condenser | wide drum under a dome, radiating fins | teal |

**Upgrades add parts, never brightness.** A levelled machine grows a side
motor, another tooth, a second stack, an extra fin. **Heat changes the light,
never the body**, so a hot Smelter still looks like a Smelter.

## 7. Environment language

Four bands, blended continuously, from `Palette.shaft(depth)`:

| band | strata | rock | mineral | light |
|---|---|---|---|---|
| Surface | 0–3 | cool blue-grey stone | pale quartz | daylight leaking in |
| Workings | 4–9 | warmer worked rock | copper | lamp light |
| Deep | 10–16 | iron-red | violet crystal | heat in the cracks |
| Abyssal | 17+ | near-black basalt | bright veins | lit from below |

Empty rock is a shallow pit — dark seam, floor, lit lip — with per-tile tonal
variation and a scattering of minerals. Past the Deep band the ground itself
starts glowing through hairline cracks, so by stratum 22 the board is lit from
underneath. None of it is allowed in front of a machine.

## 8. Character language

**The Foreman** — a small robot, built from the same `Palette.block()` calls
as the machines and lit by the same key light, so he belongs to the factory
rather than visiting it. Hard hat with a dome and a brim, wide cyan visor, a
warm core in his chest, green antenna light that blinks on its own clock.
Three poses: idle, pointing, cheering.

The earlier direction argued there should be no mascot on the grounds that
"the factory is the character". Both things are true at once, and this is the
resolution: **the mascot is a machine**. It costs no texture, no import, no
atlas, and it cannot drift between the version in the tutorial and the version
in the shop, because there is only one of him and he is a function.

He is deliberately **not on the gameplay screen** — a mascot standing next to
a board somebody is trying to read is a mascot in the way. He appears at the
four moments where the game is talking rather than being played: coming back
from being away, unlocking a machine, the Codex, and the shop.

## 9. UI language

Dark translucent panels with a lit top edge, a soft drop shadow and rounded
corners — the same key light as the board, so the interface and the factory
look like they are in the same room. Big touch targets: 64px primary buttons,
104×112 palette chips. Colour-coded state, minimal text.

The palette chips draw the **real machine** through `MachineArt`, so what you
tap looks like what appears. A chip you cannot afford dims as a whole rather
than turning its price red.

## 10. Icon language

Every machine icon *is* the machine, rendered by the same code at a different
size. That is the entire icon pipeline, and it is why an icon cannot drift
from the thing it stands for. The app icon and the feature graphic are drawn
by `tools/brand_painter.gd` from `MachineArt` and `Palette.shaft()`, so the
store page shows the place the game is actually set.

## 11. VFX language

- **light pools** — every working machine paints a soft falloff of its own
  light colour onto the floor around it, and a stalled one paints none. The
  brightness of the *ground* is a second, peripheral channel for the same fact
  the status pip carries. Drawn as four nested rects of falling alpha; the
  first version used two slabs of flat alpha and produced coloured rectangles
  bleeding across the board, which read as tinted tiles rather than as light.
- **conduits** — a short run of pipe across every seam where one machine can
  actually hand something to the one beside it, coloured by the resource,
  barely there at rest and lit when something is flowing. This game has no
  belts on purpose, which made adjacency legible only in the instant a mote
  crossed a gap — exactly not the moment somebody is standing still trying to
  work out why a tile is starved. `test_a_conduit_is_drawn_exactly_where_material_can_move`
  checks the picture and the simulation agree, because a pipe drawn where
  nothing can flow is the board lying.
- **ambient dust** — sixteen particles drifting upward, pale quartz at the
  surface and embers in the deep. The cheapest thing on the board and the
  difference between air and vacuum.
- **vignette** — four gradient bands pushing the corners back, so the factory
  sits in a hole in the ground rather than on a sheet of paper.
- **material in transit** — a lit packet crossing the gap between two
  machines, eased so it leaves fast and arrives soft. On a busy board dozens
  are in flight, and that is the clearest signal the factory is working.
- **venting** — an overheating machine pushes pale puffs off its top edge
- **cycle sweep** — a bar along the bottom of every machine in its own light
  colour. A bar that has stopped sweeping is a machine that has stopped.
- **working beat** — the moving part moves: the drill bit strokes, the ram
  falls, the teeth bob, the dishes reach. Amplitude is deliberately tiny;
  seventy tiles bouncing is a screensaver.
- **minerals** — veins in the rock glow harder with depth

Nothing here is a particle system, a shader or a texture. Rare things stay
rare: the crystal is on about one tile in ten and the vent only fires on a
machine that is genuinely too hot.

## 12. Animation language

Everything is driven by state the simulation already has, so nothing can
animate a lie:

| motion | driven by |
|---|---|
| moving parts | `Simulation.progress_of(cell)` — the real cycle phase |
| core brightness | status and heat efficiency |
| cycle sweep | the same progress value |
| motes | `Simulation.last_transfers` — transfers that actually happened |
| vent | heat efficiency below the thermal warning |

---

## What this cost

| | before | after |
|---|---|---|
| canvas draw calls | 183 | **44** |
| total renderer draw calls | 247 | **108** |
| simulation cost | 1.341 ms/tick | 1.341 ms/tick |
| texture memory | 11.5 MB | 11.5 MB |
| bitmap assets in the game | 0 | 0 |

The draw calls went **down** while the machines got four times more detailed
and gained light pools, conduits, drifting dust and a vignette,
because the board is now drawn in passes — every platform, then every body,
then every readout, then every glyph — instead of interleaving rectangles and
text seventy times. A glyph is a texture and a texture switch breaks the
batch.

## What this is checked by

`tools/readability.gd` renders all twelve machines at 44, 64 and 96 pixels —
the cell sizes a 7-wide board actually produces on a phone —
and `tools/check-readability.py` compares every pair, in colour and again
desaturated. CI fails if any two machines have become the same picture.
Current worst pair: Smelter and Boiler at 20.8 against a floor of 9.0 in
colour; Crusher and Smelter at 16.0 against a floor of 6.0 in greyscale.

**"Prettier and now I cannot tell the machines apart" is a build failure, not
a matter of opinion.**
