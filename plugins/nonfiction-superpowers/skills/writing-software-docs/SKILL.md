---
name: writing-software-docs
description: Use when writing, restructuring, or reviewing technical documentation for software, such as a docs site page, README section, user or admin guide, tutorial, how-to, reference, troubleshooting page, or feature explanation, from code, a spec, or a fact sheet.
---

# Writing Software Docs

## Overview

Software docs answer four different reader needs, and each need gets its own kind of
page (the Diataxis framework, https://diataxis.fr): a tutorial for learning, a how-to
guide for a task, reference for looking something up, and explanation for
understanding. The page a reader needs depends on what they are doing at that moment,
so a page that serves all four serves none of them well.

Plan the pages by reader need first. Then write each page to its type's recipe.

## When to use

- Documenting a feature, setting, command, API, workflow, or product area.
- Adding to or reorganizing a docs site, README, or guide.
- Asked for "a page about X": X usually spans more than one reader need.

Not for: code comments, commit messages, changelogs, or essays (use writing-nonfiction).

## What you deliver

1. **A placement plan, before any prose.** List the reader needs the request covers.
   For each need, give its type and where it lands: a section added to an existing
   page, or a new page. If the site already has a nav or docs tree, read it first and
   prefer existing pages (a new setting is usually a row in an existing reference
   table plus a how-to, not a new page).
2. **The pages, one type each,** following the recipes below, each starting with a
   comment naming its type: `<!-- diataxis: how-to -->`.
3. **Cross-links instead of repetition.** Each page links to the other types for the
   same subject ("To set it, see How to limit tool call time"; "All values: Workflow
   step reference").
4. **An Unconfirmed list.** A statement goes on a page only when a source states it.
   Arithmetic on stated values counts as stated. Anything you inferred (a consequence,
   a converse, what a control probably does, what happens next) goes in this list for
   the requester to confirm.
5. **Visible markers for gaps a page cannot work without.** When a how-to step or a
   table cell needs an unconfirmed fact, write that step or cell with a visible inline
   marker, `**TODO(confirm):** <the open question>`, and add it to the Unconfirmed list.
   The marker renders on the page so nobody publishes it by accident, and `grep
   TODO(confirm)` finds every one. A hidden HTML comment does not count.

## Recipes

| Type | Reader is | Page is | Page leaves out |
| --- | --- | --- | --- |
| Tutorial | learning, new to it | one guided path to a first success; numbered steps, each with the result the reader should see; ends with what they can now do | options, alternatives, background beyond a sentence |
| How-to | doing a task they already understand | title names the goal; prerequisites; numbered steps; how to check it worked | teaching, the full list of options (link reference) |
| Reference | looking something up | mirrors the product's structure (fields, settings, events, errors, menus); tables with name, type or range, default, effect | steps, advice, opinions |
| Explanation | trying to understand | prose on why it works this way, how the parts connect, and the tradeoffs | steps, exhaustive value lists |

Troubleshooting is a how-to keyed by symptom: the symptom as the heading, then the
cause, then the fix.

A short page is fine. A how-to with three steps that links to a reference table is
better than one long page that mixes both.

## Writing the sentences

**REQUIRED SUB-SKILL:** use writing-human-prose for every sentence. Before a docs set
ships to users, run reviewing-nonfiction on it.

`references/evals.md` holds the baseline and with-skill scenarios for changes to this
skill.

## Common mistakes

| Mistake | Fix |
| --- | --- |
| One "everything page" with Quick answer, How it works, Steps, Reference, Troubleshooting | Split by reader need; link the parts |
| Steps inside a reference page | Move them to a how-to and link to it |
| Explaining "why" in the middle of a procedure | Put it on the explanation page; leave one link |
| Writing the converse of a stated fact ("v1 imports on old servers" so "v2 fails on old servers") | Put it in the Unconfirmed list |
| Describing UI behavior the sources do not state | Unconfirmed list, or read the code |
| Writing an assumed step as fact and only flagging it in the list | `**TODO(confirm):**` marker on the step itself |
| Dropping the main path (for example the UI) because one detail is unconfirmed | Write the path; mark the one unconfirmed step |
| Flagging an unconfirmed fact in an HTML comment | Readers never see it; use the visible marker |
| Creating a new page when the site already has the right one | Add a section or a table row there |
