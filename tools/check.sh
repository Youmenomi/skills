#!/bin/bash
# check.sh — run before committing and in CI.
#   1. every skills/*/SKILL.md has frontmatter and name == directory
#   2. version: semver X.Y.Z, assets/VERSION == skills/loop-run/VERSION, run-round.sh keeps the
#      @VERSION@ placeholder (filled on install), CHANGELOG has the section
#   3. change files: every changes/*.md declares type; on main there must be none pending
#      (main is always a released state); elsewhere a change under skills/loop-* needs one
#      (locally: working tree vs HEAD; in CI: CHECK_RANGE="<before>..HEAD")
#   4. shell syntax
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

V=$(cat skills/loop-init/assets/VERSION); RV=$(cat skills/loop-run/VERSION)
echo "loop-version: assets=$V loop-run=$RV"
echo "$V" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo "FAIL: assets/VERSION '$V' is not X.Y.Z"; fail=1; }
[ "$V" = "$RV" ] || { echo "FAIL: skills/loop-run/VERSION ($RV) != assets/VERSION ($V); use tools/release.sh"; fail=1; }
grep -q '^# loop-version: @VERSION@$' skills/loop-init/assets/run-round.sh || { echo "FAIL: assets/run-round.sh must keep '# loop-version: @VERSION@' on line 2"; fail=1; }
grep -q "^## loop-version $V " CHANGELOG.md || { echo "FAIL: CHANGELOG has no '## loop-version $V' section"; fail=1; }

pending=$(ls changes/*.md 2>/dev/null | grep -v README || true)
for f in $pending; do
  grep -qE '^type: *(patch|minor|major) *$' "$f" || { echo "FAIL: $f needs a 'type: patch|minor|major' line"; fail=1; }
done
BRANCH=${CHECK_BRANCH:-$(git branch --show-current 2>/dev/null || true)}
if [ "$BRANCH" = main ] && [ -n "$pending" ]; then
  echo "FAIL: main must not carry pending change files (release first):"; echo "$pending" | sed 's/^/  /'; fail=1
elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -n "${CHECK_RANGE:-}" ]; then
    changed=$(git diff --name-only "$CHECK_RANGE" -- skills/loop-init skills/loop-run 2>/dev/null || true)
    bumped=$(git diff --name-only "$CHECK_RANGE" -- skills/loop-init/assets/VERSION 2>/dev/null || true)
    if [ -n "$changed" ] && [ -z "$pending" ] && [ -z "$bumped" ]; then
      echo "FAIL: $CHECK_RANGE changes skills/loop-* without a changes/ file or a release:"; echo "$changed" | sed 's/^/  /'; fail=1
    fi
  elif ! git diff --quiet HEAD -- skills/loop-init skills/loop-run 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard skills/loop-init skills/loop-run)" ]; then
    # a working tree whose VERSION differs from HEAD is release.sh mid-flight: allowed
    if git diff --quiet HEAD -- skills/loop-init/assets/VERSION 2>/dev/null; then
      [ -n "$pending" ] || { echo "FAIL: skills/loop-* changed but changes/ has no pending file (add changes/<slug>.md with 'type:')"; fail=1; }
    fi
  fi
fi

bash -n skills/loop-init/assets/run-round.sh && bash -n skills/loop-init/assets/ctx-usage.sh && bash -n install.sh && bash -n tools/release.sh
[ "$fail" = 0 ] && echo "OK" || exit 1
