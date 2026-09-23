#!/usr/bin/env python3
"""Can a player still tell the twelve machines apart?

Reads the strips written by tools/readability.gd and compares every machine
against every other one, twice: in colour, and again desaturated, because a
board that only works for people with normal colour vision is a board that
does not work.

The measure is mean absolute pixel difference over the tile. It is crude on
purpose -- what it catches is the failure that matters, which is two machines
that have quietly become the same picture.
"""
import sys, pathlib
from PIL import Image

ORDER = ["drill", "crusher", "vault", "smelter", "boiler", "coolant",
         "press", "assembler", "amplifier", "lab", "duplicator", "condenser"]

# Below this two tiles are close enough that a player scanning a board would
# have to stop and look. Tuned against the pair that is legitimately most
# similar -- Coolant Cell and Condenser, which are both cold blue boxes.
FLOOR_COLOUR = 9.0
FLOOR_GREY = 6.0


def tiles(path, n):
    im = Image.open(path).convert("RGB")
    w = im.width // n
    return [im.crop((i * w, 0, (i + 1) * w, im.height)) for i in range(n)]


def diff(a, b):
    pa, pb = a.load(), b.load()
    total = 0
    for y in range(a.height):
        for x in range(a.width):
            ca, cb = pa[x, y], pb[x, y]
            total += abs(ca[0] - cb[0]) + abs(ca[1] - cb[1]) + abs(ca[2] - cb[2])
    return total / (a.width * a.height * 3)


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    failures, checked = [], 0
    for strip in sorted(root.glob("strip_*.png")):
        px = int(strip.stem.split("_")[1])
        for mode, floor in (("colour", FLOOR_COLOUR), ("grey", FLOOR_GREY)):
            ts = tiles(strip, len(ORDER))
            if mode == "grey":
                ts = [t.convert("L").convert("RGB") for t in ts]
            worst, worst_pair = 999.0, None
            for i in range(len(ORDER)):
                for j in range(i + 1, len(ORDER)):
                    d = diff(ts[i], ts[j])
                    checked += 1
                    if d < worst:
                        worst, worst_pair = d, (ORDER[i], ORDER[j])
                    if d < floor:
                        failures.append(
                            f"{px}px {mode}: {ORDER[i]} and {ORDER[j]} differ "
                            f"by only {d:.1f} (floor {floor})")
            print(f"   {px:>3}px {mode:<6} closest pair "
                  f"{worst_pair[0]}/{worst_pair[1]} at {worst:.1f}")
    print(f"   {checked} pair comparisons")
    if failures:
        for f in failures:
            print("FAIL  " + f)
        return 1
    print("   every machine is distinguishable from every other, in colour "
          "and in greyscale, at every supported cell size")
    return 0


if __name__ == "__main__":
    sys.exit(main())
