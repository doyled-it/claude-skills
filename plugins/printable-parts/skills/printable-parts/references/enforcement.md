# Enforcing the ordering

The two skills must run together, in order: the intent list and checks around the
cad modeling, and the checks before any slice. Three layers enforce it, each
catching what the one above misses.

## Contents

- Soft layer: this skill as the entry point
- Hard layer: the PreToolUse hook
- Repo layer: CI
- Per-runtime limits

## Soft layer: this skill as the entry point

This skill's description triggers on designing or printing a functional part (a
mount, bracket, stand, cover, enclosure, clip, perch, and the rest), and its body
composes the `cad` and `print3d` skills by name, in order. When it loads first,
the ordering follows.

The cad skill competes for the same prompts: its description triggers on "3D CAD
modeling", "editing a model script", and "exporting". A prompt like "model a
bracket and print it" can match both. Two things make printable-parts load first
or alongside: its description leads with the printed-and-used intent and the part
nouns, which a cad-only reading does not emphasise; and it names cad and print3d
as required sub-skills, so loading printable-parts pulls them in at the right
step rather than the reverse. The soft layer is a bias, not a guarantee, which is
why the hard and repo layers exist.

## Hard layer: the PreToolUse hook

`hooks/guard-printable-mesh.js` is a Claude Code PreToolUse hook on the Bash
tool, following this repo's hooks precedent in
`plugins/nonfiction-superpowers/hooks`. It is written in Node so it can parse the
tool payload and hash a mesh with no shell dependencies. Two gates:

- **Export gate.** A command that exports a printable mesh (`cad <type> export`
  with a `.stl` or `.3mf` output) is denied when no intent file in the tree names
  that mesh. You write the intent list first.
- **Slice / send gate.** A command that slices a mesh (`--slice`, `--export-3mf`,
  `--export-gcode`, or a slicer invoked by name) or opens one in a slicer or Bambu
  app is denied unless a passing check record sits beside the mesh whose SHA-256
  matches the mesh on disk now.

It fails open. Any error, any payload it cannot parse, and it allows the command:
a hook must never wedge an unrelated session. It only ever emits a deny, never an
allow, so unrelated commands pass untouched. Its decisions are tested in
`tests/printable-parts/hook_test.sh`.

Known gaps, by design: the slice gate cannot recover the source mesh from an
already-sliced `.gcode.3mf`, so a Bambu Connect import of a sliced file is not
gated; the earlier slice and open-model steps are, which is where the check
belongs. If Node is absent the hook cannot run and the command proceeds (fail
open).

## Repo layer: CI

The host repo (the one holding the part, not this skills repo) runs
`check_part.py` on each part in CI. A pull request cannot merge a part whose
checks fail, whoever made it and whatever runtime they used. This is the only
layer that binds a contributor whose editor runs no hook.

## Per-runtime limits

- **Claude Code**: all three layers. The hook is the hard gate.
- **Codex, opencode, and other runtimes**: the soft layer and the repo layer. The
  SKILL.md and its scripts run anywhere the Agent Skills standard runs, and CI
  binds every contributor; but the PreToolUse hook is a Claude Code mechanism, so
  those runtimes have no per-command block. Lean on CI there.
