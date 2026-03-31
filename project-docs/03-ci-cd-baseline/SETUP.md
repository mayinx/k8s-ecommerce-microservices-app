# 🛠️ Setup Guide — Phase 03 (CI/CD Baseline): GitHub Environments, Workflow Readiness, and Local Validation

> ## 👤 About
> This document is the **setup guide** for **Phase 03 (CI/CD Baseline)**.  
> It covers the **repository/platform preparation** and the **local validation prerequisites** that had to be in place before the real CI/CD delivery proof could start.  
> It is intentionally focused on setup-only topics: GitHub Actions readiness, GitHub Environments, required reviewers, GHCR usage, and optional local overlay validation.  
> For the full build diary and the broader CI/CD/Kubernetes reasoning, see: **[03-ci-cd-baseline/IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For the short happy-path rerun flow, see: **[03-ci-cd-baseline/RUNBOOK.md](RUNBOOK.md)**.

---

## 📌 Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done**](#definition-of-done)
- [**Preconditions**](#preconditions)
- [**Step 01 — Verify repository Actions readiness**](#step-01--verify-repository-actions-readiness)
- [**Step 02 — Create GitHub Environments for `dev` and `prod`**](#step-02--create-github-environments-for-dev-and-prod)
- [**Step 03 — Configure the production approval gate**](#step-03--configure-the-production-approval-gate)
- [**Step 04 — Verify workflow-file presence and visibility**](#step-04--verify-workflow-file-presence-and-visibility)
- [**Step 05 — Optional local validation checks**](#step-05--optional-local-validation-checks)
- [**Sources**](#sources)

---

## Purpose / Goal

- Prepare the repository and GitHub settings so the Phase 03 delivery workflow can run correctly.
- Establish explicit `dev` / `prod` environment modeling inside GitHub.
- Enable an approval-gated `prod` smoke path through GitHub Environments.
- Confirm the repository is ready for:
  - overlay validation
  - GHCR image publishing
  - `dev` smoke deployment
  - approval-gated `prod` smoke deployment

## Definition of done

The Phase 03 setup is considered done when:

- GitHub Actions is usable in the repository
- the workflow file exists at:
  - `.github/workflows/phase-03-delivery.yaml`
- GitHub Environments exist for:
  - `dev`
  - `prod`
- the `prod` environment has **Required reviewers** enabled
- one reviewer is configured for `prod`
- the workflow appears in the GitHub Actions UI
- optional local overlay validation works when used

## Preconditions

- repository access on GitHub
- permission to edit repository settings
- permission to edit repository workflows
- optional local tools for validation:
  - `kubectl`
  - Docker

---

## Step 01 — Verify repository Actions readiness

### Rationale

Before the Phase 03 workflow can run, GitHub Actions must be enabled and the repository must allow the workflow actions used in this phase.

### GitHub click path

Go to:

- `Repository -> Settings -> Actions -> General`

Verify:

- Actions are enabled for the repository
- the repository settings do not block the workflow actions used in this phase
- the workflow can run on GitHub-hosted runners

### Why this matters

The Phase 03 workflow depends on:

- GitHub Actions
- GitHub-hosted runners
- reusable workflow actions such as:
  - `actions/checkout`
  - `docker/login-action`
  - `docker/build-push-action`
  - `engineerd/setup-kind`

### Result

The repository is allowed to execute the workflow path required by Phase 03.

---

## Step 02 — Create GitHub Environments for `dev` and `prod`

### Rationale

The workflow uses:

- `environment: dev`
- `environment: prod`

So those named environments must exist in the repository settings.

### GitHub click path

Go to:

- `Repository -> Settings -> Environments`

Create:

- `dev`
- `prod`

### Why this matters

GitHub Environments are the place where deployment protection rules are defined.  
Without these environments, the workflow could still exist as YAML, but the intended environment model and promotion flow would not be demonstrated cleanly.

### Result

The repository now has explicit named deployment environments for:

- `dev`
- `prod`

---

## Step 03 — Configure the production approval gate

### Rationale

Phase 03 is supposed to prove not only automated deployment, but also an explicit promotion checkpoint before `prod`.

### GitHub click path

Go to:

- `Repository -> Settings -> Environments -> prod`

Enable:

- **Required reviewers**

Add:

- one reviewer (yourself)

### Why the repository owner is used here

This repository is a solo project, not a team-operated production service.  
The goal in this phase is to prove the approval-gate mechanism itself.

So the smallest workable proof is:

- use the repository owner as the required reviewer

In a team setup, this would typically be:

- another engineer
- a team
- or a release-approval role

### Result

The `prod` environment is now approval-gated and can pause the workflow until it is explicitly approved.

---

## Step 04 — Verify workflow-file presence and visibility

### Rationale

The repository settings can be correct, but the workflow still needs to be present on the active branch and visible in the GitHub Actions UI.

### Repository path to verify

- `.github/workflows/phase-03-delivery.yaml`

### GitHub UI check

Go to:

- `Repository -> Actions`

Verify that:

- the workflow is visible
- its name appears as:
  - `phase-03-delivery`

### Result

The workflow is now present and visible as a runnable GitHub Actions workflow.

---

## Step 05 — Optional local validation checks

### Rationale

These checks are optional, but useful when validating the Phase 03 setup and local repo state before or after GitHub workflow runs.

### Commands

~~~bash
# Verify kubectl is available
kubectl version --client

# Verify Docker is available
docker --version

# Verify the dev overlay renders
kubectl kustomize deploy/kubernetes/kustomize/overlays/dev > /tmp/dev-rendered.yaml

# Verify the prod overlay renders
kubectl kustomize deploy/kubernetes/kustomize/overlays/prod > /tmp/prod-rendered.yaml
~~~

### Result

- local validation tools are available
- both overlays render successfully if the local repo state matches the Phase 03 implementation baseline

---

## Sources

- GitHub Docs — Workflow syntax for GitHub Actions  
  https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax

- GitHub Docs — Managing environments for deployment  
  https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments

- GitHub Docs — Deploying to a specific environment  
  https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/deploy-to-environment

- GitHub Docs — GitHub-hosted runners  
  https://docs.github.com/en/actions/concepts/runners/github-hosted-runners

- GitHub Docs — Working with the Container registry  
  https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry