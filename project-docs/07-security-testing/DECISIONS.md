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

### Step 1 - Phase entry decisions — scope, scaffold, and assessment strategy

#### P07-D01 — Test scope = Prioritize repo-owned helper code (Ruby + Bash), close the API-response schema-validation gap with a small Python QA utility, and reserve space for later browser-level validation (E2E)

- **Decision:** Build the first Phase 07 scope around the strongest repo-owned helper surfaces (**Ruby + Bash**) and explicitly add one small project-owned **Python QA utility** to cover the still-missing **API-response schema-validation** layer. Also reserve space for a later **browser-level validation layer (E2E)**, because API and helper checks alone do not prove that the deployed storefront actually renders correctly in a real browser.
- **Why:** The strongest owned executable test surfaces were already clear at the start of the phase in:
  - `healthcheck/healthcheck.rb`
  - `scripts/observability/generate-sockshop-traffic.sh`
  Those helpers already cover important quality layers, but **not the structural validity of downstream-relevant API responses**. The implementation of a corresponding Python QA layer will close this specific quality gap.  
- **Proof:** The initial test scope analysis and the resulting decision was based on the already existing repo-owned helper surfaces located in:
  - `healthcheck/healthcheck.rb`
  - `scripts/observability/generate-sockshop-traffic.sh`
  Their roles already showed that Phase 07 had coverage for **service health/reachability** and **observability traffic generation**, while still lacking a repo-owned layer for **API-response schema validation**.
- **Next-step impact:** The following steps first assess the owned helper surfaces in their current shape for testability and chainability, refactor those helpers accordingly and create corresponmding tests. Later steps then implement the Python layer as a targeted response to the identified gap instead of as an unrelated technology add-on.

#### P07-D02 — Assessment model = Prove current helper behavior before refactoring test surfaces

- **Decision:** Assess the selected repo-owned helper scripts first in their current operational shape before changing their structure for automated testing.
- **Why:** Phase 07 should not refactor helper code blindly. The project first needs proof that the current scripts are functionally valid and clear identification of the specific structural traits that block clean automated testing.
- **Proof:** `healthcheck/healthcheck.rb` is proven locally and on the remote target cluster, while `generate-sockshop-traffic.sh` is assessed through syntax checks and controlled negative-path execution.
- **Next-step impact:** The following refactoring work can preserve known-good behavior instead of changing both structure and runtime contract at the same time.

### Steps 2–3 — Ruby healthcheck refactor, chainability, and test model

#### P07-D03 — Ruby refactor strategy = Characterization-first refactoring for `healthcheck.rb`

- **Decision:** Refactor the repo-owned Ruby `healthcheck` helper using a characterization-first approach.
- **Why:** The helper already worked operationally, so the safer path was:
  - freeze the current CLI behavior first
  - introduce only the minimum structural changes needed for safe import and isolated testing
  - then add focused unit tests around the refactored logic
- **Proof:** `tests/ruby/test_healthcheck_cli.rb` locks down the external CLI behavior, while the refactored `HealthChecker` class supports direct unit testing through `tests/ruby/test_healthcheck.rb`.
- **Next-step impact:** Ruby helper changes can now proceed with a safer local edit-test cycle and reduced risk of breaking the executable contract.

#### P07-D04 — Ruby helper shape = Importable class plus execution guard

- **Decision:** Move the Ruby helper behind an importable `HealthChecker` class and protect direct execution with `if __FILE__ == $0`.
- **Why:** The original top-level execution model was awkward for framework-driven testing because option parsing, runtime flow, and process exit all happened immediately when the file was loaded.
- **Proof:** `healthcheck/healthcheck.rb` can now be required safely by the unit-test file without triggering a live run or uncontrolled process exit.
- **Next-step impact:** The Ruby helper becomes a stable test surface for both local development and later CI execution.

#### P07-D05 — Stream model = Separate machine data from human logs for chainability

- **Decision:** Separate machine-readable output and human-readable logs in the Ruby helper and the target-environment proof helper.
- **Why:** The previous output shape mixed informational logs with non-standard Ruby pretty-print output, which blocked safe chaining into tools such as `jq` and reduced automation-readiness.
- **Proof:** The Ruby helper now emits JSON to `stdout`, sends human-readable status messages to `stderr`, and the refactored target-environment proof helper preserves that clean output path through Bash, `kubectl`, and `make`.
- **Next-step impact:** The helper is now ready for later pipeline integration, machine parsing, and chained validation steps.

#### P07-D06 — Ruby test model = Keep CLI characterization tests and unit tests separate

- **Decision:** Split the Ruby test surface into two complementary layers:
  - CLI characterization tests
  - unit tests
- **Why:** These two layers protect different things:
  - the CLI tests protect the external executable contract
  - the unit tests protect the refactored internal logic
- **Proof:** `tests/ruby/test_healthcheck_cli.rb` verifies process-level behavior via `Open3`, while `tests/ruby/test_healthcheck.rb` verifies parsing, aggregation, failure handling, delay execution, and empty-payload hardening in isolation.
- **Next-step impact:** The Ruby helper now has a stronger and more explainable test story for mentors, reviewers, and later CI quality gates.

### Step 4 — Bash Observability Helper refactor and test model

#### P07-D07 — Bash helper shape = Move runtime flow behind `main()` and protect it with a Bash execution guard

- **Decision:** Move the repo-owned Bash observability helper behind `main()` and add a Bash execution guard so the file can be sourced safely by tests without triggering prompt handling or the long-running traffic loop.
- **Why:** The original file shape tied helper loading and runtime start together, which blocked clean automated testing of function-level logic.
- **Proof:** `generate-sockshop-traffic.sh` can now be sourced safely by `tests/bash/test_generate_sockshop_traffic.sh`, while the preserved invalid-input CLI checks still behave as expected during direct execution.
- **Next-step impact:** The Bash helper becomes a stable owned test surface for later CI integration and further Phase 07 Bash-side quality work.

#### P07-D08 — Bash test model = Use a dependency-free native Bash test harness for the first Bash test layer

- **Decision:** Implement the first automated Bash test layer as a plain native Bash test harness instead of introducing an external Bash testing framework.
- **Why:** Phase 07 needs a small, fast, and locally runnable Bash test path without adding another tool dependency first. A native Bash test file is sufficient here because the initial scope is intentionally narrow:
  - preserve key CLI error behavior
  - verify a few deterministic helper functions after safe sourcing
- **Proof:** `tests/bash/test_generate_sockshop_traffic.sh` runs successfully with plain `bash` and verifies both:
  - direct CLI invalid-input behavior
  - function-level helper logic after sourcing
- **Next-step impact:** The Bash helper now has a lightweight test path that is easy to run locally and easy to integrate into CI. If the Bash test surface grows later, a dedicated Bash test framework can still be introduced from a working baseline.

### Steps 5–6 — Python QA module (Contract Guard), live contract API smoke tests

### Steps 5–6 — Python QA module (API contract-guard) and live API contract-guard smoke tests

#### P07-D09 — Python contract model = Use a consumer-side compatibility guard instead of a provider-authoritative schema

- **Decision:** Implement the Phase 07 Python schema as a consumer-side compatibility guard for catalogue responses, not as the canonical provider specification of the upstream API.
- **Why:** The project does not own the upstream service contract formally. The Python layer should therefore protect only the minimum response shape this project depends on, without claiming ownership of the entire provider schema.
- **Proof:** `tests/python/sockshop_contract_guard.py` validates a small subset-based schema focused on required consumer fields such as `id`, `name`, and `price`, while still tolerating additional upstream fields.
- **Next-step impact:** Later live API contract checks can reuse the same guard.

#### P07-D10 — Python test scope = Keep the first contract-guard layer local and deterministic

- **Decision:** Keep the first Python contract-guard step fully local and deterministic instead of coupling it immediately to live HTTP requests or cluster-internal endpoints.
- **Why:** Phase 07 first needs a reusable and reliable Python QA utility whose correctness can be proven independently of network reachability, cluster DNS, or deployment timing.
- **Proof:** `tests/python/test_contract_guard.py` validates the contract logic entirely with local sample payloads and passes without any live environment dependency.
- **Next-step impact:** A later step can reuse the same contract guard against a live fetched catalogue response, while Step 5 already provides a stable Python foundation.

#### P07-D11 — Reference consumer and schema scope = Use `front-end` as the consumer baseline and keep the first contract intentionally narrow

- **Decision:** Use the `front-end` service as the reference downstream consumer for the initial catalogue compatibility baseline, and limit the first strict schema to the functional-core fields `id`, `name`, and `price`.
- **Why:** In this project, the `front-end` service is the most immediate downstream consumer of catalogue data. At the same time, the `front-end` implementation is not directly analyzed in this step, so the first schema must remain narrow and defensible: strict enough to catch likely breaking changes, but tolerant enough to avoid unnecessary pipeline failures from non-breaking metadata or cosmetic content changes.
- **Proof:** The Step 5 compatibility baseline explicitly selects `id`, `name`, and `price` as the functional core, while intentionally leaving `description`, `imageUrl`, `count`, and `tag` outside strict validation.
- **Next-step impact:** The first Python contract guard provides a high-signal baseline for downstream compatibility and can later be tightened deliberately if additional hard dependencies of the `front-end` service become clear.

#### P07-D12 — Live Python contract API smoke test = Reuse the proven Step 5 contract guard instead of creating a second validation path

- **Decision:** Reuse the existing Step 5 Python contract guard for the first live catalogue API smoke test instead of implementing separate live-only validation logic.
- **Why:** The local contract logic is already proven and deterministic. Reusing it against the live API keeps the validation model consistent and avoids maintaining two different contract-check implementations.
- **Proof:** `tests/python/test_contract_guard_live.py` fetches the live `/catalogue` response and passes the parsed payload directly into `validate_catalogue_contract(...)`.
- **Next-step impact:** The Python QA layer now spans both deterministic local validation and explicit live environment smoke validation, while still keeping one shared contract-check implementation.

#### P07-D13 — Live contract smoke = Keep environment-facing validation separate from the default deterministic Phase 07 test loop

- **Decision:** Keep the live catalogue contract smoke test out of the default `p07-tests` aggregate target.
- **Why:** The Phase 07 default local loop should remain stable and deterministic. The live smoke path is intentionally environment-dependent and must therefore remain an explicit opt-in validation step.
- **Proof:** The new Make targets expose `p07-contract-guard-live-dev`, `p07-contract-guard-live-prod`, and `p07-contract-guard-live-local` separately, while `p07-tests` continues to cover the deterministic Ruby, Bash, and local Python layers only.
- **Next-step impact:** Phase 07 preserves a clean distinction between local deterministic validation and live smoke validation, reducing noise and avoiding unnecessary flakiness in the default local test run.

#### P07-D14 — Live routing default = Use the public `dev` edge URL with environment-variable override

- **Decision:** Use the public `dev` edge URL as the default live contract-smoke target, while keeping the base URL configurable through `SOCKSHOP_CONTRACT_BASE_URL`.
- **Why:** This makes the first live smoke path easy to execute from the workstation and from CI without requiring an in-cluster execution context or cluster-internal DNS assumptions.
- **Proof:** `test_contract_guard_live.py` defaults to `https://dev-sockshop.cdco.dev`, and the Make targets allow `dev`, `prod`, or local port-forward execution by overriding the base URL.
- **Next-step impact:** The live Python contract smoke check remains easy to reuse across environments while keeping the validation logic unchanged.

### Step 7 — Playwright browser smoke tests

#### P07-D15 — E2E scope = Start with a tiny Chromium-only browser smoke layer instead of broad end-to-end coverage

- **Decision:** Introduce the first browser-based validation in Phase 07 as a minimal Chromium-only Playwright smoke layer against the live `dev` storefront.
- **Why:** Time is tight, and the immediate goal is a real browser-path proof rather than broad user-flow automation or cross-browser regression coverage.
- **Proof:** The Playwright setup adds one small browser suite that verifies storefront load success, key landing-page content, and at least one rendered catalogue image.
- **Next-step impact:** Phase 07 now includes a real browser-based smoke signal while keeping the E2E layer small enough for later CI integration.

#### P07-D16 — Playwright project placement = Keep the first browser smoke tooling nested under `tests/e2e`

- **Decision:** Keep the first Playwright setup in a nested `tests/e2e` project instead of introducing a root-level Node.js project.
- **Why:** The Phase 07 browser-smoke layer is small and phase-local. Keeping the Node.js tooling nested avoids unnecessary project-root noise while the Makefile hides the nested-path complexity during normal usage.
- **Proof:** `package.json`, `playwright.config.js`, and `smoke.spec.js` are placed under `tests/e2e`, while the Makefile exposes repo-root helper targets for normal reruns.
- **Next-step impact:** The E2E layer stays isolated and easy to remove, expand, or later consolidate if broader Node.js tooling becomes necessary.

#### P07-D17 — Browser smoke placement = Keep Playwright in the explicit live aggregate path, not in the deterministic default loop

- **Decision:** Keep the Playwright smoke layer in `p07-tests-live` rather than adding it to `p07-tests`.
- **Why:** Browser-path validation depends on the deployed target and is therefore environment-dependent by design.
- **Proof:** The Makefile integrates the Playwright smoke target into `p07-tests-live`, while `p07-tests` remains limited to deterministic local checks.
- **Next-step impact:** The overall Phase 07 signal model remains clean:
  - deterministic local checks stay deterministic
  - live/browser smoke checks stay explicit
 
#### P07-D18 — Playwright execution model = Make the browser smoke layer CI-aware in both config and Make targets

- **Decision:** Make the first Playwright browser smoke layer explicitly CI-aware in both `playwright.config.js` and the Phase 07 Make targets.
- **Why:** The browser smoke path should run predictably in both local and CI environments without requiring separate test files or ad hoc command variants. This required coordinated handling of `CI`, retries, worker count, failure artifacts, and target execution flow.
- **Proof:** `playwright.config.js` reacts to `process.env.CI` for `forbidOnly`, `workers`, and `retries`, while the Make targets forward the current `CI` state explicitly and keep output controlled and automation-friendly.
- **Next-step impact:** The Playwright smoke layer is ready for later workflow integration without restructuring the tests or introducing separate local-vs-CI implementations.

### Steps 8–9 — Trivy security baseline and repo-owned image remediation

#### P07-D19 — Security scanner choice = Use Trivy as the first Phase-07 security baseline

- **Decision:** Introduce **Trivy** as the first security scanner for Phase 07.
- **Why:** One tool covers the three most relevant owned security surfaces needed at this stage:
  - filesystem misconfigurations
  - filesystem secret scanning
  - container image vulnerability scanning
  This keeps the first security layer compact without introducing a separate tool per security category.
- **Proof:** Step 8 uses Trivy successfully for:
  - repo-level filesystem scanning
  - image-level vulnerability scanning of the repo-owned `healthcheck` image
- **Next-step impact:** Security scanning can now be extended and later wired into CI from a single, already working scanner baseline.

#### P07-D20 — Security-scan scope = Start with repo-owned surfaces, not the full inherited upstream stack

- **Decision:** Limit the first Trivy baseline to **repo-owned helper/config surfaces** and the **repo-owned `healthcheck` image**.
- **Why:** A full-stack scan of the inherited upstream application would immediately surface a large volume of legacy findings that are outside the current owned remediation scope. The first security layer needs to stay realistic and actionable.
- **Proof:** Step 8 focuses on:
  - `healthcheck/`
  - `scripts/`
  - `deploy/kubernetes/`
  - `.github/`
  - `tests/`
  plus the local `sockshop-healthcheck` image
- **Next-step impact:** Phase 07 now has a clean security baseline on repo-owned surfaces, while the broader repo/remediation backlog can still be addressed later.

#### P07-D21 — Trivy execution model = Run Trivy containerized with a persistent cache volume

- **Decision:** Run Trivy through its official container image and mount a persistent Docker cache volume.
- **Why:** This avoids requiring a workstation-local Trivy install, keeps the execution model close to later CI usage, and avoids repeated database/check downloads on every scan run.
- **Proof:** Step 8 executes Trivy through `docker run ... aquasec/trivy:latest` and reuses `trivy-cache` across runs.
- **Next-step impact:** The security scan flow stays reproducible, portable, and fast enough for repeated local reruns and later workflow reuse.

#### P07-D22 — Trivy repo-scan shape = Scan repo-owned filesystem paths one by one and keep a focused healthcheck-only target alongside the broad baseline target

- **Decision:** Structure the repo scan so that the broad baseline iterates over repo-owned paths one by one, and add a second focused target for `healthcheck/` only.
- **Why:** `trivy fs` accepts exactly one target path per invocation. The broad baseline is still useful as a general security sweep, while the focused `healthcheck/` target is needed later as a precise remediation-proof scan for the owned Dockerfile path.
- **Proof:** Step 8 finalizes:
  - `p07-trivy-repo-scan` for the broad repo-owned baseline
  - `p07-trivy-healthcheck-repo-scan` for path-specific verification
- **Next-step impact:** Phase 07 gains both:
  - A broader security baseline
  - A precise path-level proof target for later remediation validation

#### P07-D23 — Image-scan transport = Export the local image to a tar file instead of coupling Trivy to the Docker socket

- **Decision:** Scan the repo-owned `healthcheck` image via exported image tar and `--input`, not via direct Docker-socket coupling.
- **Why:** Trivy can scan a mounted image file directly, without needing privileged access to the host Docker daemon, which often causes permission and runner-environment complications. This is easier to reuse in a later CI setting.     
- **Proof:** Step 8 builds `sockshop-healthcheck`, exports it to `/tmp/p07-trivy/sockshop-healthcheck.tar`, and scans that tar through Trivy.
- **Next-step impact:** The image-scan path is easier to reuse, and better suited for later CI adaptation.

#### P07-D24 — First remediation target = Prioritize the repo-owned `healthcheck` Dockerfile findings before tackling the broader Trivy backlog

- **Decision:** Use the `healthcheck` Dockerfile findings as the first explicit security remediation target.
- **Why:** The Step-8 baseline surfaced a clear and actionable finding set:
  - Repo-level Dockerfile misconfigurations
  - Outdated base-image-driven vulnerability exposure (outdated Apline version)
- **Proof:** Step 9 focuses on the `healthcheck` Dockerfile and resolves:
  - missing non-root `USER`
  - missing `--no-cache`
  - outdated unsupported Alpine base
- **Next-step impact:** Phase 07 now demonstrates not only security detection but also owned security remediation on a concrete artifact path.

#### P07-D25 — Dockerfile hardening model = Use a up to date Alpine base, minimal runtime packages, and a non-root runtime user

- **Decision:** Harden the `healthcheck` Dockerfile by:
  - Moving to a modern Alpine base
  - Reducing the runtime package set to what is actually needed
  - Running the container as a dedicated non-root user
- **Why:** This directly addresses the Step-8 findings while keeping the remediation small.
- **Proof:** Step 9 replaces the old Alpine 3.12-based image with a Alpine 3.21-based runtime image and reruns the helper checks successfully.
- **Next-step impact:** The Healthcheck image is now ready for new Trivy scans.

#### P07-D26 — Remediation proof model = Validate Dockerfile hardening with both targeted Trivy reruns and owned helper checks

- **Decision:** Prove the Dockerfile remediation through:
  - A focused repo-level Trivy rerun on `healthcheck/`
  - A rebuilt-image vulnerability rerun
  - Rerun of the Ruby helper tests 
- **Why:** Security hardening must reduce the findings but should also preserve the helper’s intended behavior. The proof needs both security evidence and functional regression protection.
- **Proof:** Step 9 shows:
  - `p07-trivy-healthcheck-repo-scan` => 0 misconfigurations
  - `p07-trivy-healthcheck-image-scan` => 0 vulnerabilities
  - `p07-healthcheck-tests` still passing
- **Next-step impact:** The Phase-07 security alyer now includes a completed, evidence-based remediation cycle on a repo-owned Docker image path.  



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