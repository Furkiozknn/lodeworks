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

cat >> export_presets.cfg <<PRESET
keystore/release="${LODEWORKS_KEYSTORE}"
keystore/release_user="${LODEWORKS_KEYSTORE_USER}"
keystore/release_password="${LODEWORKS_KEYSTORE_PASSWORD}"
PRESET

echo "==> tests"
"$GODOT" --headless --path . --script res://tests/test_runner.gd

echo "==> export"
"$GODOT" --headless --path . --export-release "Android" "$OUT"

echo "==> done: $OUT"
ls -lh "$OUT"
