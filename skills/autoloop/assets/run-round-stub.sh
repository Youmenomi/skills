#!/bin/bash
# autoloop stub (major @MAJOR@) — installed by /autoloop init. Do not edit; it never changes.
# Runs the shared runner from the installed autoloop skill with this repo as the root.
cd "$(dirname "$0")/../.." || exit 2
exec "${AUTOLOOP_HOME:-$HOME/.claude/skills/autoloop/assets}/run-round.sh" "$@"
