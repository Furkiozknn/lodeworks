#!/usr/bin/env bash
# Fetch the two native Android plugins into addons/.
#
# They are deliberately NOT vendored in the repository: they are large
# prebuilt AAR bundles, they update on Google's schedule rather than ours, and
# every service in scripts/services/ is written to run without them. A build
# with no plugins is a valid build -- it just cannot show an ad or take a
# payment, and says so on the diagnostics screen.
#
#   tools/install-plugins.sh            # the pinned versions below
#   ADMOB_TAG=latest BILLING_TAG=latest tools/install-plugins.sh
#
# PINNED, not "latest": scripts/services/ads.gd and store.gd bind to these
# plugins' native singletons by method name, argument count and signal name,
# and tests/test_plugin_protocol.gd checks that wiring against stand-ins of
# exactly these versions. A newer release can rename any of it, and a wrong
# name fails silently on a phone. Moving a pin is a code change with a test
# run, not something a build does on its own.
#
# Writes addons/PLUGINS.lock with the exact tag, asset name and sha256 of
# everything it installed, so a build can be traced back to the bytes that
# went into it. Missing a plugin is not an error here: the script reports it
# and exits 0, because the build that follows is still a build worth having.
set -uo pipefail

ADMOB_REPO="poingstudios/godot-admob-plugin"
BILLING_REPO="godot-sdk-integrations/godot-google-play-billing"
ADMOB_TAG="${ADMOB_TAG:-v5.1.0}"
BILLING_TAG="${BILLING_TAG:-3.3.0}"
GODOT_VERSION="${GODOT_VERSION:-4.7.2}"

root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/addons"
lock="$root/addons/PLUGINS.lock"
: > "$lock"
missing=0

api() {
  # GITHUB_TOKEN lifts the 60/hour anonymous rate limit on CI. Optional.
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -sSL -H "Authorization: Bearer $GITHUB_TOKEN" "$1"
  else
    curl -sSL "$1"
  fi
}

install_one() {
  local label="$1" repo="$2" tag="$3" pattern="$4" dest="$5"
  local url
  if [ "$tag" = "latest" ]; then
    url="https://api.github.com/repos/$repo/releases/latest"
  else
    url="https://api.github.com/repos/$repo/releases/tags/$tag"
  fi

  local json
  json="$(api "$url")"
  local resolved
  resolved="$(printf '%s' "$json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name",""))' 2>/dev/null)"
  if [ -z "$resolved" ]; then
    echo "!! $label: no release found at $url" >&2
    echo "$label MISSING no-release" >> "$lock"
    missing=$((missing + 1))
    return 0
  fi

  # Pick the asset by name. The AdMob release carries twenty-odd zips (an
  # addon bundle plus Android and iOS binaries for every Godot version), so
  # "the first .zip" is the Android template for Godot 4.5.0 -- not the addon.
  local asset name
  asset="$(printf '%s' "$json" | PATTERN="$pattern" python3 -c '
import fnmatch, json, os, sys
r = json.load(sys.stdin)
pat = os.environ["PATTERN"]
for a in r.get("assets", []):
    if fnmatch.fnmatch(a["name"], pat):
        print(a["name"], a["browser_download_url"])
        break
' 2>/dev/null)"
  if [ -z "$asset" ]; then
    echo "!! $label: release $resolved has no asset matching $pattern" >&2
    echo "$label MISSING no-asset:$pattern $resolved" >> "$lock"
    missing=$((missing + 1))
    return 0
  fi
  name="${asset%% *}"
  url="${asset#* }"

  local tmp
  tmp="$(mktemp -d)"
  if ! curl -sSL -o "$tmp/p.zip" "$url"; then
    echo "!! $label: download failed" >&2
    echo "$label MISSING download-failed $resolved" >> "$lock"
    missing=$((missing + 1))
    return 0
  fi
  local sum
  sum="$(sha256sum "$tmp/p.zip" | cut -d' ' -f1)"
  unzip -q -o "$tmp/p.zip" -d "$tmp/x"

  mkdir -p "$dest"
  # The AdMob bundle nests the addon under poing-godot-admob/addons/; the
  # billing one is the addon folder itself; the AdMob Android binaries are
  # flat. Copy whichever shape arrived into the destination given.
  local inner
  inner="$(find "$tmp/x" -maxdepth 3 -type d -name addons | head -1)"
  if [ -n "$inner" ]; then
    cp -r "$inner/." "$dest/"
  else
    cp -r "$tmp/x/." "$dest/"
  fi
  rm -rf "$tmp"

  echo "$label $resolved $name sha256=$sum" >> "$lock"
  echo "   $label $resolved  ($name)"
}

echo "installing native plugins into addons/"
install_one admob "$ADMOB_REPO" "$ADMOB_TAG" "poing-godot-admob-v*.zip" "$root/addons"
# The AdMob addon's Android AARs, for this exact Godot version, where its
# export plugin looks for them. Installing them here rather than letting the
# addon fetch them at editor start keeps the bytes in PLUGINS.lock.
install_one admob-android "$ADMOB_REPO" "$ADMOB_TAG" \
  "android-template-v${GODOT_VERSION}.zip" "$root/addons/admob/android/bin"
install_one billing "$BILLING_REPO" "$BILLING_TAG" "godot-google-play-billing.zip" "$root/addons"

# An addon's export plugin -- the thing that puts its AAR and manifest entries
# into the Gradle build -- only runs if the addon is enabled. Enable whichever
# ones actually arrived, in the working copy only; the committed project
# stays plugin-free so a checkout without addons/ opens without errors.
python3 - "$root/project.godot" <<'PY'
import os, sys
path = sys.argv[1]
root = os.path.dirname(path)
want = []
for cfg in ("addons/admob/plugin.cfg", "addons/GodotGooglePlayBilling/plugin.cfg"):
    if os.path.exists(os.path.join(root, cfg)):
        want.append("res://" + cfg)
text = open(path, encoding="utf-8").read()
lines = text.splitlines()
out, skip = [], False
for ln in lines:
    if ln.strip() == "[editor_plugins]":
        skip = True
        continue
    if skip and ln.startswith("["):
        skip = False
    if skip:
        continue
    out.append(ln)
if want:
    while out and out[-1] == "":
        out.pop()
    out += ["", "[editor_plugins]", "",
            "enabled=PackedStringArray(%s)" % ", ".join('"%s"' % w for w in want)]
open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
print("enabled editor plugins:", ", ".join(want) or "none")
PY

echo
echo "addons/PLUGINS.lock:"
cat "$lock"
if [ "$missing" -gt 0 ]; then
  echo
  echo "$missing plugin(s) not installed. The build will still run; ads and"
  echo "purchases will report 'not installed' on the diagnostics screen."
fi
exit 0
