# Running the checks

## Contents

- The measurement helper
- The intent checker and its feedback loop
- The check record
- The stale-file guard
- What the checks cannot see

## The measurement helper

`scripts/stl_measure.py` reads an STL (binary or ASCII) or a 3MF and measures the
mesh. Standard library only.

```bash
python3 scripts/stl_measure.py bbox out/perch.stl
python3 scripts/stl_measure.py hole out/perch.stl --axis z --at 11 --near 15,15
python3 scripts/stl_measure.py slot out/perch.stl --axis z --at 6 --along u --near 40,15
python3 scripts/stl_measure.py section out/perch.stl --axis z --at 6 --json
```

It cuts the mesh with the plane `axis = at`, stitches the crossing segments into
closed loops, and classifies each loop as the outer boundary or a hole by
even-odd nesting. A hole's `equiv_radius` is the area-equivalent radius; `width_u`
and `width_v` are its extents along the two in-plane axes. Measure at a
mid-feature height, never exactly on a face.

## The intent checker and its feedback loop

`scripts/check_part.py` runs every intent in an intent file against the mesh:

```bash
uv run scripts/check_part.py perch.intent.json
```

It prints each intent as `ok`, `FAIL`, or `ERR`, with the measured and expected
numbers. The loop is: check, read the first failure, fix the model, re-export,
check again. Do not edit the number in the intent file to make a real failure
pass: the claim is the design, the measurement is the referee.

Exit status: 0 every intent passed, 1 an intent failed, 2 the check could not run
(a bad intent file, an unreadable mesh, a feature it could not find). Exit 2 is
never a pass. A feature it could not find usually means the plane height is wrong
or `near` points at the wrong hole; fix the intent, not the verdict.

Pair it with the cad skill's own printing check, which covers walls, overhangs,
and supports that this skill does not:

```bash
cad model dfm "$ID" --process printing --technology fdm --material pla
```

## The check record

On a run that reaches a verdict, `check_part.py` writes
`out/<name>.check.json` beside the mesh: the pass or fail state, the SHA-256 of
the exact mesh it judged, and the SHA-256 of the intent file. The slice gate
reads this record and refuses to slice unless a passing record's hash matches the
mesh on disk, so a mesh edited after it passed cannot reach the printer on an old
verdict.

## The stale-file guard

The guard is `check_part.py` run in the host repo's CI. Because the expected
numbers are derived from the parameters and the measured numbers come from the
mesh, a parameter changed without a re-export makes the two disagree and CI
fails. The `bbox` intent is the cheap anchor every part carries; the feature
intents catch the rest. This needs no extra machinery: the same checker that
drives the design loop is the guard.

## What the checks cannot see

These checks measure geometry on the mesh. They do not judge strength, layer
adhesion, or whether the fit tolerance you chose is right for your filament and
printer; the test-fit coupon settles that on a real print. Report what a check
did not cover beside what it passed.
