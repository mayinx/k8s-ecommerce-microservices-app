# Project Roadmap

> ## 👤 About
> This document is the internal project-planning overview for the Sock Shop DevOps project.  
> It captures the bird’s-eye phase plan, major next steps, deferred follow-ups, optional extension tracks, and open planning questions.  
> It is meant as the working planning reference for future implementation discussions and prioritization.  
> For the navigable project documentation index, see: **[project-docs/INDEX.md](INDEX.md)**.  
> For the summarized project-wide decision record, see: **[project-docs/DECISIONS.md](DECISIONS.md)**.

---

## 📌 Index (top-level)

- [Current position](#current-position)
- [Planning tiers](#planning-tiers)
- [Core phase roadmap](#core-phase-roadmap)
- [Extension tracks](#extension-tracks)
- [Deferred follow-ups already known](#deferred-follow-ups-already-known)
- [Open planning questions](#open-planning-questions)

---

## Current position

- Current proven phase:
  - Phase 04 — Proxmox VM baseline
- Primary next target:
  - Phase 05 — Target deployment on Proxmox + selective Terraform / IaC
- Main current objective:
  - move from the proven Proxmox VM baseline to real application deployment on the target and continue the remaining core DevOps layers cleanly
- Important planning note:
  - the project should preserve room for strong extensions (see below Tier B), but the core path must stay stable first

---

## Planning tiers

### Tier A — Must complete before bootcamp evaluation
- target deployment on the primary long-lived environment
- IaC for that target
- observability baseline
- security baseline
- DR / rollback baseline
- explicit testing track
- clean final project documentation

### Tier B — Strong stretch goals before evaluation, if time allows
- custom Python microservice:
  - Order Guard / Policy Service
- unit tests for the Python service
- Playwright storefront smoke / E2E coverage
- image scanning / SBOM generation
- optional selective image optimization for stronger delivery/security signal

### Tier C — Post-bootcamp portfolio extensions
- GitOps layer (for example Argo CD)
- stronger secret-management integration
- optional AWS target as an additional Terraform-driven deployment track
- recruiter-facing live dashboard / situation-room style proof layer

### Tier D — Optional experimental ideas
- Compose Bridge experiment
- AI/agent sidecar ideas
- broader image-modernization pass
- Helm rehabilitation / modernization

---

## Phase roadmap

### Phase 00 — Compose baseline
- status:
  - done
- purpose:
  - local application baseline and repo reconnaissance
- already proven:
  - compose baseline
  - host-port conflict diagnosis
- docs:
  - [Implementation](./00-compose-repo-baseline/IMPLEMENTATION.md)
  - [Runbook](./00-compose-repo-baseline/RUNBOOK.md)

### Phase 01 — Port-based Kubernetes baseline
- status:
  - done
- purpose:
  - clean local k3s deployment via upstream manifests
- already proven:
  - NodePort storefront access
- docs:
  - [Implementation](./01-nodeport-baseline/IMPLEMENTATION.md)
  - [Runbook](./01-nodeport-baseline/RUNBOOK.md)

### Phase 02 — Host-based ingress baseline
- status:
  - done
- purpose:
  - Traefik ingress path for storefront access
- already proven:
  - `sockshop.local`
  - rollback path
- docs:
  - [Implementation](./02-ingress-baseline/IMPLEMENTATION.md)
  - [Runbook](./02-ingress-baseline/RUNBOOK.md)

### Phase 03 — CI/CD baseline
- status:
  - done
- purpose:
  - prove a real delivery smoke path for `dev` / `prod`
- already proven:
  - GitHub Actions workflow
  - Kustomize overlays
  - GHCR publishing for `healthcheck`
  - automated `dev`
  - approval-gated `prod`
- docs:
  - [Setup](./03-ci-cd-baseline/SETUP.md)
  - [Implementation](./03-ci-cd-baseline/IMPLEMENTATION.md)
  - [Runbook](./03-ci-cd-baseline/RUNBOOK.md)
  - [Decisions](./03-ci-cd-baseline/DECISIONS.md)

### Phase 04 — Proxmox VM baseline
- status:
  - done
- purpose:
  - establish the first reusable Proxmox-backed VM baseline
- already proven:
  - target-host discovery and documentation
  - reusable Ubuntu 24.04 Cloud-Init VM template as `9000`
  - reference smoke VM as `9100`
  - host-side verification
  - guest-side verification
- docs:
  - [Discovery](./04-proxmox-vm-baseline/DISCOVERY.md)
  - [Implementation](./04-proxmox-vm-baseline/IMPLEMENTATION.md)
  - [Runbook](./04-proxmox-vm-baseline/RUNBOOK.md)
  - [Decisions](./04-proxmox-vm-baseline/DECISIONS.md)

### Phase 05 — Target deployment on Proxmox + selective Terraform / IaC
- status:
  - next core phase
- purpose:
  - move from the proven VM baseline to real application deployment on the Proxmox-backed target and codify the stable target/bootstrap pieces that are worth automating now
- likely work:
  - choose the most realistic target-side Kubernetes deployment path
  - deploy Sock Shop on the target
  - codify the stable target/bootstrap pieces where Terraform adds clear value
  - retarget the already proven delivery mechanics toward the real target
- open questions:
  - exact target-cluster shape
  - exact target-cluster access path
  - how much of the current GitHub Actions structure can stay unchanged
  - which target/bootstrap pieces should be codified first in Terraform
  - whether manifest-touching work in this phase should already include the deprecated node selector cleanup

### Phase 06 — Observability
- status:
  - core phase still open
- purpose:
  - add monitoring / visibility
- likely work:
  - Prometheus / Grafana
  - health and service metrics
  - at least one business-facing or operationally meaningful dashboard view
- open questions:
  - what minimum useful dashboards should exist before project evaluation

### Phase 07 — Security hardening
- status:
  - core phase still open
- purpose:
  - add stronger security / workflow hardening
- likely work:
  - scanning
  - workflow hardening
  - secrets-handling improvements
- open questions:
  - what fits the project scope best before evaluation
  - what should be deferred to extension work
  - Tighten repository allowed-actions settings
  - Pin third-party GitHub Actions to full commit SHAs
  - Add workflow protection such as `CODEOWNERS`
  - Re-check `GITHUB_TOKEN` permissions job-by-job  

### Phase 08 — DR / rollback
- status:
  - core phase still open
- purpose:
  - document and prove recovery thinking
- likely work:
  - rollback path
  - redeploy-from-IaC path
  - backup / restore thinking
- open questions:
  - what can be practically demonstrated versus documented

---

## Extension tracks

### Testing track
- priority:
  - strong stretch before evaluation
- purpose:
  - make the delivery path more defensible
- likely additions:
  - pipeline smoke verification
  - Playwright storefront smoke / E2E coverage
  - unit tests for owned components

### Custom Python microservice
- priority:
  - strong stretch before evaluation
- working concept:
  - **Order Guard / Policy Service** (FastAPI)
- intended role:
  - service extension integrated into the existing flow
- candidate API:
  - `POST /policy/check`
- candidate rule types:
  - max quantity
  - restricted countries
  - min/max total
  - suspicious patterns
- expected return:
  - `allow`
  - `block`
  - `review`
  - plus reason
- why it matters:
  - shows service ownership
  - creates a natural place for tests
  - strengthens deployment, networking, and observability stories

### Supply-chain / image-security track
- priority:
  - strong stretch before evaluation
- likely additions:
  - image scanning / SBOM generation
  - later optional signing / verification
- why it matters:
  - improves the project’s security and modern-delivery signal

### GitOps extension
- priority:
  - post-bootcamp portfolio extension
- likely additions:
  - Argo CD or similar
- why it matters:
  - strong modern delivery signal
- note:
  - do this only after the core target deployment path is stable

### Secret-management extension
- priority:
  - post-bootcamp portfolio extension
- likely additions:
  - external secret-management integration
- why it matters:
  - strengthens the operational/security story

### Optional AWS target
- priority:
  - post-bootcamp portfolio extension
- purpose:
  - add AWS relevance without replacing the primary Proxmox-first path
- likely shape:
  - secondary Terraform-driven deployment track
- why it matters:
  - strengthens AWS / SAA alignment
  - adds additional platform signal for job search

---

## Cross-phase backlog

- item:
- item:
- item:

---

## Deferred follow-ups already known

- `openapi` remains excluded from the workflow because it still depends on legacy Node 6 / npm 3
- GitHub Actions runtime warnings around Node.js 20 deprecation still need a later cleanup pass
- Kubernetes manifests still contain the deprecated node selector label `beta.kubernetes.io/os`
- future workflow hardening remains open:
  - restrict allowed actions
  - pin third-party actions to full SHAs
  - add workflow protection such as `CODEOWNERS`
- ...

---

## Open planning questions

- What is the most realistic minimum target-deployment scope for Phase 05?
- Which target/bootstrap pieces should be codified first in Terraform during Phase 05?
- Which test layer gives the strongest value soonest:
  - pipeline smoke checks
  - Playwright
  - service-level tests
- Should the custom Python microservice be implemented before or after the first full observability baseline?
- Is an AWS extension realistic before evaluation, or better kept for post-bootcamp portfolio work?
- Which later extension gives the strongest hiring signal "per hour of effort" ;-) :
  - Argo CD
  - Python microservice
  - stronger testing
  - AWS target
  - ...