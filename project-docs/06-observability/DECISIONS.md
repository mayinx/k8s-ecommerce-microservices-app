# Decision Log — Phase 06 (Observability & Health): kube-prometheus-stack monitoring baseline on the Proxmox-backed target cluster

> ## About
> This document is the **phase-local decision log** for **Phase 06 (Observability & Health)**.
> It captures the full decision story for this phase without overloading the shorter project-wide summary in **[project-docs/DECISIONS.md](../DECISIONS.md)**.
> For the full chronological build diary, see: **[IMPLEMENTATION.md](IMPLEMENTATION.md)**.
> For the short rerun flow, see: **[RUNBOOK.md](RUNBOOK.md)**.
> For cross-phase incident and anomaly tracking, see: **[../DEBUG-LOG.md](../DEBUG-LOG.md)**.

---

## Index

- [**Quick recap (Phase 06)**](#quick-recap-phase-06)
  - [**Starting point: The project needed a first useful monitoring layer on the real target**](#starting-point-the-project-needed-a-first-useful-monitoring-layer-on-the-real-target)
  - [**Obstacle: Existing repository monitoring material was not the right baseline for Phase 06**](#obstacle-existing-repository-monitoring-material-was-not-the-right-baseline-for-phase-06)
  - [**Chosen path: Use the well maintained `kube-prometheus-stack` in a dedicated `monitoring` namespace - instead of reviving older repository monitoring material**](#chosen-path-use-the-well-maintained-kube-prometheus-stack-in-a-dedicated-monitoring-namespace---instead-of-reviving-older-repository-monitoring-material)
  - [**Constraint: Monitoring access should remain private-only in Phase 06**](#constraint-monitoring-access-should-remain-private-only-in-phase-06)
  - [**Chosen path: Private operator access via `kubectl port-forward` over the existing Tailnet-based kubeconfig path**](#chosen-path-private-operator-access-via-kubectl-port-forward-over-the-existing-tailnet-based-kubeconfig-path)
  - [**Obstacle: Grafana credential handling had to stay out of tracked repository files**](#obstacle-grafana-credential-handling-had-to-stay-out-of-tracked-repository-files)
  - [**Chosen path: Tracked non-secret values file + gitignored local Helm override + chart-managed Kubernetes Secret**](#chosen-path-tracked-non-secret-values-file--gitignored-local-helm-override--chart-managed-kubernetes-secret)
  - [**Scope of the first rollout: small, private-only, and evidence-oriented**](#scope-of-the-first-rollout-small-private-only-and-evidence-oriented)
  - [**Verified result of Phase 06**](#verified-result-of-phase-06)
- [**Key Phase Decisions**](#key-phase-decisions)
  - [**P06-D01 — Observability baseline = maintained `kube-prometheus-stack` in dedicated `monitoring` namespace**](#p06-d01--observability-baseline--maintained-kube-prometheus-stack-in-dedicated-monitoring-namespace)
  - [**P06-D02 — First rollout scope = intentionally small and private-only**](#p06-d02--first-rollout-scope--intentionally-small-and-private-only)
  - [**P06-D03 — Grafana credential handling = tracked non-secret values + gitignored local Helm override + chart-managed Kubernetes Secret**](#p06-d03--grafana-credential-handling--tracked-non-secret-values--gitignored-local-helm-override--chart-managed-kubernetes-secret)
  - [**P06-D04 — Access model = private `kubectl port-forward` over the existing Tailnet path instead of public monitoring exposure/ingress**](#p06-d04--access-model--private-kubectl-port-forward-over-the-existing-tailnet-path-instead-of-public-monitoring-exposureingress)
  - [**P06-D05 — Verification model = dashboard proof + scrape-target proof + light recent traffic**](#p06-d05--verification-model--dashboard-proof--scrape-target-proof--light-recent-traffic)
- [**Next-step implications**](#next-step-implications)
---

## Quick recap of Phase 06

Phase 06 established the working observability baseline on top of the real Proxmox-based K3s target platform proven in Phase 05.

### Starting point: The project needed a first useful monitoring layer on the real target

Status: After Phase 05, the project already had:

- A real Proxmox-backed target VM
- A working single-node K3s control plane
- Namespace-based `dev` / `prod` application delivery 
- Private operator access and public application exposure

So after Phase 05 had proven the target-delivery path, the next logical capability was a working **observability baseline**. The project could already deploy and expose the application, but it **still lacked an operational visibility layer** for **checking cluster health, workload behavior, and monitoring health on the live target**. 

This made **observability the next logical DevOps step**: 
- Before moving into Security/Testing, Terraform/IaC, or DR/Rollback, the project first **needs a way to inspect what the live platform is actually doing**.
- Otherwise, **later phases would partly operate without a clear visibility layer** for verifying cluster state, workload behavior, and monitoring health. 
- Phase 05 proved delivery, while **Phase 06 adds the inspectability needed to operate and validate the platform** more confidently in the following project phases.

Phase 06 therefore aimed to prove:

- The monitoring stack can run on the real target
- Grafana can be reached privately by the operator
- Prometheus can scrape the core monitoring targets successfully
- namespace-level workload data for `sock-shop-prod` can be visualized


### Obstacle: Existing repository monitoring material was not the right baseline for Phase 06

The repository already contains older monitoring-related material under:

- `deploy/kubernetes/manifests-monitoring/`
- `deploy/kubernetes/manifests-alerting/`

This older monitoring path was evaluated as a possible starting point, but proved to be **a weaker fit for Phase 06** because it is **more fragmented, more manual, and heavier to set up for a first observability baseline**. It is also **less aligned with the architecture direction already established in earlier phases**, which had already started moving the project away from **NodePort as a primary access model** and toward **Ingress-based and private-only access patterns**

The main reasons are:

- The **monitoring setup is split across multiple manual stages and many raw manifests** rather than one well maintained install unit - which requires additional manual preparation steps  
- The monitoring README also documents **NodePort-based exposure for Grafana and Prometheus**:
  - Prometheus on `31090`
  - Grafana on `31300`
- This is less aligned with the project’s current and later direction:
  - Phase 02 already moved the primary access model from **NodePort** to **host-based Ingress**
  - Phase 03 already removed fixed NodePort coupling from the CI/CD delivery path
  - Phase 06 monitoring is intended **private-only**, not via public NodePort exposure  
- the alerting setup is separated again and requires a manually created Kubernetes Secret `slack-hook-url`

### Chosen path: Use the well maintained `kube-prometheus-stack` in a dedicated `monitoring` namespace - instead of reviving older repository monitoring material

To provide the Phase 06 monitoring baseline, the project therefore used the well-maintained Helm chart **`kube-prometheus-stack`** and installed it into a dedicated `monitoring` namespace.

This provided a single integrated installation path for:

- **Prometheus** for metrics collection ("scraping") and querying
- **Grafana** for dashboards and visualization
- **Prometheus Operator** for managing the Prometheus stack inside Kubernetes
- **Supporting monitoring components** such as:
  - **kube-state-metrics** for exporting Kubernetes object/state metrics such as Deployments, Pods, and Nodes
  - **node-exporter** for exporting host-level machine metrics such as CPU, memory, filesystem, and network usage

**Reasoning:**

For Phase 06, the `kube-prometheus-stack` provides the **cleaner and faster route to a first working observability baseline**:
- it **bundles the core monitoring components into one integrated install** 
- it avoids a preliminary **legacy-monitoring cleanup/revival step** and **reduces the amount of manual assembly** required for the first observability rollout
- it fits the **private-only access model** planned for Phase 06, where Grafana and Prometheus are supposed to be accessible via `kubectl port-forward` instead of being exposed publicly through NodePorts
- it keeps the **monitoring stack isolated** in a dedicated **`monitoring` namespace**, separate from the application namespaces, **without requiring a separate manual namespace-creation step** outside the "monitoring install flow" (`helm upgrade --install...` handles this in one go).

### Constraint: Monitoring access should remain private-only in Phase 06

Phase 06 needs **operator access** to Grafana and Prometheus in order to prove that the monitoring baseline works on the live target. However, it does **not** require a publicly exposed monitoring surface yet, because Grafana and Prometheus are used here for **internal observability checks**. 

Public exposure in form of a public monitoring route is not a requirement at this stage and **would introduce additional scope/prep-work** that is not needed for the first baseline, such as:

- Monitoring-specific ingress exposure
- DNS and TLS setup for monitoring endpoints
- Additional access-control and hardening considerations for a public-facing monitoring surface

For the first observability baseline, the stronger requirement is therefore **private operator reachability**, not public exposure.

### Chosen path: Private operator access via `kubectl port-forward` over the existing Tailnet-based kubeconfig path

Phase 06 therefore uses **`kubectl port-forward`** over the already working **Tailnet-based kubeconfig path** instead of creating a public ingress route for Grafana or Prometheus.

This fits the phase better since `kubectl port-forward` provides a **temporary local access path from the workstation to an internal Kubernetes Service** without exposing the monitoring stack publicly. 

It also reuses the already proven operator-access path from earlier phases instead of introducing new exposure and hardening work just for the monitoring baseline.

### Obstacle: Grafana credential handling had to stay out of tracked repository files

Phase 06 needed a **secure Grafana login path** for the monitoring baseline, but an **admin password must not be committed** into repository-tracked files.

This created a **setup requirement**:

- The tracked **values file** had to **remain non-secret**
- The **Grafana password** still had to be **provided during Chart-installation/updates**
- The **resulting credential** (after install/updte) still had **to exist inside the cluster** in a Kubernetes-native form (Kubernetes Secret)

### Chosen path: Tracked non-secret values file + gitignored local Helm override + chart-managed Kubernetes Secret

Phase 06 therefore used:

- a **tracked values** file:
  - `deploy/kubernetes/observability/prometheus-values-minimal.yaml`
- a **gitignored local Helm secrets override** file:
  - `deploy/kubernetes/observability/prometheus-local.secrets.yaml`

The Helm chart then created the resulting Grafana credential dynamically inside the cluster as a Kubernetes Secret.

This kept the **repository-tracked configuration free of live credentials** while preserving a simple and reproducible install path for the first monitoring rollout.

### Scope of the first rollout: small, private-only, and evidence-oriented

The first rollout was intentionally kept narrow:

- Alertmanager disabled
- default alert rules disabled
- short Prometheus retention
- ephemeral storage
- conservative resource requests and limits
- private access via `kubectl port-forward`
- no public monitoring ingress
- no custom application telemetry yet

This made it possible to prove the first real observability baseline without immediately adding alert-routing, longer-term metric retention, or public monitoring exposure.

### Verified result of Phase 06

By the end of the phase, the project had proven:

- `kube-prometheus-stack` is installed successfully in `monitoring`
- the core monitoring workloads are running
- the Grafana admin credential is managed through the chart-created Kubernetes Secret
- Grafana is reachable privately via `kubectl port-forward`
- Prometheus is reachable privately via `kubectl port-forward`
- the Grafana dashboard `Kubernetes / Compute Resources / Namespace (Pods)` shows live namespace-level workload data for `sock-shop-prod`
- the Prometheus `/targets` page shows the core monitoring targets in the `UP` state

---

## Key Phase Decisions

### P06-D01 — Observability baseline = maintained `kube-prometheus-stack` in dedicated `monitoring` namespace

- **Decision:** Use the maintained **`kube-prometheus-stack`** Helm chart as the Phase 06 observability baseline and install it into the dedicated namespace `monitoring`
- **Why:** Phase 06 needs the fastest clean route to a first useful monitoring layer on the real target cluster, not a larger manual cleanup and rebuild of older repository monitoring material.
- **Why not the older repository monitoring path:** The existing monitoring-related material under:
  - `deploy/kubernetes/manifests-monitoring/`
  - `deploy/kubernetes/manifests-alerting/`
  is a weaker fit for Phase 06 because it is more fragmented, more manual, and more NodePort-oriented than needed for the first observability baseline. The monitoring README documents a multi-stage raw-manifest setup with separate Prometheus, Grafana, and dashboard-import steps, while the alerting setup is separated again and requires an additional manually created Kubernetes Secret. This requires additional manual preparation steps.
- **Why this chart:** `kube-prometheus-stack` provides a more integrated installation path for the first baseline by bundling the core monitoring components needed in this phase:
  - Prometheus Operator
  - Prometheus
  - Grafana
  - kube-state-metrics
  - node-exporter
- **Proof:** The Helm release `observability` is deployed successfully, the `monitoring` namespace exists, and the core monitoring workloads are running.
- **Next-step impact:** This establishes the first real operational visibility layer on the live target, so later observability extensions, Terraform/IaC, security/testing, and hardening work can build on a proven monitoring baseline instead of reopening tool selection.

### P06-D02 — First rollout scope = intentionally small and private-only

- **Decision:** Keep the first monitoring rollout intentionally small:
  - Alertmanager disabled
  - default alert rules disabled
  - short retention
  - ephemeral storage
  - conservative resource requests and limits
  - no public monitoring ingress
- **Why:** The phase goal is to establish a first useful monitoring layer, not yet a broader long-retention monitoring platform with alert-routing and public exposure.
- **Proof:** The tracked values file configures exactly that narrow scope in:
  - `deploy/kubernetes/observability/prometheus-values-minimal.yaml`
- **Next-step impact:** Later phases can extend the monitoring setup incrementally instead of carrying unnecessary early complexity.

### P06-D03 — Grafana credential handling = tracked non-secret values + gitignored local Helm override + chart-managed Kubernetes Secret

- **Decision:** Keep non-secret Helm values in the tracked baseline file, inject the Grafana admin password through a gitignored local Helm override file, and rely on the chart to create the resulting Kubernetes Secret.
- **Why:** The phase must avoid committing a live password into repository-tracked files, while still keeping the install path simple and reproducible.
- **Proof:** The install uses:
  - `deploy/kubernetes/observability/prometheus-values-minimal.yaml`
  - `deploy/kubernetes/observability/prometheus-local.secrets.yaml`
  and the resulting chart-managed Secret exists as:
  - `observability-grafana`
- **Next-step impact:** This establishes a practical secret-handling pattern for the monitoring baseline, while leaving broader project-wide secret management for the later security phase.

### P06-D04 — Access model = private `kubectl port-forward` over the existing Tailnet path instead of public monitoring exposure/ingress 

- **Decision:** Access Grafana and Prometheus privately through **`kubectl port-forward`** over the **already working Tailnet-based kubeconfig path**, instead of creating a public monitoring ingress route in Phase 06.
- **Why:** Phase 06 needs private operator access for monitoring proof, not a public monitoring surface with additional DNS, TLS, and hardening complexity. `kubectl port-forward` provides a **temporary local access path from the local workstation to the internal Kubernetes Service** without exposing the cluster publicly.
- **Proof:** Grafana and Prometheus are both reached successfully from the workstation through private local tunnels.
- **Next-step impact:** Monitoring remains private until a later phase justifies broader exposure or stronger access controls.

### P06-D05 — Verification model = dashboard proof + scrape-target proof + light recent traffic

- **Decision:** Count Phase 06 as successful only when the monitoring baseline is proven through:
  - successful stack deployment
  - private Grafana access
  - dashboard-based workload visibility
  - Prometheus scrape-target health
  - recent storefront traffic to make current activity visible
  - **Supporting helper introduced in this phase:** A small repository-side **Traffic Generator (Observability Helper)** was added to generate repeatable storefront traffic for observability checks. This improves rerunnability and creates a cleaner bridge between manual verification and later automation.
- **Why:** A running monitoring Pod set alone is not strong enough proof of useful observability.
- **Proof:** The Grafana namespace dashboard shows workload data for `sock-shop-prod`, recent storefront requests return successful HTTP responses, and Prometheus `/targets` shows the core monitoring targets as healthy.
- **Next-step impact:** Later observability work starts from a baseline that is already operationally proven both at the scrape layer and the dashboard layer.

---

## Next-step implications 

- Phase 06 establishes the first real observability layer on top of the Proxmox-based target cluster.
- The next major step regarding observability is not to reopen tool selection, but to extend the already proven baseline where useful.
- Later phases can now build on:
  - a running monitoring namespace
  - a proven Grafana access path
  - a proven Prometheus scrape path
  - a proven namespace-level dashboard proof
- Terraform work in the later IaC phase can codify this monitoring baseline instead of trying to invent it first.
- Security hardening can later evaluate whether monitoring should remain private-only or gain stronger controlled exposure.