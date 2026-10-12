#!/bin/bash
# release.sh — release autoloop from the pending change files.
#
#   changes/<slug>.md   frontmatter `type: patch|minor|major`, then one line for the CHANGELOG
#   bump = highest type among pending files (semver: patch = fix, minor = feature, major = incompatible)
#   every release needs /autoloop init in each repo: the stub carries the full version and
#   /autoloop run requires an exact match.
#
# Run it on the dev branch with a clean tree. It bumps skills/autoloop/assets/VERSION, rewrites
# CHANGELOG, removes the change files, commits, tags autoloop-v<X.Y.Z>, then fast-forwards main.
# Push yourself: git push origin dev main --follow-tags
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT"
A=skills/autoloop/assets
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
OLD=$(cat $A/VERSION)
IFS=. read -r MA MI PA <<< "$OLD"
case "$bump" in major) MA=$((MA+1)); MI=0; PA=0 ;; minor) MI=$((MI+1)); PA=0 ;; patch) PA=$((PA+1)) ;; esac
NEW="$MA.$MI.$PA"; DATE=$(date +%F)

{
  echo "# Changelog"; echo
  echo "## autoloop $NEW — $DATE ($bump)"; echo
  for f in $pending; do
    t=$(sed -nE 's/^type: *(.*) *$/\1/p' "$f" | head -1)
    body=$(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm!=1{print}' "$f" | sed '/^[[:space:]]*$/d' | tr '\n' ' ' | sed 's/ *$//')
    echo "- ($t) $body"
  done
  echo
  tail -n +2 CHANGELOG.md
} > CHANGELOG.new && mv CHANGELOG.new CHANGELOG.md
echo "$NEW" > $A/VERSION
git rm -q $pending
bash tools/check.sh
git add CHANGELOG.md $A/VERSION
git commit -qm "autoloop $NEW" -m "$(for f in $pending; do echo "- $(basename "$f" .md)"; done)"
git tag "autoloop-v$NEW"
if [ "$BR" != main ]; then git checkout -q main && git merge -q --ff-only "$BR" && git checkout -q "$BR"; fi
echo "released autoloop $NEW ($bump) → tag autoloop-v$NEW, main fast-forwarded."
echo "next: git push origin $BR main --follow-tags; ./install.sh; then /autoloop init in every repo (stub must match $NEW exactly)"
