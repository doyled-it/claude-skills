---
name: reviewing-nonfiction
description: Use to review a finished nonfiction draft before it ships, or to review someone else's draft; the review phase of writing-nonfiction. Not for drafting or for sentence-level cleanup alone.
---

# Reviewing Nonfiction

## Overview

An independent, adversarial review of a nonfiction draft, run by fresh eyes. This mirrors code
review: the reviewer hunts for problems, and the writer does not grade their own work. A fresh
agent with no sunk cost catches the antithesis the writer wrote without noticing and the claim
the writer "knows" is true. Self-review misses these every time.

## When to use

- After a complete draft, before calling it done (phase 5 of `writing-nonfiction`).
- Reviewing a draft someone else wrote.
- Not for: drafting, or sentence cleanup on its own (that is `writing-human-prose`).

## How to run it

Dispatch a subagent that did not write the draft. Give it the draft and the list of sources.
Tell it to review and report, not to rewrite. It checks, in order:

1. **Accuracy and fact-check.** Every claim must trace to a cited source. Flag anything
   unsupported, overstated beyond what the source says, or contradicted by its own source.
   Check numbers and quotations against the sources, not just that a link exists.
2. **Structure.** Is the main point in the lede? Is there a nut graf near the top? Does each
   section hold one thread? Does the ending answer the question the lead raised? (Check against
   `structuring-web-nonfiction`.)
3. **Data and charts.** Honest axes, takeaway titles, a source on every chart, uncertainty
   shown where the data is estimated. (Check against `structuring-web-nonfiction`.)
4. **Craft and AI tells.** Run the `writing-human-prose` blacklist: em dashes, "not just X but
   Y", antithesis reversals, banned words, summary kickers, rule-of-three padding. Then the
   craft bar: concrete openings, varied sentences, a real ending.
5. **Form fit.** Does it follow the chosen form's rule-set (essay, science, data, argument,
   archive, guide)?

The reviewer returns a prioritized list: blocking problems first, then minor ones. Each finding
names a specific location and a suggested fix. The reviewer does not edit the draft.

## The writer's job after review

Triage the findings. Fix every blocking one. For any finding you reject, write one line saying
why. Then run the edit pass (`writing-human-prose`'s mandatory second pass). Do not ship with
blocking findings open.

## Why independent eyes

The same reason code review works: the person who wrote it is the worst person to catch its
blind spots. Use a subagent, not your own reread, for this pass.
