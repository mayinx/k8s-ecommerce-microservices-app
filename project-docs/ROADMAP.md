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

- Current implemented phase:
  - Phase 10 — Proxmox Exit Evidence and Migration Readiness
- Primary next target:
  - Phase 11 — AWS Target Migration
- Current strategic constraint:
  - The original Proxmox environment has a fixed remaining lifetime and will no longer be available as a long-lived target.
- Current project direction:
  - Preserve the completed Proxmox/K3s target platform story, then migrate the target architecture to AWS while reusing the proven delivery model where practical.

---
## Planning tiers

### Tier A — Completed core delivery scope

- Target deployment on the primary Proxmox-backed environment
  - status: done in Phase 05
- Observability baseline
  - status: done in Phase 06
- Security baseline
  - status: done in Phase 07
- Testing track
  - status: done as first baseline in Phase 07
- IaC baseline
  - status: done in Phase 08
- DR / rollback baseline
  - status: done in Phase 09
- Final Proxmox exit evidence and migration-readiness capture
  - status: done in Phase 10

### Tier B — Active next migration track

- AWS target migration
  - status: next core phase
- Terraform-based AWS target provisioning
  - status: planned for Phase 11
- K3s target bootstrap on AWS EC2
  - status: planned for Phase 11
- CI/CD retargeting from Proxmox to AWS
  - status: planned for Phase 11
- Public edge continuity through Cloudflare routing
  - status: planned for Phase 11 where practical
- Recovery from Phase 10 / Phase 09 backup artifacts
  - status: planned for Phase 11 where practical

### Tier C — Post-migration hardening

- Remote Terraform state with S3 and DynamoDB locking
- Keyless GitHub Actions authentication to AWS through OIDC
- Optional Amazon ECR migration for repo-owned images
- Broader Terraform coverage for target recreation and bootstrap steps
- Full restore drill in a disposable namespace or throwaway cluster
- Stronger secret-management integration

### Tier D — Portfolio extension tracks

- Deeper Playwright storefront checks beyond the current smoke baseline
- Synthetic monitoring based on the existing live-smoke workflow
- Optional custom Python microservice:
  - Order Guard / Policy Service
- GitOps layer, for example Argo CD
- Optional SBOM generation or signing / verification follow-up
- Recruiter-facing live dashboard / situation-room style proof layer
- Agentic runbook assistant / AI operations helper

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
  - [Implementation](./01-k8s-nodeport-baseline/IMPLEMENTATION.md)
  - [Runbook](./01-k8s-nodeport-baseline/RUNBOOK.md)

### Phase 02 — Host-based ingress baseline
- status:
  - done
- purpose:
  - Traefik ingress path for storefront access
- already proven:
  - `sockshop.local`
  - rollback path
- docs:
  - [Implementation](./02-k8s-ingress-baseline/IMPLEMENTATION.md)
  - [Runbook](./02-k8s-ingress-baseline/RUNBOOK.md)

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
  - done
- purpose:
  - prove a safe Proxmox Infrastructure as Code baseline without importing or modifying the live K3s target VM `9200`
- already proven:
  - isolated Terraform workspace under `infra/terraform/proxmox-smoke-vm/`
  - Proxmox-specific Terraform proof using the `bpg/proxmox` provider
  - disposable smoke VM `9300` cloned from workload-ready template `9010`
  - Proxmox node `sd-178532`, storage `vmdata`, and private VM network model reused from the proven Proxmox baseline
  - Cloud-Init guest initialization for the `ubuntu` user, DNS, gateway, and static smoke-VM IP `10.10.10.30/24`
  - Terraform `init`, `validate`, `plan`, `apply`, Proxmox host-side verification, guest reachability check, and `destroy`
  - live K3s target VM `9200` remained untouched
  - Terraform-related Makefile helpers for repeatable local execution
  - Terraform provider dependency monitoring through Dependabot
  - Trivy scan coverage extended to the Terraform infrastructure path
- docs:
  - [Implementation](./08-proxmox-iac/IMPLEMENTATION.md)
  - [Runbook](./08-proxmox-iac/RUNBOOK.md)
  - [Decisions](./08-proxmox-iac/DECISIONS.md)

### Phase 09 — DR / rollback baseline
- status:
  - done
- purpose:
  - establish a practical disaster-recovery and rollback-readiness baseline for the single-node Proxmox-backed K3s target
- already proven:
  - local DR backup helper under `scripts/dr/`
  - timestamped backup artifacts under gitignored `backups/`
  - Kubernetes namespace-state exports for `sock-shop-dev` and `sock-shop-prod`
  - MongoDB dump attempts for known Sock Shop database pods
  - successful MongoDB-compatible dumps for `carts-db`, `orders-db`, and `user-db`
  - unsupported data-store pods recorded as skipped instead of failing the whole backup run
  - representative `user-db` dump restored and queried in a temporary local MongoDB container
  - safe pod-recovery proof by deleting a `front-end` pod in `sock-shop-dev`
  - Kubernetes recreated the deleted pod through Deployment reconciliation
  - live smoke validation passed after the recovery proof
  - Git-based rollback and Kubernetes emergency rollback paths documented
  - full node/VM recovery documented as rebuild, redeploy, and restore where artifacts are available
- docs:
  - [Implementation](./09-dr-rollback/IMPLEMENTATION.md)
  - [Runbook](./09-dr-rollback/RUNBOOK.md)
  - [Decisions](./09-dr-rollback/DECISIONS.md)

### Phase 10 — Proxmox Exit Evidence and Migration Readiness
- status:
  - done
- purpose:
  - preserve the final proven Proxmox-backed K3s target state before the original environment becomes unavailable
- already proven:
  - final public `dev` and `prod` storefront evidence captured
  - final terminal endpoint verification for both public endpoints
  - final Proxmox UI and host-side VM `9200` evidence captured
  - final Kubernetes target-state snapshot captured
  - final Grafana and Prometheus evidence captured
  - final GitHub Actions CI/CD and live-smoke evidence captured
  - final local DR backup artifacts created for `sock-shop-dev` and `sock-shop-prod`
  - historical Proxmox-era README snapshot archived
  - migration boundary documented before AWS follow-up work starts
- docs:
  - [Implementation](./10-proxmox-exit-evidence/IMPLEMENTATION.md)
  - [Runbook](./10-proxmox-exit-evidence/RUNBOOK.md)
  - [Decisions](./10-proxmox-exit-evidence/DECISIONS.md)
  - [Archived Proxmox-era README](./10-proxmox-exit-evidence/archive/%5B2026-05-06%5D-README-proxmox-phases-00-09.md)

### Phase 11 — AWS Target Migration
- status:
  - next core phase
- purpose:
  - migrate the proven Proxmox/K3s target model to an AWS-backed target before the original Proxmox environment becomes unavailable
- likely work:
  - provision an AWS EC2-based target using Terraform
  - bootstrap K3s on the AWS target
  - preserve private operator / CI access where practical
  - retarget GitHub Actions delivery from Proxmox to AWS
  - restore or reseed application state from existing backup artifacts where practical
  - preserve public `dev` / `prod` entrypoints through updated routing
- intended result:
  - the project remains live after Proxmox decommissioning
  - the existing delivery story evolves into a concrete cloud migration story

---

## Extension tracks

### AWS migration and hardening track
- priority:
  - active next track
- purpose:
  - keep the project live after Proxmox decommissioning and turn the infrastructure change into a cloud migration story
- likely additions:
  - Terraform AWS target provisioning
  - K3s bootstrap on EC2
  - CI/CD retargeting to the AWS-backed cluster
  - later remote Terraform state with S3 and DynamoDB
  - later GitHub Actions OIDC for keyless AWS access
  - optional Amazon ECR integration for repo-owned images
- Relevance:
  - strengthens AWS / SAA alignment
  - demonstrates migration thinking
  - adds cloud-platform signal without discarding the proven Proxmox/K3s work

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

---

## Cross-phase backlog

- Keep the completed Proxmox/K3s path reviewable through archived README, final presentation, Phase 10 evidence, and phase docs.
- Retarget the live platform to AWS before the original Proxmox environment becomes unavailable.
- Preserve the existing delivery model where practical:
  - Kustomize overlays
  - namespace-based `dev` / `prod`
  - GitHub Actions promotion model
  - live smoke validation
  - DR / rollback documentation
- After AWS migration, harden the platform with remote Terraform state, keyless CI/CD, and stronger AWS-native security controls.

---

## Deferred Follow-Ups 

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
- Phase 08 deliberately proves a disposable Proxmox smoke-VM lifecycle only; broader target recreation and bootstrap automation remain later IaC hardening
- Phase 09 deliberately records `session-db` and `catalogue-db` backup gaps as follow-up hardening instead of hiding them as completed work
- A full restore drill should later run against a disposable namespace or throwaway cluster before any production-style restore claim is made
- Phase 10 captures the final Proxmox state, but the original Proxmox target is expected to become unavailable later.
- Phase 11 should prioritize AWS migration before broader polish or optional feature work.
- The archived Proxmox-era README should remain stable as a historical snapshot; later README changes should describe the AWS migration without overwriting the completed Proxmox story.
- Final DR backup artifacts from Phase 10 remain local and should not be committed to Git.

---

## Open planning questions

- What is the safest AWS target shape for the migration timeline:
  - single EC2 instance with K3s
  - later split dev/prod VMs
  - later managed Kubernetes only if cost and complexity are justified
- How much of the Proxmox target bootstrap should Phase 11 automate immediately through Terraform and user data?
- Which access model should be retained or adapted on AWS:
  - Tailscale for private Kubernetes API access
  - Cloudflare Tunnel for public storefront access
  - direct AWS security-group controlled access only where necessary
- Which backup artifacts from Phase 10 should be restored into the AWS target, and which should remain documentation-only proof?
- Should the first AWS migration prioritize public reachability first, or CI/CD retargeting first?
- After the AWS target is stable, which hardening step gives the strongest portfolio value:
  - remote Terraform state with S3 and DynamoDB
  - GitHub OIDC and keyless CI/CD
  - Amazon ECR integration
  - synthetic monitoring
  - full restore drill
  - deeper Playwright coverage
  - Agentic runbook assistant

---

