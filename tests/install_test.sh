#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
INSTALL="$ROOT/plugins/development-loop/skills/development-loop/scripts/install.sh"
FALLBACK="$ROOT/scripts/install-skills.sh"
mkdir -p "$WORK/home" "$WORK/bin"
TEST_HOME="$WORK/home"
export PATH="$WORK/bin:/usr/bin:/bin"
export CALLS="$WORK/calls"
: > "$CALLS"
for tool in claude codex codegraph; do
  cat > "$WORK/bin/$tool" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$0 $*" >> "$CALLS"
if [ "${NATIVE_PLUGINS:-0}" = 1 ] && [ "$*" = 'plugin --help' ]; then exit 0; fi
exit 1
EOF
  chmod +x "$WORK/bin/$tool"
done
run_install() { env HOME="$TEST_HOME" bash "$INSTALL" "$@"; }
run_fallback() { env HOME="$TEST_HOME" bash "$FALLBACK" "$@"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
reject() {
  if "$@" > "$WORK/rejected.log" 2>&1; then fail "unexpected success: $*"; fi
}

# The legacy entry point updates conventions only unless shared fallback is explicit.
run_install > "$WORK/install.log"
test ! -e "$TEST_HOME/.agents/skills" || fail 'default installed shared skills'
test ! -s "$CALLS" || fail 'default touched CLIs or indexes'
# shellcheck disable=SC2016
grep -qF '`using-codegraph`' "$TEST_HOME/.claude/CLAUDE.md" || fail 'wrong skill routed'
grep -qF 'codegraph init .' "$TEST_HOME/.claude/CLAUDE.md" || fail 'missing cold index guidance'
cp "$TEST_HOME/.claude/CLAUDE.md" "$WORK/first"
run_install > "$WORK/repeat.log"
cmp "$WORK/first" "$TEST_HOME/.claude/CLAUDE.md" || fail 'reinstall is not idempotent'

# Rewrite both historical marker labels without losing the surrounding instructions.
for label in claude-skills Codex-skills; do
  target="$TEST_HOME/$label instructions.md"
  cat > "$target" <<EOF
Keep this prefix.
<!-- BEGIN doyled-it:development-conventions (managed by $label/development-loop) -->
Old indexed-only rules.
<!-- END doyled-it:development-conventions -->
Keep this suffix.
EOF
  chmod 600 "$target"
  run_install --global-file "$target" > "$WORK/update.log"
  test "$(grep -c '^<!-- BEGIN doyled-it:development-conventions ' "$target")" = 1 || fail 'duplicate block'
  grep -q '^Keep this prefix.$' "$target" || fail 'lost prefix'
  grep -q '^Keep this suffix.$' "$target" || fail 'lost suffix'
  if grep -q 'Old indexed-only' "$target"; then fail 'stale block survived'; fi
  test "$(stat -c %a "$target" 2>/dev/null || stat -f %Lp "$target")" = 600 || fail 'broadened permissions'
done

# Invalid marker state and symlinks fail before touching user instructions.
for contents in begin end reversed duplicate; do
  target="$TEST_HOME/malformed.md"
  begin='<!-- BEGIN doyled-it:development-conventions (managed by claude-skills/development-loop) -->'
  end='<!-- END doyled-it:development-conventions -->'
  case "$contents" in
    begin) printf '%s\n' "$begin" > "$target" ;;
    end) printf '%s\n' "$end" > "$target" ;;
    reversed) printf '%s\n' "$end" "$begin" > "$target" ;;
    duplicate) printf '%s\n' "$begin" "$begin" "$end" > "$target" ;;
  esac
  cp "$target" "$WORK/before"
  reject run_install --global-file "$target"
  cmp "$target" "$WORK/before" || fail 'malformed file was changed'
done
ln -s "$WORK/first" "$TEST_HOME/link.md"
reject run_install --global-file "$TEST_HOME/link.md"
reject run_install --global-file
reject run_install --unknown
run_install --print-only --global-file "$TEST_HOME/never-created.md" > "$WORK/printed"
test ! -e "$TEST_HOME/never-created.md" || fail 'print-only mutated filesystem'

# Explicit fallback preserves foreign symlinks and real directories on repeated runs.
mkdir -p "$TEST_HOME/.agents/skills" "$WORK/foreign" "$TEST_HOME/.agents/skills/cross-repo-completeness"
ln -s "$WORK/foreign" "$TEST_HOME/.agents/skills/using-codegraph"
run_install --shared-skills > "$WORK/shared.log"
test "$(readlink "$TEST_HOME/.agents/skills/using-codegraph")" = "$WORK/foreign" || fail 'clobbered foreign symlink'
test ! -L "$TEST_HOME/.agents/skills/cross-repo-completeness" || fail 'clobbered real directory'
test -L "$TEST_HOME/.agents/skills/development-loop" || fail 'fallback missing'
test ! -e "$TEST_HOME/.claude/skills" || fail 'created duplicate Claude skill links'
run_fallback > "$WORK/shared-repeat.log"
test -L "$TEST_HOME/.agents/skills/development-loop" || fail 'repeat lost fallback'
run_fallback --help > "$WORK/help.log"
reject run_fallback --unknown

# A modern native-plugin runtime must not gain a second shared copy of the skills.
export NATIVE_PLUGINS=1
mkdir -p "$WORK/native-home"
TEST_HOME="$WORK/native-home"
reject run_fallback
test ! -e "$TEST_HOME/.agents" || fail 'native guard wrote skills'
reject run_install --shared-skills
test ! -e "$TEST_HOME/.claude/CLAUDE.md" || fail 'failed fallback partially applied conventions'

printf 'PASS: conventions, migration, validation, fallback ownership and native-plugin isolation\n'
