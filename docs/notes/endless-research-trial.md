# Research without an end: a parked trial (25 September 2026)

Parked on this branch when the owner moved the priority to the progression
backbone (Core prerequisites) on the same day. Not merged into
visual/landscape-iso. What it contains: every collapse raises the limit of
five research lines by one level (Economy.max_level); past a line's first
limit a level multiplies instead of adding and is priced mainly in Cores;
the deepest stratum ever reached is kept and a new record is announced.

Collapse lab runs (LODEWORKS_JOURNEY=collapses), one seed, stall 15 min:

Variant A (limits rise, deep levels add, priced in Research at x1.6):
```
   8 lines, 5 of them growing one level a collapse (Economy.max_level)
   1    1h 18m    15     5.96M     76     58.4      20 (30)       1h 18m
   2    52m 9s    19     76.0M     168    193.3     38 (17)       2h 10m
   3    56m 7s    20     101M      258    275.8     50 (10)       3h 6m
   4    51m 42s   20     105M      333    386.4     57 (8)        3h 58m
   5    54m 30s   20     128M      377    415.0     62 (8)        4h 52m
```
Depth stuck at 20; Research was the choke, Cores piled up unspent.

Variant B2 (deep levels multiply; 0.3 of the steep Research price, x1.25; Cores 12 x1.22):
```
   8 lines, 5 of them growing one level a collapse (Economy.max_level)
   1    1h 18m    15     5.96M     76     58.4      20 (30)       1h 18m
   2    54m 2s    19     70.9M     167    185.4     34 (21)       2h 12m
   3    38m 41s   18     50.4M     212    328.8     44 (16)       2h 50m
   4    39m 1s    20     142M      266    409.0     55 (10)       3h 29m
   5    54m 25s   23     343M      546    601.8     62 (8)        4h 24m
   6    45m 30s   23     382M      1077   1419.8    69 (6)        5h 9m
   7    39m 16s   23     400M      1689   2579.9    75 (5)        5h 49m
```
Depth 20 -> 23, then stuck; Cores inflated (1,689 a run, 2,167 unspent).

Variant B3 (0.1 Research share, x1.2; Cores 20 x1.3), stopped after run 4:
```
   8 lines, 5 of them growing one level a collapse (Economy.max_level)
   1    1h 18m    15     5.96M     76     58.4      20 (30)       1h 18m
   2    54m 2s    19     70.9M     167    185.4     34 (21)       2h 12m
   3    59m 53s   20     105M      222    222.4     42 (18)       3h 12m
   4    37m 4s    20     140M      228    368.9     50 (15)       3h 49m
```

Open question for the progression work: where the collapse sits once the
Factory Core has its own levels and prerequisites.
