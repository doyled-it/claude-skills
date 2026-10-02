# doyled-it skills

A small Claude Code marketplace of personal skills.

## Skills

- **writing-human-prose** — narrative-nonfiction craft plus an AI-tells blacklist
  (no em dashes, no "not just X but Y", banned words, summary kickers) and a mandatory
  post-draft proofread pass, for prose that reads human and stays sourced. Triggers on
  essays, history, articles, posts, READMEs, reports, or editing text so it does not read
  as AI-generated.
- **writing-a-researched-piece** — the workflow around it: pin the style by interview,
  outline, research, draft, then review for craft and slop. For explainers, deep dives,
  topic pages, and reports that reach a conclusion. Pairs with writing-human-prose.

## Install

```
/plugin marketplace add doyled-it/claude-skills
/plugin install writing-human-prose@doyled-it-skills
/plugin install writing-a-researched-piece@doyled-it-skills
```

Once installed, the skill loads automatically when a task matches its description.

## Layout

```
.claude-plugin/marketplace.json          marketplace manifest
plugins/<plugin>/.claude-plugin/plugin.json
plugins/<plugin>/skills/<skill>/SKILL.md
```
