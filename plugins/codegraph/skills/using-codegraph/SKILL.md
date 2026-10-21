---
name: using-codegraph
description: Use when understanding, locating, or changing code, including when the CodeGraph index is missing, absent, or stale; before exploring a repo or dispatching code readers; and when the codegraph command is unavailable.
---

# Using CodeGraph

## Default policy

Close index gaps during code understanding. A missing `.codegraph/` directory is
an initialization step, not an opt-out. An explicit user no-index restriction
overrides this default. Honor restrictions on generated-file writes too: a
source-read-only review may refresh generated metadata only when that is allowed.
Keep `.codegraph/` untracked through existing ignore rules or an allowed local
exclude; do not edit product files during source-read-only tasks to add ignores.
If indexing is prohibited, inspect source directly and state that graph evidence
is unavailable. Never invent symbols, callers, or coverage.

CodeGraph indexes supported source files per checkout. It cannot trace an HTTP
request across repositories. Use `cross-repo-completeness` to connect the evidence
from each repository, and `development-loop` for feature and bugfix work.

## Prepare the tool

1. Check `command -v codegraph`. If it is unavailable, install the verified npm
   package with `npm install -g @colbymchenry/codegraph`. Its source is
   [colbymchenry/codegraph](https://github.com/colbymchenry/codegraph).
2. Run `codegraph telemetry off` unless the user requested telemetry. If installation
   is blocked by permissions or missing npm, report that limitation and continue
   with direct inspection. Do not silently treat a missing CLI as a user opt-out.
3. MCP registration is separate from indexing. Prefer the native plugin setup at
   [agentic-dev-setup](https://github.com/doyled-it/agentic-dev-setup) for modern
   Claude Code and Codex. Register only the intended runtime, for example
   `codegraph install --yes --target claude` or `--target codex`.
   Registration changes agent configuration and needs a restart for new MCP tools;
   the CLI can query immediately. Do not register other agents as a side effect
   of understanding this repo.

## Workflow

1. Work inside the specific checkout. Run `codegraph status .` and confirm its
   project path matches the repo you are inspecting. A worktree needs its own index.
2. If the index is missing, run `codegraph init .` (use `--yes` in unattended
   validation). Do not use `--force` to bypass home-directory or filesystem guards.
3. Run `codegraph sync .` before querying, even after initialization. Repeat after
   edits and before handing code exploration to another reader.
4. Query with `codegraph files`, `codegraph query <name>`, or
   `codegraph explore "<question or symbols>"`. Verify the returned files belong
   to this checkout. Prefer MCP only when its project binding is verified; otherwise
   use the CLI from the correct repo.
5. Use `codegraph callers <symbol>`, `codegraph callees <symbol>`, and
   `codegraph impact <symbol>` before changing indexed symbols. Run
   `codegraph affected <files...>` to find candidate tests, then read the actual
   source and tests. The graph does not prove that all necessary tests were found.

## Unsupported files and empty indexes

An index can be empty when the repository contains only unsupported file types.
For mixed repositories, a successful index may cover only some files. After the
query, directly inspect unsupported source with file reads and targeted text
search. State the coverage limit. Do not repeatedly initialize an empty index,
claim missing code is dead, or invent a graph result for Markdown, shell, config,
or any language this installed CodeGraph version does not support.

A stale-index negative result is also insufficient evidence for deletion. Sync
again before any reachability or dead-code judgment, then corroborate with source,
runtime entrypoints, external consumers, and tests.

## Per-repo checks

- In a multi-repo project, prepare each relevant repo with the same status,
  init-if-missing, sync, query sequence. A hub index cannot cover its siblings.
- A `codegraph_explore` MCP server may be bound to another project. Wrong-project
  results require switching to the correct CLI checkout, not trusting the answer.
- Before dispatch, tell the reader the checkout path, index status, known coverage
  limits, and any explicit user restrictions. When delegation is unavailable or
  prohibited, perform those reads inline.
- Code understanding authorizes indexing the relevant checkout by default; it
  does not authorize crawling unrelated workspaces. Setup installers should not
  recursively initialize every repo on the machine.

## Validation

Use `references/evals.md` for cold, stale, prohibited, unsupported, and wrong-project
cases. These are behavioral evaluation instructions, not recorded success claims.
