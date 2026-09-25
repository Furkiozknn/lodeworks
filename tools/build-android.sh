#!/usr/bin/env bash
# Builds a signed Android App Bundle.
#
#   GODOT=/path/to/godot \
#   LODEWORKS_KEYSTORE=/path/to/release.keystore \
#   LODEWORKS_KEYSTORE_USER=upload \
#   LODEWORKS_KEYSTORE_PASSWORD=... \
#   tools/build-android.sh
#
# Credentials come from the environment and are injected at build time, because
# Godot writes them into export_presets.cfg in plain text and that file is
# committed. Nothing secret should ever end up in the repository.
set -euo pipefail

GODOT="${GODOT:-godot}"
OUT="${OUT:-build/lodeworks.aab}"
: "${LODEWORKS_KEYSTORE:?set LODEWORKS_KEYSTORE to your release keystore}"
: "${LODEWORKS_KEYSTORE_USER:?set LODEWORKS_KEYSTORE_USER}"
: "${LODEWORKS_KEYSTORE_PASSWORD:?set LODEWORKS_KEYSTORE_PASSWORD}"

mkdir -p "$(dirname "$OUT")"

# Work on a copy so the committed preset stays clean even if the build fails.
cp export_presets.cfg export_presets.cfg.bak
trap 'mv -f export_presets.cfg.bak export_presets.cfg' EXIT

# Injected into [preset.0.options] specifically, not appended to the file --
# there is a second preset after it now, and keys landing in the wrong section
# produce an unsigned bundle and no error at all.
python3 tools/_inject_keystore.py \
  "$LODEWORKS_KEYSTORE" "$LODEWORKS_KEYSTORE_USER" "$LODEWORKS_KEYSTORE_PASSWORD"

# Play refuses a bundle whose versionCode is not above the last one it took,
# and the committed preset says 1. The commit count only grows along the
# branch a release is built from; LODEWORKS_VERSION_CODE overrides it.
CODE="${LODEWORKS_VERSION_CODE:-$(git rev-list --count HEAD)}"
python3 - "$CODE" <<'PY'
import sys
code, section, out, done = sys.argv[1], None, [], False
for line in open("export_presets.cfg", encoding="utf-8"):
    if line.startswith("["):
        section = line.strip()
    if section == "[preset.0.options]" and line.startswith("version/code=") and not done:
        line, done = "version/code=%d\n" % int(code), True
    out.append(line)
if not done:
    sys.exit("version/code not found in [preset.0.options]")
open("export_presets.cfg", "w", encoding="utf-8").write("".join(out))
PY
echo "==> versionCode $CODE"

echo "==> tests"
"$GODOT" --headless --path . --script res://tests/test_runner.gd

echo "==> self test"
"$GODOT" --headless --path . --script res://tools/selftest_cli.gd

echo "==> export"
"$GODOT" --headless --path . --install-android-build-template \
  --export-release "Android" "$OUT"

# An export that produced nothing still exits zero often enough to be worth
# checking. A signed Godot bundle is tens of megabytes.
if [ ! -s "$OUT" ]; then
  echo "!! $OUT is empty -- the Gradle build did not produce a bundle" >&2
  exit 1
fi
size=$(stat -c%s "$OUT" 2>/dev/null || stat -f%z "$OUT")
if [ "$size" -lt 5000000 ]; then
  echo "!! $OUT is only $size bytes -- that is not a complete bundle" >&2
  exit 1
fi

echo "==> done: $OUT"
ls -lh "$OUT"
