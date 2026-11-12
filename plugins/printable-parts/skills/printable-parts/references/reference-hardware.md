# Reference hardware (step 1.5)

## Contents

- When this step applies
- The five-tier source order
- The assembly checks
- Where the models live
- What the gate checks

## When this step applies

Whenever the part holds, encloses, mounts, or touches a device, you need a 3D
model of that device to check the fit against, not just the dimensions in your
head. A clearance that is right on paper can still interfere with a connector, a
cable exit, or a ribbon. Model the device, place it in an assembly with the part,
and measure the fit.

If the part touches no device (a standalone bracket, a spacer), record `devices`
as an empty list and move on.

## The five-tier source order

Get each device model from the best available source, and record which tier it
came from in the `devices` block. Prefer lower numbers:

1. **Official CAD** from the maker: a STEP or similar from the manufacturer. For
   example, Raspberry Pi publishes STEP for some boards and mechanical drawing
   PDFs for others.
2. **A community model built from the official drawing** (GrabCAD and similar),
   spot-checked against the official drawing's key dimensions before you trust it.
3. **An envelope model** you build from the official mechanical drawing or
   datasheet: a box plus the features that matter (mounting holes, ports,
   connectors, cable exits, the ribbon or antenna).
4. **Owner caliper measurements**, when nothing is published. State which
   dimensions you need and how to measure them.
5. **An estimate with explicit clearance padding**, flagged loudly as unverified.
   A tier 5 entry must set `unverified: true`, and the test-fit coupon is
   mandatory before the full part.

```json
"devices": [
  { "name": "raspberry-pi-3b", "reference_tier": 2,
    "source": "GrabCAD model built from the official mechanical drawing, hole pitch spot-checked",
    "unverified": false },
  { "name": "rpi-7in-touch-display", "reference_tier": 3,
    "source": "envelope from the official 7 inch display mechanical drawing (active area, ribbon exit, mounting bosses)",
    "unverified": false }
]
```

## The assembly checks

Place each device model in an assembly with the part and confirm, with text-to-cad:

- **No interference** (the interference check): the part and the device do not
  occupy the same space.
- **The intended clearance per side**: the gap is the one the intent claims, not
  just non-negative.
- **Reachability**: ports, buttons, the SD card, cables, the screen's active area
  and its ribbon all stay reachable once assembled.
- **The insertion path**: the device can physically get into place; a captive fit
  with no insertion path is a defect.

Snapshot the assembly and a cross-section through the fit, and look at them
yourself before handing over.

## Where the models live

Keep each reference model and its source and license in the host repo next to the
part, so a reviewer can re-open the assembly. If a license forbids
redistribution, keep a fetch script instead of the model file.

## What the gate checks

`check_part.py` and the PreToolUse export gate both require, for every entry in
`devices`:

- a `reference_tier` that is an integer 1 to 5;
- a non-empty `source`;
- `unverified: true` when the tier is 5 (an estimate).

The check is on the record. The assembly fit itself is confirmed by the
interference and clearance checks in the cad skill and by the test-fit coupon.
