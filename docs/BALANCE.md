# What the board is actually worth

Measured on 23 September 2026 with `tools/layout_lab.gd` and
`tools/layout_search.gd`, at stratum 9 with a mid-game research set, over a
25-second warm-up and a 40-second sample.

Both tools are in the repository because the finding below could not have been
reached by reading the numbers. It came from adding a per-tile duty-cycle
readout to the simulation and then noticing that half the showcase board was
sitting at zero.

---

## The reference layout was half dead

The board this project used in its screenshots, in its self test and as the
end-to-end fixture in `tests/test_progression.gd` had **thirteen of its
twenty-eight machines permanently output-blocked at 0% duty cycle**.

It passed every test. The tests asked whether the board produced credits and
research; it did — on the half of itself that was running. Nothing was asking
"is this board any good", so nothing noticed.

The cause was structural rather than arithmetic. Two Assemblers fed two Labs
and nothing else. A Lab consumes 0.6 components a second; two amplified
Assemblers can make several times that. The surplus had nowhere to go, the
Assemblers' output buffers filled, and back-pressure propagated all the way up
to the Drills. Every machine in the top two rows was blocked.

## What replaced it

```
        d d d d d d d      seven drills
        c c c c c c c      seven crushers
        s s a p s s s      smelters, one assembler, one press
        v v l v v v v      vaults, one lab
```

**Superseded in the following round.** Once one-for-one recipes made a long
chain feedable, the reference board became a tapered full chain with a shallow
deck under it — 601.7 credits/s and 0.97 research/s from 61 machines with 12
dead, the highest working share (66%) of any board measured:

```
        d d d d d d d
        c c c c c c c
        v s s s s s v      vaults on the shoulders, so the edges never back up
        v p p p p p v
        v v a a a v v
        . v v l v v .
        d d d d d d d      a second, shallower deck under it
        c c c c c c c
        v v v v v v v
```

| layout | credits/s | research/s | machines | dead | working |
|---|---|---|---|---|---|
| **deck_a (adopted)** | **445.9** | **0.97** | 28 | **3** | 61% |
| deck_b | 571.7 | 0.00 | 35 | 12 | 37% |
| three_decks | 477.8 | 0.00 | 70 | 26 | 56% |
| wide_shallow | 388.6 | 0.00 | 31 | 7 | 52% |
| gravel_only | 248.4 | 0.00 | 39 | 6 | 72% |
| component_farm | 136.2 | 0.00 | 48 | 27 | 35% |
| **baseline (replaced)** | **48.1** | 2.56 | 28 | 12 | 50% |

Nine times the income from the same number of machines, with three dead tiles
instead of twelve, and it still produces research. `deck_b` earns more and was
not chosen: twelve dead tiles and no research make it a worse thing to show
someone who is trying to learn the game.

`tests/test_performance.gd::test_the_reference_layout_is_not_half_dead` now
fails if more than a third of the reference board is idle, so this cannot
quietly come back.

## The finding that WAS fixed, in the round after

**Hand-built clean chains lost badly to dense shallow boards, and the deep end
of the production chain did not pay for the space it needed.** Measured, in
the previous round, and left unfixed on purpose because every available fix
invalidated the playability results the balance tests encode.

It is fixed now, and the fix is a rule rather than a number.

### Why it was broken

A machine is fed only by the four cells it touches, and one of those is
usually its own output, leaving three. Under the original recipes every
refining step consumed **two** of the thing below it, so the supply tree
branched by two at every level while the space to attach it branched by
three. A chain deeper than about three steps could not be fed at all, no
matter how valuable its product was. Nothing was wrong with the values; the
geometry was wrong.

### What was tried

`tools/econ_lab.gd` runs every model in `MachineDB.MODELS` against seven board
archetypes at three depths. All of them are still in the source so the
comparison can be re-run.

| model | rule change | best deep board vs best shallow |
|---|---|---|
| `base` | the original | **0.00x** — the deep archetypes produced nothing at all |
| `hybrid` | one input above the Press only | **0.00x** — the Assembler still needed two, and still starved |
| `linear` | one input from the Smelter up, values flattened | 1.06x |
| `linear_hot` | the same, plus hot deep machines with tight tolerance | 0.68x — over-corrected, depth back below shallow |
| **`linear_warm` (shipped)** | one input from the Smelter up, deep machines run warm | **0.99x** |

### What shipped

`linear_warm`. From the Smelter upwards each step takes one of the thing below
it, so a single adjacent supplier is enough; the value ladder is flattened to
match, because with one-for-one conversions the old ladder would have made a
five-tile chain worth ninety-five times a Drill; and the Press and Assembler
run warm, so a long chain has to be cooled and the cooling costs tiles.

Measured at the three depths, with the archetypes in `econ_lab.gd`:

| depth | best board | what wins there |
|---|---|---|
| 3 | deep_columns, 328/s | a full chain, narrowly over shallow's 324/s |
| 9 | deep_double, 592/s | a full chain, narrowly over shallow's 588/s |
| 16 | raw, 266/s | Cramped takes thirty of the seventy tiles; no long chain fits |

Near-parity on credits at every depth, and a **monopoly on Research**: the
deep archetypes produce 1.88-2.00 research per second and the shallow ones
produce exactly none, because Research comes from a Lab and a Lab only eats
Components. So the choice is not "which board earns more" but "do I want
credits now or permanent upgrades", and the stratum modifiers decide which
board is even buildable.

That is the design target this whole exercise was for, and
`tests/test_gameplay.gd` holds all three halves of it: a long chain must be
within reach of a shallow board, it must not make the shallow board pointless,
and no single board shape may win at every depth.

## Two mechanics bugs found on the way

Both were found by instruments built for something else, which is the argument
for building them.

**The duty cycle was measuring intent, not work.** The first version asked
"did this machine finish something this tick", and a machine running at 0.9
cycles a second finishes something on one tick in eleven even when perfectly
fed — so a machine merely mid-cycle counted as 100% working. It reported 99%
for a Smelter completing barely half the cycles its supply allowed. Every
dead-tile figure in the balance tools rested on that number. It now measures
completed cycles against the cycles the machine's current speed would allow,
over a six-second window, blended with the previous one.

**A producer gave everything to whichever consumer was visited first.**
Material moved by a pull, and consumers pulled in cell-dictionary order, so
one Crusher feeding three identical Smelters produced duty cycles of 96%, 73%
and 0%. Three tiles, identically connected, doing completely different amounts
of work, with nothing on screen that could explain it — because there was
nothing to explain, it was dictionary order. Transfer is now a push: a
producer deals its output out one unit at a time, round robin, starting one
place further along on every tick. The totals are identical. What changed is
that the board became something a player can reason about — and across the
archetype table, dead tiles on shallow boards fell from twenty-one to zero.

## A caveat on the search tool

`layout_search.gd` is a plain hill-climber with random restarts. One of its
four restarts, seeded from an empty board, never improved at all — single-cell
mutations almost never help when there is no chain to extend. Its results are
a lower bound on what is achievable, not an optimum, and the spread figure it
prints is meaningless when one restart scores zero. Both are noted here rather
than in a commit message because the number it prints will be quoted later.

---

# The retention audit, 23 September 2026

Measured with `tools/journey_lab.gd` (the player's first ten seconds, first
thirty minutes and long game) and `tools/strategy_lab.gd` (does the modifier
table actually change which board is correct). Everything below is a number
the tools print, not an opinion about the design.

## The first ten minutes are the strong part

| moment | measured |
|---|---|
| a lone Drill | **earns nothing, ever** — it has nowhere to sell, so the second machine is not a suggestion |
| Drill + Vault | first credit at **2.1 s** |
| machine three | affordable **17 s** later |
| first descent | **179 s**, unlocking Smelter and Boiler |
| first ten minutes | **five descents**, one new machine at each |
| thirty minutes | stratum 5, 70 machines, first collapse available |

Nothing here needed changing. The opening teaches adjacency by making it the
only way anything happens at all.

## Four things the audit found broken

### 1. Two modifiers did nothing

`Strata.describe()` computed twelve modifier effects; `Sim` applied ten.

- **Brittle Rock** — "Drills run 35% faster, but everything downstream runs
  15% slower". `source_speed` was read by nobody, so the card described a
  trade-off and delivered a pure penalty. It scored below a clean stratum in
  **all 32** board-by-condition cells.
- **Resonant Strata** — "Amplifiers are twice as strong". `amplify` was read
  by nobody. A board measured under Resonant produced numbers identical to a
  clean stratum **to the last credit**, including a board built entirely
  around Amplifiers.

Both were copy-paste omissions across nine files that each configured a
Simulation from a stratum by hand. `Strata.apply()` is now the only way to do
it, and `tests/test_release_config.gd` fails the build if anything sets those
fields directly again.

### 2. Four of the twelve machines were decoration

The same eight-row chain with its fourteen spare tiles spent seven ways:

| spare tiles spent on | credits/s at depth 14 |
|---|---|
| nothing | 1077 |
| Boilers | 1069 |
| Coolant Cells | 1069 |
| Duplicators | 1077 |
| Condensers | 1072 |
| **more chain** | **1167** |

Within 1% of leaving the tiles empty. The cause was geometric, not numeric: on
a four-neighbour grid with no belts **every chain tile is the sole outlet of
the tile upstream of it**, so a support machine woven into a chain starves it
(an Amplifier row inside the Crusher row scored 473 against 652 for not
building it) and a support machine in a spare row is next to Vaults and serves
nothing. The two requirements were mutually exclusive.

Two rules fixed it, both stated on the tile before it is bought:

- **A support machine bridges rather than blocks.** Material passes straight
  through it to the machine on the far side. It costs a tile of production,
  never a connection. One hop only.
- **A support machine is worth what it touches.** Its effect scales by
  `1 + 0.5 x (n - 1)` for `n` working neighbours, and stacked supports pay 1,
  0.6, 0.36, 0.22 of their value so no single layout is correct everywhere —
  the failure Factorio rebuilt its beacon maths to avoid (FFF #409).

The result, same tool, same conditions:

| | before | after |
|---|---|---|
| distinct winning boards across 12 conditions | 2 | **3** |
| Amplifier board ever wins | never | **6 of 12** at both depths |
| deep chain ever wins | 4 of 12 | **5 of 12** |
| Resonant changes the answer | no | **+44%** for the Amplifier board |
| Resonant + Thermal Vent | no effect | **+69%** for the Amplifier board |

### 3. The prestige layer had no sink

One 77-minute run to stratum 20 paid **774 Cores against a permanent tree that
cost 88 in total** — finished nearly nine times over by the first collapse.
Every collapse after that was a strict loss, because a collapse also takes the
Research. That is the Realm Grinder complaint exactly: *"at each new prestige
tier you generally don't have more than one new goal to chase."*

Credits now enter the Core formula logarithmically rather than as a square
root, and the depth exponent came down from 1.25 to 1.1. Core costs rise 1.2
per level rather than 0.6, on bases tripled.

| | before | after |
|---|---|---|
| whole permanent tree | 88 Cores | **372 Cores** |
| one stratum-20 run | 774 Cores | **85 Cores** |
| first collapse at 30 minutes | 25 Cores | **7 Cores** |
| collapses to finish the tree | under 1 | **4 at the ceiling**, many more in practice |

### 4. Novelty ends at stratum 10

The last new machine unlocks at depth 10. Past it a stratum is a quota, a
richness number and a modifier pair — and over 60 strata there are 41 distinct
modifier sets with **18 repeats**. This is reported rather than fixed: adding
machines to cover it is the content treadmill, and the honest answer is that
the game's depth after stratum 10 now comes from the three-way board choice
above rather than from new tiles.

## What did not change

Simulation cost went from 1.197 to **1.341 ms per tick** against a 3.0 ms
budget. Canvas draw calls are unchanged at 247. The opening, the tutorial, the
economy model and the monetization are untouched.
