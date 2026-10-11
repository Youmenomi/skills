#!/bin/bash
# Fake gate for the mini harness. Checks that work/<id>.txt exists and is non-empty.
#   gate.sh <id>                 normal check
#   gate.sh <id> --leave-process also leaves a detached `sleep 3600` behind (cleanup test)
#   gate.sh <id> --hang          hangs for 10 minutes (timeout test)
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd); cd "$ROOT" || exit 2
ID=${1:?id}; MODE=${2:-}
case "$MODE" in
  --leave-process) nohup sleep 3600 >/dev/null 2>&1 & echo "gate: left sleep pid $! running (on purpose)" ;;
  --hang) echo "gate: hanging for 600s (on purpose)"; sleep 600 ;;
esac
if [ -s "work/$ID.txt" ]; then echo "gate $ID: PASS"; exit 0; else echo "gate $ID: FAIL (work/$ID.txt missing or empty)"; exit 1; fi
