# Lodeworks — Godot 4.7 / gl_compatibility / Android performance & game feel

Research date: 2026-09-23. Target: Godot 4.7, `gl_compatibility`, mid/low-end Android, all-procedural `_draw()` UI + 7x10 board, no bitmaps.

**Verification policy used here.** Every API name and enum below is marked:
- **[V-4.7]** = read verbatim from `doc/classes/*.xml` on the `godotengine/godot` **4.7 branch**.
- **[V-SRC]** = read verbatim from engine source on `master`.
- **[V-DOC]** = read verbatim from `godotengine/godot-docs`.
- **[UNVERIFIED]** = could not confirm in this research. Do not paste without checking editor autocomplete.

---

## 1. What costs what — 2D on gl_compatibility / Android

The compatibility renderer builds *canvas instance batches*. The authoritative list of what forces a new batch is in `drivers/gles3/rasterizer_canvas_gles3.cpp` (`_record_item_commands`) **[V-SRC]**.

| Thing | Cost | Why / source |
|---|---|---|
| **Changing material (ShaderMaterial or CanvasItemMaterial)** between adjacent canvas items | **Breaks the batch** → new draw call | `if (material != state.canvas_instance_batches[state.current_batch_index].material)` **[V-SRC]** |
| **Changing texture filter** (`texture_filter` per-CanvasItem or project default) | **Breaks the batch** | `if (texture_filter != ...filter)` **[V-SRC]** |
| **Changing texture repeat** | **Breaks the batch** | `if (texture_repeat != ...repeat)` **[V-SRC]** |
| **Changing blend mode or blend colour** | **Breaks the batch** | `if (blend_mode != ...blend_mode \|\| blend_color != ...blend_color)` **[V-SRC]** |
| **Clip / `clip_children` boundary change** | **Breaks the batch** | `if (ci->final_clip_owner != ...clip)` **[V-SRC]** |
| **Toggling "lights disabled"** (e.g. `LIGHT_MODE_UNSHADED` vs normal, next to each other) | **Breaks the batch** | `lights_disabled != bool(...specialization & CanvasShaderGLES3::DISABLE_LIGHTING)` **[V-SRC]** |
| **`draw_rect()` / textured rects (`TYPE_RECT`)** | **Batchable** — merges while texture, filter, repeat, blend match | **[V-SRC]** |
| **`TYPE_PRIMITIVE`** (small point/line/tri primitives) | **Batchable** — merges while *point count*, command type and texture match | **[V-SRC]** |
| **`TYPE_POLYGON`** (`draw_polygon`, `draw_colored_polygon`, `draw_circle`, antialiased/thick lines) | **Never batched — one draw call each.** Source comment: *"Polygon's can't be batched, so always create a new batch"* | **[V-SRC]** |
| **`TYPE_MESH` / `TYPE_MULTIMESH` / `TYPE_PARTICLES`** | **Never batched.** *"Meshes can't be batched, so always create a new batch."* | **[V-SRC]** |
| **`TYPE_NINEPATCH`** | Forces its own batch | **[V-SRC]** |
| **`TYPE_TRANSFORM` (`draw_set_transform`) and `TYPE_ANIMATION_SLICE`** | **Free** for batching — state only, no batch break | *"Can ignore these as they only impact batch creation."* **[V-SRC]** |
| **Exceeding the instance buffer** | Forced flush | `if (r_index + state.last_item_index >= data.max_instances_per_buffer)` **[V-SRC]** |
| **Label / Control node counts** | Each glyph is counted as an object/draw call in the monitors. Godot issue #90133 reports that from 4.3 onward `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` and `RENDER_TOTAL_OBJECTS_IN_FRAME` **include all UI elements, and the counter rises per letter typed** (was not the case in 4.2.1). Glyphs are textured rects, so they *do* batch when font atlas + filter + blend match. |
| **`queue_redraw()` frequency** | Cheap to call, but the redraw itself is the cost. *"This only occurs **once** per frame, even if this method has been called multiple times."* and *"canvas items don't need to be redrawn on every frame, improving the performance significantly"* **[V-4.7 CanvasItem]** |
| **First draw of a new 2D shader / Control** | **Stall.** Godot issue #76241: on the Compatibility renderer, first-time instantiation of Control nodes dropped 60fps → 23fps; not present on Mobile/Forward+. |
| **Per-tile shaders / rounded corners** | Measured, closest real analogue to Lodeworks: Godot forum thread 108481 — Godot 4.4.1, Compatibility renderer, Android, **11x11 = 121 tiles: ~12 ms render time → ~3 ms** after removing per-tile shaders and StyleBox corner radius. ~75% faster. |
| **Renderer scaling characteristic** | Compatibility has *"Low base cost, but high scaling cost"* **[V-DOC renderers.rst]** |

**Not available in gl_compatibility (2D-relevant)** **[V-DOC renderers.rst]**: MSAA 2D, TAA, FSR2, FXAA, SMAA, screen-space roughness limiter. Tracker #66458 additionally lists as still open: *"OpenGL: 2D MSAA antialiasing is not reimplemented yet"*, *"OpenGL: FXAA antialiasing is not reimplemented yet"*, *"Screen Reading Textures ignore 'nearest' filtering flag in compatibility render"*.

**Available in gl_compatibility**: glow/bloom (merged for **4.3** via PR #87360 — explicitly *"basic implementation… to keep this performant on mobile devices"*, dual-filter blur, works in 2D; glow over a transparent background requires 2D HDR), adjustments, custom post-processing via a fullscreen quad **[V-DOC renderers.rst]**; `hint_screen_texture` + `BackBufferCopy`.

---

## 2. Runtime performance counters — exact GDScript

### 2a. `Performance.get_monitor()` — **[V-4.7 Performance.xml]**

Signature: `Performance.get_monitor(monitor: int) -> float`.
Custom monitors: `Performance.add_custom_monitor(id: StringName, callable: Callable, arguments: Array = [], type: int = 0) -> void`.

Confirmed constants relevant to a 2D budget checker (name, value, doc gist):

| Constant | Val | Meaning |
|---|---|---|
| `Performance.TIME_FPS` | 0 | frames in last second; **updated only once per second** |
| `Performance.TIME_PROCESS` | 1 | frame time, **seconds** |
| `Performance.TIME_PHYSICS_PROCESS` | 2 | physics frame time, seconds |
| `Performance.MEMORY_STATIC` | 4 | static memory bytes — **not available in release builds** |
| `Performance.MEMORY_STATIC_MAX` | 5 | available static memory — not in release builds |
| `Performance.MEMORY_MESSAGE_BUFFER_MAX` | 6 | peak message-queue bytes |
| `Performance.OBJECT_COUNT` | 7 | objects instantiated |
| `Performance.OBJECT_RESOURCE_COUNT` | 8 | resources in use |
| `Performance.OBJECT_NODE_COUNT` | 9 | nodes in tree (incl. root) |
| `Performance.OBJECT_ORPHAN_NODE_COUNT` | 10 | **debug only — always 0 in release** |
| `Performance.RENDER_TOTAL_OBJECTS_IN_FRAME` | 11 | objects last frame |
| `Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME` | 12 | vertices/indices last frame |
| `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` | 13 | draw calls last frame |
| `Performance.RENDER_VIDEO_MEM_USED` | 14 | **video memory, bytes** (texture + vertex + misc; always > texture+buffer) |
| `Performance.RENDER_TEXTURE_MEM_USED` | 15 | **texture memory, bytes** |
| `Performance.RENDER_BUFFER_MEM_USED` | 16 | render buffer memory, bytes |
| `Performance.PIPELINE_COMPILATIONS_CANVAS` | 34 | **pipeline compilations triggered by the 2D canvas renderer** — the hitch counter for this project |
| `Performance.PIPELINE_COMPILATIONS_MESH` | 35 | mesh-load compilations |
| `Performance.PIPELINE_COMPILATIONS_SURFACE` | 36 | surface-cache compilations |
| `Performance.PIPELINE_COMPILATIONS_DRAW` | 37 | on-demand draw compilations |
| `Performance.PIPELINE_COMPILATIONS_SPECIALIZATION` | 38 | background specialization |

(Also confirmed and present but irrelevant here: `TIME_NAVIGATION_PROCESS`=3, `PHYSICS_2D_ACTIVE_OBJECTS`=17, `PHYSICS_2D_COLLISION_PAIRS`=18, `PHYSICS_2D_ISLAND_COUNT`=19, `AUDIO_OUTPUT_LATENCY`=23, the `NAVIGATION_*` / `NAVIGATION_2D_*` / `NAVIGATION_3D_*` block, `MONITOR_MAX`=59.)

### 2b. The **2D** draw-call counter — `Viewport.get_render_info()` **[V-4.7 Viewport.xml]**

This is the one that actually isolates 2D. `RenderingServer.get_rendering_info()` carries the note *"Only 3D rendering is currently taken into account by some of these values, such as the number of draw calls"* **[V-4.7 RenderingServer.xml]**, so prefer this:

Signature: `get_render_info(type: int, info: int) -> int`

`Viewport.RenderInfoType`: `RENDER_INFO_TYPE_VISIBLE` = 0, `RENDER_INFO_TYPE_SHADOW` = 1, **`RENDER_INFO_TYPE_CANVAS` = 2** (*"Canvas item rendering. This includes all 2D rendering."*), `RENDER_INFO_TYPE_MAX` = 3.

`Viewport.RenderInfo`: `RENDER_INFO_OBJECTS_IN_FRAME` = 0, `RENDER_INFO_PRIMITIVES_IN_FRAME` = 1, `RENDER_INFO_DRAW_CALLS_IN_FRAME` = 2, `RENDER_INFO_MAX` = 3.

### 2c. `RenderingServer.get_rendering_info()`

Signature **[V-4.7]**: `RenderingServer.get_rendering_info(info: int) -> int`, enum type `RenderingServer.RenderingInfo`. Notes **[V-4.7]**: *"Only 3D rendering is currently taken into account by some of these values, such as the number of draw calls."* and *"Rendering information is not available until at least 2 frames have been rendered by the engine."*

The constant **names** could not be loaded from the 4.7 branch in this research (the XML is too large to fetch whole). A 4.3 documentation mirror gives: `RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME`=0, `RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME`=1, `RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME`=2, `RENDERING_INFO_TEXTURE_MEM_USED`=3, `RENDERING_INFO_BUFFER_MEM_USED`=4, `RENDERING_INFO_VIDEO_MEM_USED`=5. **Treat these as [UNVERIFIED for 4.7] — confirm with editor autocomplete before shipping.** Everything you need is already in 2a/2b, so you can avoid this API entirely.

### 2d. Memory APIs **[V-4.7 OS.xml]**

- `OS.get_static_memory_usage() -> int` — *"Only works in debug builds."*
- `OS.get_static_memory_peak_usage() -> int` — *"Only works in debug builds."*
- `OS.get_memory_info() -> Dictionary` — keys `"physical"`, `"free"`, `"available"`, `"stack"`; *"Each entry may return -1 if unknown."* Works in release.
- `Node.print_orphan_nodes()` — **static**, *"Prints all orphan nodes… only functions in debug builds."* **[V-4.7 Node.xml]**

### 2e. Paste-ready budget checker

```gdscript
extends Node
## Poll once per second; every name below is verified against Godot 4.7 class XML.

const BUDGET := {
    "frame_ms": 16.6,
    "canvas_draw_calls": 0,   # set from your own device baseline, see section 3
    "nodes": 0,
    "tex_mem_mb": 0.0,
}

func _ready() -> void:
    var t := Timer.new()
    t.wait_time = 1.0
    t.autostart = true
    t.timeout.connect(_sample)
    add_child(t)

func _sample() -> void:
    var vp := get_viewport()

    # --- 2D-specific (the numbers that matter for Lodeworks) ---
    var canvas_draws := vp.get_render_info(
        Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
    var canvas_objs := vp.get_render_info(
        Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
    var canvas_prims := vp.get_render_info(
        Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)

    # --- Whole-frame ---
    var fps          := Performance.get_monitor(Performance.TIME_FPS)
    var frame_ms     := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
    var draws_total  := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    var objs_total   := Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
    var prims_total  := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)

    # --- Memory (bytes) ---
    var vram_mb := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)   / 1048576.0
    var tex_mb  := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
    var buf_mb  := Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)  / 1048576.0

    # --- Object churn ---
    var nodes     := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
    var objects   := Performance.get_monitor(Performance.OBJECT_COUNT)
    var resources := Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
    var orphans   := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) # debug only

    # --- Shader/pipeline hitches: should stop rising after warm-up ---
    var pipe_canvas := Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_CANVAS)

    # MEMORY_STATIC is debug-only; guard it.
    var static_mb := 0.0
    if OS.is_debug_build():
        static_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0

    print("fps=%.0f frame=%.2fms | canvas draws=%d objs=%d prims=%d | total draws=%.0f objs=%.0f prims=%.0f | vram=%.1f tex=%.1f buf=%.1f MB | nodes=%.0f obj=%.0f res=%.0f orph=%.0f | pipeCanvas=%.0f | static=%.1fMB" % [
        fps, frame_ms, canvas_draws, canvas_objs, canvas_prims,
        draws_total, objs_total, prims_total,
        vram_mb, tex_mb, buf_mb, nodes, objects, resources, orphans,
        pipe_canvas, static_mb])
```

---

## 3. Recommended budget — 7x10 idle game, low-end Android

**Read this first: no official Godot document publishes per-frame budgets for 2D on Android.** Anything not tied to a source below is marked UNKNOWN and must be replaced by a measurement on your own worst target device. Use §2e to capture that baseline.

| Budget item | Number | Justification |
|---|---|---|
| **Frame time** | **≤ 16.6 ms** for 60 fps; **≤ 33.3 ms** if you ship at `Engine.max_fps = 30` | Arithmetic from the target frame rate, not a source. `Engine.max_fps` doc: *"Limiting frame rates reduces power consumption, heat… extending battery life"* **[V-4.7]** |
| **Render time for the 70-tile board** | **≤ 3 ms** target, **12 ms = failure** | Directly measured analogue: Godot forum 108481, Godot 4.4.1 + Compatibility + Android, **121 tiles at ~12 ms dropped to ~3 ms** once per-tile shaders and corner radius were removed. 70 tiles is ~58% of that workload. |
| **Canvas draw calls (`RENDER_INFO_TYPE_CANVAS`)** | **UNKNOWN as an absolute.** Set your ceiling at *measured idle baseline × 1.5*. A third-party mobile guide (slicker.me, not official, version unspecified) suggests ~100 draw calls/frame on mobile — treat as folklore, not a Godot figure. | No Godot doc states a draw-call budget. |
| **Structural rule that replaces the draw-call number** | The 70 board cells should collapse to **a small constant number of batches**, not 70. Achievable only if all cells share material, texture filter, texture repeat, blend mode and clip state, and are drawn as `TYPE_RECT`/`TYPE_PRIMITIVE`. | Batch-break list **[V-SRC]**, §1 |
| **Polygon-type primitives per frame** | **Count them; each is one draw call.** `draw_circle`, `draw_polygon`, `draw_colored_polygon`, antialiased/thick lines → `TYPE_POLYGON`. Budget these explicitly rather than by feel. | *"Polygon's can't be batched, so always create a new batch"* **[V-SRC]** |
| **`PIPELINE_COMPILATIONS_CANVAS`** | **Must be flat (delta = 0) after the loading screen.** Any increase during play is a visible hitch. | Monitor description: *"Number of pipeline compilations that were triggered by the 2D canvas renderer"* **[V-4.7]**; Compatibility has no ubershaders **[V-DOC]**; issue #76241 measured 60→23 fps on first Control draw. |
| **`OBJECT_ORPHAN_NODE_COUNT`** | **0, steady** (debug builds) | *"only available in debug mode and will always return 0… in release"* **[V-4.7]** |
| **`OBJECT_NODE_COUNT`** | **Flat across a full idle cycle.** Absolute ceiling UNKNOWN. | Growth = leak; no published ceiling. |
| **`RENDER_TEXTURE_MEM_USED`** | **Flat after warm-up.** You ship zero bitmaps, so this is font atlases only; any growth is a font-atlas or viewport leak. Absolute MB ceiling UNKNOWN. | No Godot source states a texture-memory budget. |
| **`MEMORY_STATIC` / `OS.get_static_memory_usage()`** | **Flat across a 30-minute idle run.** Absolute ceiling UNKNOWN. | Debug-only **[V-4.7]** |
| **Total RAM on Android** | **UNKNOWN.** The "~300 MB" and "~512 MB" figures circulating come from a third-party guide (slicker.me), not Godot or Google. Measure with `OS.get_memory_info()`. | — |
| **Particle counts on a low-end phone** | **UNKNOWN — no Godot doc or issue publishes a number.** Derive empirically. Constraints that *are* documented: every particle node is its own draw call (`TYPE_PARTICLES` never batches **[V-SRC]**); `amount_ratio` gives **no** perf saving because resources are allocated for the full `amount` **[V-4.7]**; high `preprocess` *"can even lead to a GPU crash"* **[V-4.7]**. | — |
| **Physics** | `Engine.physics_ticks_per_second` — an idle game needs no 2D physics; leave nodes out entirely. Doc warns rates *"below 30 can destabilize physics behavior and reduce input responsiveness"* **[V-4.7]**, so don't simply lower it. | — |

**CPUParticles2D vs GPUParticles2D on gl_compatibility/Android.** Both function; the documented differences are:
- `CPUParticles2D` exists precisely because `GPUParticles2D` *"may not run on older devices"* **[V-4.7 CPUParticles2D.xml]**.
- `GPUParticles2D.emit_particle()` is *"only supported on the Forward+ and Mobile rendering methods, **not Compatibility**"* **[V-4.7 GPUParticles2D.xml]** — so one-shot manual emission is off the table for you.
- Tracker #66458 lists as **unresolved**: *"On a GPUParticles2D, when using Compatibility renderer, 'reverse lifetime' draw order and non-local coords don't play nice"*.
- Godot forum reports show particle **shader compilation lag** on first emission in Compatibility (web/mobile), consistent with #76241.
- **Recommendation for Lodeworks:** given you have no textures, no `emit_particle()`, tiny counts, and want to avoid a first-use canvas-pipeline compile, hand-rolled particles in your existing `_draw()` (as batched `TYPE_RECT`s, *not* `draw_circle`) are the lowest-risk option, with `CPUParticles2D` as the fallback. Whatever you pick, warm it up before gameplay.

---

## 4. Juice that works in gl_compatibility

All Tween names verified **[V-4.7 Tween.xml]**: `create_tween()`, `tween_property()`, `tween_method()`, `tween_callback()`, `tween_interval()`, `set_ease()`, `set_trans()`, `set_loops()`, `set_parallel()`, `chain()`, `set_process_mode()`, `set_pause_mode()`, `kill()`, `is_running()`. `TransitionType`: `TRANS_LINEAR` 0, `TRANS_SINE` 1, `TRANS_QUINT` 2, `TRANS_QUART` 3, `TRANS_QUAD` 4, `TRANS_EXPO` 5, `TRANS_ELASTIC` 6, `TRANS_CUBIC` 7, `TRANS_CIRC` 8, `TRANS_BOUNCE` 9, `TRANS_BACK` 10, `TRANS_SPRING` 11. `EaseType`: `EASE_IN` 0, `EASE_OUT` 1, `EASE_IN_OUT` 2, `EASE_OUT_IN` 3. `TweenProcessMode`: `TWEEN_PROCESS_PHYSICS` 0, `TWEEN_PROCESS_IDLE` 1. `TweenPauseMode`: `TWEEN_PAUSE_BOUND` 0, `TWEEN_PAUSE_STOP` 1, `TWEEN_PAUSE_PROCESS` 2.

### 4.1 Punch scale (no art, no batch break)
Animate a plain float and redraw; `draw_set_transform` is batch-neutral **[V-SRC]**.
```gdscript
var punch := 1.0

func punch_tile() -> void:
    var t := create_tween()
    t.tween_property(self, "punch", 1.18, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    t.tween_property(self, "punch", 1.0, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    t.step_finished.connect(func(_i): queue_redraw())   # or drive redraw from _process while running

func _draw() -> void:
    draw_set_transform(size * 0.5, 0.0, Vector2(punch, punch))
    draw_rect(Rect2(-size * 0.5, size), colour)   # TYPE_RECT → batchable
```

### 4.2 Shake, decaying, driven by one float
```gdscript
var shake := 0.0

func add_shake(amount: float) -> void:
    shake = min(shake + amount, 12.0)

func _process(delta: float) -> void:
    if shake > 0.0:
        shake = move_toward(shake, 0.0, 30.0 * delta)
        offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
        queue_redraw()
```

### 4.3 Number roll-up — `tween_method` (no node churn)
```gdscript
func roll_to(new_value: int) -> void:
    var t := create_tween()
    t.tween_method(_set_display, float(displayed), float(new_value), 0.45) \
     .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_display(v: float) -> void:
    displayed = int(round(v))
    queue_redraw()
```

### 4.4 Colour flash — `modulate`, **not** a shader
The 108481 thread's 75% win came from deleting per-tile shaders; `modulate` is a CanvasItem property, adds no material, and therefore cannot break a batch.
```gdscript
func flash(c := Color(1.6, 1.6, 1.6)) -> void:
    var t := create_tween()
    t.tween_property(self, "modulate", c, 0.05)
    t.tween_property(self, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_QUAD)
```

### 4.5 Cheap "glow" — two options
- **Real bloom:** WorldEnvironment glow *is* supported in Compatibility since **4.3** (PR #87360), works in 2D, deliberately basic for mobile; glow over a transparent background requires 2D HDR. Full-screen cost — measure before committing.
- **Faked glow, zero post-processing:** draw 3–4 concentric alpha-falloff rects behind the tile with `CanvasItemMaterial.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD` **[V-4.7]**. Keep every glow quad in **one** CanvasItem so the blend-mode switch costs a single batch break, not one per tile.

### 4.6 Heat shimmer / steam
- **Screen-reading route:** `hint_screen_texture` + `BackBufferCopy` work in 2D. Godot docs **[V-DOC]**: in 2D a full-screen copy happens automatically before the first node using `hint_screen_texture` draws; subsequent nodes do **not** trigger extra copies; use `BackBufferCopy` between overlapping shader nodes. Caveat from tracker #66458: *"Screen Reading Textures ignore 'nearest' filtering flag in compatibility render"* (unresolved). A full-screen back-buffer copy each frame is a bandwidth cost on low-end mobile — gate it behind a quality setting.
- **Primitive route (recommended):** rising `TYPE_RECT` quads with sine-offset x, fading alpha, additive blend. Batches, no screen read, no shader compile.

### 4.7 Redraw discipline
`queue_redraw()` coalesces: *"This only occurs once per frame, even if this method has been called multiple times"* **[V-4.7]**. Call it freely, but only from things that actually changed. `draw_polyline()` and `draw_multiline()` are documented as *"faster than using individual draw_line calls"* **[V-4.7]**; `draw_colored_polygon()` with many vertices should be pre-triangulated via `Geometry2D.triangulate_polygon()` **[V-4.7]**.

---

## 5. Haptics and procedural audio

### 5.1 Android haptics

**The whole API is one call** **[V-4.7 Input.xml]**:

```gdscript
Input.vibrate_handheld(duration_ms: int = 500, amplitude: float = -1.0) -> void
```

Documented behaviour **[V-4.7]**:
- Implemented on **Android, iOS and Web only**; every other platform ignores the call.
- `amplitude` is **0.0–1.0**; **`-1.0` means "use the device default strength"**.
- **Android requires the `VIBRATE` permission enabled in the export preset.**
- iOS honours `duration_ms` only on **iOS 13+**.
- Web cannot set amplitude; Safari and Firefox for Android may not support it at all.
- Device settings — vibration off, Do Not Disturb, haptic-feedback preferences — can suppress it entirely.

**Real-device trap:** Godot issue #103496 — in **4.4-stable**, `Input.vibrate_handheld` **crashed on Android** when the `VIBRATE` permission was not enabled (not a bug in 4.3). Closed by PR #107385. Set the permission regardless, and treat vibration as best-effort.

```gdscript
## Autoload. Keep taps short; long buzzes read as errors and drain battery.
extends Node

var haptics_enabled := true          # expose in settings; some users hate it

func tap() -> void:        _pulse(12,  0.35)   # tile tap
func confirm() -> void:    _pulse(25,  0.6)    # placement accepted
func reject() -> void:     _pulse(60,  1.0)    # invalid move
func milestone() -> void:                        # small pattern
    _pulse(18, 0.7)
    await get_tree().create_timer(0.09).timeout
    _pulse(35, 1.0)

func _pulse(ms: int, amp: float) -> void:
    if not haptics_enabled:
        return
    if OS.get_name() != "Android" and OS.get_name() != "iOS":
        return                                   # no-op elsewhere; call is safe anyway
    Input.vibrate_handheld(ms, amp)
```

There is **no** Godot API to query whether a device has a vibrator (godot-proposals #1427 requests one and is still open), and **no** API for Android's predefined haptic constants (`EFFECT_CLICK` etc.) — that needs a plugin. Amplitude support itself was proposal #9582 and is now in the signature above.

### 5.2 Procedural audio — bake once, play many (recommended)

For tiny SFX, **generate `AudioStreamWAV` at load time** and play it with ordinary `AudioStreamPlayer`s. This avoids per-frame GDScript buffer filling entirely.

`AudioStreamWAV` **[V-4.7]**: properties `data: PackedByteArray`, `format: Format`, `loop_mode: LoopMode`, `loop_begin: int`, `loop_end: int`, `mix_rate: int = 44100`, `stereo: bool = false`, `tags: Dictionary`.
`Format`: `FORMAT_8_BITS`=0, `FORMAT_16_BITS`=1, `FORMAT_IMA_ADPCM`=2, `FORMAT_QOA`=3.
`LoopMode`: `LOOP_DISABLED`=0, `LOOP_FORWARD`=1, `LOOP_PINGPONG`=2, `LOOP_BACKWARD`=3.
Methods: static `AudioStreamWAV.load_from_file(path, options := {})`, static `AudioStreamWAV.load_from_buffer(stream_data, options := {})`, `save_to_wav(path)` (cannot save IMA ADPCM or QOA).

**`data` for `FORMAT_16_BITS` is raw little-endian signed 16-bit PCM — no RIFF/WAV header.** (Note for `FORMAT_8_BITS`: the docs state it expects **signed** PCM.)

```gdscript
## Bake SFX once in _ready(); zero licensed audio files, zero runtime generator cost.
const SR := 22050                      # plenty for UI blips; halves memory vs 44100

static func bake(duration: float, gen: Callable) -> AudioStreamWAV:
    var n := int(SR * duration)
    var fade := maxi(128, n / 20)      # ≥128-sample fades at BOTH ends -> no clicks
    var bytes := PackedByteArray()
    bytes.resize(n * 2)                 # 16-bit mono
    for i in n:
        var t := float(i) / SR
        var env := 1.0
        if i < fade:          env = smoothstep(0.0, 1.0, float(i) / fade)
        elif i > n - fade:    env = smoothstep(0.0, 1.0, float(n - i) / fade)
        var s : float = clampf(gen.call(t, float(i) / n) * env, -1.0, 1.0)
        bytes.encode_s16(i * 2, int(s * 32767.0))

    var w := AudioStreamWAV.new()
    w.format = AudioStreamWAV.FORMAT_16_BITS
    w.mix_rate = SR
    w.stereo = false
    w.loop_mode = AudioStreamWAV.LOOP_DISABLED
    w.data = bytes
    return w

# --- voices ---
static func blip(t: float, p: float) -> float:
    return sin(TAU * lerpf(880.0, 660.0, p) * t) * (1.0 - p)          # soft UI tap
static func clank(t: float, p: float) -> float:
    return (sin(TAU * 220.0 * t) * 0.6 + randf_range(-1.0, 1.0) * 0.4) * pow(1.0 - p, 3.0)
static func chime(t: float, p: float) -> float:
    return (sin(TAU * 523.25 * t) + 0.5 * sin(TAU * 783.99 * t)) * 0.5 * pow(1.0 - p, 2.0)

var sfx := {}
func _ready() -> void:
    sfx["blip"]  = bake(0.09, Callable(self, "blip"))
    sfx["clank"] = bake(0.22, Callable(self, "clank"))
    sfx["chime"] = bake(0.60, Callable(self, "chime"))
```

**Avoiding pops — the rules that matter:**
1. **Fade in and out.** Godot's own docs-user-notes for `AudioStreamGenerator` state the fix for clicks is to *"smoothly fade it out at the end (over a period of at least 100 samples)"*, and recommend `smoothstep()`. The `bake()` above uses ≥128 samples at both ends.
2. **Start and end at zero amplitude** — a non-zero first or last sample is a step discontinuity, i.e. a click.
3. **Clamp before converting to int16** — integer wraparound is a loud crack.
4. **Watch summed gain** when several SFX overlap; layering clips.
5. For looping tones set `loop_begin`/`loop_end` on a zero crossing.

### 5.3 Procedural audio — live synthesis (only if you need continuous tones)

`AudioStreamGenerator` **[V-4.7]**: `buffer_length: float = 0.5` (*"Lower values result in less latency, but require the script to generate audio data faster, resulting in increased CPU usage and more risk for audio cracking"*), `mix_rate: float = 44100.0`, `mix_rate_mode: int = 2` (uses `mix_rate` only when set to `MIX_RATE_CUSTOM`).

**Engine warning, verbatim [V-4.7]:** *"Due to performance constraints, this class is best used from C# or from a compiled language via GDExtension. If you still want to use this class from GDScript, consider using a lower mix_rate such as 11,025 Hz or 22,050 Hz."* On a low-end Android phone this is a real risk — prefer §5.2.

`AudioStreamGeneratorPlayback` **[V-4.7]**: `push_frame(frame: Vector2) -> bool` (*"may be more efficient in GDScript"* than `push_buffer`), `push_buffer(frames: PackedVector2Array) -> bool`, `can_push_buffer(amount: int) -> bool`, `get_frames_available() -> int`, `get_skips() -> int` (*"number of times playback skipped due to a buffer underrun… reset at the start of playback"* — poll this as your underrun alarm), `clear_buffer() -> void`.

```gdscript
var playback: AudioStreamGeneratorPlayback
var phase := 0.0

func _ready() -> void:
    var gen := AudioStreamGenerator.new()
    gen.mix_rate = 22050.0            # engine-recommended for GDScript
    gen.buffer_length = 0.15
    $Player.stream = gen
    $Player.play()
    playback = $Player.get_stream_playback()

func _process(_d: float) -> void:
    var inc := 440.0 / 22050.0
    for i in playback.get_frames_available():
        playback.push_frame(Vector2.ONE * sin(phase * TAU) * 0.2)
        phase = fmod(phase + inc, 1.0)
    if playback.get_skips() > 0:
        push_warning("audio underrun")     # raise buffer_length or lower mix_rate
```
When idle, set `$Player.stream_paused = true` — otherwise the generator keeps producing forever (Godot docs-user-notes).

---

## 6. Traps to avoid

1. **Do not give each board cell its own `ShaderMaterial`.** Every material change breaks the batch **[V-SRC]**, and this exact pattern cost a real Godot 4.4.1 Android project 12 ms/frame on 121 tiles (forum 108481). Use `modulate` and `draw_rect` colours.
2. **Do not use `StyleBoxFlat` corner radius per tile.** Same measurement — removing corner radius plus shaders gave the 75% win.
3. **Do not reach for `draw_circle` / `draw_colored_polygon` for per-cell decoration.** Every one is `TYPE_POLYGON` and *"can't be batched"* **[V-SRC]** — 70 circles = 70 draw calls. Use rects, or one merged polygon per layer.
4. **Do not mix blend modes cell-by-cell.** Draw all additive/glow elements in one CanvasItem, in one pass.
5. **Do not set `texture_filter` or `texture_repeat` per node.** Each differing value forces a new batch **[V-SRC]**.
6. **Do not assume `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` isolates the board.** From 4.3 it includes all UI elements and rises per glyph (issue #90133). Use `Viewport.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS, …)` for board-only numbers.
7. **Do not call `RenderingServer.get_rendering_info()` expecting 2D numbers** — *"Only 3D rendering is currently taken into account by some of these values, such as the number of draw calls"*, and it returns nothing useful until *"at least 2 frames have been rendered"* **[V-4.7]**.
8. **Do not expect pipeline precompilation or ubershaders to save you.** They *"only apply to the Forward+ and Mobile renderers, not Compatibility"* **[V-DOC]**. The documented remedy is the legacy one: **display every shader/material/particle for at least one frame during loading**. Issue #76241 measured 60→23 fps the first time Control nodes were drawn in Compatibility. Watch `Performance.PIPELINE_COMPILATIONS_CANVAS`.
9. **Do not ship `OS.low_processor_usage_mode = true` without testing animation on device.** It *"only redraws the screen if necessary"* **[V-4.7]** — exactly what an idle game wants — but Godot issue #19304 reported it breaking animations, Tweens and CheckButtons on Android (raised on 3.x, milestoned 3.5). Verify on 4.7 on your own device before enabling. Prefer the safer pair: `Engine.max_fps = 30` (or 60) plus strict `queue_redraw()` discipline, and only enable `low_processor_usage_mode` on a genuinely static screen.
10. **`application/run/max_fps` is read only at project startup** — change it at runtime via `Engine.max_fps` **[V-4.7]**.
11. **V-Sync overrides your FPS cap.** *"When vsync is enabled or set to adaptive, the monitor's refresh rate takes precedence and caps the max FPS setting"* **[V-4.7 Engine.max_fps]**. `DisplayServer.VSyncMode` constant names are **[UNVERIFIED]** here — check autocomplete before using them; the project setting is `display/window/vsync/vsync_mode`.
12. **`MEMORY_STATIC`, `MEMORY_STATIC_MAX`, `OBJECT_ORPHAN_NODE_COUNT`, `OS.get_static_memory_usage()` and `Node.print_orphan_nodes()` are debug-only** **[V-4.7]**. Guard with `OS.is_debug_build()`, and never build a release-mode budget check on them. `OS.get_memory_info()` works in release (entries may be `-1`).
13. **The classic Godot 4 2D leak: a helper class that `extends Node` but is never added to the tree.** It becomes an orphan and is never freed; `extends RefCounted` instead. Detect via `Performance.OBJECT_ORPHAN_NODE_COUNT` or `Node.print_orphan_nodes()`.
14. **`GPUParticles2D.emit_particle()` does not exist functionally on Compatibility** — *"only supported on the Forward+ and Mobile rendering methods, not Compatibility"* **[V-4.7]**. Also: `amount_ratio` saves nothing (resources allocated for full `amount`), and large `preprocess` *"can even lead to a GPU crash"* **[V-4.7]**.
15. **`Input.vibrate_handheld` without the `VIBRATE` export permission crashed on Android 4.4-stable** (issue #103496, fixed by PR #107385). Set the permission; wrap haptics in a user toggle.
16. **`AudioStreamGenerator` from GDScript is explicitly discouraged** — the class docs recommend C#/GDExtension, or 11025/22050 Hz if you must use GDScript **[V-4.7]**. Bake `AudioStreamWAV` at load instead.
17. **2D MSAA and FXAA do not exist in gl_compatibility** **[V-DOC renderers.rst, tracker #66458]**. Build your look from crisp geometry; per-primitive `antialiased: true` turns rects into unbatchable polygons, so use it sparingly.
18. **Set `display/window/stretch/mode = canvas_items` and `aspect = expand`, base 720×1280 portrait** for phones **[V-DOC multiple_resolutions.rst]**.
19. **Screen-reading shaders cost a full-screen back-buffer copy.** Fine on desktop, a bandwidth tax on low-end mobile. Also *"Screen Reading Textures ignore 'nearest' filtering flag in compatibility render"* (tracker #66458, unresolved).
20. **Never trust a third-party performance number as a Godot guarantee.** The "~100 draw calls / ~300 MB RAM" figures on mobile-optimisation blogs are not from Godot or Google. Baseline on your own worst device using §2e.

---

## Sources

- Godot 4.7 class XML (`godotengine/godot`, branch `4.7`): [Performance.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/Performance.xml), [Viewport.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/Viewport.xml), [RenderingServer.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/RenderingServer.xml), [Input.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/Input.xml), [OS.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/OS.xml), [Engine.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/Engine.xml), [CanvasItem.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/CanvasItem.xml), [CanvasItemMaterial.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/CanvasItemMaterial.xml), [Tween.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/Tween.xml), [Node.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/Node.xml), [ProjectSettings.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/ProjectSettings.xml), [GPUParticles2D.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/GPUParticles2D.xml), [CPUParticles2D.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/CPUParticles2D.xml), [AudioStreamGenerator.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/AudioStreamGenerator.xml), [AudioStreamGeneratorPlayback.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/AudioStreamGeneratorPlayback.xml), [AudioStreamWAV.xml](https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/AudioStreamWAV.xml)
- Engine source: [drivers/gles3/rasterizer_canvas_gles3.cpp](https://raw.githubusercontent.com/godotengine/godot/master/drivers/gles3/rasterizer_canvas_gles3.cpp)
- Godot docs (source .rst / pages): [Reducing stutter from shader (pipeline) compilations](https://docs.godotengine.org/en/latest/tutorials/performance/pipeline_compilations.html), [Screen-reading shaders](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/shaders/screen-reading_shaders.rst), [Overview of renderers](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/rendering/renderers.rst), [Multiple resolutions](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/rendering/multiple_resolutions.rst), [Optimization using servers](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/performance/using_servers.rst)
- Godot issues / PRs: [#90133 draw-call monitor counts UI/letters](https://github.com/godotengine/godot/issues/90133), [#76241 OpenGL 2D shader-compilation stutter](https://github.com/godotengine/godot/issues/76241), [#66458 Compatibility renderer tracker](https://github.com/godotengine/godot/issues/66458), [#66455 / PR #87360 OpenGL glow](https://github.com/godotengine/godot/pull/87360), [#103496 vibrate_handheld crash without VIBRATE](https://github.com/godotengine/godot/issues/103496), [#19304 low_processor_usage_mode breaks anims on Android](https://github.com/godotengine/godot/issues/19304), [#74060 draw-call monitor 0 in 2D](https://github.com/godotengine/godot/issues/74060), [proposal #1427 detect vibration support](https://github.com/godotengine/godot-proposals/issues/1427), [proposal #9582 vibrate amplitude](https://github.com/godotengine/godot-proposals/issues/9582)
- Community measurements: [Trying to improve performance of 2D game on Android (121 tiles, 12ms→3ms, 4.4.1 Compatibility)](https://forum.godotengine.org/t/trying-to-improve-performance-of-2d-game-on-android/108481), [AudioStreamGenerator user notes (fade ≥100 samples)](https://github.com/godotengine/godot-docs-user-notes/discussions/268), [orphan nodes in Godot](https://simondalvai.org/blog/godot-orphan-nodes/)
- Third-party, **not authoritative**, cited only where flagged: [Optimizing Godot for Mobile — A Field Guide](https://slicker.me/godot/mobile-optimization.html)
