#!/usr/bin/env bash
# shellcheck disable=SC2016  # command strings carry a literal $ID on purpose
# Behavioral test for the printable-parts PreToolUse hook. Drives it with real
# JSON payloads and asserts the deny/allow decision for each gate. Node builds
# the payloads so command strings and paths escape cleanly.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
HOOK="$ROOT/plugins/printable-parts/hooks/guard-printable-mesh.js"

if ! command -v node >/dev/null 2>&1; then
  echo "SKIP hook_test: node not found"
  exit 0
fi

TMP=$(mktemp -d "${TMPDIR:-/tmp}/pp_hook.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

fail=0
pass=0

# Run the hook with a synthesized payload; echoes its stdout (a deny JSON, or
# empty for allow).
run_hook() {
  local cwd="$1" cmd="$2"
  node -e 'process.stdout.write(JSON.stringify({tool_name:"Bash",cwd:process.argv[1],tool_input:{command:process.argv[2]}}))' \
    "$cwd" "$cmd" | node "$HOOK"
}

assert_deny() {
  local label="$1" out="$2"
  if printf '%s' "$out" | grep -q '"permissionDecision":"deny"'; then
    echo "  ok   $label (denied)"
    pass=$((pass + 1))
  else
    echo "  FAIL $label (expected deny, got: ${out:-<allow>})"
    fail=$((fail + 1))
  fi
}

assert_allow() {
  local label="$1" out="$2"
  if printf '%s' "$out" | grep -q '"permissionDecision":"deny"'; then
    echo "  FAIL $label (expected allow, got deny)"
    fail=$((fail + 1))
  else
    echo "  ok   $label (allowed)"
    pass=$((pass + 1))
  fi
}

# --- fixtures ---------------------------------------------------------------
mkdir -p "$TMP/out"
MESH="$TMP/out/perch.stl"
printf 'dummy-mesh-bytes-v1' >"$MESH"
if command -v sha256sum >/dev/null 2>&1; then
  HASH=$(sha256sum "$MESH" | awk '{print $1}')
else
  HASH=$(shasum -a 256 "$MESH" | awk '{print $1}')
fi

# A complete intent file: the geometry intent plus the two pre-modeling records
# the export gate now also checks (prior art and a device reference tier).
write_intent() {
  cat >"$TMP/perch.intent.json" <<EOF
{"part":"perch","mesh":"out/perch.stl","prior_art":{"decision":"design_new","reason":"nothing close found"},"devices":[{"name":"usb-bt-adapter","reference_tier":3,"source":"datasheet envelope"}],"intents":[{"id":"x","check":{"type":"bbox","expected_mm":[1,1,1]}}]}
EOF
}

# An intent file missing the prior-art record: names the mesh, but the record
# gate must still deny the export.
write_intent_no_prior_art() {
  cat >"$TMP/perch.intent.json" <<EOF
{"part":"perch","mesh":"out/perch.stl","devices":[{"name":"usb-bt-adapter","reference_tier":3,"source":"datasheet envelope"}],"intents":[{"id":"x","check":{"type":"bbox","expected_mm":[1,1,1]}}]}
EOF
}

# An intent file whose device carries no reference tier (step 1.5 incomplete).
write_intent_bad_device() {
  cat >"$TMP/perch.intent.json" <<EOF
{"part":"perch","mesh":"out/perch.stl","prior_art":{"decision":"design_new","reason":"nothing close found"},"devices":[{"name":"usb-bt-adapter","source":"datasheet envelope"}],"intents":[{"id":"x","check":{"type":"bbox","expected_mm":[1,1,1]}}]}
EOF
}

write_record() {
  local status="$1" hash="$2"
  cat >"$TMP/out/perch.check.json" <<EOF
{"part":"perch","mesh":"perch.stl","mesh_sha256":"$hash","status":"$status"}
EOF
}

# --- Gate 1: export without / with an intent file ---------------------------
out=$(run_hook "$TMP" 'cad model export "$ID" out/perch.stl')
assert_deny "export mesh with no intent file" "$out"

write_intent
out=$(run_hook "$TMP" 'cad model export "$ID" out/perch.stl')
assert_allow "export mesh with a complete intent file (records present)" "$out"

# The record gate: a named intent file is not enough. Missing prior art, or a
# device with no reference tier, must still deny the export.
write_intent_no_prior_art
out=$(run_hook "$TMP" 'cad model export "$ID" out/perch.stl')
assert_deny "export denied when the intent records no prior-art decision" "$out"

write_intent_bad_device
out=$(run_hook "$TMP" 'cad model export "$ID" out/perch.stl')
assert_deny "export denied when a device has no reference_tier" "$out"

write_intent  # restore the complete intent for the slice/send gate below

# A STEP export is not a printable mesh: never gated.
out=$(run_hook "$TMP" 'cad step export part.step part.step')
assert_allow "cad step export to .step is not gated" "$out"

# --- Gate 2: slice / send without a passing matching record -----------------
rm -f "$TMP/out/perch.check.json"
out=$(run_hook "$TMP" '/Applications/OrcaSlicer.app/Contents/MacOS/OrcaSlicer out/perch.stl --slice 0 --export-3mf perch.gcode.3mf')
assert_deny "slice with no check record" "$out"

write_record "pass" "$HASH"
out=$(run_hook "$TMP" 'orca-slicer out/perch.stl --slice 0')
assert_allow "slice with a passing record matching the mesh hash" "$out"

write_record "pass" "deadbeef"
out=$(run_hook "$TMP" 'orca-slicer out/perch.stl --slice 0')
assert_deny "slice with a stale record (hash mismatch)" "$out"

write_record "fail" "$HASH"
out=$(run_hook "$TMP" 'open -a OrcaSlicer out/perch.stl')
assert_deny "open in slicer with a failing record" "$out"

write_record "pass" "$HASH"
out=$(run_hook "$TMP" 'open -a BambuStudio out/perch.stl')
assert_allow "open model in Bambu Studio with a passing record" "$out"

# --- Fail-open and non-target cases -----------------------------------------
out=$(printf 'not json at all' | node "$HOOK" || true)
assert_allow "malformed payload fails open" "$out"

out=$(node -e 'process.stdout.write(JSON.stringify({tool_name:"Read",tool_input:{file_path:"out/perch.stl"}}))' | node "$HOOK" || true)
assert_allow "non-Bash tool is ignored" "$out"

out=$(run_hook "$TMP" 'ls out/perch.stl')
assert_allow "unrelated command mentioning a mesh is ignored" "$out"

echo
if [ "$fail" -ne 0 ]; then
  echo "HOOK TEST FAILED: $fail failed, $pass passed"
  exit 1
fi
echo "HOOK TEST PASSED: $pass checks"
