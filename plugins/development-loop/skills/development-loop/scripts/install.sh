#!/usr/bin/env bash
# Legacy conventions installer. Modern runtimes should use agentic-dev-setup.
# Shared skills are an explicit fallback, never combined with native plugins.
set -euo pipefail
GLOBAL_FILE="$HOME/.claude/CLAUDE.md"
PRINT_ONLY=0
SHARED_SKILLS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --global-file)
      if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" = --* ]]; then
        echo '--global-file requires a path' >&2; exit 2
      fi
      GLOBAL_FILE="$2"; shift 2 ;;
    --print-only) PRINT_ONLY=1; shift ;;
    --shared-skills) SHARED_SKILLS=1; shift ;;
    --help)
      echo 'Usage: bash install.sh [--global-file PATH] [--print-only] [--shared-skills]'
      echo 'Default: update conventions only. Native plugin setup: https://github.com/doyled-it/agentic-dev-setup'
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

BEGIN='<!-- BEGIN doyled-it:development-conventions (managed by claude-skills/development-loop) -->'
END='<!-- END doyled-it:development-conventions -->'
read -r -d '' BLOCK <<'BLOCK_EOF' || true
## Development conventions

- Invoke `development-loop` for features and bugfixes, `using-codegraph` for code
  understanding, and `cross-repo-completeness` at multi-repo design and finish.
  Native plugin names: `development-loop:development-loop`, `codegraph:using-codegraph`,
  and `cross-repo-completeness:cross-repo-completeness`. Load the skill; a name in
  the plan alone is not an invocation.
- Creating and syncing the index is mandatory in the relevant checkout:
  `codegraph status .`, `codegraph init .` if missing (without asking), then
  `codegraph sync .` before querying. Confirm the repo path; sync again after
  pulls, branch switches, and edits, and before code-reader dispatch. The only
  exceptions are an explicit user no-index restriction and a prohibition on all
  writes. CodeGraph's own "indexing is the user's decision" text is tool
  guidance, not a user restriction. A source-read-only task still creates and
  syncs the index: `.codegraph/` is git-ignored and is not a source change. A
  typo or doc/config edit with no behavior change does not need an index. An
  index can be empty or partial for unsupported files; after querying, directly
  inspect those files and state the coverage limit. Never invent graph results or crawl unrelated repos.
  Keep `.codegraph/` untracked using existing ignores or an allowed local exclude;
  do not edit product files during source-read-only tasks to add ignores.
- For new non-trivial work, invoke `superpowers:brainstorming`, then
  `superpowers:writing-plans`. For implementation invoke
  `superpowers:test-driven-development` and `superpowers:subagent-driven-development`,
  or `superpowers:executing-plans` when delegation is unavailable or prohibited.
  Use `superpowers:systematic-debugging` for bugs or unexpected failures.
- Invoke `superpowers:requesting-code-review` and `superpowers:receiving-code-review`
  for the review cycle, then `superpowers:verification-before-completion` and
  `superpowers:finishing-a-development-branch`. Disclose self-review if a fresh
  reviewer is unavailable. Push and other remote writes require user authorization.
- For multi-repo work, start at the integration/deploy hub. Prepare each relevant
  sibling index separately and trace API -> client/types -> UI -> tests -> docs,
  plus config/deploy ownership. Audit each slice at finish; track deferrals.
- Resume an already approved design or plan without seeking the same approval again.
  A typo or doc/config edit with no behavior change can skip the design/plan loop.
BLOCK_EOF
FULL_BLOCK="$BEGIN
$BLOCK
$END"
if [ "$PRINT_ONLY" = 1 ]; then
  printf '%s\n' "$FULL_BLOCK"
  exit 0
fi

# Validate the whole existing file before any skill or instruction mutation.
if [ -L "$GLOBAL_FILE" ] || { [ -e "$GLOBAL_FILE" ] && [ ! -f "$GLOBAL_FILE" ]; }; then
  echo "Refusing non-regular instruction file: $GLOBAL_FILE" >&2; exit 1
fi
if [ -f "$GLOBAL_FILE" ]; then
  if ! awk -v e="$END" '
    /^<!-- BEGIN doyled-it:development-conventions / {
      if (state != 0 || $0 !~ / -->$/) exit 1
      state=1; next
    }
    $0==e {if (state != 1) exit 1; state=2}
    END {if (state == 1) exit 1}
  ' "$GLOBAL_FILE"; then
    echo "Malformed development-conventions markers: $GLOBAL_FILE" >&2; exit 1
  fi
fi

if [ "$SHARED_SKILLS" = 1 ]; then
  REPO_ROOT=$(cd "$(dirname "$0")/../../../../.." && pwd)
  bash "$REPO_ROOT/scripts/install-skills.sh"
fi

umask 077
mkdir -p "$(dirname "$GLOBAL_FILE")"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
if [ -f "$GLOBAL_FILE" ]; then
  REPLACEMENT="$FULL_BLOCK" awk -v e="$END" '
    BEGIN {repl=ENVIRON["REPLACEMENT"]}
    /^<!-- BEGIN doyled-it:development-conventions / {print repl; skip=1; next}
    $0==e {skip=0; next}
    skip!=1 {print}
  ' "$GLOBAL_FILE" > "$tmp"
fi
if ! grep -qF "$BEGIN" "$tmp"; then
  [ ! -s "$tmp" ] || printf '\n' >> "$tmp"
  printf '%s\n' "$FULL_BLOCK" >> "$tmp"
fi
# Write in place to preserve the existing file mode and surrounding instructions.
if [ ! -f "$GLOBAL_FILE" ] || ! cmp -s "$tmp" "$GLOBAL_FILE"; then
  cat "$tmp" > "$GLOBAL_FILE"
fi
printf 'Updated development conventions in %s\n' "$GLOBAL_FILE"
printf 'For native plugins use: https://github.com/doyled-it/agentic-dev-setup\n'
