#!/usr/bin/env bash
# Push this repository to a new, empty GitHub repository and start CI.
#
#   tools/push-to-github.sh git@github.com:<you>/lodeworks.git
#
# The repository has to exist and be empty first; creating it is the one step
# in this project that cannot be automated here (see docs/CI.md). Everything
# after this command is automatic.
set -euo pipefail

REMOTE="${1:-}"
if [ -z "$REMOTE" ]; then
  echo "usage: $0 <git remote url>" >&2
  echo "create an empty repository first -- private is fine" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ -n "$(git status --porcelain)" ]; then
  echo "!! the working tree has uncommitted changes:" >&2
  git status --short >&2
  echo "commit or stash them first; CI builds what is committed" >&2
  exit 1
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
echo "==> $(git rev-list --count HEAD) commits on '$branch', tree is clean"

if git remote | grep -qx origin; then
  current="$(git remote get-url origin)"
  if [ "$current" != "$REMOTE" ]; then
    echo "==> pointing origin at $REMOTE (was $current)"
    git remote set-url origin "$REMOTE"
  fi
else
  git remote add origin "$REMOTE"
fi

# Refuse to push over an existing history. A force push is never the right
# answer here and this script will not offer one.
if git ls-remote --heads origin 2>/dev/null | grep -q .; then
  echo "!! $REMOTE already has branches. This script only populates an empty" >&2
  echo "   repository; pushing over an existing history is a decision for a" >&2
  echo "   human, not for a script." >&2
  exit 1
fi

echo "==> pushing"
git push -u origin "$branch"

slug="$(printf '%s' "$REMOTE" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
cat <<DONE

==> done. Two workflows should now be starting:

    https://github.com/$slug/actions/workflows/ci.yml
    https://github.com/$slug/actions/workflows/android.yml

The android run produces two APKs as artifacts. Download
'lodeworks-apk-with-plugins', install it, and follow docs/DEVICE-TEST.md.

Nothing else needs doing for the build. The signed bundle needs three
repository secrets and a tag -- docs/CI.md has both.
DONE
