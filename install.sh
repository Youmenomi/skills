#!/bin/bash
# install.sh — copy skills/<name>/ into ~/.claude/skills/<name>/.
# Works from a clone (./install.sh) or piped from GitHub:
#   curl -fsSL https://raw.githubusercontent.com/Youmenomi/skills/main/install.sh | bash
set -eu
REPO=${SKILLS_REPO:-Youmenomi/skills}
DEST=${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}

SRC=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)
if [ -z "$SRC" ] || [ ! -d "$SRC/skills" ]; then
  # Not running from a clone: fetch the repository tarball into a temp dir.
  TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
  echo "downloading $REPO ..."
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP"
  SRC=$(ls -d "$TMP"/*/ | head -1)
fi

mkdir -p "$DEST"
installed=""
for d in "$SRC"/skills/*/; do
  name=$(basename "$d")
  [ -f "$d/SKILL.md" ] || continue
  rm -rf "$DEST/$name"
  cp -R "$d" "$DEST/$name"
  installed="$installed $name"
done
echo "installed:$installed → $DEST"
echo "next: in each repo you want to automate, run /loop-init in Claude Code, then /loop-run."
