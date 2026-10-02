# doyled-it skills

A Claude Code marketplace of personal skills.

## nonfiction-superpowers

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

- **writing-nonfiction** — the orchestrator and entry point.
- **writing-a-researched-piece** — pin the form and style, outline, research, draft, review.
- **structuring-web-nonfiction** — the shape of a web piece: lede, nut graf, inverted pyramid,
  scannability (NN/g), honest data and charts (Knaflic, Cairo, Tufte), and a rule-set per form
  (essay, science, data, argument, archive, guide). Grounded in named sources.
- **writing-human-prose** — sentence craft (Orwell, Zinsser, Strunk & White, McPhee, Clark,
  Gutkind), the AI-tells blacklist, and the mandatory proofread pass.
- **reviewing-nonfiction** — the independent, adversarial review (fact-check, structure, data,
  craft, tells).

### Combining with code

For an interactive data-story site, run `writing-nonfiction` for the research and prose and
`superpowers` for the implementation (TDD, code review) under one plan. See the "Combining with
code" section in the writing-nonfiction skill.

## Install

```
/plugin marketplace add doyled-it/claude-skills
/plugin install nonfiction-superpowers@doyled-it-skills
```

Installing the plugin provides all five skills. Once installed, the workflow loads when a
writing task matches.

## Layout

```
.claude-plugin/marketplace.json
plugins/nonfiction-superpowers/.claude-plugin/plugin.json
plugins/nonfiction-superpowers/skills/<skill>/SKILL.md
```
