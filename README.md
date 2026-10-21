# doyled-it skills

A Claude Code marketplace of personal skills. The skills follow the Agent Skills open standard
(agentskills.io), so the same `SKILL.md` runs in Claude Code, Codex, and opencode.

## Writing

### nonfiction-superpowers

A superpowers-style system for writing nonfiction: a phased workflow with gates, built as a
sequence of composable skills. It is to prose what superpowers is to code.

Start with **writing-nonfiction** (the orchestrator). It runs the phases:

1. **Brainstorm** the premise, angle, and audience (uses `superpowers:brainstorming`).
2. **Design**: pin the form and a style sheet, then outline (`writing-a-researched-piece`,
   `structuring-web-nonfiction`).
3. **Research**: grounded and cited, nothing from memory.
4. **Draft** to the structure and the prose rules (`structuring-web-nonfiction`,
   `writing-human-prose`).
5. **Review**: an independent adversarial pass by fresh eyes (`reviewing-nonfiction`).
6. **Edit**: the mandatory proofread pass and the clean checks (`writing-human-prose`).

The skills in the plugin:

- **writing-nonfiction**: the orchestrator and entry point.
- **writing-a-researched-piece**: pin the form and style, outline, research, draft, review.
- **structuring-web-nonfiction**: the shape of a web piece: lede, nut graf, inverted pyramid,
  scannability (NN/g), honest data and charts (Knaflic, Cairo, Tufte), and a rule-set per form
  (essay, science, data, argument, archive, guide). Grounded in named sources.
- **writing-human-prose**: sentence craft (Orwell, Zinsser, Strunk & White, McPhee, Clark,
  Gutkind), the AI-tells blacklist, and the mandatory proofread pass.
- **reviewing-nonfiction**: the independent, adversarial review (fact-check, structure, data,
  craft, tells).

For an interactive data-story site, run `writing-nonfiction` for the research and prose and
`superpowers` for the implementation under one plan (see the "Combining with code" section in the
writing-nonfiction skill).

## Development

Three composable skills for writing code. **development-loop** is the orchestrator; it uses the
other two and the upstream superpowers skills.

### development-loop

A disciplined loop for any feature or bugfix, single-repo or multi-repo: understand (codegraph) ->
brainstorm and design -> plan -> implement with TDD -> finish and verify the whole surface. It
does not fork the superpowers skills, it sequences them (so their updates flow through) and adds
two always-on habits plain prompting drops: ground understanding in codegraph, and verify a
change's full cross-repo surface. Invoke **development-loop** explicitly; it routes code
understanding to **using-codegraph**, multi-repo design and finish to
**cross-repo-completeness**, and the implementation stages to upstream Superpowers.
It includes inline execution when delegation is unavailable or prohibited.

### codegraph

Close CodeGraph index gaps during code understanding: run `codegraph status .`,
`codegraph init .` if missing, then `codegraph sync .` before querying. An explicit user
no-index restriction overrides this default. Prepare each relevant sibling repo and
worktree separately, verify the project binding, and re-sync after edits. An index can
be empty or partial for unsupported file types; after querying, use direct inspection
of unsupported source and report the coverage limit. Never invent graph results.
Invoke **using-codegraph** for this sequence, including code-understanding questions.

### cross-repo-completeness

Map and verify a change's full surface across a multi-repo system, so it does not ship wired in
one repo and missing in the others (the API contract, client + types, UI, config, deploy, and
docs per repo). Two modes: **setup** (scaffold a project's seam map + per-repo pointers + MR
checklist, partly scripted) and **audit** (read each repo for a named change, walk the
end-to-end seam, report present/missing/undocumented slices). Pairs with the **codegraph** skill
as its per-repo engine.

## Install with native plugins

For modern Claude Code and Codex, prefer
[agentic-dev-setup](https://github.com/doyled-it/agentic-dev-setup). It installs this
marketplace, upstream Superpowers, CodeGraph, and canonical global instructions. Use
its core install by default; its extended plugin set is optional. It does not crawl
unrelated workspaces. The agent closes index gaps in relevant repos during actual work.

For manual Claude Code installation, add both marketplaces and install the plugins:

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
/plugin marketplace add doyled-it/claude-skills
/plugin install development-loop@doyled-it-skills
/plugin install codegraph@doyled-it-skills
/plugin install cross-repo-completeness@doyled-it-skills
/plugin install nonfiction-superpowers@doyled-it-skills
```

Installing plugins exposes skills. Explicitly load the matching skill; mentioning a
name in a plan is not an invocation. Native names are
`development-loop:development-loop`, `codegraph:using-codegraph`, and
`cross-repo-completeness:cross-repo-completeness`. Shared fallback installs expose
the bare skill names. Use the runtime's skill loader, or read the SKILL.md when no
loader exists. Report unavailable skills and carry out the phase directly.

The development loop names each Superpowers stage: `superpowers:brainstorming`,
`superpowers:writing-plans`, `superpowers:test-driven-development`, and
`superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline).
It also routes diagnosis, requesting/receiving review, verification before completion,
and branch finishing. Remote writes still require user authorization.

### Legacy shared-skills fallback

For a runtime without native plugin support that discovers `~/.agents/skills`, the
legacy fallback creates shared links. It refuses installation when `claude` or
`codex` on PATH supports native plugins because shared skills could appear beside
native copies. Use one installation method for each skill across runtimes that
share discovery paths. Do not hide a runtime from detection to bypass this guard.

```bash
bash scripts/install-skills.sh             # fallback links into ~/.agents/skills
bash scripts/install-skills.sh --copy      # fallback for filesystems without links
```

This does not install upstream Superpowers; install it using the fallback runtime's
supported method. Existing manual directories and foreign symlinks are preserved.
Copies are not refreshed on re-run. Links point to this checkout and require it to
stay in place. Old absolute `~/.claude/skills` links owned by this checkout are
removed when fallback installation runs; directories and foreign links are kept.

The development-loop legacy entry point updates only its managed conventions block
by default. It no longer installs native plugins or shared links automatically:

```bash
bash plugins/development-loop/skills/development-loop/scripts/install.sh
bash plugins/development-loop/skills/development-loop/scripts/install.sh --print-only
bash plugins/development-loop/skills/development-loop/scripts/install.sh --global-file "$HOME/.codex/AGENTS.md"
bash plugins/development-loop/skills/development-loop/scripts/install.sh --shared-skills
```

`--shared-skills` explicitly opts into the guarded fallback. Updates preserve text
outside the managed block and replace both historical manager labels. Malformed
markers fail without changing the file. `--print-only` has no installation side
effects. The legacy block is distinct from the setup repo's canonical instruction
block: review and remove the old managed block when migrating to that setup.

Before switching to native plugins, inspect `~/.agents/skills` and
`~/.claude/skills`. Remove only links/copies you recognize as these skills after
checking their targets or contents. Never delete manual skills or foreign links.
The native setup does not automatically clean historical fallback installations.
Refresh marketplaces and the three changed plugins after publication, then restart
the runtime to load their new versions. This branch is not installed by a remote
marketplace command until it is published; test a local plugin path for local edits.

## Validation

Run `bash scripts/check.sh` with Bash, Node.js 18+, and ShellCheck installed. It
checks policy conflicts, plugin metadata, installer behavior in disposable homes,
syntax, and shell lint. No actual plugin installation or account configuration
is performed by those tests.

Run `bash tests/codegraph_smoke.sh` with CodeGraph and uv installed for real CLI
fixtures: cold and stale indexes, a hub with sibling indexes, an unsupported-only
repo, and scaffold idempotence. All generated files stay in an ignored temporary
directory in this repo. The fixture checks verify commands and artifacts; they do
not prove that a fresh agent selects or invokes a skill correctly.

Behavioral evaluation instructions are in each development skill's
`references/evals.md`. Record loader events or SKILL.md reads, commands, exit
status, actual symbol evidence, and user restrictions. Do not count a skill name
echoed in prose as a successful invocation or fabricate a fresh-agent run.

## Layout

```
.claude-plugin/marketplace.json
plugins/<plugin>/.claude-plugin/plugin.json
plugins/<plugin>/skills/<skill>/SKILL.md
scripts/install-skills.sh
```
