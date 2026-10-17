#!/usr/bin/env bash
# Install the development loop so the model always reaches for the right tools.
# Five parts:
#   1. Ensure the composed superpowers skills are installed and current (the loop
#      references them by name), from obra's upstream marketplace, via the claude
#      plugin CLI when available.
#   2. Ensure the codegraph CLI is installed and current
#      (github.com/colbymchenry/codegraph), with its MCP server wired into every
#      detected agent and its usage telemetry turned off. The loop's Understand
#      phase needs the tool, not just the skill that describes it.
#   3. Register this repo's plugins for Claude Code (its native plugin path).
#   4. Make this repo's skills available to the OTHER tools (Codex, opencode,
#      Copilot, Gemini) by symlinking into ~/.agents/skills, via the repo's
#      scripts/install-skills.sh. Claude Code is NOT symlinked (step 3 covers it),
#      so tools that read both skill homes never list a skill twice.
#   5. Write a managed "development conventions" block into your GLOBAL agent
#      instructions, so the always-on habits (codegraph for understanding, the
#      loop for features/bugfixes, cross-repo verification) load every session
#      regardless of whether a skill auto-activates.
#
# The block is delimited by markers and is tool-agnostic, so re-running updates it
# in place (no duplication) and you can paste the same block into any tool's global
# config (Claude Code: ~/.claude/CLAUDE.md; Codex: ~/.codex/AGENTS.md; opencode:
# your global AGENTS.md). This script writes it to ~/.claude/CLAUDE.md by default.
#
# Usage: bash install.sh [--global-file PATH] [--print-only] [--skip-codegraph]
#                        [--keep-codegraph-telemetry]

set -euo pipefail
GLOBAL_FILE="$HOME/.claude/CLAUDE.md"
PRINT_ONLY=0
SKIP_CODEGRAPH=0
KEEP_CG_TELEMETRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --global-file) GLOBAL_FILE="$2"; shift 2 ;;
    --print-only) PRINT_ONLY=1; shift ;;
    --skip-codegraph) SKIP_CODEGRAPH=1; shift ;;
    --keep-codegraph-telemetry) KEEP_CG_TELEMETRY=1; shift ;;
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
  is worse than none; re-sync often and after your own edits. If the `codegraph`
  command is missing, install it (github.com/colbymchenry/codegraph, npm package
  `@colbymchenry/codegraph`) rather than falling back to grep.
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

# 1. Ensure superpowers is installed from obra's UPSTREAM marketplace (7.x), not
#    the slower Anthropic-curated channel. Install from obra FIRST; only once that
#    succeeds, drop any claude-plugins-official copy so superpowers is registered
#    once. If obra is unreachable, the existing install is left intact rather than
#    removed. A restart applies the change.
SP_MP="superpowers-marketplace"
if command -v claude >/dev/null 2>&1; then
  echo "Ensuring superpowers (obra upstream) is installed and up to date..."
  # `add` fetches the catalog on first use; only refresh (update) if already added,
  # so a fresh install does not fetch the same catalog twice.
  claude plugin marketplace add obra/superpowers-marketplace >/dev/null 2>&1 \
    || claude plugin marketplace update "$SP_MP" >/dev/null 2>&1 || true
  if claude plugin install "superpowers@$SP_MP" -y >/dev/null 2>&1; then
    # obra copy is registered; now drop the Anthropic-curated one so it is registered once.
    claude plugin uninstall "superpowers@claude-plugins-official" >/dev/null 2>&1 || true
    # `plugin install` is a no-op (still exit 0) when already present, so update
    # explicitly to pull obra's latest on a re-run.
    claude plugin update superpowers >/dev/null 2>&1 || true
    echo "  superpowers installed and current from $SP_MP (restart your tool to apply)"
  else
    echo "  (could not install superpowers from $SP_MP; left any existing install intact)"
    echo "   run: claude plugin marketplace add obra/superpowers-marketplace && claude plugin install superpowers@$SP_MP"
  fi
else
  echo "Note: 'claude' CLI not found; install superpowers for your tool:"
  echo "  Claude Code     : claude plugin marketplace add obra/superpowers-marketplace && claude plugin install superpowers@superpowers-marketplace"
  echo "  Codex / opencode: clone github.com/obra/superpowers and symlink its skills/* into ~/.agents/skills"
fi

# 2. Ensure the codegraph CLI (github.com/colbymchenry/codegraph). npm is preferred
#    because its releases carry npm provenance; without npm, fall back to the
#    project's own installer, which links the binary into ${CODEGRAPH_BIN_DIR:-~/.local/bin}.
#    An existing install is upgraded in place (`codegraph upgrade` also refreshes the
#    agent wiring). A fresh install wires the MCP server into every detected agent.
#    Telemetry goes off first so nothing is sent from the first run; pass
#    --keep-codegraph-telemetry to leave the upstream default alone.
CG_PKG="@colbymchenry/codegraph"
CG_INSTALLER="https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh"
CG_BIN=""
if [ "$SKIP_CODEGRAPH" = 1 ]; then
  echo "Skipping the codegraph CLI (--skip-codegraph)."
elif command -v codegraph >/dev/null 2>&1; then
  CG_BIN="$(command -v codegraph)"
  echo "Ensuring the codegraph CLI is current..."
  if "$CG_BIN" upgrade >/dev/null 2>&1; then
    echo "  codegraph $("$CG_BIN" --version) is current"
  else
    echo "  (could not upgrade codegraph; left the installed version in place)"
  fi
else
  echo "Installing the codegraph CLI (github.com/colbymchenry/codegraph)..."
  if command -v npm >/dev/null 2>&1 && npm install -g "$CG_PKG" >/dev/null 2>&1; then
    CG_BIN="$(command -v codegraph || true)"
  elif command -v curl >/dev/null 2>&1 && curl -fsSL "$CG_INSTALLER" | sh >/dev/null 2>&1; then
    # The installer links into a dir that may not be on this shell's PATH yet.
    CG_BIN="$(command -v codegraph || echo "${CODEGRAPH_BIN_DIR:-$HOME/.local/bin}/codegraph")"
  fi
  if [ -n "$CG_BIN" ] && [ -x "$CG_BIN" ]; then
    [ "$KEEP_CG_TELEMETRY" = 1 ] || "$CG_BIN" telemetry off >/dev/null 2>&1 || true
    if "$CG_BIN" install --yes >/dev/null 2>&1; then
      echo "  installed codegraph $("$CG_BIN" --version) and wired it into your agents (restart them to load the MCP server)"
    else
      echo "  installed codegraph $("$CG_BIN" --version); wiring agents failed, run: codegraph install"
    fi
    case ":$PATH:" in
      *":$(dirname "$CG_BIN"):"*) ;;
      *) echo "  note: add $(dirname "$CG_BIN") to your PATH so 'codegraph' resolves in new shells" ;;
    esac
  else
    CG_BIN=""
    echo "  (could not install codegraph; install it by hand:"
    echo "     npm install -g $CG_PKG"
    echo "     or: curl -fsSL $CG_INSTALLER | sh   then: codegraph install)"
  fi
fi
# Re-assert the telemetry choice on every run, so an upgrade cannot quietly reset it.
if [ -n "$CG_BIN" ] && [ "$KEEP_CG_TELEMETRY" = 0 ]; then
  "$CG_BIN" telemetry off >/dev/null 2>&1 || true
fi

REPO_ROOT="$(cd "$(dirname "$0")/../../../../.." && pwd)"

# 3. Register ALL of this repo's plugins for Claude Code (its native plugin path),
#    rather than symlinking them into ~/.claude/skills. Keeping Claude Code on the
#    plugin path means tools that read both skill homes (opencode) never list a
#    skill twice. The list is derived from the repo's plugin dirs, so it always
#    matches what step 3 exposes to the other tools and never drifts by hand.
if command -v claude >/dev/null 2>&1; then
  echo "Installing this repo's plugins for Claude Code..."
  claude plugin marketplace add doyled-it/claude-skills >/dev/null 2>&1 \
    || claude plugin marketplace update doyled-it-skills >/dev/null 2>&1 || true
  for plugin_json in "$REPO_ROOT"/plugins/*/.claude-plugin/plugin.json; do
    [ -f "$plugin_json" ] || continue
    p="$(basename "$(dirname "$(dirname "$plugin_json")")")"
    claude plugin install "$p@doyled-it-skills" -y >/dev/null 2>&1 \
      && echo "  installed $p" \
      || echo "  (could not install $p; run: claude plugin install $p@doyled-it-skills)"
  done
else
  echo "Note: 'claude' CLI not found; Claude Code plugin registration skipped."
  echo "  Install later with: claude plugin marketplace add doyled-it/claude-skills"
  echo "  then: claude plugin install <plugin>@doyled-it-skills"
fi

# 3. Install this repo's skills for the OTHER tools (~/.agents/skills). Claude Code
#    is covered by step 2, so install-skills.sh no longer touches ~/.claude/skills.
#    Note: step 2 installs plugins from the PUBLISHED marketplace (the repo's remote
#    default branch), not this working tree, so to test local plugin edits run the
#    plugin from its path rather than relying on `claude plugin install`.
if [ -f "$REPO_ROOT/scripts/install-skills.sh" ]; then
  echo "Installing skills into ~/.agents/skills for other tools..."
  bash "$REPO_ROOT/scripts/install-skills.sh" || echo "  (skill symlinking step reported an issue; continuing)"
else
  echo "Note: $REPO_ROOT/scripts/install-skills.sh not found; skipping skill symlinking."
fi

# 4. Managed global-conventions block (idempotent via markers).
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
