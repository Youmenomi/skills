#!/bin/bash
# release.sh — release loop-init + loop-run from the pending change files.
#
#   changes/<slug>.md   frontmatter `type: patch|minor|major`, then one line for the CHANGELOG
#   bump = highest type among pending files (semver: patch = fix, minor = feature, major = incompatible)
#   guard: run-round.sh changed since the last tag  ⇒  a major change file is required
#          (repos hold a copy of run-round.sh; /loop-run refuses to start on a major mismatch)
#
# Run it on the dev branch with a clean tree. It bumps assets/VERSION and skills/loop-run/VERSION,
# rewrites CHANGELOG, removes the change files, commits, tags loop-v<X.Y.Z>, then fast-forwards
# main. Push yourself: git push origin dev main --follow-tags
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT"
pending=$(ls changes/*.md 2>/dev/null | grep -v README || true)
[ -n "$pending" ] || { echo "nothing to release: changes/ has no pending file"; exit 1; }
git diff --quiet HEAD -- . || { echo "commit or stash your working tree first"; exit 1; }
BR=$(git branch --show-current)

bump=patch
for f in $pending; do
  t=$(sed -nE 's/^type: *(patch|minor|major) *$/\1/p' "$f" | head -1)   # -E: BSD sed has no \| in BRE
  [ -n "$t" ] || { echo "FAIL: $f has no 'type: patch|minor|major' frontmatter line"; exit 1; }
  case "$t" in major) bump=major ;; minor) [ "$bump" = major ] || bump=minor ;; esac
done
OLD=$(cat skills/loop-init/assets/VERSION)
LASTTAG=$(git describe --tags --match 'loop-v*' --abbrev=0 2>/dev/null || true)
if [ -n "$LASTTAG" ] && ! git diff --quiet "$LASTTAG" HEAD -- skills/loop-init/assets/run-round.sh; then
  [ "$bump" = major ] || { echo "FAIL: run-round.sh changed since $LASTTAG; that needs a 'type: major' change file (repos keep a copy)"; exit 1; }
fi
IFS=. read -r MA MI PA <<< "$OLD"
case "$bump" in major) MA=$((MA+1)); MI=0; PA=0 ;; minor) MI=$((MI+1)); PA=0 ;; patch) PA=$((PA+1)) ;; esac
NEW="$MA.$MI.$PA"; DATE=$(date +%F)

{
  echo "# Changelog"; echo
  echo "## loop-version $NEW — $DATE ($bump)"; echo
  for f in $pending; do
    t=$(sed -nE 's/^type: *(.*) *$/\1/p' "$f" | head -1)
    body=$(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm!=1{print}' "$f" | sed '/^[[:space:]]*$/d' | tr '\n' ' ' | sed 's/ *$//')
    echo "- ($t) $body"
  done
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
if [ "$BR" != main ]; then git checkout -q main && git merge -q --ff-only "$BR" && git checkout -q "$BR"; fi
echo "released loop-version $NEW ($bump) → tag loop-v$NEW, main fast-forwarded."
echo "next: git push origin $BR main --follow-tags; ./install.sh; $([ "$bump" = major ] && echo 're-run /loop-init in every repo' || echo 'no repo action needed')"
