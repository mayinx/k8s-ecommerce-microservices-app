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

---


## Step 12 — Wire the live smoke checks into a GitHub Actions workflow for deployed environments

### Rationale

Now we need to implement a **GitHub-native live validation workflow** for the already deployed application environments. 

This **separate live smoke workflow** will validate the deployed storefront against a chosen target environment, using exsiting **Python and Playwright live smoke tests**. It's purpose is not broad feature testing. It is a focused check that the deployed storefront still behaves correctly at a small but meaningful level:

- The **live application URL** responds
- The **catalogue API** still returns the expected **response shape**
- The **storefront** still **renders key visible content** in a **real browser**

This workflow is intentionally kept **separate from the PR gate** because it depends on a deployed environment and can therefore be affected by factors outside the pull request itself.  

#### Scope

- **1 GitHub Actions workflow** for live smoke validation
- **Manual execution through `workflow_dispatch`**
- **Optional later reuse through `workflow_call`**
- **Support for both `dev` and `prod`**
- Reuse of the already existing **Phase-07 live smoke test bundle**:
  - Python live contract smoke
  - Playwright browser smoke

#### Environment separation through GitHub repository variables

This workflow validates **deployed environments**, not only repository code. It therefore needs a target-specific **base URL**.
The environment separation is handled through separate GitHub repository variables:

- `P07_DEV_BASE_URL`
- `P07_PROD_BASE_URL`

This also reinforces the multi-environment requirement by keeping `dev` and `prod` configuration values explicitly separated.

### Action

The goal of this step is to establish a first **GitHub-native live smoke workflow** for the deployed storefront:
- **(1)** Define the environment-specific base-URLs 
- **(2)** Create the live-smoke GitHub Actions workflow
- **(3)** Reuse the already existing local live smoke test bundle in CI
- **(4)** Produce a clean post-run artifact for Playwright evidence and debugging

#### Defining the environment-specific base URLs

**Public environment URLs should not be hard-coded** directly into the workflow file.  

Instead, we define the two URLs as **GitHub repository variables**:

- `P07_DEV_BASE_URL` = `https://dev-sockshop.cdco.dev`
- `P07_PROD_BASE_URL` = `https://prod-sockshop.cdco.dev`

These values can be configured in the GitHub repository UI under:

- Settings > Secrets and variables > Actions > Tab "Variables" > Button "New repository variable" 

This keeps the workflow configuration clean and makes environment changes easier later without editing the workflow YAML itself.

#### Creating the live-validation workflow: `.github/workflows/phase-07-live-smoke.yml`

#### Expected live workflow execution path

The reusable live-validation workflow established here follows this execution path:

- **(1)** Resolve the selected target environment
- **(2)** Resolve the matching base URL from repository variables
- **(3)** Set up Python and Node.js
- **(4)** Run the existing `make p07-tests-live` bundle
- **(5)** Upload the Playwright report and test-results as GitHub Actions artifacts

This means the workflow validates both existing live Phase-07 surfaces in one CI run:

- **Python live contract smoke**
- **Playwright live browser smoke**

For this, the workflow reuses the already existing Phase-07 live smoke bundle via the environment-agnostic Make target `p07-tests-live`, instead of introducing CI-specific test execution commands or additional Make targets:

- The same smoke tests are usable **locally** and in **CI**
- Live-validation behavior stays defined in **one place**
- Environment selection happens through **inputs + variables**
- The workflow is already structured for later reuse through `workflow_call`

~~~yaml
# .github/workflows/phase-07-live-smoke.yml
#
# Phase 07 - Reusable Live Validation Workflow
#
# Purpose:
#   Validate already deployed environments (dev/prod) using the existing Phase 07
#   live smoke bundle:
#   - Python API contract smoke tests
#   - Playwright browser smoke tests
#
# Scope & Strategy:
#   This workflow is intentionally separate from the required PR gate.
#   Because it validates a deployed environment, results can be influenced by
#   factors outside the pull request itself, such as target availability,
#   deployed runtime state, and browser timing.
#
# Trigger Model:
#   - workflow_dispatch : Manual on-demand validation from the GitHub Actions UI
#   - workflow_call     : Reusable hook for automated post-deployment validation
#
# Environment Handling:
#   Target environments (dev/prod) and base URLs are resolved dynamically via
#   repository variables or explicit workflow_call inputs.
#
# Usage Example (via workflow_call):
# ---------------------------------------------------------------------------
# jobs:
#   verify-prod-deployment:
#     uses: ./.github/workflows/phase-07-live-smoke.yml
#     with:
#       target_environment: "prod"
#       base_url: "https://prod-sockshop.cdco.dev"
# ---------------------------------------------------------------------------

name: Phase 07 - Live Smoke

on:
  # Manual trigger for ad-hoc environment validation
  workflow_dispatch:
    inputs:
      target_environment:
        description: "Deployed environment to validate"
        required: true
        type: choice
        options:
          - dev
          - prod
        default: dev

  # Reusable workflow hook for automated post-deployment validation
  # (i.e. reusable by another GitHub Actiosn workflow)
  workflow_call:
    inputs:
      target_environment:
        description: "Deployed environment to validate"
        required: true
        type: string
      base_url:
        description: "Optional explicit base URL override"
        required: false
        type: string

# Security: Enforce principle of least privilege
permissions:
  contents: read

jobs:
  # ---------------------------------------------------------------------------
  # 1) Live Environment Validation Bundle
  # ---------------------------------------------------------------------------
  p07-live-smoke:
    name: p07-live-smoke
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      # Provide runtime for the Python API contract-guard tests
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      # Provide runtime for the Playwright E2E browser tests
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"

      # -----------------------------------------------------------------------
      # Dynamic Target Environment Resolution
      # -----------------------------------------------------------------------
      # Resolve the target environment and choose the matching base URL.
      #
      # Resolution order:
      # 1) Explicit workflow_call input `base_url`
      # 2) Repository variable P07_PROD_BASE_URL (for prod)
      # 3) Repository variable P07_DEV_BASE_URL (for dev)
      - name: Resolve live target URL
        id: resolve-target
        shell: bash
        env:
          INPUT_TARGET_ENVIRONMENT: ${{ inputs.target_environment }}
          INPUT_BASE_URL: ${{ inputs.base_url }}
          DEV_BASE_URL: ${{ vars.P07_DEV_BASE_URL }}
          PROD_BASE_URL: ${{ vars.P07_PROD_BASE_URL }}
        run: |
          # Default to 'dev' if the target environment is not explicitly passed.
          target_environment="${INPUT_TARGET_ENVIRONMENT:-dev}"
          base_url="${INPUT_BASE_URL:-}"

          # Fallback to repository variables if no explicit base_url override is provided
          if [ -z "$base_url" ]; then
            case "$target_environment" in
              dev)
                base_url="$DEV_BASE_URL"
                ;;
              prod)
                base_url="$PROD_BASE_URL"
                ;;
              *)
                echo "ERROR: Unsupported target_environment: $target_environment" >&2
                exit 1
                ;;
            esac
          fi

          # Fail workflow immediately if base URL is still empty.
          if [ -z "$base_url" ]; then
            echo "ERROR: No base URL resolved for environment '$target_environment'." >&2
            echo "Set repository variable P07_DEV_BASE_URL / P07_PROD_BASE_URL or pass base_url explicitly." >&2
            exit 1
          fi

          echo "target_environment=$target_environment" >> "$GITHUB_OUTPUT"
          echo "base_url=$base_url" >> "$GITHUB_OUTPUT"

      # Print the resolved target in the workflow logs for traceability.
      - name: Show resolved live target
        shell: bash
        run: |
          echo "Resolved target environment: ${{ steps.resolve-target.outputs.target_environment }}"
          echo "Resolved target base URL:    ${{ steps.resolve-target.outputs.base_url }}"

      # -----------------------------------------------------------------------
      # Live Smoke Tests Execution & Artifacts
      # -----------------------------------------------------------------------
      # Execute the live smoke test bundle against the resolved target environment.
      #
      # BASE_URL is injected explicitly into the environment-agnostic Make target
      # `p07-tests-live`, which passes it on to:
      # - Python live contract smoke tests
      # - Playwright browser smoke tests
      #
      # CI=true activates the CI-aware Playwright behavior already defined in
      # the Phase-07 Playwright configuration.
      - name: Run Phase 07 live smoke test bundle
        shell: bash
        env:
          BASE_URL: ${{ steps.resolve-target.outputs.base_url }}
          CI: "true"
        run: make p07-tests-live

      # Preserve the Playwright HTML report for debugging, even if the job fails.
      # The report is uploaded to GitHub Actions artifact storage and can be
      # downloaded from the workflow run page.
      - name: Upload Playwright HTML report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: p07-playwright-report-${{ steps.resolve-target.outputs.target_environment }}
          path: tests/e2e/playwright-report
          if-no-files-found: ignore
          retention-days: 7

      # Preserve deep-dive artifacts (traces, screenshots) on failure
      - name: Upload Playwright test-results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: p07-playwright-test-results-${{ steps.resolve-target.outputs.target_environment }}
          path: tests/e2e/test-results
          if-no-files-found: ignore
          retention-days: 7
~~~

#### Triggering the first live workflow run

After the workflow file is committed and pushed, the first live run can be started through the GitHub Actions UI:

- Actions > "Phase 07 - Live Smoke" > Run workflow
- Select branch 
- Select `target_environment`
- Run workflow

A first run should be executed against **`dev`**. 

### Result

Step 12 establishes the first **GitHub-native live smoke workflow** for deployed environments in Phase 07.

The successful end state is shown by these signals / verification points:

- The repository now contains a dedicated live-validation workflow:
  - `.github/workflows/phase-07-live-smoke.yml`
- The workflow is explicitly **environment-aware**:
  - `dev` and `prod` are selected through a workflow input
  - the matching base URLs are resolved from separate repository variables
- The workflow reuses the already existing **Phase-07 live smoke bundle**
  - Python live contract smoke
  - Playwright browser smoke
- The workflow remains intentionally **separate from the deterministic PR gate**
- The workflow uploads **Playwright artifacts** for later inspection and debugging
- The workflow is already shaped for two usage modes:
  - **manual live validation** through `workflow_dispatch`
  - **later reuse from another workflow** through `workflow_call`

At this point, the **Phase 07 Test & Security Layer** validates:

- **(1) Service health/reachability** (Ruby)
- **(2) Helper-script behavior (Traffic Generator)** (Bash)
- **(3) API response-shape compatibility** (Python)
- **(4) Storefront rendering in a real browser** (Playwright / JavaScript)
- **(5) Security-scanning for repo-owned surfaces** (Trivy)
- **(6) Evidence-based security remediation on a repo-owned Docker image path** (Trivy + hardened `healthcheck` image)
- **(7) Dependency-scanning for repo-owned dependency surfaces** (Dependabot)
- **(8) Stable PR-gate validation in GitHub Actions** (deterministic workflow)
- **(9) Live deployed-environment smoke validation in GitHub Actions** (manual / reusable live-smoke workflow)

The next step is now clear: 
- Apply repository governance by locking the default branch to the stable PR-gate checks
- While keeping the live workflow available as an explicit post-deploy validation path. 

---