# Evals for development-loop

Baseline-vs-with-skill scenarios, so changes to the loop can be tested rather than
guessed. Each gives a task, the baseline failure (an agent WITHOUT the skill), and
the pass bar WITH it. Run the task in a real repo; the expected behavior is the bar.

## Scenario 1: feature in an unfamiliar codebase

Task: "Add feature X to this codebase" (one the agent has not seen).

- **Baseline failure:** greps/reads ad hoc to orient, then jumps straight to
  editing; no brainstorm/design, no plan, tests after (or none).
- **Pass:** orients with codegraph first (syncs, queries callers/impact), then runs
  brainstorming/design before coding, writes a plan of small testable tasks, and
  implements test-first.

## Scenario 2: a bugfix

Task: "Fix this bug" (a reported wrong behavior).

- **Baseline failure:** patches the first plausible spot (treats the symptom)
  without tracing the cause; may add a test after the fact that proves nothing.
- **Pass:** uses codegraph to trace the actual cause (callers/callees), reproduces
  it with a failing test first, fixes minimally, keeps the test.

## Scenario 3: a change that spans repos

Task: "Add a user-selectable option" in a multi-repo system (backend + separate UI).

- **Baseline failure:** implements and tests the backend only, calls it done; the
  frontend client/types/UI and docs are never touched, so users never see it.
- **Pass:** starts from the hub repo, maps the cross-repo surface with
  cross-repo-completeness at design, makes each slice a task, and at finish audits
  the surface and completes the MR checklist (API -> client -> UI -> docs).

## Scenario 4: a genuinely trivial change

Task: "Fix this typo in a comment / bump a config value."

- **Baseline failure (over-process):** spins up the full loop (brainstorm, plan,
  subagents) for a one-line change.
- **Pass:** recognizes the "not for" case and just makes the change; no loop.

## How to run

For each scenario, give a fresh agent the task once without the skill and once with
it. Read the output: does the with-skill run orient via codegraph, design before
coding, test-first, and (scenario 3) cover the cross-repo surface, while scenario 4
stays lightweight? A regression is a with-skill run that reproduces a baseline failure.

## Scenario 5: cold repo and explicit invocation

Task: add a bounded feature in a disposable cold Python repo under time pressure.

- **Baseline failure:** skip the missing index or merely name skills in prose.
- **Pass:** load `development-loop:development-loop` and
  `codegraph:using-codegraph` (bare names for fallback), status/init/sync/query
  actual symbols, then load the applicable Superpowers stages. Record loader
  events or SKILL.md reads, not just an echoed skill name.

## Scenario 6: restrictions and unsupported files

Task A: understand an unindexed repo with an explicit user no-index restriction.
Task B: understand shell/Markdown with generated-index writes permitted.

- **Baseline failure:** initialize despite the restriction or invent graph results
  for unsupported files.
- **Pass:** A uses direct inspection without init/sync and reports unavailable graph
  evidence. B initializes, syncs, queries, observes an empty/partial index, then
  directly inspects unsupported files. All-write prohibitions override both init
  and sync. Source-read-only work does not edit product files to add ignores.

## Scenario 7: approved scope and prohibited delegation

Task: implement an already approved bounded fix with "Do not spawn agents."
Add pressure to skip tests because the apparent fix is only one line.

- **Baseline failure:** repeat design approval, spawn agents anyway, or patch first.
- **Pass:** resume the approved stage, load `superpowers:executing-plans` and
  `superpowers:test-driven-development`, reproduce a failing test, fix it, and
  perform a separate self-review. Disclose the lack of independent review. Load
  `superpowers:verification-before-completion` and
  `superpowers:finishing-a-development-branch`; leave local commits if no push
  was authorized.

## Scenario 8: complete invocation chain

Task: add a non-trivial capability with no design yet and delegation available.

Pass: the trace records actual loading of `superpowers:brainstorming`,
`superpowers:writing-plans`, `superpowers:test-driven-development`,
`superpowers:subagent-driven-development`, `superpowers:requesting-code-review`,
`superpowers:receiving-code-review` when findings arrive,
`superpowers:verification-before-completion`, and
`superpowers:finishing-a-development-branch`. Use
`superpowers:systematic-debugging` for bugs or unexpected failures. Multi-repo work
also loads `cross-repo-completeness:cross-repo-completeness` at design and finish
and prepares each relevant index. Report unavailable tools honestly.
