"""Check every generated store asset against Google Play's published specs.

    python3 tools/check-store-assets.py store

Run by tools/store-assets.sh after generation. It exists because the specs
are the kind of detail that is easy to satisfy by accident and easy to break
by accident -- the previous set of screenshots were 720x1440 32-bit PNGs, and
both of those are outside what Play accepts, which nobody noticed because the
images looked fine.

Specs, from support.google.com/googleplay/android-developer/answer/9866151:

  icon              512x512, 32-bit PNG, <= 1024 KB
  feature graphic   1024x500, JPEG or 24-bit PNG (no alpha)
  phone screenshot  JPEG or 24-bit PNG, 320-3840px per side, longest side no
                    more than twice the shortest; up to 8
  games eligibility at least 3 screenshots at 16:9 or 9:16 and >= 1080px
  large screen      at least 4, 1080-7680px, 16:9 or 9:16
"""
import re
import struct
import sys
from pathlib import Path

COLOR_TYPE = {0: "grey", 2: "rgb (24-bit)", 3: "indexed",
              4: "grey+alpha", 6: "rgba (32-bit)"}


def png_info(path):
    with open(path, "rb") as fh:
        head = fh.read(33)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    w, h, _depth, color = struct.unpack(">IIBB", head[16:26])
    return {"w": w, "h": h, "color": color, "bytes": path.stat().st_size}


def main(root):
    root = Path(root)
    problems = []
    notes = []

    icon = root / "brand" / "icon-512.png"
    info = png_info(icon) if icon.exists() else None
    if info is None:
        problems.append("brand/icon-512.png is missing")
    else:
        if (info["w"], info["h"]) != (512, 512):
            problems.append("icon must be 512x512, is %dx%d" % (info["w"], info["h"]))
        if info["bytes"] > 1024 * 1024:
            problems.append("icon is %d bytes, limit is 1024 KB" % info["bytes"])
        if info["color"] in (4, 6):
            problems.append(
                "icon has an alpha channel; Play masks the corners itself, so a "
                "pre-rounded icon is double-rounded")
        notes.append("icon 512x512 %s %d KB" %
                     (COLOR_TYPE.get(info["color"], "?"), info["bytes"] // 1024))

    feat = root / "brand" / "feature-1024x500.png"
    info = png_info(feat) if feat.exists() else None
    if info is None:
        problems.append("brand/feature-1024x500.png is missing -- Play will not "
                        "let the listing publish without one")
    else:
        if (info["w"], info["h"]) != (1024, 500):
            problems.append("feature graphic must be 1024x500, is %dx%d"
                            % (info["w"], info["h"]))
        if info["color"] in (4, 6):
            problems.append("feature graphic must have no alpha channel")
        notes.append("feature 1024x500 %s" % COLOR_TYPE.get(info["color"], "?"))

    for label, folder, want_min, floor in (
            ("phone", "screenshots", 2, 320),
            ("tablet", "screenshots-tablet", 4, 1080)):
        shots = sorted((root / folder).glob("*.png")) if (root / folder).exists() else []
        if len(shots) < want_min:
            problems.append("%s: %d screenshots, Play wants at least %d"
                            % (label, len(shots), want_min))
        if len(shots) > 8:
            problems.append("%s: %d screenshots, Play accepts at most 8"
                            % (label, len(shots)))
        eligible = 0
        for s in shots:
            info = png_info(s)
            if info is None:
                problems.append("%s is not a PNG" % s.name)
                continue
            if info["color"] in (4, 6):
                problems.append("%s/%s is %s; screenshots must be 24-bit with "
                                "no alpha" % (folder, s.name,
                                              COLOR_TYPE[info["color"]]))
            lo, hi = sorted((info["w"], info["h"]))
            if lo < floor:
                problems.append("%s/%s shortest side %dpx, minimum %d"
                                % (folder, s.name, lo, floor))
            if hi > 3840 and label == "phone":
                problems.append("%s/%s longest side %dpx, maximum 3840"
                                % (folder, s.name, hi))
            if hi > lo * 2:
                problems.append("%s/%s is %dx%d; the long side may not exceed "
                                "twice the short side" % (folder, s.name,
                                                          info["w"], info["h"]))
            ratio = hi / float(lo)
            if abs(ratio - 16.0 / 9.0) < 0.02 and lo >= 1080:
                eligible += 1
        need = 3 if label == "phone" else 4
        if eligible < need:
            problems.append("%s: %d screenshots are 16:9 or 9:16 at >=1080px; "
                            "games need %d to be eligible for Play's "
                            "recommendation surfaces" % (label, eligible, need))
        notes.append("%s: %d screenshots, %d eligible" % (label, len(shots), eligible))

    for extra in ("preview.mp4", "preview.gif"):
        pth = root / extra
        if pth.exists():
            notes.append("%s %d KB" % (extra, pth.stat().st_size // 1024))
        else:
            notes.append("%s not produced" % extra)

    # The words: every "(N max)" heading in listing.md is followed by the text
    # itself in a code block, and Play refuses a field over its limit.
    listing = root / "listing.md"
    if listing.exists():
        text = listing.read_text(encoding="utf-8")
        fields = re.findall(r"^#+ ([^\n]+?) \((\d+) max\)[ \t]*\n+```\n(.*?)\n```", text, re.S | re.M)
        for name, limit, body in fields:
            if len(body) > int(limit):
                problems.append("listing: %s is %d characters, limit %s"
                                % (name, len(body), limit))
            notes.append("listing: %s %d/%s" % (name, len(body), limit))
        if not fields:
            problems.append("listing.md has no '(N max)' fields to check")

    for n in notes:
        print("   " + n)
    if problems:
        print()
        for p in problems:
            print("!! " + p)
        return 1
    print("   every asset meets the published spec")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1] if len(sys.argv) > 1 else "store"))
