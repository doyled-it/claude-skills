# /// script
# requires-python = ">=3.9"
# ///
"""Measure printed-part features directly on an exported STL or 3MF mesh.

Standard library only, so it runs in any repo's CI with `uv run` or plain
`python3`. It parses binary and ASCII STL, and 3MF (the mesh inside the
OPC zip), then measures the things a functional check needs that a
file-format test and a DFM check never look at:

  * the bounding box of the solid;
  * the profile of every hole, slot and pocket on a cross-section plane,
    so a countersink that is wider at the wrong face, or a slot cut to the
    wrong width, shows up as a number.

The mesh is the source of truth. Measuring the model code would miss an
export that never ran, a unit slip, or a kernel that tessellated something
other than what the code meant.

Usage:
  python3 stl_measure.py bbox MESH [--json]
  python3 stl_measure.py section MESH --axis z --at H [--json]
  python3 stl_measure.py hole MESH --axis z --at H [--near U,V] [--json]
  python3 stl_measure.py slot MESH --axis z --at H --along u [--near U,V] [--json]

Axis is the plane normal (z means a plane of constant z). The two in-plane
axes are named u and v, in x < y < z order with the section axis removed:
for an --axis z section, u is x and v is y.
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
import zipfile
from xml.etree import ElementTree

# A shared tessellation vertex lands on the same float in every triangle that
# touches it, so rounding section points to 0.1 micron makes coincident
# endpoints hash equal while keeping genuinely distinct points apart.
_STITCH_DECIMALS = 4
# Loops shorter than this (in the plane's units, mm) are tessellation noise,
# not a feature a person designed. 0.05 mm is well under a printable detail.
_MIN_LOOP_SPAN = 0.05

Vec3 = tuple
Triangle = tuple


def read_mesh(path: str) -> list:
    """Return a list of triangles; each triangle is three (x, y, z) tuples."""
    with open(path, "rb") as handle:
        head = handle.read(5)
    if path.lower().endswith(".3mf"):
        return _read_3mf(path)
    if head[:5] == b"solid":
        # "solid" can still head a binary file, so fall back on a parse error.
        try:
            tris = _read_ascii_stl(path)
            if tris:
                return tris
        except (ValueError, UnicodeDecodeError):
            pass
    return _read_binary_stl(path)


def _read_binary_stl(path: str) -> list:
    with open(path, "rb") as handle:
        data = handle.read()
    if len(data) < 84:
        raise ValueError(f"{path}: too short to be a binary STL")
    count = struct.unpack_from("<I", data, 80)[0]
    expected = 84 + count * 50
    if len(data) != expected:
        raise ValueError(
            f"{path}: not a binary STL (count {count} implies {expected} bytes, "
            f"file is {len(data)})"
        )
    tris = []
    offset = 84
    for _ in range(count):
        # 50-byte record: normal (3 floats), then 3 vertices (9 floats), then
        # a 2-byte attribute. Skip the normal, keep the 9 vertex floats.
        vals = struct.unpack_from("<9f", data, offset + 12)
        tris.append(
            (
                (vals[0], vals[1], vals[2]),
                (vals[3], vals[4], vals[5]),
                (vals[6], vals[7], vals[8]),
            )
        )
        offset += 50
    return tris


def _read_ascii_stl(path: str) -> list:
    tris = []
    verts = []
    with open(path, "r", encoding="utf-8", errors="strict") as handle:
        for line in handle:
            parts = line.split()
            if len(parts) == 4 and parts[0] == "vertex":
                verts.append((float(parts[1]), float(parts[2]), float(parts[3])))
                if len(verts) == 3:
                    tris.append((verts[0], verts[1], verts[2]))
                    verts = []
    return tris


def _read_3mf(path: str) -> list:
    tris = []
    with zipfile.ZipFile(path) as zf:
        model_names = [n for n in zf.namelist() if n.lower().endswith(".model")]
        if not model_names:
            raise ValueError(f"{path}: no 3D model part inside the 3MF")
        for name in model_names:
            root = ElementTree.fromstring(zf.read(name))
            for mesh in root.iter():
                if not mesh.tag.endswith("}mesh") and mesh.tag != "mesh":
                    continue
                points = []
                for child in mesh:
                    tag = child.tag.split("}")[-1]
                    if tag == "vertices":
                        for vtx in child:
                            points.append(
                                (
                                    float(vtx.get("x")),
                                    float(vtx.get("y")),
                                    float(vtx.get("z")),
                                )
                            )
                    elif tag == "triangles":
                        for tri in child:
                            a = int(tri.get("v1"))
                            b = int(tri.get("v2"))
                            c = int(tri.get("v3"))
                            tris.append((points[a], points[b], points[c]))
    if not tris:
        raise ValueError(f"{path}: 3MF held no triangles")
    return tris


def bounding_box(tris: list) -> dict:
    lo = [math.inf, math.inf, math.inf]
    hi = [-math.inf, -math.inf, -math.inf]
    for tri in tris:
        for vx in tri:
            for i in range(3):
                lo[i] = min(lo[i], vx[i])
                hi[i] = max(hi[i], vx[i])
    return {
        "min": lo,
        "max": hi,
        "size": [hi[i] - lo[i] for i in range(3)],
    }


_AXES = {"x": 0, "y": 1, "z": 2}


def _plane_point(p0, p1, axis_i, level):
    """Interpolate where the segment p0->p1 crosses the plane at `level`."""
    d0 = p0[axis_i] - level
    d1 = p1[axis_i] - level
    t = d0 / (d0 - d1)
    return tuple(p0[i] + t * (p1[i] - p0[i]) for i in range(3))


def _in_plane_axes(axis_i):
    return [i for i in range(3) if i != axis_i]


def section_segments(tris: list, axis: str, level: float) -> list:
    """Return the 2D segments where the mesh crosses the plane `axis=level`.

    Each segment is ((u0, v0), (u1, v1)) in the two in-plane axes. Choose a
    `level` that is not exactly on a vertex; a plane through a vertex or along
    an edge is degenerate, so callers measure at mid-feature heights.
    """
    axis_i = _AXES[axis]
    ua, va = _in_plane_axes(axis_i)
    segs = []
    for tri in tris:
        sides = [v[axis_i] - level for v in tri]
        above = [s > 0 for s in sides]
        if all(above) or not any(above):
            continue  # wholly on one side
        crossings = []
        for a in range(3):
            b = (a + 1) % 3
            if (sides[a] > 0) != (sides[b] > 0):
                pt = _plane_point(tri[a], tri[b], axis_i, level)
                crossings.append((pt[ua], pt[va]))
        if len(crossings) == 2:
            segs.append((crossings[0], crossings[1]))
    return segs


def _key(pt):
    return (round(pt[0], _STITCH_DECIMALS), round(pt[1], _STITCH_DECIMALS))


def stitch_loops(segments: list) -> list:
    """Assemble 2D segments into closed loops by matching shared endpoints."""
    from collections import defaultdict

    adjacency = defaultdict(list)
    for idx, (a, b) in enumerate(segments):
        adjacency[_key(a)].append((idx, b))
        adjacency[_key(b)].append((idx, a))

    used = [False] * len(segments)
    loops = []
    for start_idx in range(len(segments)):
        if used[start_idx]:
            continue
        a, b = segments[start_idx]
        used[start_idx] = True
        loop = [a, b]
        current = b
        while True:
            nxt = None
            for idx, other in adjacency[_key(current)]:
                if not used[idx]:
                    used[idx] = True
                    nxt = other
                    break
            if nxt is None:
                break
            if _key(nxt) == _key(loop[0]):
                break  # closed
            loop.append(nxt)
            current = nxt
        if len(loop) >= 3:
            loops.append(loop)
    return loops


def _polygon_area(loop):
    area = 0.0
    n = len(loop)
    for i in range(n):
        u0, v0 = loop[i]
        u1, v1 = loop[(i + 1) % n]
        area += u0 * v1 - u1 * v0
    return area / 2.0


def _centroid(loop):
    area = _polygon_area(loop)
    if abs(area) < 1e-12:
        us = [p[0] for p in loop]
        vs = [p[1] for p in loop]
        return (sum(us) / len(us), sum(vs) / len(vs))
    cu = cv = 0.0
    n = len(loop)
    for i in range(n):
        u0, v0 = loop[i]
        u1, v1 = loop[(i + 1) % n]
        cross = u0 * v1 - u1 * v0
        cu += (u0 + u1) * cross
        cv += (v0 + v1) * cross
    return (cu / (6 * area), cv / (6 * area))


def _point_in_polygon(pt, loop):
    u, v = pt
    inside = False
    n = len(loop)
    j = n - 1
    for i in range(n):
        ui, vi = loop[i]
        uj, vj = loop[j]
        if ((vi > v) != (vj > v)) and (
            u < (uj - ui) * (v - vi) / (vj - vi + 1e-30) + ui
        ):
            inside = not inside
        j = i
    return inside


def _span(loop):
    us = [p[0] for p in loop]
    vs = [p[1] for p in loop]
    return max(max(us) - min(us), max(vs) - min(vs))


def section_features(tris: list, axis: str, level: float) -> dict:
    """Measure each loop on the section plane, classifying holes by nesting.

    A loop is a hole when it sits inside an odd number of other loops
    (even-odd nesting): the outer boundary is depth 0, a hole through the
    solid is depth 1.
    """
    segs = section_segments(tris, axis, level)
    loops = [lp for lp in stitch_loops(segs) if _span(lp) >= _MIN_LOOP_SPAN]
    records = []
    for i, loop in enumerate(loops):
        cen = _centroid(loop)
        depth = 0
        for j, other in enumerate(loops):
            if i != j and _point_in_polygon(cen, other):
                depth += 1
        area = abs(_polygon_area(loop))
        us = [p[0] for p in loop]
        vs = [p[1] for p in loop]
        dists = [math.hypot(p[0] - cen[0], p[1] - cen[1]) for p in loop]
        records.append(
            {
                "centroid": [cen[0], cen[1]],
                "area": area,
                "equiv_radius": math.sqrt(area / math.pi) if area > 0 else 0.0,
                "min_radius": min(dists) if dists else 0.0,
                "max_radius": max(dists) if dists else 0.0,
                "width_u": max(us) - min(us),
                "width_v": max(vs) - min(vs),
                "is_hole": depth % 2 == 1,
                "depth": depth,
            }
        )
    holes = [r for r in records if r["is_hole"]]
    return {"axis": axis, "level": level, "loops": records, "holes": holes}


def nearest_hole(features: dict, near):
    holes = features["holes"]
    if not holes:
        return None
    if near is None:
        # Default to the largest hole, the dominant feature on the plane.
        return max(holes, key=lambda r: r["area"])
    return min(
        holes,
        key=lambda r: math.hypot(
            r["centroid"][0] - near[0], r["centroid"][1] - near[1]
        ),
    )


def _parse_near(text):
    if text is None:
        return None
    parts = text.split(",")
    if len(parts) != 2:
        raise SystemExit("--near wants U,V (two numbers)")
    return (float(parts[0]), float(parts[1]))


def _emit(payload, as_json):
    if as_json:
        print(json.dumps(payload, indent=2))
    else:
        print(_human(payload))


def _human(payload):
    if "size" in payload:
        s = payload["size"]
        mn = payload["min"]
        mx = payload["max"]
        return (
            f"bbox size {s[0]:.3f} x {s[1]:.3f} x {s[2]:.3f} mm\n"
            f"  min ({mn[0]:.3f}, {mn[1]:.3f}, {mn[2]:.3f})\n"
            f"  max ({mx[0]:.3f}, {mx[1]:.3f}, {mx[2]:.3f})"
        )
    if "hole" in payload:
        h = payload["hole"]
        if h is None:
            return f"no hole on plane {payload['axis']}={payload['level']}"
        return (
            f"hole on {payload['axis']}={payload['level']}: "
            f"equiv_radius {h['equiv_radius']:.3f} mm "
            f"(min {h['min_radius']:.3f}, max {h['max_radius']:.3f}), "
            f"width_u {h['width_u']:.3f}, width_v {h['width_v']:.3f}, "
            f"centroid ({h['centroid'][0]:.3f}, {h['centroid'][1]:.3f})"
        )
    if "loops" in payload:
        lines = [f"section {payload['axis']}={payload['level']}: "
                 f"{len(payload['loops'])} loop(s), "
                 f"{len(payload['holes'])} hole(s)"]
        for r in payload["loops"]:
            kind = "hole" if r["is_hole"] else "outer"
            lines.append(
                f"  {kind} equiv_radius {r['equiv_radius']:.3f} "
                f"width_u {r['width_u']:.3f} width_v {r['width_v']:.3f} "
                f"at ({r['centroid'][0]:.3f}, {r['centroid'][1]:.3f})"
            )
        return "\n".join(lines)
    return json.dumps(payload)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_bbox = sub.add_parser("bbox", help="bounding box of the mesh")
    p_bbox.add_argument("mesh")
    p_bbox.add_argument("--json", action="store_true")

    for name in ("section", "hole", "slot"):
        sp = sub.add_parser(name)
        sp.add_argument("mesh")
        sp.add_argument("--axis", choices=list(_AXES), required=True)
        sp.add_argument("--at", type=float, required=True)
        sp.add_argument("--near")
        sp.add_argument("--json", action="store_true")
        if name == "slot":
            sp.add_argument("--along", choices=["u", "v"], required=True)

    args = parser.parse_args(argv)
    tris = read_mesh(args.mesh)

    if args.cmd == "bbox":
        _emit(bounding_box(tris), args.json)
        return 0

    feats = section_features(tris, args.axis, args.at)
    if args.cmd == "section":
        _emit(feats, args.json)
        return 0

    hole = nearest_hole(feats, _parse_near(args.near))
    if args.cmd == "hole":
        _emit({"axis": args.axis, "level": args.at, "hole": hole}, args.json)
        return 0 if hole else 1

    if args.cmd == "slot":
        if hole is None:
            _emit({"axis": args.axis, "level": args.at, "hole": None}, args.json)
            return 1
        width = hole["width_u"] if args.along == "u" else hole["width_v"]
        payload = {
            "axis": args.axis,
            "level": args.at,
            "along": args.along,
            "slot_width": width,
            "hole": hole,
        }
        _emit(payload, args.json)
        return 0
    return 2


if __name__ == "__main__":
    sys.exit(main())
