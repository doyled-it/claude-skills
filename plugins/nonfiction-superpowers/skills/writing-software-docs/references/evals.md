# writing-software-docs evaluation scenarios

Fresh-agent behavior tests. Run each scenario in a fresh, single-shot context
with no other skills, both without and with this skill. Read every output; do
not score by keyword counts alone. Scenarios marked "not yet run" are planned.

## Scenario 1: "a page about X" from a fact sheet

Prompt: the team lead asks for one docs page about a feature ("Make it good") and
supplies a fact sheet (a per-step tool timeout: field name, range, default, a limit
tied to another setting, an error name, UI control names and defaults, a package
version consequence, failure behavior). The agent may not add facts.

Pass criteria (with skill):

- A placement plan comes before any prose, mapping each reader need to a Diataxis
  type and a destination (existing page section or new page).
- Each page has one type, marked `<!-- diataxis: <type> -->`, and links to the
  other types instead of repeating them. Existing pages gain same-type sections.
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
- Authoring-guidance revision: 3 fresh single-shot `codex exec` runs (only this
  skill and the same fact sheet) each produced a visible placement plan, four
  separate single-type pages, cross-links, the plugin UI path, an Unconfirmed
  list, and visible markers for missing actions. Marker counts were 10, 10,
  and 8; none hid a gap in an HTML comment. These were Codex runs on one model.
- Additional one-shot Claude Haiku, Sonnet, and Opus probes each produced four
  single-type pages, but used a troubleshooting how-to instead of a tutorial.
  They confirm model coverage, not identical page selection across models.

## Scenario 2: routing (not yet run as a fresh-agent test)

Prompts: "Write a README section for the workflow timeout setting" and
"Write an essay explaining why per-call timeouts matter to developers."

Pass criteria: the README request loads writing-software-docs, not the full
writing-nonfiction workflow. The essay starts at writing-nonfiction. Record a
loader event or SKILL.md read, not just a name mentioned in prose.

## Scenario 3: placement in an existing docs tree (not yet run)

Prompt: "Add documentation for a new `batch_limit` setting. Our docs already
have `reference/workflow-settings.md` for setting fields and
`how-to/configure-workflows.md` for configuration tasks. The code says the
field is an optional integer from 1 to 100, defaults to 20, and is set in
the workflow editor. The code does not say which control edits it or whether
changing it affects running workflows. Do not add facts."

Pass criteria: the placement plan adds a row or section to each compatible
existing page instead of creating duplicate pages. The reference stays a
reference, the how-to stays a how-to, and they link to each other. The editor
action has a visible `**TODO(confirm):**` marker in the how-to and appears in
Unconfirmed; behavior for running workflows is not asserted as fact.
