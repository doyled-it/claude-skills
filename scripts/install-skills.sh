#!/usr/bin/env bash
# Install this repo's skills into the discovery paths of every agent tool, so the
# SAME SKILL.md works in Claude Code, Codex, and opencode. The Agent Skills format
# is an open standard (agentskills.io); only the install location differs per tool:
#
#   Claude Code : this repo is a plugin marketplace (add it with /plugin), OR
#                 ~/.claude/skills/<name>
#   Codex       : ~/.agents/skills/<name>  (also scans .agents/skills up-tree)
#   opencode    : ~/.agents/skills/<name>  (and ~/.claude/skills)
#
# ~/.agents/skills is the cross-runtime home, so we symlink each skill there and
# into ~/.claude/skills. Symlinks keep one source of truth: edit the skill here,
# every tool sees the change. Re-run after adding a skill.
#
# Usage: bash scripts/install-skills.sh [--copy]
#   --copy  copy instead of symlink (for tools/filesystems that do not follow links)

set -euo pipefail
MODE="symlink"
[ "${1:-}" = "--copy" ] && MODE="copy"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGETS=("$HOME/.agents/skills" "$HOME/.claude/skills")

link_one() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  if [ "$MODE" = "copy" ]; then
    cp -R "$src" "$dest"; echo "  copied  -> $dest"
  else
    ln -s "$src" "$dest"; echo "  linked  -> $dest"
  fi
}

found=0
for skill_dir in "$REPO_ROOT"/plugins/*/skills/*/; do
  [ -f "$skill_dir/SKILL.md" ] || continue
  name="$(basename "$skill_dir")"
  echo "$name:"
  for t in "${TARGETS[@]}"; do
    link_one "${skill_dir%/}" "$t/$name"
  done
  found=$((found + 1))
done

echo
if [ "$found" -eq 0 ]; then
  echo "No skills found under $REPO_ROOT/plugins/*/skills/*/"
  exit 1
fi
echo "Installed $found skill(s) into: ${TARGETS[*]}"
echo "Claude Code can also use this repo as a plugin marketplace (run /plugin and add it)."
