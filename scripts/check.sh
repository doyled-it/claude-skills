#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
node --test tests/policy.test.cjs
bash tests/install_test.sh
for script in scripts/check.sh scripts/install-skills.sh tests/install_test.sh \
  tests/codegraph_smoke.sh plugins/development-loop/skills/development-loop/scripts/install.sh; do
  bash -n "$script"
  shellcheck "$script"
done
node --check tests/policy.test.cjs
git diff --check
printf 'PASS: policy, installer, syntax, ShellCheck and whitespace checks\n'
