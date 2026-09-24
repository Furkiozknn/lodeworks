# The Lodeworks visual system

The main screen is a landscape, three-quarter isometric world: a painted
canyon, a rock island floating in it, a stone slab on the island, and on
the slab the 7x10 board the simulation plays on, with the Factory Core
standing behind it. Every picture in it is generated art, built into the
game by `tools/art_build.py`; every number that places a picture is in
`assets/art/layout.json`; everything that moves is driven by the
simulation.

The procedural renderer this replaced (`GridView` + `MachineArt`, every
machine drawn from lit rectangles) is described in the git history
(`docs/ART.md` before `c10ae71`). `MachineArt` survives only in
`tools/brand_painter.gd`, which draws the store icon; see section 12.

---

## 1. Master style

Every asset is generated against the same rules, and a new one is not used
until it matches them. These are the words that go into every prompt:

| rule | value |
|---|---|
| camera | **true isometric**: rotated 45 degrees, about 35 degrees above the ground, one corner pointing at the viewer, left and right faces equally visible |
| ground plane | a square seen as a **diamond twice as wide as it is deep** (2:1) |
| light | one warm key light from the **upper left**, cool fill; glowing cores are the only things brighter than the key |
| materials | polished brass, dark riveted iron, copper, grey-brown stone, jade and marble (Verdant), ice (Frost), basalt and magma (Ember); crystals in purple and cyan |
| register | stylized 3D, chunky, toy-like, glossy, soft bevels -- premium mobile, never childish |
| machines | one main colour each, **one glowing core in its own light colour**, a readable moving part, all on the same riveted base plate with brass corner caps |
| scale | a machine's plate is one cell; the Core's plate is three |
| background | sprites on a fully transparent background, no floor, no ground shadow (the game draws its own) |
| consistency | a new sheet is generated **from** an existing sheet as its first reference ("keep EXACTLY the FIRST sheet's machines, positions, camera...") and changes only what it was asked to |

The references, in priority order: the user's concept images
(`lodeworks_art/concept_ref.png`, `ref2.png`), the isometric machine sheet
`r2_machines`, the island `r2_island`, and the world painting `r3_world`.
The older front-view sheets (`machines_v1` and its palettes) are **not**
used: they are a different camera, and mixing cameras is the one
inconsistency the eye catches first.

## 2. Camera and projection

- **2:1 isometric**, cell 128 x 64 world units (`Iso.TW`, `Iso.TH`). Board x
  runs down-right, board y down-left, depth is x + y.
- **Pan** 1:1 with the finger (no easing while it is down), a **fling** that
  coasts after release, **pinch** and **wheel** zoom about the point under
  them, the zoom key gliding between the whole factory and a close view.
- **Zoom** 0.42 to 1.6. The default frames the board and the Core in the
  space the HUD leaves free.
- **Bounds**: the camera never shows anything outside the painting, at any
  zoom, aspect ratio or fling (`test_the_camera_never_shows_the_void` checks
  seven aspect ratios, every edge, every zoom).
- **Parallax**: the painting is the far layer. It slides at 0.82 of the
  camera's speed and scales by zoom^0.82, never below what covers the
  screen, so the island reads as floating over the canyon.

Readability before show: a cell at the default zoom is 32-34 dp tall on a
1080p phone (measured by `tools/layout_check.tscn`), which is enough to see
the factory and too small to aim at precisely; at the closest zoom it is
52-61 dp, above Android's 48 dp floor. A machine must be picked (tapped)
before it can be dragged, so a pan never moves a machine by accident.

## 3. The world

Back to front, each a layer of `IsoView`:

| layer | what | notes |
|---|---|---|
| painting | `world/workings.jpg`, 3840x2160 | tinted per depth band; a light haze over it separates it from the island |
| island | `world/island.webp` | its flat top stretched to the board's 2:1 so the stone around the board is in the same plane |
| floor | the slab's two front faces, 70 floor slabs, the iron rim with brass rivets, the expansion plot, marks, contact shadows, pipes | one textured and two untextured batches |
| floor light | each working machine's light pool, hot machines' orange pool, the rim lamps | additive |
| things | machines, props and the Core, sorted by slab depth | one atlas: the machines batch |
| light | machine cores, flow along seams, steam, embers, crystals, the Core's crystal, dust | additive |
| overlay | badges, flow beads, notches, previews, numbers, the selected machine's links | screen space, fixed size |

**The slab** is 12 x 12 cells. The board sits at slab (4, 1); the Factory
Core stands on slab (1..3, 8..10), beside the board's left corner, and takes
no board cell (`test_the_board_sits_on_the_island_and_inside_the_world`).
It stood behind the back corner until the default view was tightened; there
it set the view's height (docs/AUDIT.md, "The default view").
Slab (1..3, 1..7) is **the expansion plot**: dimmed, outlined in dashes,
with a padlocked barrier at each end. It is visual only -- no rule reads
it -- and it is where a future expansion mechanic would open ground.

**Props** (crystals, an ore vein, rubble, lamps, a crate, a steam vent) are
hand-placed in `layout.json` -> `placement.props`.

**Depth bands** (0-3 Surface, 4-9 Workings, 10-16 Deep, 17+ Abyss) tint the
one painting: daylight, lamp light, red, violet. Four paintings would be
better; the tint is the honest interim and is written down as such
(docs/AUDIT.md). A descent drops the canyon away and dips the light for
1.4 s while the new band's colour arrives.

## 4. Machines

- Twelve sprites per sheet, **six palettes x two tiers** = twelve sheets.
  The palette the player bought and the upgrade tier they reached pick the
  sheet (`IsoArt.sheet_name`); a missing sheet falls back to the free one,
  never to a crash.
- **Upgrades**: 1-2 notches of research show as gold notches on every
  plate; at 3 the whole factory switches to the gilded top-tier sheet.
- **State, without words**:

| state | what the machine does |
|---|---|
| working | breathes (1.2% on its cycle), core glows with its cycle, lights the floor, steams if it is a hot machine |
| idle | a little dimmer |
| stalled | dim, no floor light |
| mild heat (< 90%) | a faint warm or cool tint, **no badge** |
| hot/cold (< 70%) | tint, orange floor glow, embers, flame or frost badge |
| critical (< 40%) | pulsing, warning badge, the Foreman says so once per stratum |
| blocked | amber pause badge on the side it hands material out of |
| starved | red empty badge on the side it is fed from |

- **Badges wait**: a state must hold 1.5 s before its badge appears and be
  gone 0.6 s before it goes. **Only the root of a jam is badged**: a blocked
  machine loses its badge if what it feeds is itself jammed, a starved one
  if what feeds it is. On the reference board the badges on screen are one
  blocked drill and the four hot presses of the Dense Seam.

## 5. Connections

A pipe exists **exactly** where the simulation can move material
(`Iso.links`, the same rule as `Simulation._takers`, held to it by
`test_a_pipe_is_drawn_exactly_where_the_simulation_can_move_material`). A
connection through a support machine is drawn through it.

In a 45-degree view every neighbour is in front of or behind another, so a
pipe in the seam between two machines is partly behind the nearer one.
That is physically right and it is why pipes vanished in the earlier
perspective round. What makes connections readable now:

1. the floor pipe in the seam, in the resource's colour, lit while material
   crosses it;
2. a **bead** riding each seam the simulation actually moved material
   across in the last 0.6 s, in screen space, outlined, in the direction it
   went;
3. **selecting a machine** draws every link in and out of it on top of
   everything, with chevrons running the way material runs.

At the default zoom (1) is mostly hidden on a dense board; (2) and (3)
carry it. Recorded as PARTIAL in the audit.

## 6. Heat

Heat is light first and numbers second: the orange floor pool under a hot
machine, embers rising from it, its body flushing, the flame badge. The
**Heat** key turns the floor into a heat map and prints the numbers. The
screen is never washed red: mild heat is a tint, and the badge only appears
at a real loss.

## 7. The HUD

Landscape, in the corners and along the edges, never over the middle:

| where | what |
|---|---|
| top left | stratum card: number, band, quota bar, modifiers |
| top right | credits (+rate), research, cores, settings |
| right edge | heat view, zoom, problems (count on the key; each tap glides to the next problem) |
| bottom left | research, collapse, codex |
| bottom middle | the machine tray -- or the selected machine's panel, in the same place |
| bottom right | DESCEND |
| left edge | the Foreman, only when there is something to say |

Keys are 96 canvas units: 48 dp on a 16:9 1080p phone, where a canvas unit
is smallest (0.51 dp). `tools/layout_check.tscn` checks eleven screen shapes
and three safe areas for overlap, safe-area escape, touch size and a fully
visible board. Icons are the generated sheet `ui/icons.webp`.

## 8. The Foreman

The generated miner (`foreman/poses.webp`): idle, point, cheer, jump,
alert. He stands at the left edge, never over the board, and speaks in one
short line: the first-chapter tutorial, a new stratum, the first critical
machine in a stratum, the research nudge. Tapping him sends him away.

## 9. Asset pipeline

```
Higgsfield (gpt_image_2_5, flare, high, 2k/4k)
   -> raw sheet, downloaded on Windows          lodeworks_art/gen/*.png
   -> tools/art_build.py                        slice, measure, normalise
   -> assets/art/**  +  assets/art/layout.json  what the game loads
   -> art_src/sources.json -> art_src/SOURCES.md  job id, prompt, refs, URL
```

**Generating.** The Higgsfield MCP tools, from this machine's Claude Code
session. References are passed as job ids of earlier generations, which is
how a new sheet keeps the camera and the style: every palette sheet names
`r2_machines` as its first reference, every top-tier sheet its own palette
sheet. Cost at the time of writing: 2.75 credits for a 2k image, 4.25 for 4k.

**Downloading (Windows).** The Cowork sandbox could not fetch the CDN (403),
so downloads run on this machine: a list file of `name url` lines in
`D:\Claude Projeleri\lodeworks_art\` and a loop of
`curl -sS -o gen/<name> <url>` (or `fetch.ps1 -List <file>`). Each batch
gets a new list file (`list8.txt`, `list9.txt`, ...), so nothing is
overwritten. Uploading a local reference is the reverse: Higgsfield's
`media_upload` returns a presigned URL, `put.ps1` PUTs the file to it.

**Building.** `uv run --no-project --with pillow --with numpy --with scipy
python tools/art_build.py`. It finds each machine's plate from the alpha
channel (the body blobs are labelled after cutting the emptiest line near
each row and column boundary, so touching neighbours separate), scales
every machine so its plate is 224 px, and writes one atlas per sheet with
one shared anchor. The island's flat top, the tiles' bounds and the
Foreman's poses are measured the same way. Missing raw files are
downloaded from the URL in `sources.json`.

**Import settings are decisions**, so `assets/art/**/*.import` is tracked:
the world and the island are VRAM-compressed (ETC2/ASTC on phones), sprites
are lossy WebP in the package with mipmaps, uncompressed on the GPU.

## 10. Texture budget

From `tools/asset_budget.py` (repo and package measured; VRAM estimated)
and `tools/perf_probe.tscn` (renderer counters, Windows / Intel UHD):

| | value |
|---|---|
| committed art | **6.76 MB** of the 40 MB budget |
| imported (package) | 15.5 MB |
| VRAM, everything the play screen draws (estimate) | 26.2 MB |
| texture memory, renderer counter, play screen | 33.9 MB |
| on a phone | UNKNOWN |

Only one machine sheet is resident at a time (a palette at a tier).

## 11. layout.json

| key | contents |
|---|---|
| `tile` | the cell in world units |
| `machines.order` | the twelve ids, atlas order |
| `machines.sheets.<palette>[_up]` | file, cell size, cols, anchor (plate centre in the cell), base_px |
| `tiles` | file, tile px, the eight kinds |
| `island` | file, size, top_center, top_half_w, top_half_h |
| `world` | file, size, anchor (the slab's centre in the painting) |
| `foreman` | file, cell, pose names |
| `core`, `props`, `icons` | atlases, same shape as a machine sheet |
| `placement` | hand-set: slab size, board offset, Core cell and size, footprint, parallax, board lift, the expansion plot, the props |

Everything but `placement` is written by `art_build.py`; `placement` is
preserved across rebuilds. `test_layout_json_is_complete_and_every_picture_exists`
checks it.

## 12. What checks it

- `tools/readability.gd` + `tools/check-readability.py`: the board's own
  sprites at 44, 72 and 110 px, free palette and Slate (the grey one), every
  pair compared in colour and greyscale. Closest pair: Drill/Boiler 18.9 in
  colour at 44 px (floor 9.0); Lab/Condenser 11.8 in greyscale, Slate, 44 px
  (floor 6.0).
- `tests/test_iso.gd`, `tools/layout_check.tscn`, the audit screenshots in
  CI (`LODEWORKS_CAPTURE=audit tools/shots.tscn`).

**Not yet on the new art**: the store icon and feature graphic
(`tools/brand_painter.gd` still draws them procedurally with `MachineArt`),
and the store screenshots, which are portrait and must be re-shot in
landscape. The directive puts store work after the main screen.
