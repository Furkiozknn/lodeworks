"""Measure the art: what it costs on disk, in the package, and in memory.

    uv run --no-project --with pillow python tools/asset_budget.py [--md FILE]

Three different numbers, never to be confused:

  repo     bytes of the committed file (the 40 MB art budget)
  package  bytes of what Godot imported and will pack (.godot/imported/*.ctex)
  vram     what the texture occupies on the GPU once loaded -- estimated from
           its size, its import mode and its mipmaps. An estimate, labelled as
           one: the true figure is a device measurement (RENDER_TEXTURE_MEM_USED
           in tools/perf_probe.gd), and on a phone it is UNKNOWN until someone
           runs it there.

Exits 1 if the committed art is over budget.
"""
import argparse
import glob
import io
import json
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art")
BUDGET_MB = 40.0

# Bytes per pixel on the GPU for each Godot import mode. VRAM-compressed is
# ETC2/ASTC 4x4 on phones: 1 byte/px with alpha, 0.5 without (ETC2 RGB).
MODES = {0: "lossless", 1: "lossy", 2: "vram", 3: "vram-uncompressed", 4: "basis"}


def import_params(path):
    """The [params] and dest_files of a Godot .import file. Not an INI file --
    its metadata value spans lines -- so read as plain key=value lines."""
    p = path + ".import"
    out = {}
    if not os.path.exists(p):
        return out
    section = ""
    with io.open(p, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("[") and line.endswith("]"):
                section = line[1:-1]
            elif "=" in line and section in ("params", "deps"):
                k, v = line.split("=", 1)
                out[("_dest" if k == "dest_files" else k)] = v.strip('"')
    if "_dest" in out:
        out["_dest"] = "[" + out["_dest"].strip("[]") + "]"
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--md")
    args = ap.parse_args()
    with io.open(os.path.join(ROOT, "art_src", "sources.json"), encoding="utf-8") as f:
        src = json.load(f)
    used_by = {}
    for k, e in src.items():
        for u in e.get("used_for", []):
            used_by[u.replace("\\", "/")] = k

    rows = []
    for path in sorted(glob.glob(os.path.join(ART, "**", "*.*"), recursive=True)):
        if path.endswith((".import", ".json")):
            continue
        rel = os.path.relpath(path, ROOT).replace("\\", "/")
        im = Image.open(path)
        w, h = im.size
        alpha = im.mode in ("RGBA", "LA") or "transparency" in im.info
        params = import_params(path)
        mode = int(params.get("compress/mode", 0))
        mips = params.get("mipmaps/generate", "false") == "true"
        bpp = {2: 1.0 if alpha else 0.5}.get(mode, 4.0)
        vram = w * h * bpp * (4.0 / 3.0 if mips else 1.0)
        pack = 0
        for d in json.loads(params.get("_dest", "[]") or "[]"):
            fp = os.path.join(ROOT, d.replace("res://", ""))
            # Of the per-platform variants only one ships on a phone (etc2).
            if os.path.exists(fp) and (".s3tc." not in fp):
                pack = max(pack, os.path.getsize(fp))
        rows.append({"file": rel, "repo": os.path.getsize(path), "format": im.format,
                     "size": "%dx%d" % (w, h), "alpha": alpha, "mode": MODES.get(mode, mode),
                     "mips": mips, "vram": vram, "package": pack,
                     "source": used_by.get(rel, "UNSOURCED")})

    total_repo = sum(r["repo"] for r in rows)
    total_vram = sum(r["vram"] for r in rows)
    total_pack = sum(r["package"] for r in rows)
    # What is resident at once: one machine sheet (a palette at a tier), not
    # all twelve.
    sheets = [r for r in rows if "/machines/" in r["file"]]
    resident = total_vram - sum(r["vram"] for r in sheets) + (max((r["vram"] for r in sheets), default=0))

    lines = ["| file | repo KB | format | pixels | alpha | import | mips | package KB | VRAM KB (est.) | source |",
             "|---|---:|---|---|---|---|---|---:|---:|---|"]
    for r in rows:
        lines.append("| `%s` | %d | %s | %s | %s | %s | %s | %d | %d | %s |" % (
            r["file"], r["repo"] // 1024, r["format"], r["size"], "yes" if r["alpha"] else "no",
            r["mode"], "yes" if r["mips"] else "no", r["package"] // 1024, r["vram"] // 1024,
            r["source"]))
    lines += ["", "- repo total: **%.2f MB** of a %.0f MB budget" % (total_repo / 1048576.0, BUDGET_MB),
              "- imported (package) total: %.2f MB" % (total_pack / 1048576.0),
              "- VRAM if every file were loaded: %.1f MB (estimate)" % (total_vram / 1048576.0),
              "- VRAM resident in play (world, island, tiles, props, core, icons, foreman "
              "and ONE machine sheet): %.1f MB (estimate)" % (resident / 1048576.0)]
    text = "\n".join(lines)
    print(text)
    if args.md:
        with io.open(args.md, "w", encoding="utf-8", newline="\n") as f:
            f.write(text + "\n")
    bad = [r["file"] for r in rows if r["source"] == "UNSOURCED"]
    if bad:
        print("UNSOURCED:", ", ".join(bad))
    return 1 if total_repo / 1048576.0 > BUDGET_MB or bad else 0


if __name__ == "__main__":
    sys.exit(main())
