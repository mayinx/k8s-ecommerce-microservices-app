# Implementation — Subphase 04: Stable PR gate, live CI validation, and branch protection (Steps 11–13)

## Step 11 — Wire deterministic PR-gate checks into a new GitHub Actions workflow

### Rationale

Phase 07 now already provides a strong **local validation baseline**:

- **Service health / reachability** through the Ruby healthcheck
- **Observability-helper behavior** through the Bash observability-helper tests
- **API response-shape compatibility** through the Python API contract guard
- **Storefront rendering in a real browser** through the Playwright browser smoke test
- **Security-scanning for repo-owned surfaces** through Trivy
- **Dependency-scanning for repo-owned dependency surfaces** through Dependabot

What is still missing is a **GitHub-native deterministic PR gate** that runs automatically on pull requests and prevents regressions from reaching the default branch.

The next useful addition is therefore a **deterministic PR-gate workflow** in GitHub Actions.

**Scope**

This step stays intentionally limited to **deterministic checks** only:

- **`make p07-tests`**
  - Ruby helper tests
  - Bash helper tests
  - local Python contract-guard tests
- **`make p07-trivy-healthcheck-repo-scan`**
  - focused repo-level Trivy scan for the owned `healthcheck/` path
- **`make p07-trivy-healthcheck-image-scan`**
  - vulnerability scan of the repo-owned `sockshop-healthcheck` image

The following checks are **explicitly excluded** from this PR gate:

- **`make p07-tests-live`**
- **Playwright live smoke tests**
- **Live Python contract smoke checks**
- **The broad `make p07-trivy-repo-scan` baseline**

That split is deliberate:

- Live/browser checks are **environment-dependent**
- The broad repo Trivy baseline currently surfaces **additional backlog outside the focused `healthcheck/` remediation path**
- tThe PR gate in this step should stay **stable, explainable, and merge-blocking only for owned deterministic signals already under control**

> [!NOTE] **🛡️ Deterministic PR gate**
>
> A **deterministic PR gate** is a CI workflow that runs checks whose result should not depend on instable external conditions. It should rely on deterministic conditions and tests.
>
> A deterministic test runs entirely in isolation and produces - given the exact same input and initial state - always the exact same outout. It mocks or uses otherwise predefined stable input, doesn't rely on unstable random factors (like the public internet), and controls its own environment.
> 
> In short: If a deterministic test fails, the code is broken. No other factors play a role.
>
> In this phase, the PR gate is intentionally **limited to checks that are stable enough to act as merge blockers** for normal development work to check for broken code.

> [!NOTE] **🧭 Why "flaky"/non-deterministic live checks are not part of the PR gate**
>
> The Phase 07 live checks answer a different question:
>
> - **Deterministic PR gate:** “Is this change structurally and locally safe to merge?”
> - **Live smoke workflow:** “Does the deployed environment still behave correctly?”
>
> Apart from this, life tests against the public internet are flaky and not well suited for a determninistic PR gate. They are non-deterministic: Because of non-controllable external variables (network latency, 3rd part API downtime etc.) non-determinsitic tests can produce different outputs - for the same inputs.             
>
> In short: If a non-deterministic test fails, the code might be broken - or the network, or the database, or Cloudflare...
>
> For this rasons, those two concerns stay separated on purpose. The live path follows in the next step.

> [!NOTE] **🧭 Regression**
>
> In software testing, a **regression** means that a previously working behavior stops working correctly after a change.
>
> Typical examples:
>
> - A helper test that used to pass now fails
> - A Dockerfile hardening change breaks the container startup
> - A dependency update introduces a new incompatibility
> - A refactor keeps the code cleaner but unintentionally breaks existing behavior
>
> A CI gate helps catch such regressions before the change is merged into the default branch.

### Action

The goal of this step is to establish a first **GitHub Actions PR gate** for **deterministic validation**:
- **(1)** Map the existing owned Make targets into CI jobs
- **(2)** Create a workflow with stable job names for later branch protection
- **(3)** Keep the workflow intentionally deterministic and fast enough for pull-request use

#### Mapping the existing local validation targets into CI

We will reuse the deterministic Make targets already created earlier in Phase 07:

- **`make p07-tests`**
  - Aggregate deterministic code/test validation (Ruby, Bash, Python)
    - p07-healthcheck-tests (Ruby)
	- p07-traffic-helper-tests (Bash)
	- p07-contract-guard-tests (Python)
- **`make p07-trivy-healthcheck-repo-scan`**
  - Focused Trivy repo scan for `healthcheck/`
- **`make p07-trivy-healthcheck-image-scan`**
  - Focused Trivy healthcheck image vulnerability scan 

This keeps the local and CI execution paths aligned:

- Local reruns use the same targets
- GitHub Actions uses the same targets
- Later branch protection can require the exact same job results

#### Creating the workflow file: `.github/workflows/phase-07-deterministic-pr-gate.yml`

The workflow below acts as a **pre-merge gate for pull requests**. 
- It validates stable checks **before changes reach the default branch**. 
- The actual **deployment workflow remains separate** and runs on its own trigger **after merge or manual execution**.

The workflow 
- implements **3 separate, purely deterministic jobs** to avoid live checks with flaky MR/PR blocking from public-edge/network/browser conditions. 
- utilizes **existing Make targets only** to avoid a duplication of test logic between local and CI execution. 

~~~yaml
# .github/workflows/phase-07-deterministic-pr-gate.yml
#
# Phase 07 - Deterministic PR Gate
#
# Purpose:
# Run the deterministic, repo-owned validation bundle on pull requests 
# targeting the default branch. 
#
# This workflow intentionally excludes live/environment-dependent checks 
# (such as Playwright smoke runs against the deployed edge) to prevent 
# temporary network issues from blocking code merges.

name: Phase 07 - Deterministic PR Gate

on:
  # Run automatically for pull requests targeting the protected default branch.
  pull_request:
    branches:
      - master

  # Allow manual reruns from the GitHub Actions UI.
  workflow_dispatch:

# Keep the default token minimal.
permissions:
  contents: read

# Cancel older runs for the same ref when a newer commit is pushed.
concurrency:
  group: phase-07-deterministic-pr-gate-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # ---------------------------------------------------------------------------
  # 1) Deterministic repo-owned test bundle
  # ---------------------------------------------------------------------------
  # Reuses the existing Make target from local development:
  # - Ruby helper tests
  # - Bash helper tests
  # - local Python contract-guard tests
  p07-deterministic-tests:
    name: p07-deterministic-tests
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
      # Check out the repository contents for this PR revision.
      - name: Checkout repository
        uses: actions/checkout@v4

      # Install a Ruby runtime for the repo-owned Ruby helper tests.
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.2"

      # Install a Python runtime for the repo-owned Python test path.
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      # Execute the deterministic validation bundle.
      - name: Run deterministic Phase 07 validation bundle
        run: make p07-tests

  # ---------------------------------------------------------------------------
  # 2) Focused repo-level Trivy gate for the owned healthcheck path
  # ---------------------------------------------------------------------------
  # This is intentionally the focused path-specific scan, not the broad repo
  # baseline, so the PR gate only blocks on the currently owned/remediated scope.
  p07-trivy-healthcheck-repo-scan:
    name: p07-trivy-healthcheck-repo-scan
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      # Check out the repository so Trivy can scan the current PR content.
      - name: Checkout repository
        uses: actions/checkout@v4

      # Reuse the focused repo-level Trivy scan already proven locally.
      - name: Run focused Trivy repo scan for healthcheck
        run: make p07-trivy-healthcheck-repo-scan

  # ---------------------------------------------------------------------------
  # 3) Owned image vulnerability gate
  # ---------------------------------------------------------------------------
  # Rebuild the repo-owned healthcheck image and scan that image in CI.
  p07-trivy-healthcheck-image-scan:
    name: p07-trivy-healthcheck-image-scan
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
      # Check out the repository so Docker can build the owned image.
      - name: Checkout repository
        uses: actions/checkout@v4

      # Reuse the existing Make target that builds and scans the owned image.
      - name: Run Trivy image scan for healthcheck
        run: make p07-trivy-healthcheck-image-scan
~~~

#### Why the broad Trivy repo baseline is not used as the PR gate

As noted in Step 9 (Healthcheck Dockerfile Hardening), the broader target `make p07-trivy-repo-scan` currently surfaces **additional findings outside the focused `healthcheck/` remediation path**. This Make target functions as **Legacy Hardening Backlog** and will be addressed again in later phases. At this point, before its remediation, it is therefore not suitable to be used in the current PR gate workflow. 

For the deterministic PR gate in this step, the correct Trivy repo target is `make p07-trivy-healthcheck-repo-scan` - because it blocks only on the **owned and already-remediated `healthcheck/`-path**, that is under active control.


#### Trigger behavior of the workflow

This workflow is triggered by:

- **Pull requests targeting `master`**
- **Manual workflow dispatch**

This gives us two useful execution paths:

- **Normal PR validation**
- **Manual rerun/debug run** from the Actions tab when needed

A `push` trigger is intentionally not required for this step. The main purpose here is to establish the merge-relevant PR gate first.

#### Running and verifying the workflow

Once the workflow file is committed and pushed, opening a pull request targeting `master` will have this outcome in **GitHub Actions**:

- Workflow: **Phase 07 - Deterministic PR Gate**
- Jobs:
  - **p07-deterministic-tests**
  - **p07-trivy-healthcheck-repo-scan**
  - **p07-trivy-healthcheck-image-scan**

A successful run should show all three jobs green.

#### Relationship to the next step

This step establishes the **deterministic PR gate**.

The next step adds the **separate live/environment workflow**, for example:

- Playwright smoke tests
- live Python contract smoke checks

Only after the deterministic workflow has run successfully and its job names are stable does it make sense to finalize **branch protection** with required status checks.

### Result

Step 11 establishes the first **deterministic GitHub Actions PR gate** for Phase 07.

The successful end state is shown by these signals / verification points:

- The repository now contains a dedicated workflow:
  - `.github/workflows/phase-07-deterministic-pr-gate.yml`
- The workflow reuses the already established deterministic local validation targets:
  - `make p07-tests`
  - `make p07-trivy-healthcheck-repo-scan`
  - `make p07-trivy-healthcheck-image-scan`
- The workflow intentionally excludes live/environment-dependent checks
- The job names are stable and suitable for later branch-protection enforcement
- Local and CI execution paths now stay aligned through the same Make targets
- The repository is now prepared for:
  - a separate live smoke workflow in the next step
  - required status-check enforcement through branch protection afterward

At this point, the **Phase 07 Test & Security Layer** validates:
- **(1) Service health/reachability** (Ruby)
- **(2) Helper-script behavior (Traffic Generator)** (Bash)
- **(3) API response-shape compatibility** (Python)
- **(4) Storefront rendering in a real browser** (Playwright / JavaScript)
- **(5) Security-scanning for repo-owned surfaces** (Trivy)
- **(6) Evidence-based security remediation on a repo-owned Docker image path** (Trivy + hardened `healthcheck` image)
- **(7) Dependency-scanning for repo-owned dependency surfaces** (Dependabot)
- **(8) Deterministic PR-gate validation in CI** (GitHub Actions)

The next step is now clear: **wire the live/environment-dependent validation path into a separate GitHub Actions workflow.**