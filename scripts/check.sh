#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
node --test tests/policy.test.cjs
bash tests/install_test.sh
bash tests/printable_parts_test.sh
for script in scripts/check.sh scripts/install-skills.sh tests/install_test.sh \
  tests/codegraph_smoke.sh tests/printable_parts_test.sh \
  tests/printable-parts/hook_test.sh \
  plugins/development-loop/skills/development-loop/scripts/install.sh; do
  bash -n "$script"
  shellcheck "$script"
done
node --check tests/policy.test.cjs
node --check plugins/printable-parts/hooks/guard-printable-mesh.js
git diff --check
printf 'PASS: policy, installer, syntax, ShellCheck and whitespace checks\n'
