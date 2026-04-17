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
  - Phase 06 — Observability
- Primary next target:
  - Phase 07 — Security baseline & testing
- Main current objective:
  - strengthen the now observable real target with a defensible security/testing baseline
- Important planning note:
  - the first useful observability baseline is now proven, so the next phases should build on that visibility layer instead of reopening baseline monitoring selection unless a real blocker appears

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

### Phase 05 — Proxmox target delivery
- status:
  - done
- purpose:
  - move from the proven Proxmox VM baseline to a real long-lived target-delivery platform
- already proven:
  - real Proxmox-backed target VM `9200` cloned from workload-ready template `9010`
  - single-node K3s control plane on the target VM
  - source-controlled MongoDB compatibility fix for the target runtime
  - namespace-based `dev` / `prod` target model
  - working Traefik ingress for both environments
  - private tailnet-based operator and CI/CD cluster access
  - public HTTPS exposure through Cloudflare Tunnel
  - dedicated Phase 05 workflow for the real target cluster
  - automated `dev` deployment
  - approval-gated `prod` deployment
- docs:
  - [Setup](./05-proxmox-target-delivery/SETUP.md)
  - [Implementation](./05-proxmox-target-delivery/IMPLEMENTATION.md)
  - [Runbook](./05-proxmox-target-delivery/RUNBOOK.md)
  - [Decisions](./05-proxmox-target-delivery/DECISIONS.md)

### Phase 06 — Observability
- status:
  - done
- purpose:
  - add the first useful monitoring and visibility layer to the real Proxmox-backed target
- already proven:
  - dedicated `monitoring` namespace on the real target cluster
  - maintained Helm-based monitoring baseline through `kube-prometheus-stack`
  - private Grafana access via `kubectl port-forward`
  - private Prometheus access via `kubectl port-forward`
  - namespace-level workload visibility for `sock-shop-prod`
  - healthy core monitoring targets on the Prometheus `/targets` page
- docs:
  - [Implementation](./06-observability/IMPLEMENTATION.md)
  - [Runbook](./06-observability/RUNBOOK.md)
  - [Decisions](./06-observability/DECISIONS.md)

### Phase 07 — Security baseline & testing
- status:
  - core phase still open
- purpose:
  - add stronger security / workflow hardening and satisfy the minimum test requirement
- likely work:
  - Trivy vulnerability scanning in GitHub Actions
  - Dependabot configuration
  - explicit documentation of GitHub Secrets (no hard-coded secrets)
  - implement the smallest defensible unit-test path (Capstone minimum requirement)

### Phase 08 — Infrastructure as Code (Terraform)
- status:
  - core phase still open
- purpose:
  - codify the stable target/bootstrap pieces using the Capstone-recommended IaC tool
- likely work:
  - do *not* rebuild the entire Proxmox VM layer to avoid timeline risk
  - use Terraform (and the Terraform Helm Provider) to manage Kubernetes namespaces
  - codify the Phase 06 monitoring stack installation via Terraform
- why it matters:
  - safely satisfies the IaC requirement while demonstrating senior-level add-on management.

### Phase 09 — DR / rollback baseline
- status:
  - core phase still open
- purpose:
  - document and prove recovery thinking (Capstone requirement)
- likely work:
  - demonstrate how to roll back a deployment to a previous version
  - outline database backup and persistent-storage strategies
  - document the redeploy-from-IaC path
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
- Future workflow hardening remains open:
  - restrict allowed actions
  - pin third-party actions to full SHAs
  - add workflow protection such as `CODEOWNERS`
- The guest-session storefront persistence bug remains tracked as an upstream application issue and is currently out of scope for infrastructure phases
- The current Cloudflare edge path still hands traffic from `cloudflared` to Traefik over HTTP on the local origin side; later hardening may add end-to-end TLS via cert-manager or an equivalent origin-side certificate path
- The first observability rollout still defers:
  - Alertmanager and alert-routing
  - longer Prometheus retention
  - persistent storage for monitoring data
  - broader project-wide secret management
  - any public monitoring ingress or broader monitoring exposure

---

## Open planning questions

- Which Security / Testing combination gives the strongest signal soonest:
  - Trivy in CI
  - Dependabot
  - policy / secret handling improvements
  - pipeline smoke checks
  - Playwright
  - service-level tests
- Which Terraform scope is the strongest low-risk fit for the remaining timeline:
  - codify namespaces and selected Kubernetes resources
  - codify the monitoring baseline
  - codify only stable target/bootstrap pieces
- Should monitoring remain private-only through the next phase, or is there a later justified case for stronger controlled exposure?
- Should the custom Python microservice be implemented before or after the first defensible security/testing baseline?
- Is an AWS extension realistic before evaluation, or better kept for post-bootcamp portfolio work?
- Which later extension gives the strongest hiring signal per hour of effort:
  - Argo CD
  - Python microservice
  - stronger testing
  - AWS target

---

