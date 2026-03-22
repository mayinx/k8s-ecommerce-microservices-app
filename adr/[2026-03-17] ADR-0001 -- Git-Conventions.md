# ADR-0001: Git conventions (workflow, branching, commit messages)

Status: Accepted  
Date: 2026-03-17

## Problem / Issue

Without explicit Git conventions, the repo’s change process can drift quickly when it comes to: 

- (1) **branch strategy/workflow**: Without a proven branch strategy + git workflow contributors might default to long-lived branches or even direct commits 

- (2) **commit semantics + conventions**: Commit Messages could become inconsistent and hard to interpret without solid commit standards  

- (3) **merge discipline / quality gate**: Without clear merge rules and quality standards, work can be merged before it is verified (WIP-Branches, failing checks), causing the default branch to become unstable

This reduces reviewability, increases merge risk/conflicts and makes automation harder (CI/CD pipelines, changelogs).

## Context

This project applies professional engineering standards with consistent workflow and documentation conventions to keep changes reviewable, reproducible, and automation-friendly across phases.

- This project is developed phase-by-phase and will introduce CI/CD and automated checks in later phases.
- The workflow must therefore a) be professional and battle tested, b) keep changes reviewable, reproducible, and automation-friendly + c) stay lightweight for a solo developer   
- A clear branch/merge model plus a consistent commit message standard are required
- Goal: Anchor the default branch as reliable reference point for feature branches and pipelines.

## Options considered

1. No standard (direct commits to `main`/`master`, free-form messages)
2. GitFlow-style (multiple long-lived branches, release branches)
3. Trunk-based (solo-friendly) + Conventional Commits (short-lived branches) ✅

## Decision

### Workflow model: trunk-based 

This project utilizes trunk-based development: a widely used, flexible Git workflow built around a single long-lived core branch (the “trunk”) - and short-lived branches for focused changes. 

Work is done on a short-lived branch (e.g. a feature or docs update) and merged back into the "trunk" once it is complete and reviewable. This keeps updates small, frequent, and easy to audit.

Trunk-based development is a common DevOps practice. It reduces long-lived divergence, keeps merge conflicts small, and aligns naturally with CI/CD because the trunk is kept in a consistently runnable/releasable state. 

**Guidelines:**

In this project, this translates into the following rules:

- **Use the repository’s default branch (in our case `master`) as trunk and keep it runnable/relesable.**
  - `master` stays a reliable, unbroken, stable reference point at all times, ready to deploy.
  - No half-finished changes are permitted on `master`.

- **Use short-lived branches for each change.**
  - branch prefixes: `feat`, `fix`, `docs`, `chore`, `refactor`
  - keep branches narrow in scope (one topic per branch).

-** Merge back frequently in small, working + reviewable increments.**
  - merge only branches that are working and reviewable (no “WIP merge”!).

> Info: GitFlow was considered but not chosen because it introduces additional long-lived branches (`develop`/`release`/`hotfix`) and ceremony that doesn’t pay off for this solo, phase-driven project. Trunk-based keeps the workflow lightweight while still supporting reviewability and CI/CD via short-lived branches and PRs.

Source: [Trunk-based development](https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development) 

### Default branch name: `master`

- Thsi project uses `master` (inherited from upstream) as the repository’s default branch name - we keep it that way for the time beeing.
- In case renaming to `main` comes up later: [GitLab Docs: Change the default branch name for a project](https://docs.gitlab.com/user/project/repository/branches/default/#change-the-default-branch-name-for-a-project)

### Branching Workflow 

The following proven branching workflow is PR-based, uncomplicated + "solo-friendly": 

1. Create a short-lived branch from the default branch (here `master`).
~~~bash
# schema
git checkout -b <type>/<scope>-<topic>

# example
git checkout -b docs/adr-workflow-and-docs-system
~~~

2. Commit in small increments using Conventional Commits.
~~~bash
# Stage changes (typical)
git add <files-or-folders>

# Commit with Conventional Commits
git commit -m "<type>(<scope>): <imperative description>"
~~~

3. Push the branch early (after the first commit) to back up work and allow CI to run.
~~~bash
# First push (sets upstream tracking)
git push -u origin <type>/<scope>-<topic>

# Subsequent pushes
git push
~~~

4. On the remote: Merge back via a PR/MR targeting the default branch (`master`).

5. After the PR/MR merge, update the local default branch.
~~~bash
git checkout master
git pull --ff-only
~~~

### Merge strategy  

When merging a MR/PR back into master:  

- Prefer **Squash and merge** for most feature branches (keeps the default branch history clean).
- Use **Merge commit** when the individual commits are intentionally meaningful (e.g., ADR series, stepwise docs evolution).

### Branch naming

Use lowercase, hyphen-separated names:

- `feat/<scope>-<topic>`
- `fix/<scope>-<topic>`
- `docs/<scope>-<topic>`
- `chore/<scope>-<topic>`
- `refactor/<scope>-<topic>`

Examples:
- `feat/ingress-traefik-storefront`
- `docs/project-docs-phase02-runbook`
- `fix/k8s-frontend-service`
- `chore/repo-add-githooks`

### Commit message format (Conventional Commits)

Use: `<type>(<scope>): <short imperative description>`

Types used:
- `feat`, `fix`, `docs`, `refactor`, `chore`, `test`

Scopes (keep stable and repo-relevant):
- `readme`, `project-docs`, `adr`, `repo`
- `k8s`, `ingress`, `ci`, `iac`, `monitoring`, `security`, `dr`
- `app`, `api` (only when custom service code exists)

Examples per type:

docs:
- `docs(readme): clarify Phase 02 ingress steps`
- `docs(project-docs): add Phase 01 evidence snapshot commands`
- `docs(adr): add git conventions ADR`

feat:
- `feat(ingress): add Traefik ingress for storefront host`
- `feat(ci): add dev deploy job for k3s namespace`
- `feat(monitoring): deploy Prometheus and Grafana manifests`

fix:
- `fix(k8s): correct front-end service selector`
- `fix(ci): block image push when tests fail`
- `fix(docs): correct storefront NodePort in Phase 01`

refactor:
- `refactor(project-docs): rename phase folders for consistent indexing`
- `refactor(k8s): split ingress manifest into dedicated file`
- `refactor(ci): simplify pipeline rules without changing stages`

chore:
- `chore(repo): add adr folder and README links`
- `chore(deps): bump base image tag for runner`
- `chore(tooling): add optional commit-msg hook`

test:
- `test(api): add unit tests for policy rules`
- `test(e2e): add Cypress smoke test`
- `test(ci): add pipeline job to run tests only`

### Perspective: Optional enforcement (commit-msg hook)

To enfore the format of commit messages, a local `commit-msg` hook could be introduced - or husky. This will be invbestiagted later on to avoid blocking the project progress in this early stage.

## Consequences / Outcome

Using a trunk-based workflow along with Conventional Commits + short-lived branches results in a number of benefits:

- The workflow is professional and proven - while staying lightweight and solo-friendfly at the same time.
- The commit history becomes consistently readable.
- The intent of a branch or a commit is obvious at a glance.
- An automation-friendly commit format is available without introducing heavy tooling.
- CI/CD benefits: smaller, frequent merges keep the default branch close to deployable, so pipelines run on a stable reference and failures are easier to isolate.
- Review + rollback benefits: changes are scoped (short-lived branches + clear commit intent), making reviews faster and rollbacks less risky when a pipeline or deploy fails.

## References
- [Trunk-based development](https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development) 
- [Conventional Commits spec - A specification for adding human and machine readable meaning to commit messages](https://www.conventionalcommits.org/en/v1.0.0/)
- [Githooks Documentation (commit-msg)](https://git-scm.com/docs/githooks)
- [GitLab Docs: Change the default branch name for a project](https://docs.gitlab.com/user/project/repository/branches/default/#change-the-default-branch-name-for-a-project)