# Project Documentation Index

Documentation is iterative and phase-aligned: baseline notes first, then milestone implementation notes, setup guides when needed, runbooks, and decision logs.

## Cross-phase docs
- **[Project roadmap / planning](./ROADMAP.md)**
- **[Project-wide decision summary](./DECISIONS.md)**
- **[Project Debug Log](./DEBUG-LOG.md)**  
- **[Final Project Presentation](./final-presentation/%5B2026-05-05%5D-Sock-Shop-Production-Grade-DevOps-Delivery-Path.pd)**

---

## Phase 00: Docker Compose + Repo Baseline (local poke-around + repo mapping)
- **[Phase 00 — Implementation Log](./00-compose-baseline/IMPLEMENTATION.md)**
- **[Phase 00 — Runbook (TL;DR)](./00-compose-baseline/RUNBOOK.md)**

---

## Phase 01 — Port-based Kubernetes baseline (local K3s NodePort Sock Shop deploy)
- **[Phase 01 — Implementation Log](./01-k8s-nodeport-baseline/IMPLEMENTATION.md)**
- **[Phase 01 — Runbook (TL;DR)](./01-k8s-nodeport-baseline/RUNBOOK.md)**

---

## Phase 02 — Host-based Kubernetes ingress baseline (local K3s Traefik routing to storefront)
- **[Phase 02 — Implementation Log](./02-k8s-ingress-baseline/IMPLEMENTATION.md)**
- **[Phase 02 — Runbook (TL;DR)](./02-k8s-ingress-baseline/RUNBOOK.md)**

---

## Phase 03: CI/CD baseline (GitHub Actions delivery smoke path for dev/prod)
- **[Phase 03 — Setup Guide](./03-ci-cd-baseline/SETUP.md)**
- **[Phase 03 — Implementation Log](./03-ci-cd-baseline/IMPLEMENTATION.md)**
- **[Phase 03 — Runbook (TL;DR)](./03-ci-cd-baseline/RUNBOOK.md)**
- **[Phase 03 — Decision Log](./03-ci-cd-baseline/DECISIONS.md)**

---

## Phase 04 Proxmox VM Baseline (Generic Ubuntu VM Template, smoke VM, and workload-ready VM template)
- **[Phase 04 — Setup Guide](./04-proxmox-vm-baseline/SETUP.md)**
- **[Phase 04 — Discovery / target audit](./04-proxmox-vm-baseline/DISCOVERY.md)**
- **[Phase 04 — Implementation Log](./04-proxmox-vm-baseline/IMPLEMENTATION.md)**
- **[Phase 04 — Runbook (TL;DR)](./04-proxmox-vm-baseline/RUNBOOK.md)**
- **[Phase 04 — Decision Log](./04-proxmox-vm-baseline/DECISIONS.md)**

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

---

## Phase 06 Observability & Health (kube-prometheus-stack monitoring baseline on the Proxmox-backed target cluster)
- **[Phase 06 — Implementation Log](./06-observability/IMPLEMENTATION.md)**
- **[Phase 06 — Runbook (TL;DR)](./06-observability/RUNBOOK.md)**
- **[Phase 06 — Decision Log](./06-observability/DECISIONS.md)**

---

## Phase 07 Security Testing (Helper Refactors, Deterministic Tests, Trivy Baseline, Dependabot, PR Gate, Live Smoke Tests Workflow, Branch Protection)
- **[Phase 07 — Setup Guide](./07-security-testing/SETUP.md)**
- **[Phase 07 — Main Implementation Log](./07-security-testing/IMPLEMENTATION.md)**
- **[Phase 07 — Runbook (TL;DR)](./07-security-testing/RUNBOOK.md)**
- **[Phase 07 — Decision Log](./07-security-testing/DECISIONS.md)**

### Subphase implementation guides
- **[P07-A — Scope, Assessment & Owned Helper Refactors](./07-security-testing/implementation/PHASE-07-A.md)**
- **[P07-B — Python Contract Guard, Live API Smoke Tests & Playwright Browser Smoke Tests](./07-security-testing/implementation/PHASE-07-B.md)**
- **[P07-C — Trivy Security Baseline, Healthcheck Image Remediation & Dependabot](./07-security-testing/implementation/PHASE-07-C.md)**
- **[P07-D — Stable PR Gate, Live CI Validation & Branch Protection](./07-security-testing/implementation/PHASE-07-D.md)**

---

## Phase 08 — Proxmox IaC Baseline (Terraform smoke-VM provisioning proof)

- **[Phase 08 — Implementation Log](./08-proxmox-iac/IMPLEMENTATION.md)**
- **[Phase 08 — Runbook (TL;DR)](./08-proxmox-iac/RUNBOOK.md)**
- **[Phase 08 — Decision Log](./08-proxmox-iac/DECISIONS.md)**

---

## Phase 09 — Disaster Recovery & Rollback (Backup baseline, restore validation, recovery proof, rollback readiness)

- **[Phase 09 — Implementation Log](./09-dr-rollback/IMPLEMENTATION.md)**
- **[Phase 09 — Runbook (TL;DR)](./09-dr-rollback/RUNBOOK.md)**
- **[Phase 09 — Decision Log](./09-dr-rollback/DECISIONS.md)**

---

## Later hardening / optional future phases
- Broader Terraform coverage for target VM recreation and bootstrap steps
- Full restore drill in a disposable namespace or throwaway cluster
- GitOps layer:
  - Argo CD or similar
- Secret-management extension:
  - external secrets integration
- Optional AWS target:
  - Terraform-driven secondary deployment track

---

## Optional extension track (later / if time allows)
- Testing track:
  - extend the existing deterministic PR gate where useful
  - expand Playwright storefront smoke checks into deeper E2E coverage if needed
  - check repo owned openapi 
- Custom Python microservice:
  - Order Guard / Policy Service
- GitOps layer:
  - Argo CD or similar
- Secret-management extension:
  - external secrets integration
- Optional AWS target:
  - Terraform-driven secondary deployment track
