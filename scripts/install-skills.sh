#!/usr/bin/env bash
# Install this repo's skills into the cross-runtime skills home so the SAME
# SKILL.md works in Codex, opencode, Copilot, and Gemini. The Agent Skills format
# is an open standard (agentskills.io); those tools discover global skills in
# ~/.agents/skills/<name>.
#
# We symlink ONLY into ~/.agents/skills, not ~/.claude/skills. Claude Code is
# handled as a plugin marketplace instead (see the development-loop install.sh,
# which runs `claude plugin install <name>@doyled-it-skills`). opencode reads BOTH
# ~/.agents/skills and ~/.claude/skills, so placing a skill in both homes would
# make opencode list it twice; keeping Claude Code on the plugin path avoids any
# duplication while still covering every tool.
#
# Symlinks keep one source of truth: edit the skill here, every tool sees it.
# Re-run after adding a skill.
#
# Usage: bash scripts/install-skills.sh [--copy]
#   --copy  copy instead of symlink (for tools/filesystems that do not follow links)

set -euo pipefail
MODE="symlink"
[ "${1:-}" = "--copy" ] && MODE="copy"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGETS=("$HOME/.agents/skills")

link_one() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  # Only replace our own managed symlinks. If something real (a directory, or a
  # skill the user authored by hand) sits at this name, do NOT clobber it: warn
  # and skip, so a name collision can never destroy the user's own work. Remove
  # it by hand if you want this repo's skill to take the name.
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "  skip    -> $dest (exists and is not a managed symlink; remove it to replace)"
    return 0
  fi
  rm -f "$dest"
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
