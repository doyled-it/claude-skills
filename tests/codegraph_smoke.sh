#!/usr/bin/env bash
# Real CLI fixtures, not a fresh-agent skill-selection evaluation.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
command -v codegraph >/dev/null
command -v uv >/dev/null
mkdir -p "$ROOT/.superpowers"
TASK_DIR=$(mktemp -d "$ROOT/.superpowers/codegraph-smoke.XXXXXX")
trap 'rm -rf "$TASK_DIR"' EXIT
TASK_HOME="$TASK_DIR/home"
mkdir -p "$TASK_HOME"
graph() {
  local repo="$1"
  shift
  (cd "$repo" && env HOME="$TASK_HOME" XDG_CONFIG_HOME="$TASK_HOME/.config" codegraph "$@")
}
expect_symbol() {
  graph "$1" query "$2" --json > "$TASK_DIR/query.json"
  node - "$TASK_DIR/query.json" "$2" <<'JS'
const fs = require('node:fs');
const assert = require('node:assert/strict');
const rows = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
assert.ok(rows.some((row) => row.node.name === process.argv[3]), 'expected actual indexed symbol');
JS
}

for repo in hub api client unsupported; do
  mkdir -p "$TASK_DIR/$repo"
  git -C "$TASK_DIR/$repo" -c init.defaultBranch=main init -q
done
for repo in hub api client; do
  printf 'def %s_probe():\n    return "original"\n' "$repo" > "$TASK_DIR/$repo/app.py"
  test ! -d "$TASK_DIR/$repo/.codegraph"
  graph "$TASK_DIR/$repo" status . > "$TASK_DIR/$repo-status.log" 2>&1 || true
  graph "$TASK_DIR/$repo" init . --yes > "$TASK_DIR/$repo-init.log" 2>&1
  graph "$TASK_DIR/$repo" sync . > "$TASK_DIR/$repo-sync.log" 2>&1
  expect_symbol "$TASK_DIR/$repo" "${repo}_probe"
done

# Indexes are per-repo and sync must replace stale symbols.
graph "$TASK_DIR/hub" query api_probe --json > "$TASK_DIR/query.json"
node - "$TASK_DIR/query.json" <<'JS'
const assert = require('node:assert/strict');
const fs = require('node:fs');
assert.equal(JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).length, 0);
JS
printf 'def api_updated():\n    return "changed"\n' > "$TASK_DIR/api/app.py"
graph "$TASK_DIR/api" sync . > "$TASK_DIR/rename-sync.log" 2>&1
expect_symbol "$TASK_DIR/api" api_updated

# A successful empty index does not supply symbols for unsupported source.
printf '# Demo\nUnsupported source is inspected directly.\n' > "$TASK_DIR/unsupported/README.md"
printf '#!/bin/sh\nprintf "actual shell source"\n' > "$TASK_DIR/unsupported/run.sh"
graph "$TASK_DIR/unsupported" init . --yes > "$TASK_DIR/unsupported-init.log" 2>&1
graph "$TASK_DIR/unsupported" sync . > "$TASK_DIR/unsupported-sync.log" 2>&1
graph "$TASK_DIR/unsupported" query missing_probe --json > "$TASK_DIR/query.json"
node - "$TASK_DIR/query.json" <<'JS'
const assert = require('node:assert/strict');
const fs = require('node:fs');
assert.equal(JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).length, 0);
JS
grep -q 'actual shell source' "$TASK_DIR/unsupported/run.sh"

# Existing scaffold keeps user edits and does not duplicate README pointers.
SCAFFOLD="$ROOT/plugins/cross-repo-completeness/skills/cross-repo-completeness/scripts/scaffold.py"
uv run --no-project "$SCAFFOLD" --hub "$TASK_DIR/hub" --repo "$TASK_DIR/hub" \
  --repo "$TASK_DIR/api" --repo "$TASK_DIR/client" --forge github > "$TASK_DIR/scaffold.log"
printf '\nPreserved user note.\n' >> "$TASK_DIR/api/CONTRIBUTING.md"
uv run --no-project "$SCAFFOLD" --hub "$TASK_DIR/hub" --repo "$TASK_DIR/hub" \
  --repo "$TASK_DIR/api" --repo "$TASK_DIR/client" --forge github >> "$TASK_DIR/scaffold.log"
grep -q 'Preserved user note' "$TASK_DIR/api/CONTRIBUTING.md"
test "$(grep -c '^## Part of a multi-repo system' "$TASK_DIR/api/README.md")" = 1
test -f "$TASK_DIR/hub/docs/cross-repo-features.md"
printf 'PASS: real CLI cold/stale/per-repo/unsupported fixtures and scaffold idempotence\n'
