#!/usr/bin/env bash
# Fetch the two native Android plugins into addons/.
#
# They are deliberately NOT vendored in the repository: they are large
# prebuilt AAR bundles, they update on Google's schedule rather than ours, and
# every service in scripts/services/ is written to run without them. A build
# with no plugins is a valid build -- it just cannot show an ad or take a
# payment, and says so on the diagnostics screen.
#
#   tools/install-plugins.sh            # latest release of each
#   ADMOB_TAG=v5.1.0 BILLING_TAG=v3.3.0 tools/install-plugins.sh
#
# Writes addons/PLUGINS.lock with the exact tag, asset name and sha256 of
# everything it installed, so a build can be traced back to the bytes that
# went into it. Missing a plugin is not an error here: the script reports it
# and exits 0, because the build that follows is still a build worth having.
set -uo pipefail

ADMOB_REPO="poingstudios/godot-admob-plugin"
BILLING_REPO="godot-sdk-integrations/godot-google-play-billing"
ADMOB_TAG="${ADMOB_TAG:-latest}"
BILLING_TAG="${BILLING_TAG:-latest}"

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
  local label="$1" repo="$2" tag="$3"
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

  # Pick the first .zip asset. Both projects ship exactly one addon bundle per
  # release; if that ever stops being true this prints what it chose.
  local asset name
  asset="$(printf '%s' "$json" | python3 -c '
import json,sys
r = json.load(sys.stdin)
for a in r.get("assets", []):
    if a["name"].lower().endswith(".zip"):
        print(a["name"], a["browser_download_url"])
        break
' 2>/dev/null)"
  if [ -z "$asset" ]; then
    echo "!! $label: release $resolved has no .zip asset" >&2
    echo "$label MISSING no-zip-asset $resolved" >> "$lock"
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

  # Releases differ on whether the zip root is addons/ or the addon folder.
  if [ -d "$tmp/x/addons" ]; then
    cp -r "$tmp/x/addons/." "$root/addons/"
  else
    cp -r "$tmp/x/." "$root/addons/"
  fi
  rm -rf "$tmp"

  echo "$label $resolved $name sha256=$sum" >> "$lock"
  echo "   $label $resolved  ($name)"
}

echo "installing native plugins into addons/"
install_one admob   "$ADMOB_REPO"   "$ADMOB_TAG"
install_one billing "$BILLING_REPO" "$BILLING_TAG"

echo
echo "addons/PLUGINS.lock:"
cat "$lock"
if [ "$missing" -gt 0 ]; then
  echo
  echo "$missing plugin(s) not installed. The build will still run; ads and"
  echo "purchases will report 'not installed' on the diagnostics screen."
fi
exit 0
