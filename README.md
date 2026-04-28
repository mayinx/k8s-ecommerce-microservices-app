# 🧦 Sock Shop: Production-Grade DevOps Delivery Path

<!-- ### Proxmox VM Templates & K3s Target Delivery • Multi-Environment (`dev` / `prod`) • GitHub Actions CI/CD & GHCR • Cloudflare Tunnels • Tailscale Private Access • Prometheus/Grafana Observability • Ruby/Bash/Python Test Gate • Playwright Smoke Tests • Trivy Security Scanning & Dependabot • Terraform IaC Baseline • DR Backup & Restore Validation • Protected PR Workflow -->

![Proxmox](https://img.shields.io/badge/Proxmox-333333?style=for-the-badge&logo=proxmox&logoColor=white)
![Kubernetes](https://img.shields.io/badge/K3s-333333?style=for-the-badge&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-333333?style=for-the-badge&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-333333?style=for-the-badge&logo=githubactions&logoColor=white)
![GHCR](https://img.shields.io/badge/GHCR-333333?style=for-the-badge&logo=github&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-333333?style=for-the-badge&logo=cloudflare&logoColor=white)
![Tailscale](https://img.shields.io/badge/Tailscale-333333?style=for-the-badge&logo=tailscale&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-333333?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-333333?style=for-the-badge&logo=grafana&logoColor=white)
![Ruby](https://img.shields.io/badge/Ruby-333333?style=for-the-badge&logo=ruby&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-333333?style=for-the-badge&logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-333333?style=for-the-badge&logo=python&logoColor=white)
![Playwright](https://img.shields.io/badge/Playwright-333333?style=for-the-badge&logo=playwright&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-333333?style=for-the-badge&logo=aquasecurity&logoColor=white)
![Dependabot](https://img.shields.io/badge/Dependabot-333333?style=for-the-badge&logo=dependabot&logoColor=white)

<!-- ![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=for-the-badge&logo=proxmox&logoColor=white) 
![Kubernetes](https://img.shields.io/badge/K3s-FFC61C?style=for-the-badge&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![GHCR](https://img.shields.io/badge/GHCR-181717?style=for-the-badge&logo=github&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)
![Tailscale](https://img.shields.io/badge/Tailscale-000000?style=for-the-badge&logo=tailscale&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Playwright](https://img.shields.io/badge/Playwright-2EAD33?style=for-the-badge&logo=playwright&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1E5B99?style=for-the-badge&logo=aquasecurity&logoColor=white)
![Dependabot](https://img.shields.io/badge/Dependabot-025E8C?style=for-the-badge&logo=dependabot&logoColor=white) -->

Production-grade DevOps project based on the upstream WeaveSocks microservices application. This repository demonstrates a **reproducible, phase-based delivery path** from a **local Docker Compose baseline** to a **long-lived Proxmox-based K3s target environment** with public `dev` and `prod` entrypoints.

> **Project focus:** The goal is not just to run the application once, but to build a reproducible, phase-based DevOps delivery path with evidence-grade documentation. The project is intentionally implemented in phases so that each new capability builds on an already proven baseline, gradually covering the core capabilities expected from a modern DevOps delivery project:
>
> - **🏗️ Infrastructure & Platform:** Infrastructure as Code (IaC), Proxmox VM templating, Kubernetes deployment, and long-lived target-environment evolution.
> - **🚢 Delivery & Operations:** Containerized microservices delivery and operation, CI/CD, repo-owned container image build and publishing, and `dev` / `prod` environment separation.
> - **🛡️ Quality & Security:** Repo-owned validation tooling, deterministic test gates, security measures, Trivy scanning, and Dependabot dependency visibility.
> - **📊 Resilience & Observability:** Prometheus/Grafana observability, Kubernetes state backup, Mongo-compatible data-store dump validation, pod recovery proof, and rollback readiness.
> - **📚 Documentation & Evidence:** Phase-based implementation logs, runbooks, decisions, architecture notes, and evidence folders.. Start with [Documentation Index](project-docs/INDEX.md) for the full phase-based documentation structure: implementation logs, runbooks, decisions, ADRs, architecture notes, and evidence folders. Quick links: [Roadmap](project-docs/ROADMAP.md) · [Global decisions](project-docs/DECISIONS.md) · [Debug log](project-docs/DEBUG-LOG.md)

---

## 🧱 Tech Stack

*Infrastructure, delivery & operations:*\
🐳 **Docker** | ☸️ **Kubernetes (K3s)** | 🧪 **kind** | 🐙 **GitHub Actions** | 📦 **GHCR** | 🚜 **Proxmox VE** | ☁️ **Cloud-Init** | 🧱 **Terraform** | 🛡️ **Tailscale** | ☁️ **Cloudflare Tunnels** | 🚦 **Traefik** | 🧩 **Kustomize** | 📈 **Prometheus & Grafana** | ⚓ **Helm** | 🔎 **Trivy** | 🤖 **Dependabot** | 🗄️ **MongoDB**

*Repo-owned code, tooling & tests:*\
💎 **Ruby** | 🐍 **Python** | 🐚 **Bash** | 🟨 **JavaScript** | **Minitest** | **pytest** | 🎭 **Playwright**

---

## 🚀 Live Target Environments

The project exposes two long-lived public target environments through the Proxmox-based K3s delivery path:

| Environment | Public&nbsp;Entrypoint&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Role |
| :--- | :--- | :--- |
| 🧪&nbsp;**Development** | [dev-sockshop.cdco.dev](https://dev-sockshop.cdco.dev/) | Post-merge automated deployment target for validated changes; gated by required PR-checks; used for live smoke tests before production promotion |
| 🚀&nbsp;**Production** | [prod-sockshop.cdco.dev](https://prod-sockshop.cdco.dev/) | Approval-gated target environment for the promoted release |

Both entrypoints are routed through **Cloudflare Tunnel** to the **Proxmox-based K3s target platform**, where **Traefik** routes traffic by hostname into the correct namespace.

## 🔄 CI/CD Promotion Model

The current delivery path follows a **trunk-based CI/CD model with gated promotion**. Feature branches are reviewed through pull requests and can enter `master` only after the required deterministic checks pass. The merged commit triggers the Delivery Pipeline and is deployed automatically to `dev`. The same merge commit is finally promoted to `prod` after approval. 

### Delivery Flow 

The delivery path is organized as a controlled promotion chain: protected merge, automated `dev` deployment, optional live validation, and approval-gated `prod` promotion.

1. **🛡️&nbsp;Before merge:**\
The deterministic PR gate (**Ruby, Bash, Python tests + focused Trivy scans**) must pass before changes can enter `master` 

2. **⚡ After merge:**\
The merge commit accepted by the PR gate triggers the target delivery workflow and deploys automatically to `dev`

3. **🔍 Before production:**\
Live validation can be run against `dev` via **Python API contract smoke checks and Playwright browser smoke tests**

4. **🚀 Production promotion:**\
The same accepted commit promotes to `prod` only after reviewer approval (**GitHub Environment approval gate**)

### Workflow Trigger Model

The following workflows and automations implement this delivery flow:

| Workflow / automation | Trigger&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Executed&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Role |
| :--- | :--- | :--- | :--- |
| **🛡️&nbsp;Deterministic&nbsp;PR&nbsp;Gate** | (1) Pull requests targeting `master` when opened, reopened, or updated with new commits<br/>(2) Manual reruns via `workflow_dispatch` | (1) Ruby HealthCheck helper tests<br/>(2) Bash helper tests<br/>(3) Python API contract-guard tests<br/>(4) Focused Trivy repo scan and image scan | Required merge gate before changes can enter `master` |
| **🏗️&nbsp;Target&nbsp;Delivery&nbsp;Workflow** | (1) Push to `master` after merge<br/>(2) Manual runs via `workflow_dispatch` | (1) Kustomize overlay validation<br/>(2) Repo-owned `healthcheck` image build and GHCR push<br/>(3) Automated `dev` deployment<br/>(4) Approval-gated `prod` deployment | Main delivery workflow for the Proxmox target cluster |
| **🧪&nbsp;Live Smoke Workflow** | (1) Manual run via `workflow_dispatch`<br/>(2) Reusable workflow call via `workflow_call` | (1) Python live contract smoke tests<br/>(2) Playwright browser smoke tests against `dev` or `prod` | Environment-dependent validation, intentionally separate from the deterministic PR gate |
| **🤖&nbsp;Dependabot** | (1) Weekly scheduled dependency checks<br/>(2) Manual runs via GitHub UI or PR comments | (1) GitHub Actions<br/>(2) Playwright npm dependencies<br/>(3) Terraform provider dependencies | Dependency visibility for repo-owned tooling and infrastructure paths; generated PRs still go through the normal PR gate |

### Promotion model summary

The project does not use separate long-lived Git branches for `dev` and `prod`. Instead, `master` remains the source of truth, and the same accepted merge commit moves through:

- Deterministic PR validation
- Automated `dev` delivery
- Optional live smoke validation
- Approval-gated `prod` promotion

**Result:** This project uses a professional **single-branch promotion workflow** with protected merge checks, automated `dev` delivery, controlled `prod` promotion, separate live validation for deployed environments, and scheduled dependency visibility through Dependabot.

## 🌍 Environment model on the current target

### Target shape

The current `dev` and `prod` environments do not run on separate machines.

Both run on the **same Proxmox-based target VM** inside the **same single-node K3s cluster**.

**Result: `1 VM -> 1 cluster -> 2 namespaces -> 2 app environments`**

### Logical environment separation

The logical environment separation is implemented through:

- (1) Separate Kubernetes namespaces (`sock-shop-dev`, `sock-shop-prod`)
- (2) Separate Kustomize overlays (`deploy/kubernetes/kustomize/overlays/dev|prod`)
- (3) Host-based ingress routing through Traefik for both environments 
- (4) Separate public hostnames:
  - https://dev-sockshop.cdco.dev/
  - https://prod-sockshop.cdco.dev/
- (5) Separate workflow behavior (automated `dev` deployment, approval-gated `prod` deployment)

### Operational support around the target model

Additional operational support around this target model now includes:

- **Terraform IaC baseline:** Phase 08 proves reproducible Proxmox VM provisioning through an isolated disposable smoke VM path.
- **DR backup baseline:** Phase 09 exports Kubernetes namespace state for `sock-shop-dev` and `sock-shop-prod` and validates Mongo-compatible dump artifacts through a temporary restore check.

### Public routing path

Public traffic reaches the same target platform through Cloudflare Tunnel and is then routed by **hostname** through **Traefik** to the correct namespace-based application environment.

**Result:\
\
`1 VM -> 1 cluster -> 2 namespaces -> 2 app environments`**

Note: The Terraform baseline currently supports this architecture as a reproducible Proxmox provisioning proof, while the live `dev` / `prod` target remains the already established VM `9200` from the Phase 05 target-delivery path. 

~~~text
                          Public Internet
                                |
                                | (R1) HTTPS :443
                                |
                                v
+-------------------------------------------------------------------+
|                        CLOUDFLARE TUNNEL                          |
|                   (Public Edge + Security)                        |
+-------------------------------------------------------------------+
                                |
                                | (R2) Hostname-based HTTPS routing
                                | 
                                v
+-------------------------------------------------------------------+
|     --- TARGET VM 9200 (PROXMOX / K3S SINGLE-NODE) ---            |
|                                                                   |
|   +----------------------------------------------------------+    |
|   |               TRAEFIK INGRESS CONTROLLER                 |    |
|   +----------------------------------------------------------+    |
|             |                                   |                 |
|   (R3a) dev-sockshop.cdco.dev       (R3b) prod-sockshop.cdco.dev  |
|             |                                   |                 |
|             v                                   v                 |
|   +-----------------------+         +-----------------------+     |
|   | Namespace:            |         | Namespace:            |     |
|   | sock-shop-dev         |         | sock-shop-prod        |     |
|   |                       |         |                       |     |
|   | (Automated via CI)    |         | (Approval-gated CI)   |     |
|   +-----------------------+         +-----------------------+     |
|             ^                                  ^                  |
|             |                                  |                  |
|             |  (D3) Controllers Reconcile      |                  |       
|             |       namespace resources        |                  |
|             +-----------------+----------------+                  |
|                               |                                   |
|   +----------------------------------------------------------+    |
|   |          (D2) KUBERNETES API / CONTROL PLANE             |    |
|   | API stores desired state; controllers reconcile resources|    |
|   +----------------------------------------------------------+    |
+-------------------------------------------------------------------+
                                ^
                                |
            (D1) Private Kubernetes API access via Tailscale
                                |
+-------------------------------------------------------------------+
|        --- GITHUB ACTIONS RUNNER / OPERATOR WORKSTATION ---       |
|          renders selected env-specific Kustomize overlay          |
|           overlay into final Kubernetes manifests and             |
|        uses private kubectl access to the target cluster          |
+-------------------------------------------------------------------+

     
~~~

The **numbered flow** above separates the public request path from the deployment control path: 
- **Public Request Path (R1-R3):**\
User traffic enters through HTTPS, reaches the Cloudflare Tunnel, and is routed by Traefik based on the requested hostname to either `sock-shop-dev` or `sock-shop-prod`.
- **Deployment Control Path (D1-D3):**\
**GitHub Actions CI** renders the selected environment-specific Kustomize overlay into final Kubernetes manifests and applies those manifests to the Kubernetes API through the private **Tailscale** access path - as the desired target cluster state for the selected namespace. The same private access model is also used for operator `kubectl` access and private port-forwarding tasks.\
**Kubernetes** then performs **reconciliation**: the API receives the manifests and stores them as desired state, and Kubernetes controllers create, update, or replace resources until the affected namespace matches the applied manifests.

### Deployment and Reconciliation Model

These namespaces are logical partitions inside one Kubernetes cluster, not separate clusters. When the `dev` overlay is applied, Kubernetes updates the desired state of the resources in `sock-shop-dev` only. The `prod` namespace remains unchanged until the `prod` overlay is applied and approved.

The delivery workflow does not copy the repository onto the VM or run the application from a Git checkout on the target machine. 

Instead, GitHub Actions applies Kubernetes manifests to the cluster API. Kubernetes stores that desired state and recreates/updates the affected resources until the namespace matches it (reconciliation).

## 🎯 Target Scope

✅ **Kubernetes Deployment** (local K3s baseline → Proxmox target K3s cluster)\
✅ **CI/CD** (test/build/push/deploy with automated `dev` and approval-gated `prod`)\
✅ **Environment Separation** (`sock-shop-dev` / `sock-shop-prod` namespaces and Kustomize overlays)\
✅ **Observability** (Prometheus/Grafana baseline proven on the Proxmox target)\
✅ **Testing** (Ruby, Bash, Python contract guard, Playwright live smoke checks)\
✅ **DevSecOps Controls** (Trivy filesystem/image scanning, Dependabot, protected PR gate)\
✅ **Infrastructure as Code Baseline** (Terraform Proxmox Smoke-VM provisioning proof)\
✅ **Disaster Recovery / Rollback Readiness** (Kubernetes state backup, Mongo-compatible dump validation, pod recovery proof, rollback path documentation)\
✅ **Documentation:** Phase logs + setup notes + decisions + ADRs + evidence folders

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
✅ Protected default branch with required deterministic CI checks\
✅ Terraform-based Proxmox IaC baseline with disposable smoke-VM provisioning\
✅ DR backup helper for Kubernetes namespace state and Mongo-compatible data-store dumps\
✅ Temporary restore validation for a representative MongoDB dump artifact\
✅ Pod-level recovery proof through Kubernetes Deployment reconciliation\
✅ Rollback readiness documentation for Kubernetes Deployment revisions

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
- Dependabot baseline for GitHub Actions, Playwright npm dependencies, and Terraform provider dependencies
- Deterministic GitHub Actions PR gate with required status-check job names
- Separate live-smoke workflow for deployed environment validation
- Protected `master` branch with required deterministic Phase 07 checks

#### Infrastructure as Code Baseline

- Terraform workspace for a focused Proxmox smoke-VM proof
- Proxmox API access validated through the configured Terraform provider path
- Disposable VM `9300` provisioned from the workload-ready template `9010`
- Terraform plan/apply/destroy lifecycle proven successfully
- Terraform provider dependencies added to the Dependabot scope
- Terraform-related Makefile helpers added for repeatable local execution

#### Disaster Recovery & Rollback Readiness

- DR backup helper added for `sock-shop-dev` and `sock-shop-prod`
- Backup artifacts include Kubernetes namespace state, resource snapshots, Secret metadata only, and database backup reports
- Mongo-compatible data-store dumps created where `mongodump` is available
- Representative `user-db` dump restored into a temporary local MongoDB container and queried successfully
- Pod-level recovery proven by deleting a live `front-end` dev pod and validating Kubernetes recreation
- Live smoke checks passed after recovery
- Kubernetes rollback path documented without forcing an artificial bad release

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
| dev-sockshop.cdco.dev     | basket     | -                                        | 200    | 0.060022 |
| dev-sockshop.cdco.dev     | categories | -                                        | 200    | 0.054873 |
| dev-sockshop.cdco.dev     | home       | -                                        | 200    | 0.052675 |
| dev-sockshop.cdco.dev     | detail     | id=d3588630-ad8e-49df-bbd7-3167f7efb246  | 200    | 0.053624 |
| dev-sockshop.cdco.dev     | category   | tags=action                              | 200    | 0.055025 |
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
- **Current support layers:**
  - Terraform IaC baseline for reproducible Proxmox provisioning proof
  - Phase 09 DR backup path for Kubernetes state and Mongo-compatible data-store dumps
  - Pod recovery and rollback-readiness documentation
- **Later planned / hardening layers:** broader IaC coverage, full restore drills in disposable environments, stronger secret-management integration, and optional GitOps

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

- Phase 09 disaster recovery / rollback readiness:
  - [project-docs/09-dr-rollback/IMPLEMENTATION.md](project-docs/09-dr-rollback/IMPLEMENTATION.md)
  - Phase 09 documentation is in progress; the functional backup, restore-validation, and recovery proof are already implemented.
- Phase 08 Proxmox IaC baseline:
  - [project-docs/08-proxmox-iac/IMPLEMENTATION.md](project-docs/08-proxmox-iac/IMPLEMENTATION.md)
  - Phase 08 documentation is in progress; the Terraform smoke-VM proof is already implemented.
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

- **Phase 08 — Proxmox IaC baseline**
  - Terraform workspace added for a focused Proxmox smoke-VM proof
  - Proxmox API endpoint and token-based access validated
  - Terraform plan created for disposable VM `9300`
  - Terraform apply successfully created the smoke VM from template `9010`
  - Proxmox host-side verification confirmed the created VM
  - Terraform destroy successfully removed the disposable VM again
  - Makefile helpers added for Terraform init, validate, plan, apply, and destroy
  - Dependabot scope extended to Terraform provider dependencies
  - Docs:
    - [Implementation](project-docs/08-proxmox-iac/IMPLEMENTATION.md)

- **Phase 09 — Disaster recovery / rollback readiness**
  - DR backup helper added for `sock-shop-dev` and `sock-shop-prod`
  - Remote Proxmox target kubeconfig used by default for backup execution
  - Kubernetes namespace state exported into timestamped local backup artifacts
  - Secret values intentionally excluded; only Secret metadata is recorded
  - Mongo-compatible data-store dumps created where `mongodump` is available
  - Representative `user-db` dump restored into a temporary MongoDB container and queried successfully
  - Dev pod recovery proven through intentional `front-end` pod deletion and Kubernetes recreation
  - Live smoke checks passed after recovery
  - Kubernetes rollback path documented for future bad-revision scenarios
  - Docs:
    - [Implementation](project-docs/09-dr-rollback/IMPLEMENTATION.md)

Note: This section is intentionally a moving summary, not the final shape of the project.

---

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

### Phase 08 — Proxmox IaC baseline

- The first IaC proof is intentionally scoped to a disposable Proxmox smoke VM instead of replacing the already working target VM `9200`.
- Terraform is used to prove reproducible Proxmox VM provisioning without destabilizing the live `dev` / `prod` target.
- The Terraform-managed smoke VM is destroyed after verification so the target host remains clean.

### Phase 09 — Disaster Recovery & Rollback Readiness

- The first DR baseline focuses on safe, executable proof: Kubernetes state export, Mongo-compatible dump validation, pod recovery, and rollback path documentation.
- Backup artifacts are generated locally and excluded from Git.
- Secret values are not exported; only Secret metadata is recorded.
- Full database restore into live `dev` or `prod` is intentionally avoided; restore validation is performed in a disposable temporary MongoDB container.
- The current single-node K3s target is documented honestly: pod recovery is automatic, while full node/VM recovery follows rebuild, redeploy, and restore procedures.

---

## Repository structure (high level)

- `.github/workflows/` — workflow definitions
- `adr/` — Architecture Decision Records
- `project-docs/` — phase documentation, evidence, and decisions
- `deploy/` — upstream deployment assets (Compose, Kubernetes manifests, Helm chart, related deployment material)

## 🔮 What comes next

This README is intentionally kept open for the next implementation phases.


## 🔮 What comes next

The functional project scope now covers the core delivery, target-platform, observability, security, IaC, and DR requirements. Remaining work is mainly documentation polish and optional hardening.

### Immediate polish before final defense

- Finish Phase 08 implementation documentation
- Finish Phase 09 implementation documentation and runbook
- Add the final architecture diagram as an exported image
- Tighten cross-links in `project-docs/INDEX.md`, `ROADMAP.md`, and `DECISIONS.md`
- Review evidence captions and screenshots for Phase 08/09

### Later hardening / portfolio extensions

- Broader Terraform coverage for target VM recreation and bootstrap steps
- Full restore drill in a disposable namespace or throwaway cluster
- GitOps layer, for example Argo CD
- Stronger secret-management integration
- Optional SBOM generation and later image signing / verification
- Deeper Playwright user-flow checks
- Portfolio polish: recruiter-facing live dashboard / situation-room style proof layer
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
