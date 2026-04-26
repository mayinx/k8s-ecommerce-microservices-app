# Sock Shop — Production-like DevOps Delivery Path


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


# 🧦 Sock Shop: Production-Grade DevOps Delivery Path

### Proxmox VE Target Delivery • K3s Multi-Environment (`dev` / `prod`) • GitHub Actions CI/CD • Cloudflare Tunnels • Tailscale Private Access • Prometheus/Grafana Observability • Deterministic Test Gate • Trivy Security Scanning • Playwright Smoke Tests • Protected PR Workflow

Production grade DevOps project based on the upstream WeaveSocks microservices application. This repository demonstrates a complete, **reproducible, phase-based delivery path** from **local Docker Compose baseline** to a **production-like Proxmox target environment**.

> **Project focus:** The goal is not just to run the application once, but to build a **reproducible, phase-based delivery path** with **evidence-grade documentation** that gradually proves the **core capabilities expected from a modern DevOps project**: containerized delivery, environment separation, observability, security measures, and infrastructure-oriented deployment evolution.

---

## 🧱 Tech Stack

🐳 **Docker** | ☸️ **Kubernetes (K3s)** | 🐙 **GitHub Actions** | 🚜 **Proxmox VE** | 🛡️ **Tailscale** | ☁️ **Cloudflare Tunnels** | 🚦 **Traefik** | 🧩 **Kustomize** | 📈 **Prometheus & Grafana** | 🔎 **Trivy** | 🎭 **Playwright** | 🤖 **Dependabot** | 💎 **Ruby/Minitest** | 🐚 **Bash** | 🐍 **Python/pytest** | 🟨 **JavaScript**

---

## 🚀 Live target environments

The project now exposes both long-lived target environments (`dev-sockshop` + `prod-sockshop`) publicly through a Proxmox-based delivery path:

- **Development:** https://dev-sockshop.cdco.dev/ 
- **Production:** https://prod-sockshop.cdco.dev/ 

These URLs represent the current live public entrypoints of the target platform proven in Phase 05 of the implementation path.

## 🌍 Environment model on the current target

The current `dev` and `prod` environments do not run on separate machines.

Both run on the **same Proxmox-based target VM** inside the **same single-node K3s cluster**.

The **Environment separation is logical** and implemented through:

- Separate Kubernetes namespaces (`sock-shop-dev`, `sock-shop-prod`)
- Separate Kustomize overlays (`deploy/kubernetes/kustomize/overlays/dev|prod`)
- Host-based ingress routing through Traefik for both environments 
- Separate public hostnames:
  - https://dev-sockshop.cdco.dev/
  - https://prod-sockshop.cdco.dev/
- Separate workflow behavior (automated `dev` deployment, approval-gated `prod` deployment)

Public traffic reaches the same target platform through Cloudflare Tunnel and is then routed by **hostname** through **Traefik** to the correct namespace-based application environment.

**Result: `1 VM -> 1 cluster -> 2 namespaces -> 2 app environments`**

~~~text
Public Internet
       |
       v
+-------------------------------------------------------------+
| Cloudflare Tunnel (Edge Security)                           |
+-------------------------------------------------------------+
       |
       | (HTTPS routed by hostname)
       v
+-------------------------------------------------------------+
| Target VM (Proxmox / K3s Single-Node)                       |
|                                                             |
|   +-----------------------------------------------------+   |
|   | Traefik Ingress Controller                          |   |
|   +-----------------------------------------------------+   |
|          |                                     |            |
|   dev-sockshop.cdco.dev              prod-sockshop.cdco.dev |
|          |                                     |            |
|          v                                     v            |
|   +-----------------------+         +-----------------------+
|   | Namespace:            |         | Namespace:            |
|   | sock-shop-dev         |         | sock-shop-prod        |
|   |                       |         |                       |
|   | (Automated via CI)    |         | (Approval-gated CI)   |
|   +-----------------------+         +-----------------------+
+-------------------------------------------------------------+
~~~

These namespaces are logical partitions inside one Kubernetes cluster, not separate clusters. When the `dev` overlay is applied, Kubernetes updates the desired state of the resources in `sock-shop-dev` only. The `prod` namespace remains unchanged until the `prod` overlay is applied and approved.

The delivery workflow does not copy the repository onto the VM or run the application from a Git checkout on the target machine. Instead, GitHub Actions applies Kubernetes manifests to the cluster API. Kubernetes stores that desired state and reconciles the affected namespace resources. 

## 🔄 Delivery workflow model

The current delivery path follows a **trunk-based CI/CD model with gated promotion**:

- Feature branches are merged into `master`
- The merged commit triggers teh Pipeline and is deployed automatically to `dev`
- The same commit is promoted to `prod` only after approval 

**Result:** This project uses a professional **single-branch promotion workflow** rather than separate long-lived Git branches per environment.

## 🎯 Target Scope

✅ **Kubernetes deployment** (K3s locally → Proxmox target)\
✅ **CI/CD** (build/test/push/deploy with approval-gated `prod`)\
✅ **Observability** (Prometheus/Grafana baseline proven on the real target)\
✅ **Testing** (Ruby, Bash, Python contract guard, Playwright smoke checks)\
✅ **DevSecOps controls** (Trivy filesystem/image scanning, Dependabot, protected PR gate)\
✅ **Documentation:** phase logs + setup notes + decisions + ADRs\
⏳ **IaC** (Terraform planned for stable target/bootstrap pieces)\
⏳ **DR / rollback approach** (planned)

---

## ✅ What this repository already demonstrates

This repository demonstrates an iterative DevOps delivery path built around Sock Shop, including:

✅ Docker-based application execution\
✅ Kubernetes deployment via proven raw manifests\
✅ Environment-specific deployment layering with Kustomize\
✅ GitHub Actions CI/CD with GHCR image publishing\
✅ Approval-gated promotion flow\
✅ Evidence-oriented technical documentation\
✅ A real Proxmox-backed target-delivery platform\
✅ A delivery path spanning local proof, CI/CD proof, and a long-lived target environment\
✅ Observability with Grafana + Prometheus\
✅ Automated tests for repo-owned Ruby, Bash, and Python validation components\
✅ Browser smoke testing with Playwright\
✅ Trivy-based security scanning and evidence-based Dockerfile remediation\
✅ Dependabot dependency update baseline\
✅ Protected default branch with required deterministic CI checks

---

### 🌟 Current proven highlights include: 

#### Local and CI/CD baselines

- Clean local Kubernetes baseline
- Host-based local ingress baseline
- Namespace-based `dev` / `prod` Kustomize overlays
- GitHub Actions CI/CD smoke workflow
- GHCR publishing for the repo-owned `healthcheck` image
- Automated `dev` smoke deployment
- Approval-gated `prod` smoke deployment

#### Proxmox target platform and public delivery path

- Reusable Proxmox VM template baseline
- Verified Proxmox smoke VM with host-side and guest-side proof
- Workload-ready Proxmox baseline variant for target-side deployment
- Real target VM `9200`, cloned from workload-ready template `9010`
- Single-node K3s control plane on the real target
- Source-controlled MongoDB compatibility fix for the target runtime
- Working `dev` / `prod` deployment model on the real target cluster
- Private Tailnet-based operator and CI/CD access path
- Public HTTPS exposure through Cloudflare Tunnel
- Stable live public environments:
  - `https://dev-sockshop.cdco.dev/`
  - `https://prod-sockshop.cdco.dev/`
- Dedicated Phase 05 workflow for automated `dev` and approval-gated `prod` deployment on the real target cluster

#### Observability Baseline

- Dedicated `monitoring` namespace on the real target
- Maintained Helm-based monitoring baseline through `kube-prometheus-stack`
- Private Grafana and Prometheus operator access via `kubectl port-forward`
- Namespace-level workload visibility for `sock-shop-prod`
- Healthy core monitoring targets through Prometheus

#### Testing, Security, Merge Governance

- Repo-owned Ruby `healthcheck` helper refactored and covered by CLI/unit tests
- Repo-owned Bash Observability Traffic Generator refactored and covered by CLI/function-level tests
- Python `/catalogue` contract guard with deterministic local tests and live endpoint validation
- Playwright browser smoke tests for live storefront rendering
- Trivy filesystem scan baseline for repo-owned code/config components
- Trivy image vulnerability scan for the repo-owned `healthcheck` image
- Hardened `healthcheck` Dockerfile with clean focused Trivy reruns
- Dependabot baseline for GitHub Actions and Playwright npm dependencies
- Deterministic GitHub Actions PR gate with required status-check job names
- Separate live-smoke workflow for deployed environment validation
- Protected `master` branch with required deterministic Phase 07 checks

#### 🚥 Traffic Generator (Observability Helper)

Reusable observability helper script (introduced in Phase 06):

- `scripts/observability/generate-sockshop-traffic.sh`

On execution, it generates **repeatable storefront traffic** so the monitoring stack has useful live activity to visualize during observability checks. It is equipped both for **manual observability verification** and for **non-interactive execution in scripts, pipeline jobs, or other automated checks**.

**Current features:**

- Execution against **`dev`** or **`prod`** live targets `(prod|dev)-sockshop.cdco.dev`
- **Interactive** or **CLI-driven** startup
- Choice between **Local Preset** or **live-discovered** data sources (fetched via the Sock Shop's JSON API endpoints for products and categories) for request params
- **Randomized** product detail/category **requests**
- **Makefile shortcuts** for the most common traffi generator flows:
- `make p06-traffic-dev-preset`
- `make p06-traffic-dev-live`
- `make p06-traffic-prod-preset`
- `make p06-traffic-prod-live`
- **Cookie-based session reuse** (via cookie jar)
- **Detailed terminal output** (request-table style):
  - Endpoint
  - Parameter
  - HTTP status
  - Latency
 
~~~bash
|---------------------------+------------+------------------------------------------+--------+----------|
|                                           --- 00:07:53 ---                                            |
|---------------------------+------------+------------------------------------------+--------+----------|
| Host                      | Endpoint   | Param                                    | Status | Latency  |
|---------------------------+------------+------------------------------------------+--------+----------|
| dev-sockshop.cdco.dev    | basket     | -                                        | 200    | 0.060022 |
| dev-sockshop.cdco.dev    | categories | -                                        | 200    | 0.054873 |
| dev-sockshop.cdco.dev    | home       | -                                        | 200    | 0.052675 |
| dev-sockshop.cdco.dev    | detail     | id=d3588630-ad8e-49df-bbd7-3167f7efb246  | 200    | 0.053624 |
| dev-sockshop.cdco.dev    | category   | tags=action                              | 200    | 0.055025 |
|---------------------------+------------+------------------------------------------+--------+----------|
|                                           --- 00:07:54 ---                                            |
|---------------------------+------------+------------------------------------------+--------+----------|
| Host                      | Endpoint   | Param                                    | Status | Latency  |
|---------------------------+------------+------------------------------------------+--------+----------|
| prod-sockshop.cdco.dev    | basket     | -                                        | 200    | 0.057636 |
| prod-sockshop.cdco.dev    | categories | -                                        | 200    | 0.058919 |
| prod-sockshop.cdco.dev    | home       | -                                        | 200    | 0.054376 |
| prod-sockshop.cdco.dev    | detail     | id=zzz4f044-b040-410d-8ead-4de0446aec7e  | 200    | 0.058766 |
| prod-sockshop.cdco.dev    | category   | tags=geek                                | 200    | 0.054238 |
|---------------------------+------------+------------------------------------------+--------+----------|
~~~

#### Observability Make Helper Targets

The repository exposes a few thin Makefile helpers for the most common bservability checks and traffic-generation flows (introduced in Phase 06):

- `make p06-monitoring-status`
- `make p06-grafana-port-forward`
- `make p06-prometheus-port-forward`
- `make p06-traffic-dev-preset`
- `make p06-traffic-dev-live`
- `make p06-traffic-prod-preset`
- `make p06-traffic-prod-live`

#### 🛡️ Phase 07 Testing & Security Helper Targets

Phase 07 adds thin Makefile helpers for deterministic tests, live smoke checks, and focused security scans:

- `make p07-tests`
- `make p07-tests-live`
- `make p07-tests-all`
- `make p07-healthcheck-tests`
- `make p07-traffic-helper-tests`
- `make p07-contract-guard-tests`
- `make p07-contract-guard-live-dev`
- `make p07-e2e-smoke-dev`
- `make p07-trivy-healthcheck-repo-scan`
- `make p07-trivy-healthcheck-image-scan`

These targets keep local reruns aligned with the GitHub Actions validation path.

---

## 🏗️ Architecture direction

The current architecture direction is:

- **application:** Sock Shop microservices
- **local baseline runtime:** Docker Compose and local k3s
- **Kubernetes deploy input:** raw manifests with environment overlays
- **CI/CD platform:** GitHub Actions
- **container registry:** GHCR
- **historical CI/CD smoke target:** `kind` (Phase 03 baseline)
- **Current long-lived target:** Proxmox-backed VM + K3s
  - **Current realized target shape:**
    - Workload-ready baseline template `9010`
    - Target VM `9200`
    - Single-node K3s control plane
    - `sock-shop-dev` and `sock-shop-prod`
    - Traefik ingress
    - Tailscale private access path
    - Cloudflare Tunnel public edge
    - Dedicated `monitoring` namespace
    - `kube-prometheus-stack` monitoring baseline
    - Private Grafana and Prometheus access via `kubectl port-forward`
- **Later planned layers:** security hardening, DR, and selective IaC-driven codification of stable target/bootstrap pieces

This means the project is no longer only proving delivery mechanics in isolation; it is now also proving those mechanics against a real long-lived target environment.

## 📚 Documentation (start here)

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

- Phase 07 setup:
  - [project-docs/07-security-testing/SETUP.md](project-docs/07-security-testing/SETUP.md)
- Phase 07 runbook:
  - [project-docs/07-security-testing/RUNBOOK.md](project-docs/07-security-testing/RUNBOOK.md)  
- Phase 07 implementation overview:
  - [project-docs/07-security-testing/IMPLEMENTATION.md](project-docs/07-security-testing/IMPLEMENTATION.md)
- Phase 07 decisions:
  - [project-docs/07-security-testing/DECISIONS.md](project-docs/07-security-testing/DECISIONS.md)
- Phase 07 detailed subphase guides:
  - [Phase 07-A](project-docs/07-security-testing/implementation/PHASE-07-A.md)
  - [Phase 07-B](project-docs/07-security-testing/implementation/PHASE-07-B.md)
  - [Phase 07-C](project-docs/07-security-testing/implementation/PHASE-07-C.md)
  - [Phase 07-D](project-docs/07-security-testing/implementation/PHASE-07-D.md)

### Previous phase docs

- Phase 06 implementation log:
  - [project-docs/06-observability/IMPLEMENTATION.md](project-docs/06-observability/IMPLEMENTATION.md)
- Phase 06 runbook:
  - [project-docs/06-observability/RUNBOOK.md](project-docs/06-observability/RUNBOOK.md)
- Phase 06 decisions:
  - [project-docs/06-observability/DECISIONS.md](project-docs/06-observability/DECISIONS.md)

### Cross-phase docs

- Summarized project decisions:
  - [project-docs/DECISIONS.md](project-docs/DECISIONS.md)
- Project roadmap / planning:
  - [project-docs/ROADMAP.md](project-docs/ROADMAP.md)
- Project Debug Log & Incident Reports:
  - [project-docs/DEBUG-LOG.md](project-docs/DEBUG-LOG.md)
- Architecture Decision Records (ADRs):
  - [adr/](adr/)

## 🏛️ Architecture Decision Records (ADRs)

Project-wide standards and long-lived decisions live in:

- [adr/](adr/)

**Current ADRs (source of truth):**
- ADR-0001 — Git conventions (workflow, branching, commit messages): [adr/[2026-03-17] ADR-0001 -- Git-Conventions.md](adr/%5B2026-03-17%5D%20ADR-0001%20--%20Git-Conventions.md)
- ADR-0002 — Documentation system and locations: [adr/[2026-03-18] ADR-0002 -- Docs-System.md](adr/%5B2026-03-18%5D%20ADR-0002%20--%20Docs-System.md)

## 📁 Current verified scope

The repository currently contains proven work across these phases:

- **Phase 00 — Compose baseline**
  - Repository reconnaissance
  - Local Docker Compose baseline
  - Host-port conflict diagnosis and workaround
  - Docs:
    - [Implementation](project-docs/00-compose-baseline/IMPLEMENTATION.md)
    - [Runbook](project-docs/00-compose-baseline/RUNBOOK.md)  

- **Phase 01 — Port-based Kubernetes baseline**
  - Clean local k3s deployment via upstream manifests
  - Storefront reachable via NodePort `30001`
  - Docs:  
    - [Implementation](project-docs/01-nodeport-baseline/IMPLEMENTATION.md)
    - [Runbook](project-docs/01-nodeport-baseline/RUNBOOK.md)  

- **Phase 02 — Host-based ingress baseline**
  - Local Traefik ingress for `sockshop.local`
  - NodePort retained as fallback
  - Docs:  
    - [Implementation](project-docs/02-ingress-baseline/IMPLEMENTATION.md)
    - [Runbook](project-docs/02-ingress-baseline/RUNBOOK.md)  

- **Phase 03 — CI/CD baseline**
  - GitHub Actions delivery workflow
  - Kustomize overlays for `dev` / `prod`
  - GHCR publishing for the repo-owned `healthcheck` image
  - automated `dev` smoke deployment
  - Approval-gated `prod` smoke deployment
  - Docs:
    - [Setup](project-docs/03-ci-cd-baseline/SETUP.md)
    - [Implementation](project-docs/03-ci-cd-baseline/IMPLEMENTATION.md)
    - [Runbook](project-docs/03-ci-cd-baseline/RUNBOOK.md)
    - [Decisions](project-docs/03-ci-cd-baseline/DECISIONS.md)  

- **Phase 04 — Proxmox VM baseline**
  - Provided Proxmox target host inspected and documented
  - Reusable Ubuntu 24.04 Cloud-Init VM template created as `9000`
  - Reference smoke VM created as `9100`
  - Host-side verification completed
  - Guest-side verification completed:
    - Login
    - Cloud-Init completion
    - Usable root disk
    - Outbound connectivity
  - Workload-ready baseline variant prepared and finalized as `9010`
    - Private guest bridge `vmbr1`
    - Stable private guest addressing and routing
    - Deterministic DNS and outbound bootstrap reachability
    - Guest-agent capability
  - docs:
    - [Discovery](project-docs/04-proxmox-vm-baseline/DISCOVERY.md)
    - [Setup](project-docs/04-proxmox-vm-baseline/SETUP.md)
    - [Implementation](project-docs/04-proxmox-vm-baseline/IMPLEMENTATION.md)
    - [Runbook](project-docs/04-proxmox-vm-baseline/RUNBOOK.md)
    - [Decisions](project-docs/04-proxmox-vm-baseline/DECISIONS.md)

- **Phase 05 — Proxmox target delivery**
  - Real target VM `9200` cloned from workload-ready template `9010`
  - Single-node K3s control plane on the target VM
  - Source-controlled MongoDB compatibility fix for the target runtime
  - Environment-separated `dev` / `prod` deployment model on the real target cluster
  - Working Traefik ingress for both environments
  - Private Tailscale-based operator and CI/CD access path
  - Public HTTPS exposure through Cloudflare Tunnel
  - Dedicated Phase 05 workflow for automated `dev` and approval-gated `prod` deployment on the real target
  - Docs:
    - [Setup](project-docs/05-proxmox-target-delivery/SETUP.md)
    - [Implementation](project-docs/05-proxmox-target-delivery/IMPLEMENTATION.md)
    - [Runbook](project-docs/05-proxmox-target-delivery/RUNBOOK.md)
    - [Decisions](project-docs/05-proxmox-target-delivery/DECISIONS.md)

- **Phase 06 — Observability & Health**
  - Dedicated `monitoring` namespace on the real target cluster
  - Maintained Helm-based monitoring baseline through `kube-prometheus-stack`
  - Private Grafana access through `kubectl port-forward`
  - Private Prometheus access through `kubectl port-forward`
  - Namespace-level workload visibility for `sock-shop-prod`
  - Healthy core monitoring targets on the Prometheus `/targets` page
  - Oberservability helper Bash script to auto-generate traffic on the target cluster for Grafana/Prometheus  
  - Docs:
    - [Implementation](project-docs/06-observability/IMPLEMENTATION.md)
    - [Runbook](project-docs/06-observability/RUNBOOK.md)
    - [Decisions](project-docs/06-observability/DECISIONS.md)

- **Phase 07 — Security Testing**
  - Repo-owned Ruby `healthcheck` helper refactored into a testable structure
  - Ruby CLI characterization and unit tests added
  - Repo-owned Bash Observability Traffic Generator refactored behind `main()` and an execution guard
  - Bash CLI and function-level tests added
  - Python `/catalogue` contract guard added with deterministic local tests
  - Live Python contract smoke checks added for deployed catalogue endpoints
  - Playwright browser smoke tests added for live storefront rendering
  - Trivy filesystem scan baseline added for repo-owned code/config components
  - Trivy image scan added for the repo-owned `healthcheck` image
  - `healthcheck` Dockerfile hardened and verified through focused clean Trivy reruns
  - Dependabot configured for GitHub Actions and the Playwright npm toolchain
  - Deterministic GitHub Actions PR gate added
  - Separate manual/reusable live-smoke workflow added
  - `master` protected with required deterministic Phase 07 checks
  - Docs:
    - [Setup](project-docs/07-security-testing/SETUP.md)
    - [Implementation](project-docs/07-security-testing/IMPLEMENTATION.md)
    - [Runbook](project-docs/07-security-testing/RUNBOOK.md)    
    - [Decisions](project-docs/07-security-testing/DECISIONS.md)

Note: This section is intentionally a moving summary, not the final shape of the project.

## Tech stack

Current or already chosen technology in this project includes:

- Docker
- Kubernetes
- K3s
- Traefik
- Kustomize
- GitHub Actions
- GHCR
- `kind`
- Proxmox VE
- Cloud-Init
- Tailscale
- Cloudflare Tunnel
- Helm
- Prometheus
- Grafana
- Trivy
- Playwright
- Dependabot
- Python / pytest
- Ruby / Minitest
- Bash helper tests

Additional planned layers include:

- Terraform
- DR / rollback automation and documentation

Helm is also present in the repository and was evaluated, but deferred for the current CI/CD baseline because the chart path still introduces legacy compatibility friction. [TODO: Update Helm-usage for monitoring/observability] ...
 
## 📸 Evidence

Evidence is captured phase-by-phase under:\
`project-docs/<phase-folder>/evidence/`

For the CI/CD baseline f. i., key workflow evidence lives under:\
`project-docs/03-ci-cd-baseline/evidence/gh/`

The full evidence index for each phase is documented inside the corresponding `IMPLEMENTATION.md`, for example:\
[project-docs/03-ci-cd-baseline/IMPLEMENTATION.md](project-docs/03-ci-cd-baseline/IMPLEMENTATION.md)

---

## Current notable decisions

[TODO: Organize in Implementation Phases (see Phase 06 ff.) ]

- Helm was evaluated but deferred because the chart path still introduces legacy compatibility friction.
- The CI/CD baseline uses GitHub-hosted runners, not a self-hosted runner on a personal machine.
- `openapi` is excluded for now because it is a legacy auxiliary build target and not required for proving the main delivery path.
- The Proxmox baseline is standardized on the official Cloud-Init template workflow via `qm`.
- Phase 04 proves the target VM baseline through both host-side and guest-side verification, not through inventory visibility alone.
- Phase 05 keeps the Kubernetes/Kustomize deployment path and evolves it onto the real Proxmox-backed target instead of switching deployment models midstream.
- The real target cluster is reached privately through Tailscale, not by exposing the Kubernetes API publicly.
- Public application exposure is handled through Cloudflare Tunnel and Traefik, not by opening inbound application ports directly on the VM.
- The historical Phase 03 workflow is preserved, while the Phase 05 workflow is the active real-target delivery path.
- The project remains phase-based so later observability, security, and DR work can build on already proven mechanics.

### Phase 06 - Oberservabiliyt & Health
- The first observability baseline uses the maintained `kube-prometheus-stack` chart instead of the older fragmented repository monitoring path.
- The first monitoring rollout is intentionally small and private-only.
- Grafana and Prometheus are accessed privately through `kubectl port-forward` over the already proven Tailnet-based kubeconfig path.
- The first observability baseline is considered proven only when both dashboard visibility and Prometheus scrape health are shown successfully.

### Phase 07 — Security Testing

- The first testing and security baseline focuses on repo-owned components before inherited upstream legacy components.
- Deterministic tests and focused security scans are used as required merge checks.
- Live smoke checks remain separate from the required PR gate because they depend on deployed environment state.
- Trivy is used as the first security scanner for repo-owned code/config checks and the repo-owned `healthcheck` image.
- The repo-owned `healthcheck` image is the first explicit remediation target.
- Dependabot is scoped to owned dependency targets: GitHub Actions and the Playwright npm project.
- The default branch is protected through required deterministic Phase 07 checks.


---

## Repository structure (high level)

- `.github/workflows/` — workflow definitions
- `adr/` — Architecture Decision Records
- `project-docs/` — phase documentation, evidence, and decisions
- `deploy/` — upstream deployment assets (Compose, Kubernetes manifests, Helm chart, related deployment material)

## 🔮 What comes next

This README is intentionally kept open for the next implementation phases.

### Core phases still to complete

- **Selective IaC codification**  
  Terraform for stable target/bootstrap pieces, with the existing validation and branch-protection path kept in place.

- **Disaster recovery / rollback strategy**  
  Recovery documentation, rollback commands, and evidence-backed recovery thinking.

### Strong stretch goals before evaluation, if time allows

- **Testing track extension:**
  - deeper Playwright user-flow checks
  - automatic post-deployment live-smoke reuse after `dev` or `prod` rollout
- **Custom Python microservice:**
  - Order Guard / Policy Service
  - FastAPI-based service extension with its own tests and deployment path
- **Stronger image / supply-chain checks:**
  - broader Trivy backlog cleanup
  - optional SBOM generation
  - optional later signing / verification

### Later portfolio extensions

- GitOps layer (for example Argo CD)
- stronger secret-management integration
- optional AWS target as an additional Terraform-driven deployment track
- **Portfolio polish:** recruiter-facing live dashboard / situation-room style proof layer

For the fuller internal planning view, see:

- [project-docs/ROADMAP.md](project-docs/ROADMAP.md)

## License / upstream

This is a fork-based DevOps project. Upstream origins and licenses apply where relevant.

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
