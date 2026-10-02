---
name: writing-a-researched-piece
description: Use during the design and drafting of a nonfiction piece, normally invoked by writing-nonfiction at its design phase, to pin the form and style, outline, research, and draft. Not the entry point (use writing-nonfiction to start a piece), not for quick factual answers or code.
---

# Writing a Researched Piece

## Overview

The design-through-draft engine that `writing-nonfiction` calls at its design phase. It
assumes the brainstorm is done, and it hands the finished draft to `reviewing-nonfiction` and
the edit pass. The order is the point: pin the style first, outline, research, draft. Jumping
straight to prose produces generic, unsourced, AI-sounding writing that then needs rebuilding.

**REQUIRED SUB-SKILLS:**
- `structuring-web-nonfiction` for the shape: lede, nut graf, section order, scannability,
  how to present data and charts, and the moves for each form.
- `writing-human-prose` for the sentences: craft rules, the AI-tells blacklist, and the
  mandatory review pass.

This skill is the process around those two.

## When to use

- Longform explainers, deep dives, essays, topic pages or sites, reports that argue a
  thesis or explain context.
- Any piece where the voice matters and every claim has to be grounded.
- Not for: quick factual answers, code, terse notes, structured reference tables.

## The workflow (in order, do not skip steps)

### 1. Pin the style (interview first)

Before outlining or writing, ask the person a few questions to fix the target. Use the
question tool, do not guess the style. Settle:

- **Form**: which kind of piece (see the list below). The form sets the default moves.
- **Mode**: scene-rich and personal, or concise and data-grounded, or somewhere between.
- **Voice**: who is speaking, how much personality, how much restraint.
- **Audience**: who reads it, what they already know.
- **Length and depth**.
- **Structure**: narrative, thematic, or chronological; does it reach a conclusion or argue
  a thesis, or just explain?
- **Extras**: data, charts, or visuals? Inline citations visible to the reader?

Pick from the forms that `structuring-web-nonfiction` has a rule-set for, and load that
rule-set:

- **Essay or narrative explainer**
- **Science or research explainer**
- **Data explainer**
- **Argument, analysis, or political**
- **Cultural or exploratory archive**
- **Practical or reference guide**

Each form's specific structure and moves live in `structuring-web-nonfiction`; load it and
follow the matching rule-set.

Write the answers into a short **style sheet** (below) and keep it in front of you while
drafting. "I'll infer the style" is the failure this step exists to prevent.

### 2. Outline

Turn the topic into an ordered outline, one thread per section. If the person is around,
get sign-off before researching.

### 3. Research

Fill the outline with grounded, cited facts. Nothing from memory. Prefer primary and
authoritative sources. Flag anything contested or thin instead of smoothing it.

### 4. Draft

Write to the style sheet, to `structuring-web-nonfiction` (shape, scannability, data), and to
`writing-human-prose` (sentences, no tells). Hit the mode you agreed: a data-grounded piece
should not sprout invented scenes, and a personal piece should not read like a briefing.

### 5. Review twice

Run both passes, not one:
- **AI-tells pass**: the mandatory second pass from `writing-human-prose`.
- **Structure and craft pass**: check against `structuring-web-nonfiction` (is the point in
  the lede, is there a nut graf, does it scan, are charts honest and sourced), that each
  section's first sentence is concrete and its last lands a point (see `writing-human-prose`),
  and that every claim is sourced or flagged.

For anything that matters, get an independent pass too: `reviewing-nonfiction` dispatches a
fresh agent to adversarially check the draft, which catches what your own reread slides over.

Tell-free is not the same as good. Do both or the piece ships dull or sloppy.

## Style sheet template

Fill this in step 1 and obey it:

```
Mode:        (scene-rich / balanced / concise data-grounded)
Voice:       (who speaks, how much personality)
Audience:    (who, what they know)
Length:      (rough target)
Structure:   (narrative / thematic / chronological; thesis or explain-only)
Data/visuals:(charts, tables, images? inline citations?)
Non-negotiables: no em dashes; no AI tells (writing-human-prose); every claim sourced.
```

## Common mistakes

- Drafting before the style is pinned, so the voice is generic and needs a rewrite.
- Researching after writing, which bakes in unsourced claims.
- One review pass, so either slop or dullness survives.
- Treating "clean" as "good". Removing tells is not the same as being worth reading.

## Red flags, stop

- You started drafting with no style sheet.
- You wrote first and went looking for sources after.
- You shipped after a single pass.
