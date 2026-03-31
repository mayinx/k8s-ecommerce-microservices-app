# Sock Shop — Production-like DevOps Delivery Path

This repository uses the Sock Shop microservices application as the base for a production-like DevOps project.

The goal is not just to run the application once, but to build a **reproducible, phase-based delivery path** with evidence-grade documentation that gradually proves the core capabilities expected from a modern DevOps project:

- containerized application delivery
- Kubernetes deployment
- CI/CD
- environment separation
- observability
- security measures
- disaster-recovery thinking
- and infrastructure-oriented deployment evolution toward a long-lived target environment

The project is intentionally implemented in phases so that each new capability builds on an already proven baseline.

## Target Scope

- Kubernetes deployment (k3s locally → Proxmox target)
- CI/CD (build/test/push/deploy with gated prod later)
- IaC (Terraform planned for Proxmox)
- Observability (Prometheus/Grafana planned)
- DevSecOps controls (>= 3 measures planned)
- DR / rollback approach (planned)
- Documentation: phase logs + runbooks + decisions + ADRs

## What this repository already demonstrates

This repository demonstrates an iterative DevOps delivery path built around Sock Shop, including:

- Docker-based application execution
- Kubernetes deployment via proven raw manifests
- environment-specific deployment layering with Kustomize
- GitHub Actions CI/CD
- GHCR image publishing
- approval-gated promotion flow
- evidence-oriented technical documentation
- a delivery path that can later be retargeted to a long-lived infrastructure platform

Current proven highlights include:

- clean local Kubernetes baseline
- host-based local ingress baseline
- namespace-based `dev` / `prod` Kustomize overlays
- GitHub Actions CI/CD smoke workflow
- GHCR publishing for the repo-owned `healthcheck` image
- automated `dev` smoke deployment
- approval-gated `prod` smoke deployment

## Architecture direction

The current architecture direction is:

- **application:** Sock Shop microservices
- **local baseline runtime:** Docker Compose and local k3s
- **Kubernetes deploy input:** raw manifests with environment overlays
- **CI/CD platform:** GitHub Actions
- **container registry:** GHCR
- **temporary CI/CD smoke target:** `kind`
- **later long-lived target:** Proxmox-based environment
- **later planned layers:** monitoring, security hardening, DR, IaC-driven target deployment

This means the project is already proving the delivery mechanics now, while remaining open for the next infrastructure and operations layers.

## Documentation (start here)

- **Project docs index:** [project-docs/INDEX.md](project-docs/INDEX.md)

Project documentation is organized by phase under:

- `project-docs/<phase-folder>/`

Depending on the phase, a folder may contain:

- `SETUP.md`
- `IMPLEMENTATION.md`
- `RUNBOOK.md`
- `DECISIONS.md`
- `evidence/`

### Current phase docs
- Phase 03 setup:
  - [project-docs/03-ci-cd-baseline/SETUP.md](project-docs/03-ci-cd-baseline/SETUP.md)
- Phase 03 implementation log:
  - [project-docs/03-ci-cd-baseline/IMPLEMENTATION.md](project-docs/03-ci-cd-baseline/IMPLEMENTATION.md)
- Phase 03 runbook:
  - [project-docs/03-ci-cd-baseline/RUNBOOK.md](project-docs/03-ci-cd-baseline/RUNBOOK.md)
- Phase 03 decisions:
  - [project-docs/03-ci-cd-baseline/DECISIONS.md](project-docs/03-ci-cd-baseline/DECISIONS.md)

### Cross-phase docs

- Summarized project decisions:
  - [project-docs/DECISIONS.md](project-docs/DECISIONS.md)
- Project roadmap / planning:
  - [project-docs/ROADMAP.md](project-docs/ROADMAP.md)
- Architecture Decision Records (ADRs):
  - [adr/](adr/)

## Architecture Decision Records (ADRs)

Project-wide standards and long-lived decisions live in:

- [adr/](adr/)

**Current ADRs (source of truth):**
- ADR-0001 — Git conventions (workflow, branching, commit messages): [adr/[2026-03-17] ADR-0001 -- Git-Conventions.md](adr/%5B2026-03-17%5D%20ADR-0001%20--%20Git-Conventions.md)
- ADR-0002 — Documentation system and locations: [adr/[2026-03-18] ADR-0002 -- Docs-System.md](adr/%5B2026-03-18%5D%20ADR-0002%20--%20Docs-System.md)

## Current verified scope

The repository currently contains proven work across these phases:

- **Phase 00 — Compose baseline**
  - repository reconnaissance
  - local Docker Compose baseline
  - host-port conflict diagnosis and workaround
  - docs:
    - [Implementation](project-docs/00-compose-repo-baseline/IMPLEMENTATION.md)
    - [Runbook](project-docs/00-compose-repo-baseline/RUNBOOK.md)  

- **Phase 01 — Port-based Kubernetes baseline**
  - clean local k3s deployment via upstream manifests
  - storefront reachable via NodePort `30001`
  - docs:  
    - [Implementation](project-docs/01-nodeport-baseline/IMPLEMENTATION.md)
    - [Runbook](project-docs/01-nodeport-baseline/RUNBOOK.md)  

- **Phase 02 — Host-based ingress baseline**
  - local Traefik ingress for `sockshop.local`
  - NodePort retained as fallback
  - docs:  
    - [Implementation](project-docs/02-ingress-baseline/IMPLEMENTATION.md)
    - [Runbook](project-docs/02-ingress-baseline/RUNBOOK.md)  

- **Phase 03 — CI/CD baseline**
  - GitHub Actions delivery workflow
  - Kustomize overlays for `dev` / `prod`
  - GHCR publishing for the repo-owned `healthcheck` image
  - automated `dev` smoke deployment
  - approval-gated `prod` smoke deployment
  - docs:
    - [Setup](project-docs/03-ci-cd-baseline/SETUP.md)
    - [Implementation](project-docs/03-ci-cd-baseline/IMPLEMENTATION.md)
    - [Runbook](project-docs/03-ci-cd-baseline/RUNBOOK.md)
    - [Decisions](project-docs/03-ci-cd-baseline/DECISIONS.md)  

This section is intentionally a moving summary, not the final shape of the project.

## Tech stack

Current or already chosen technology in this project includes:

- Docker
- Kubernetes
- k3s
- Traefik
- Kustomize
- GitHub Actions
- GHCR
- `kind`

Additional planned layers include:

- Terraform
- Prometheus / Grafana
- further DevSecOps controls

Helm is also present in the repository and was evaluated, but deferred for the current CI/CD baseline because the chart path still introduces legacy compatibility friction.
 
## Evidence

Evidence is captured phase-by-phase under:

- `project-docs/<phase-folder>/evidence/`

For the current CI/CD baseline, key workflow evidence lives under:

- `project-docs/03-ci-cd-baseline/evidence/gh/`

The full evidence index for each phase is documented inside the corresponding `IMPLEMENTATION.md`, for example:

- [project-docs/03-ci-cd-baseline/IMPLEMENTATION.md](project-docs/03-ci-cd-baseline/IMPLEMENTATION.md)

## Current notable decisions

- Helm was evaluated but deferred for the current CI/CD baseline because the chart path still depends on legacy incompatible API usage.
- The CI/CD baseline uses GitHub-hosted runners and `kind`, not a self-hosted runner on a personal machine.
- `openapi` is excluded for now because it is a legacy auxiliary build target and not required for proving the main delivery path.
- The project remains phase-based so later infrastructure retargeting and hardening can build on already proven delivery mechanics.

## Repository structure (high level)

- `.github/workflows/` — workflow definitions
- `adr/` — Architecture Decision Records
- `project-docs/` — phase documentation, evidence, and decisions
- `deploy/` — upstream deployment assets (Compose, Kubernetes manifests, Helm chart, related deployment material)

## What comes next

This README is intentionally kept open for the next implementation phases.

### Core phases still to complete
- target deployment on the primary long-lived environment (Proxmox)
- IaC for that target environment (Terraform)
- monitoring / observability
- security hardening
- disaster recovery / rollback strategy

### Strong stretch goals before evaluation, if time allows
- **Testing track:**
  - pipeline smoke verification
  - browser-level Playwright smoke / E2E coverage
- **Custom Python microservice:**
  - Order Guard / Policy Service
  - FastAPI-based service extension with its own tests and deployment path
- **Stronger image / supply-chain checks:**
  - image scanning / SBOM generation
  - optional later signing / verification

### Later portfolio extensions
- GitOps layer (for example Argo CD)
- stronger secret-management integration
- Optional AWS target as an additional Terraform-driven deployment track
- Recruiter-facing live dashboard / situation-room style proof layer

For the fuller internal planning view, see:
- [project-docs/ROADMAP.md](project-docs/ROADMAP.md)

## License / upstream
This is a fork-based project built for training/capstone purposes. Upstream origins and licenses apply where relevant.

-----------------

# Upstream README

[![Build Status](https://travis-ci.org/microservices-demo/microservices-demo.svg?branch=master)](https://travis-ci.org/microservices-demo/microservices-demo)

Sock Shop : A Microservice Demo Application

The application is the user-facing part of an online shop that sells socks. It is intended to aid the demonstration and testing of microservice and cloud native technologies.

It is built using [Spring Boot](http://projects.spring.io/spring-boot/), [Go kit](http://gokit.io) and [Node.js](https://nodejs.org/) and is packaged in Docker containers.

You can read more about the [application design](./internal-docs/design.md).

## Deployment Platforms

The [deploy folder](./deploy/) contains scripts and instructions to provision the application onto your favourite platform. 

Please let us know if there is a platform that you would like to see supported.

## Bugs, Feature Requests and Contributing

We'd love to see community contributions. We like to keep it simple and use Github issues to track bugs and feature requests and pull requests to manage contributions. See the [contribution information](.github/CONTRIBUTING.md) for more information.

## Screenshot

![Sock Shop frontend](https://github.com/microservices-demo/microservices-demo.github.io/raw/master/assets/sockshop-frontend.png)

## Visualizing the application

Use [Weave Scope](http://weave.works/products/weave-scope/) or [Weave Cloud](http://cloud.weave.works/) to visualize the application once it's running in the selected [target platform](./deploy/).

![Sock Shop in Weave Scope](https://github.com/microservices-demo/microservices-demo.github.io/raw/master/assets/sockshop-scope.png)

## 
