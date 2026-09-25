"""Lay out the props round the yard: resource nodes in clusters, clutter
between them, and ground left bare on purpose.

    python tools/props_layout.py            # rewrites placement.props in assets/art/layout.json
    python tools/props_layout.py --check    # prints the counts, writes nothing

The distribution reads outwards from the Factory Core:

  reach 2-4   a few small starter nodes on the yard's back and sides
  reach 5-10  clusters of one kind: crystal, ore seams, heat vents
  reach 11+   fewer, larger fields, and the rare blue crystal
  two wide sectors are kept bare: ground for a factory to grow into

"Reach" is the tile distance from the Core's 4 x 4 block (BuildArea.reach).
The yard clears a prop when it reaches it, so near nodes are claimed first.

Rules every prop keeps (tests/test_iso.gd checks them on the file):
  - never on the Core's block, never two props within one tile of each other
  - nothing within reach 6 in front of the Core, where a prop would stand
    over the yard's front edge and the machines on it
  - kinds are only the prop sheet's own, sizes 0.8 to 1.25
Deterministic: the same seed writes the same file.
"""
import io
import json
import math
import os
import random
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAYOUT = os.path.join(ROOT, "assets", "art", "layout.json")

W = H = 44
CORE = (20, 20, 4, 4)          # BuildArea.CORE
OFFSET = 2                     # placement.board_offset: slab = grid + 2
SEED = 2609


def reach(x, y):
    cx, cy, cw, ch = CORE
    dx = max(cx - x, 0, x - (cx + cw - 1))
    dy = max(cy - y, 0, y - (cy + ch - 1))
    return max(dx, dy)


def in_front(x, y):
    # Below the Core on screen: both past the block's far edges' middle.
    return x + y > 46 and abs(x - y) < 8


# (kind, centre x, centre y, count, spread, size) -- each a small group of
# one kind, placed round its centre with some jitter.
#
# The ground has regions, so a player reads kinds by where they are: crystal
# behind the Core, ore to its right, heat vents to its left, the rare blue
# crystal only far out, and bare clearings in front. By the yard, one small
# sample of each region's kind: the first thing a new factory looks out on,
# and the first the yard claims.
CLUSTERS = [
    # starters (reach 2-4): one of each region's kind, on its side
    ("rubble", 22, 18, 1, 0.3, 0.85),
    ("vent", 18, 22, 1, 0.3, 0.85),
    ("crystal_purple", 20, 16, 2, 1.0, 0.85),
    ("ore_vein", 27, 18, 2, 1.0, 0.9),
    ("vent", 16, 25, 1, 0.3, 0.9),
    # behind the Core: crystal fields
    ("crystal_purple", 16, 13, 4, 1.2, 1.0),
    ("crystal_purple", 24, 14, 3, 1.1, 1.0),
    ("crystal_purple", 11, 10, 4, 1.3, 1.05),
    ("crystal_purple", 21, 9, 3, 1.2, 1.0),
    ("rubble", 15, 8, 2, 1.0, 0.95),
    ("crystal_purple", 12, 16, 2, 0.8, 1.0),
    ("crystal_purple", 6, 5, 5, 1.6, 1.1),
    # to the right: ore seams and their spoil
    ("ore_vein", 29, 14, 3, 1.1, 1.0),
    ("ore_vein", 29, 19, 2, 0.8, 0.95),
    ("rubble", 26, 12, 1, 0.3, 0.95),
    ("ore_vein", 34, 18, 3, 1.1, 1.0),
    ("rubble", 32, 11, 2, 1.0, 0.95),
    ("ore_vein", 32, 14, 2, 0.8, 1.0),
    ("crate", 36, 14, 1, 0.3, 0.95),
    ("ore_vein", 39, 9, 4, 1.4, 1.1),
    ("rubble", 41, 19, 2, 1.0, 1.0),
    # to the left: heat rising from below
    ("vent", 13, 27, 3, 1.1, 1.0),
    ("vent", 15, 19, 2, 0.8, 0.95),
    ("ore_vein", 12, 24, 2, 0.8, 1.0),
    ("rubble", 17, 29, 1, 0.3, 0.95),
    ("vent", 9, 22, 3, 1.1, 1.0),
    ("vent", 11, 18, 2, 0.8, 1.0),
    ("ore_vein", 11, 32, 2, 1.0, 1.0),
    ("rubble", 7, 28, 2, 1.0, 0.95),
    ("vent", 4, 34, 3, 1.3, 1.05),
    # far out: the rare blue crystal, and an ore seam beyond the clearings
    ("crystal_cyan", 38, 4, 5, 1.5, 1.15),
    ("crystal_cyan", 3, 41, 4, 1.4, 1.15),
    ("crystal_cyan", 24, 41, 3, 1.2, 1.15),
    ("ore_vein", 33, 39, 4, 1.4, 1.1),
    ("crate", 38, 36, 1, 0.3, 1.0),
    ("crate", 17, 40, 1, 0.3, 1.0),
]

# Ground left bare for a factory to grow into: a wide clearing front-left
# and one front-right of the Core, from the middle band outwards. No prop
# lands in them.
BARE = [
    lambda x, y: 6 <= y - x <= 14 and 50 <= x + y <= 64,
    lambda x, y: 6 <= x - y <= 14 and 50 <= x + y <= 64,
]

LAMPS = [[1, 1, "lamp"], [46, 1, "lamp"], [1, 46, "lamp"], [46, 46, "lamp"],
         [24, 1, "lamp"], [1, 24, "lamp"], [46, 24, "lamp"], [24, 46, "lamp"]]


def allowed(x, y, taken):
    if not (0 <= x < W and 0 <= y < H):
        return False
    r = reach(x, y)
    if r < 2:
        return False
    if r < 7 and in_front(x, y):
        return False
    if any(f(x, y) for f in BARE):
        return False
    for (tx, ty) in taken:
        if max(abs(tx - x), abs(ty - y)) < 2:
            return False
    return True


def build():
    rng = random.Random(SEED)
    taken = []
    out = []
    for kind, cx, cy, n, spread, size in CLUSTERS:
        placed = 0
        tries = 0
        while placed < n and tries < 400:
            tries += 1
            a = rng.random() * math.tau
            d = spread * math.sqrt(rng.random()) * (1.0 if placed else 0.4)
            x = int(round(cx + math.cos(a) * d * 1.8))
            y = int(round(cy + math.sin(a) * d * 1.8))
            if not allowed(x, y, taken):
                continue
            taken.append((x, y))
            s = round(size * (0.92 + 0.16 * rng.random()), 2)
            out.append([x + OFFSET, y + OFFSET, kind, s])
            placed += 1
        if placed < n:
            print("  cluster %s at (%d,%d): placed %d of %d" % (kind, cx, cy, placed, n))
    return LAMPS + out


def report(props):
    from collections import Counter
    board = [p for p in props if 0 <= p[0] - OFFSET < W and 0 <= p[1] - OFFSET < H]
    print("props %d (on the board %d, lamps %d)" % (len(props), len(board), len(props) - len(board)))
    print("by kind", dict(Counter(p[2] for p in props)))
    bands = Counter()
    for p in board:
        r = reach(p[0] - OFFSET, p[1] - OFFSET)
        bands["2-4" if r <= 4 else ("5-10" if r <= 10 else "11+")] += 1
    print("by reach", dict(bands))
    cells = [(x, y) for x in range(W) for y in range(H) if 3 <= reach(x, y) <= 10]
    held = sum(1 for p in board if 3 <= reach(p[0] - OFFSET, p[1] - OFFSET) <= 10)
    print("reach 3-10: %d of %d cells hold a prop (%.1f%%)" % (held, len(cells),
                                                               100.0 * held / len(cells)))


def main():
    props = build()
    report(props)
    if "--check" in sys.argv:
        return
    with io.open(LAYOUT, encoding="utf-8") as f:
        layout = json.load(f)
    layout["placement"]["props"] = props
    with io.open(LAYOUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(layout, f, indent=1)
    print("wrote", LAYOUT)


if __name__ == "__main__":
    main()
