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

Unchanged from the previous round, and not improved by anything here:

- No APK or AAB has ever been built. No Android SDK, Gradle repository or
  Godot export template is reachable from the build environment.
- CI has never run. The repository has never been pushed.
- Nothing has run on a real Android device. Every frame-time, memory, battery,
  input-latency and touch figure is UNKNOWN.
- No purchase has ever been made in a real store, and no ad has ever been
  served.

Everything in this document was measured in the headless simulation, which is
the same code the game runs, on hardware that is not a phone.
