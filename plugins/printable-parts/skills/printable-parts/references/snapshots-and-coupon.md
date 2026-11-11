# Snapshots, cross-sections, and the test-fit coupon

## Contents

- Why cross-sections
- Snapshots to take
- Cross-sections through every hole, slot, and pocket
- Test-fit coupon

## Why cross-sections

The owner has no CAD software and cannot open the model. A render of the outside
hides exactly the features that fail: a countersink's taper, a slot's inner
width, a bore's depth. A cross-section makes the inside a picture a person can
read, and makes you look at the feature you claim to have built. Look at them
yourself before handing over; a check that passed and a section that looks wrong
means the intent is measuring the wrong thing.

## Snapshots to take

Use the cad skill's snapshots. Take several angles so the whole part is seen,
front and back:

```bash
cad model snapshot "$ID" tmp/iso.png
cad model snapshot "$ID" tmp/top.png --camera top --display hidden-line
cad model snapshot "$ID" tmp/front.png --camera front
```

## Cross-sections through every hole, slot, and pocket

Produce a section view through each internal feature. The cad skill's snapshot
and inspection references cover section and clip views; a hidden-line view from
the feature's axis also exposes the inner profile. The rule is coverage: every
hole, slot, and pocket named in the intent list gets a picture that shows its
inside, at the plane the intent measures.

Name each section after the feature and the plane, so the reviewer can line the
picture up with the intent it belongs to (for example `tmp/countersink-z11.png`).

## Test-fit coupon

Export a small, fast print of just the critical fit, alongside the full part. The
coupon is its own cad model that reuses the part's parameters, so it tests the
same numbers: the clip jaws and their slot, the bore and its pilot, the
countersunk hole in a thin tab. A 10-minute coupon settles whether the clearance
is right for this filament and printer before committing to the full print.

```bash
cad model export "$COUPON_ID" out/perch-coupon.stl
uv run scripts/check_part.py perch-coupon.intent.json
```

Give the coupon its own intent file and its own print sheet line. It goes through
the same gates as the part: an intent file to export, a passing check to slice.
