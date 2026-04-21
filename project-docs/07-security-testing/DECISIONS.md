# Decision Log — Phase 07 (Security & Testing): ...

TODO: Adjust to Phase 07

> ## About
> This document is the **phase-local decision log** for **Phase 07 (Secutrity & Testing)**.
> It captures the full decision story for this phase without overloading the shorter project-wide summary in **[project-docs/DECISIONS.md](../DECISIONS.md)**.
> For the full chronological build diary, see: **[IMPLEMENTATION.md](IMPLEMENTATION.md)**.
> For the short rerun flow, see: **[RUNBOOK.md](RUNBOOK.md)**.
> For cross-phase incident and anomaly tracking, see: **[../DEBUG-LOG.md](../DEBUG-LOG.md)**.

---

## Index

- [**Quick recap (Phase 07)**](#quick-recap-phase-06)
  - [**Starting point: ...**](#starting-point-the-project-needed-a-first-useful-monitoring-layer-on-the-real-target)
  - [**Obstacle: ..**](#obstacle-existing-repository-monitoring-material-was-not-the-right-baseline-for-phase-06)
  - [**Chosen path: ...**](#chosen-path-use-the-well-maintained-kube-prometheus-stack-in-a-dedicated-monitoring-namespace---instead-of-reviving-older-repository-monitoring-material)
  - [**Scope ...: ...**](#scope-of-the-first-rollout-small-private-only-and-evidence-oriented)
  - [**Verified result of Phase 07**](#verified-result-of-phase-07)
- [**Key Phase Decisions**](#key-phase-decisions)
  - [**P07-D01 — ...**](#p06-d01--observability-baseline--maintained-kube-prometheus-stack-in-dedicated-monitoring-namespace)
  - [**Next-step implications**](#next-step-implications)
---

## Quick recap of Phase 06

Phase 07 established the working

testing & security 

on top of the real Proxmox-based K3s target platform proven in Phase 05 and the observability / monitoring ... in Phase 06.

### Starting point: The project needed ...

Status: After Phase 06, the project already had:

- A real Proxmox-backed target VM
- A working single-node K3s control plane
- Namespace-based `dev` / `prod` application delivery 
- Private operator access and public application exposure
- Observability ....

The next logical capability was a working **securtity & testing layer **. The project could already deploy and expose the application, but it **still lacked an operational visibility layer** for **checking cluster health, workload behavior, and monitoring health on the live target**. 

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

### P07-D01 — Test scope = prioritize repo-owned helper code plus one small Python QA utility layer

- **Decision:** Build the first Phase 07 test scope primarily around repo-owned code surfaces and one small project-owned Python QA utility module.
- **Why:** The project already contains owned and directly explainable code in:
  - `healthcheck/healthcheck.rb`
  - `scripts/observability/generate-sockshop-traffic.sh`
  A small Python QA utility module adds both a valuable QA addition and a relevant Python unit-test path without requiring invasive changes to the legacy upstream application services.
- **Proof:** Phase 07 identifies these files as the primary owned test targets and uses them as the basis for the first test layer.
- **Next-step impact:** The next steps can assess those helpers for current behavior and testability gaps before introducing targeted refactors and tests.

### P07-D02 — Assessment model = prove current helper behavior before refactoring test surfaces

- **Decision:** Assess the selected repo-owned helper scripts first in their current operational shape before changing their structure for automated testing.
- **Why:** Phase 07 should not refactor helper code blindly. The project first needs proof that the current scripts are functionally valid and clear identification of the specific structural traits that block clean automated testing.
- **Proof:** `healthcheck/healthcheck.rb` is proven locally and on the remote target cluster, while `generate-sockshop-traffic.sh` is assessed through syntax checks and controlled negative-path execution.
- **Next-step impact:** The following refactoring work can preserve known-good behavior instead of changing both structure and runtime contract at the same time.

### P07-D03 — Ruby refactor strategy = characterization-first refactoring for `healthcheck.rb`

- **Decision:** Refactor the repo-owned Ruby `healthcheck` helper using a characterization-first approach.
- **Why:** The helper already worked operationally, so the safer path was:
  - freeze the current CLI behavior first
  - introduce only the minimum structural changes needed for safe import and isolated testing
  - then add focused unit tests around the refactored logic
- **Proof:** `tests/ruby/test_healthcheck_cli.rb` locks down the external CLI behavior, while the refactored `HealthChecker` class supports direct unit testing through `tests/ruby/test_healthcheck.rb`.
- **Next-step impact:** Ruby helper changes can now proceed with a safer local edit-test cycle and reduced risk of breaking the executable contract.

### P07-D04 — Ruby helper shape = importable class plus execution guard

- **Decision:** Move the Ruby helper behind an importable `HealthChecker` class and protect direct execution with `if __FILE__ == $0`.
- **Why:** The original top-level execution model was awkward for framework-driven testing because option parsing, runtime flow, and process exit all happened immediately when the file was loaded.
- **Proof:** `healthcheck/healthcheck.rb` can now be required safely by the unit-test file without triggering a live run or uncontrolled process exit.
- **Next-step impact:** The Ruby helper becomes a stable test surface for both local development and later CI execution.

### P07-D05 — Stream model = separate machine data from human logs for chainability

- **Decision:** Separate machine-readable output and human-readable logs in the Ruby helper and the target-environment proof helper.
- **Why:** The previous output shape mixed informational logs with non-standard Ruby pretty-print output, which blocked safe chaining into tools such as `jq` and reduced automation-readiness.
- **Proof:** The Ruby helper now emits JSON to `stdout`, sends human-readable status messages to `stderr`, and the refactored target-environment proof helper preserves that clean output path through Bash, `kubectl`, and `make`.
- **Next-step impact:** The helper is now ready for later pipeline integration, machine parsing, and chained validation steps.

### P07-D06 — Ruby test model = keep CLI characterization tests and unit tests separate

- **Decision:** Split the Ruby test surface into two complementary layers:
  - CLI characterization tests
  - unit tests
- **Why:** These two layers protect different things:
  - the CLI tests protect the external executable contract
  - the unit tests protect the refactored internal logic
- **Proof:** `tests/ruby/test_healthcheck_cli.rb` verifies process-level behavior via `Open3`, while `tests/ruby/test_healthcheck.rb` verifies parsing, aggregation, failure handling, delay execution, and empty-payload hardening in isolation.
- **Next-step impact:** The Ruby helper now has a stronger and more explainable test story for mentors, reviewers, and later CI quality gates.

### P07-D07 — Bash helper shape = move runtime flow behind `main()` and protect it with a Bash execution guard

- **Decision:** Move the repo-owned Bash observability helper behind `main()` and add a Bash execution guard so the file can be sourced safely by tests without triggering prompt handling or the long-running traffic loop.
- **Why:** The original file shape tied helper loading and runtime start together, which blocked clean automated testing of function-level logic.
- **Proof:** `generate-sockshop-traffic.sh` can now be sourced safely by `tests/bash/test_generate_sockshop_traffic.sh`, while the preserved invalid-input CLI checks still behave as expected during direct execution.
- **Next-step impact:** The Bash helper becomes a stable owned test surface for later CI integration and further Phase 07 Bash-side quality work.

### P07-D08 — Bash test model = use a dependency-free native Bash test harness for the first Bash test layer

- **Decision:** Implement the first automated Bash test layer as a plain native Bash test harness instead of introducing an external Bash testing framework.
- **Why:** Phase 07 needs a small, fast, and locally runnable Bash test path without adding another tool dependency first. A native Bash test file is sufficient here because the initial scope is intentionally narrow:
  - preserve key CLI error behavior
  - verify a few deterministic helper functions after safe sourcing
- **Proof:** `tests/bash/test_generate_sockshop_traffic.sh` runs successfully with plain `bash` and verifies both:
  - direct CLI invalid-input behavior
  - function-level helper logic after sourcing
- **Next-step impact:** The Bash helper now has a lightweight test path that is easy to run locally and easy to integrate into CI. If the Bash test surface grows later, a dedicated Bash test framework can still be introduced from a working baseline.

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