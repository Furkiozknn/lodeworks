"""Turn the generated source sheets into the game's art.

    uv run --no-project --with pillow --with numpy --with scipy \
        python tools/art_build.py [--raw DIR]

Reads the raw sheets named in art_src/sources.json (from --raw, from
$LODEWORKS_ART_RAW, or from ../lodeworks_art/gen; anything missing is
downloaded from the URL recorded next to it), and writes:

  assets/art/machines/<theme>.webp       12 machines, one atlas per palette
  assets/art/machines/<theme>_up.webp    the same, top upgrade tier
  assets/art/tiles/floor.jpg             8 floor slabs, square, top-down
  assets/art/world/workings.jpg          the landscape world painting
  assets/art/world/island.webp           the rock the platform stands on
  assets/art/foreman/poses.webp          5 Foreman poses
  assets/art/layout.json                 every number the game needs to
                                         place those images
  art_src/SOURCES.md                     generated from sources.json

The raw sheets are never committed: they are 4-7 MB each and the art folder
has a 40 MB budget. What is committed is small enough to ship and exact
enough to rebuild -- every raw file has its job id, prompt and URL.

Every measurement that places a sprite (where a machine's base plate is,
where the island's flat top is) is taken from the alpha channel here, not
typed in, so a regenerated sheet re-measures itself.
"""
import argparse
import io
import json
import os
import subprocess
import sys
import urllib.request

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art")
SOURCES = os.path.join(ROOT, "art_src", "sources.json")

MACHINE_ORDER = ["drill", "crusher", "vault", "smelter", "boiler", "coolant",
                 "press", "assembler", "amplifier", "lab", "duplicator",
                 "condenser"]
THEMES = ["shaft", "brass", "frost", "verdant", "ember", "slate"]

# Width of a machine's base plate in the atlas, in pixels. Every machine is
# scaled so its plate is exactly this wide, which makes one scale factor in
# the game right for all twelve. 224 px is the plate at the closest zoom on a
# 1080p phone (128 world units x 0.8 footprint x 1.45 zoom x 1.5 px/unit).
BASE_PX = 224
TILE_PX = 256
ISLAND_W = 2048
FOREMAN_H = 420
# The Core's plate spans 2.6 cells; a prop's patch is most of one.
CORE_BASE_PX = 520
PROP_BASE_PX = 200


def raw_dir(arg):
    for d in [arg, os.environ.get("LODEWORKS_ART_RAW"),
              os.path.join(os.path.dirname(ROOT), "lodeworks_art", "gen")]:
        if d and os.path.isdir(d):
            return d
    d = os.path.join(ROOT, ".art_raw")
    os.makedirs(d, exist_ok=True)
    return d


def load_raw(src, name):
    entry = src[name]
    path = os.path.join(RAW, entry["file"])
    if not os.path.exists(path):
        print("  downloading", entry["file"])
        urllib.request.urlretrieve(entry["url"], path)
    return Image.open(path)


def alpha01(im):
    """The generator's alpha tops out at 252-254 and has a soft glow skirt.
    Remapped so the body is fully opaque and the skirt is a short falloff
    rather than a grey halo."""
    a = np.asarray(im.getchannel("A"), dtype=np.float32)
    return np.clip((a - 16.0) / (232.0 - 16.0), 0.0, 1.0)


def with_alpha(im, a):
    rgb = np.asarray(im.convert("RGB"), dtype=np.uint8)
    out = np.dstack([rgb, (a * 255.0 + 0.5).astype(np.uint8)])
    return Image.fromarray(out, "RGBA")


# --- machines ---------------------------------------------------------------

def machine_parts(im, cols=4, rows=3):
    """Twelve crops, one per machine, found as connected blobs of alpha and
    assigned to the 4 x 3 cell their base sits in -- a steam plume or a spark
    that crosses a cell line stays with its own machine."""
    a = alpha01(im)
    h, w = a.shape
    # Labelled on the solid body only: at a low threshold the glow skirts of
    # neighbouring machines touch and two machines become one blob. The skirt
    # is added back below, per machine, by growing the solid mask.
    # On some sheets two neighbours touch (a plate corner against an arm).
    # The emptiest line near each row and column boundary is cut first, so
    # every body is its own blob; anything the cut detaches is reattached
    # to the nearest body below.
    solid = a > 0.5
    for k in range(1, rows):
        band = range(int(h * k / rows) - 90, int(h * k / rows) + 90)
        y = min(band, key=lambda y: solid[y].sum())
        solid[y - 1:y + 2] = False
    for k in range(1, cols):
        band = range(int(w * k / cols) - 90, int(w * k / cols) + 90)
        x = min(band, key=lambda x: solid[:, x].sum())
        solid[:, x - 1:x + 2] = False
    lab, n = ndimage.label(solid)
    objs = ndimage.find_objects(lab)
    sizes = ndimage.sum(np.ones_like(a), lab, index=np.arange(1, n + 1))
    # The twelve bodies are the twelve largest blobs. The sheet is not a
    # strict grid -- a first-row plate can hang below the one-third line --
    # so rows are found by sorting the bodies by where their plates end, and
    # columns by x within each row.
    count = cols * rows
    big = sorted(np.argsort(sizes)[-count:] + 1,
                 key=lambda i: objs[i - 1][0].stop)
    order = []
    for r in range(rows):
        row = sorted(big[r * cols:(r + 1) * cols], key=lambda i: objs[i - 1][1].start)
        order += row
    cells = {k: [order[k]] for k in range(count)}
    centre = {i: ((objs[i - 1][1].start + objs[i - 1][1].stop) / 2,
                  (objs[i - 1][0].start + objs[i - 1][0].stop) / 2) for i in order}
    # Loose pieces -- a spark, a puff of steam -- go with the nearest body.
    for i in range(1, n + 1):
        if i in order or sizes[i - 1] < 30:
            continue
        ys, xs = objs[i - 1]
        c = ((xs.start + xs.stop) / 2, (ys.start + ys.stop) / 2)
        k = min(range(count), key=lambda k: (centre[order[k]][0] - c[0]) ** 2
                + (centre[order[k]][1] - c[1]) ** 2)
        cells[k].append(i)
    parts = []
    for k in range(count):
        mask = ndimage.binary_dilation(np.isin(lab, cells[k]), iterations=10)
        mask &= a > 0.0
        ys, xs = np.nonzero(mask)
        x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        am = np.where(mask, a, 0.0)[y0:y1, x0:x1]
        crop = with_alpha(im.crop((x0, y0, x1, y1)), am)
        solid = am > 0.5
        sy, sx = np.nonzero(solid)
        bottom = sy.max()
        # The front corner of the plate: the centre of the lowest solid row.
        foot_x = float(sx[sy >= bottom - 2].mean())
        # The plate's width: the widest solid row in the lower third.
        lo = int(bottom - 0.33 * (bottom - sy.min()))
        widest = 0
        for y in range(lo, bottom + 1):
            row = np.nonzero(solid[y])[0]
            if row.size:
                widest = max(widest, row.max() - row.min())
        parts.append({"img": crop, "foot": (foot_x, float(bottom)),
                      "plate_w": float(widest)})
    return parts


def build_machine_atlas(im, name, cols=4, rows=3, folder="machines", base_px=BASE_PX):
    parts = machine_parts(im, cols, rows)
    # One plate width for the whole sheet. The generator draws every base
    # identically, so the median is the plate and the outliers are machines
    # with something sticking out sideways.
    plate = float(np.median([p["plate_w"] for p in parts]))
    s = base_px / plate
    # The anchor is the centre of the plate's top face: a quarter of the plate
    # width above the front corner (a 2:1 diamond), plus the plate's own
    # thickness, which is 3% of its width on these sheets.
    lift = plate * (0.25 + 0.03)
    above, below, half = 0.0, 0.0, 0.0
    for p in parts:
        fx, fy = p["foot"]
        iw, ih = p["img"].size
        ay = fy - lift
        above = max(above, ay * s)
        below = max(below, (ih - ay) * s)
        half = max(half, max(fx, iw - fx) * s)
    cw = int(np.ceil(half * 2 + 8))
    ch = int(np.ceil(above + below + 8))
    ax, ay_cell = cw / 2.0, above + 4
    atlas = Image.new("RGBA", (cw * cols, ch * rows), (0, 0, 0, 0))
    for k, p in enumerate(parts):
        iw, ih = p["img"].size
        sp = p["img"].resize((max(1, round(iw * s)), max(1, round(ih * s))),
                             Image.LANCZOS)
        fx, fy = p["foot"]
        ox = (k % cols) * cw + ax - fx * s
        oy = (k // cols) * ch + ay_cell - (fy - lift) * s
        atlas.alpha_composite(sp, (int(round(ox)), int(round(oy))))
    path = os.path.join(OUT, folder, name + ".webp")
    atlas.save(path, "WEBP", quality=90, method=6)
    return {"cell": [cw, ch], "anchor": [round(ax, 1), round(ay_cell, 1)],
            "base_px": base_px, "cols": cols, "rows": rows,
            "file": "res://assets/art/%s/%s.webp" % (folder, name)}


# --- sprites that stand on the ground: the crew and the galleries ------------

def build_sprites(im, name, cols, rows, folder, width_px, order):
    """A sheet of things that stand on the ground at their lowest point --
    the Rig's poses, the gallery mouths -- one scale for the whole sheet
    (the median base is `width_px` wide), each cell anchored at the centre
    of its lowest solid row."""
    parts = machine_parts(im, cols, rows)
    base = float(np.median([p["plate_w"] for p in parts]))
    s = width_px / base
    above, below, half = 0.0, 0.0, 0.0
    for p in parts:
        fx, fy = p["foot"]
        iw, ih = p["img"].size
        above = max(above, fy * s)
        below = max(below, (ih - fy) * s)
        half = max(half, max(fx, iw - fx) * s)
    cw = int(np.ceil(half * 2 + 8))
    ch = int(np.ceil(above + below + 8))
    ax, ay = cw / 2.0, above + 4
    n = cols * rows
    atlas = Image.new("RGBA", (cw * n, ch), (0, 0, 0, 0))
    for k, p in enumerate(parts):
        iw, ih = p["img"].size
        sp = p["img"].resize((max(1, round(iw * s)), max(1, round(ih * s))), Image.LANCZOS)
        fx, fy = p["foot"]
        atlas.alpha_composite(sp, (int(round(k * cw + ax - fx * s)), int(round(ay - fy * s))))
    os.makedirs(os.path.join(OUT, folder), exist_ok=True)
    atlas.save(os.path.join(OUT, folder, name + ".webp"), "WEBP", quality=90, method=6)
    return {"file": "res://assets/art/%s/%s.webp" % (folder, name), "cell": [cw, ch],
            "anchor": [round(ax, 1), round(ay, 1)], "base_px": width_px, "order": order}


# --- tiles ------------------------------------------------------------------

def build_tiles(im, name="floor"):
    rgb = np.asarray(im.convert("RGB"), dtype=np.float32)
    lum = rgb.mean(axis=2)
    lab, n = ndimage.label(lum > 38)
    boxes = []
    for i, sl in enumerate(ndimage.find_objects(lab), start=1):
        ys, xs = sl
        if (ys.stop - ys.start) > 200 and (xs.stop - xs.start) > 200:
            boxes.append((ys.start, xs.start, ys.stop, xs.stop))
    # The eight slabs are the eight largest bright regions; anything else is
    # a stray highlight in a gap.
    boxes = sorted(boxes, key=lambda b: (b[2] - b[0]) * (b[3] - b[1]))[-8:]
    boxes.sort(key=lambda b: (round(b[0] / 300), b[1]))
    assert len(boxes) == 8, "expected 8 floor tiles, found %d" % len(boxes)
    atlas = Image.new("RGB", (TILE_PX * 4, TILE_PX * 2))
    for k, (y0, x0, y1, x1) in enumerate(boxes):
        # A hair inside the slab, so no black gap survives into the seam.
        ix, iy = int((x1 - x0) * 0.012), int((y1 - y0) * 0.012)
        t = im.convert("RGB").crop((x0 + ix, y0 + iy, x1 - ix, y1 - iy))
        atlas.paste(t.resize((TILE_PX, TILE_PX), Image.LANCZOS),
                    ((k % 4) * TILE_PX, (k // 4) * TILE_PX))
    atlas.save(os.path.join(OUT, "tiles", name + ".jpg"), "JPEG", quality=88,
               optimize=True)
    return {"file": "res://assets/art/tiles/%s.jpg" % name, "tile_px": TILE_PX,
            "cols": 4, "rows": 2,
            "kinds": ["plain", "plain", "plain", "plain", "plate", "grate",
                      "crystal", "cracked"]}


# --- island -----------------------------------------------------------------

def build_island(im):
    a = alpha01(im)
    solid = a > 0.5
    ys, xs = np.nonzero(solid)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    # The flat top is a diamond: its left and right corners are the extreme
    # solid points in the upper half, its back corner is the top of the
    # silhouette. The front corner is hidden by the cliff below it, so it is
    # taken by symmetry.
    upper = solid[: solid.shape[0] // 2]
    uy, ux = np.nonzero(upper)
    left = (ux.min(), uy[ux == ux.min()].mean())
    right = (ux.max(), uy[ux == ux.max()].mean())
    cy = (left[1] + right[1]) / 2
    cx = (left[0] + right[0]) / 2
    # The back corner, from the columns around the centre rather than the
    # single highest pixel, which is a tuft of grass.
    cols = [np.nonzero(solid[:, x])[0] for x in range(int(cx) - 40, int(cx) + 40)]
    back = float(np.median([c[0] for c in cols if c.size]))
    crop = with_alpha(im, a).crop((x0, y0, x1, y1))
    s = ISLAND_W / crop.size[0]
    crop = crop.resize((ISLAND_W, round(crop.size[1] * s)), Image.LANCZOS)
    crop.save(os.path.join(OUT, "world", "island.webp"), "WEBP", quality=86,
              method=6)
    return {"file": "res://assets/art/world/island.webp",
            "size": list(crop.size),
            "top_center": [round((cx - x0) * s, 1), round((cy - y0) * s, 1)],
            "top_half_w": round((right[0] - left[0]) / 2 * s, 1),
            "top_half_h": round((cy - back) * s, 1)}


def build_world(im):
    im = im.convert("RGB")
    im.save(os.path.join(OUT, "world", "workings.jpg"), "JPEG", quality=84,
            optimize=True, progressive=False)
    w, h = im.size
    # Where the chasm is: the painting was asked for an empty middle, and the
    # island is centred slightly above the middle so the tray at the bottom
    # of the screen does not cover its front corner.
    return {"file": "res://assets/art/world/workings.jpg", "size": [w, h],
            "anchor": [round(w * 0.5), round(h * 0.47)]}


def build_foreman(im):
    a = alpha01(im)
    lab, n = ndimage.label(a > 0.08)
    blobs = []
    for i, sl in enumerate(ndimage.find_objects(lab), start=1):
        ys, xs = sl
        if (ys.stop - ys.start) > im.size[1] * 0.4:
            blobs.append(sl)
    blobs.sort(key=lambda sl: sl[1].start)
    assert len(blobs) == 5, "expected 5 Foreman poses, found %d" % len(blobs)
    crops = []
    for sl in blobs:
        ys, xs = sl
        mask = np.zeros_like(a)
        mask[sl] = a[sl]
        c = with_alpha(im, mask).crop((xs.start, ys.start, xs.stop, ys.stop))
        s = FOREMAN_H / c.size[1]
        crops.append(c.resize((round(c.size[0] * s), FOREMAN_H), Image.LANCZOS))
    cw = max(c.size[0] for c in crops) + 4
    atlas = Image.new("RGBA", (cw * 5, FOREMAN_H), (0, 0, 0, 0))
    for k, c in enumerate(crops):
        atlas.alpha_composite(c, (k * cw + (cw - c.size[0]) // 2, 0))
    atlas.save(os.path.join(OUT, "foreman", "poses.webp"), "WEBP", quality=88,
               method=6)
    return {"file": "res://assets/art/foreman/poses.webp", "cell": [cw, FOREMAN_H],
            "poses": ["idle", "point", "cheer", "jump", "surprised"]}


ICON_PX = 128
ICON_ORDER = ["credits", "energy", "descend", "research", "cores", "heat", "cold",
              "upgrade", "shop", "settings", "codex", "star", "lock", "ad", "ok",
              "warning"]


def build_icons(im):
    """The HUD's sixteen icons, each fitted into a square cell."""
    parts = machine_parts(im, 4, 4)
    atlas = Image.new("RGBA", (ICON_PX * 4, ICON_PX * 4), (0, 0, 0, 0))
    for k, p in enumerate(parts):
        img = p["img"]
        s = (ICON_PX - 6) / max(img.size)
        img = img.resize((max(1, round(img.size[0] * s)), max(1, round(img.size[1] * s))),
                         Image.LANCZOS)
        atlas.alpha_composite(img, ((k % 4) * ICON_PX + (ICON_PX - img.size[0]) // 2,
                                    (k // 4) * ICON_PX + (ICON_PX - img.size[1]) // 2))
    os.makedirs(os.path.join(OUT, "ui"), exist_ok=True)
    atlas.save(os.path.join(OUT, "ui", "icons.webp"), "WEBP", quality=90, method=6)
    return {"file": "res://assets/art/ui/icons.webp", "cell": [ICON_PX, ICON_PX],
            "cols": 4, "rows": 4, "order": ICON_ORDER}


# --- sources ----------------------------------------------------------------

def write_sources_md(src):
    lines = ["# Art sources", "",
             "Generated by `tools/art_build.py` from `art_src/sources.json`."
             " Do not edit by hand.", "",
             "Every image the game ships is built from one of these raw"
             " generations. The raw files are not in the repository (4-7 MB"
             " each, against a 40 MB art budget); each can be downloaded"
             " again from its URL and rebuilt with `tools/art_build.py`.", "",
             "| raw file | job id | date | model | quality | refs | used for |",
             "|---|---|---|---|---|---|---|"]
    for key, e in src.items():
        lines.append("| `%s` | `%s` | %s | %s | %s | %s | %s |" % (
            e["file"], e["job"], e["date"], e["model"], e["quality"],
            ", ".join("`%s`" % r[:8] for r in e.get("refs", [])) or "-",
            ", ".join("`%s`" % u for u in e["used_for"])))
    lines.append("")
    lines.append("## Prompts")
    for key, e in src.items():
        lines += ["", "### %s" % e["file"], "",
                  "- job `%s`, %s, %s, %s, aspect %s, background %s" % (
                      e["job"], e["date"], e["model"], e["quality"],
                      e.get("aspect", "-"), e.get("background") or "default"),
                  "- session: %s" % e.get("session", "-"),
                  "- url: %s" % e["url"], "", "> " + e["prompt"]]
    with io.open(os.path.join(ROOT, "art_src", "SOURCES.md"), "w",
                 encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def main():
    global RAW
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw")
    # Only these layout keys, the rest of layout.json kept as it is: a new
    # sheet does not re-encode every atlas the game already ships.
    ap.add_argument("--only")
    args = ap.parse_args()
    RAW = raw_dir(args.raw)
    with io.open(SOURCES, encoding="utf-8") as f:
        src = json.load(f)
    for d in ["machines", "tiles", "world", "foreman"]:
        os.makedirs(os.path.join(OUT, d), exist_ok=True)
    lp = os.path.join(OUT, "layout.json")
    if args.only:
        with io.open(lp, encoding="utf-8") as f:
            layout = json.load(f)
        for key in args.only.split(","):
            print(key)
            layout[key] = SPRITE_SHEETS[key](src)
        with io.open(lp, "w", encoding="utf-8", newline="\n") as f:
            json.dump(layout, f, indent=1)
            f.write("\n")
        write_sources_md(src)
        print("wrote", lp)
        return

    layout = {"tile": {"w": 128, "h": 64}, "machines": {"order": MACHINE_ORDER,
              "sheets": {}}}
    for theme in THEMES:
        for tier in ["", "_up"]:
            key = "machines_" + theme + tier
            if key not in src:
                print("  no source for", key, "- skipped")
                continue
            print("machines", theme + tier)
            layout["machines"]["sheets"][theme + tier] = build_machine_atlas(
                load_raw(src, key), theme + tier)
    print("tiles")
    layout["tiles"] = build_tiles(load_raw(src, "tiles"))
    print("island")
    layout["island"] = build_island(load_raw(src, "island"))
    print("world")
    layout["world"] = build_world(load_raw(src, "world"))
    print("foreman")
    layout["foreman"] = build_foreman(load_raw(src, "foreman"))
    print("icons")
    layout["icons"] = build_icons(load_raw(src, "icons"))
    print("core")
    # The Factory Core is one machine-shaped sprite on a plate three cells
    # wide; the slicer treats it as a 1 x 1 sheet.
    layout["core"] = build_machine_atlas(load_raw(src, "core"), "core", 1, 1,
                                         "world", CORE_BASE_PX)
    print("props")
    layout["props"] = build_machine_atlas(load_raw(src, "props"), "props", 4, 2,
                                          "world", PROP_BASE_PX)
    layout["props"]["order"] = ["crystal_purple", "crystal_cyan", "ore_vein",
                                "rubble", "lamp", "lock", "crate", "vent"]

    # Hand-set numbers that no image can measure: where the board sits on the
    # island, how much of a cell a machine's plate covers, and the parallax.
    # Kept in the same file so the whole placement is in one place.
    prev = {}
    lp = os.path.join(OUT, "layout.json")
    if os.path.exists(lp):
        with io.open(lp, encoding="utf-8") as f:
            prev = json.load(f)
    layout["placement"] = prev.get("placement", {
        "slab_cells": 12, "board_offset": [1, 1], "footprint": 0.80,
        "parallax": 0.82, "board_lift": 10})
    with io.open(lp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(layout, f, indent=1)
        f.write("\n")
    write_sources_md(src)
    print("wrote", lp)


def build_band_worlds(src):
    """A painting for each band of the shaft -- the Surface, the Workings
    (the world painting, `build_world`), the Deep and the Abyss -- the same
    composition and size, so the camera frames them all alike."""
    files = []
    for band in ["surface", "workings", "deep", "abyss"]:
        if band == "workings":
            files.append("res://assets/art/world/workings.jpg")
            continue
        im = load_raw(src, "world_" + band).convert("RGB")
        im.save(os.path.join(OUT, "world", band + ".jpg"), "JPEG", quality=84, optimize=True,
                progressive=False)
        files.append("res://assets/art/world/%s.jpg" % band)
    return files


# The Rig's five poses (docs/GAME-LOOP.md), and the galleries' mouths with
# the crew's Bay: sheets built on their own (--only), or with the rest.
SPRITE_SHEETS = {
    "worlds": build_band_worlds,
    # The floor of each band, in build_tiles' layout: the Workings' is the
    # "tiles" sheet itself.
    "tiles_bands": lambda src: [
        build_tiles(load_raw(src, "tiles_surface"), "floor_surface")["file"],
        "res://assets/art/tiles/floor.jpg",
        build_tiles(load_raw(src, "tiles_deep"), "floor_deep")["file"],
        build_tiles(load_raw(src, "tiles_abyss"), "floor_abyss")["file"]],
    "crew": lambda src: build_sprites(load_raw(src, "crew"), "rig", 5, 1, "crew", 120,
                                      ["idle", "drive", "work", "carry", "worn"]),
    "galleries": lambda src: build_sprites(load_raw(src, "galleries"), "galleries", 2, 2, "world", 300,
                                           ["open", "boarded", "nest", "bay"]),
}


if __name__ == "__main__":
    sys.exit(main())
