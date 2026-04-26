# Decision Log — Phase 07 (Security Testing): deterministic validation, security scanning, live smoke checks, and branch governance

> ## 👤 About
> This document is the **phase-local decision log** for **Phase 07 (Security Testing)**.  
> It captures the main decision story for this phase without overloading the shorter project-wide summary in **[project-docs/DECISIONS.md](../DECISIONS.md)**.
>
> For the Phase 07 top-level implementation guide, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.  
> For the detailed chronological subphase implementation trail, see:
>
> - **[Phase 07-A — Scope, Assessment & Owned Helper Refactors](./implementation/PHASE-07-A.md)**
> - **[Phase 07-B — Python Contract Guard, Live API Smoke Tests & Playwright Browser Smoke](./implementation/PHASE-07-B.md)**
> - **[Phase 07-C — Trivy Security Baseline, Healthcheck Image Remediation & Dependabot](./implementation/PHASE-07-C.md)**
> - **[Phase 07-D — Stable PR Gate, Live CI Validation & Branch Protection](./implementation/PHASE-07-D.md)**
>
> For setup-only preparation around Phase 07 tooling and local execution paths, see: **[SETUP.md](./SETUP.md)**.  
> For recorded technical anomalies discovered during this phase, see: **[DEBUG-LOG.md](../DEBUG-LOG.md)**.

---

## 📌 Index

- [**Quick recap (Phase 07)**](#quick-recap-phase-07)
  - [**Starting point: The project had live target delivery and observability, but no enforced security/testing gate yet**](#starting-point-the-project-had-live-target-delivery-and-observability-but-no-enforced-securitytesting-gate-yet)
  - [**Validation scope: Focus on repo-owned components before inherited upstream legacy components**](#validation-scope-focus-on-repo-owned-components-before-inherited-upstream-legacy-components)
  - [**Test model: Separate deterministic local checks from live environment checks**](#test-model-separate-deterministic-local-checks-from-live-environment-checks)
  - [**Security model: Combine Trivy scanning, owned-image remediation, and Dependabot visibility**](#security-model-combine-trivy-scanning-owned-image-remediation-and-dependabot-visibility)
  - [**Workflow model: Keep the merge gate deterministic and move live validation into a separate workflow**](#workflow-model-keep-the-merge-gate-deterministic-and-move-live-validation-into-a-separate-workflow)
  - [**Governance model: Protect the default branch with required deterministic checks**](#governance-model-protect-the-default-branch-with-required-deterministic-checks)
  - [**Verified result: Local validation, security scanning, CI validation, live smoke checks, and branch governance**](#verified-result-local-validation-security-scanning-ci-validation-live-smoke-checks-and-branch-governance)
  - [**Next-step implications**](#why-this-matters-next)
- [**Phase 07 validation stack**](#phase-07-validation-stack)
- [**Key Phase Decisions**](#key-phase-decisions)
  - [**P07-D01 — Validation scope and ownership boundary = prioritize repo-owned validation components before inherited legacy components**](#p07-d01--validation-scope-and-ownership-boundary--prioritize-repo-owned-validation-components-before-inherited-legacy-components)
  - [**P07-D02 — Helper testability model = refactor Ruby and Bash helpers without losing their operational role**](#p07-d02--helper-testability-model--refactor-ruby-and-bash-helpers-without-losing-their-operational-role)
  - [**P07-D03 — Output and chainability model = keep machine-readable data separate from human-readable logs**](#p07-d03--output-and-chainability-model--keep-machine-readable-data-separate-from-human-readable-logs)
  - [**P07-D04 — Python contract-guard model = use a consumer-side compatibility guard with deterministic local tests and explicit live reuse**](#p07-d04--python-contract-guard-model--use-a-consumer-side-compatibility-guard-with-deterministic-local-tests-and-explicit-live-reuse)
  - [**P07-D05 — Browser smoke model = add a small live Playwright layer without turning it into a broad E2E suite**](#p07-d05--browser-smoke-model--add-a-small-live-playwright-layer-without-turning-it-into-a-broad-e2e-suite)
  - [**P07-D06 — Trivy security baseline model = scan repo-owned components with a containerized, cache-backed Trivy workflow**](#p07-d06--trivy-security-baseline-model--scan-repo-owned-components-with-a-containerized-cache-backed-trivy-workflow)
  - [**P07-D07 — Healthcheck image remediation model = harden the owned Docker image and prove the remediation with focused reruns**](#p07-d07--healthcheck-image-remediation-model--harden-the-owned-docker-image-and-prove-the-remediation-with-focused-reruns)
  - [**P07-D08 — Dependency baseline model = use Dependabot for owned dependency components only**](#p07-d08--dependency-baseline-model--use-dependabot-for-owned-dependency-components-only)
  - [**P07-D09 — Deterministic PR-gate model = require only stable owned checks as merge blockers**](#p07-d09--deterministic-pr-gate-model--require-only-stable-owned-checks-as-merge-blockers)
  - [**P07-D10 — Live smoke workflow model = validate deployed environments separately from the merge gate**](#p07-d10--live-smoke-workflow-model--validate-deployed-environments-separately-from-the-merge-gate)
  - [**P07-D11 — Default-branch governance model = enforce the deterministic PR gate through a protected `master` ruleset**](#p07-d11--default-branch-governance-model--enforce-the-deterministic-pr-gate-through-a-protected-master-ruleset)
- [**Next-step implications**](#next-step-implications)
---

## Quick recap of Phase 07

Phase 07 implemented a dedicated **testing and security layer** and moved the project from a deployed (Phase 05) and observable (Phase 06) target platform to a **validated, security-scanned, dependency-aware, and merge-governed delivery path**.

### Starting point: The project had live target delivery and observability, but no enforced security/testing gate yet

By the start of Phase 07, the project already had:

- Proxmox-based K3s target
- Environment-separated `dev` and `prod` namespaces
- Public HTTPS access through Cloudflare Tunnel
- CI/CD-Workflow-driven target delivery through GitHub Actions
- Observability through Prometheus and Grafana

What was still missing was a dedicated **testing and security layer** that could support **controlled changes**.

The project needed:

- Repo-owned **automated tests**
- A first **security-scanning** baseline
- **Dependency** update visibility
- **Stable CI checks** for pull requests
- Live deployed-**environment validation**
- **Default-branch protection** that makes the stable checks **mandatory** before merge

### Validation scope: Focus on repo-owned components before inherited upstream legacy components

Phase 07 starts from the components that are a**ctively owned and maintained** in this repository.

The strongest initial repo-owned validation targets were:

- **Ruby Healthcheck**, implemented in `healthcheck/healthcheck.rb`
- **Bash Traffic Generator (Observability Helper)**, implemented in `scripts/observability/generate-sockshop-traffic.sh`

Those helpers were technically relevant:

- The Ruby healthcheck provides **service health and reachability checks**
- The Bash traffic helper provides **observability validation** through generated storefront traffic

At the same time, those helpers did **not cover every relevant quality layer**. 

Phase 07 therefore added:

- A **Python API contract guard** for `/catalogue` **response-schema validation**
- A **Playwright browser smoke layer** for **live storefront rendering** proof

The chosen path also **avoids turning Phase 07 into an unfinishable full-stack hardening effort**. 

Instead, the phase follows a **realistic DevSecOps sequence**:

- (1) Establish a baseline
- (2) Identify owned findings
- (3) Remediate the owned artifact / component / configuration
- (4) Re-scan and verify the result
- (5) Enforce the stable part through CI and branch protection

### Test model: Separate deterministic local checks from live environment checks

A central decision in Phase 07 was to keep two validation paths separate:

- **Deterministic checks**
  - Ruby helper tests
  - Bash helper tests
  - Local Python contract-guard tests
  - Focused Trivy scans for the remediated `healthcheck` path and image

- **Live environment checks**
  - Python live catalogue contract smoke checks
  - Playwright browser smoke checks against the deployed storefront

This split matters because **deterministic checks are suitable as merge blockers**, while live tests tend to be "flaky" - they can be affected by various conditions outside the control of the test environment (like target availability, network conditions, browser timing etc.).

The result is a **cleaner validation model**:

- Deterministic tests answer whether a change is safe to merge (Code Check)
- Live smoke checks answer whether a deployed environment still behaves correctly 

### Security Model: Combine Trivy scanning, owned-image remediation, and Dependabot visibility

Phase 07 adds three DevSecOps controls:

- **Trivy filesystem scanning**
  - Scans for repo-owned misconfiguration 
  - Secret scanning

- **Trivy image scanning**
  - Vulnerability scanning for the repo-owned `sockshop-healthcheck` image

- **Dependabot**
  - GitHub-native dependency update scanning for GitHub Actions and the Playwright npm toolchain

The first security baseline intentionally **focuses on repo-owned and actively maintained components** instead of trying to remediate the full inherited upstream application stack in one step.

The phase also demonstrates a **complete remediation loop on the owned `healthcheck` Dockerfile**:

- (1) Establish initial findings
- (2) Harden the Dockerfile
- (3) Rerun the focused repo scan
- (4) Rerun the image vulnerability scan
- (5) Confirm the helper still behaves correctly

### Workflow model: Keep the merge gate deterministic and move live validation into a separate workflow

(1) The **deterministic validation path*** is implemented as a **dedicated GitHub Actions PR-gate workflow**.

The workflow functions as merge-gate and uses teh follwoing job names as **required-checks**:

- `p07-deterministic-tests`
- `p07-trivy-healthcheck-repo-scan`
- `p07-trivy-healthcheck-image-scan`

(2) The **live validation path** is implemented as a **separate workflow**:

- `phase-07-live-smoke.yml`

This workflow validates deployed environments through:

- Python live contract smoke tests (API schema validation from the consumer side)
- Playwright browser smoke tests (basic reachability and catalogue-image rendering validation)

The live smoke tests workflow can be run manually, but is also prepared for later workflow reuse. It is intentionally not required for normal merges.

### Governance model: Protect the default branch with required deterministic checks

The last Phase 07 layer is repository governance / branch protection.

Without a sepcific branch prtection ruleset the deterministic PR gate would only "informational", since merges or direct branch changes can just bypass it. 

Phase 07 therefore adds **default-branch protection** through a **GitHub ruleset**.

The protected-branch rule-set enforces for the `master` branch:

- Only Pull-request-based changes to `master`
- Successful deterministic Phase 07 checks before merge
- Up-to-date branch state before merge
- Blocked force pushes
- No direct bypass of the validation tests

This turns the deterministic workflow into an **actual merge gate**.

### Verified result: Local validation, security scanning, CI validation, live smoke checks, and branch governance

By the end of Phase 07, the project proves:

- Repo-owned Ruby and Bash helpers are now testable and covered by automated checks
- The Python API contract guard validates `/catalogue` response compatibility locally and against live endpoints
- The Playwright smoke tests layer verifies storefront rendering in a real browser
- Trivy scans repo-owned source/config and image artifacts
- The repo-owned `healthcheck` image was hardened and rescanned successfully
- Dependabot monitors owned dependency components
- The deterministic validation bundle runs in GitHub Actions on pull requests
- Live smoke validation runs separately against deployed environments when manually triggered
- `master` is protected by required deterministic Phase 07 tests that funciton as merge guard

### Next-step implications

Phase 07 gives the remaining project work a **stronger safety net**.

Later phases can now add infrastructure automation, disaster recovery, rollback workflows, or further hardening behind:

- Repo-owned automated tests
- Security scan targets
- Dependency update visibility
- Deterministic CI checks
- Live Browser CI checks
- Protected-branch governance

This means the project can continue evolving without relying only on manual checks and screenshots.

---

## Phase 07 validation stack

At this point, the **Phase 07 Test & Security Layer** validates:

- **(1) Service health/reachability** through the Ruby healthcheck helper
- **(2) Helper-script behavior** through Bash tests for the observability traffic generator
- **(3) API response-shape compatibility** through the Python catalogue contract guard
- **(4) Storefront rendering in a real browser** through Playwright / JavaScript browser smoke tests
- **(5) Security scanning for repo-owned components** through Trivy
- **(6) Evidence-based security remediation of a repo-owned Docker image** through Trivy and Dockerfile hardening (`healthcheck`)
- **(7) Dependency scanning for repo-owned dependency components** through Dependabot
- **(8) Deterministic PR-gate validation in CI** through GitHub Actions
- **(9) Live deployed-environment smoke validation in GitHub Actions** through the manual / reusable live-smoke workflow
- **(10) Repository-level merge governance on the default branch** through a ruleset and required deterministic checks

This completes the implementation of Phase 07 as a full testing, security, CI-validation, live-smoke, and governance layer.

---

## Key Phase Decisions

### P07-D01 — Validation scope and ownership boundary = Prioritize repo-owned validation components before inherited legacy components

- **Decision:** Build the first Phase 07 validation scope around repo-owned and actively maintained project components before broadening into inherited upstream legacy components.
- **Why:** The strongest executable components under project control were the Ruby `healthcheck` helper and the Bash observability traffic generator. Those helpers already supported real operational flows, but they did not cover all quality layers. Phase 07 therefore added a Python API contract guard and reserved space for a browser smoke layer instead of trying to retrofit the entire inherited Sock Shop application stack at once.
- **Proof:** The Phase 07 test scaffold separates Ruby, Bash, Python, and browser smoke concerns under `tests/` and `.gitignore` is configured to exclude generated dependency and report artifacts.
- **Next-step impact:** The phase starts from components that can be tested and maintained realistically. Broader inherited application hardening remains possible later without blocking the first security/testing baseline.

### P07-D02 — Helper testability model = Refactor Ruby and Bash helpers without losing their operational role

- **Decision:** Refactor the repo-owned Ruby and Bash helpers into testable structures while preserving their original command-line and runtime behavior.
- **Why:** Both helpers were operationally useful, but their original top-level execution shape blocked clean automated testing. The Ruby helper parsed options and exited directly from top-level code, while the Bash helper entered prompt handling and the traffic loop immediately when executed.
- **Proof:** The Ruby helper is now structured around an importable `HealthChecker` class plus execution guard, and the Bash helper is protected behind `main()` plus a Bash execution guard. Ruby CLI and unit tests pass, and Bash CLI/function-level tests pass.
- **Next-step impact:** Both helpers become deterministic repo-owned validation components that can be run locally and later reused in CI without triggering uncontrolled runtime side effects.

### P07-D03 — Output and chainability model = Keep machine-readable data separate from human-readable logs

- **Decision:** Make the Ruby healthcheck path machine-chainable by separating machine-readable JSON output from human-readable status logs.
- **Why:** The earlier Ruby helper output mixed informational logs with Ruby-style pretty-printed hash output. That blocked safe parsing by tools such as `jq` and reduced automation-readiness.
- **Proof:** The Ruby helper now emits valid JSON to `stdout`, sends human-readable status messages to `stderr`, and the target-environment proof helper preserves that clean stream separation through Bash, `kubectl`, and `make`.
- **Next-step impact:** The healthcheck helper is now usable as both an operational CLI tool and an automation-friendly validation component.

### P07-D04 — Python contract-guard model = Use a consumer-side compatibility guard with deterministic local tests and explicit live reuse

- **Decision:** Implement the Python schema validation layer as a consumer-side catalogue compatibility guard, not as the authoritative provider schema for the upstream API.
- **Why:** The project does not formally own the upstream catalogue API contract. The Python layer should therefore protect the minimum response shape needed by this project without claiming to fully specify the upstream provider.
- **Proof:** `tests/python/sockshop_contract_guard.py` validates a narrow tolerant schema focused on `id`, `name`, and `price`. Local Python unit tests validate the contract logic deterministically, and the live test reuses the same validation function against deployed catalogue endpoints.
- **Next-step impact:** The Python QA layer covers both deterministic contract logic and explicit live API smoke validation without duplicating schema logic.

### P07-D05 — Browser smoke model = Add a small live Playwright layer without turning it into a broad E2E suite

- **Decision:** Start browser-level validation with a minimal Chromium-only Playwright smoke suite against the live storefront.
- **Why:** Phase 07 needed proof that the deployed storefront renders in a real browser, but broad user-flow automation or cross-browser regression coverage would have been too large for this phase.
- **Proof:** The Playwright setup under `tests/e2e` verifies storefront loading, key landing-page content, and visibility of at least one catalogue image. The generated Playwright reports provide browser-level evidence.
- **Next-step impact:** The project gains a real browser smoke signal that can be expanded later without overloading the first security/testing phase.

### P07-D06 — Trivy security baseline model = Scan repo-owned components with a containerized, cache-backed Trivy workflow

- **Decision:** Use Trivy as the first security scanner and run it containerized with a persistent cache volume.
- **Why:** Trivy covers the most relevant first security components in one tool: filesystem misconfiguration scanning, filesystem secret scanning, and image vulnerability scanning. Running it in a container avoids requiring a host-side Trivy installation and keeps the execution model close to later CI usage.
- **Proof:** The Makefile exposes Trivy targets for broad repo-owned filesystem scanning, focused `healthcheck/` scanning, and repo-owned image vulnerability scanning. The first scan baseline surfaced concrete findings in `healthcheck/Dockerfile`.
- **Next-step impact:** The project now has a repeatable security scan path that can run locally and be reused in GitHub Actions.

### P07-D07 — Healthcheck image remediation model = Harden the owned Docker image and prove the remediation with focused reruns

- **Decision:** Use the repo-owned `healthcheck` Dockerfile as the first explicit security-remediation target.
- **Why:** The Trivy baseline produced a clear owned finding set: missing non-root `USER`, missing `--no-cache`, and an outdated Alpine base image with HIGH/CRITICAL vulnerabilities. This made the `healthcheck` image the most actionable first remediation target.
- **Proof:** The Dockerfile was hardened with a newer Alpine base, a reduced runtime package set, `apk add --no-cache`, and a dedicated non-root runtime user. Focused Trivy reruns then showed 0 misconfigurations for the `healthcheck/` path and 0 vulnerabilities for the rebuilt image. Ruby helper checks still passed afterward.
- **Next-step impact:** Phase 07 demonstrates a complete detect-remediate-rerun security cycle on a repo-owned Docker image path, while broader legacy hardening findings remain a follow-up backlog.

### P07-D08 — Dependency baseline model = Use Dependabot for owned dependency components only

- **Decision:** Establish the first automated dependency update baseline with GitHub Dependabot, scoped to GitHub Actions and the Playwright npm project under `tests/e2e`.
- **Why:** These are dependency components actively owned and operated in this repository. Scanning inherited legacy dependency trees would generate noise before the project has a clear maintenance strategy for them.
- **Proof:** `.github/dependabot.yml` configures weekly updates for the GitHub Actions ecosystem and npm dependencies under `/tests/e2e`. GitHub recognizes the monitored targets and creates normal reviewable Dependabot pull requests.
- **Next-step impact:** Dependency update visibility becomes part of the repository’s DevSecOps baseline and can be reviewed through the same protected pull-request path as normal changes.

### P07-D09 — Deterministic PR-gate model = Require only stable owned checks as merge blockers

- **Decision:** Build the required PR gate from deterministic, repo-owned checks only.
- **Why:** Merge-blocking CI should fail on signals that are stable, reproducible, and directly attributable to the pull request. Live checks and broad legacy-security backlogs are valuable, but they are not suitable as the first mandatory gate because they can depend on deployed runtime state or known backlog outside the focused remediation scope.
- **Proof:** `.github/workflows/phase-07-deterministic-pr-gate.yml` runs:
  - `make p07-tests`
  - `make p07-trivy-healthcheck-repo-scan`
  - `make p07-trivy-healthcheck-image-scan`
  with stable job names:
  - `p07-deterministic-tests`
  - `p07-trivy-healthcheck-repo-scan`
  - `p07-trivy-healthcheck-image-scan`
- **Next-step impact:** The deterministic CI path is stable enough to become the required status-check set for default-branch protection.

### P07-D10 — Live smoke workflow model = Validate deployed environments separately from the merge gate

- **Decision:** Implement deployed-environment smoke validation as a separate GitHub Actions workflow instead of including it in the required PR gate.
- **Why:** Live validation depends on public-edge reachability, deployed runtime state, and browser execution timing. It is important for environment confidence, but not stable enough to act as the primary merge blocker.
- **Proof:** `.github/workflows/phase-07-live-smoke.yml` resolves `dev` or `prod` target URLs through repository variables or explicit inputs, runs the existing live smoke bundle, and uploads Playwright artifacts.
- **Next-step impact:** The live-smoke workflow remains available for manual validation and later post-deployment reuse, while the merge gate stays deterministic.

### P07-D11 — Default-branch governance model = Enforce the deterministic PR gate through a protected `master` ruleset

- **Decision:** Protect the default branch so changes to `master` must go through a pull request and the deterministic Phase 07 checks must pass before merge.
- **Why:** A CI workflow alone is not a governance control if it can be bypassed through direct branch updates. The repository therefore needs branch-level enforcement that turns the deterministic workflow into a mandatory merge gate.
- **Proof:** The GitHub ruleset for `master` requires pull-request-based changes, up-to-date branch state, blocked force pushes, and the deterministic Phase 07 status checks:
  - `p07-deterministic-tests`
  - `p07-trivy-healthcheck-repo-scan`
  - `p07-trivy-healthcheck-image-scan`
- **Next-step impact:** Phase 07 ends with an enforced quality and security boundary on the default branch. Future phases can build on this governance model instead of relying on manual discipline alone.
---

## Next-step implications

- Phase 07 establishes the project’s first enforceable testing and security baseline.
- Future infrastructure, recovery, and hardening work should reuse the deterministic PR-gate path instead of adding disconnected validation logic.
- The live-smoke workflow can later be reused from deployment workflows after `dev` or `prod` rollout.
- The broader Trivy findings outside the remediated `healthcheck` path remain a planned hardening backlog.
- GitHub Actions runtime deprecation warnings remain a later workflow-maintenance follow-up and do not block the Phase 07 validation outcome.
- Dependabot PRs should be treated as controlled maintenance proposals and reviewed through the same protected pull-request path.
- The default branch is now governed by required deterministic checks, which gives later phases a stronger quality and security boundary.
