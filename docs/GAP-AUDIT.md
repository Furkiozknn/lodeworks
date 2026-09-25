# Lodeworks gap audit and backlog

25 September 2026, on `visual/landscape-iso` at `e110295` (70 commits ahead
of `main`). This document answers the question "of everything asked for
Lodeworks so far, what is really done, what is half done, and what is
missing", checked against the code, the tests and the tools rather than
against any earlier prompt or report. It also sets the order of work.

Method: the docs (AUDIT, PLAY, ART, CI, RELEASE, DEVICE-TEST, BALANCE,
README) were read, and every feature was looked up in the code with its
test. The live numbers come from the tools named beside them. A read-only
audit pass and a sourced Clash of Clans study
([research/clash-ux.md](research/clash-ux.md)) fed into it. Nothing here
has run on a real phone. Every figure a phone decides is marked UNKNOWN.

Status words: DONE, PARTIAL, MISSING, UNKNOWN (needs a real device or
store), OBSOLETE. Priority: P0 hurts the core experience, P1 soon, P2
mid-term, P3 a future system, P4 not needed now.

---

## 1. Verified DONE (no action; do not rebuild)

| feature | evidence |
|---|---|
| Dark Factory Core at start, its 40-credit reserve | `Sim.power_core` (sim.gd), `test_a_new_game_can_start_the_core_pays_for_the_first_two_machines` |
| Starting yard, growing by stratum | `BuildArea.RINGS` (build_area.gd), `test_a_new_shaft_builds_in_a_small_yard_round_the_core` |
| Core grows with its yard, 8 levels | `IsoView.level_at`, `test_the_core_grows_with_its_yard_all_the_way_down` |
| Cells behind the Core usable | `IsoView.cells_behind_core`, `test_the_cells_behind_the_core_are_yard_cells_the_player_can_use` |
| Factory Core card | `main._show_core`, `FactoryReport`, smoke `core card` |
| Machine animations and work effects | `iso_view._draw_work` |
| Research as a 3-column grid of picture cards | `main._show_research`, smoke `research` |
| Collapse card, visual, with what the Cores open | `main._show_collapse`, `_cores_open`, smoke `collapse` |
| Codex: running mini boards, groups, short words | `codex.gd`, `test_codex_pages_are_short` |
| Machine groups | `MachineDB.GROUPS` |
| Research count on its key | `main._research_ready`, smoke `research badge` |
| What lies below | `main._show_below`, smoke `below` |
| Descend plunge and band banner | `iso_view` dive, `main._band_banner` |
| Problem key and its escalation | `StatusBadges.alarm_*`, DEVICE-TEST `alarm` |
| Heat system and heat key | `Grid` heat, `StatusBadges.heat_state` |
| Zoom key off by default | Settings, Accessibility |
| Settings in five groups | `main._show_settings`, smoke `settings: 7 switches` |
| Larger text | `Palette.text_px`, layout check pass with it on |
| Landscape isometric camera: pan, fling, pinch, wheel, bounds | `iso_camera.gd`, `test_iso.gd` |
| Touch selection by the picture | `IsoArt.pick` |
| Pipes, flow beads, work particles | `Iso.links`, `iso_view` |
| Props round the Core, in clusters | `tools/props_layout.py`, `test_the_props_ring_the_yard_in_clusters_and_leave_ground_bare` |
| Resource-node visuals and card | `ResourceNodes`, `main._on_node_tapped` (no economy: see A2) |
| Green "it works here" tiles | `Simulation.links_if_placed`, `test_a_placement_mark_is_what_the_machine_would_really_be_connected_to` |
| Stratum arrows on the tray | `Strata.effect_on`, `test_a_tray_arrow_is_what_the_simulation_does_to_the_machine` |
| Shop | `shop.gd` |
| Removing a machine (bin key and long press) | `main._on_cell_long_pressed` |
| Tutorial and first minute | `tutorial.gd` 8 steps, pointer, `LODEWORKS_CAPTURE=first` |
| Machine locks (Codex locked cards, "next:" on Descend) | `codex._machine_card`, `main._show_next_unlock` |
| 44 x 44 board | `Grid.W/H` |
| **English and Turkish** (new today) | `Loc`, `locale/tr.po` 369/369, `test_localization.gd`, `tools/loc_check.tscn` |
| Tests, CI, Android debug build, release config, asset budget, monetization plumbing | 296 tests; `ci` and `android` green; `test_release_config.gd`; `asset_budget.py` 6.76 of 40 MB |

---

## 2. What is not done

### A — MISSING

| # | item | evidence | what is missing | priority |
|---|---|---|---|---|
| A1 | **Blueprint screen** | `Sim.blueprints` is saved but never written; Drafting Table hidden (`HIDDEN_RESEARCH`); the Licence's blueprint grant hidden | a format, save, list, preview, apply; or removal of the slots | decision P1, build P2 |
| A2 | **Resource-node economy** | `ResourceNodes` holds words only; nodes vanish when the yard reaches them | any production effect | P3, owner |
| A3 | **Analytics sink** | `Analytics.endpoint = ""`: events never leave the device | a sink decision; then `first_machine`, `language_change`, `heat_problem`... | P1 before closed testing |
| A4 | **Landscape store screenshots, tablet shots, preview video** | `store/screenshots*` are 1080x1920 portrait from 23 Sep; `tools/store-assets.sh` still captures portrait | re-shoot at 1920x1080 from the `ui`/`field` captures. **FIXED**: CI renders all store assets at the exact sizes and checks them, the listing is rewritten, a Turkish listing added (B-4) | P1, release |
| A5 | ~~Store listing text~~ **FIXED** (B-4) | `store/listing.md` described the old small-grid game; English only | rewritten for the landscape game; a Turkish listing; every field's length checked | done |
| A6 | **Release items needing a person** | privacy-policy contact is a placeholder; no keystore, no signed AAB; versionCode fixed at 1 | owner actions; a versionCode bump step | P1 |
| A7 | ~~Some sounds~~ **FIXED** | `Juice.income()` was never played; no sound for Descend ready or a new band | the credits chime now plays once when the quota is met and Descend opens. A new band arrives with the Descend sound already playing, so a second cue there would be noise; none added | done |
| A8 | Right-to-left layout | `Loc.is_rtl` exists; nothing mirrors | layout mirroring before Arabic | P4 |

### B — PARTIAL

| # | item | state | missing | priority |
|---|---|---|---|---|
| B1 | **Depth bands** | the four bands tint one painting, one tile sheet and one prop sheet | per-band ground, props, particles and light (planned in AUDIT, about six image generations) | P2 |
| B2 | Reading the production chain | pipes hide behind nearer machines at default zoom; beads and the selected machine's links carry it | a flow overlay drawing every link | P2 |
| B3 | Machine variety | 12 single-frame sprites; no per-machine level | per-part motion (N5) | P3 |
| B4 | Larger text coverage | labels, keys and board numbers scale (today); symbol keys (?, ✕, +) keep their size on purpose | nothing further planned | done enough |
| B5 | Reduce motion | covers pulses, swells, halo, flicker, plunge | **FIXED** (B-8): camera glides cut, key punches, bobbing marks, the Foreman's bob and the hot flicker now still; the yard wave, the banner and the number roll are fades and counts, not movement, and stay | P2 |
| B6 | Colour-blind reading | badges, arrows and the heat key have shapes | no colour-vision simulation check | P3 |
| B7 | Touch targets | HUD keys 96 units, enforced; tray "?" backed by hold-to-open | 43-44 dp on a 720p phone, reported only | P3 |
| B8 | **Tile size at deep strata** | default zoom floor 0.6, about 19-22 dp; green tiles and picture picking help | a closer look while placing, if the device run shows mis-taps | P1 (P0 if the device run confirms) |
| B9 | Save architecture | one flat save; `"v": 1` written, never read; migration only by defaults | a `_migrate(d)` step keyed on `v`; player and factory split later | P2 |
| B10 | **Collapse economy measurement** | `journey_lab` plays one run and projects the rest | a lab that plays collapse after collapse with upgrades carried over | P1 (the payout decision waits on it) |
| B11 | **Welcome back panel** | credits, and now the research the Labs banked (it was added but never shown) | "what now": **FIXED** with the Worklist (B-1): its first line, as a row to tap | P1 |

### C — EXISTS BUT SHOULD IMPROVE

| # | item | state | fix | priority |
|---|---|---|---|---|
| C1 | ~~Analytics opt-out does not persist~~ **FIXED** | the choice is kept in `user://analytics_off`, read before the first event of every launch (`Analytics._load_consent`); test and smoke switch | — | done |
| C2 | ~~Offline rate can be saved as zero~~ **FIXED** | a Descend keeps the last measured rate for offline (`Sim.offline_rate`); a collapse still banks zero for its empty board; `test_a_descend_does_not_throw_away_the_offline_rate` | — | done |
| C3 | ~~Docs that overstate~~ **FIXED** | README advertised a "reroll a stratum" ad that ships unreachable, "one IAP" where there are two, and blueprints that "save and load"; RELEASE said the tree "sells slots"; the data-safety form declared analytics collection that never happens | corrected; the form now follows `Analytics.endpoint` (empty: "not collected", with the note to re-run when one is set). Left for the owner: the privacy policy still describes statistics as if they may be sent, which is right only once an endpoint exists | done |
| C4 | CI | `ci` runs on push to `main` only; this branch runs by hand | run on this branch's pushes too | P2 |
| C5 | Settings audio switches | Sounds and Volume not in the smoke test | add them | P3 |

### D — UNKNOWN (a real phone or store)

- **D1 device run**: frame time, memory, battery, heat, touch, text at
  arm's length, haptics, speaker, cutouts. Desktop numbers only (idle p50
  11.06 ms, 177-193 draw calls). DEVICE-TEST.md is not yet run. P0 gate.
- **D2 live monetization**: no AdMob unit ids, no Play products, no
  purchase or ad ever made, consent flow unverified.
- **D3 release build**: size, 16 KB alignment, Billing Library version on
  the produced bundle.
- **D4 Play Console**: account, trader details, 12 testers x 14 days,
  content rating, data safety, trademark.
- **D5 launcher icon**: the adaptive icon background is empty.
- **D6 premium feel**: world saturation 0.43 against the reference's 0.57.

### E — FUTURE

- **E1 the long game.** Stratum 20 comes in about 12 hours. After depth 10
  no machine is new. The permanent tree (372 Cores) is done after about
  6 collapses, roughly 9 hours of play. Past that nothing is designed. The
  deferred C1-C4 ideas in AUDIT §2 (endless tier, challenge runs, stratum
  records, novelty past 10) each have a stated trigger. See §5 for a
  proposed map.
- **E2 goals over time**: achievements, events, cloud save. None exist in
  code (§4 on the refusals).
- **E3 more than one factory**: AUDIT "Toward more than one factory".
- **E4 social systems**: research/clash-ux.md §10.2.8-10.2.12. All need a
  server except Factory Tours by share code.

### F — OBSOLETE / can be cancelled

- F1 portrait store assets (replaced by A4).
- F2 `slice/`, a 3D diorama experiment. Nothing references it, and it is
  excluded from export. Move it to `_eski/` or delete it with the owner's
  word.
- F3 orphan `tools/_probe2.gd.uid` and `tools/_statdump.gd.uid`.
- F4 dead code: `Palette.shaft`, `BAND_ROCK`, `BAND_FLECK` and
  `rock_deep` (used by one test only); `CELL_BLOCKED` and `ROCK_DEEP`;
  `Strata.configure`; unused `_collapses` parameters; the unreachable
  `P_REROLL_STRATUM` and `P_EXTRA_BLUEPRINT` placements.
- F5 duplicate icon files in `store/` and `store/brand/`.
- F6 stale docs: ART §2 zoom range, ART §3 slab counts, Core levels 1-5,
  RELEASE §6-§8 CI and screenshots, BALANCE's 7x10 tables.

---

## 3. The first half hour, measured, and what it answers

`tools/journey_lab.gd` plays a bot. A bot is not a person: it never
hesitates and never misreads. The times are a lower bound.

| window | what happens (measured) | "what now?" answered by | in pictures? |
|---|---|---|---|
| 0-30 s | the dark Core; tap brings it online (40 credits); Drill + Vault earn their first credit at 2.1 s | the Foreman's line, the pulsing Core, the arrow | yes |
| 2 min | 3 to 14 machines; move, crusher and heat steps | the tutorial's outlines and arrow | yes |
| 5 min | first descent at 178 s (Smelter, Boiler), stratum 2 at 335 s | the Descend key's % and "next" pictures; what lies below | mostly |
| 15 min | stratum 5-6, the Lab opens at 942 s | tray arrows, the Core card's next growth | partly: nothing ranks what to do next |
| 30 min | stratum 9, 120 machines, a collapse would pay 22 Cores; Research still 0 | the Collapse card (loses, keeps, what the Cores open) | yes, but nothing says **when** a collapse is worth it |
| first run | 1 h 30 to stratum 12, 46 Cores | — | — |

The gap is the same from minute 15 on. The game shows every system well
once the player opens it. After the tutorial, though, nothing ranks what
to do next. Clash of Clans' strongest tool is a ranked list one tap away
(clash-ux.md §9.3, §10.2.2). Lodeworks has the pieces: the problem key,
the research count, the quota, the tray's affordability, and the unbuilt
unlocks. It does not have the list.

---

## 4. Recorded decisions the new requests touch

These were decided and written down earlier. Some of the new requests
reverse them, so each needs the owner, not the agent:

| topic | recorded decision | where | what the new requests ask |
|---|---|---|---|
| daily / weekly challenges | refused: "a retention mechanic that punishes absence" | AUDIT §2 D2 | evaluate daily/weekly objectives |
| multiplayer, leaderboards, social | refused: account, server, privacy surface | AUDIT §2 D3 | design visits, trade, co-op, challenges |
| more currencies | refused as the content treadmill | AUDIT §2 D1 | new resources and factory types |
| collapse payout | waiting on the owner; runs got 1.8x longer for the same Cores | AUDIT "What is still UNKNOWN" | measure before changing (B10) |
| blueprints | waiting on the owner | AUDIT | decide: build a slice or remove the slots |

Proposal:
- Keep D2 in spirit. Use accumulation instead of streaks (clash-ux.md
  §10.2.6: a Ledger whose marks never expire), not daily chores.
- Lift D3 only for designs that need no server: Factory Tours by share
  code, and the same weekly rock for everyone (Rock of the Week).

---

## 5. The long game: a proposed map (not built)

| hours | today | proposed (each needs the owner) |
|---|---|---|
| 0-1 | strata 0-11, all 12 machines by depth 10 | a ranked Worklist (B-1 below) |
| 1-10 | collapses 1-6, the permanent tree | the Ledger: deterministic marks, cosmetic rewards |
| 10-50 | nothing new; deeper strata repeat modifier pairs | challenge runs (AUDIT C2), Rock of the Week, per-band worlds (B1) |
| 50-100 | nothing | a second shaft with its own rules (clash-ux.md §10.2.13); Output Trials on a shared seed (needs a server) |

---

## 6. Backlog, in order

Rule: bugs first (data, privacy, lost income), then what answers "what
now?", then measurement for the waiting decisions, then the release, then
the world.

**B-0 — Three audit bugs (P1).**
- WHY: a privacy switch that forgets; research earned offline but never
  shown ("every term is shown in the UI", save_service.gd); offline
  income lost after a Descend.
- CURRENT: C1, B11 (research line), C2.
- TARGET:
  - the opt-out survives a restart;
  - Welcome back shows credits and research;
  - offline pays at the last measured rate.
- TEST: a unit test each; a smoke check for the switch; a capture of
  the panel.
- RISK: none for performance.

**B-1 — The Worklist: "what now?", one tap (P1).**
- WHY: §3. It is the strongest what-next tool in the reference, and it
  is the gap after minute 15.
- CURRENT: the parts exist separately: the problem key, the research
  count, quota %, tray affordability, unlocked-but-unbuilt machines.
- TARGET: one key opens 3-5 ranked lines, in a deterministic order:
  - machines in trouble;
  - quota ready: Descend;
  - research ready;
  - an unlocked machine never built;
  - the best affordable machine by the green-tile count.
  Each line shows a picture and a short verb, and a tap goes there (the
  camera glides, the key opens, the machine arms).
- DEPENDENCIES: none; it only points, and costs no economy change.
- TEST: the order on fixed boards (unit); every line's action in the
  smoke test; Turkish and pseudo-language checks.
- VISUAL: a capture at 18:9 and 16:9.
- RISK: none; it is built on request.
- STATUS: **DONE** (`scripts/sim/worklist.gd`, the "What now?" key at
  the top of the right-hand column, a row in Welcome back). Seven kinds
  of line in a fixed order, at most five: trouble, the way down,
  research, a collapse that opens research, a first machine, the
  furthest step that would work on some empty tile now (by
  `links_if_placed`, the same rule as the green tiles), and otherwise
  the quota. 6 unit tests, a smoke check that the rows match the list
  and a tap works, a Turkish and pseudo-language screen. The camera does
  not glide to a green tile: arming the machine lights the tiles where
  it would work, which is the same answer without a second camera path.
  The key appears when the Foreman's first chapter ends (or after a
  collapse); before that the Foreman is the worklist.

**B-2 — A collapse lab (P1, measurement).**
- WHY: the payout decision (§4) needs real multi-collapse numbers, not
  a projection.
- TARGET: `journey_lab` plays collapse after collapse with the Cores
  spent. It reports minutes per run, Cores per hour, and when the tree
  is done.
- No economy change; the numbers go to AUDIT for the owner.

**B-3 — CI on this branch (P2).** `ci.yml` also on pushes to
`visual/**`.

**B-4 — Landscape store screenshots and listing (P1, release prep).**
- 1920x1080 phone and 16:9 tablet shots from the existing captures.
- The listing rewritten for the landscape game, in English and Turkish.
- Nothing is published.
- STATUS: **DONE**. `tools/store-assets.sh` renders at 1920x1080 and
  2560x1440; CI runs it (a desktop window is clamped to its screen, so a
  local run cannot make the exact sizes) and fails on any spec miss. The
  check now also measures every listing field against its limit (it said
  it did; it did not). The description names the Core, the yard, the
  "What now?" key and the languages; the Turkish listing uses the game's
  own Turkish words. Still a person's: the YouTube upload of the preview,
  and whether to list in Turkish at all.

**B-5 — The blueprint decision (P1 decision memo).**
- Research: layouts shared by code are valuable (Factory Tours).
- Proposal: a slice that saves the yard's layout and applies it with the
  green-tile preview and its cost. Or remove the slots.
- The owner chooses.

**B-6 — Save format v2 groundwork (P2).** `_migrate` keyed on `v`, with
a round-trip test; no split yet.
- STATUS: **PARTIAL, the part that protects data is DONE.** A save whose
  `v` is higher than `Save.VERSION` (written by a newer build, then opened
  by an older one after a rollback) is no longer loaded and then written
  back without the fields the older build does not know: it is copied,
  whole, to `user://save.newer.json` and the game starts fresh. The round
  trip was already tested (`test_a_save_round_trips`). No `_migrate` table
  yet: there is no v2 to migrate to, and an empty table is scaffolding.

**B-7 — Per-band worlds (P2, art).**
- One tile sheet and one prop sheet each for the Workings, the Deep and
  the Abyss (AUDIT "Planned: a different look per depth").
- Before the art: a free interim of per-band particle colours and props
  mix.

**B-8 — Reduce-motion coverage and a flow overlay (P2).**
- STATUS: the coverage is **DONE** (see B5 in the table above): one
  switch now stills every moving thing that is not information, the
  smoke test checks it reaches the view, the camera and Juice, and a unit
  test checks the camera cuts. The flow overlay is not built.

**B-9 — A resource-node slice (P3, owner).** For example, a Drill on or
beside an ore vein digs more; measured with the labs before it ships.

---

## 7. Take, adapt, leave (from the Clash study)

| take | adapt | leave |
|---|---|---|
| the ready action is always visible | Town Hall as the gate → the Factory Core card's next growth (done) | upgrade timers and gem skips |
| teach at first contact | Builder suggestions → the Worklist, with no builders | builders sold for money |
| a warning, not a wall | achievements → the Ledger: never expires, cosmetic | a paid season pass, random chests |
| celebrate real milestones | events → the same seeded rock for everyone, no daily obligation | login calendars that need consecutive days |
| accumulate instead of streak | clan projects → a cooperative plant (server, later) | raiding, theft, shields |
| — | clan wars → production contests on a shared seed, re-run by the deterministic simulation | combat |
