#!/usr/bin/env bash
# Install the development loop so the model always reaches for the right tools.
# Three parts:
#   1. Ensure the composed superpowers skills are installed and current (the loop
#      references them by name), via the claude plugin CLI when available.
#   2. Make every skill in this repo available to all tools (symlink into their
#      discovery paths), by delegating to the repo's scripts/install-skills.sh.
#   3. Write a managed "development conventions" block into your GLOBAL agent
#      instructions, so the always-on habits (codegraph for understanding, the
#      loop for features/bugfixes, cross-repo verification) load every session
#      regardless of whether a skill auto-activates.
#
# The block is delimited by markers and is tool-agnostic, so re-running updates it
# in place (no duplication) and you can paste the same block into any tool's global
# config (Claude Code: ~/.claude/CLAUDE.md; Codex: ~/.codex/AGENTS.md; opencode:
# your global AGENTS.md). This script writes it to ~/.claude/CLAUDE.md by default.
#
# Usage: bash install.sh [--global-file PATH] [--print-only]

set -euo pipefail
GLOBAL_FILE="$HOME/.claude/CLAUDE.md"
PRINT_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --global-file) GLOBAL_FILE="$2"; shift 2 ;;
    --print-only) PRINT_ONLY=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

BEGIN="<!-- BEGIN doyled-it:development-conventions (managed by claude-skills/development-loop) -->"
END="<!-- END doyled-it:development-conventions -->"

read -r -d '' BLOCK <<'EOF' || true
## Development conventions

- ALWAYS understand code through codegraph before changing it. In a codegraph-indexed
  repo (a `.codegraph/` directory), sync the index first, confirm it is the repo you
  are editing, then query symbols / callers / callees / impact instead of grep or find,
  especially before spawning subagents that explore code. A stale or wrong-repo index
  is worse than none; re-sync often and after your own edits.
- For ANY feature or bugfix, follow the development loop before writing code:
  understand (codegraph) -> brainstorm and design -> plan -> implement with TDD -> finish.
  Do not jump straight to implementation.
- For a MULTI-REPO project, start from the hub (integration or deploy) repo with the
  sibling repos checked out alongside it, and verify the change's full cross-repo
  surface (API -> client -> UI -> docs, plus config, deploy, and docs in each repo)
  before calling it done.
- Reach for the `development-loop`, `codegraph`, and `cross-repo-completeness` skills
  by name when the task matches; do not wait to be asked.
EOF

FULL_BLOCK="$BEGIN
$BLOCK
$END"

if [ "$PRINT_ONLY" = 1 ]; then
  printf '%s\n' "$FULL_BLOCK"
  exit 0
fi

# 1. Ensure the composed superpowers skills are installed and current. The loop
#    references superpowers skills by name, so they must be present. On Claude Code
#    they install as a plugin from the claude-plugins-official marketplace; refresh
#    the catalog, then update (or install if missing). A restart applies the update.
if command -v claude >/dev/null 2>&1; then
  echo "Ensuring superpowers is installed and up to date..."
  claude plugin marketplace update claude-plugins-official >/dev/null 2>&1 || true
  if claude plugin update superpowers >/dev/null 2>&1; then
    echo "  superpowers updated (restart your tool to apply)"
  elif claude plugin install superpowers@claude-plugins-official -y >/dev/null 2>&1; then
    echo "  superpowers installed (restart your tool to apply)"
  else
    echo "  (could not auto-install superpowers; run: claude plugin install superpowers@claude-plugins-official)"
  fi
else
  echo "Note: 'claude' CLI not found; install the superpowers skills for your tool:"
  echo "  Claude Code     : claude plugin install superpowers@claude-plugins-official"
  echo "  Codex / opencode: clone github.com/obra/superpowers and symlink its skills/* into ~/.agents/skills"
fi

# 2. Cross-tool skill install (delegate if available).
REPO_ROOT="$(cd "$(dirname "$0")/../../../../.." && pwd)"
if [ -f "$REPO_ROOT/scripts/install-skills.sh" ]; then
  echo "Installing skills into tool paths..."
  bash "$REPO_ROOT/scripts/install-skills.sh" || echo "  (skill symlinking step reported an issue; continuing)"
else
  echo "Note: $REPO_ROOT/scripts/install-skills.sh not found; skipping skill symlinking."
fi

# 3. Managed global-conventions block (idempotent via markers).
mkdir -p "$(dirname "$GLOBAL_FILE")"
touch "$GLOBAL_FILE"
if grep -qF "$BEGIN" "$GLOBAL_FILE"; then
  tmp="$(mktemp)"
  awk -v b="$BEGIN" -v e="$END" -v repl="$FULL_BLOCK" '
    $0==b {print repl; skip=1; next}
    $0==e {skip=0; next}
    skip!=1 {print}
  ' "$GLOBAL_FILE" > "$tmp"
  # Write back in place (not mv) so the file keeps its own permissions; mv would
  # give it mktemp's 0600 and silently tighten a 0644 global-instructions file.
  cat "$tmp" > "$GLOBAL_FILE"
  rm -f "$tmp"
  echo "Updated the development-conventions block in $GLOBAL_FILE"
else
  printf '\n%s\n' "$FULL_BLOCK" >> "$GLOBAL_FILE"
  echo "Added the development-conventions block to $GLOBAL_FILE"
fi

echo
echo "Done. For Codex or opencode, paste the same block into their global config"
echo "(re-run with --print-only to print it)."
