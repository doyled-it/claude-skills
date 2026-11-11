# Evals for printable-parts

Baseline-vs-with-skill scenarios. Each gives a task, the baseline failure (an
agent WITHOUT the plugin), and the pass bar WITH it. Keep three kinds of evidence
separate, as the repo requires:

- **Deterministic check**: a script result, reproducible in CI. Strong evidence
  the measurement catches a defect; no evidence about agent behavior.
- **CLI smoke check**: a real `cad` or `print3d` command ran and produced a file.
- **Fresh-agent behavior**: a fresh agent, given the task, chose and ran the
  workflow. The only evidence that the skill triggers and is followed. Never
  claimed from the first two.

## Scenario 1: the screw-mounted perch (the baseline defect)

Task: "Design a screw-mounted perch for a USB Bluetooth adapter. The adapter body
is 18 mm wide; it should fit with 0.4 to 0.8 mm per side. Two M4 screws hold it
down, countersunk so the heads sit flush. Make a shelf-clip variant whose slot
takes a 25 mm shelf with 2 mm of play. Print it on the Bambu Lab X2D."

- **Baseline failure (no plugin):** models the part, exports an STL, runs at most
  the cad DFM printing check (walls and overhangs), and hands off. Nothing
  measures the countersink orientation or the slot width on the mesh, so an
  inverted countersink (wide at the bottom) or a slot built to 22 mm instead of 27
  passes every check. These are the two defects that shipped.
- **Pass (with plugin):** writes the intent list first (countersink wider at the
  top face; slot = shelf + play; body fit 0.4 to 0.8 mm per side), models with the
  cad skill, exports, and runs `check_part.py`. An inverted countersink fails the
  `countersink_orientation` check; a 22 mm slot fails the `slot_width` check. The
  agent fixes the model, re-exports, re-checks, renders the cross-sections, builds
  a coupon, writes a print sheet, and never starts a print.

**Deterministic evidence for this scenario** lives in
`tests/printable-parts/geometry_test.py`: it builds a perch mesh with the inverted
countersink and the 22 mm slot and shows the checks catch both, while a correct
mesh passes. Run `uv run tests/printable-parts/geometry_test.py`.

## Scenario 2: a parameter changed without re-export (stale-file guard)

Task: "Make the shelf slot take a 28 mm shelf now" (then commit without
re-exporting the mesh).

- **Baseline failure:** the parameter changes in the model, the committed STL is
  stale, and a file-format test still passes it. The printed part has the old slot.
- **Pass:** the intent file's expected slot updates with the parameter; CI runs
  `check_part.py`, measures the stale mesh, and fails because the mesh still reads
  the old width. The deterministic form of this is asserted in
  `geometry_test.py` (the stale-guard case).

## Scenario 3: trying to slice before the checks pass (hook gate)

Task: "Slice perch.stl for the X2D and send it to the printer," with no intent file
or no passing check record.

- **Baseline failure:** slices and opens the file in the printer app; an unchecked
  mesh heads for the plate.
- **Pass (Claude Code):** the export gate blocks the export until an intent file
  exists; the slice gate blocks slicing until a passing check record matches the
  mesh hash. On Codex or opencode there is no hook, so the soft layer and CI carry
  it. Decisions are asserted in `tests/printable-parts/hook_test.sh`.

## How to run the fresh-agent scenarios

For scenario 1, give a fresh agent the task once without the plugin and once with
it, in a scratch repo with the cad server available. Record, per the repo's
evaluation rules: whether the skill loaded (a SKILL.md read or loader event),
which `cad`/`check_part.py` commands ran with their exit status, and whether the
inverted countersink and short slot were caught on the mesh. A regression is a
with-plugin run that hands off a part with an unmeasured functional feature.

Do not count a skill name echoed in prose as an invocation, and do not infer
fresh-agent behavior from the deterministic or CLI checks.
