# Google Play store listing — draft

Nothing here has been submitted. Character limits are Play's.

---

## App name (30 max)

```
Lodeworks: Idle Machine Grid
```
`28 characters.` A distinctive brand word plus the two search terms that
actually describe the game. "Idle" is the single highest-value keyword for
discovery in this genre and belongs in the name, not only the description.

**Alternative if "Lodeworks" turns out to be taken:** `Orecircuit: Idle Factory`

## Short description (80 max)

```
Place machines. Heat feeds them. Rearrange the grid. Descend for richer rock.
```
`77 characters.` Verbs, not adjectives. It says what your hands do.

## Full description (4000 max)

```
Build a machine that runs itself, then spend the rest of your life improving it.

Lodeworks is an idle factory puzzle on a small grid. Machines pass material to
whatever sits next to them — no belts to draw, no menus to fight. A drill makes
ore. A crusher turns it into gravel. A vault sells whatever it is handed. Three
tiles, and the numbers start moving.

Then heat arrives and the grid becomes a puzzle.

Every machine emits heat, half of it bleeds into each neighbour, and every
machine has a temperature it works best at. A smelter next to a boiler runs
hot and fast. A press three tiles away chokes on the same heat and needs a
coolant cell you would rather have spent on production. Two players with the
same twelve machines will not build the same board.

DESCEND
Hit the quota and drop to the next stratum. Deeper rock is richer, hotter and
stranger. Thermal vents, insulating clay that stops heat spreading at all,
brittle seams that speed your drills and slow everything downstream, and a
collapsed ring that takes a third of your build space away. Each stratum is
generated from its depth, so the stratum 14 you are stuck on is the same
stratum 14 everyone else is stuck on.

COLLAPSE
When you can go no deeper, collapse the shaft. You lose the board, the credits
and the research. You keep Cores, and everything you have permanently
researched with them. Then you go again — deeper, faster, and with machines you
did not have last time.

WHILE YOU ARE AWAY
The factory keeps running. You bank a share of your own measured rate for up to
four hours, more once you have researched it. The game tells you the exact
three numbers it used, because an idle game that fudges that number is training
you to disbelieve every other number it prints.

NO DARK PATTERNS
• No interstitial ads. Not one. Every ad is a rewarded video you choose to
  watch, and every one of them adds something rather than removing a penalty.
• One optional purchase that removes ads and adds convenience. It unlocks no
  machine, no stratum and no upgrade. The whole game is reachable without it.
• No energy bars, no timers to skip, no loot boxes, no daily-login guilt, no
  account, no ads for other games interrupting you mid-thought.

Plays entirely offline. No sign-in, no cloud, nothing to create.

TWELVE MACHINES
Drill, Crusher, Vault, Smelter, Boiler, Coolant Cell, Press, Assembler,
Amplifier, Lab, Duplicator, Condenser. Only twelve — but what matters is what
each one is next to, and that is a much larger number.
```

## Category and tags

- Category: **Games → Simulation** (secondary fit: Puzzle)
- Tags: idle, factory, incremental, simulation, puzzle, offline, management
- Content rating target: **everyone**, target audience **13+**
- Contains ads: **yes** (rewarded only) · In-app purchases: **yes** (one item)

## ASO keyword set

Ranked by how honestly the game answers the search. Chasing a term the game
does not deliver costs an uninstall, and uninstalls cost ranking.

**Primary** — idle game, idle factory, incremental game, factory builder,
offline idle game, idle simulation

**Secondary** — grid puzzle, machine builder, automation game, idle tycoon,
production line, prestige game

**Long tail, where a small game can actually rank** — idle game no ads,
offline factory game, incremental grid builder, idle game without timers,
factory game offline

**Deliberately not targeted** — "tycoon" alone, "merge", "clicker". Vastly more
competitive, and this is not that game. The genre research was blunt on this:
2,000+ block-puzzle titles launched in H1 2026 alone and the leader runs 125+
data scientists. The winnable strategy is a term nobody contests, not a term
everybody does.

## Screenshots

Five, generated from the running game by `tools/screenshot.gd` at 720×1440.
Nothing is a mock-up; every board shown is one the simulation actually ran and
the test suite verifies.

| file | shows | caption |
|---|---|---|
| `01_first_line.png` | the tutorial board, stratum 0 | "Three tiles and the numbers start moving." |
| `02_heat.png` | boiler + coolant around a smelter | "Heat makes machines fast. Then it makes them choke." |
| `03_full_board.png` | a complete chain at stratum 9 | "Ore to components to research, on one small grid." |
| `04_research.png` | the permanent research tree | "Cores survive the collapse. Nothing else does." |
| `05_offline.png` | the welcome-back panel | "It runs while you are gone, and shows its working." |

## Feature graphic (1024×500)

Not produced. The three-panel screenshot composite is the obvious source;
needs a title treatment over it. **Outstanding.**

## Trailer

Not produced. Lowest priority: Play does not require one, and for an idle game
a 15-second capture of a board being rearranged and the rate changing would do
more than an edited trailer. `tools/screenshot.gd` already drives the game
programmatically and is the natural place to add frame capture for a GIF.

## What this listing deliberately does not claim

No player counts, no review quotes, no "millions of downloads", no awards, no
"#1" anything. There is nothing to cite, and a store listing that claims what
the app cannot show is both a rejection risk and the setup for the one-star
review that follows.
