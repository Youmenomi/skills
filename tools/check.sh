#!/bin/bash
# check.sh — run before committing and in CI.
#   1. every skills/*/SKILL.md has frontmatter and name == directory
#   2. loop-version is consistent: assets/VERSION == skills/loop-run/VERSION, run-round.sh keeps
#      the @VERSION@ placeholder (loop-init stamps it on install), CHANGELOG has the entry
#   3. uncommitted or staged changes under skills/loop-*/ require a pending file in changes/
#   4. shell syntax of the scripts
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
RV=$(cat skills/loop-run/VERSION)
echo "loop-version: assets=$V loop-run=$RV"
[ "$V" = "$RV" ] || { echo "FAIL: skills/loop-run/VERSION ($RV) != assets/VERSION ($V); run tools/release.sh"; fail=1; }
grep -q '^# loop-version: @VERSION@$' skills/loop-init/assets/run-round.sh || { echo "FAIL: assets/run-round.sh must keep '# loop-version: @VERSION@' on line 2"; fail=1; }
grep -q "^## loop-version $V " CHANGELOG.md || { echo "FAIL: CHANGELOG has no '## loop-version $V' section"; fail=1; }

# Rule 3: a change to skills/loop-* needs a pending change file, unless the same change
# bumped the version (that is what release.sh produces).
#   locally: working tree vs HEAD        in CI: CHECK_RANGE="<before>..HEAD" (set by the workflow)
pending=$(ls changes/*.md 2>/dev/null | grep -v README || true)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -n "${CHECK_RANGE:-}" ]; then
    changed=$(git diff --name-only "$CHECK_RANGE" -- skills/loop-init skills/loop-run 2>/dev/null || true)
    bumped=$(git diff --name-only "$CHECK_RANGE" -- skills/loop-init/assets/VERSION 2>/dev/null || true)
    if [ -n "$changed" ] && [ -z "$pending" ] && [ -z "$bumped" ]; then
      echo "FAIL: $CHECK_RANGE changes skills/loop-* without a changes/ file or a version bump:"; echo "$changed" | sed 's/^/  /'; fail=1
    fi
  elif ! git diff --quiet HEAD -- skills/loop-init skills/loop-run 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard skills/loop-init skills/loop-run)" ]; then
    [ -n "$pending" ] || { echo "FAIL: skills/loop-* changed but changes/ has no pending file (add changes/<slug>.md, one line)"; fail=1; }
  fi
fi

bash -n skills/loop-init/assets/run-round.sh && bash -n skills/loop-init/assets/ctx-usage.sh && bash -n install.sh && bash -n tools/release.sh
[ "$fail" = 0 ] && echo "OK" || exit 1
