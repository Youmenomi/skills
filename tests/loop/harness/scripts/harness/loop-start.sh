#!/bin/bash
# Mini loop-start (stand-in for the real loop-start.mjs in the project repos).
# Exit 0 = work assigned (lock written); 3 = stop condition; 4 = STOP file or live lock.
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd); cd "$ROOT" || exit 2
LOCK=.loop.lock
[ -e STOP ] && { echo "END ROUND (write nothing, commit nothing): STOP file present"; exit 4; }
if [ -f "$LOCK" ]; then
  age=$(( ( $(date +%s) - $(stat -f %m "$LOCK") ) / 60 ))
  if [ "$age" -lt 30 ]; then echo "END ROUND (write nothing, commit nothing): .loop.lock heartbeat ${age} min old: another round in progress"; exit 4; fi
  echo "== stale lock (${age} min) removed =="; cat "$LOCK"; rm -f "$LOCK"
fi
printf 'started: %s\nslice: (deciding)\npid: %s\n' "$(date -u +%FT%TZ)" "$PPID" > "$LOCK"
echo "== git status =="; git status --porcelain || true
echo "== git log -5 =="; git log --oneline -5 2>/dev/null || echo "(no commits)"
echo "== NEEDS-USER OPEN =="; grep -E '^### .* — OPEN — ' docs/progress/NEEDS-USER.md || echo "(none)"
if grep -qE '^### .* — OPEN — AUTH' docs/progress/NEEDS-USER.md; then
  rm -f "$LOCK"; echo; echo "STOP CONDITION: an AUTH item is OPEN and waits for the user"; exit 3
fi
echo "== PLAN next =="
next=$(grep -E '^### .* — TODO$' docs/progress/PLAN.md | head -1)
if [ -z "$next" ]; then rm -f "$LOCK"; echo; echo "STOP CONDITION: PLAN has no TODO"; exit 3; fi
echo "$next"
echo "== heartbeat: touch .loop.lock before each long step =="
exit 0
