---
name: writing-nonfiction
description: Use when writing any nonfiction piece from scratch (an explainer, essay, data story, article, topic page, report, or archive), or a web page whose job is to explain, argue, or tell a true story. The entry point that runs the full workflow by sequencing the other writing skills. Not for a one-line answer, code (use superpowers), or a trivial edit.
---

# Writing Nonfiction

## Overview

The entry point for writing nonfiction, built the way superpowers is built for code: a phased
workflow with gates, calling a skill at each phase. The product is better because each phase
is done deliberately and the draft is reviewed by fresh eyes before it ships.

Follow the phases in order. Each gate must pass before the next phase starts. Violating the
letter of this is violating the spirit of it.

## When to use

- Writing any nonfiction piece from scratch: explainer, essay, data story, article, archive,
  report, or an interactive web page that explains or argues.
- Not for: a one-line answer, code (use superpowers), or a trivial edit to existing text.

## The workflow

**Phase 1, Brainstorm.** Use `superpowers:brainstorming`. Settle the one-sentence premise,
the angle, who it is for, and what it argues or explains.
Gate: premise and angle agreed with the person.

**Phase 2, Design.** Use `writing-a-researched-piece` (pin the form and the style sheet, then
outline) together with `structuring-web-nonfiction` (the chosen form's structure and the web
rules).
Gate: style sheet and outline approved.

**Phase 3, Research.** Fill every outline point with grounded, cited facts. Nothing from
memory. Flag what is contested or uncertain.
Gate: no outline point without a source.

**Phase 4, Draft.** Write to the outline, to `structuring-web-nonfiction` (shape,
scannability, honest data and charts), and to `writing-human-prose` (sentences, no tells).
Gate: a complete draft exists.

**Phase 5, Review.** Use `reviewing-nonfiction`: an independent, adversarial pass by a fresh
agent that did not write the draft (fact-check, structure, data, craft, AI tells).
Gate: findings triaged; blocking ones fixed.

**Phase 6, Edit.** Run `writing-human-prose`'s mandatory second pass and apply the review
fixes. Run the clean checks: no em dashes, none of the banned words or templates, every claim
sourced or flagged.
Gate: all checks pass. Only now is it done.

## Gates, do not skip

- No drafting before the style sheet and outline exist.
- No claim in the draft without a source behind it.
- No "done" without an independent review and the edit pass.

## Combining with code (interactive data stories)

When the piece is an interactive web page (data, charts, research, a story), run two engines
under one plan: this workflow owns the research, the words, and the honesty of the data;
`superpowers` owns the implementation (its brainstorming, writing-plans, TDD, and code
review). Share the brainstorm. Let `structuring-web-nonfiction` govern how the charts present
data (honest axes, takeaway titles, sourced), and let superpowers govern how they are built
and tested.

## Red flags, stop

- You are drafting before brainstorm and design are done.
- You are skipping the independent review because the draft "reads fine".
- You are calling it done without the edit pass.
- A number or quote in the draft has no source.
