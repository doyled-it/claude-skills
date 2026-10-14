---
name: using-codegraph
description: Use when orienting in, navigating, or mapping a codebase that has a CodeGraph index (a .codegraph/ directory) — finding symbols, callers/callees, or change impact — instead of grep/find, and especially before spawning subagents that will explore code.
---

# Using CodeGraph

## Overview

CodeGraph is a precomputed per-repo index of every symbol, edge, and file (a `.codegraph/` directory at the repo root). Query it to orient and traverse code instead of rebuilding that picture with `grep`/`find`. Reads are sub-millisecond; the index lags writes by about a second.

**Core principle: an index you did not sync is an index you cannot trust.** A stale or wrong-repo index returns "no callers" / wrong-project results that silently send you (or a subagent) down the wrong path. Sync first, confirm it is the repo you are editing, then query.

## When to use

- Orienting in an unfamiliar repo, or locating a symbol / its callers / its blast radius.
- Before editing a symbol (check `impact` and which tests cover it).
- **Before spawning any subagent that will explore code** — sync the target repo first so the subagent is not querying a stale index.
- After your own edits, and before any reachability or dead-code judgment.

Skip it when there is no `.codegraph/` directory (indexing is the repo owner's choice) — use normal search then.

## The workflow

1. `codegraph status .` — is there an index, and is it current?
2. `codegraph init .` (first time) or `codegraph sync .` (stale). Sync is cheap (seconds) — run it freely.
3. `codegraph query <name>` / `codegraph explore "<question or symbols>"` to locate.
4. `codegraph callers|callees|impact <symbol>`, `codegraph affected <files...>` to traverse.
5. Only then open the specific files the graph pointed at.

## Quick reference

| Command | Answers |
|---|---|
| `codegraph status .` | Is an index present and current? |
| `codegraph init .` | Build the first index for this repo |
| `codegraph sync .` | Bring a stale index current (cheap) |
| `codegraph files` | Project structure + symbol counts per file |
| `codegraph query <name>` | Find symbols by name |
| `codegraph explore "<q>"` | Source + call paths + blast radius in one call |
| `codegraph callers <symbol>` | Who calls this |
| `codegraph callees <symbol>` | What this calls |
| `codegraph impact <symbol>` | Blast radius of changing this |
| `codegraph affected <files...>` | Which tests cover these changed files |

Run any subcommand with `--help` for flags.

## Gotchas that cause silent wrong answers

- **One index per repo.** Each repo has its own `.codegraph/` pointed at itself. In a multi-repo workspace, `cd` into the *specific* repo before running codegraph — do not assume a shared index covers the repo you are editing.
- **The MCP server is bound to ONE project.** If a `codegraph_explore` MCP tool is available, it points at whatever project its server was started against — not necessarily the repo you are in. When its results look like a different project (unfamiliar files, the wrong language), it is pointed elsewhere: stop trusting it and use the **CLI** `codegraph explore` from the correct repo. In multi-repo setups the CLI is the reliable default; the MCP tool is a convenience only when it targets the right repo.
- **A "no results" / "no callers" from a stale index is worthless.** It can lead you to delete live code. Sync before trusting a negative answer.
- **Worktrees need their own index.** A git worktree is a separate checkout; run `codegraph init -i` / `sync .` inside it, and sync again after edits before any reachability call.
- **Before a subagent dispatch**, sync the target repo; if the MCP tool might be mis-pointed, tell the subagent to use the CLI or fall back to direct reads.

## Common mistakes

| Mistake | Fix |
|---|---|
| Querying without syncing, then trusting the result | `codegraph sync .` first; it is seconds |
| Trusting MCP `codegraph_explore` results that look like another project | It is bound elsewhere; use the CLI in the correct repo |
| Running codegraph from a monorepo root expecting one repo's symbols | `cd` into the specific repo; indexes are per-repo |
| Spawning subagents against a stale/wrong index | Sync the target repo (and note the MCP caveat) before dispatch |
| Judging dead code from an old graph | Re-sync, then check `callers`/`impact` |
