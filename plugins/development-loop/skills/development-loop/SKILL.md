---
name: development-loop
description: Use when starting any feature, enhancement, or bugfix in a codebase (one repo, or several repos that form one system), before writing code; when tempted to jump straight to editing; when you need to understand unfamiliar code before changing it; or when a change may span a backend and a separate frontend, service, or deploy repo.
compatibility: Composes the superpowers skills (brainstorming, writing-plans, subagent-driven-development, finishing-a-development-branch) and the codegraph and cross-repo-completeness skills. Reads the Agent Skills open standard (Claude Code, Codex, opencode).
---

# Development loop

## Overview

The disciplined path for any feature or bugfix. It does not replace the
superpowers skills; it SEQUENCES them and adds two always-on habits that plain
prompting drops: **ground every code-understanding step in codegraph**, and
**verify a change's full surface across repos** when the project spans more than
one. Works the same for a single repo (the cross-repo steps are simply skipped)
and for a multi-repo system.

**Core principle: understand before you change, and finish the whole surface, not
just the file you touched.** The two failure modes this prevents are exploring
code with grep instead of the index (slow, and blind to dynamic-dispatch and
cross-repo calls), and shipping a change wired in one place and missing in the
others.

Compose, do not fork: this skill references the upstream skills by name, so their
updates flow through. If an upstream skill is unavailable, do that phase directly
and continue.

## When to use

- Starting any feature, enhancement, or bugfix, before writing code.
- Any repo shape: one repo, or several repos that make one system.

Not for: a one-line typo/doc/config tweak with no behavior change (just do it), or
a pure question (answer it).

## First: is this one repo or several?

Decide once, up front, it changes two phases:

- **Single repo:** run the loop as written, skip the steps marked (multi-repo).
- **Multi-repo system:** start from the **hub repo** (the integration/deploy repo)
  with the sibling repos checked out alongside it; clone a missing one before
  starting. The seam map is the hub's `docs/cross-repo-features.md`.

## The loop

### 1. Understand (always codegraph)

**REQUIRED:** orient with codegraph, not grep. codegraph is both a CLI/MCP tool
and a skill (`using-codegraph`): use the skill if it is installed, otherwise run
the tool directly (`codegraph sync .`, then `query` / `callers` / `callees` /
`impact`). Either way, sync the index first, confirm it is the repo you are
editing, then query symbols instead of grep. In a multi-repo system, do this per repo; run it
again before spawning any subagent that will explore code, and again after your
own edits, so callers/impact reflect the current tree. If a repo has no index,
that is the orientation gap to close first.

### 2. Brainstorm and design

**REQUIRED SUB-SKILL:** use `superpowers:brainstorming` to classify the work
(spike / bounded / architectural), refine intent and requirements, and agree on a
design before any implementation. Architectural work gets a written spec; bounded
work gets a short in-chat design.

**(multi-repo)** As part of the design, map the change's **cross-repo surface**:
which repos and seams it touches (API field, client + types, UI, config, deploy,
docs). Use the `cross-repo-completeness` skill if installed; otherwise follow the
hub's `docs/cross-repo-features.md` seam map and the per-repo MR checklist (the
skill is the optional automation of that doc). A user-facing backend capability is
not designed until the API -> client -> UI -> docs chain is in the plan.

### 3. Plan

**REQUIRED SUB-SKILL:** use `superpowers:writing-plans` to break the approved
design into small, independently testable tasks. In a multi-repo change, make each
cross-repo slice its own task so none is silently dropped, and give each touched
repo its own feature branch and MR/PR: link them and land (or track) them together.

### 4. Implement (TDD, subagent-driven)

**REQUIRED SUB-SKILL:** use `superpowers:subagent-driven-development` with
`superpowers:test-driven-development` (RED-GREEN-REFACTOR) per task, and a review
per task. Each repo uses its own test runner (for example pytest for a Python
backend, vitest for a TS frontend). Re-sync codegraph after edits that add or move
symbols.

### 5. Finish and verify the whole surface

**REQUIRED SUB-SKILL:** use `superpowers:finishing-a-development-branch` to verify
tests, push, and open the MR/PR.

**(multi-repo)** Before declaring done, audit the whole surface: run the
`cross-repo-completeness` skill in audit mode if installed, otherwise re-walk the
hub's `docs/cross-repo-features.md` seam map per repo. Complete each repo's
MR-template cross-repo checklist: confirm every slice landed and is documented, or
is explicitly deferred and tracked. **Do not skip this even when all tests pass:**
backend-green-but-UI-missing is the exact failure this phase exists to catch. A
change is done only when its whole surface is.

## Quick reference

| Phase | Skill | Always / when |
| --- | --- | --- |
| Understand | codegraph (skill if installed, else the CLI/MCP tool) | always |
| Brainstorm/design | `superpowers:brainstorming` | always |
| Map cross-repo surface | `cross-repo-completeness` | multi-repo |
| Plan | `superpowers:writing-plans` | always (non-trivial) |
| Implement | `superpowers:subagent-driven-development` + `test-driven-development` | always |
| Finish | `superpowers:finishing-a-development-branch` | always |
| Audit the surface | `cross-repo-completeness` (audit) + MR checklist | multi-repo |

## Making this always-on

Do not rely on this skill being auto-selected (skill auto-activation is
unreliable, more so for smaller models). The durable trigger is your global agent
instructions. Run `scripts/install.sh` once: it ensures the composed superpowers
skills are installed and current, installs this repo's skills into every tool's
path, and writes a managed "development conventions" block into your global
instructions (for example `~/.claude/CLAUDE.md`) that tells the agent to always use
codegraph for understanding and to run this loop for features and bugfixes. The
block is tool-agnostic so you can paste it into Codex or opencode global config too.

`references/evals.md` holds baseline-vs-with-skill scenarios for testing changes to
this loop.
