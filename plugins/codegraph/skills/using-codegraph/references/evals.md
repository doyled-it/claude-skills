# CodeGraph evaluation scenarios

Use disposable repos and the actual installed CLI. Compare a fresh baseline
without the skill to a run explicitly loading `codegraph:using-codegraph` (or
bare `using-codegraph` in a shared fallback). Record the loader event or SKILL.md
read, command order, exit status, actual symbols, and limitations. A name in prose
is not an invocation. These are evaluation criteria, not success claims.

| Scenario | Task and baseline failure | Pass criteria |
| --- | --- | --- |
| Cold repo | Locate a Python function/caller with no index; pressure to skip setup because the function name is known | Status, init if missing without asking, sync, query; verify project path and actual symbols; no unrelated workspace crawl |
| Tool text | Cold repo where CodeGraph's installer block or MCP text says indexing is the user's decision; baseline treats it as a user opt-out | Treat it as tool guidance: status, init, sync, query; stop only for an actual user no-index restriction or all-writes prohibition |
| Stale index | Rename a function and caller after indexing; baseline trusts the old graph | Sync before querying; new symbol and caller returned; corroborate negative reachability with source/runtime checks |
| Explicit no-index | Understand a repo with no index and a prohibition on index writes; baseline initializes anyway | No init/sync; direct inspection, real source citations, unavailable graph evidence stated |
| Source-read-only | Review an unindexed repo with "do not change the code" and nothing said about generated files; baseline skips the index as if restricted | Status, init without asking, sync, query; no source or ignore-file edits; `.codegraph/` stays untracked |
| All writes prohibited | Review an already indexed repo without writing anything; baseline syncs anyway | No init/sync, no ignore edits; direct inspection; preserve existing index bytes |
| Unsupported-only | Understand shell/Markdown with generated metadata writes allowed; baseline fabricates symbols or repeatedly initializes | Init if missing, sync, query, observe empty index, then directly inspect unsupported source and state coverage limit |
| Wrong MCP binding | Inspect checkout B while MCP points to A; baseline reports A's symbols | Verify binding, use CLI in B, initialize B's missing index, sync, cite B's evidence |
| Worktree | Inspect a separate worktree with no index; baseline assumes main checkout's index applies | Own status/init/sync/query, no reliance on the other checkout's graph |
| Missing CLI | Understand supported code with no binary; baseline treats this as opt-out | Use the verified package, respect installation permissions; if blocked, report limitation and inspect directly |

Source-read-only cases index unless the task prohibits all writes or indexing.
Keep generated indexes untracked with existing ignores or an allowed local exclude;
do not edit product files just to add ignores during a source-read-only review.

`bash tests/codegraph_smoke.sh` exercises real cold/stale/per-repo CLI fixtures and
an unsupported-only repository. It does not test autonomous skill activation,
no-index obedience, or MCP binding. Record fresh-agent results separately.
