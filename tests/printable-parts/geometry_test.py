# /// script
# requires-python = ">=3.9"
# ///
"""Regression test for the printable-parts measurement and check scripts.

It builds fixture meshes that carry the two defects the brief describes as
real: a countersink inverted so the screw head cannot seat, and a shelf-clip
slot cut to 22 mm when its parameters asked for 27 mm. Both pass a file-format
test and a DFM check. This test proves the printable-parts checks catch them on
the mesh, and that a correct mesh passes.

Standard library only. Run with `uv run geometry_test.py` or `python3`.
"""

from __future__ import annotations

import json
import math
import os
import struct
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.normpath(
    os.path.join(HERE, "..", "..", "plugins", "printable-parts",
                 "skills", "printable-parts", "scripts")
)
sys.path.insert(0, SCRIPTS)

import stl_measure as M  # noqa: E402
import check_part as C  # noqa: E402


# --- fixture mesh construction (open-walled shells; sections and the bounding
# --- box are what the checks read, so caps are unnecessary) ------------------

def _quad(a, b, c, d):
    return [(a, b, c), (a, c, d)]


def _box_walls(x0, y0, x1, y1, z0, z1):
    tris = []
    corners = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
    for i in range(4):
        (ax, ay) = corners[i]
        (bx, by) = corners[(i + 1) % 4]
        tris += _quad((ax, ay, z0), (bx, by, z0), (bx, by, z1), (ax, ay, z1))
    return tris


def _cylinder_wall(cx, cy, r, z0, z1, n=72):
    tris = []
    for i in range(n):
        a0 = 2 * math.pi * i / n
        a1 = 2 * math.pi * (i + 1) / n
        p0 = (cx + r * math.cos(a0), cy + r * math.sin(a0))
        p1 = (cx + r * math.cos(a1), cy + r * math.sin(a1))
        tris += _quad((p0[0], p0[1], z0), (p1[0], p1[1], z0),
                      (p1[0], p1[1], z1), (p0[0], p0[1], z1))
    return tris


def _write_binary_stl(path, tris):
    with open(path, "wb") as f:
        f.write(b"printable-parts fixture".ljust(80, b"\0"))
        f.write(struct.pack("<I", len(tris)))
        for tri in tris:
            f.write(struct.pack("<12f", 0.0, 0.0, 0.0,
                                *tri[0], *tri[1], *tri[2]))
            f.write(struct.pack("<H", 0))


# Plate 60 x 30 x 12. A screw hole at (15, 15): a counterbore for the head
# (radius 4.0) in the top 3 mm, a clearance pilot (radius 2.2) below. A shelf
# clip slot at (40, 15), width along x, length 6 along y, through the plate.
PLATE = (60.0, 30.0, 12.0)
HOLE_C = (15.0, 15.0)
R_HEAD = 4.0
R_PILOT = 2.2
Z_STEP = 9.0
SLOT_C = (40.0, 15.0)
SLOT_LEN_Y = 6.0


def build_part(path, head_on_top, slot_width):
    x, y, z = PLATE
    tris = _box_walls(0, 0, x, y, 0, z)
    if head_on_top:
        tris += _cylinder_wall(*HOLE_C, R_HEAD, Z_STEP, z)       # wide at top
        tris += _cylinder_wall(*HOLE_C, R_PILOT, 0.0, Z_STEP)    # narrow below
    else:
        tris += _cylinder_wall(*HOLE_C, R_PILOT, Z_STEP, z)      # narrow at top
        tris += _cylinder_wall(*HOLE_C, R_HEAD, 0.0, Z_STEP)     # wide below
    sx, sy = SLOT_C
    hw, hl = slot_width / 2.0, SLOT_LEN_Y / 2.0
    tris += _box_walls(sx - hw, sy - hl, sx + hw, sy + hl, 0, z)
    _write_binary_stl(path, tris)


def records(decision="design_new"):
    """A valid pre-modeling record block: a prior-art decision and a device
    reference tier. The perch touches a USB Bluetooth adapter, modeled from its
    datasheet envelope (tier 3)."""
    pa = {"decision": decision, "reason": "nothing close found; fit is specific"}
    if decision in ("use_as_is", "remix"):
        pa["found"] = [{"url": "https://example.test/x", "license": "CC BY 4.0"}]
    return {
        "prior_art": pa,
        "devices": [
            {"name": "usb-bt-adapter", "reference_tier": 3,
             "source": "datasheet envelope, mounting pitch from drawing"},
        ],
    }


def intent_for(mesh_path, slot_expected=27.0):
    return {
        "part": "perch",
        "mesh": os.path.basename(mesh_path),
        "units": "mm",
        "params": {"slot_mm": slot_expected, "head_r": R_HEAD, "pilot_r": R_PILOT},
        **records(),
        "intents": [
            {"id": "envelope", "claim": "40 wide shelf perch, 60 x 30 x 12 mm",
             "check": {"type": "bbox", "expected_mm": [60, 30, 12],
                       "tolerance_mm": 0.4}},
            {"id": "countersink",
             "claim": "screw head seats flush: hole wider at the top face",
             "check": {"type": "countersink_orientation", "axis": "z",
                       "near": [15, 15], "top_at": 11.0, "bottom_at": 1.0,
                       "top_wider": True, "min_delta_mm": 1.0}},
            {"id": "pilot", "claim": "M4 clearance pilot, radius 2.2 mm",
             "check": {"type": "hole_radius", "axis": "z", "at": 1.0,
                       "near": [15, 15], "measure": "equiv_radius",
                       "expected_mm": 2.2, "tolerance_mm": 0.3}},
            {"id": "shelf-slot",
             "claim": "25 mm shelf fits the clip with 2 mm play: slot 27 mm",
             "check": {"type": "slot_width", "axis": "z", "at": 6.0,
                       "along": "u", "near": [40, 15],
                       "expected_mm": slot_expected, "tolerance_mm": 0.5}},
        ],
    }


# --- assertions --------------------------------------------------------------

FAILURES = []


def expect(cond, msg):
    if cond:
        print(f"  ok   {msg}")
    else:
        print(f"  FAIL {msg}")
        FAILURES.append(msg)


def by_id(record, cid):
    return next(r for r in record["checks"] if r["id"] == cid)


def run():
    tmp = tempfile.mkdtemp(prefix="pp_geom_")

    # 1. Raw measurement sanity on the good mesh.
    good = os.path.join(tmp, "perch_good.stl")
    build_part(good, head_on_top=True, slot_width=27.0)
    tris = M.read_mesh(good)
    box = M.bounding_box(tris)
    expect(all(abs(box["size"][i] - PLATE[i]) < 0.01 for i in range(3)),
           f"bbox reads {['%.2f' % s for s in box['size']]} == 60 x 30 x 12")

    top = M.nearest_hole(M.section_features(tris, "z", 11.0), (15, 15))
    bot = M.nearest_hole(M.section_features(tris, "z", 1.0), (15, 15))
    expect(abs(top["equiv_radius"] - R_HEAD) < 0.05,
           f"hole radius at top face {top['equiv_radius']:.3f} ~= 4.0")
    expect(abs(bot["equiv_radius"] - R_PILOT) < 0.05,
           f"hole radius at bottom face {bot['equiv_radius']:.3f} ~= 2.2")
    slot = M.nearest_hole(M.section_features(tris, "z", 6.0), (40, 15))
    expect(abs(slot["width_u"] - 27.0) < 0.05,
           f"slot width {slot['width_u']:.3f} ~= 27.0")

    # 2. The good part passes every intent, and writes a check record.
    gi = os.path.join(tmp, "perch_good.intent.json")
    with open(gi, "w") as f:
        json.dump(intent_for(good), f)
    rec = C.run(gi)
    expect(rec["status"] == "pass", f"good part status == pass (got {rec['status']})")
    rp = os.path.splitext(good)[0] + ".check.json"
    expect(os.path.exists(rp), "check record written beside the mesh")
    if os.path.exists(rp):
        with open(rp) as f:
            saved = json.load(f)
        expect(saved["mesh_sha256"] == C._sha256(good),
               "check record carries the SHA-256 of the mesh it judged")

    # 3. The defective part: inverted countersink AND a 22 mm slot. Both are
    #    the real defects; both must be caught on the mesh.
    bad = os.path.join(tmp, "perch_bad.stl")
    build_part(bad, head_on_top=False, slot_width=22.0)
    bi = os.path.join(tmp, "perch_bad.intent.json")
    with open(bi, "w") as f:
        json.dump(intent_for(bad), f)
    rec = C.run(bi)
    expect(rec["status"] == "fail",
           f"defective part status == fail (got {rec['status']})")
    expect(by_id(rec, "countersink")["status"] == "fail",
           "inverted countersink is caught (heads cannot seat)")
    expect(by_id(rec, "shelf-slot")["status"] == "fail",
           "short 22 mm slot is caught (asked for 27 mm)")
    expect(by_id(rec, "envelope")["status"] == "pass",
           "envelope still passes: the defects are internal, not the bbox")

    # 4. Stale-file guard: a parameter changed (slot 27 -> 30) without a
    #    re-export makes the expectation disagree with the stale mesh.
    stale_intent = os.path.join(tmp, "perch_stale.intent.json")
    with open(stale_intent, "w") as f:
        json.dump(intent_for(good, slot_expected=30.0), f)
    rec = C.run(stale_intent, write_record=False)
    expect(by_id(rec, "shelf-slot")["status"] == "fail",
           "stale guard: bumped slot param without re-export fails the check")

    # 5. 3MF reads the same as STL (format parity).
    try:
        threemf = os.path.join(tmp, "perch_good.3mf")
        _write_3mf(threemf, M.read_mesh(good))
        box2 = M.bounding_box(M.read_mesh(threemf))
        expect(all(abs(box2["size"][i] - PLATE[i]) < 0.01 for i in range(3)),
               "3MF parses to the same bounding box as the STL")
    except Exception as exc:  # noqa: BLE001
        expect(False, f"3MF round-trip raised {exc}")

    # 6. The pre-modeling records (step 0 prior art, step 1.5 reference
    #    hardware) are checked on the intent file, before the geometry.
    def rec_status(intent, which):
        return next(r for r in C.validate_records(intent) if r["type"] == which)["status"]

    good_intent = {**records(), "intents": []}
    expect(rec_status(good_intent, "prior_art") == "pass",
           "valid prior_art (design_new + reason) passes")
    expect(rec_status(good_intent, "reference_hardware") == "pass",
           "a device with a reference_tier and source passes")

    expect(rec_status({"intents": []}, "prior_art") == "fail",
           "a missing prior_art record fails")
    expect(rec_status({"prior_art": {"decision": "remix", "reason": "r"},
                       "devices": []}, "prior_art") == "fail",
           "remix with no found design (url + license) fails")
    expect(rec_status({"devices": [{"name": "d", "reference_tier": 9,
                                    "source": "s"}]}, "reference_hardware") == "fail",
           "a device with an out-of-range reference_tier fails")
    expect(rec_status({"devices": [{"name": "d", "reference_tier": 5,
                                    "source": "s"}]}, "reference_hardware") == "fail",
           "tier 5 (estimate) without unverified:true fails")
    expect(rec_status({"devices": []}, "reference_hardware") == "pass",
           "an explicit empty devices list passes (part touches none)")

    # A good mesh with a missing prior-art record fails the whole check, so the
    # records gate the part just like a bad dimension does.
    norec = os.path.join(tmp, "perch_norec.intent.json")
    bare = intent_for(good)
    del bare["prior_art"]
    with open(norec, "w") as f:
        json.dump(bare, f)
    rec = C.run(norec, write_record=False)
    expect(rec["status"] == "fail",
           "a geometrically correct mesh fails when prior_art is absent")

    print()
    if FAILURES:
        print(f"GEOMETRY TEST FAILED: {len(FAILURES)} assertion(s)")
        return 1
    print("GEOMETRY TEST PASSED")
    return 0


def _write_3mf(path, tris):
    import zipfile
    verts = []
    index = {}
    faces = []
    for tri in tris:
        idx = []
        for v in tri:
            key = tuple(round(c, 5) for c in v)
            if key not in index:
                index[key] = len(verts)
                verts.append(v)
            idx.append(index[key])
        faces.append(idx)
    ns = "http://schemas.microsoft.com/3dmanufacturing/core/2015/02"
    vx = "".join(f'<vertex x="{v[0]}" y="{v[1]}" z="{v[2]}"/>' for v in verts)
    tx = "".join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in faces)
    model = (
        f'<?xml version="1.0" encoding="UTF-8"?>'
        f'<model unit="millimeter" xmlns="{ns}"><resources>'
        f'<object id="1" type="model"><mesh>'
        f"<vertices>{vx}</vertices><triangles>{tx}</triangles>"
        f'</mesh></object></resources>'
        f'<build><item objectid="1"/></build></model>'
    )
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("3D/3dmodel.model", model)


if __name__ == "__main__":
    sys.exit(run())
