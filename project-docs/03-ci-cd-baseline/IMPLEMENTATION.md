# Phase 03 baseline = GitHub Actions + raw manifests + dev/prod namespaces

Steps:

- GitHub Actions
- GHCR
- self-hosted GitHub runner on your laptop for deploy jobs
- deploy to sock-shop-dev automatically
- deploy to sock-shop-prod after manual approval
- based on the already proven Kubernetes manifest path

- But: No helm (not yet) - reason:

Fragments:

- Helm exists in the repo, but it is not ready-to-use out of the box for our Phase-03 baseline path.
- Helm was evaluated during Phase 03 triage, but because it was optional and showed dependency/setup friction, the CI/CD baseline was implemented first on the already proven Kubernetes deployment path. Helm remained a later enhancement candidate.
- I evaluated Helm: 
    - I found an outdated/incomplete dependency setup
    - Helm is not required
    - I chose the already proven Kubernetes path for the baseline
    - I preserved Helm as a later enhancement candidate
- So: Helm is deferred, not rejected!


--------


# 🧱 Implementation Log — Phase 03 (CI/CD Baseline): GitHub Actions delivery smoke path for dev/prod

> ## 👤 About
> This document is the implementation log and detailed project build diary for **Phase 03 (CI/CD Baseline)**.  
> It records the full implementation path including rationales, key observations, corrections, verification steps, and evidence pointers so the work remains auditable and reproducible.  
> For a shorter, reproducible **TL;DR command checklist / rerun guide**, see: **[03-ci-cd-baseline/RUNBOOK.md](RUNBOOK.md)**.

---

## 📌 Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done (Phase 03)**](#definition-of-done-phase-03)
- [**Preconditions**](#preconditions)
- [**Step 0 — Evaluate Helm as an optional deployment path**](#step-0--evaluate-helm-as-an-optional-deployment-path)
- [**Step 1 — Add an environment-specific deployment layer with Kustomize**](#step-1--add-an-environment-specific-deployment-layer-with-kustomize)
- [**Step 2 — Prove the manual dev deployment baseline before automation**](#step-2--prove-the-manual-dev-deployment-baseline-before-automation)
- [**Step 3 — Prepare GitHub environments for dev and prod**](#step-3--prepare-github-environments-for-dev-and-prod)
- [**Step 4 — Create a dedicated GitHub Actions delivery workflow**](#step-4--create-a-dedicated-github-actions-delivery-workflow)
- [**Step 5 — Run the first workflow and triage the openapi failure**](#step-5--run-the-first-workflow-and-triage-the-openapi-failure)
- [**Step 6 — Re-run the workflow and prove the dev smoke deployment**](#step-6--re-run-the-workflow-and-prove-the-dev-smoke-deployment)
- [**Step 7 — Prove the prod approval gate and prod smoke deployment**](#step-7--prove-the-prod-approval-gate-and-prod-smoke-deployment)
- [**Cleanup / rollback notes**](#cleanup--rollback-notes)
- [**Baseline observations and evidence (Phase 03)**](#baseline-observations-and-evidence-phase-03)
- [**Sources**](#sources)

---

## Purpose / Goal

### Build a valid CI/CD baseline before moving to the real target environment

- The goal of Phase 03 is to add a **working CI/CD baseline** that proves **build/push automation**, **Kubernetes deployment automation**, **environment separation**, and an **approval-gated production flow**.
- This phase intentionally focuses on the **delivery mechanics first**, not yet on the final long-lived Proxmox target.
- A clean CI/CD baseline already provides real DevOps value:
  - pipeline mechanics
  - deployment automation
  - Kubernetes deploy reproducibility
  - environment modeling
  - approval flow

### Why use GitHub-hosted runners + Kind here

- This repository is a **public fork**, so using a self-hosted runner attached to a personal machine would introduce an unnecessary security risk for this phase.
- GitHub-hosted runners are a better fit here because they run workflow jobs in fresh hosted VMs, while `kind` provides a clean temporary Kubernetes target that is explicitly suited to local development and CI.
- This gives us a strong **delivery smoke-test path** now, while keeping the later transition to Proxmox straightforward.

### Why not move directly to Proxmox in this phase

- Going directly to Proxmox here would stack too many moving parts at once:
  - new target infrastructure
  - cluster setup
  - networking / firewall / ingress concerns
  - CI/CD logic
- A more disciplined DevOps move is to validate the **pipeline + deploy mechanics** first in a clean temporary Kubernetes target, then retarget the same delivery flow later to the real environment.

> **🧩 Info box — CI/CD pipeline**
>
> A **CI/CD pipeline** is an automated workflow that runs defined delivery steps after a trigger such as a push or a manual start.  
> In this phase, the important elements are:
> - validation of the Kubernetes overlays
> - image build and registry push
> - deployment smoke tests for `dev` and `prod`
> - an approval gate before the `prod` deployment step

> **🧩 Info box — GitHub-hosted runner**
>
> A **GitHub-hosted runner** is a GitHub-provided VM used to run workflow jobs.  
> In this phase, hosted runners are used for all jobs because the repository is public and the goal is to avoid attaching a self-hosted runner to a personal machine.

> **🧩 Info box — kind**
>
> `kind` = **Kubernetes in Docker**.  
> It creates a temporary Kubernetes cluster inside Docker containers and is explicitly designed for local development and CI.  
> In this phase, `kind` is used as a **clean deployment smoke-test target** for `dev` and `prod`.

> **🧩 Info box — GHCR**
>
> **GHCR** = **GitHub Container Registry**.  
> It stores container images under the GitHub account / repository ecosystem and can be used directly from GitHub Actions with `GITHUB_TOKEN`.

---

## Definition of done (Phase 03)

- A dedicated GitHub Actions workflow exists at `.github/workflows/phase-03-delivery.yaml`
- The workflow validates both Kustomize overlays
- The workflow builds and pushes at least one repo-owned support image to GHCR
- The workflow deploys the **dev smoke environment** successfully
- The workflow pauses before the **prod smoke environment** and requires approval
- The **prod smoke environment** also deploys successfully after approval
- The deployment path remains compatible with a later retargeting to Proxmox

---

## Preconditions

- The proven raw Kubernetes manifest baseline from earlier phases exists
- Phase 03 Kustomize overlays for `dev` and `prod` exist
- GitHub environments `dev` and `prod` are configured in the repository settings
- `prod` uses required reviewers for the approval gate
- The workflow file exists in `.github/workflows/phase-03-delivery.yaml`

---

## Step 0 — Evaluate Helm as an optional deployment path

**Rationale:** Before choosing the deployment mechanism for Phase 03, evaluate whether the existing Helm chart is usable out of the box for dev/prod automation.

~~~bash
# Inspect the chart metadata
$ sed -n '1,220p' deploy/kubernetes/helm-chart/Chart.yaml
apiVersion: v1
description: A Helm chart for Sock Shop
name: helm-chart
version: 0.3.0

# Inspect legacy Helm dependencies
$ sed -n '1,220p' deploy/kubernetes/helm-chart/requirements.yaml
dependencies:
  - name: nginx-ingress
    version: 0.4.2
    repository: https://helm.nginx.com/stable

# Check whether the expected dependency artifacts are present
$ sed -n '1,220p' deploy/kubernetes/helm-chart/Chart.lock
sed: can't read deploy/kubernetes/helm-chart/Chart.lock: No such file or directory

$ tree -L 2 deploy/kubernetes/helm-chart/charts
deploy/kubernetes/helm-chart/charts  [error opening dir]

0 directories, 0 files
~~~

**Observed result:**

- The repository contains a Helm chart, so Helm was a realistic option to evaluate.
- The chart uses the older dependency mechanism via `requirements.yaml`.
- A dependency on `nginx-ingress` is declared.
- At the same time, there is no `Chart.lock` and no usable `charts/` dependency directory.

**Conclusion:**

Helm was evaluated and taken seriously, but it was **not ready-to-use out of the box** for this phase.  
Because Helm is optional for the project, and because the already proven raw manifest path existed, the Phase 03 baseline was implemented first on the **manifest + Kustomize** path. Helm remains a later enhancement candidate.

> **🧩 Info box — Helm vs manifests**
>
> **Helm** is a Kubernetes package manager and templating layer.  
> Plain **manifests** are direct Kubernetes YAML resources.  
> In this phase, the plain-manifest path was preferred because it was already proven and did not introduce extra dependency/setup friction.

---

## Step 1 — Add an environment-specific deployment layer with Kustomize

**Rationale:** The proven raw manifest baseline is single-environment oriented. Phase 03 needs a thin layer that introduces environment separation for `dev` and `prod` without rewriting the upstream manifests.

~~~bash
# Initial attempt: render the dev overlay
$ kubectl kustomize deploy/kubernetes/kustomize/overlays/dev | sed -n '1,120p'
error: accumulating resources: accumulation err='accumulating resources from '../../base' ... security; file ... is not in or below .../deploy/kubernetes/kustomize/base' ...

# After restructuring the base into the manifests directory, render again
$ kubectl kustomize deploy/kubernetes/kustomize/overlays/dev | sed -n '1,40p'
apiVersion: v1
kind: Namespace
metadata:
  name: sock-shop-dev
...
~~~

**Observed result:**

- The first Kustomize layout hit a path/security restriction and could not render.
- The fix was to move the Kustomize base into `deploy/kubernetes/manifests/` and let the overlays reference that proven manifest location directly.
- After that change, the overlays rendered successfully.

**Conclusion:**

Kustomize was chosen as the minimal environment layer because it:
- reuses the already proven raw manifests
- keeps upstream manifests untouched
- supports `dev` / `prod` environment separation cleanly

> **🧩 Info box — Kustomize overlay**
>
> A **Kustomize overlay** is a thin customization layer on top of a base set of Kubernetes resources.  
> In this phase, the overlays do three important things:
> - define the target namespace (`sock-shop-dev` / `sock-shop-prod`)
> - add namespace manifests so the deploy path is reproducible
> - patch the `front-end` Service from fixed `NodePort` to `ClusterIP` to avoid cross-environment port collisions

---

## Step 2 — Prove the manual dev deployment baseline before automation

**Rationale:** Before automating the deployment path in GitHub Actions, prove manually that the `dev` overlay can recreate the namespace and deploy the stack from scratch.

~~~bash
# Delete the dev namespace so the overlay has to recreate it from scratch
$ kubectl delete namespace sock-shop-dev
namespace "sock-shop-dev" deleted

# Recreate namespace + resources in one command
$ kubectl apply -k deploy/kubernetes/kustomize/overlays/dev
namespace/sock-shop-dev created
deployment.apps/carts created
service/carts created
...
deployment.apps/front-end created
service/front-end created
...

# Inspect the recreated dev resources
$ kubectl get deploy,pods,svc -n sock-shop-dev -o wide
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
front-end      1/1     1            1           ...
catalogue      1/1     1            1           ...
payment        1/1     1            1           ...
user           1/1     1            1           ...
...

# Confirm the key storefront rollout
$ kubectl rollout status deployment/front-end -n sock-shop-dev
deployment "front-end" successfully rolled out
~~~

**Observed result:**

- The dev namespace could be recreated from scratch via the overlay.
- The overlay path proved that namespace creation no longer depended on a manual pre-step.
- The dev stack converged successfully.
- Some services (`catalogue`, `payment`, `user`) were slower to become ready, but they did eventually converge successfully.

**Conclusion:**

The manual **dev deployment baseline** was proven before automation.  
This made the later GitHub Actions implementation much more defensible: the automation step reuses a path that was already known to work manually.

---

## Step 3 — Prepare GitHub environments for dev and prod

**Rationale:** Phase 03 needs explicit environment modeling and a production approval gate.

**GitHub UI preparation:**

- Go to: **Repository → Settings → Environments**
- Create:
  - `dev`
  - `prod`
- In `prod`:
  - enable **Required reviewers**
  - add one reviewer (here: the repository owner)

**Observed result:**

- `dev` became the unprotected smoke environment
- `prod` became the approval-gated smoke environment

**Conclusion:**

This establishes the **manual promotion checkpoint** between `dev` and `prod`.

> **🧩 Info box — GitHub Environment**
>
> A **GitHub Environment** is a named deployment target in GitHub Actions, such as `dev` or `prod`.  
> It can hold protection rules like required reviewers and is used here to pause the `prod` smoke deployment until it is explicitly approved.

---

## Step 4 — Create a dedicated GitHub Actions delivery workflow

**Rationale:** The repository already contains an upstream-style GitHub Actions workflow. Phase 03 needs a separate, cleaner delivery workflow for the project-specific dev/prod CI/CD path.

The resulting workflow file:

- lives at `.github/workflows/phase-03-delivery.yaml`
- uses **GitHub-hosted runners only**
- validates both overlays
- builds and pushes repo-owned support images to GHCR
- deploys the `dev` smoke environment automatically
- deploys the `prod` smoke environment only after approval

### Workflow logic at a glance

1. **`validate-overlays`**
   - checks that both overlays render successfully

2. **`build-push-support-images`**
   - builds/pushes repo-owned support images to GHCR
   - uses a small matrix to avoid hardcoding each build step separately

3. **`deploy-dev-smoke`**
   - starts a temporary `kind` cluster
   - applies the `dev` overlay
   - verifies the key rollouts

4. **`deploy-prod-smoke`**
   - starts another temporary `kind` cluster
   - waits for the `prod` environment approval
   - applies the `prod` overlay
   - verifies the key rollouts

> **🧩 Info box — workflow_dispatch**
>
> `workflow_dispatch` is the GitHub Actions event for **manual workflow starts** from the GitHub UI.  
> In this phase, pushes were the practical first test path on the feature branch, while `workflow_dispatch` becomes more useful once the workflow exists on the default branch.

> **🧩 Info box — upstream vs downstream (workflow graph)**
>
> In the workflow graph, **upstream jobs** run earlier and **downstream jobs** depend on them via `needs:`.  
> Example: if `build-push-support-images` fails, the deploy jobs are downstream and do not run.

---

## Step 5 — Run the first workflow and triage the openapi failure

**Rationale:** The first workflow run should expose whether the selected repo-owned image build surfaces are actually usable in the Phase 03 baseline.

~~~bash
# Relevant workflow result signal from the first run
Build and push repo-owned images to GHCR (openapi)
ERROR: failed to build: failed to solve: process "/bin/sh -c npm install" did not complete successfully: exit code: 236
~~~

From the earlier repo audit:

- `openapi` is not a main runtime Sock Shop service
- it is a repo-owned support/test build surface
- its metadata still points to **Node 6 / npm 3**

**Observed result:**

- `healthcheck` built and pushed successfully
- `openapi` failed during `npm install`
- downstream deploy jobs did not run because the build matrix was not fully successful

**Conclusion:**

Excluding `openapi` from the Phase 03 workflow was the right decision to unblock the actual CI/CD baseline.  
This was not a random cut; it was a documented decision based on:
- the repo audit
- the legacy Node 6 / npm 3 dependency
- the fact that `openapi` is optional for the main delivery path

---

## Step 6 — Re-run the workflow and prove the dev smoke deployment

**Rationale:** After removing `openapi` from the matrix, the workflow should be able to complete the `dev` smoke deployment path.

**Observed result:**

- overlay validation succeeded
- `healthcheck` build/push to GHCR succeeded
- `deploy-dev-smoke` started a fresh `kind` cluster
- the `dev` overlay was applied successfully
- the key rollouts succeeded

**Conclusion:**

The GitHub Actions workflow now proved a complete **dev smoke delivery path**:
- validate
- build/push
- deploy
- verify

---

## Step 7 — Prove the prod approval gate and prod smoke deployment

**Rationale:** Phase 03 is only fully convincing if the `prod` environment gate is also exercised successfully.

During feature-branch testing, the `prod` job was temporarily allowed to run from the active Phase 03 feature branch so that the approval gate could be tested before merge. After the proof succeeded, the job condition was restored to `master` only.

**Observed result:**

- the workflow paused before `deploy-prod-smoke`
- GitHub required explicit approval through the `prod` environment
- after approval, the `prod` smoke deployment succeeded as well

**Conclusion:**

Phase 03 proved:
- automatic `dev` smoke deployment
- approval-gated `prod` smoke deployment
- a realistic CI/CD promotion model without yet depending on the final Proxmox target

---

## Cleanup / rollback notes

- The temporary feature-branch allowance for the `prod` smoke job was reverted after the proof succeeded.
- The workflow keeps the final intended behavior:
  - `dev` smoke deploy on the active workflow path
  - `prod` smoke deploy only on `master` and only after approval
- `openapi` remains excluded from the workflow for now and is tracked as a later legacy follow-up item.

---

## Baseline observations and evidence (Phase 03)

### What was implemented

- A new phase-specific workflow was added:
  - `.github/workflows/phase-03-delivery.yaml`
- A Kustomize-based environment layer was added for:
  - `sock-shop-dev`
  - `sock-shop-prod`
- Namespace creation was moved into the overlay path so the deploy baseline became reproducible
- A GitHub-hosted-runner-only delivery path was chosen for this phase
- `openapi` was excluded from the workflow after a documented legacy build failure

### What was verified

- Helm was evaluated and deferred with a documented rationale
- Kustomize overlays render successfully
- The dev namespace can be recreated from scratch via the overlay
- The full dev smoke path works in GitHub Actions
- The prod approval gate works
- The prod smoke deployment also succeeds after approval

### Evidence index

**Local / Kubernetes proof placeholders**
- `[YYYY-MM-DD]-Phase-03-kustomize-dev-render-success.png`  
  - overlay render / apply proof after the Kustomize path fix
- `[YYYY-MM-DD]-Phase-03-dev-namespace-recreated.png`  
  - `sock-shop-dev` recreated from the overlay
- `[YYYY-MM-DD]-Phase-03-dev-resources-healthy.png`  
  - `kubectl get deploy,pods,svc -n sock-shop-dev -o wide`
- `[YYYY-MM-DD]-Phase-03-dev-rollout-success.png`  
  - successful rollout proof for the dev baseline

**GitHub / workflow proof placeholders**
- `[YYYY-MM-DD]-Phase-03-github-environments-overview.png`  
  - repository `dev` / `prod` environment overview
- `[YYYY-MM-DD]-Phase-03-prod-required-reviewer-config.png`  
  - `prod` environment protection rule / reviewer config
- `[YYYY-MM-DD]-Phase-03-workflow-run-success.png`  
  - successful pipeline overview
- `[YYYY-MM-DD]-Phase-03-ghcr-healthcheck-image.png`  
  - pushed GHCR package/image
- `[YYYY-MM-DD]-Phase-03-prod-approval-gate.png`  
  - workflow paused before `prod`
- `[YYYY-MM-DD]-Phase-03-prod-smoke-success.png`  
  - successful prod smoke completion after approval

### Deferred follow-ups captured during this phase

- `openapi` build surface excluded for now because it still depends on legacy Node 6 / npm 3
- GitHub Actions runtime warnings about Node.js 20 deprecation were noted for later action/runtime cleanup
- Kubernetes manifests still use deprecated `beta.kubernetes.io/os` node selector labels and should later switch to `kubernetes.io/os`
- GitHub Actions hardening remains a later step:
  - tighten allowed actions
  - pin third-party actions to full SHAs
  - add workflow protection such as CODEOWNERS once the pipeline is stable

---

## Sources

### Project requirements and project-specific standards
- `Project Requirements & Expectations.docx.pdf`
- `CAPSTONE_COLLAB_RULES.md`
- `adr/[2026-03-18] ADR-0002 -- Docs-System.md`

### GitHub Actions / GitHub Environments / GHCR
- GitHub Docs — Workflow syntax for GitHub Actions  
- GitHub Docs — Managing environments for deployment  
- GitHub Docs — Working with the Container registry  
- GitHub Docs — GitHub-hosted runners

### kind
- kind official documentation

