#!/usr/bin/env bash
# Runs the printable-parts deterministic checks: the mesh measurement and intent
# regression (Python, stdlib) and the PreToolUse hook behavior (Node). Each
# sub-test skips cleanly when its runtime is absent, but a real failure fails.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

status=0

echo "printable-parts: mesh measurement and intent checks"
if command -v uv >/dev/null 2>&1; then
  uv run tests/printable-parts/geometry_test.py || status=1
elif command -v python3 >/dev/null 2>&1; then
  python3 tests/printable-parts/geometry_test.py || status=1
else
  echo "  SKIP: no uv or python3"
fi

echo
echo "printable-parts: PreToolUse hook behavior"
bash tests/printable-parts/hook_test.sh || status=1

exit "$status"
