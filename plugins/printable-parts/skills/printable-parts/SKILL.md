---
name: printable-parts
description: Designs 3D-printed functional parts whose every functional feature is a measured check on the exported mesh, layered on text-to-cad (composed by name, never vendored). It writes a measurable intent list before modeling, models with the cad skill, checks each intent on the exported STL or 3MF (not just the model code), guards against stale exports, renders cross-sections through every hole and slot, builds a test-fit coupon, and writes a print sheet for a Bambu Lab printer. Use when designing or printing any part that will be printed and then fitted, fastened, or loaded: a mount, bracket, stand, cover, enclosure, clip, perch, holder, adapter, jig, or fixture, or whenever a screw hole, countersink, slot, bore, snap, or press fit has to come out to a real dimension. Start here before the cad or print3d skills so the checks and the ordering hold.
license: AGPL-3.0-only
metadata:
  repository: doyled-it/claude-skills
---

# Printable parts

A file-format test and a DFM check both pass a part whose countersink is inverted
so the screw head cannot seat, or whose clip slot is 22 mm when its parameters
asked for 27 mm. Those are real defects that shipped. The gap is that nobody
measured the function on the mesh. This skill closes it: every functional feature
becomes a number checked on the exported mesh itself, and the check runs before
anything reaches the printer.

This skill composes text-to-cad by skill name. It never vendors or edits it.

- **REQUIRED SUB-SKILL:** `cad` (text-to-cad) for all modeling, export, inspection,
  and snapshots.
- **REQUIRED SUB-SKILL:** `print3d` (text-to-cad) for slicing and the Bambu Lab
  handoff, and only after the checks pass. Never start or send a print.

## Workflow

Copy this checklist into your working notes and tick each item. The loop in
steps 2 to 4 repeats until every intent passes.

```
Printable part: <name>
- [ ] 0. Prior art searched (MakerWorld, Printables, Thingiverse); decision recorded
- [ ] 1. Intent list written (<name>.intent.json), every function a measurable claim
- [ ] 1.5 Reference model per device (five-tier source order); assembly fit checked
- [ ] 2. Modeled with the cad skill
- [ ] 3. Exported, then every intent checked on the mesh (check_part.py) + cad printing DFM
- [ ] 4. Stale-file guard green (bbox + key dims from parameters)
- [ ] 5. Snapshots from several angles + a cross-section through every hole, slot, pocket
- [ ] 6. Test-fit coupon exported (just the critical fit)
- [ ] 7. Print sheet written (orientation, filament, Bambu profile, what to measure)
- [ ] 8. Reviewer re-ran the checks and opened the cross-sections
```

Steps 0 and 1.5 are also recorded in the intent file (`prior_art` and
`devices`), so the export gate and `check_part.py` confirm them mechanically,
not just the prose. Both run before modeling.

### 0. Prior-art search, before anything

Before modeling, search existing designs: MakerWorld, Printables, and Thingiverse,
with STLFinder or 3DGO as aggregators. Search with the device's product name and
generic terms only, never anything about the owner. Record what you found (links
and licenses) and decide: use as is, remix (license permitting), or design new,
with the reason. A downloaded or remixed mesh still goes through the same intent
checks. The decision goes in the intent file's `prior_art` block, which the export
gate requires. See [references/prior-art.md](references/prior-art.md).

### 1. Intent list, before modeling

Write every functional feature as a claim a measurement can settle, and keep it
in `<name>.intent.json` beside the model. The claim names the physics, not just a
number: "a screw head seats flush, so the hole is wider at the top face than at
the bottom"; "a 25 mm shelf fits the clip with 2 mm play, so the slot is 27 mm";
"the adapter body fits with 0.4 to 0.8 mm per side". Each intent carries a check
that `check_part.py` runs on the mesh. See
[references/intent-list.md](references/intent-list.md) for the file format, the
check types, and [templates/intent.example.json](templates/intent.example.json).

Writing the intent list first is also what the export gate looks for (see
[references/enforcement.md](references/enforcement.md)): exporting a mesh with no
intent file is blocked.

### 1.5 Reference hardware, whenever the part touches a device

Whenever the part holds, encloses, mounts, or touches a device, get a 3D model of
that device and record which source tier it came from, in this order of
preference: official CAD from the maker (tier 1), a community model built from the
official drawing and spot-checked (tier 2), an envelope built from the drawing or
datasheet (tier 3), owner caliper measurements (tier 4), or an estimate with
clearance padding, flagged unverified with a mandatory coupon (tier 5). Place the
device in an assembly with the part and check: no interference, the intended
clearance per side, that ports, buttons, SD cards, cables, and screens stay
reachable, and that the insertion path works. Snapshot the assembly and a
cross-section. Record each device in the intent file's `devices` block (name,
`reference_tier`, source), which the export gate requires. See
[references/reference-hardware.md](references/reference-hardware.md).

### 2. Model with the cad skill

Use the `cad` skill. Record each part's intended process so its own DFM check runs
(`part.material = metals.pla(process=printed())` style, per the cad skill). Keep
the model's parameters named, because the stale-file guard derives expected
dimensions from them.

### 3. Export, then check the mesh

Export with the cad skill (`cad model export <id> out/<name>.stl out/<name>.3mf`),
then check every intent against that exported file, plus the cad skill's own
printing DFM check:

```bash
uv run plugins/printable-parts/skills/printable-parts/scripts/check_part.py <name>.intent.json
cad model dfm "$ID" --process printing --technology fdm --material pla
```

A failed intent sends you back to step 2. Fix the model, re-export, re-check. The
checker reads the mesh, never the model code, because an export that never ran, a
unit slip, or a kernel surprise all hide in the gap between code and file. Details
and the measurement helper are in [references/checks.md](references/checks.md).

### 4. Stale-file guard

Running `check_part.py` in CI is the guard: the expected numbers come from the
part's parameters (you derive them into the intent file), the measured numbers
come from the mesh, so a parameter changed without a re-export makes them
disagree and the check fails. Every intent file carries a `bbox` intent as the
cheap anchor. See [references/checks.md](references/checks.md#stale-file-guard).

### 5. Pictures for a person without CAD software

The owner cannot open a CAD file. Produce, and look at yourself before handing
over: snapshots from several angles, and a cross-section through every hole, slot,
and pocket so the inside is visible. See
[references/snapshots-and-coupon.md](references/snapshots-and-coupon.md).

### 6. Test-fit coupon

Export a small, fast print of just the critical fit (the clip jaws, the bore, the
countersunk hole), so a 10-minute print settles the fit before the full part. See
[references/snapshots-and-coupon.md](references/snapshots-and-coupon.md#test-fit-coupon).

### 7. Print sheet

Write orientation, filament, the Bambu Lab printer profile, and what to measure or
try once the part is off the plate. Slicing and the printer handoff go through the
`print3d` skill, and only after steps 3 to 6 pass. Never start a print. See
[references/print-sheet.md](references/print-sheet.md).

### 8. Reviewer checklist

A reviewer re-runs the checks and opens the cross-sections instead of trusting the
report. See [references/reviewer-checklist.md](references/reviewer-checklist.md).

## Scripts

Standard-library Python, run with `uv run` or `python3`, so they work in any
repo's CI with no dependencies.

- `scripts/stl_measure.py`: bounding box, and the hole, slot, and pocket profile
  on a cross-section plane of an STL or 3MF. `python3 scripts/stl_measure.py --help`.
- `scripts/check_part.py`: runs every intent in an intent file against the mesh,
  prints pass or fail, and writes a check record beside the mesh.

## Ordering and its limits

The ordering is enforced in three layers: this skill as the soft entry point, a
Claude Code PreToolUse hook as the hard gate on export and slicing, and the
checks in the host repo's CI. The hook is Claude Code only; other runtimes get
the soft layer. [references/enforcement.md](references/enforcement.md) has the
detail and the per-runtime limits.
