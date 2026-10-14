---
name: cross-repo-completeness
description: Use when building, reviewing, or finishing a change (a feature, bugfix, or refactor) in a multi-repo system (a backend or API repo plus a separate frontend, service, or deploy repo) and you must confirm it is wired and documented across every repo it touches, not just the one you started in; when a change works in the backend but may not reach the UI; or when setting up cross-repo completeness discipline in a project.
compatibility: Reads the Agent Skills standard (Claude Code, Codex, opencode). Pairs with the codegraph skill as its per-repo engine. Expects the system's repos checked out as siblings; setup mode's scaffold.py needs Python 3.
---

# Cross-repo feature audit

## Overview

In a multi-repo system a feature almost never lives in one repo. A new backend
capability has to cross the seam to the frontend (API field, then client, then
UI, then UI docs), and often touches config, deploy, and docs in several repos.
The seams are exactly what gets dropped, so the change ships "done" in the repo
you started in and silently never reaches users.

**Core principle: a cross-repo feature is not done when only the repo you started
in is updated.** It is done when every slice of its surface has landed and is
documented. One repo's view, and a single-repo tool like `codegraph`, cannot see
across the HTTP/API boundary; you have to look in each repo.

This skill fans a reader into each repo and checks the whole chain. Its per-repo
engine is codegraph: **PAIR WITH the codegraph skill** (`using-codegraph`) for
navigation inside each repo; this skill composes those per-repo views across the
boundary codegraph cannot follow.

## When to use

- Designing a feature that plausibly spans repos (a new generation/method/model,
  a new API-backed UI control, a new retrieval strategy, a config/service change).
- Finishing one: before calling it done or opening an MR, to catch a missing slice.
- Reviewing one: an MR that looks backend-only but should reach the UI.
- Bootstrapping the discipline in a project that lacks a seam map (setup mode).

Not for: a change genuinely contained in one repo with no external seam (say it,
do not assume it).

## Two modes

### Setup mode (map the system)

Run once per project to produce the shared artifacts this audit reads later:

1. Fan a reader into each repo (use codegraph to orient). Each returns: the repo's
   responsibility, its public seam (the HTTP routes it exposes or consumes, the
   client module and types on the consuming side, config/env it owns), and its docs.
2. Scaffold the shared files with the bundled script, so the boilerplate is
   identical every time instead of improvised (deterministic work belongs in a
   script, not the model):
   `python scripts/scaffold.py --hub <hub-repo> --repo <repo> [--repo <repo> ...] --forge <gitlab|github> --remote-base <clone-base>`
   It writes a `cross-repo-features.md` skeleton in the hub plus a request-template
   checklist, a `CONTRIBUTING.md`, and a README pointer in each repo.
3. Fill in the skeleton's TODOs (the judgment part): the real repo map, the seams,
   the feature-type to surface table. Add a one-line pointer to the guide from each
   repo's agent memory file (AGENTS.md / CLAUDE.md).
4. Name the home-base repo (usually the deploy/integration repo) and the
   convention: run the coding agent there with the sibling repos cloned alongside.

### Audit mode (check one feature)

Given a named feature, confirm its full surface:

1. Load the project's `cross-repo-features.md` (its seam map). If none exists, run
   setup mode first, or derive the seams live.
2. **Confirm the backend capability is end-to-end functional and reachable FIRST.**
   An "implemented" core may be orphaned: no non-test caller, no emitter/output
   step, a dead sub-package. Run `codegraph callers` on its entrypoint and trace a
   real path to output. If the capability itself is unfinished, that is the first
   gap; do not mark the backend slice present just because the code exists.
3. Fan one reader per repo (each using codegraph). Ask each, for THIS feature:
   what is wired here, what is missing, what is undocumented. Name files and symbols.
4. Walk the primary seam end to end and report each slice as present / missing /
   undocumented. For a backend capability that should reach a UI, the chain is:
   backend logic, AND its internal selector/registry + dispatch when the feature is
   a choice (method/model/mode) -> the API field on EVERY entrypoint that triggers
   the capability (the async job route the UI submits through, any sync endpoint,
   the CLI), not just the one path -> a discovery/enumeration endpoint if the UI must
   list the options -> frontend client fn + types -> frontend UI control -> frontend
   user docs. Also check config/env/deploy and docs in each affected repo.
5. Report the gaps, each as a concrete slice in a named repo. A slice that genuinely
   does not apply is marked N/A (a valid outcome, for example a per-request option
   needs no deploy/config change), not invented; a deferred slice is fine only if it
   is stated and tracked, never silently missing.

Fan-out is a parallel-agents job (one agent per repo, running concurrently); use
your harness's parallel-agent or workflow mechanism, and have each agent run
codegraph in its repo before reading files.

## The seam checklist (adapt to the project)

- [ ] The backend capability itself is functional and reachable (not an orphaned core)
- [ ] Backend logic, plus its internal selector/registry + dispatch if the feature is a choice
- [ ] The API field on EVERY entrypoint that triggers it (the route the UI uses, any sync endpoint, the CLI)
- [ ] A discovery/enumeration endpoint, if the UI must list the options
- [ ] The frontend API client fn and its types (both; a UI control with no client has nothing to call)
- [ ] The frontend UI control (route/component) AND its user docs
- [ ] The other service's endpoint/index, if the feature touches retrieval/search/etc.
- [ ] Config / env / deploy in the integration repo (mark N/A for a per-request option)
- [ ] Docs updated in EACH affected repo (README / agent memory file / guides)
- [ ] Any deferred slice explicitly noted and tracked

## Common mistakes

- **Treating an orphaned core as a done backend.** An "implemented" sub-package
  with no non-test caller and no output path cannot ship. Confirm the capability is
  end-to-end functional (`codegraph callers` on its entrypoint) before auditing its
  outward seams; otherwise you mark the backend present when it is the first gap.
- **Trusting a single-repo tool across the boundary.** codegraph cannot follow a
  call through an HTTP API into another repo; "no callers" in one repo is not
  "unused". Fan out per repo.
- **Putting a new option on the wrong endpoint.** If the UI submits through a
  specific endpoint (for example an async job-create route), a field added only to
  a different synchronous route leaves the feature unreachable from the UI. Verify
  which endpoint the client actually calls.
- **Shipping the UI control without the client layer.** A picker needs a client
  fn AND types to populate it, not just a component.
- **Calling it done at the backend.** Coverage in one repo reads as "covered
  everything" when the UI and docs never landed.
- **Guessing the seams.** Read the code: command names, routes, and client fns
  drift. Even careful reviews get cross-repo facts backward; confirm each.

## Red flags (stop and widen the audit)

- "It works in the backend, so the feature is done."
- "I only changed one repo, so there is nothing else to check."
- Reasoning about what the frontend does without opening the frontend repo.
- A CLI/endpoint/command name asserted from memory rather than read from the code.

Each means: open every repo the feature touches and walk the full seam before
declaring it done.

## Bundled files, portability, and model notes

- `scripts/scaffold.py` writes the setup-mode boilerplate deterministically (see
  setup mode). `references/evals.md` holds baseline-vs-with-skill test scenarios.
- This skill is the Agent Skills open standard, so the same `SKILL.md` runs in
  Claude Code, Codex, and opencode; only the install path differs. The repo's
  `scripts/install-skills.sh` symlinks it into each tool's path
  (`~/.agents/skills`, `~/.claude/skills`); Claude Code can also load the repo as a
  plugin marketplace.
- The audit steps are deliberately explicit and low-freedom: follow them in order
  rather than improvising, which also keeps the skill reliable when a smaller or
  open-weight model is driving the agent. Do not rely on this skill being
  auto-selected; the discipline's durable home is the repo itself (the MR-template
  checklist, CONTRIBUTING, and agent memory files that setup mode installs), with
  this skill as the on-demand technique.
