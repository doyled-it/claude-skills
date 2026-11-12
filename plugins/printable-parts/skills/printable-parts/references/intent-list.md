# The intent list

## Contents

- Why the list comes first
- The intent file format
- The pre-modeling records (prior_art and devices)
- Check types
- Deriving the numbers from parameters

## Why the list comes first

A functional feature nobody wrote down as a measurable claim is a feature nobody
checks. Writing the list before modeling forces the fit, the clearance, and the
orientation to be decided as numbers, not discovered on the printed part. The
list is also what the export gate reads: a mesh exported with no intent file is
blocked.

Keep the list in `<name>.intent.json` beside the model script. One file per part.

## The intent file format

```json
{
  "part": "perch",
  "mesh": "out/perch.stl",
  "units": "mm",
  "params": { "slot_mm": 27, "head_r": 4.0, "pilot_r": 2.2 },
  "intents": [
    {
      "id": "envelope",
      "claim": "fits the shelf bracket: 60 x 30 x 12 mm",
      "check": { "type": "bbox", "expected_mm": [60, 30, 12], "tolerance_mm": 0.4 }
    }
  ]
}
```

- `mesh` is relative to the intent file. The checker and the hook match a part by
  this path's file name.
- `params` records the parameters the expected numbers come from. It makes the
  stale-file guard legible: when a parameter changes, the intent's expected
  number changes with it.
- Every intent has an `id`, a plain-language `claim` that names the physics, and a
  `check` the measurement runs.

## The pre-modeling records (prior_art and devices)

Two records sit beside the intents and are checked before the geometry, by both
`check_part.py` and the export gate. They make the owner's step 0 and step 1.5
mechanical: a mesh cannot be exported until they are filled in. Full detail is in
[prior-art.md](prior-art.md) and [reference-hardware.md](reference-hardware.md);
the fields are:

```json
{
  "prior_art": {
    "decision": "design_new",
    "reason": "no close match on MakerWorld, Printables, Thingiverse; fit is specific",
    "found": [{ "url": "https://makerworld.com/...", "license": "CC BY 4.0" }]
  },
  "devices": [
    { "name": "usb-bt-adapter", "reference_tier": 3,
      "source": "datasheet envelope; mounting pitch from the drawing",
      "unverified": false }
  ]
}
```

- `prior_art.decision` is one of `design_new`, `use_as_is`, `remix`, and
  `prior_art.reason` must be non-empty. `use_as_is` and `remix` need at least one
  `found` entry with a `url` and a `license`.
- `devices` is a list, empty when the part touches no device. Each entry needs a
  `reference_tier` (an integer 1 to 5) and a non-empty `source`. A tier 5
  (estimate) entry must set `unverified: true` and carry a test-fit coupon.

## Check types

Each `check` has a `type` and its own fields. All lengths are millimetres. The
in-plane axes on a section are named `u` and `v` in x, y, z order with the
section axis removed (for `axis: "z"`, `u` is x and `v` is y).

**bbox**: the solid's envelope.
```json
{ "type": "bbox", "expected_mm": [60, 30, 12], "tolerance_mm": 0.4 }
```

**hole_radius**: a hole's radius on a plane. `measure` is `equiv_radius`
(area-equivalent, the default), `min_radius`, or `max_radius`. `near` picks the
hole nearest that in-plane point when a section has several.
```json
{ "type": "hole_radius", "axis": "z", "at": 1.0, "near": [15, 15],
  "measure": "equiv_radius", "expected_mm": 2.2, "tolerance_mm": 0.3 }
```

**slot_width**: the width of a slot or pocket along one in-plane axis.
```json
{ "type": "slot_width", "axis": "z", "at": 6.0, "along": "u",
  "near": [40, 15], "expected_mm": 27, "tolerance_mm": 0.5 }
```

**countersink_orientation**: the feature that catches the inverted countersink. A
countersunk or counterbored hole must be wider at the face the screw head enters,
or the head cannot seat. It measures the hole radius just inside the top face
(`top_at`) and just inside the bottom face (`bottom_at`) and requires the top
wider by at least `min_delta_mm` (set `top_wider` to false to require the bottom
wider).
```json
{ "type": "countersink_orientation", "axis": "z", "near": [15, 15],
  "top_at": 11.0, "bottom_at": 1.0, "top_wider": true, "min_delta_mm": 1.0 }
```

Choose `at`, `top_at`, and `bottom_at` at mid-feature heights, not exactly on a
face or a vertex: a plane through a vertex is degenerate. For a 12 mm plate with a
3 mm counterbore, measure the head at 11 and the pilot at 1.

## Deriving the numbers from parameters

The expected numbers are a function of the part's parameters, and writing them
that way is what makes the stale-file guard work. If the shelf is `shelf_mm` wide
and wants `play_mm` of play, the slot's `expected_mm` is `shelf_mm + play_mm`.
When a parameter moves, update `params` and the expected number together, then
re-export. A mesh that was not re-exported will fail the check, which is the
guard doing its job.
