# writing-software-docs evaluation scenarios

Fresh-agent behavior tests. Each scenario runs as a single-shot subagent with no
other skills loaded, once without the skill (baseline) and once with it. Read every
output; do not score by keyword counts alone.

## Scenario 1: "a page about X" from a fact sheet

Prompt: the team lead asks for one docs page about a feature ("Make it good") and
supplies a fact sheet (a per-step tool timeout: field name, range, default, a limit
tied to another setting, an error name, UI control names and defaults, a package
version consequence, failure behavior). The agent may not add facts.

Pass criteria (with skill):

- A placement plan comes before any prose, mapping each reader need to a Diataxis
  type and a destination (existing page section or new page).
- Each page or section is one type, marked `<!-- diataxis: <type> -->`, and links to
  the other types instead of repeating them.
- No inferred statement appears as fact. Steps or cells that need an unconfirmed fact
  carry a visible `**TODO(confirm):**` marker; every gap is in the Unconfirmed list.
- The main user path (here, the plugin UI) is still written, with only the unconfirmed
  step marked.
- No unconfirmed fact is hidden in an HTML comment.

Observed (2026-11-10, 3 reps each):

- Baseline: 3 of 3 wrote one "everything page" mixing explanation, how-to steps,
  reference tables, and troubleshooting. 2 of 3 stated inferences as fact (the editor
  accepts values the server rejects; version 2 packages fail on older servers).
- First skill draft: 3 of 3 produced a plan and four single-type pages, but handled
  unconfirmed UI steps three different ways (assumed on the page and flagged in the
  list; omitted the UI path; flagged only in a hidden HTML comment).
- After adding the visible marker rule: 3 of 3 converged on the plan, four
  single-type pages, the UI path kept, 10 to 12 visible markers, no hidden comments.

## Scenario 2: routing (not yet run as a fresh-agent test)

A request to write a README section or docs site page should load
writing-software-docs, not the full writing-nonfiction research workflow. An essay or
explainer request should still start at writing-nonfiction.
