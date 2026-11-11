# Reviewer checklist

A reviewer re-runs the checks and opens the cross-sections. The report is a
record of what the author did, not evidence the part is right: the two defects
this skill exists for both passed a report. Verify on the mesh and the pictures.

Copy and tick:

```
Reviewing printable part: <name>
- [ ] Intent list exists and every functional feature is a measurable claim
- [ ] Re-ran check_part.py on the exported mesh; every intent passes (exit 0)
- [ ] Re-ran the cad printing DFM check; no errors
- [ ] Opened the cross-section through every hole, slot, and pocket
- [ ] Each section matches its intent (a countersink wider at the top face, the
      slot at its stated width); a passing number with a wrong-looking section
      means the intent measures the wrong thing
- [ ] Bounding box matches the parameters (stale-file guard green)
- [ ] A check record exists and its hash matches the mesh on disk
- [ ] Test-fit coupon exported and checked
- [ ] Print sheet present: orientation justified, filament and profile named,
      what to measure after the print
```

If any item fails, send it back with the specific intent id or section that is
wrong. Do not approve on the report alone.

## Reviewing as a fresh agent

A dispatched reviewer gets the repo, not the author's context. Run the two
commands and open the sections; that is the whole job:

```bash
uv run plugins/printable-parts/skills/printable-parts/scripts/check_part.py <name>.intent.json
cad model dfm "$ID" --process printing --technology fdm --material pla
```
