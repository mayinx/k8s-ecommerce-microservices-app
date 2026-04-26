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
  - Phase 07 — Security Testing
- Primary next target:
  - Phase 08 — Infrastructure as Code (Terraform)

---

## Planning tiers

### Tier A — Must complete before evaluation
- Target deployment on the primary long-lived environment
  - status: done in Phase 05
- Observability baseline
  - status: done in Phase 06
- Security baseline
  - status: done in Phase 07
- Testing track
  - status: done as first baseline in Phase 07
- IaC for the stable target/bootstrap pieces
  - status: next core phase
- DR / rollback baseline
  - status: still open
- Clean final project documentation
  - status: ongoing

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

## Core Phase Roadmap

### Phase 00 — Compose baseline
- status:
  - done
- purpose:
  - local application baseline and repo reconnaissance
- already proven:
  - compose baseline
  - host-port conflict diagnosis
- docs:
  - [Implementation](./00-compose-baseline/IMPLEMENTATION.md)
  - [Runbook](./00-compose-baseline/RUNBOOK.md)

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

### Phase 07 — Security Testing
- status:
  - done
- purpose:
  - add the first integrated testing, security, dependency-visibility, CI-validation, live-smoke, and branch-protection layer
- already proven:
  - Repo-owned Ruby healthcheck 
    - Refactor into an importable, CLI-testable, unit-testable, and machine-chainable helper
    - Ruby healthcheck tests
  - Repo-owned Bash observability-helper 
    - Refactor behind `main()` and an execution guard for safe sourcing in tests
    - Bash observability-helper tests
  - Python `/catalogue` contract guard with deterministic local tests
  - live Python contract smoke checks for deployed endpoints
  - Playwright browser smoke checks against the live storefront
  - Trivy filesystem scan targets for repo-owned code/config components
  - Trivy vulnerability scan for the repo-owned `healthcheck` image
  - hardened `healthcheck` Dockerfile with focused clean Trivy reruns
  - Dependabot baseline for GitHub Actions and the Playwright npm toolchain
  - deterministic GitHub Actions PR gate
  - separate manual/reusable live-smoke workflow
  - default-branch protection with required deterministic Phase 07 checks
- docs:
  - [Setup](./07-security-testing/SETUP.md)
  - [Implementation](./07-security-testing/IMPLEMENTATION.md)
  - [Decisions](./07-security-testing/DECISIONS.md)
  - [P07-A](./07-security-testing/implementation/PHASE-07-A.md)
  - [P07-B](./07-security-testing/implementation/PHASE-07-B.md)
  - [P07-C](./07-security-testing/implementation/PHASE-07-C.md)
  - [P07-D](./07-security-testing/implementation/PHASE-07-D.md)

### Phase 08 — Infrastructure as Code (Terraform)
- status:
  - core phase still open
- purpose:
  - codify the stable target/bootstrap pieces using the Capstone-recommended IaC tool
- likely work:
  - do *not* rebuild the entire Proxmox VM layer to avoid timeline risk
  - use Terraform (and the Terraform Helm Provider) to manage Kubernetes namespaces
  - codify the Phase 06 monitoring stack installation via Terraform
- Relevance:
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
  - baseline done in Phase 07; deeper coverage is a stretch goal
- purpose:
  - extend the existing validation model only where it adds clear project value
- likely additions:
  - Deeper Playwright user-flow checks if time allows
  - Automatic post-deployment live-smoke reuse after `dev` or `prod` rollout
  - Additional tests for future custom project-owned services
  - Investigate openapi

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
- Relevance:
  - shows service ownership
  - creates a natural place for tests
  - strengthens deployment, networking, and observability stories

### Supply-chain / image-security track
- priority:
  - baseline done in Phase 07; broader hardening remains a follow-up
- likely additions:
  - handle broader Trivy backlog outside the remediated `healthcheck` path
  - optional SBOM generation
  - later optional signing / verification
- Relevance:
  - improves the project’s security and modern-delivery signal

### GitOps extension
- priority:
  - post-bootcamp portfolio extension
- likely additions:
  - Argo CD or similar
- Relevance:
  - strong modern delivery signal
- note:
  - do this only after the core target deployment path is stable

### Secret-management extension
- priority:
  - post-bootcamp portfolio extension
- likely additions:
  - external secret-management integration
- Relevance:
  - strengthens the operational/security story

### Optional AWS target
- priority:
  - post-bootcamp portfolio extension
- purpose:
  - add AWS relevance without replacing the primary Proxmox-first path
- likely shape:
  - secondary Terraform-driven deployment track
- Relevance:
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
- Phase 07 broader Trivy findings outside the remediated `healthcheck` path remain a later hardening backlog
- Dependabot-generated PRs should be reviewed through the protected pull-request path and merged or deferred intentionally
- The Phase 07 live-smoke workflow can later be called automatically after deployment workflows once that behavior is desired
- Playwright coverage can later be expanded beyond the current smoke-level storefront checks
- GitHub Actions runtime deprecation warnings remain a later workflow-maintenance cleanup item  

---

## Open planning questions

- Which Terraform scope is the strongest low-risk fit for the remaining timeline:
  - codify namespaces and selected Kubernetes resources
  - codify the monitoring baseline
  - codify only stable target/bootstrap pieces
- Should the Phase 07 live-smoke workflow be called automatically after deployment workflows, or remain manually triggered for now?
- Which broader Trivy findings outside the remediated `healthcheck` path should be prioritized first?
- Should monitoring remain private-only through the next phase, or is there a later justified case for stronger controlled exposure?
- Should the custom Python microservice be implemented before or after the first IaC / DR baseline?
- Is an AWS extension realistic before evaluation, or better kept for post-evaluation portfolio work?
- Which later extension gives the strongest hiring signal per hour of effort:
  - Argo CD
  - Python microservice
  - stronger E2E coverage
  - AWS target

---

