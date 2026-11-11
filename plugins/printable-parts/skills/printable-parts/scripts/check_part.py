# /// script
# requires-python = ">=3.9"
# ///
"""Check every intent for a part against its exported mesh.

Reads an intent file (the functional claims, written before modeling and kept
beside the model) and the mesh the claims are about, measures each claim on the
mesh with stl_measure, and reports pass or fail. On completion it writes a
check record beside the mesh: the pass/fail state and the SHA-256 of the exact
mesh it judged, so a later slice or print can prove it is slicing a mesh that
passed, not a stale one.

This is the feedback loop of the printable-parts workflow and, run in CI, the
stale-file guard: the expected numbers come from the part's parameters (the
author derives them), the measured numbers come from the mesh, so a parameter
changed without a re-export makes the two disagree and the check fails.

Usage:
  python3 check_part.py INTENT.json [--mesh PATH] [--json] [--no-record]

Exit status: 0 all intents pass, 1 an intent failed, 2 the check could not run
(bad intent file, unreadable mesh, a feature it could not find). Exit 2 is never
a pass.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys

import stl_measure as M


class CheckError(Exception):
    """The check could not be evaluated (maps to exit 2, not a fail)."""


def _sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _within(value, expected, tol):
    return abs(value - expected) <= tol


def _radius_at(tris, axis, level, near, measure):
    feats = M.section_features(tris, axis, level)
    hole = M.nearest_hole(feats, near)
    if hole is None:
        raise CheckError(f"no hole on plane {axis}={level} near {near}")
    return hole[measure], hole


def check_bbox(tris, spec):
    expected = spec["expected_mm"]
    tol = spec.get("tolerance_mm", 0.3)
    box = M.bounding_box(tris)
    size = box["size"]
    ok = all(_within(size[i], expected[i], tol) for i in range(3))
    detail = (
        f"size {size[0]:.3f} x {size[1]:.3f} x {size[2]:.3f} mm, "
        f"expected {expected[0]} x {expected[1]} x {expected[2]} "
        f"(tol {tol})"
    )
    return ok, detail, {"size": size, "expected": expected, "tolerance_mm": tol}


def check_hole_radius(tris, spec):
    near = tuple(spec["near"]) if spec.get("near") else None
    measure = spec.get("measure", "equiv_radius")
    value, hole = _radius_at(tris, spec["axis"], spec["at"], near, measure)
    expected = spec["expected_mm"]
    tol = spec.get("tolerance_mm", 0.3)
    ok = _within(value, expected, tol)
    detail = f"{measure} {value:.3f} mm, expected {expected} (tol {tol})"
    return ok, detail, {measure: value, "expected": expected, "tolerance_mm": tol}


def check_slot_width(tris, spec):
    near = tuple(spec["near"]) if spec.get("near") else None
    feats = M.section_features(tris, spec["axis"], spec["at"])
    hole = M.nearest_hole(feats, near)
    if hole is None:
        raise CheckError(
            f"no slot on plane {spec['axis']}={spec['at']} near {near}"
        )
    width = hole["width_u"] if spec["along"] == "u" else hole["width_v"]
    expected = spec["expected_mm"]
    tol = spec.get("tolerance_mm", 0.4)
    ok = _within(width, expected, tol)
    detail = (
        f"slot width ({spec['along']}) {width:.3f} mm, "
        f"expected {expected} (tol {tol})"
    )
    return ok, detail, {"slot_width": width, "expected": expected, "tolerance_mm": tol}


def check_countersink_orientation(tris, spec):
    """A countersunk or counterbored hole must be wider at the face the screw
    head enters, or the head cannot seat. Measure the hole radius just inside
    the top face and just inside the bottom face and compare."""
    near = tuple(spec["near"]) if spec.get("near") else None
    measure = spec.get("measure", "equiv_radius")
    axis = spec["axis"]
    top_r, _ = _radius_at(tris, axis, spec["top_at"], near, measure)
    bot_r, _ = _radius_at(tris, axis, spec["bottom_at"], near, measure)
    top_wider = spec.get("top_wider", True)
    min_delta = spec.get("min_delta_mm", 0.5)
    delta = top_r - bot_r
    ok = delta >= min_delta if top_wider else (-delta) >= min_delta
    want = "top wider" if top_wider else "bottom wider"
    detail = (
        f"top radius {top_r:.3f} mm, bottom radius {bot_r:.3f} mm, "
        f"delta {delta:+.3f} (need {want} by {min_delta} mm)"
    )
    return ok, detail, {
        "top_radius": top_r,
        "bottom_radius": bot_r,
        "delta": delta,
        "top_wider": top_wider,
        "min_delta_mm": min_delta,
    }


_CHECKS = {
    "bbox": check_bbox,
    "hole_radius": check_hole_radius,
    "slot_width": check_slot_width,
    "countersink_orientation": check_countersink_orientation,
}


def run(intent_path, mesh_override=None, write_record=True):
    with open(intent_path, "r", encoding="utf-8") as handle:
        intent = json.load(handle)
    intents = intent.get("intents", [])
    if not intents:
        raise CheckError(f"{intent_path}: no intents listed")

    base_dir = os.path.dirname(os.path.abspath(intent_path))
    mesh_path = mesh_override or intent.get("mesh")
    if not mesh_path:
        raise CheckError(f"{intent_path}: no mesh given (intent 'mesh' or --mesh)")
    if not os.path.isabs(mesh_path):
        mesh_path = os.path.join(base_dir, mesh_path)
    if not os.path.exists(mesh_path):
        raise CheckError(f"mesh not found: {mesh_path}")

    tris = M.read_mesh(mesh_path)

    results = []
    for item in intents:
        spec = item.get("check", {})
        kind = spec.get("type")
        entry = {"id": item.get("id", "?"), "claim": item.get("claim", ""),
                 "type": kind}
        handler = _CHECKS.get(kind)
        if handler is None:
            entry.update(status="error",
                         detail=f"unknown check type {kind!r}")
            results.append(entry)
            continue
        try:
            ok, detail, data = handler(tris, spec)
            entry.update(status="pass" if ok else "fail",
                         detail=detail, data=data)
        except CheckError as exc:
            entry.update(status="error", detail=str(exc))
        except (KeyError, ValueError) as exc:
            entry.update(status="error", detail=f"bad spec: {exc}")
        results.append(entry)

    any_error = any(r["status"] == "error" for r in results)
    any_fail = any(r["status"] == "fail" for r in results)
    if any_error:
        status = "not_checked"
    elif any_fail:
        status = "fail"
    else:
        status = "pass"

    record = {
        "part": intent.get("part", os.path.basename(intent_path)),
        "mesh": os.path.relpath(mesh_path, base_dir),
        "mesh_sha256": _sha256(mesh_path),
        "intent_sha256": _sha256(os.path.abspath(intent_path)),
        "status": status,
        "checks": results,
        "generated_by": "printable-parts check_part.py",
    }

    if write_record and status != "not_checked":
        record_path = os.path.splitext(mesh_path)[0] + ".check.json"
        with open(record_path, "w", encoding="utf-8") as handle:
            json.dump(record, handle, indent=2)
        record["record_path"] = record_path

    return record


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("intent")
    parser.add_argument("--mesh")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--no-record", action="store_true")
    args = parser.parse_args(argv)

    try:
        record = run(args.intent, args.mesh, write_record=not args.no_record)
    except CheckError as exc:
        print(f"NOT CHECKED: {exc}", file=sys.stderr)
        return 2
    except (OSError, json.JSONDecodeError) as exc:
        print(f"NOT CHECKED: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(record, indent=2))
    else:
        print(f"{record['status'].upper()} {record['part']}  ({record['mesh']})")
        for r in record["checks"]:
            mark = {"pass": "ok  ", "fail": "FAIL", "error": "ERR "}[r["status"]]
            print(f"  [{mark}] {r['id']}: {r['detail']}")
            if r["status"] != "pass" and r["claim"]:
                print(f"         claim: {r['claim']}")

    return {"pass": 0, "fail": 1, "not_checked": 2}[record["status"]]


if __name__ == "__main__":
    sys.exit(main())
