#!/bin/bash
# release.sh — bump loop-version from the pending change files.
#   changes/<slug>.md (one line each, written when you change skills/loop-*) are merged into a
#   new CHANGELOG section, VERSION is incremented in assets/VERSION and skills/loop-run/VERSION,
#   the change files are removed, check.sh runs, then one commit + tag loop-v<N>. Push yourself.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT"
pending=$(ls changes/*.md 2>/dev/null | grep -v README || true)
[ -n "$pending" ] || { echo "nothing to release: changes/ has no pending file"; exit 1; }
git diff --quiet HEAD -- . || { echo "commit or stash your working tree first (release makes its own commit)"; exit 1; }

OLD=$(cat skills/loop-init/assets/VERSION); NEW=$((OLD + 1)); DATE=$(date +%F)
{
  echo "# Changelog"; echo
  echo "## loop-version $NEW — $DATE"; echo
  for f in $pending; do echo "- $(sed -e 's/^[-* ]*//' "$f" | tr '\n' ' ' | sed 's/ *$//')"; done
  echo
  tail -n +2 CHANGELOG.md
} > CHANGELOG.new && mv CHANGELOG.new CHANGELOG.md
echo "$NEW" > skills/loop-init/assets/VERSION
echo "$NEW" > skills/loop-run/VERSION
git rm -q $pending
bash tools/check.sh
git add CHANGELOG.md skills/loop-init/assets/VERSION skills/loop-run/VERSION
git commit -qm "loop-version $NEW" -m "$(for f in $pending; do echo "- $(basename "$f" .md)"; done)"
git tag "loop-v$NEW"
echo "released loop-version $NEW (tag loop-v$NEW). Next: git push --follow-tags; then re-run /loop-init in each repo."
