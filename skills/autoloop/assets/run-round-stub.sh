#!/bin/bash
# autoloop stub (version @VERSION@) — installed by /autoloop init. Do not edit.
# Runs the shared runner from the installed autoloop skill with this repo as the root.
# Lookup order: AUTOLOOP_HOME, then this repo's .claude/skills, then ~/.claude/skills.
cd "$(dirname "$0")/../.." || exit 2
for a in "${AUTOLOOP_HOME:-}" ".claude/skills/autoloop/assets" "$HOME/.claude/skills/autoloop/assets"; do
  [ -n "$a" ] && [ -x "$a/run-round.sh" ] && exec "$a/run-round.sh" "$@"
done
echo "autoloop stub: run-round.sh not found (install the autoloop skill, or set AUTOLOOP_HOME)" >&2; exit 2
