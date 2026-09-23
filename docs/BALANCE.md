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

## The finding that is not fixed

**Hand-built clean chains lose badly to dense mixed boards, and the deep end of
the production chain does not pay for the space it needs.**

`tools/layout_search.gd` hill-climbs from four different starting points. Its
best result was **1,136 credits/s** from a board that looks like machine soup —
two and a half times the best hand-designed layout, and twenty-three times the
old reference board. Meanwhile every carefully built long chain
(`component_farm`, `fed_ladder`, `amplified`) placed near the bottom of the
table.

The arithmetic explains it. Each refining step multiplies value by roughly 1.2
to 1.5 per cycle after the rate penalty, but it costs a tile, and — because
machines are fed only by the four cells they touch — a long chain has to be
laid out in a line, where every link is limited by the single neighbour
supplying it. Breadth beats depth, and the Press, Assembler, Lab and
Condenser end up as content that a player who is optimising will not build.

This is a real design problem: it makes four of the twelve machines decorative,
and the game's stated progression — deeper rock, deeper chain — does not
survive contact with a calculator.

It is **not** fixed in this release, deliberately. Fixing it means changing
`RES_VALUE`, the input counts or the rates, and every one of those invalidates
the measured playability results the balance tests encode — the first quota
landing inside a first session, the curve not walling out by stratum 20, heat
management paying for itself when heat is the bottleneck. That is a balance
pass with its own verification, not a line changed on the way past.

What the next pass should try, in the order the measurements suggest:

1. **Cut the input counts on the deep machines.** The Press wanting two Ingots
   and the Assembler wanting a Plate plus two Gravel are what make the deep
   chain impossible to feed through four neighbours. One input each would make
   depth viable without touching a single value.
2. **Let a machine pull from a neighbour's neighbour at reduced rate**, or give
   one machine a "conveys" tag. This is the least invasive way to break the
   adjacency ceiling, and it is a new interaction rather than a number change.
3. **Re-run `layout_lab.gd` and `layout_search.gd` after either change.** The
   number to watch is not the best score but the *spread*: if independent
   searches keep landing on very different boards within a few percent of each
   other, the placement puzzle is doing its job. If one board dominates, the
   game has a solved answer and no puzzle.

## A caveat on the search tool

`layout_search.gd` is a plain hill-climber with random restarts. One of its
four restarts, seeded from an empty board, never improved at all — single-cell
mutations almost never help when there is no chain to extend. Its results are
a lower bound on what is achievable, not an optimum, and the spread figure it
prints is meaningless when one restart scores zero. Both are noted here rather
than in a commit message because the number it prints will be quoted later.
