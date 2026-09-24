"""Put numbers on a screenshot so "closer to the reference" is not a feeling.

    uv run --no-project --with pillow --with numpy python tools/visual_compare.py \
        IMAGE [IMAGE ...] [--md FILE]

For each image: mean brightness, contrast (luminance standard deviation),
saturation, the Hasler-Suesstrunk colourfulness metric, warm/cool balance,
and the share of the frame taken by near-black (the "void" the camera must
never show). Run it on the reference concepts and on the game's own
screenshots and the table says where they differ. It does not say which is
better; that is a judgement, and the report marks it as one.
"""
import argparse
import io
import os
import sys

import numpy as np
from PIL import Image


def stats(path):
    im = Image.open(path).convert("RGB")
    im.thumbnail((960, 960))
    a = np.asarray(im, dtype=np.float32) / 255.0
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    mx = a.max(axis=2)
    mn = a.min(axis=2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    rg = r - g
    yb = 0.5 * (r + g) - b
    colourful = np.sqrt(rg.std() ** 2 + yb.std() ** 2) + 0.3 * np.sqrt(rg.mean() ** 2 + yb.mean() ** 2)
    return {
        "image": os.path.basename(path),
        "size": "%dx%d" % Image.open(path).size,
        "brightness": float(lum.mean()),
        "contrast": float(lum.std()),
        "saturation": float(sat.mean()),
        "colourfulness": float(colourful * 100.0),
        "warm-cool": float((r - b).mean()),
        "near-black %": float((lum < 0.04).mean() * 100.0),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("images", nargs="+")
    ap.add_argument("--md")
    args = ap.parse_args()
    rows = [stats(p) for p in args.images]
    cols = ["image", "size", "brightness", "contrast", "saturation", "colourfulness",
            "warm-cool", "near-black %"]
    lines = ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]
    for r in rows:
        lines.append("| " + " | ".join(
            ("%.3f" % r[c]) if isinstance(r[c], float) else str(r[c]) for c in cols) + " |")
    text = "\n".join(lines)
    print(text)
    if args.md:
        with io.open(args.md, "w", encoding="utf-8", newline="\n") as f:
            f.write(text + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
