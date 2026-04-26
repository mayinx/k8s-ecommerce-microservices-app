# Runbook — Phase 07 Security Testing

> ## 👤 About
> This runbook provides the short rerun path for **Phase 07 (Security Testing)**.
>
> It covers the Phase 07 deterministic tests, live smoke checks, focused Trivy scans, and GitHub-side validation paths.
>
> For the full implementation story, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.  
> For phase-local decisions, see: **[DECISIONS.md](./DECISIONS.md)**.  
> For setup-only prerequisites, see: **[SETUP.md](./SETUP.md)**.

---

## 📌 Index

- [Quick command map](#quick-command-map)
- [Local deterministic checks](#local-deterministic-checks)
- [Live smoke checks](#live-smoke-checks)
- [Security scans](#security-scans)
- [Full local Phase 07 check path](#full-local-phase-07-check-path)
- [GitHub validation paths](#github-validation-paths)
- [Recommended usage](#recommended-usage)

---

## Quick command map

| Command | What it checks | Used by CI? |
| :--- | :--- | :--- |
| `make p07-tests` | Deterministic Ruby, Bash, and Python checks | Yes, in `p07-deterministic-tests` |
| `make p07-healthcheck-tests` | Ruby syntax, CLI characterization test, and unit tests for `healthcheck.rb` | Indirectly through `p07-tests` |
| `make p07-traffic-helper-tests` | Bash syntax and tests for the Observability Traffic Generator | Indirectly through `p07-tests` |
| `make p07-contract-guard-tests` | Python virtual environment, syntax check, and local contract-guard tests | Indirectly through `p07-tests` |
| `make p07-contract-guard-live-dev` | Live `/catalogue` contract smoke against `dev` | No |
| `make p07-e2e-smoke-dev` | Playwright browser smoke against `dev` | No |
| `make p07-tests-live` | Live Python contract smoke + Playwright browser smoke | Yes, in the optional live-smoke workflow |
| `make p07-trivy-healthcheck-repo-scan` | Focused Trivy filesystem scan for `healthcheck/` | Yes, required PR check |
| `make p07-trivy-healthcheck-image-scan` | Rebuild and scan the repo-owned `sockshop-healthcheck` image | Yes, required PR check |
| `make p07-trivy-repo-scan` | Broader Trivy scan over selected repo-owned paths | No |
| `make p07-tests-all` | Deterministic checks + live smoke checks | No |

---

## Local deterministic checks

Use this before committing changes that touch Phase 07 test logic, helper scripts, or validation code:

~~~bash
make p07-tests
~~~

This runs the deterministic local Phase 07 test bundle:

- Ruby `healthcheck` checks
- Bash Observability Traffic Generator checks
- Python `/catalogue` contract-guard checks

It expands to:

~~~bash
make p07-healthcheck-tests
make p07-traffic-helper-tests
make p07-contract-guard-tests
~~~

### Ruby healthcheck checks

~~~bash
make p07-healthcheck-tests
~~~

Runs:

- Ruby syntax validation for `healthcheck/healthcheck.rb`
- CLI characterization tests for the external command-line contract
- Unit tests for the refactored `HealthChecker` class

Use this after editing:

- `healthcheck/healthcheck.rb`
- `tests/ruby/test_healthcheck_cli.rb`
- `tests/ruby/test_healthcheck.rb`

Optional milestone proof against the remote target cluster:

~~~bash
make p07-healthcheck-target-env
~~~

This runs the local Ruby helper against the remote `sock-shop-dev` namespace through a temporary Ruby Pod. It is useful after larger `healthcheck` changes, but it is not part of the required PR gate.

### Bash Observability Traffic Generator checks

~~~bash
make p07-traffic-helper-tests
~~~

Runs:

- Bash syntax validation for `scripts/observability/generate-sockshop-traffic.sh`
- Bash syntax validation for `tests/bash/test_generate_sockshop_traffic.sh`
- CLI and function-level tests for the refactored traffic helper

Use this after editing:

- `scripts/observability/generate-sockshop-traffic.sh`
- `tests/bash/test_generate_sockshop_traffic.sh`

### Python contract-guard checks

~~~bash
make p07-contract-guard-tests
~~~

Runs:

- Local Python virtual environment setup/update
- Python syntax validation
- Local deterministic pytest suite for the `/catalogue` contract guard

Use this after editing:

- `tests/python/sockshop_contract_guard.py`
- `tests/python/test_contract_guard.py`
- `tests/python/requirements-p07.txt`

---

## Live smoke checks

Live checks validate deployed environments and are intentionally separate from the deterministic merge gate.

### Live API contract smoke

~~~bash
make p07-contract-guard-live-dev
make p07-contract-guard-live-prod
~~~

These reuse the Python `/catalogue` contract guard against the deployed `dev` or `prod` endpoint.

For local port-forward debugging:

~~~bash
kubectl port-forward -n sock-shop-dev svc/catalogue 18080:80
make p07-contract-guard-live-local
~~~

### Playwright browser smoke

~~~bash
make p07-e2e-smoke-dev
make p07-e2e-smoke-prod
~~~

These run the Chromium-only Playwright smoke suite against the selected live storefront.

The browser smoke checks verify:

- Storefront root loads
- Key landing-page content is visible
- At least one catalogue image renders

To inspect the latest local Playwright report:

~~~bash
make p07-e2e-report
~~~

### Combined live smoke bundle

~~~bash
make p07-tests-live
~~~

This runs:

- Live Python `/catalogue` contract smoke
- Playwright browser smoke

`BASE_URL` can be injected externally, for example by GitHub Actions:

~~~bash
BASE_URL=https://prod-sockshop.cdco.dev make p07-tests-live
~~~

---

## Security scans

### Focused `healthcheck/` repo scan

~~~bash
make p07-trivy-healthcheck-repo-scan
~~~

This runs the focused Trivy filesystem scan for the remediated `healthcheck/` path.

It checks for:

- Misconfigurations
- Secrets
- HIGH / CRITICAL findings

This target is part of the required GitHub PR gate.

### Healthcheck image scan

~~~bash
make p07-trivy-healthcheck-image-scan
~~~

This target:

- Builds the repo-owned `sockshop-healthcheck` image
- Exports it as a tar file
- Scans it with Trivy in vulnerability mode

This target is part of the required GitHub PR gate.

### Broader Trivy baseline

~~~bash
make p07-trivy-repo-scan
~~~

This scans selected repo-owned paths:

- `healthcheck`
- `scripts`
- `deploy/kubernetes`
- `.github`
- `tests`

This target is useful for broader hardening review, but it is intentionally not part of the required PR gate because it can expose backlog outside the focused `healthcheck/` remediation path.

---

## Full local Phase 07 check path

~~~bash
make p07-tests-all
~~~

This runs:

- `make p07-tests`
- `make p07-tests-live`

Use it for milestone checks, not as the normal fast pre-commit command.

---

## GitHub validation paths

### Required deterministic PR gate

Workflow:

~~~text
.github/workflows/phase-07-deterministic-pr-gate.yml
~~~

Required jobs:

- `p07-deterministic-tests`
- `p07-trivy-healthcheck-repo-scan`
- `p07-trivy-healthcheck-image-scan`

The workflow runs on pull requests targeting `master`.

The required jobs map to these Make targets:

~~~bash
make p07-tests
make p07-trivy-healthcheck-repo-scan
make p07-trivy-healthcheck-image-scan
~~~

These checks are enforced through the default-branch ruleset.

### Optional live-smoke workflow

Workflow:

~~~text
.github/workflows/phase-07-live-smoke.yml
~~~

Main job:

- `p07-live-smoke`

This workflow runs:

~~~bash
make p07-tests-live
~~~

It is available for manual live validation and later workflow reuse, but it is not required for merging into `master`.

---

## Recommended usage

### Before committing normal Phase 07 helper/test changes

~~~bash
make p07-tests
~~~

### Before opening or updating a pull request

~~~bash
make p07-tests
make p07-trivy-healthcheck-repo-scan
make p07-trivy-healthcheck-image-scan
~~~

### After editing `healthcheck/Dockerfile`

~~~bash
make p07-healthcheck-tests
make p07-trivy-healthcheck-repo-scan
make p07-trivy-healthcheck-image-scan
~~~

### After editing live smoke checks

~~~bash
make p07-tests-live
~~~

### After a deployment or manual environment check

~~~bash
make p07-contract-guard-live-dev
make p07-e2e-smoke-dev
~~~

For production:

~~~bash
make p07-contract-guard-live-prod
make p07-e2e-smoke-prod
~~~

---

## Notes

- `make p07-tests` is the normal fast deterministic local validation path.
- The required PR gate uses deterministic checks only.
- Live smoke checks are useful environment validation, but not required merge blockers.
- The broad Trivy repo scan remains useful for hardening backlog discovery, but the required PR gate uses only the focused remediated `healthcheck/` scan and image scan.