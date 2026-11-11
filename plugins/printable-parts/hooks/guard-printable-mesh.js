#!/usr/bin/env node
/*
 * printable-parts PreToolUse hook (Claude Code, Bash tool).
 *
 * Two gates on text-to-cad commands, so the intent list and the functional
 * checks cannot be skipped by habit:
 *
 *   1. Export gate. A command that exports a printable mesh
 *      (`cad <type> export ... part.stl|.3mf`) is blocked when no intent file
 *      names that part. You write the measurable intent list first.
 *
 *   2. Slice / send gate. A command that slices a mesh or opens it in a
 *      slicer or printer app is blocked unless a passing check record sits
 *      beside the mesh whose SHA-256 matches the mesh on disk now. You run the
 *      checks, on this exact mesh, before anything heads for the plate.
 *
 * Fail open. Any error, anything it cannot parse, and it allows the command:
 * a hook must never wedge an unrelated session. It only ever emits a "deny",
 * never an "allow", so commands it does not recognise flow through untouched.
 *
 * Claude Code only. Other runtimes (Codex, opencode) get the soft layer: the
 * skill ordering, not this hook. See references/enforcement.md.
 */

"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const MESH_EXT = [".stl", ".3mf", ".obj", ".amf", ".step", ".stp"];
const PRINTABLE_EXT = [".stl", ".3mf"];
const SKIP_DIRS = new Set([
  ".git", "node_modules", ".codegraph", ".superpowers", ".cache", "dist",
]);
const MAX_SCAN_FILES = 400;

function deny(reason) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: reason,
      },
    })
  );
  process.exit(0);
}

function allow() {
  process.exit(0);
}

function readStdin() {
  try {
    return fs.readFileSync(0, "utf8");
  } catch (_e) {
    return "";
  }
}

function tokenize(command) {
  // Loose: strip quotes, split on whitespace and common separators. Good
  // enough to find file arguments and flags; we never execute anything.
  return command
    .replace(/[`"']/g, " ")
    .split(/[\s=]+/)
    .filter(Boolean);
}

function hasExt(tok, exts) {
  const low = tok.toLowerCase();
  return exts.some((e) => low.endsWith(e));
}

function baseNoExt(p) {
  const b = path.basename(p);
  const dot = b.lastIndexOf(".");
  return dot > 0 ? b.slice(0, dot) : b;
}

function isCadExport(command, tokens) {
  // `cad <type> export ...`: cad, then a subject type, then export.
  const m = command.match(/\bcad(?:\.exe)?\s+(model|step|stl|threemf|glb|xbf)\s+export\b/);
  if (!m) return false;
  return tokens.includes("export");
}

function looksLikeSliceOrSend(command) {
  const c = command.toLowerCase();
  const sliceFlags = ["--slice", "--export-3mf", "--export-gcode", "--export-slicedata"];
  if (sliceFlags.some((f) => c.includes(f))) return true;
  // A slicer or printer app invoked by name or path.
  if (/orca[-_ ]?slicer/.test(c)) return true;
  if (/bambustudio|bambu studio|bambu-studio|bambu connect|bambu-connect/.test(c)) return true;
  if (/open\s+-a\s+(orcaslicer|bambustudio)/.test(c)) return true;
  return false;
}

function sha256(file) {
  const h = crypto.createHash("sha256");
  h.update(fs.readFileSync(file));
  return h.digest("hex");
}

function walkFindJson(root, suffix) {
  const found = [];
  const stack = [root];
  let budget = MAX_SCAN_FILES;
  while (stack.length && budget > 0) {
    const dir = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch (_e) {
      continue;
    }
    for (const ent of entries) {
      if (budget-- <= 0) break;
      const full = path.join(dir, ent.name);
      if (ent.isDirectory()) {
        if (!SKIP_DIRS.has(ent.name) && !ent.name.startsWith(".")) {
          stack.push(full);
        }
      } else if (ent.name.toLowerCase().endsWith(suffix)) {
        found.push(full);
      }
    }
  }
  return found;
}

function loadJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (_e) {
    return null;
  }
}

// Does some intent file in the tree name this mesh (by its mesh field's
// basename, or by its part matching the mesh basename)?
function intentExistsFor(cwd, meshPath) {
  const wantMesh = path.basename(meshPath).toLowerCase();
  const wantPart = baseNoExt(meshPath).toLowerCase();
  for (const f of walkFindJson(cwd, ".intent.json")) {
    const data = loadJson(f);
    if (!data) continue;
    if (data.mesh && path.basename(String(data.mesh)).toLowerCase() === wantMesh) {
      return true;
    }
    if (data.part && String(data.part).toLowerCase() === wantPart) return true;
  }
  return false;
}

// Find a passing check record whose hash matches the mesh on disk now.
function passingRecordFor(cwd, meshAbs) {
  const candidates = [];
  const sibling = path.join(path.dirname(meshAbs), baseNoExt(meshAbs) + ".check.json");
  if (fs.existsSync(sibling)) candidates.push(sibling);
  for (const f of walkFindJson(cwd, ".check.json")) {
    if (!candidates.includes(f)) candidates.push(f);
  }
  let currentHash = null;
  try {
    currentHash = sha256(meshAbs);
  } catch (_e) {
    return { ok: false, reason: "mesh-unreadable" };
  }
  for (const f of candidates) {
    const rec = loadJson(f);
    if (!rec) continue;
    if (path.basename(String(rec.mesh || "")).toLowerCase() !== path.basename(meshAbs).toLowerCase()) {
      continue;
    }
    if (rec.status === "pass" && rec.mesh_sha256 === currentHash) {
      return { ok: true };
    }
    if (rec.status === "pass" && rec.mesh_sha256 !== currentHash) {
      return { ok: false, reason: "stale", record: f };
    }
  }
  return { ok: false, reason: "missing" };
}

function main() {
  const raw = readStdin();
  if (!raw) allow();
  let payload;
  try {
    payload = JSON.parse(raw);
  } catch (_e) {
    allow();
  }
  if (!payload || payload.tool_name !== "Bash") allow();
  const command = (payload.tool_input && payload.tool_input.command) || "";
  if (!command) allow();
  const cwd = payload.cwd || process.cwd();
  const tokens = tokenize(command);

  // Gate 1: exporting a printable mesh needs an intent file first.
  if (isCadExport(command, tokens)) {
    const outputs = tokens.filter((t) => hasExt(t, PRINTABLE_EXT));
    for (const mesh of outputs) {
      if (!intentExistsFor(cwd, mesh)) {
        deny(
          "printable-parts: no intent file names '" +
            path.basename(mesh) +
            "'. Load the printable-parts skill and write the measurable intent " +
            "list (" +
            baseNoExt(mesh) +
            ".intent.json) before exporting a mesh to print. The intent list is " +
            "what the checks read; exporting first is how an inverted countersink " +
            "or a short slot ships."
        );
      }
    }
    allow();
  }

  // Gate 2: slicing or sending needs a passing check on this exact mesh.
  if (looksLikeSliceOrSend(command)) {
    const meshes = tokens.filter(
      (t) =>
        hasExt(t, MESH_EXT) &&
        !t.toLowerCase().endsWith(".gcode.3mf") &&
        !t.toLowerCase().includes("preset")
    );
    for (const mesh of meshes) {
      const meshAbs = path.isAbsolute(mesh) ? mesh : path.join(cwd, mesh);
      if (!fs.existsSync(meshAbs)) continue; // the command will fail on its own
      const res = passingRecordFor(cwd, meshAbs);
      if (!res.ok && res.reason === "missing") {
        deny(
          "printable-parts: no passing check record for '" +
            path.basename(mesh) +
            "'. Run the printable-parts checks (check_part.py) on this mesh and " +
            "look at the cross-sections before slicing or sending it to a printer."
        );
      }
      if (!res.ok && res.reason === "stale") {
        deny(
          "printable-parts: the check record for '" +
            path.basename(mesh) +
            "' was written for a different mesh (the file changed since it last " +
            "passed). Re-run check_part.py on the current mesh before slicing."
        );
      }
    }
    allow();
  }

  allow();
}

try {
  main();
} catch (_e) {
  // Never wedge a session on our own error.
  allow();
}
