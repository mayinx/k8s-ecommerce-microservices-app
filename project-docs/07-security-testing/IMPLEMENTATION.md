# 🛡️ Implementation Guide — Phase 07: Security Testing

> ## 👤 About
> This document is the **top-level implementation guide** for **Phase 07 (Security Testing)**.  
> It explains the overall implementation story, the selected security and testing strategy, the final outcome that was achieved, and how the detailed work is split across the Phase 07 subphases.
>
> ## 🧭 Phase 07 reading paths
>
> **This top-level guide** is the best entry point for the **Phase 07 big picture**. For the full chronological hands-on build diary and implementation trail, continue with the **subphase guides listed below**:
>
> - **[Phase 07-A — Scope, Assessment & Owned Helper Refactors](./implementation/PHASE-07-A.md)**
> - **[Phase 07-B — Python Contract Guard, Live API Smoke Tests & Playwright Browser Smoke Tests](./implementation/PHASE-07-B.md)**
> - **[Phase 07-C — Trivy Security Baseline, Healthcheck Image Remediation & Dependabot](./implementation/PHASE-07-C.md)**
> - **[Phase 07-D — Stable PR Gate, Live CI Validation & Branch Protection](./implementation/PHASE-07-D.md)**
>
> ## 🔎 Companion documents
>
> - Setup-only preparation: [SETUP.md](./SETUP.md)  
> - Phase-local decision record: [DECISIONS.md](./DECISIONS.md)  
> - Cross-phase incident and anomaly tracking: [DEBUG-LOG.md](../DEBUG-LOG.md)  
> - Top-level project navigation: [INDEX.md](../INDEX.md)  

---

## 📌 Index (top-level)

- [Phase 07 outcomes at a glance](#phase-07-outcomes-at-a-glance)
- [Phase 07 validation stack](#phase-07-validation-stack)
- [Validation and security model at a glance](#validation-and-security-model-at-a-glance)- [CI/CD governance model at a glance](#cicd-governance-model-at-a-glance)
- [Implementation Roadmap & Phase 07 Subphase Quick Navigation](#️-implementation-roadmap--phase-07-subphase-quick-navigation)
- [Purpose / Goal](#purpose--goal)
- [Definition of done](#definition-of-done)
- [Phase 07 Subphase Overview](#phase-07-subphase-overview)
  - [Phase 07-A — Scope, Assessment & Owned Helper Refactors](#phase-07-a--scope-assessment--owned-helper-refactors)
  - [Phase 07-B — Python Contract Guard, Live API Smoke Tests & Playwright Browser Smoke](#phase-07-b--python-contract-guard-live-api-smoke-tests--playwright-browser-smoke)
  - [Phase 07-C — Trivy Security Baseline, Healthcheck Image Remediation & Dependabot](#phase-07-c--trivy-security-baseline-healthcheck-image-remediation--dependabot)
  - [Phase 07-D — Stable PR Gate, Live CI Validation & Branch Protection](#phase-07-d--stable-pr-gate-live-ci-validation--branch-protection)
- [Phase outcome summary](#phase-outcome-summary)
- [Foundation for later phases](#foundation-for-later-phases)
- [Source trail](#source-trail)

---

## 🚀 Phase 07 outcomes at a glance

Phase 07 adds an integrated **security and testing layer** on top of the already deployed (Pahse 05) and observable (Phase 06) target platform.

**Phase 07 establishes:**

- **Repo-owned validation scope:** Clear separation between actively maintained project components and inherited upstream legacy application components
- **Ruby helper tests:** Characterization and unit tests for the repo-owned `healthcheck` helper
- **Bash helper tests:** CLI and function-level tests for the repo-owned Observability Traffic Generator
- **Python contract guard:** A consumer-side `/catalogue` response schema validator with deterministic local unit tests
- **Live API smoke checks:** Reuse of the Python contract guard against deployed `dev` and `prod` `/catalogue` endpoints
- **Browser smoke tests:** A minimal Playwright smoke suite that verifies storefront rendering in Chromium
- **Makefile targets as rerun commands:** Phase 07 helper targets for deterministic tests, live checks, Playwright, Python contract tests, and Trivy scans  
- **Trivy security baseline:** Filesystem scanning for repo-owned source/config components and image vulnerability scanning for the repo-owned `healthcheck` image
- **Evidence-based remediation:** Hardening of the `healthcheck` Dockerfile based on Trivby Scans and final verification that the remediated image scans cleanly
- **Dependency update baseline:** Dependabot configuration for GitHub Actions and the Playwright npm project under `tests/e2e`
- **Deterministic PR gate:** GitHub Actions workflow with stable required-check job names
- **Live smoke workflow:** Separate manual/reusable GitHub Actions workflow for deployed-environment validation
- **Default-branch governance:** GitHub branch-protection ruleset anchoring the deterministic Phase 07 checks as mandatory merge-gate before `master`

By the end of this phase, the project no longer relies only on manual smoke checks. It has a **layered validation model** that covers 
- Helper behavior
- API compatibility
- Browser rendering
- Security scanning
- Dependency visibility
- CI validation
- Branch-protection incl. merge-gates 

---

## Phase 07 validation stack

At this point, the **Phase 07 Test & Security Layer** validates:

- **(1) Service health/reachability** through the Ruby healthcheck helper
- **(2) Helper-script behavior** through Bash tests for the Observability Traffic Generator
- **(3) API response schema compatibility** through the Python `/catalogue` contract guard
- **(4) Storefront rendering in a real browser** through Playwright / JavaScript browser smoke tests
- **(5) Security scanning for repo-owned components** through Trivy
- **(6) Evidence-based security remediation of a repo-owned Docker image** through Trivy and Dockerfile hardening (`healthcheck`)
- **(7) Dependency scanning for repo-owned dependency components** through Dependabot
- **(8) Deterministic PR-gate validation in CI** through GitHub Actions + determinsitic Bash, Ruby + Python Tests
- **(9) Live smoke validation in GitHub Actions** through the manual/reusable live-smoke test workflow (Playwright)
- **(10) Repository-level merge governance on the default branch** through a branch-protection ruleset and required deterministic checks

This completes the implementation of Phase 07 as a full testing, security, CI-validation, live-smoke, and governance layer.

---

## 🧩 Validation and security model at a glance

Phase 07 separates **deterministic checks** from **live environment checks**.

The deterministic path is stable enough to act as a required merge gate. It validates repo-owned logic and repo-owned security components without depending on the public edge, browser timing, or the current state of a deployed environment.

The live path answers a different question: Whether the already deployed application still behaves correctly through the public `dev` or `prod` edge. Since live tests operate against a not fully controlled environment, they are non-deterministic and tehrfore potentially flaky - and not per se a good fit as merge guard. 

Later phases will evaluate, if those live tests are stable enough, to fucntion as pre-production deplyoment gate.  

### Deterministic validation path

The deterministic local and CI path includes:

- **Ruby HealthCheck** syntax, CLI characterization, and unit tests
- **Bash Observability-helper** syntax, CLI behavior, and deterministic function tests
- **Python API contract-guard** syntax and local unit tests
- Focused **Trivy filesystem scan** for the remediated `healthcheck/` path
- **Trivy image vulnerability scan** for the repo-owned `sockshop-healthcheck` image

This validation path is represented locally through Make targets:

- `make p07-tests`
- `make p07-trivy-healthcheck-repo-scan`
- `make p07-trivy-healthcheck-image-scan`

GitHub Actions reflect this in Form of the deterministic PR gate workflow.

### Live validation path

The live path includes:

- **Python** live `/catalogue` contract smoke tests (API schema validation)
- **Playwright** browser smoke tests against the deployed storefront

This path is represented locally through:

- `make p07-tests-live`
- `make p07-tests-all`

It is represented in GitHub Actions by the separate live-smoke workflow.

### Security baseline path

The security layer contains three complementary controls:

- **Trivy filesystem scan:** Scan for repo-owned misconfiguration and secret scanning
- **Trivy image scan:** Vulnerability scanning for the repo-owned `healthcheck` image
- **Dependabot:** Automated dependency update visibility for GitHub Actions and the Playwright npm test toolchain

The key **scope decision** is that Phase 07 focuses first on **repo-owned and actively maintained components**. This keeps the security refactoring actionable. Broader legacy findings are kept as **follow-up backlog**.

---

## 🔄 CI/CD governance model at a glance

Phase 07 introduces a clean split between three workflow responsibilities:

- **Target delivery:** handled by the existing Phase 05 target-delivery workflow
- **Pre-merge deterministic validation:** handled by the Phase 07 deterministic PR gate
- **Deployed-environment smoke validation:** handled by the Phase 07 live-smoke workflow

The deterministic PR gate is the enforced merge-control layer.

It contains three stable required job names:

- `p07-deterministic-tests`
- `p07-trivy-healthcheck-repo-scan`
- `p07-trivy-healthcheck-image-scan`

Those jobs are intentionally stable and focused so they can be selected as required status checks in GitHub branch protection.

The live-smoke workflow remains separate and non-required for merge. It can be run manually against `dev` or `prod`, and it is structured as a reusable workflow for later post-deployment validation.

This produces the final governance model:

- Pull requests to `master` run the deterministic PR gate
- Required deterministic checks must pass before merge
- Live smoke checks remain available for deployed-environment confidence
- The default branch is protected by a GitHub ruleset
- Direct bypass of the normal PR validation path is prevented by repository rules

---

## 🗺️ Implementation Roadmap & Phase 07 subphase quick navigation

The Phase 07 implementation is split into four focused subphases because the detailed execution path spans test architecture, security scanning, remediation, CI, and governance.

| Subphase | Strategic Focus | Deliverables / Proof Points |
| :--- | :--- | :--- |
| **[P07-A:<br>Owned components & Helper Refactors](./implementation/PHASE-07-A.md)** | **Testability Foundation**<br>Defines the repo-owned validation components, creates the test scaffold, assesses the Ruby and Bash helpers, and refactors both into controlled test targets. | > Repo-owned test scope defined<br>> Ruby healthcheck refactored and tested<br>> Bash traffic helper refactored and tested |
| **[P07-B:<br>Contract & Browser Smoke](./implementation/PHASE-07-B.md)** | **API and UI Validation**<br>Adds a Python consumer-side `/catalogue` contract guard, reuses it against live endpoints, and introduces a minimal Playwright browser smoke layer. | > Local Python contract tests<br>> Live API contract smoke checks<br>> Browser smoke proof through Playwright |
| **[P07-C:<br>Security Baseline & Dependency Visibility](./implementation/PHASE-07-C.md)** | **Security Scanning and Remediation**<br>Introduces Trivy scans, remediates the repo-owned healthcheck image, and establishes Dependabot for owned dependency components. | > Trivy repo/image scan baseline<br>> Hardened healthcheck Dockerfile<br>> Dependabot update baseline |
| **[P07-D:<br>CI Gate & Branch Governance](./implementation/PHASE-07-D.md)** | **CI Enforcement and Governance**<br>Moves the deterministic checks into GitHub Actions, adds a separate live-smoke workflow, and protects `master` with required checks. | > Deterministic PR gate<br>> Live smoke workflow<br>> Default-branch protection ruleset |

---

## 🎯 Purpose / Goal

The goal of Phase 07 is to add a **Testing and Security Layer** to the already deployed Sock Shop target platform.

Earlier phases established:

- A local application baseline
- A local Kubernetes baseline 
- Host-based ingress
- CI/CD delivery mechanics
- A real Proxmox-backed K3s target
- Environment-separated `dev` and `prod`
- Public HTTPS exposure through Cloudflare Tunnel
- Observability through Prometheus and Grafana

Phase 07 builds on that foundation by adding the validation and security layer that should exist before later infrastructure automation, recovery planning, or portfolio polish.

This phase therefore has the following objectives:

- **Identify repo-owned code and configuration components** that can be tested and secured realistically
- Add **deterministic automated tests** for **owned helper code**
- Add **live smoke validation** for the **deployed application** 
- Establish **security scanning**, **dependency visibility**, and **remediation evidence**
- Enforce the **stable validation path** through **GitHub Actions CI/CD-Workflows** and **branch protection**

Phase 07 intentionally avoids trying to modernize the entire inherited legacy microservice stack. This is out of scope of this Capstone project. 

Instead Phase 07 focus on the components and configurations the project actively controls. 

---

## Definition of done

Phase 07 is considered done when the following conditions are met:

- The repo-owned testing components are defined explicitly
- The Phase 07 test scaffold exists for:
  - Ruby
  - Bash
  - Python
  - Playwright / JavaScript
- `.gitignore` excludes generated Phase 07 test dependencies and test artifacts
- The Ruby `healthcheck` helper is refactored into a testable structure without losing its CLI role
- Ruby CLI characterization tests and unit tests pass locally
- The Bash observability traffic helper is refactored behind a safe execution guard
- Bash CLI and deterministic function tests pass locally
- The Python catalogue contract guard validates a minimum consumer-side response-shape baseline
- Local Python contract-guard tests pass deterministically
- The same Python contract guard is reused against live `dev` and `prod` catalogue endpoints
- The Playwright smoke suite validates the live storefront in Chromium
- Local Make targets exist for deterministic tests, live checks, Playwright, Python, and Trivy
- A Trivy repo-owned filesystem scan baseline exists
- A Trivy image vulnerability scan baseline exists for the repo-owned `healthcheck` image
- The `healthcheck` Dockerfile is hardened and the focused Trivy reruns show the remediation result
- Dependabot is configured for:
  - GitHub Actions
  - The Playwright npm project under `tests/e2e`
- GitHub shows Dependabot monitoring and dependency graph evidence
- The deterministic PR-gate workflow exists and runs successfully
- The live-smoke workflow exists and runs successfully against the deployed edge
- Default-branch protection requires the deterministic Phase 07 job checks before merge
- Phase 07 evidence screenshots are captured in `project-docs/07-security-testing/evidence/`

---

## Phase 07 Subphase Overview

The detailed execution diary is split into four focused subphase guides. Each subphase adds one concrete layer to the testing and security model.

### Phase 07-A — Scope, Assessment & Owned Helper Refactors

**Detailed file:** [./implementation/PHASE-07-A.md](./implementation/PHASE-07-A.md)

**Focus:** Define repo-owned test components, create the test scaffold, assess the Ruby and Bash helpers, and refactor both helpers into testable shapes.

**Result achieved:** The Ruby healthcheck and Bash observability traffic helper became deterministic automated test components while preserving their operational roles.

**Bridge forward:** With the first repo-owned helper tests in place, the next step was to add a data-contract layer and browser smoke validation for the deployed application path.

---

### Phase 07-B — Python Contract Guard, Live API Smoke Tests & Playwright Browser Smoke Tests

**Detailed file:** [./implementation/PHASE-07-B.md](./implementation/PHASE-07-B.md)

**Focus:** Add a Python consumer-side catalogue contract guard, test it locally, reuse it against live deployed endpoints, and introduce a minimal Playwright browser smoke suite.

**Result achieved:** The validation layer expanded from helper behavior into API response-shape compatibility and browser-level storefront rendering proof.

**Bridge forward:** With the application validation path established, the next step was to add security scanning, dependency visibility, and remediation evidence.

---

### Phase 07-C — Trivy Security Baseline, Healthcheck Image Remediation & Dependabot

**Detailed file:** [./implementation/PHASE-07-C.md](./implementation/PHASE-07-C.md)

**Focus:** Establish Trivy security scans for repo-owned components, remediate the owned healthcheck image, and configure Dependabot for owned dependency update visibility.

**Result achieved:** The project gained a repo-owned security baseline, a proven Dockerfile hardening cycle, and GitHub-native dependency monitoring.

**Bridge forward:** With deterministic tests and security checks available locally, the next step was to move the stable subset into GitHub Actions and enforce it at repository level.

---

### Phase 07-D — Stable PR Gate, Live CI Validation & Branch Protection

**Detailed file:** [./implementation/PHASE-07-D.md](./implementation/PHASE-07-D.md)

**Focus:** Implement the deterministic GitHub Actions PR gate, add a separate live-smoke workflow, and enforce the deterministic checks through default-branch protection.

**Result achieved:** Phase 07 completed the chain from local validation to CI validation to repository-level merge governance.

**Bridge beyond Phase 07:** Later phases can build on an enforced validation baseline instead of relying on manual review alone.

---

## Phase outcome summary

Phase 07 completed the first integrated **testing, security, and governance baseline** for the project.

By the end of this phase, the project proves:

- Repo-owned helper code is tested locally and deterministically
- API compatibility is guarded through a Python consumer-side contract validator
- Deployed `dev` and `prod` catalogue endpoints can be checked through the same validation engine
- The live storefront can be verified through a real Chromium browser using Playwright
- Repo-owned security components are scanned through Trivy
- The repo-owned healthcheck image was hardened and rescanned successfully
- Dependency update visibility is active through Dependabot
- Deterministic tests and focused security scans run in GitHub Actions on pull requests
- Live smoke validation runs separately against deployed environments
- `master` is protected by required deterministic Phase 07 checks

The full resulting validation stack of this implementation phase is summarized at the top of this guide in [Phase 07 validation stack](#phase-07-validation-stack).

This moves the project from deployed and observable to 

- validated 
- security-scanned 
- dependency-aware 
- merge-governed

---

## Foundation for later phases

Phase 07 creates a stronger foundation for the remaining project work.

The next phases can now build on:

- A stable deterministic test target for pull requests
- A separate live validation workflow for deployed environments
- Playwright artifacts as browser-level evidence
- Trivy scan targets that can be expanded later
- Dependabot PRs as a controlled dependency-maintenance workflow
- Branch protection as a governance baseline for future changes

This directly supports the next implementation areas:

- **Infrastructure as Code:** Future Terraform or Kubernetes-provider work can be added behind the same deterministic PR gate.
- **Disaster recovery / rollback:** Recovery scripts and runbooks can be tested and reviewed through the existing repo-governance path.
- **Further hardening:** Broader Trivy findings can be handled as planned backlog instead of mixed into the first security baseline.
- **Post-deployment validation:** The live-smoke workflow can later be reused from deployment workflows after `dev` or `prod` rollout.

---

## Source trail

The detailed technical sources and command-specific references for this phase are maintained in the subphase implementation guides where the respective tools and decisions are introduced.

- [Phase 07-A — Scope, Assessment & Owned Helper Refactors](./implementation/PHASE-07-A.md)
- [Phase 07-B — Python Contract Guard, Live API Smoke Tests & Playwright Browser Smoke](./implementation/PHASE-07-B.md)
- [Phase 07-C — Trivy Security Baseline, Healthcheck Image Remediation & Dependabot](./implementation/PHASE-07-C.md)
- [Phase 07-D — Stable PR Gate, Live CI Validation & Branch Protection](./implementation/PHASE-07-D.md)