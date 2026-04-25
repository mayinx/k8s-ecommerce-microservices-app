# Project Documentation Index

Documentation is iterative and phase-aligned: baseline notes first, then milestone implementation notes, setup guides when needed, runbooks, and decision logs.

## Cross-phase docs
- **[Project roadmap / planning](./ROADMAP.md)**
- **[Project-wide decision summary](./DECISIONS.md)**
- **[Project Debug Log](./DEBUG-LOG.md)**  

## Phase 00: Compose + repo baseline (local poke-around + repo mapping)
- **[Phase 00 — Implementation Log](./00-compose-baseline/IMPLEMENTATION.md)**
- **[Phase 00 — Runbook (TL;DR)](./00-compose-baseline/RUNBOOK.md)**

## Phase 01: Local k3s cluster baseline (port-based Sock Shop deploy, conflict-free)
- **[Phase 01 — Implementation Log](./01-nodeport-baseline/IMPLEMENTATION.md)**
- **[Phase 01 — Runbook (TL;DR)](./01-nodeport-baseline/RUNBOOK.md)**

---

## Phase 02: Ingress baseline (host-based Traefik routing to storefront + rollback)
- [Phase 02 — Implementation Log](./02-ingress-baseline/IMPLEMENTATION.md)
- [Phase 02 — Runbook (TL;DR)](./02-ingress-baseline/RUNBOOK.md)

---

## Phase 03: CI/CD baseline (GitHub Actions delivery smoke path for dev/prod)
- [Phase 03 — Setup Guide](./03-ci-cd-baseline/SETUP.md)
- [Phase 03 — Implementation Log](./03-ci-cd-baseline/IMPLEMENTATION.md)
- [Phase 03 — Runbook (TL;DR)](./03-ci-cd-baseline/RUNBOOK.md)
- [Phase 03 — Decision Log](./03-ci-cd-baseline/DECISIONS.md)

---

## Phase 04 Proxmox VM Baseline (Generic Ubuntu VM Template, smoke VM, and workload-ready VM template)
- [Phase 04 — Setup Guide](./04-proxmox-vm-baseline/SETUP.md)
- [Phase 04 — Discovery / target audit](./04-proxmox-vm-baseline/DISCOVERY.md)
- [Phase 04 — Implementation Log](./04-proxmox-vm-baseline/IMPLEMENTATION.md)
- [Phase 04 — Runbook (TL;DR)](./04-proxmox-vm-baseline/RUNBOOK.md)
- [Phase 04 — Decision Log](./04-proxmox-vm-baseline/DECISIONS.md)

---

## Phase 05 — Proxmox Target Delivery

### Core phase documents
- **[Phase 05 — Setup Guide](./05-proxmox-target-delivery/SETUP.md)** 
- **[Phase 05 — Main Implementation Log](./05-proxmox-target-delivery/IMPLEMENTATION.md)** 
- **[Phase 05 — Runbook (TL;DR)](./05-proxmox-target-delivery/RUNBOOK.md)** 
- **[Phase 05 — Decision Log](./05-proxmox-target-delivery/DECISIONS.md)** 

### Subphase implementation guides
- **[P05-A — Target VM bootstrap and first cluster setup](./05-proxmox-target-delivery/implementation/PHASE-05-A.md)**
- **[P05-B — First application deployment, runtime compatibility fix, and initial target-side proof](./05-proxmox-target-delivery/implementation/PHASE-05-B.md)**
- **[P05-C — Environment modeling, ingress routing, and private tailnet access](./05-proxmox-target-delivery/implementation/PHASE-05-C.md)**
- **[P05-D — Public Cloudflare exposure and CI/CD workflow retargeting](./05-proxmox-target-delivery/implementation/PHASE-05-D.md)**

## Phase 06 Observability & Health (kube-prometheus-stack monitoring baseline on the Proxmox-backed target cluster)
- **[Phase 06 — Implementation Log](./06-observability/IMPLEMENTATION.md)**
- **[Phase 06 — Runbook (TL;DR)](./06-observability/RUNBOOK.md)**
- **[Phase 06 — Decision Log](./06-observability/DECISIONS.md)**

## Future phases (placeholders; added when we reach them)
- Phase 07: Security baseline & testing
- Phase 08: Infrastructure as Code (Terraform)
- Phase 09: DR / rollback baseline

## Optional extension track (later / if time allows)
- Testing track:
  - pipeline smoke verification
  - Playwright storefront smoke / E2E coverage
- Custom Python microservice:
  - Order Guard / Policy Service
- GitOps layer:
  - Argo CD or similar
- Secret-management extension:
  - external secrets integration
- Optional AWS target:
  - Terraform-driven secondary deployment track
