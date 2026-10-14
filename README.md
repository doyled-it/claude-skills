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
change's full cross-repo surface. Start with the **development-loop** skill. Its
`scripts/install.sh` installs the skills into every tool's path, ensures the superpowers skills
are installed and current, and writes a managed "development conventions" block into your global
agent instructions so the habits load every session.

### codegraph

Use CodeGraph effectively to orient in and navigate a codebase: sync the index first, query
symbols / callers / impact instead of grep, and handle the multi-repo and MCP-binding gotchas.
Start with the **using-codegraph** skill.

### cross-repo-completeness

Map and verify a change's full surface across a multi-repo system, so it does not ship wired in
one repo and missing in the others (the API contract, client + types, UI, config, deploy, and
docs per repo). Two modes: **setup** (scaffold a project's seam map + per-repo pointers + MR
checklist, partly scripted) and **audit** (fan one reader per repo for a named change, walk the
end-to-end seam, report present/missing/undocumented slices). Pairs with the **codegraph** skill
as its per-repo engine.

## Install

As a Claude Code plugin marketplace:

```
/plugin marketplace add doyled-it/claude-skills
/plugin install development-loop@doyled-it-skills
/plugin install codegraph@doyled-it-skills
/plugin install cross-repo-completeness@doyled-it-skills
/plugin install nonfiction-superpowers@doyled-it-skills
```

Installing a plugin provides its skills; each loads when a matching task appears.

### Using these skills in Codex or opencode

Only the install path differs per tool. To make every skill in this repo available to the other
tools, symlink them into each tool's discovery path:

```
bash scripts/install-skills.sh      # symlinks into ~/.agents/skills and ~/.claude/skills
```

To turn the development loop on everywhere (symlinks + superpowers + the global conventions block):

```
bash plugins/development-loop/skills/development-loop/scripts/install.sh
```

## Layout

```
.claude-plugin/marketplace.json
plugins/<plugin>/.claude-plugin/plugin.json
plugins/<plugin>/skills/<skill>/SKILL.md
scripts/install-skills.sh
```
