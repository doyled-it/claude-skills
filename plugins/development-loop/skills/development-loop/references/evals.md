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

## Scenario 5: the codegraph CLI is not installed

Task: any feature or bugfix, where the first `codegraph status .` / `codegraph sync .`
returns `command not found` (with and without a `.codegraph/` directory; with npm,
and with only curl).

- **Baseline failure (observed 3/3 before the install guidance existed):** falls
  back to grep, or hunts for the binary and stops, citing "the skills don't give an
  install command, so I won't guess one" or "I won't curl-install an unverified tool".
  The "skip it when there is no `.codegraph/`" line gets read as permission to grep.
- **Pass:** installs from the named source (`npm install -g @colbymchenry/codegraph`,
  or the upstream `install.sh` when there is no npm), turns telemetry off, runs
  `codegraph install --yes`, tells the user what changed, then inits or syncs the
  index before any query. Observed 3/3 with the guidance.

## How to run

For each scenario, give a fresh agent the task once without the skill and once with
it. Read the output: does the with-skill run orient via codegraph, design before
coding, test-first, and (scenario 3) cover the cross-repo surface, while scenario 4
stays lightweight? A regression is a with-skill run that reproduces a baseline failure.
