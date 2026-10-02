# doyled-it skills

A small Claude Code marketplace of personal skills.

## Skills

- **writing-human-prose** — narrative-nonfiction craft plus an AI-tells blacklist
  (no em dashes, no "not just X but Y", banned words, summary kickers), for writing
  prose that reads human and stays sourced. Triggers on essays, history, articles,
  posts, READMEs, reports, or editing text so it does not read as AI-generated.

## Install

```
/plugin marketplace add doyled-it/claude-skills
/plugin install writing-human-prose@doyled-it-skills
```

Once installed, the skill loads automatically when a task matches its description.

## Layout

```
.claude-plugin/marketplace.json          marketplace manifest
plugins/<plugin>/.claude-plugin/plugin.json
plugins/<plugin>/skills/<skill>/SKILL.md
```
