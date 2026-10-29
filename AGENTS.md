# Repository instructions

- This repo publishes composable skills. Route feature and bugfix work through
  `development-loop`, code understanding through `using-codegraph`, and multi-repo
  design/audits through `cross-repo-completeness`. Invoke the upstream Superpowers
  stages they name; do not modify or vendor upstream Superpowers.
- Creating and syncing the index is mandatory: `codegraph status .`,
  `codegraph init .` if missing, then `codegraph sync .` before querying and after
  edits. The only exception is an explicit user no-index restriction. After querying, directly inspect unsupported files when
  an index is empty or partial. Markdown and shell need direct reads here.
- Keep policy consistent across skills, README, evaluation scenarios, and the
  managed conventions block in the legacy development-loop installer. Native
  plugin installation belongs to agentic-dev-setup; shared links are a fallback
  and must not duplicate native skills.
- Keep AGENTS.md canonical; CLAUDE.md imports it. Bump a modified plugin's
  `.claude-plugin/plugin.json` version above published/cached versions, and keep
  its description consistent with `.claude-plugin/marketplace.json`.
- Write meaningful regression tests first for behavior changes. Run
  `bash scripts/check.sh`; run `bash tests/codegraph_smoke.sh` when CodeGraph
  behavior changes. These checks need Bash, Node.js 18+, and ShellCheck; the smoke
  check additionally needs the CodeGraph CLI and uv for scaffold validation.
- Follow the evaluation references for behavioral validation. Report which
  scenarios actually ran and distinguish deterministic checks, real CLI smoke
  checks, and fresh-agent behavior. Do not claim the last from the first two.
- Work on feature branches; use Conventional Commits and a public noreply identity.
  Do not add coauthors. Remote writes require explicit user authorization.
- Ignore `.codegraph/` and `.superpowers/`. Do not commit generated designs, plans,
  transcripts, private configuration, or internal source. Keep prose free of
  em dashes and emoji. Update these instructions with new repo conventions.
