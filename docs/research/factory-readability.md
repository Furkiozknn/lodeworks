# Factory / Automation / Grid-Placement Games: Readability & Feedback Research
### Prepared for **Lodeworks** (Godot, Android, 7x10 grid, orthogonal adjacency, heat field, strata, "collapse the shaft" prestige)
Date: 2026-09-23

---

## 0. Method, and what "verified" means here

Everything below is sourced to a dev blog, patch note/wiki, mod page, store page, or a player thread. Where I could not
open or verify a source, the line says **UNKNOWN** rather than guessing. Steam *announcement* pages (several shapez 2
devlogs) would not render text through my tooling and curl to steamcommunity.com was blocked by the egress proxy, so a
few things I know exist are marked UNKNOWN on detail.

Two labels are used throughout:
- **[SOURCE]** — the source says this.
- **[INFERENCE]** — my reasoning about Lodeworks, not a claim any source makes.

A note on what Lodeworks is *not*: it has no belts, so most of the "item flow" literature (belt sprites, splitters,
throughput on a line) is only indirectly applicable. The closest analogues are **Factorio inserters** (a visible
hand-off between two adjacent machines) and **Islanders** (an adjacency effect shown at placement time), not conveyors.

---

## 1. Games examined, and the specific technique each contributes

| Game | Technique it contributes | Verified detail | Source |
|---|---|---|---|
| **Factorio** (vanilla) | **Per-entity status vocabulary.** A single enumerated machine state drives every piece of feedback. | The prototype API defines ~70 `EntityStatus` values including `working`, `no-power`, `low-power`, `no-ingredients`, `item-ingredient-shortage`, `full-output`, `not-enough-space-in-output`, `no-minable-resources`, `low-temperature`, `disabled-by-control-behavior`, `frozen`. | [EntityStatus, Factorio Prototype Docs](https://lua-api.factorio.com/latest/types/EntityStatus.html) |
| **Factorio** (vanilla) | **Two-tier alerting: on-entity warning icon + global alert strip + screen-edge pointers.** | Alerts "display to the right of the quickbar"; "Hovering over an alert enlarges the associated alert icons on the map and shows arrows on the screen edges that point to the positions of the entities that caused the alert." Warning icons are "shown directly on a given entity" and persist "until the object's status changes". Alerts carry explicit durations (5–30s). | [Alerts, Factorio Wiki](https://wiki.factorio.com/Alerts) |
| **Factorio** (vanilla) | **Alt-mode: toggleable recipe icon drawn on every building.** | Described by players as: pressing Alt makes "all buildings display the icon for their recipie, allowing you to see at a glance what's being produced where." | [Captain of Industry idea board](https://ideas.captain-of-industry.com/suggestions/221581/blatantly-steal-altmode-from-factorio) |
| **Factorio** (art direction) | **Readability beats fidelity for small in-factory objects.** | Albert on the pole redesign: "I had to clean up the style a lot in order to make it very visible in any situation." Poles "have to be transparent" yet "visible enough in order to feel comfortable at the time of playing." | [FFF #195](https://factorio.com/blog/post/fff-195) |
| **Factorio** (mod: Bottleneck) | **The three-state traffic light — the de facto standard for surfacing bottlenecks.** | Green = "currently doing stuff"; Yellow = "not currently doing anything, limited by the output"; Red = "not currently doing anything, limited by the input." Colours configurable; hotkey SHIFT+ALT+L; **316,000 downloads**. | [Bottleneck](https://mods.factorio.com/mods/trold/Bottleneck) |
| **Factorio** (mod: Bottleneck Lite) | **Status→colour mapping collapsed to 3 colours, and baked into the sprite (zero runtime cost).** | "Disabled (red), Full output (yellow), Idle (red), Insufficient input (red), Low power (yellow), No minable resources (red), No power (red), Working (green)." "The indicators are added to the actual sprites of each entity, and are tinted based on the working visualisations property." Settings for indicator **size** and **glow in darkness**. **228,000 downloads**. | [Bottleneck Lite](https://mods.factorio.com/mod/BottleneckLite) |
| **Factorio** (mod: Alternative Alt Mode) | **Cursor-local detail overlay — the anti-clutter pattern.** | "This information is shown only for entities around the player cursor, so the graphics of other objects can be enjoyed without always having an information overlay on top of them." Adds fluid temperatures, accumulator charge, pole network usage, heat pipe temperatures. | [Alternative Alt Mode](https://mods.factorio.com/mod/alt-alt-mode) |
| **Satisfactory** | **Four-colour status lamp on the machine body.** | Player-reported convention (not an official doc): green = producing, yellow = idle (waiting to fill / waiting to empty / not needed), red = no power or error, white = running with power shards. Players asked for a **fourth/fifth** colour to separate "manually on standby" from "power failure", arguing "orange would be too close" to existing colours. | [Steam thread: NEW LAMP STATUS (suggestion)](https://steamcommunity.com/app/526870/discussions/0/2577696996229106823/) |
| **Satisfactory** | **Uptime %, not items/sec: the Productivity Display.** | Shows "a value between 0% and 100%, based on how often the building is operating compared to its current maximum production speed", to "measure and improve the productivity of individual buildings to aid with optimization." | [Productivity Display](https://satisfactory.fandom.com/wiki/Productivity_Display) |
| **shapez 2** | **Numbers live on an opt-in in-world instrument, not on every belt.** | The Belt Reader "displays belt throughput over itself." Players complain you can't extract the number as a signal, and that "belt throughput stops updating when items stop going through it." | [Steam discussion: reading belt throughput](https://steamcommunity.com/app/2162800/discussions/0/6929437446239078173/) |
| **shapez 2** | **A dedicated colourblind colour mode.** | Game offers multiple colour modes including "RGB (colorblind)". Players also report palette confusion: "they simply need to make yellow LOOK yellow, not ORANGE." | [Steam discussion: colors](https://steamcommunity.com/app/2162800/discussions/0/565913205989269032/) |
| **shapez 2** | Art direction devlog exists ("Devlog 013 — The visuals of Shapez 2", tagline "What you see is what you get, so what you see should look good") | **UNKNOWN** — body text would not render through my tooling; Steam blocked at the proxy. Do not cite specifics from it. | [Devlog 013](https://steamcommunity.com/games/1318690/announcements/detail/3821928016070944259) |
| **Mindustry** | **What mobile factory UX gets wrong — the single best source of negative evidence.** | App Store reviews: "text is too small to read and making it bigger means zooming and scrolling back and forth"; placement "clunky" for users with larger fingers who "can't see beneath their hands" while queueing; "buttons don't work on initial clicks"; orientation friction — players ask the game to "either let me place it anyways or auto correct the direction." | [Mindustry App Store reviews](https://apps.apple.com/us/app/mindustry/id1385258906?see-all=reviews&platform=ipad) |
| **Mindustry** | **Drag-routing is the minute-to-minute action and it has no good touch equivalent.** | Routing conveyors is "the most frustrating part of playing on mobile, and also like 80% of what you do minute to minute"; desktop's CTRL+drag conveyor pathfinding has no mobile implementation. | [Mindustry-Suggestions #1763](https://github.com/Anuken/Mindustry-Suggestions/issues/1763) |
| **Dyson Sphere Program** | **What 3D costs you: occlusion and pick ambiguity.** | Player complaints: "3D building heights hide elements behind structures, making selection difficult in dense factories"; grid distortion on the spherical terrain "makes placement unpredictable"; the item bar "doesn't show unavailable items, forcing menu navigation"; no quick hotbar. | [Steam: "The UI of DSP holds this game back"](https://steamcommunity.com/app/1366540/discussions/0/4845401032850996413/?ctp=3) |
| **Techtonica** | **Animation *rate* as the state channel; animation *stopping* as the alarm.** | "The Accumulators spin when charging up. Once they reach capacity (or power stops coming in), they'll stop spinning and the lights will indicate how full they are." | [Techtonica: power obstacles and tools](https://techtonicagame.com/the-power-obstacles-and-tools-at-your-disposal-in-techtonica/) |
| **Techtonica** | **Design the UI system so a new number can be added later.** | "While squeezing in another line of info can work from time to time, it's much easier to design a robust UI system that supports these types of changes." Planned machine stats: "throughput, fuel consumption, and more." | [Techtonica's refreshed UI](https://techtonicagame.com/take-a-look-at-techtonicas-refreshed-ui/) |
| **Rise of Industry** | **Product bubble + progress, praised explicitly for diagnosability.** | PC Gamer: "I was particularly a fan of the little bubbles that pop up to show what product a building is producing and how far along it is" and these plus other icons make it "easy to diagnose problems like disconnected roads or too many products in storage." | [Rise of Industry review, PC Gamer](https://www.pcgamer.com/rise-of-industry-review/) |
| **Little Big Workshop** | **Negative case: a factory game that never surfaces its bottleneck.** | "doesn't make it easy to find any stumbling points in your setup"; it "stumbles when it comes to having to make small adjustments or fix issues." | [Game Wisdom analysis](https://game-wisdom.com/analysis/little-big-workshop-review) |
| **Opus Magnum** | **The running machine *is* the feedback; and a small fixed metric set replaces live numbers.** | Zach Barth: "It's satisfying to watch factories work, and especially so when it's one of your own design"; players optimise for "cost, area, or cycles"; the design has "a lot of circular motion that results in designs reminiscent of clockwork." | [Road to the IGF, Game Developer](https://www.gamedeveloper.com/business/road-to-the-igf-zachtronics-i-opus-magnum-i-) |
| **ISLANDERS** | **Adjacency preview as a radius ring drawn at placement time.** | "A blue circle surrounds the building you're actively pacing. Anything within the circle will be affected by the current placement." Buildings gain or lose points depending on what is nearby. | [Pocket Gamer, Islanders mobile review](https://www.pocketgamer.com/islanders-mobile/review/) |
| **Oxygen Not Included** | **Toggleable field overlay, read as *gradients* not cells.** | Guide advice: "Use the temperature overlay before rearranging machinery. Look for gradients rather than isolated hot cells" and "Chase heat flow, not the single hottest tile." Warm zones read yellow/lime, cool zones blue/green. | [ONI heat management guide](https://gamefoundry.games/blog/oxygen-not-included-heat-management-cooling-guide) · [Temperature Overlay wiki (stub)](https://oxygennotincluded.wiki.gg/wiki/Temperature_Overlay) |
| **RimWorld** (vanilla) | **Negative case: colour-only field overlays fail at thresholds.** | Players: "Temperature overlay is only showing colors of warmth not the actual temperatures"; "you can't tell the difference from the color map but those few degrees determine whether a pawn slept in the cold or not." Colourblind players raise it as an accessibility problem. Precise values require hovering with ALT, room by room. | [Steam: "Current temperature overlay is pretty much useless"](https://steamcommunity.com/app/294100/discussions/0/3495383439611738427/) |
| **RimWorld** (mod: Heat Map) | **The exact colour ramp that works for a target-temperature field.** | "Adds a toggle button to show a live temperature based colour gradient over indoor areas." Green = human comfort (22°C), deeper blue colder, deeper red hotter; **range clamped to -12°C…56°C**; toggled by a button bottom-right or the backslash key. | [Ludeon forum: Heat Map](https://ludeon.com/forums/index.php?topic=33647.0) · [GitHub](https://github.com/Falconne/HeatMap) |
| **Assembly Line 2** (mobile) | **Negative case: an invisible simulation tick destroys trust.** | Store reviews: the game "is vague in descriptions and information"; "the game seems to have internal 'tick' that aren't visible to us", causing synchronisation problems players can't reason about. | [Google Play listing + reviews](https://play.google.com/store/apps/details?id=com.Olympus.AssemblyLine2&hl=en_GB) |
| **Captain of Industry** (player demand) | **Evidence that "which machine makes what" is the #1 at-a-glance need.** | "I spend an inordinate amount of time trying to figure out which building is making which item"; alt-mode "would make learning the game, and being able to manage much much easier." | [CoI idea board](https://ideas.captain-of-industry.com/suggestions/221581/blatantly-steal-altmode-from-factorio) |
| **Android platform guidance** | **The hard number that constrains a 7x10 phone board.** | "Consider making sure these elements have a width and height of at least 48dp"; "A touch target of 48x48dp results in a physical size of about 9mm"; targets should be "separated by 8dp of space or more". | [Android Accessibility Help: Touch target size](https://support.google.com/accessibility/android/answer/7101858?hl=en) |
| **Mindustry heat (Erekir)** | Heat transfer between adjacent blocks | **UNKNOWN** — wiki returned HTTP 402 to my fetcher. Not cited. | [Mindustry heat wiki](https://mindustry-unofficial.fandom.com/wiki/Heat) |
| **Reactor Incremental** | Grid heat spreading to adjacent cells | **UNKNOWN** — wiki returned HTTP 402. Mechanically the closest analogue to Lodeworks' heat rule, but I could not verify its *visualisation*. | [Heat mechanics wiki](https://reactor-incremental.fandom.com/wiki/Heat_mechanics) |
| **Desynced** | UI/UX case study exists | The studio states the challenge was "organizing large amounts of information without overwhelming the player" and that they built "a visual system for displaying units and their activities, allowing players to quickly understand what is happening on the map" — but the case study **does not say how**. No transferable technique verified. | [N-iX case study](https://gamestudio.n-ix.com/case-study/desynced/) |
| **Autonauts, Big Pharma, Infinifactory, Tiny Glade, Dorfromantik, Idle Factory Tycoon** | — | **UNKNOWN / not verified.** I found no source in this pass that documents a specific readability or state-feedback convention in these titles at the level of detail this document requires. Listed here so the gap is explicit rather than papered over. | — |

---

## 2. Answers to the specific questions

### 2.1 How is a machine made readable at a glance?
- **Identity comes from an icon of its *output*, not its own name or shape.** Factorio's alt-mode puts the recipe icon on
  the building; the most-upvoted readability request in Captain of Industry is literally to copy that, because otherwise
  "buildings look identical" [SOURCE: CoI idea board].
- **Small in-factory objects are simplified deliberately.** Factorio's art lead cleaned up the pole style "in order to
  make it very visible in any situation", trading detail for legibility [SOURCE: FFF #195].
- **Colour carries state, not identity, in the successful cases.** Bottleneck/Bottleneck Lite/Satisfactory all reserve
  green/amber/red for *state* [SOURCE: mod pages, Steam thread].
- **3D silhouettes cost you.** DSP players cite building heights hiding things behind them as a concrete readability and
  selection failure [SOURCE: DSP Steam thread]. [INFERENCE] For a 7x10 phone board this is a strong argument to stay
  flat top-down and spend the budget on state, not depth.

### 2.2 How is material flow made visible without clutter?
Verified patterns, in descending order of how well they transfer to a belt-less game:
1. **Numbers only on an opt-in instrument.** shapez 2's Belt Reader "displays belt throughput over itself" — one device,
   one number, placed by the player where they care [SOURCE].
2. **Cursor-local detail only.** Alternative Alt Mode shows dense info "only for entities around the player cursor"
   [SOURCE]. This exists because always-on overlays were cluttering Factorio.
3. **Toggle the whole overlay.** Factorio alt-mode, ONI overlays and the RimWorld Heat Map mod are all a keypress/button
   [SOURCE].
4. **Animation as the flow signal.** Techtonica's accumulators spin while charging and stop when full/unpowered
   [SOURCE]; Opus Magnum's entire feedback model is watching the machine run [SOURCE].
5. [INFERENCE] For Lodeworks the transferable form of "item on belt" is a **hand-off tick on the shared edge** between
   donor and receiver — a short dash or dot that travels the 1-cell gap on each transfer. This is the Factorio inserter
   role, compressed to an edge.

### 2.3 How is machine state shown?
The shipped conventions, verbatim:
- **Three-state traffic light.** Green = working; **yellow = blocked by output**; **red = starved by input**
  [SOURCE: Bottleneck]. Bottleneck Lite folds ~8 statuses into the same 3 colours, notably putting *low power* with
  *full output* in yellow and *disabled/idle/no power/no resources* in red [SOURCE].
- **Four-colour lamp with a "running hot/boosted" state.** Satisfactory adds white for overclocked-with-shards
  [SOURCE: player thread]. Players asked for more states and the counter-argument was that extra hues get confusable —
  "orange would be too close" [SOURCE].
- **Status icon on the entity + a global alert strip.** Factorio draws a warning icon directly on the entity, persisting
  "until the object's status changes", and also lists it in an alert strip beside the quickbar [SOURCE: Alerts wiki].
- **Progress bubble.** Rise of Industry's "little bubbles… to show what product a building is producing and how far
  along it is" were singled out by PC Gamer as what makes problems diagnosable [SOURCE].
- **Uptime percentage.** Satisfactory's Productivity Display: 0–100% of maximum production speed [SOURCE].
- **Temperature is a first-class status in Factorio**, not a separate system: `low-temperature` is one of the
  `EntityStatus` values [SOURCE]. [INFERENCE] This is the strongest single precedent for Lodeworks folding
  over/under-temperature into the *same* status pip as starved/blocked rather than a parallel channel.

### 2.4 How is a bottleneck surfaced?
- **The shipped answer in the most-played factory game is a community mod, installed ~544,000 times across two variants,
  that puts a coloured light on every machine** [SOURCE: 316K + 228K downloads]. That is the strongest empirical signal
  in this entire document: players will install a third-party mod to get per-machine red/amber/green.
- **Factorio vanilla adds direction**: hovering an alert "shows arrows on the screen edges that point to the positions
  of the entities that caused the alert" [SOURCE].
- **Uptime % converts "is it a bottleneck" into a sortable number** [SOURCE: Satisfactory Productivity Display].
- **Counter-example:** Little Big Workshop "doesn't make it easy to find any stumbling points in your setup" and the
  reviewer treats that as the game's core failure [SOURCE].
- [INFERENCE] Note the semantics that matter: red (starved) and yellow (blocked) point in *opposite directions* along
  the chain. Red says "the problem is upstream of me"; yellow says "the problem is downstream of me". A player can
  follow the colour to the culprit without any graph analysis. That is why 3 colours beat 8.

### 2.5 How is placement validity and adjacency shown while dragging?
- **ISLANDERS:** "A blue circle surrounds the building you're actively pacing. Anything within the circle will be
  affected by the current placement" [SOURCE]. Score delta is shown live.
- **Mindustry (negative):** rotation-dependent placement is rejected rather than corrected; players ask the game to
  "either let me place it anyways or auto correct the direction" [SOURCE]. Finger occlusion — "can't see beneath their
  hands" — is a named problem [SOURCE].
- **Factorio:** unbuilt placements are a real entity state (`ghost`) [SOURCE: EntityStatus], i.e. "pending/invalid" is
  modelled, not just drawn.

### 2.6 Throughput numbers without overwhelming
Three shipped strategies, all of which *remove* numbers from the default view:
1. Opt-in in-world instrument (shapez 2 Belt Reader) [SOURCE].
2. Per-building single percentage, opened on demand (Satisfactory Productivity Display) [SOURCE].
3. A separate statistics panel (DSP; Factorio). DSP's own players complain the *bar* of items is near-useless because it
   "doesn't show unavailable items" — i.e. a persistent numeric strip that isn't actionable gets ignored [SOURCE].
Techtonica's stated plan is to add throughput to the machine panel — an on-demand panel, not the world view [SOURCE].

### 2.7 Mobile specifics
- **48dp / ~9mm minimum touch target, 8dp separation** [SOURCE: Android Accessibility].
- **Text that needs zooming is a review-killing defect**: "text is too small to read and making it bigger means zooming
  and scrolling back and forth" [SOURCE: Mindustry reviews].
- **Finger occlusion is real**: players with larger fingers "can't see beneath their hands" while placing [SOURCE].
- **Drag-routing has no good touch analogue** and it is 80% of the minute-to-minute loop in Mindustry [SOURCE].
- **First-tap reliability matters**: "buttons don't work on initial clicks" [SOURCE].
- [INFERENCE] The arithmetic for Lodeworks: a 360dp-wide phone viewport, 7 columns, a 16dp side gutter and 2dp
  inter-cell gaps gives roughly **(360 − 32 − 12) / 7 ≈ 45dp** per cell — *just under* the 48dp guidance. At 8dp
  gutters and 1dp gaps you get ≈48.6dp. So the board is right at the accessibility floor and **10 rows × ~49dp ≈ 490dp
  fits vertically on essentially every modern phone**. Conclusion: Lodeworks can and should render the entire board
  with no pan and no zoom, and must not put any tappable sub-element inside a cell.

### 2.8 Heat / spatial field over a discrete grid
- **ONI**: colour-gradient overlay, read as flow — "Look for gradients rather than isolated hot cells", "Chase heat
  flow, not the single hottest tile" [SOURCE].
- **RimWorld Heat Map mod**: the cleanest documented ramp for a *target* temperature — green at the comfort point
  (22°C), deeper blue below, deeper red above, **clamped to a fixed −12…56°C window**, behind a toggle [SOURCE].
- **RimWorld vanilla (negative)**: colour alone fails exactly where it matters — "those few degrees determine whether a
  pawn slept in the cold or not" — and is an accessibility problem for colourblind players [SOURCE].
- **Factorio**: treats temperature as a status value (`low-temperature`) and exposes heat-pipe temperatures only in the
  cursor-local overlay mod, not always-on [SOURCE].
- **UNKNOWN**: Mindustry's Erekir heat and Reactor Incremental's cell heat — both mechanically closer to Lodeworks
  (heat passed to orthogonal neighbours) but I could not verify how either draws it.

### 2.9 What players say is confusing
Collected, all [SOURCE]:
- Factorio: alt-mode is informative but clutters the view permanently — hence a mod that limits it to the cursor.
- shapez 2: throughput readings "stop updating when items stop going through"; palette confusion (yellow reads orange).
- Mindustry: small text, finger occlusion, unreliable first taps, forced orientation, no touch drag-routing.
- DSP: 3D occlusion, no hotbar, item bar hides unavailable items, spherical grid distortion.
- Satisfactory: not enough status colours to separate "I turned it off" from "it has no power".
- RimWorld: colour-only temperature; must hover each room with ALT.
- Little Big Workshop: no way to find your stumbling point.
- Assembly Line 2 (mobile): "internal 'tick' that aren't visible to us"; descriptions "vague".

---

## 3. Ranked: the 12 most transferable techniques for a small mobile grid game drawn with procedural 2D code

Ranked by **(impact on Lodeworks' current problems) × (cheapness in pure `draw_*` calls, no bitmaps)**.
Cost labels assume Godot `CanvasItem` drawing: `draw_rect`, `draw_circle`, `draw_arc`, `draw_line`,
`draw_colored_polygon`, `draw_string`.

| # | Technique | Origin (verified) |
|---|---|---|
| 1 | **Three-state status pip per machine** (green working / amber output-blocked / red input-starved) | Factorio *Bottleneck* + *Bottleneck Lite*, ~544K combined downloads |
| 2 | **Output-icon on the machine face, toggleable** (alt-mode) | Factorio alt-mode; demanded in Captain of Industry |
| 3 | **Edge hand-off tick**: animate the transfer on the shared border, not a belt | Factorio inserters [INFERENCE on form]; Techtonica animation-as-state |
| 4 | **Work-cycle progress arc** around or under the machine glyph | Rise of Industry product bubbles with progress; Satisfactory Productivity Display |
| 5 | **Toggleable full-board field overlay for heat**, with a clamped diverging ramp centred on the target | RimWorld *Heat Map* (green at 22°C, blue below, red above, clamped −12…56°C); ONI |
| 6 | **Numbers on the field overlay, not colour alone** | RimWorld vanilla failure case |
| 7 | **Uptime % (duty cycle) as the single throughput number** | Satisfactory Productivity Display (0–100% of max speed) |
| 8 | **Placement-time adjacency preview**: highlight the 4 affected neighbours and show the delta live | ISLANDERS blue radius circle + live score |
| 9 | **Cursor/selection-local detail**: dense info only for the tapped cell and its 4 neighbours | Factorio *Alternative Alt Mode* |
| 10 | **Global "worst offender" strip** that jumps the camera/selection to the culprit | Factorio alert strip + screen-edge arrows |
| 11 | **Silhouette + notch differentiation, plus a colourblind mode** | shapez 2 "RGB (colorblind)" mode; RimWorld colourblind criticism; FFF #195 simplification |
| 12 | **Animation stop = alarm** (a machine that was moving and isn't, reads as broken instantly) | Techtonica accumulators: "they'll stop spinning" |

---

## 4. Application to Lodeworks, with impact and drawing cost

**1. Three-state status pip.** Draw a filled circle radius ≈ 0.10 × cell in one fixed corner of every cell (say top-right),
outside the glyph's optical centre. Map Lodeworks' states: *green* = produced this tick; *amber* = has output, receiver
full/absent (blocked); *red* = no input (starved). Put **over/under-temperature into a fourth state, magenta/cyan or a
pip with a ring**, mirroring Satisfactory's white-for-boosted precedent. Keep it to four fills max — the Satisfactory
thread is explicit that adjacent hues get confusable. **Impact: HIGH. Cost: CHEAP** (70 `draw_circle` calls).

**2. Output-icon on the machine face.** Lodeworks already draws one glyph per machine — change it from *machine identity*
to *material produced*, or draw the material glyph small and the machine as the cell's shape. Toggle via a single
always-visible button. This is the single most-requested feature in the comparable games. **Impact: HIGH.
Cost: CHEAP** (already drawing a glyph; add a toggle and a second small glyph).

**3. Edge hand-off tick.** On each transfer from cell A to orthogonal cell B, draw a short line/dot that animates across
the shared edge over ~0.15s, coloured by the material. Because the grid is 7x10 and cells are ~49dp, an edge is ~49dp
long — plenty. This makes flow visible *exactly where Lodeworks' mechanic lives* and needs no belts.
**Impact: HIGH. Cost: CHEAP-to-MEDIUM** (one tween per active edge; cap the number of simultaneous ticks drawn, e.g.
only for the 8–12 highest-rate edges, to stop 70 cells × 4 edges of noise).

**4. Work-cycle progress arc.** `draw_arc` a 270° sweep at radius ≈ 0.38 × cell showing progress through the current
craft. This is Lodeworks' "is anything alive" signal and it costs one call per cell. It also gives you technique 12 free:
a stalled arc *is* the alarm. **Impact: HIGH. Cost: CHEAP.**

**5. Heat overlay, toggleable, diverging ramp centred on target.** A button toggles a heat mode where each cell is filled
with a colour from the RimWorld Heat Map ramp — but centred on **that machine's own preferred temperature**, not an
absolute scale: green/neutral at the machine's ideal, blue below, red above, clamped to a fixed ±N window so the ramp
never goes flat. [INFERENCE] Because every Lodeworks machine has a *different* ideal temperature, a relative ramp is
strictly more useful than ONI's absolute one, and it makes the whole board readable as "how wrong is each machine"
rather than "how hot is each cell". Offer an absolute mode too for reading the bleed field itself.
**Impact: HIGH. Cost: CHEAP** (70 `draw_rect` fills).

**6. Numbers on the heat overlay.** While the heat overlay is on, `draw_string` the temperature delta (e.g. `+14`) in each
cell. RimWorld's vanilla overlay is criticised precisely for omitting this, and it's an accessibility requirement, not a
nicety. At ~49dp cells, 2–3 characters at ~11sp is legible; do not attempt this in the default view.
**Impact: HIGH. Cost: CHEAP.**

**7. Uptime %.** Track a rolling duty cycle per machine (fraction of the last N ticks it actually produced). Show it in
the selected-machine panel as one number, and optionally as a thin fill bar along the bottom edge of each cell when a
"performance" overlay is on. This is the number that makes a bottleneck sortable, and it is far cheaper to compute and
explain than items/sec. **Impact: HIGH. Cost: CHEAP.**

**8. Placement-time adjacency preview.** While dragging a machine, dim the board, draw a bright outline on the target
cell and a distinct outline (plus a small `+`/`−`) on each of the ≤4 orthogonal neighbours it will feed, be fed by, or
heat. Show the resulting heat delta on those neighbours as a signed number. This is ISLANDERS' blue circle adapted to a
4-neighbourhood, and it directly teaches Lodeworks' two core rules at the moment the player is deciding.
**Impact: HIGH. Cost: CHEAP.**

**9. Selection-local detail.** On tap-select, draw full detail (rate, temperature, input/output contents) for the selected
cell *and small badges on its 4 neighbours only*. Everything else stays clean. This is the documented cure for
alt-mode clutter, and on a phone it also solves finger occlusion: put the detail panel in the **bottom sheet**, below
the board, never in a popover under the thumb. **Impact: MEDIUM-HIGH. Cost: CHEAP.**

**10. Worst-offender strip.** A one-line bar above or below the board: "3 starved · 1 overheating", tappable to cycle
selection through the offending cells. Factorio's screen-edge arrows are unnecessary here (nothing is off-screen) but
the *list-and-jump* half of the pattern is the valuable half. **Impact: MEDIUM-HIGH. Cost: CHEAP.**

**11. Silhouette + notch + colourblind mode.** Give each machine *family* a distinct cell shape drawn procedurally —
square, cut-corner (octagon), rounded, hexagon-ish — so identity survives greyscale. Draw a small chevron/notch on the
edge a machine primarily outputs to, so orientation is readable without an arrow overlay. Ship a colourblind palette
that separates the status pips by **shape as well as hue** (filled circle / hollow circle / triangle / square), because
shapez 2 ships a colourblind mode and RimWorld is criticised for not having one.
**Impact: MEDIUM. Cost: MEDIUM** (polygon maths per family, but written once).

**12. Animation stop as alarm.** Ensure every running machine has *some* continuous motion (the arc in #4, a slow pulse
on the glyph, or the edge ticks in #3) so that stopping is unmistakable. Techtonica uses exactly this. It costs nothing
extra once #3 and #4 exist. **Impact: MEDIUM. Cost: FREE** (falls out of #3/#4).

### Suggested build order
`#1 + #4` first (one afternoon, and they fix the "nothing animates / can't see state" complaint outright), then `#2`,
then `#3`, then `#5 + #6`, then `#8`, then `#7 + #10`, then `#9`, then `#11`.

---

## 5. Techniques that will NOT work at phone size or on a 7x10 board

| Technique | Why not |
|---|---|
| **Item sprites travelling along belts** | Lodeworks has no belts. There is no run of tiles for an item to traverse; transfer is edge-adjacent and instantaneous. The belt-sprite idiom has nothing to attach to. Use the edge hand-off tick instead. |
| **Always-on numeric throughput on every cell** | 70 simultaneous numbers at ~49dp. Mindustry's reviews show text that needs zooming is a review-killing defect [SOURCE]; DSP's persistent item bar is ignored because it isn't actionable [SOURCE]. Numbers belong in the selection sheet or behind an overlay toggle. |
| **Hover tooltips** | There is no hover on touch. RimWorld's ALT-hover-per-room workflow is explicitly criticised even on desktop [SOURCE]. Everything must be reachable by a single tap or be always-drawn. |
| **Screen-edge arrows to off-screen culprits** | [INFERENCE] The whole 7x10 board fits on a phone at ~49dp cells (≈490dp tall). Nothing is ever off-screen, so the pointer half of Factorio's alert system is dead weight. Keep the list, drop the arrows. |
| **Free pan and zoom as the way to read detail** | Mindustry: "making it bigger means zooming and scrolling back and forth" [SOURCE]. If the board fits, pan/zoom is pure friction. Allow at most a pinch-to-inspect that snaps back. |
| **Drag-to-route / drag-to-connect** | Mindustry's drag routing is "the most frustrating part of playing on mobile" and has no touch equivalent [SOURCE]. Reserve drag exclusively for *moving a machine between cells*; everything else is tap. |
| **A continuous, smoothed heat field rendered across cell boundaries** | Lodeworks' rule is discrete: full strength in the cell, half to orthogonal neighbours. A blurred/interpolated field would *misrepresent the rule the player must reason about*, and per-pixel gradients are expensive without bitmaps or shaders. Fill whole cells; let the eye do the gradient, as ONI players already do ("look for gradients") [SOURCE]. |
| **Eight or more status colours** | Satisfactory players themselves argue extra hues get confusable — "orange would be too close" [SOURCE]. Bottleneck Lite collapses ~8 engine statuses into 3 colours [SOURCE]. Cap at four, and differentiate the fourth by shape. |
| **Isometric or pseudo-3D machine bodies** | DSP's "building heights hide elements behind structures" is a named selection and readability failure [SOURCE]. At 49dp there is no room for a body and a roof and a state pip. |
| **Node-graph / visual-programming inspectors** (Desynced-style) | No screen space; and Desynced's own case study says only that managing information density was "the main challenge" without claiming it was solved [SOURCE]. |
| **Solution histograms / global leaderboards on metrics** (Opus Magnum) | Opus Magnum's metrics work because each puzzle has one bounded solution space. Lodeworks is an open idle board with strata modifiers; there is nothing to compare against. |
| **Any tappable sub-element inside a cell** | [INFERENCE] A 49dp cell is already at the 48dp minimum [SOURCE: Android]; a sub-button inside it would be ~20dp, half the accessible floor, and would sit under the finger. All per-machine actions belong in the bottom sheet after selection. |
| **Persistent dense overlay on all cells at once (full alt-mode)** | Factorio needed a mod to restrict alt-mode to the cursor's surroundings because the always-on version clutters [SOURCE]. On a phone, with 70 cells filling the screen, the clutter problem is strictly worse. |

---

## 6. Explicit gaps in this research

- **shapez 2 Devlog 013/021/036** — the art-direction devlogs almost certainly contain first-party statements about
  readability. Steam announcement bodies did not render through my tooling and direct fetches to steamcommunity.com
  were blocked by the egress proxy. **UNKNOWN.**
- **Mindustry (Erekir) heat, Reactor Incremental cell heat** — both are mechanically the closest published analogues to
  Lodeworks' "heat to orthogonal neighbours" rule. Both wikis returned HTTP 402 to my fetcher. **UNKNOWN.**
- **Autonauts, Big Pharma, Infinifactory, Idle Factory Tycoon, Dorfromantik, Tiny Glade** — examined at search level,
  no source found in this pass documenting a specific, citable readability or state-feedback convention. **UNKNOWN.**
- **Satisfactory status-light colours** are player-reported from a Steam discussion, not an official wiki or patch note.
  Treat the white/overclocked state in particular as low-confidence.
- **Desynced** — a UI/UX case study exists but states the problem without describing the solution. No technique extracted.
