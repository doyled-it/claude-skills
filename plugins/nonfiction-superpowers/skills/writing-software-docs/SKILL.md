---
name: writing-software-docs
description: Writes and reviews software docs grounded in code, specs, or fact sheets. Use for docs pages, README sections, user guides, tutorials, how-to guides, reference, explanations, or troubleshooting. Excludes code comments, commit messages, changelogs, and essays.
---

# Writing Software Docs

## Principle

Organize docs by reader need ([Diataxis](https://diataxis.fr)): learning,
doing, looking up, or understanding. Give each page one type.

## Deliverables

1. **Visible placement plan before prose.** Map each reader need to a type and
   destination. A broad "page about X" usually spans all four needs: propose
   separate pages even if asked for one. Inspect the docs tree and prefer
   same-type existing pages; otherwise propose page paths. Do not hide the
   plan in an HTML comment.
2. **One type per page.** Draft every planned page, even when a step needs
   confirmation. Add a section only to a same-type existing page. Never
   combine types on a new page. Follow the recipes below and start each page
   with `<!-- diataxis: how-to -->` (substitute its type).
3. **Cross-links.** Link related types for the subject instead of repeating
   them. When drafting without a docs tree, use proposed relative links.
4. **Unconfirmed list.** Only source-stated claims go on pages; arithmetic on
   stated values counts. Prerequisites, expected results, and control actions
   are claims too. List inferences and gaps for confirmation.
5. **Visible gaps.** Replace a needed unconfirmed step or table cell with
   `**TODO(confirm):** <question>` in place and add it to Unconfirmed. Do not
   state a guessed action before its marker. Keep the source's main path
   (such as a plugin UI) rather than replacing it. Hidden comments do not count.

## Page recipes

| Type | Include | Leave out |
| --- | --- | --- |
| Tutorial: learning | One guided path to first success; numbered steps with expected results; what the reader can now do | Options, background |
| How-to: doing | Goal in title; prerequisites; numbered steps; success check | Teaching, exhaustive options |
| Reference: looking up | Product-shaped tables: names, types or ranges, defaults, effects | Steps, advice |
| Explanation: understanding | How parts connect and their tradeoffs | Steps, exhaustive values |

Troubleshooting is a how-to keyed by symptom: symptom, cause, then fix.

## Check before delivery

- Check claims against sources; list unsupported claims or mark necessary gaps.
- Check each page's type, marker, links, and `TODO(confirm)` entries against
  the placement plan and Unconfirmed list.

Use `writing-human-prose` for sentences and `reviewing-nonfiction` before
publication. For skill revisions, use [evaluations](references/evals.md).

## Common mistakes

| Mistake | Fix |
| --- | --- |
| One page mixes steps, tables, and background | Split and cross-link |
| Procedure steps enter reference | Move them to a how-to |
| An inferred converse or UI action appears as fact | List it; mark needed gaps visibly |
| A new page duplicates a same-type page | Add a section or row there |
