---
name: development-loop
description: Use when starting ANY feature or bugfix (in a single repo or a multi-repo system), before writing code. Runs a disciplined loop that grounds code understanding in codegraph, composes the superpowers phases (brainstorm, design, plan, TDD, finish), and verifies the full cross-repo surface when the project spans repos.
compatibility: Composes the superpowers skills (brainstorming, writing-plans, subagent-driven-development, finishing-a-development-branch) and the codegraph and cross-repo-feature-audit skills. Reads the Agent Skills open standard (Claude Code, Codex, opencode).
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

**REQUIRED SUB-SKILL:** use the `codegraph` skill (`using-codegraph`). Sync the
index first, confirm it is the repo you are editing, then query symbols / callers
/ callees / impact instead of grep. In a multi-repo system, do this per repo; run
it again before spawning any subagent that will explore code, and again after your
own edits, so callers/impact reflect the current tree. If a repo has no index,
that is the orientation gap to close first.

### 2. Brainstorm and design

**REQUIRED SUB-SKILL:** use `superpowers:brainstorming` to classify the work
(spike / bounded / architectural), refine intent and requirements, and agree on a
design before any implementation. Architectural work gets a written spec; bounded
work gets a short in-chat design.

**(multi-repo)** As part of the design, map the change's **cross-repo surface**
with the `cross-repo-feature-audit` skill: which repos and seams it touches
(API field, client + types, UI, config, deploy, docs). A user-facing backend
capability is not designed until the API -> client -> UI -> docs chain is in the plan.

### 3. Plan

**REQUIRED SUB-SKILL:** use `superpowers:writing-plans` to break the approved
design into small, independently testable tasks. In a multi-repo change, make each
cross-repo slice its own task so none is silently dropped.

### 4. Implement (TDD, subagent-driven)

**REQUIRED SUB-SKILL:** use `superpowers:subagent-driven-development` with
`superpowers:test-driven-development` (RED-GREEN-REFACTOR) per task, and a review
per task. Re-sync codegraph after edits that add or move symbols.

### 5. Finish and verify the whole surface

**REQUIRED SUB-SKILL:** use `superpowers:finishing-a-development-branch` to verify
tests, push, and open the MR/PR.

**(multi-repo)** Before declaring done, run the `cross-repo-feature-audit` skill in
audit mode and complete each repo's MR-template cross-repo checklist: confirm every
slice landed and is documented, or is explicitly deferred and tracked. A change is
done only when its whole surface is.

## Quick reference

| Phase | Skill | Always / when |
| --- | --- | --- |
| Understand | codegraph (`using-codegraph`) | always |
| Brainstorm/design | `superpowers:brainstorming` | always |
| Map cross-repo surface | `cross-repo-feature-audit` | multi-repo |
| Plan | `superpowers:writing-plans` | always (non-trivial) |
| Implement | `superpowers:subagent-driven-development` + `test-driven-development` | always |
| Finish | `superpowers:finishing-a-development-branch` | always |
| Audit the surface | `cross-repo-feature-audit` (audit) + MR checklist | multi-repo |

## Making this always-on

Do not rely on this skill being auto-selected (skill auto-activation is
unreliable, more so for smaller models). The durable trigger is your global agent
instructions. Run `scripts/install.sh` once: it installs the skills into every
tool's path and writes a managed "development conventions" block into your global
instructions (for example `~/.claude/CLAUDE.md`) that tells the agent to always use
codegraph for understanding and to run this loop for features and bugfixes. The
block is tool-agnostic so you can paste it into Codex or opencode global config too.
