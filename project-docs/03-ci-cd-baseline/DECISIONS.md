# Decision Log — Phase 03 (CI/CD Baseline) - GitHub Actions delivery smoke path for dev/prod 

> ## 👤 About
> This document is the **phase-local decision log** for **Phase 03 (CI/CD Baseline)**.  
> It captures the full decision story for this phase without overloading the shorter project-wide summary in **[project-docs/DECISIONS.md](../DECISIONS.md)**.  
> For the full chronological build diary, see: **[03-ci-cd-baseline/IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For the short rerun flow, see: **[03-ci-cd-baseline/RUNBOOK.md](RUNBOOK.md)**.  
> For the setup prerequisites of this phase, see: **[03-ci-cd-baseline/SETUP.md](SETUP.md)**.

---

## 📌 Index

- [**Quick recap of Phase 03**](#quick-recap-phase-03)
  - [**Starting point: Phase 03 needed a real delivery baseline**](#starting-point-phase-03-needed-a-real-delivery-baseline)
  - [**Obstacle 1: Helm was not a viable baseline at this point**](#obstacle-1-helm-was-not-a-viable-baseline-at-this-point)
  - [**Chosen path: Reuse the proven raw manifests and add a thin Kustomize environment layer**](#chosen-path-reuse-the-proven-raw-manifests-and-add-a-thin-kustomize-environment-layer)
  - [**CI/CD runtime choice: GitHub Actions + hosted runners + kind**](#cicd-runtime-choice-github-actions--hosted-runners--kind)
  - [**Obstacle 2: The repo-owned `openapi` image target failed and had to be deferred / excluded from workflow**](#obstacle-2-the-repo-owned-openapi-image-target-failed-and-had-to-be-deferred--excluded-from-workflow)
  - [**Verified result: Successful dev + prod smoke delivery through GitHub Actions Pipeline**](#verified-result-successful-dev--prod-smoke-delivery-through-github-actions-pipeline)
- [**Key Phase Decisions**](#key-phase-decisions)
  - [**P03-D01 — Deployment input = raw manifests + Kustomize overlays (not Helm)**](#p03-d01--deployment-input--raw-manifests--kustomize-overlays-not-helm)
  - [**P03-D02 — Environment model = namespace-based dev/prod overlays**](#p03-d02--environment-model--namespace-based-devprod-overlays)
  - [**P03-D03 — CI/CD runtime = GitHub Actions + GitHub-hosted runners + kind**](#p03-d03--cicd-runtime--github-actions--github-hosted-runners--kind)
  - [**P03-D04 — Production gate = GitHub Environment with required reviewer**](#p03-d04--production-gate--github-environment-with-required-reviewer)
  - [**P03-D05 — Workflow image scope = keep `healthcheck`, defer `openapi`**](#p03-d05--workflow-image-scope--keep-healthcheck-defer-openapi)
- [**Deferred follow-ups recorded by this phase**](#deferred-follow-ups-recorded-by-this-phase)

---

## Quick recap of Phase 03

Phase 03 added a working CI/CD baseline for the project’s `dev` / `prod` delivery path.

### Starting point: Phase 03 needed a real delivery baseline

The goal of this phase was to move beyond a manually proven Kubernetes baseline and add a **real CI/CD smoke path** that proves:

- environment separation
- build/push automation
- deployment automation
- and an approval-gated promotion step for `prod`

### Obstacle 1: Helm was not a viable baseline at this point

The main design question at the start of the phase was whether to use the repository’s existing Helm chart or keep building on the already proven raw-manifest baseline. 

Helm was evaluated first, but even after fetching the missing chart dependency, the actual install path failed because the pulled `nginx-ingress` subchart relied on deprecated Kubernetes API versions. 

That made Helm a poor fit for a fast baseline in this phase.

### Chosen path: Reuse the proven raw manifests and add a thin Kustomize environment layer

Instead, the phase **reused the already proven raw manifests** and added a **thin Kustomize environment layer** for:

- `sock-shop-dev`
- `sock-shop-prod`

This made it possible to introduce environment separation **without rewriting or duplicating the full manifest set**.

### CI/CD runtime choice: GitHub Actions + hosted runners + kind

For the CI/CD runtime, the chosen baseline was:

- GitHub Actions
- GitHub-hosted runners
- `kind` (Kubernetes in Docker) as an ephemeral "dummy" cluster (only living in the ephemeral GitHub Actions runners) used as as the temporary Kubernetes smoke target 
- GitHub Environments for:
  - `dev`
  - `prod`
- "required reviewers" on `prod` for the approval gate

This gave the project a **real delivery proof in a temporary, isolated sandbox** before moving CI/CD-based delivery on the final persistent Proxmox target (see Phase 05).

### Obstacle 2: The repo-owned `openapi` image target failed and had to be deferred / excluded from workflow  

The first workflow run surfaced a legacy problem in the repo-owned `openapi` image target.

That target failed during `npm install` and was judged **non-essential for proving the main delivery path**, so it was excluded for now while the `healthcheck` image remained in scope.

### Verified result: Successful dev + prod smoke delivery through GitHub Actions Pipeline

After that fix, the workflow was successfully executed on GitHub incl. automated deployment of `dev` and gated deployment of `prod`:   

- `dev` smoke deployment is automated
- `prod` smoke deployment is approval-gated
- the delivery path remains easy to retarget later to Proxmox

The successfulyl implemented CI/CD smoke path works like this:

1. validate the `dev` / `prod` overlays
2. build and push the repo-owned `healthcheck` image to GHCR
3. deploy the `dev` smoke environment automatically
4. pause before `prod`
5. require approval through the GitHub `prod` environment
6. deploy the `prod` smoke environment after approval

This gives the repository a real delivery baseline before moving to the final infrastructure target.

---

## Key Phase Decisions

### Decision (P03-D01): deployment input = raw manifests + Kustomize overlays (not Helm)

- **Decision:** Use the already proven raw Kubernetes manifests as the base deployment path and add a thin Kustomize layer for `dev` and `prod`, instead of using the existing Helm chart in this phase.
- **Context / problem:** Phase 03 needed environment separation and CI/CD-friendly deployment input. The repository already contained a Helm chart, so Helm had to be evaluated first.
- **Options considered:**
  - use the existing Helm chart
  - continue with raw manifests only
  - use raw manifests + Kustomize overlays ✅
- **Chosen option + why:** Helm introduced legacy dependency friction and incompatible Kubernetes API usage. The raw manifest baseline was already proven, and Kustomize provided a small, reviewable environment layer without duplicating the whole manifest set.
- **Verification / evidence:**
  - `helm lint` and `helm template` initially failed due to a missing `nginx-ingress` dependency
  - `helm dependency build` fetched that dependency
  - `helm upgrade --install` still failed because the subchart used deprecated API versions such as:
    - `apiextensions.k8s.io/v1beta1`
    - `rbac.authorization.k8s.io/v1beta1`
  - the Kustomize overlays rendered successfully
- **Consequences / follow-ups:**
  - Helm is deferred, not rejected
  - Kustomize becomes the deployment definition layer for this phase
  - Helm remains a later enhancement candidate if modernized

---

### Decision (P03-D02): environment model = namespace-based dev/prod overlays

- **Decision:** Model `dev` and `prod` through separate namespace-based Kustomize overlays.
- **Context / problem:** The proven raw-manifest baseline was still a single-environment path. Phase 03 needed separate deployment inputs for `dev` and `prod`.
- **Options considered:**
  - duplicate the raw manifests per environment
  - keep manual namespace creation and patching outside the workflow
  - add Kustomize overlays per environment ✅
- **Chosen option + why:** Kustomize overlays reuse the already proven base, add environment-specific namespaces, and patch the storefront Service without duplicating the whole manifest set.
- **Verification / evidence:**
  - `kubectl kustomize deploy/kubernetes/kustomize/overlays/dev`
  - `kubectl kustomize deploy/kubernetes/kustomize/overlays/prod`
  - manual dev namespace recreation via:
    - `kubectl delete namespace sock-shop-dev`
    - `kubectl apply -k deploy/kubernetes/kustomize/overlays/dev`
- **Consequences / follow-ups:**
  - namespace creation is codified
  - the workflow can reuse the overlays directly
  - the storefront Service no longer depends on the fixed NodePort path in the CI/CD baseline

---

### Decision (P03-D03): CI/CD runtime = GitHub Actions + GitHub-hosted runners + kind

- **Decision:** Use GitHub Actions with GitHub-hosted runners and **`kind` (Kubernetes in Docker)** to spin up an ephemeral "dummy" cluster for the CI/CD baseline.
- **Context / problem:** The phase needed a working CI/CD baseline before moving to the real long-lived Proxmox target.
- **Options considered:**
  - move directly to Proxmox
  - use a self-hosted runner on the local machine
  - use GitHub-hosted runners with `kind` ✅
- **Chosen option + why:** 
  - This repository is a public fork, so attaching a self-hosted runner to a personal machine would add unnecessary risk. Relying on GitHub-hosted runners provides a fresh, isolated VM for every run. 
  - Inside this runner, `kind` instantly creates a throwaway cluster that lives entirely in memory, giving us a safe, CI-friendly sandbox to prove our delivery mechanics without depending on the final, persistent infrastructure yet.

  > [!NOTE] **🧩 Info box — kind (The "Dummy" Cluster)**
  > `kind` creates a temporary Kubernetes cluster inside Docker containers. It acts as our **ephemeral "dummy" cluster**, living entirely inside the GitHub Actions runner for just a few minutes. It has no persistent storage and is destroyed automatically when the job finishes. It is used here purely as a clean, isolated **smoke-test target** to prove the deployment logic works before transitioning to the real Proxmox VM.

- **Verification / evidence:**
  - workflow file added at:
    - `.github/workflows/phase-03-delivery.yaml`
  - successful workflow jobs:
    - overlay validation
    - image build/push
    - `dev` smoke deployment
    - `prod` smoke deployment after approval
- **Consequences / follow-ups:**
  - the delivery logic is proven now
  - later retargeting to Proxmox mainly requires swapping the temporary cluster setup for the real kubeconfig / cluster-access path

### Decision (P03-D04): production gate = GitHub Environment with required reviewer

- **Decision:** Use GitHub Environments with required reviewers to gate the `prod` smoke deployment.
- **Context / problem:** The project requirements call for environment separation, and approval-gated production deployment is explicitly encouraged when CI/CD is used.
- **Options considered:**
  - no gate, fully automatic production path
  - branch restriction only
  - GitHub Environment gate with required reviewer ✅
- **Chosen option + why:** The GitHub Environment mechanism is the cleanest native way to prove a real approval gate in this repository.
- **Verification / evidence:**
  - `dev` and `prod` environments created in repository settings
  - `prod` configured with required reviewer
  - workflow paused before `deploy-prod-smoke`
  - `prod` smoke deployment proceeded only after approval
- **Consequences / follow-ups:**
  - `dev` remains the fast smoke path
  - `prod` demonstrates controlled promotion
  - the repository owner is used as reviewer here only because this is a solo repository

---

### Decision (P03-D05): workflow image scope = keep `healthcheck`, defer `openapi`

- **Decision:** Exclude `openapi` from the Phase 03 image-build matrix and keep `healthcheck` as the repo-owned support image target for this phase.
- **Context / problem:** The first workflow run failed in the `openapi` image build job.
- **Options considered:**
  - block the whole phase until `openapi` is modernized
  - exclude `openapi` for now and keep the deliverable baseline moving ✅
- **Chosen option + why:** `openapi` is a legacy auxiliary build/test target, not part of the main storefront deployment path being proven here. Keeping `healthcheck` still proves repository-local image build and GHCR publishing.
- **Verification / evidence:**
  - first workflow failure at `npm install`
  - `openapi` uses:
    - Node 6
    - npm 3
    - legacy Docker base image
  - `healthcheck` build/push succeeded
- **Consequences / follow-ups:**
  - `openapi` is explicitly deferred
  - later follow-up may modernize or reintroduce it
  - the Phase 03 baseline remains focused on the main delivery path

---

## Deferred follow-ups recorded by this phase

- Modernize or decide the future of `openapi`
- Update deprecated Kubernetes node selector label:
  - `beta.kubernetes.io/os` → `kubernetes.io/os`
- Harden GitHub Actions later:
  - tighten allowed actions
  - pin third-party actions to full SHAs
  - add workflow protection such as CODEOWNERS once the pipeline is stable