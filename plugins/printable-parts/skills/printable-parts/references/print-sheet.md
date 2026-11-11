# The print sheet

## Contents

- What the print sheet is
- The template
- Slicing and the printer handoff

## What the print sheet is

A short, plain-language sheet the owner reads at the printer. It says how to
orient the part, what filament and printer profile to use, and what to measure or
try once the part is off the plate. It is not a slicer file; it is the human
instructions that go with one.

## The template

```markdown
# Print sheet: <name>

- Printer: Bambu Lab X2D
- Filament: <type and colour>, e.g. PLA
- Profile: <Bambu printer profile and layer height>
- Orientation: <which face on the plate, and why: countersinks up so the head
  seat prints cleanly, slots across the layers for strength, minimal supports>
- Supports: <where, or none>
- After the print, check:
  - <the fit to try: the shelf clips on with light play>
  - <the dimension to measure with calipers: slot 27 mm, pilot clears an M4>
  - <what to do if it is tight or loose: reprint the coupon at +/- 0.1 mm>
```

Orientation is a functional decision, not a default. Countersinks and counterbores
print their seat best facing up. A slot or a snap carries load across the layers,
not along them. Say why you chose the orientation, so the owner can judge a
reprint.

## Slicing and the printer handoff

Slicing and the Bambu Lab handoff go through the `print3d` skill, and only after
the checks pass (steps 3 to 6). The slice gate enforces this: a mesh with no
passing check record is not sliced. Never start or send a print; the owner picks
the printer and presses Print in the printer's app.

Keep text-to-cad's telemetry and sharing off throughout.
