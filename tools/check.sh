#!/bin/bash
# check.sh — sanity checks before committing: SKILL.md frontmatter and loop-version consistency.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT"
fail=0
for f in skills/*/SKILL.md; do
  head -1 "$f" | grep -q '^---$' || { echo "FAIL $f: no frontmatter"; fail=1; }
  grep -q '^name: ' "$f" || { echo "FAIL $f: no name"; fail=1; }
  grep -q '^description: ' "$f" || { echo "FAIL $f: no description"; fail=1; }
  n=$(grep -m1 '^name: ' "$f" | sed 's/^name: *//; s/"//g'); d=$(basename "$(dirname "$f")")
  [ "$n" = "$d" ] || { echo "FAIL $f: name '$n' != directory '$d'"; fail=1; }
done
V=$(cat skills/loop-init/assets/VERSION)
RV=$(grep -m1 '^# loop-version:' skills/loop-init/assets/run-round.sh | sed 's/.*: *//')
IV=$(grep -o -m1 'loop-version [0-9]*' skills/loop-init/SKILL.md | head -1 | awk '{print $2}')
LV=$(grep -o -m1 'loop-version [0-9]*' skills/loop-run/SKILL.md | head -1 | awk '{print $2}')
echo "loop-version: assets=$V run-round=$RV loop-init=$IV loop-run=$LV"
[ "$V" = "$RV" ] && [ "$V" = "$IV" ] && [ "$V" = "$LV" ] || { echo "FAIL: loop-version mismatch"; fail=1; }
grep -q "loop-version $V" CHANGELOG.md || { echo "FAIL: CHANGELOG has no entry for loop-version $V"; fail=1; }
bash -n skills/loop-init/assets/run-round.sh && bash -n skills/loop-init/assets/ctx-usage.sh && bash -n install.sh
[ "$fail" = 0 ] && echo "OK" || exit 1
