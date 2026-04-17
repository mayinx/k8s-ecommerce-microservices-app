# 🧭 Runbook (TL;DR) — Phase 03 (CI/CD Baseline): GitHub Actions smoke delivery for dev/prod

> ## 👤 About
> This runbook is the short, command-first version of the Phase 03 CI/CD baseline work.  
> It is meant as a quick rerun reference without the long-form diary.  
> For the full narrative log (including rationale, decisions, observations, and evidence context), see: **[03-ci-cd-baseline/IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For the setup and repository/platform prerequisites of this phase, see: **[03-ci-cd-baseline/SETUP.md](SETUP.md)**.

---

## 📌 Index (top-level)

- [**Goal**](#goal)
- [**Preconditions**](#preconditions)
- [**Step 0 — Re-check the Phase 03 setup surface**](#step-0--re-check-the-phase-03-setup-surface)
- [**Step 1 — Render the dev/prod overlays locally**](#step-1--render-the-devprod-overlays-locally)
- [**Step 2 — Recreate the manual dev baseline locally**](#step-2--recreate-the-manual-dev-baseline-locally)
- [**Step 3 — Run the GitHub Actions workflow**](#step-3--run-the-github-actions-workflow)
- [**Step 4 — Approve the prod smoke deployment**](#step-4--approve-the-prod-smoke-deployment)
- [**Step 5 — Verify the final workflow result**](#step-5--verify-the-final-workflow-result)
- [**Cleanup / rollback notes**](#cleanup--rollback-notes)
- [**Files added / modified in this phase**](#files-added--modified-in-this-phase)

---

## Goal

Re-run the verified Phase 03 baseline so that:

- the Kustomize overlays still render correctly
- the manual `dev` deployment path still works
- the GitHub Actions workflow still deploys `dev`
- the workflow still pauses before `prod`
- the `prod` smoke deployment still succeeds after approval

---

## Preconditions

- Phase 03 setup is complete
- `SETUP.md` conditions are satisfied
- The repository contains:
  - `.github/workflows/phase-03-delivery.yaml`
  - `deploy/kubernetes/manifests/kustomization.yaml`
  - `deploy/kubernetes/kustomize/overlays/dev/`
  - `deploy/kubernetes/kustomize/overlays/prod/`
- GitHub environments exist:
  - `dev`
  - `prod`
- `prod` uses required reviewers
- local validation tools are available if local checks are used:
  - `kubectl`
  - Docker

---

## Step 0 — Re-check the Phase 03 setup surface

**Rationale:** Confirm the repository/platform setup is still in place before rerunning the delivery path.

~~~bash
# Verify the workflow file exists
test -f .github/workflows/phase-03-delivery.yaml && echo "workflow present"

# Verify the overlay entrypoints exist
test -f deploy/kubernetes/manifests/kustomization.yaml && echo "base present"
test -f deploy/kubernetes/kustomize/overlays/dev/kustomization.yml && echo "dev overlay present"
test -f deploy/kubernetes/kustomize/overlays/prod/kustomization.yml && echo "prod overlay present"
~~~

Expected result:

- all required files are present

---

## Step 1 — Render the dev/prod overlays locally

**Rationale:** Confirm the deployment definitions still render before rerunning the full workflow.

Primary commands:

~~~bash
# Render both overlays and write the results to temp files
# runs: kubectl kustomize deploy/kubernetes/kustomize/overlays/dev > /tmp/dev-rendered.yaml && kubectl kustomize deploy/kubernetes/kustomize/overlays/prod > /tmp/prod-rendered.yaml
make p03-render-overlays
~~~

Raw commands:

~~~bash
# Render the dev overlay
kubectl kustomize deploy/kubernetes/kustomize/overlays/dev > /tmp/dev-rendered.yaml

# Render the prod overlay
kubectl kustomize deploy/kubernetes/kustomize/overlays/prod > /tmp/prod-rendered.yaml
~~~

Expected result:

- both overlays render without error

---

## Step 2 — Recreate the manual dev baseline locally

**Rationale:** Re-confirm the local manual baseline before relying on the workflow path.

Primary commands:

~~~bash
# Delete and recreate the dev namespace from the overlay
# runs: kubectl delete namespace sock-shop-dev && kubectl apply -k deploy/kubernetes/kustomize/overlays/dev
make p03-dev-recreate

# Show the resulting resources
# runs: kubectl get deploy,pods,svc -n sock-shop-dev -o wide
make p03-dev-status

# Check the key rollouts
# runs: kubectl rollout status deployment/front-end -n sock-shop-dev --timeout=180s && kubectl rollout status deployment/catalogue -n sock-shop-dev --timeout=180s && kubectl rollout status deployment/payment -n sock-shop-dev --timeout=180s && kubectl rollout status deployment/user -n sock-shop-dev --timeout=180s
make p03-dev-rollouts
~~~

Raw commands:

~~~bash
# Delete and recreate the dev namespace
kubectl delete namespace sock-shop-dev
kubectl apply -k deploy/kubernetes/kustomize/overlays/dev

# Inspect the recreated resources
kubectl get deploy,pods,svc -n sock-shop-dev -o wide

# Check the key rollouts
kubectl rollout status deployment/front-end -n sock-shop-dev --timeout=180s
kubectl rollout status deployment/catalogue -n sock-shop-dev --timeout=180s
kubectl rollout status deployment/payment -n sock-shop-dev --timeout=180s
kubectl rollout status deployment/user -n sock-shop-dev --timeout=180s
~~~

Expected result:

- the dev namespace is recreated by the overlay
- the key services converge successfully

---

## Step 3 — Run the GitHub Actions workflow

**Rationale:** Re-run the proven Phase 03 delivery workflow.

Use one of these two paths.

### Manual GitHub UI path

- Go to: `Repository -> Actions -> phase-03-delivery`
- Click: **Run workflow**
- Run it from:
  - `master`

### Push-driven path

~~~bash
git push origin master
~~~

Expected result:

- `validate-overlays` succeeds
- `build-push-support-images` succeeds
- `deploy-dev-smoke` succeeds
- the workflow pauses before `deploy-prod-smoke`

---

## Step 4 — Approve the prod smoke deployment

**Rationale:** The Phase 03 proof is only complete if the production gate is exercised successfully.

In GitHub Actions:

- open the waiting workflow run
- review the `prod` deployment gate
- approve the deployment

Expected result:

- `deploy-prod-smoke` starts only after approval
- the `prod` smoke deployment succeeds

---

## Step 5 — Verify the final workflow result

**Rationale:** Confirm that the workflow proves the full intended delivery chain.

Check in GitHub Actions that the run shows:

- overlay validation succeeded
- `healthcheck` image build/push succeeded
- `dev` smoke deployment succeeded
- `prod` approval was required
- `prod` smoke deployment succeeded after approval

---

## Cleanup / rollback notes

- the workflow should remain configured so that:
  - `dev` runs on the normal workflow path
  - `prod` runs only on `master`
  - `prod` still requires approval
- `openapi` remains excluded for now
- local `sock-shop-dev` resources can be removed with:

~~~bash
kubectl delete namespace sock-shop-dev
~~~

---

## Files added / modified in this phase

### Files added in this phase

- `.github/workflows/phase-03-delivery.yaml`
- `deploy/kubernetes/manifests/kustomization.yaml`
- `deploy/kubernetes/kustomize/overlays/dev/kustomization.yml`
- `deploy/kubernetes/kustomize/overlays/dev/namespace.yaml`
- `deploy/kubernetes/kustomize/overlays/dev/patches/front-end-svc-clusterip.yaml`
- `deploy/kubernetes/kustomize/overlays/prod/kustomization.yml`
- `deploy/kubernetes/kustomize/overlays/prod/namespace.yaml`
- `deploy/kubernetes/kustomize/overlays/prod/patches/front-end-svc-clusterip.yaml`
- `project-docs/03-ci-cd-baseline/SETUP.md`
- `project-docs/03-ci-cd-baseline/IMPLEMENTATION.md`
- `project-docs/03-ci-cd-baseline/RUNBOOK.md`
- `project-docs/03-ci-cd-baseline/DECISIONS.md`
- `project-docs/03-ci-cd-baseline/evidence/...`

### Files modified in this phase

- `Makefile`
- `README.md`
- `project-docs/DECISIONS.md`
- `project-docs/INDEX.md`

### Files removed in this phase

- none