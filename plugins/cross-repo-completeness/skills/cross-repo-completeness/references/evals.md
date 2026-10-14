# Evals for cross-repo-completeness

Baseline-vs-with-skill scenarios, so changes to the skill can be tested rather
than guessed. Each gives a task, the baseline failure (an agent WITHOUT the skill),
and the expected behavior WITH the skill. Run the task in a real multi-repo
project; the expected behavior is the pass bar. These are drawn from real misses
observed while building the skill.

## Scenario 1: user-facing backend feature must reach the UI

Task: "Add a new generation option (for example a method/model choice) that users
can pick in the web UI."

- **Baseline failure:** audits only the backend repo, confirms the API accepts the
  option, calls it done; the frontend client, types, UI control, and user docs are
  never checked, so the option never reaches users. Or puts the field on a
  synchronous endpoint the UI does not call, instead of the job-create route it does.
- **Pass (with skill):** reports the full chain, backend logic and its
  selector/dispatch -> the field on EVERY entrypoint that triggers it (the route the
  UI submits through, any sync endpoint, the CLI) -> a discovery endpoint if the UI
  lists options -> frontend client fn + types -> UI control -> UI user docs -> docs
  in each repo. Verifies which endpoint the client actually calls rather than
  assuming.

## Scenario 2: an "implemented" core that is actually orphaned

Task: "Expose capability X (whose core module already exists) to users."

- **Baseline failure:** sees the core module exists, marks the backend slice
  present, and audits outward from the API; misses that the core has no non-test
  caller and no path to real output, so nothing can ship.
- **Pass (with skill):** runs `codegraph callers` on the core entrypoint first,
  finds only test callers / no output path, and reports the capability itself as the
  first gap (not functional yet), before auditing outward seams.

## Scenario 3: a change that genuinely does not span the UI

Task: "Add a service config value / deploy env var."

- **Baseline failure:** either invents frontend/API slices that do not apply, or
  misses the deploy repo (compose/.env/manifests) entirely.
- **Pass (with skill):** marks the UI/client slices N/A (a valid outcome for a
  per-request or infra-only change), and reports the real surface: the consuming
  repo's config plus the hub repo's compose/.env/manifest.

## How to run

For each scenario, give a fresh agent the task in a real multi-repo checkout, once
without the skill and once with it. Read the output: does the with-skill run name
the correct per-repo slices and avoid the baseline failure? A regression is a
with-skill run that reproduces a baseline failure.
