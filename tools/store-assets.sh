#!/usr/bin/env bash
# Regenerate every store asset from the running game.
#
#   GODOT=/path/to/godot4.7.2 tools/store-assets.sh
#
# Produces, into store/:
#   screenshots/       8 landscape phone shots at 1920x1080, 24-bit, plus alt text
#   screenshots-tablet/ 8 landscape tablet shots at 2560x1440
#   brand/             icon 512 and 192, adaptive foreground, feature graphic
#   preview.mp4        a landscape gameplay capture for the Play preview video
#   preview.gif        the same, short, for anywhere a video will not embed
#
# Nothing here is composited, painted or retouched. Every image is the game
# rendering itself, and the boards shown are the ones the test suite verifies.
# A listing that shows something the app does not do is both a Play policy
# problem and the setup for the review that follows.
set -euo pipefail

GODOT="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
USERDIR="${USERDIR:-$HOME/.local/share/godot/app_userdata/Lodeworks}"
RUN=(xvfb-run -a)
if [ -n "${NO_XVFB:-}" ]; then RUN=(); fi

rm -rf "$USERDIR/shots" "$USERDIR/reel" "$USERDIR/brand" "$USERDIR/shots-tablet"

mkdir -p "$ROOT/store"
rm -rf "$ROOT/store/screenshots" "$ROOT/store/screenshots-tablet" "$ROOT/store/brand"
mkdir -p "$ROOT/store/screenshots" "$ROOT/store/screenshots-tablet" "$ROOT/store/brand"

echo "==> phone screenshots and video frames (1920x1080)"
"${RUN[@]}" "$GODOT" --path "$ROOT" --resolution 1920x1080 \
  --rendering-driver opengl3 tools/shots.tscn
cp "$USERDIR"/shots/*.png "$USERDIR"/shots/*.tsv "$ROOT/store/screenshots/"

echo "==> tablet screenshots (2560x1440)"
# Play wants at least four large-screen shots, 16:9 or 9:16, 1080-7680px.
rm -rf "$USERDIR/shots"
LODEWORKS_SHOTS_ONLY=1 "${RUN[@]}" "$GODOT" --path "$ROOT" \
  --resolution 2560x1440 --rendering-driver opengl3 tools/shots.tscn
cp "$USERDIR"/shots/*.png "$ROOT/store/screenshots-tablet/"

echo "==> icon and feature graphic"
"${RUN[@]}" "$GODOT" --path "$ROOT" --rendering-driver opengl3 tools/brand.tscn
cp "$USERDIR"/brand/*.png "$ROOT/store/brand/"

echo "==> video"
mkdir -p "$ROOT/store"
if command -v ffmpeg >/dev/null 2>&1; then
  # H.264, yuv420p, even dimensions: the combination every player accepts.
  ffmpeg -y -loglevel error -framerate 20 -i "$USERDIR/reel/f%04d.png" \
    -vf "scale=1280:-2" -c:v libx264 -pix_fmt yuv420p -crf 20 \
    "$ROOT/store/preview.mp4"
  # A palette pass, or the gif bands badly on this palette.
  ffmpeg -y -loglevel error -framerate 20 -i "$USERDIR/reel/f%04d.png" \
    -vf "fps=14,scale=640:-2:flags=lanczos,palettegen=stats_mode=diff" \
    "$USERDIR/reel/palette.png"
  ffmpeg -y -loglevel error -framerate 20 -i "$USERDIR/reel/f%04d.png" \
    -i "$USERDIR/reel/palette.png" \
    -lavfi "fps=14,scale=640:-2:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" \
    "$ROOT/store/preview.gif"
else
  echo "   ffmpeg not found -- frames are in $USERDIR/reel, video skipped"
fi

echo
echo "==> verifying against Play's specs"
python3 "$ROOT/tools/check-store-assets.py" "$ROOT/store"
