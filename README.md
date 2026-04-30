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
> - **📚 Documentation & Evidence:** Phase-based implementation logs, runbooks, decisions, architecture notes, and evidence folders.. Start with the **[Documentation Index](project-docs/INDEX.md)** for the full phase-based documentation structure: implementation logs, runbooks, decisions, ADRs, architecture notes, and evidence folders. \
*Quick links:* **[Index](project-docs/INDEX.md) • [Global decisions](project-docs/DECISIONS.md) • [Debug log](project-docs/DEBUG-LOG.md) • [Roadmap](project-docs/ROADMAP.md)**

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

---

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

---

### Workflow Trigger Model

The following workflows and automations implement this delivery flow:

| Workflow / automation | Trigger&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Executed&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Role&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :--- | :--- | :--- | :--- |
| **🛡️&nbsp;Deterministic&nbsp;PR&nbsp;Gate** | (1) Pull requests targeting `master` when opened, reopened, or updated with new commits<br/>(2) Manual reruns via `workflow_dispatch` | (1) Ruby HealthCheck helper tests<br/>(2) Bash helper tests<br/>(3) Python API contract-guard tests<br/>(4) Focused Trivy repo scan and image scan | Required merge gate before changes can enter `master` |
| **🏗️&nbsp;Target&nbsp;Delivery&nbsp;Workflow** | (1) Push to `master` after merge<br/>(2) Manual runs via `workflow_dispatch` | (1) Kustomize overlay validation<br/>(2) Repo-owned `healthcheck` image build and GHCR push<br/>(3) Automated `dev` deployment<br/>(4) Approval-gated `prod` deployment | Main delivery workflow for the Proxmox target cluster |
| **🧪&nbsp;Live Smoke Workflow** | (1) Manual run via `workflow_dispatch`<br/>(2) Reusable workflow call via `workflow_call` | (1) Python live contract smoke tests<br/>(2) Playwright browser smoke tests against `dev` or `prod` | Environment-dependent validation, intentionally separate from the deterministic PR gate |
| **🤖&nbsp;Dependabot** | (1) Weekly scheduled dependency checks<br/>(2) Manual runs via GitHub UI or PR comments | (1) GitHub Actions<br/>(2) Playwright npm dependencies<br/>(3) Terraform provider dependencies | Dependency visibility for repo-owned tooling and infrastructure paths; generated PRs still go through the normal PR gate |

---

### Promotion model summary

The project does not use separate long-lived Git branches for `dev` and `prod`. Instead, `master` remains the source of truth, and the same accepted merge commit moves through:

- Deterministic PR validation
- Automated `dev` delivery
- Optional live smoke validation
- Approval-gated `prod` promotion

**Result:** This project uses a professional **single-branch promotion workflow** with protected merge checks, automated `dev` delivery, controlled `prod` promotion, separate live validation for deployed environments, and scheduled dependency visibility through Dependabot.

---

## 🌍 Target Environment Model 

### Target Shape

The current `dev` and `prod` environments do not run on separate machines.

Both run on the **same Proxmox-based target VM** inside the **same single-node K3s cluster**.

**Result: `1 VM -> 1 cluster -> 2 namespaces -> 2 app environments`**

> **Architecture Flow:**
>
> 🖥️ **1 Proxmox VM** ➔ ☸️ **1 K3s Cluster** ➔ 🗂️ **2 Namespaces** ➔ 🚀 **2 App Environments**

### Logical environment separation

The logical environment separation is implemented through:

1. **Separate Kubernetes namespaces:** `sock-shop-dev` and `sock-shop-prod`.
2. **Separate Kustomize overlays:** `deploy/kubernetes/kustomize/overlays/dev|prod`.
3. **Host-based ingress routing:** Handled through Traefik for both environments.
4. **Separate public entrypoints:** Traffic is routed via [`dev-sockshop.cdco.dev`](https://dev-sockshop.cdco.dev/) and [`prod-sockshop.cdco.dev`](https://prod-sockshop.cdco.dev/).
5. **Distinct workflow behaviors:** Automated `dev` deployment vs. approval-gated `prod` deployment.

### Operational Aupport Around the Target Model

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

## 🌟 Current proven highlights include: 

### Local and CI/CD baselines

#### Phase 00 — Docker Compose baseline
- Repository reconnaissance
- Local Docker Compose baseline
- Host-port conflict diagnosis and workaround

#### Phase 01 — Port-based Kubernetes baseline
- Clean local Kubernetes baseline (k3s deployment via upstream manifests)
- Storefront reachable via NodePort `30001`

#### Phase 02 — Host-based Traefik ingress baseline
- Host-based local Traefik ingress baseline for `sockshop.local`
- NodePort access retained as fallback

#### Phase 03 — CI/CD baseline
- GitHub Actions CI/CD delivery smoke workflow
- Kustomize overlays for `dev` / `prod` Namespaces
- GHCR publishing for the repo-owned `healthcheck` image
- Automated `dev` smoke deployment
- Approval-gated `prod` smoke deployment

#### Phase 04 — Proxmox VM Baseline 
- Provided Proxmox target host inspected and documented
- Proxmox VM artifact model established:
  - VM Template `9000`: Generic Ubuntu 24.04 Cloud-Init VM Template (reusable VM Template baseline)
  - VM `9100`: Reference smoke VM 
  - VM Template `9010`:  Workload-ready template variant  
- Verified Proxmox Smoke `VM 9100` with host-side and guest-side proof:
  - Login
  - Cloud-Init completion
  - Usable root disk
  - Outbound connectivity
- Workload-ready baseline variant prepared as VM Template `9010`:
  - Private guest bridge `vmbr1`
  - Stable private addressing/routing
  - Deterministic DNS 
  - Outbound bootstrap reachability
  - QEMU Guest-agent capability

### Phase 05 — Proxmox Target Delivery
- Target VM `9200` created - cloned from workload-ready VM template `9010`
- Single-node K3s control plane deoloyed on the target VM 9200
- MongoDB compatibility fix for the target runtime (first in-target ad hoc fix and later repo-based permanent fix) 
- Environment-separated `dev` / `prod` deployment model on the remote k8s target cluster
- Working Traefik ingress for both environments
- Private Tailnet-based access path for operator (workstation) and CI/CD (Hosted Runners) access
- Public HTTPS exposure through Cloudflare Tunnel
- Stable live public environments:
  - `https://dev-sockshop.cdco.dev/`
  - `https://prod-sockshop.cdco.dev/`
- Dedicated Phase 05 GitHUb Actions delivery Workflow for automated `dev` and approval-gated `prod` deployment on the remote k8s target cluster

### Phase 06 — Observability & Health

- Dedicated k8s `monitoring` namespace on the remote target
- Maintained Helm-based monitoring baseline through `kube-prometheus-stack`
- Private Grafana and Prometheus operator access via `kubectl port-forward`
- Namespace-level workload visibility for `sock-shop-prod`
- Healthy core monitoring targets through Prometheus (on the Prometheus `/targets` page)
- Implementation of a custom TRaffic Generator Bash Script (Oberservability helper to auto-generate traffic on the target cluster for Grafana/Prometheus)  

### Phase 07 - Testing, Security, Merge Governance

- Repo-owned Ruby `healthcheck` helper refactored into a testable structure and covered by CLI/unit tests
- Ruby CLI characterization and unit tests added
- Repo-owned Bash Observability Traffic Generator refactored (behind `main()` and an execution guard) and covered by Bash CLI and function-level tests
- Implementation of a Python `/catalogue` API Contract Guard - coverd with deterministic local tests  
  - Live Python contract smoke checks added for deployed `catalogue` API endpoints
- Playwright browser smoke tests for live storefront rendering
- Trivy filesystem scan baseline for repo-owned code/config components
- Trivy image vulnerability scan for the repo-owned `healthcheck` image
- `healthcheck` Dockerfile hardened and verified through focused clean Trivy reruns
- Dependabot configured for GitHub Actions, Playwright npm dependencies, and Terraform provider dependencies
- Deterministic GitHub Actions PR gate with required status-check jobs
- Separate manual/reusable live-smoke test workflow for deployed environment validation
- Protected `master` branch with required deterministic Phase 07 checks

### Phase 08 — Infrastructure as Code Baseline 

- Isolated Terraform workspace created for a focused Proxmox Smoke-VM proof under `infra/terraform/proxmox-smoke-vm/`
- Disposable VM `9300` provisioned from the workload-ready template `9010`
- Proxmox automation through a Terraform Proxmox Provider (`bpg/proxmox`) 
- Proxmox API endpoint and token-based provider authentication validated before provisioning
- Disposable Smoke VM `9300` cloned and provcisioned from the workload-ready VM Template `9010` (created in Phase 04 - Proxmox VM Baseline) 
- Proxmox node `sd-178532`, storage `vmdata`, and private VM network model reused from the proven Proxmox baseline
- Cloud-Init used for guest initialization and static smoke-VM networking (to inject guest initialization values such as the `ubuntu` user, DNS, gateway, and static smoke-VM IP `10.10.10.30/24`)
- Terraform plan/apply/destroy lifecycle completed successfully (`init`, `validate`, `plan`, `apply`, Proxmox host-side verification to confirm the created VM, guest reachability check, and `destroy` to remove the disposable VM again)
- Live K3s target VM `9200` remained unmanaged and untouched to protect Live Environmenst `dev` + `prod`
- Terraform provider dependencies included in Dependabot scope
- Terraform-related Makefile helpers added for repeatable local execution (for Terraform init, validate, plan, apply, and destroy)

### Phase 09 - Disaster Recovery & Rollback Readiness

- K8s Namespace Backup Helper implemented (`scripts/dr/backup-k8s-namespace.sh`) to create local disaster-recovery backup snapshots for selected live Sock Shop namespaces on the remote target: `sock-shop-dev` (default) or `sock-shop-prod`. 
- Creates a unique, timestamped directory per run:
~~~bash
.
├── backups
│   ├── sock-shop-dev_20260427T203209Z
│   │   ├── db
│   │   │   ├── backup-report.txt
│   │   │   ├── carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
│   │   │   ├── orders-db_orders-db-944d776bc-hwgqt.archive.gz
│   │   │   └── user-db_user-db-7bd86cdcd-xwm7b.archive.gz
│   │   ├── k8s
│   │   │   ├── all-resources-wide.txt
│   │   │   ├── configmaps.yaml
│   │   │   ├── deployments.yaml
│   │   │   ├── ingress.yaml
│   │   │   ├── namespace.yaml
│   │   │   ├── persistent-volumes-wide.txt
│   │   │   ├── pods.yaml
│   │   │   ├── pvc.yaml
│   │   │   ├── secrets-metadata.txt
│   │   │   └── services.y
...
~~~

- Backup artifacts include the remote Kubernetes namespace state, resource snapshots, Secret metadata only (Secret values excluded), and database backup reports
- Mongo-compatible data-store dumps created where `mongodump` is available
- Representative `user-db` dump restored into a temporary local MongoDB container and queried successfully + comparison of users-db-dump state vs users-db-live state successfull (schema + collections count parity verified)  
- Pod-level recovery proven by deleting a live `front-end` dev pod and validating auto-recreation by Kubernetes 
- Live smoke checks passed after recovery
- Kubernetes rollback path documented for future bad-release scenarios without forcing an artificial bad release



---



## Terraform communication model

~~~text
          Terraform configuration 
    (provider.tf, variables.tf, main.tf)
                    |
                    | Declares desired infrastructure state:
                    | Proxmox Smoke VM 9300
                    v
               Terraform CLI
                    |
                    | bpg/proxmox (Terraform Proxmox Provider)
                    | HTTPS API request to Proxmox :8006
                    | Token-based Proxmox API authentication
                    v
              Proxmox VE API
                    |
                    | Clone / configure / start / destroy VM
                    v
          Disposable Smoke VM 9300
                    |
                    | Cloud-Init guest initialization
                    v
              Ubuntu guest OS
~~~

The infrastructure provisioning flow relies on **declarative API communication**:

* **Provider Communication:** Terraform communicates with the Proxmox hypervisor through the Terraform Proxmox Provider `bpg/proxmox`, sending HTTPS API requests to the Proxmox VE API to provision the desired infrastructure state declared in the configuration.
* **Proxmox Execution:** Proxmox translates that desired state into physical VM lifecycle actions to fulfill the request:
  * Clone VM `9300` from the workload-ready template `9010`.
  * Apply the VM hardware and network configuration defined in Terraform.
  * Attach Cloud-Init initialization data for the first boot of the new guest VM.
  * Start the VM.
  * Later: Destroy the VM again.

### Target Resource Definition

The Terraform resource created in this baseline is a single VM object:

| Attribute | Configuration Value |
| :--- | :--- |
| **Terraform Resource** | `proxmox_virtual_environment_vm.smoke_vm` |
| **Target VM ID** | `9300` |
| **VM Name** | `ubuntu-2404-terraform-smoke-01` |
| **Clone Source** | Workload-ready VM template `9010` |
| **Storage Pool** | `vmdata` |
| **Network Bridge** | `vmbr1` |
| **IP Address** | `10.10.10.30/24` |
| **Gateway** | `10.10.10.1` |
| **DNS Server** | `1.1.1.1` |
| **Preserved Live Target** | VM `9200` *(Intentionally bypassed and unaffected)* |

---

### Proxmox authentication model

In this baseline implementation, Terraform authenticates against the Proxmox VE API using a temporary **Proxmox API token**.

The credential model is:

- **Token Generation:** A temporary Proxmox API token is created directly on the Proxmox host to grant automation access.
- **Environment Variable Injection:** Terraform receives the API credentials and the temporary Cloud-Init password locally through `TF_VAR_...` environment variables. They are neither saved locally nor committed to Git.
- **API Authentication:** The Terraform provider uses the injected token to securely authenticate its HTTPS requests against the Proxmox API.
- **Post-Proof Revocation:** After the proof cycle is complete, the API access token is destroyed again on the Proxmox host.

### Secret Management Strategy

The repository stores the reusable Terraform configuration, but not the actual Proxmox API secret. Local Terraform state, plans, .tfvars, provider cache, and secret input files are explicitly excluded through .gitignore. This keeps the IaC proof reproducible without leaking credentials.

After the proof cycle completed, the Proxmox API access was destroyed again on Proxmox.

> **Security Note (Future Scope):**
>
> For this initial IaC proof cycle, local credential handling via environment variables is sufficient: : the reusable Terraform configuration is committed, while the real Proxmox API token and temporary Cloud-Init password stay outside Git. 
>
> If Terraform is later expanded to manage long-lived target infrastructure, this should be replaced by a stronger secret-management approach (GitHub Actions secrets, SOPS, Vault, or another dedicated secret store).

### Provisioning lifecycle

The Phase 08 IaC proof performs the following provisioning lifecycle. It starts from the already proven workload-ready Proxmox VM Template `9010` with the goal to provision a new VM `9300` via Terraform: 

1. **Confirm Initial State:** Audit the existing Proxmox baseline and confirm:
   - VM Template `9010` exists as the workload-ready source template.
   - VM `9200` is the healthy live target for `dev` and `prod`.
   - VM ID `9300` is available for the Terraform Smoke VM.
2. **Define Terraform Workspace:** Create an isolated local Terraform workspace and define the configuration for a disposable Smoke VM `9300`:
   - `provider.tf` configures the `bpg/proxmox` provider.
   - `variables.tf` defines the Proxmox endpoint, token input, VM IDs, node/storage/network values, and Cloud-Init inputs.
   - `main.tf` defines the disposable VM resource `proxmox_virtual_environment_vm.smoke_vm`.
3. **Configure API Access:** Create a temporary Proxmox API access token and export the Proxmox endpoint, API token, and temporary Cloud-Init password through local `TF_VAR_...` environment variables. 
4. **Execute Terraform Workflow:** Run the core Terraform commands to apply the plan and create VM `9300`:
   - `terraform init`
   - `terraform validate`
   - `terraform plan -out=tfplan`
   - `terraform apply tfplan`
5. **Verify VM Provisioning:** Verify on the Proxmox host (`qm list --full` and `qm config 9300`) that VM `9300` exists and was created from the intended template path.
6. **Destroy Smoke VM:** Remove the disposable VM with `terraform destroy`.
7. **Confirm Final State:** Audit the environment to ensure no side effects occurred:
   - VM Template `9010` still exists as the workload-ready source template.
   - VM `9200` was unaffected and is still the healthy live target for `dev` and `prod`.
   - Disposable VM `9300` is completely removed after the proof.

This proves a complete and reproducible IaC lifecycle for Proxmox VM provisioning—while keeping the live `dev` / `prod` target platform safe.

## 🚥 Traffic Generator (Observability Helper)

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

### Observability Make Helper Targets

The repository exposes a few thin Makefile helpers for the most common observability checks and traffic-generation flows (introduced in Phase 06):

- `make p06-monitoring-status`
- `make p06-grafana-port-forward`
- `make p06-prometheus-port-forward`
- `make p06-traffic-dev-preset`
- `make p06-traffic-dev-live`
- `make p06-traffic-prod-preset`
- `make p06-traffic-prod-live`

### 🛡️ Phase 07 Testing & Security Helper Targets

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

## 🏗️ Architecture Snapshot

The current architecture is a phase-built DevOps delivery path around the Sock Shop microservices application:

- **Application:** Sock Shop microservices
- **Local baseline runtimes:** Docker Compose and local K3s
- **Kubernetes deployment model:** Raw manifests plus environment-specific Kustomize overlays
- **CI/CD platform:** GitHub Actions
- **Container registry:** GHCR
- **Historical CI smoke target:** `kind` during the Phase 03 CI/CD baseline
- **Long-lived target platform:** Proxmox VM `9200` running single-node K3s
- **Environment model:** `sock-shop-dev` and `sock-shop-prod` namespaces on the same cluster
- **Ingress and public edge:** Traefik behind Cloudflare Tunnel
- **Private access path:** Tailscale for operator and CI access to the Kubernetes API
- **Observability:** Dedicated `monitoring` namespace with `kube-prometheus-stack`, Prometheus, and Grafana
- **Testing and security:** Ruby/Bash/Python validation tooling, Playwright smoke tests, Trivy scans, Dependabot, and protected PR checks
- **Infrastructure as Code:** Terraform Proxmox smoke-VM baseline using template `9010` and disposable VM `9300`
- **Disaster recovery:** Kubernetes state backup, Mongo-compatible dump validation, pod recovery proof, and rollback-readiness documentation

**Current architecture result:** The project now proves delivery, operations, observability, testing, security, IaC, and DR readiness against a long-lived Proxmox-backed K3s target platform, rather than only demonstrating isolated local or CI/CD mechanics.

---

## 📚 Documentation  

### Project Hub & Cross-Phase Records

* 🗂️ **Project Docs Index:** [project-docs/INDEX.md](project-docs/INDEX.md)
* 🗺️ **Project Roadmap & Planning:** [project-docs/ROADMAP.md](project-docs/ROADMAP.md)
* ⚖️ **Summarized Project Decisions:** [project-docs/DECISIONS.md](project-docs/DECISIONS.md)
* 🐛 **Project Debug & Incident Log:** [project-docs/DEBUG-LOG.md](project-docs/DEBUG-LOG.md)   

### 🏛️ Architecture Decision Records (ADRs)

Project-wide standards and long-lived decisions live in the `adr/` directory:

* **ADR-0001:** Git conventions (workflow, branching, commits) — [View Record](adr/%5B2026-03-17%5D%20ADR-0001%20--%20Git-Conventions.md)
* **ADR-0002:** Documentation system and locations — [View Record](adr/%5B2026-03-18%5D%20ADR-0002%20--%20Docs-System.md)

### Phase Docs

All implementation phase related project documentation is organized by phase under 

  **`project-docs/<phase-folder>/`**. 

Each phase folder contains at least an `IMPLEMNATION.md` - and depending on the complexity of the implementation phase, additional companion docs:

- `IMPLEMENTATION.md`
- `SETUP.md`
- `DISCOVERY.md`
- `RUNBOOK.md`
- `DECISIONS.md`
- `evidence/`


## 📁 Current Verified Scope

The repository currently contains proven work across the following phases. *(Note: This is a moving summary, not the final shape of the project).*

* **Phase 00 — Compose Baseline**
    * **Scope:** Repository reconnaissance, local Docker Compose baseline, and host-port conflict workaround.
    * **Docs: [Implementation](project-docs/00-compose-baseline/IMPLEMENTATION.md) • [Runbook](project-docs/00-compose-baseline/RUNBOOK.md)**  

* **Phase 01 — Port-Based Kubernetes Baseline**
    * **Scope:** Clean local K3s deployment via upstream manifests with the storefront reachable via NodePort `30001`.
    * **Docs: [Implementation](project-docs/01-nodeport-baseline/IMPLEMENTATION.md) • [Runbook](project-docs/01-nodeport-baseline/RUNBOOK.md)**  

* **Phase 02 — Host-Based Ingress Baseline**
    * **Scope:** Local Traefik ingress routing for `sockshop.local` (with NodePort retained as fallback).
    * **Docs: [Implementation](project-docs/02-ingress-baseline/IMPLEMENTATION.md) • [Runbook](project-docs/02-ingress-baseline/RUNBOOK.md)**  

* **Phase 03 — CI/CD Baseline**
    * **Scope:** GitHub Actions delivery workflow, Kustomize overlays for `dev`/`prod`, GHCR publishing for the `healthcheck` image, automated `dev` deployments, and approval-gated `prod` deployments.
    * **Docs: [Setup](project-docs/03-ci-cd-baseline/SETUP.md) • [Implementation](project-docs/03-ci-cd-baseline/IMPLEMENTATION.md) • [Runbook](project-docs/03-ci-cd-baseline/RUNBOOK.md) • [Decisions](project-docs/03-ci-cd-baseline/DECISIONS.md)**  

* **Phase 04 — Proxmox VM Baseline**
    * **Scope:** Target host inspected, reusable Ubuntu 24.04 Cloud-Init template (`9000`), reference Smoke VM (`9100`), host-side and guest-side verification completed, and workload-ready variant (`9010`) finalized with private guest bridge `vmbr1`, stable IP/DNS, outbound reachability, and guest-agent capability.
    * **Docs: [Discovery](project-docs/04-proxmox-vm-baseline/DISCOVERY.md) • [Setup](project-docs/04-proxmox-vm-baseline/SETUP.md) • [Implementation](project-docs/04-proxmox-vm-baseline/IMPLEMENTATION.md) • [Runbook](project-docs/04-proxmox-vm-baseline/RUNBOOK.md) • [Decisions](project-docs/04-proxmox-vm-baseline/DECISIONS.md)**

* **Phase 05 — Proxmox Target Delivery**
    * **Scope:** Real target VM `9200` cloned from `9010`, single-node K3s control plane, MongoDB compatibility fix, environment-separated `dev`/`prod` target deployments via Traefik, Tailscale private access, Cloudflare Tunnel public HTTPS, and dedicated CI/CD delivery workflows.
    * **Docs: [Setup](project-docs/05-proxmox-target-delivery/SETUP.md) • [Implementation](project-docs/05-proxmox-target-delivery/IMPLEMENTATION.md) • [Runbook](project-docs/05-proxmox-target-delivery/RUNBOOK.md) • [Decisions](project-docs/05-proxmox-target-delivery/DECISIONS.md)**\
    **Detailed Subphase Guides: [05-A](project-docs/05-proxmox-target-delivery/implementation/PHASE-05-A.md) • [05-B](project-docs/05-proxmox-target-delivery/implementation/PHASE-05-B.md) • [05-C](project-docs/05-proxmox-target-delivery/implementation/PHASE-05-C.md) • [05-D](project-docs/05-proxmox-target-delivery/implementation/PHASE-05-D.md)**

* **Phase 06 — Observability & Health**
    * **Scope:** Dedicated `monitoring` namespace, Helm-based `kube-prometheus-stack` baseline, private Grafana/Prometheus access via port-forward, namespace-level visibility for `prod`, healthy Prometheus target checks, and implementation of a custom Bash traffic-generator script.
    * **Docs: [Implementation](project-docs/06-observability/IMPLEMENTATION.md) • [Runbook](project-docs/06-observability/RUNBOOK.md) • [Decisions](project-docs/06-observability/DECISIONS.md)**

* **Phase 07 — Security Testing**
    * **Scope:** Refactored Ruby `healthcheck` and Bash traffic generators with unit/CLI tests, Python `/catalogue` contract tests, Playwright browser smoke tests, Trivy filesystem/image scans, Dependabot integration, and deterministic PR/live-smoke workflow gates.
    * **Docs:** **[Setup](project-docs/07-security-testing/SETUP.md) • [Implementation](project-docs/07-security-testing/IMPLEMENTATION.md) • [Runbook](project-docs/07-security-testing/RUNBOOK.md) • [Decisions](project-docs/07-security-testing/DECISIONS.md)**\
    **Detailed Subphase Guides: [07-A](project-docs/07-security-testing/implementation/PHASE-07-A.md) • [07-B](project-docs/07-security-testing/implementation/PHASE-07-B.md) • [07-C](project-docs/07-security-testing/implementation/PHASE-07-C.md) • [07-D](project-docs/07-security-testing/implementation/PHASE-07-D.md)**

* **Phase 08 — Proxmox IaC Baseline** *(Functionally implemented; docs polish in progress)*
    * **Scope:** Terraform workspace established under `infra/terraform/proxmox-smoke-vm/` for disposable Proxmox smoke-VM proof. VM `9300` provisioned from workload-ready template `9010`, Proxmox API authentication validated, Terraform plan/apply/destroy lifecycle verified, live VM `9200` remained untouched, and Makefile helpers added.
    * **Docs: [Implementation](project-docs/08-proxmox-iac/IMPLEMENTATION.md)**

* **Phase 09 — DR & Rollback Readiness** *(Functionally implemented; docs polish in progress)*
    * **Scope:** Target DR backup helper deployed for `sock-shop-dev` and `sock-shop-prod`, Kubernetes namespace state exported, Secret metadata recorded without exporting Secret values, Mongo-compatible data-store dumps validated through a temporary restore check, `front-end` dev pod recovery proven, live smoke checks passed after recovery, and rollback paths documented.
    * **Docs: [Implementation](project-docs/09-dr-rollback/IMPLEMENTATION.md)**

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
