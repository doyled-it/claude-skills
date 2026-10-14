#!/usr/bin/env python3
"""Scaffold the cross-repo completeness artifacts for a multi-repo project.

This is the deterministic part of the skill's setup mode: it writes the same
boilerplate files into each repo every time, so the output does not depend on a
model improvising them. The JUDGMENT part (filling in the actual repo map and
seams in cross-repo-features.md) is left to the agent after this runs.

Run it once per project. It is idempotent: an existing file is left alone unless
--force is passed.

Usage:
  python scaffold.py --hub PATH --repo PATH [--repo PATH ...] \
      --forge {gitlab,github} [--remote-base URL] [--force]

  --hub         Path to the integration/deploy repo (the "home base"); gets the
                shared cross-repo-features.md guide.
  --repo        Path to each repo in the system (repeat; include the hub too).
  --forge       gitlab -> .gitlab/merge_request_templates/Default.md;
                github  -> .github/pull_request_template.md.
  --remote-base Clone base, e.g. git@gitlab.example.com:group or
                git@github.com:org (used in the "clone a sibling" snippet).
  --force       Overwrite existing scaffold files.

Example:
  python scaffold.py --hub ../deploy \
      --repo ../svc-a --repo ../web --repo ../deploy \
      --forge gitlab --remote-base git@gitlab.example.com:myteam
"""

import argparse
import os
import sys

MR_TEMPLATE = """## Summary

<!-- What does this change do, and why? -->

## Cross-repo completeness

This repo is part of a multi-repo system. A feature usually spans repos, so
confirm the full surface of this change, or mark a line N/A. See the hub repo's
`docs/cross-repo-features.md` for the map and the definition of done.

- [ ] Backend logic / the API endpoint or field (request + response models)
- [ ] The frontend API client fn and its types (both)
- [ ] The frontend UI control (route or component) + user docs
- [ ] Any other service's endpoint/index this touches
- [ ] Config / env / deploy (compose, .env, infra manifests) in the hub repo
- [ ] Docs updated in EACH affected repo (README / agent memory file / guide)
- [ ] Any deferred slice explicitly noted and tracked
"""


def contributing(repo_name, hub_name, repo_names, remote_base):
    others = ", ".join(f"`../{r}`" for r in repo_names if r != hub_name)
    clones = "\n".join(
        f"git clone {remote_base}/{r}.git" for r in repo_names
    ) if remote_base else "git clone <remote>/<repo>.git   # for each repo"
    return f"""# Contributing

`{repo_name}` is one of several repos in this system. A feature usually spans
several of them, and the seams between repos (the API contract, config/env,
deploy, and each repo's docs) are where a change ships half-wired. Read this
before adding a feature.

## Work from the hub repo for cross-repo features

Run your coding agent from the hub repo (`{hub_name}`), with the sibling repos
checked out alongside it ({others}). Working from the hub gives the agent the
whole-system view and the seams map. If a sibling is not present, clone it into
the parent directory:

```
{clones}
```

## Cover the full cross-repo surface (definition of done)

Map the change's cross-repo surface at design time, and verify every affected
slice (including docs) at finish time, before opening a merge/pull request. The
request template checklist captures this. The repo map, the seams, and the full
definition of done are in `{hub_name}/docs/cross-repo-features.md`.
"""


def guide_skeleton(hub_name, repo_names, remote_base):
    rows = "\n".join(f"- **{r}**: TODO responsibility, and its public seam (routes it exposes/consumes, client module + types on the consuming side, config/env it owns)." for r in repo_names)
    clones = "\n".join(f"git clone {remote_base}/{r}.git" for r in repo_names) if remote_base else "git clone <remote>/<repo>.git   # for each repo"
    return f"""# Cross-repo feature guide

A feature in this system usually spans more than one repo. The seam between repos
(the API contract, shared config, deploy wiring, and each repo's docs) is where a
change ships "done" in one repo and never reaches users. This guide is the
checklist to stop that.

## Start here: run your agent from the hub

For cross-repo work, run your coding agent from the hub repo (`{hub_name}`) with
the other repos checked out as siblings. If one is missing, clone it:

```
{clones}
```

## The repos and what they own

{rows}

## The seams (where features leak)

- TODO the primary API contract (which repo exposes it, which consumes it, and
  the exact endpoint the UI submits through).
- TODO config/env/deploy ownership.
- TODO docs per repo.

## Definition of done (cross-repo)

A cross-repo feature is done only when every slice of its surface has landed and
is documented. At design, list the surface per repo; at finish, verify each slice
(or mark N/A); a deferred slice must be stated and tracked, never silently missing.
The request-template checklist in each repo enforces this. The
`cross-repo-completeness` skill automates the check.
"""


README_POINTER = """

## Part of a multi-repo system

`{repo}` is one of several repos. A feature usually spans repos; before calling
one done, cover its full cross-repo surface (API contract, config/env, deploy,
docs). Start cross-repo work from the hub repo with the siblings cloned. See the
hub's `docs/cross-repo-features.md` and `CONTRIBUTING.md`.
"""


def write(path, content, force):
    if os.path.exists(path) and not force:
        print(f"  skip (exists): {path}")
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    print(f"  wrote: {path}")
    return True


def main():
    ap = argparse.ArgumentParser(description="Scaffold cross-repo completeness artifacts.")
    ap.add_argument("--hub", required=True)
    ap.add_argument("--repo", action="append", required=True, dest="repos")
    ap.add_argument("--forge", choices=["gitlab", "github"], required=True)
    ap.add_argument("--remote-base", default="")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    hub = os.path.abspath(args.hub)
    repos = [os.path.abspath(r) for r in args.repos]
    hub_name = os.path.basename(hub)
    repo_names = [os.path.basename(r) for r in repos]
    if hub not in repos:
        print(f"ERROR: --hub {hub} must also be listed via --repo", file=sys.stderr)
        return 2

    mr_path = (".gitlab/merge_request_templates/Default.md" if args.forge == "gitlab"
               else ".github/pull_request_template.md")

    for repo in repos:
        name = os.path.basename(repo)
        if not os.path.isdir(repo):
            print(f"  skip (not a dir): {repo}")
            continue
        print(name + ":")
        write(os.path.join(repo, mr_path), MR_TEMPLATE, args.force)
        write(os.path.join(repo, "CONTRIBUTING.md"),
              contributing(name, hub_name, repo_names, args.remote_base), args.force)
        readme = os.path.join(repo, "README.md")
        pointer = README_POINTER.format(repo=name)
        if os.path.exists(readme):
            existing = open(readme).read()
            if "Part of a multi-repo system" not in existing:
                with open(readme, "a") as f:
                    f.write(pointer)
                print(f"  appended pointer: {readme}")
            else:
                print(f"  skip (pointer present): {readme}")
        else:
            write(readme, f"# {name}\n{pointer}", args.force)

    print(f"{hub_name} (hub):")
    write(os.path.join(hub, "docs/cross-repo-features.md"),
          guide_skeleton(hub_name, repo_names, args.remote_base), args.force)

    print("\nDone. Now fill in the TODOs in "
          f"{hub_name}/docs/cross-repo-features.md with the real repo map and seams, "
          "and add a one-line pointer to it from each repo's AGENTS.md.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
