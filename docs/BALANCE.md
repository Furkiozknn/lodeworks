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
