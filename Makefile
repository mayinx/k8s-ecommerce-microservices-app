# Project Makefile
# Purpose:
# - keep repeated local verification and rerun commands short and consistent
# - provide thin phase-scoped helper targets on top of the documented raw commands

# -----------------------------------------------------------------------------
# Tooling and local environment defaults
# -----------------------------------------------------------------------------

MAKE_CMD        := make
KUBECTL         := kubectl
CURL            := curl
RUBY            := ruby

E2E_DIR := tests/e2e

REMOTE_KUBECONFIG ?= $(HOME)/.kube/config-proxmox-dev.yaml

P02_INGRESS_FILE := deploy/kubernetes/manifests-local/phase-02-front-end-ingress.yaml

P03_DEV_OVERLAY  := deploy/kubernetes/kustomize/overlays/dev
P03_PROD_OVERLAY := deploy/kubernetes/kustomize/overlays/prod

P06_KUBECONFIG  := $(HOME)/.kube/config-proxmox-dev.yaml
P06_TRAFFIC_HELPER := ./scripts/observability/generate-sockshop-traffic.sh

P07_HEALTHCHECK_FILE := healthcheck/healthcheck.rb
P07_HEALTHCHECK_CLI_TEST := tests/ruby/test_healthcheck_cli.rb
P07_HEALTHCHECK_UNIT_TEST := tests/ruby/test_healthcheck.rb
P07_HEALTHCHECK_TARGET_HELPER := ./scripts/testing/run-healthcheck-target-env.sh

P07_TRAFFIC_HELPER_FILE := scripts/observability/generate-sockshop-traffic.sh
P07_TRAFFIC_HELPER_TEST := tests/bash/test_generate_sockshop_traffic.sh

P07_PYTHON_BIN := tests/venv/p07-python/bin/python
P07_PYTHON_REQUIREMENTS := tests/python/requirements-p07.txt
P07_CONTRACT_GUARD_FILE := tests/python/sockshop_contract_guard.py
P07_CONTRACT_GUARD_TEST := tests/python/test_contract_guard.py

P07_CONTRACT_GUARD_LIVE_TEST := tests/python/test_contract_guard_live.py

# Shared live-target base URLs for Phase 07: 
# - Generic live targets can still be redirected externally via BASE_URL
#   (for example by GitHub Actions).
# - Named dev/prod/local convenience targets are pinned to these fixed URLs.
P07_DEV_BASE_URL := https://dev-sockshop.cdco.dev
P07_PROD_BASE_URL := https://prod-sockshop.cdco.dev
P07_LOCAL_BASE_URL := http://127.0.0.1:18080

P07_E2E_TEST := smoke.spec.js

P07_TRIVY_IMAGE ?= aquasec/trivy:latest
P07_TRIVY_SEVERITY ?= HIGH,CRITICAL
P07_TRIVY_CACHE_VOLUME := trivy-cache
P07_TRIVY_TMP_DIR := /tmp/p07-trivy
P07_HEALTHCHECK_IMAGE := sockshop-healthcheck
P07_HEALTHCHECK_IMAGE_TAR := $(P07_TRIVY_TMP_DIR)/sockshop-healthcheck.tar

# Directory that contains the Phase 08 Terraform Smoke-VM configuration.
P08_TF_DIR := infra/terraform/proxmox-smoke-vm

# Phase 09 DR backup helper script.
P09_DR_BACKUP_SCRIPT := scripts/dr/backup-k8s-namespace.sh

# -----------------------------------------------------------------------------
# Make recipe syntax notes
# -----------------------------------------------------------------------------
#
# Notes on recurring Makefile syntax / patterns / recipes used in target commands:
#
# - @command
#   Run the command without Make echoing the raw command line first.
#   This keeps output focused on controlled status messages instead of
#   repeating every shell command verbatim.
# 	Note: '@' only hides the raw comamnd line - it does not swallow errors.
#   On error, the Make target execution is stopped imemdiately and exits 
# 	non zero - any other code in the recipe after that command is never reached.
#	This is also true for recursive / nested make calls, which propagate 
#	failure upward.  	 
#	This is especially useful for the phase 07 testing make targets and
#	their recipes - especially for aggregated make targets   	
#
# - @echo "..."
#   Print a short, human-readable status line intentionally.
#   Used when explicit output is helpful even though the raw command itself
#   stays hidden via '@'.
#
# - @# comment
#   Shell-side comment line inside a recipe.
#   This is useful for short inline explanations directly above a recipe
#   command. A plain Make comment ('# ...') outside a recipe would not execute
#   as part of the recipe itself.
#
# - @$(MAKE_CMD) target
#   Recursive Make call using the configured Make command variable.
#   This is used for aggregate targets that delegate to smaller helper targets.
#
# - --no-print-directory
#   Suppresses recursive Make noise such as:
#   "Entering directory ..." / "Leaving directory ..."
#   This keeps aggregate-target output compact and easier to scan.
#
# - @if ...; then ...; else ...; fi
#   Inline shell conditional used inside a recipe.
#   Typically used for validation steps that print a controlled OK/FAIL
#   message and then exit non-zero on failure.
#
# - exit 1 / non-zero exit code
#   `exit 1` fails the current recipe deliberately.
#   In Make, any non-zero exit code means failure.
#   This is used after controlled FAIL messages so the target stops cleanly.
#   Recursive `make` calls propagate that failure upward as well.
#
# - \  (line continuation)
#   Continues one shell command across multiple Makefile lines for readability.
#   Commonly used for longer conditionals or wrapped commands.
#
# - $$VARIABLE
#   Escaped dollar sign for the shell.
#   In Makefiles, '$' is special to Make itself, so '$$' is required when the
#   shell should receive a literal '$' (for example: "$$PWD").
#
# - ?=
#   Assign a default value only if the variable is not already set from the
#   environment or command line. Useful for overridable defaults where caller
#   overrides should remain possible.
#
# - :=
#   Assign a simply-expanded Make variable.
#   The right-hand side is evaluated once when Make reads the file, not every
#   time the variable is used.
#   Example:
#     P09_DR_BACKUP_SCRIPT := scripts/dr/backup-k8s-namespace.sh
#   This is useful for stable helper paths and fixed command defaults.
#
# - =
#   Assign a recursively-expanded Make variable.
#   The right-hand side is expanded each time the variable is used.
#   Example:
#     REPORT_PATH = $(LATEST_BACKUP)/db/backup-report.txt
#   This can be useful for dynamic values, but it can also make simple helper
#   paths harder to reason about.
#
# These patterns are used repeatedly in the Phase 07 targets to keep the output
# compact, readable, and CI-friendly: 
# - Aggregate targets stay mostly noiseless,
# - Important status lines remain visible, 
# - Failures still propagate through proper non-zero exit codes.
#
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Phony
# -----------------------------------------------------------------------------

# Public helper targets that do not correspond to real files.
# Declaring them as .PHONY ensures Make always runs the target recipe when requested.
.PHONY: \
	help \
	gen-complete-demo \
	check-generated-files \
	p02-ingress-apply \
	p02-ingress-show \
	p02-ingress-test-host-header \
	p02-ingress-test-browser-url \
	p02-ingress-delete \
	p02-nodeport-test \
	p03-render-overlays \
	p03-render-dev \
	p03-render-prod \
	p03-dev-apply \
	p03-dev-status \
	p03-dev-rollouts \
	p03-dev-recreate \
	p06-monitoring-status \
	p06-grafana-port-forward \
	p06-prometheus-port-forward \
	p06-traffic-dev-preset \
	p06-traffic-dev-live \
	p06-traffic-prod-preset \
	p06-traffic-prod-live \
	p07-healthcheck-syntax \
	p07-healthcheck-cli-test \
	p07-healthcheck-unit-test \
	p07-healthcheck-tests \
	p07-healthcheck-target-env \
	p07-traffic-helper-syntax \
	p07-traffic-helper-test-syntax \
	p07-traffic-helper-test \
	p07-traffic-helper-tests \
	p07-python-venv \
	p07-contract-guard-syntax \
	p07-contract-guard-test \
	p07-contract-guard-tests \
	p07-contract-guard-live-test \
	p07-contract-guard-live-dev \
	p07-contract-guard-live-prod \
	p07-contract-guard-live-local \
	p07-e2e-install \
	p07-e2e-smoke \
	p07-e2e-smoke-dev \
	p07-e2e-smoke-prod \
	p07-e2e-report \
	p07-tests \
	p07-tests-live \
	p07-tests-all \
	p07-trivy-repo-scan \
	p07-trivy-healthcheck-repo-scan \
	p07-trivy-healthcheck-image-scan \
	p07-trivy-scans \
	p08-tf-init \
	p08-tf-validate \
	p08-tf-plan \
	p08-tf-apply \
	p08-tf-destroy \
	p09-dr-script-syntax \
	p09-dr-backup-dev \
	p09-dr-backup-prod \
	p09-dr-print-report-dev \
	p09-dr-print-report-prod	

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

help:
	@echo "Available targets:"
	@echo "  gen-complete-demo          - Run upstream complete-demo generation helper"
	@echo "  check-generated-files      - Run upstream generated-files check"
	@echo "  p02-ingress-apply          - Apply the Phase 02 local ingress manifest"
	@echo "  p02-ingress-show           - Show and describe the Phase 02 ingress"
	@echo "  p02-ingress-test-host-header - Test Traefik host-based routing before hosts edit"
	@echo "  p02-ingress-test-browser-url - Test browser-style hostname URL after hosts edit"
	@echo "  p02-ingress-delete         - Delete the Phase 02 ingress manifest"
	@echo "  p02-nodeport-test          - Re-check the Phase 01 NodePort fallback"
	@echo "  p03-render-overlays        - Render the Phase 03 dev/prod overlays locally"
	@echo "  p03-render-dev             - Render the Phase 03 dev overlay"
	@echo "  p03-render-prod            - Render the Phase 03 prod overlay"
	@echo "  p03-dev-apply             - Apply the Phase 03 dev overlay"
	@echo "  p03-dev-status            - Show Phase 03 dev resources"
	@echo "  p03-dev-rollouts          - Check key Phase 03 dev rollouts"
	@echo "  p03-dev-recreate          - Delete and recreate the Phase 03 dev namespace"
	@echo "  p06-monitoring-status      - Show Phase 06 monitoring pods and services"
	@echo "  p06-grafana-port-forward   - Open the private Grafana port-forward"
	@echo "  p06-prometheus-port-forward - Open the private Prometheus port-forward"
	@echo "  p06-traffic-dev-preset     - Run the observability traffic helper against dev with preset data"
	@echo "  p06-traffic-dev-live       - Run the observability traffic helper against dev with live-discovered data"
	@echo "  p06-traffic-prod-preset    - Run the observability traffic helper against prod with preset data"
	@echo "  p06-traffic-prod-live      - Run the observability traffic helper against prod with live-discovered data"	
	@echo "  p07-healthcheck-syntax     - Validate Ruby syntax of the Phase 07 healthcheck helper"
	@echo "  p07-healthcheck-cli-test   - Run the Phase 07 Ruby CLI characterization test"
	@echo "  p07-healthcheck-unit-test  - Run the Phase 07 Ruby unit-test suite"
	@echo "  p07-healthcheck-tests      - Run all local Phase 07 Ruby healthcheck checks"
	@echo "  p07-healthcheck-target-env - Run the Phase 07 healthcheck helper (local version) against the remote target cluster"
	@echo "  p07-traffic-helper-syntax  - Validate Bash syntax of the Phase 07 observability helper"
	@echo "  p07-traffic-helper-test-syntax - Validate Bash syntax of the Phase 07 Bash test file"
	@echo "  p07-traffic-helper-test    - Run the Phase 07 Bash observability-helper tests"
	@echo "  p07-traffic-helper-tests   - Run all local Phase 07 Bash observability-helper checks"
	@echo "  p07-python-venv            - Create/update the local Phase 07 Python virtual environment"
	@echo "  p07-contract-guard-syntax  - Validate Python syntax of the Phase 07 contract-guard module and test file"
	@echo "  p07-contract-guard-test    - Run the Phase 07 Python contract-guard tests"
	@echo "  p07-contract-guard-tests   - Run all local Phase 07 Python contract-guard checks"
	@echo "  p07-contract-guard-live-test - Run the Phase 07 live Python contract smoke against the configured base URL"
	@echo "  p07-contract-guard-live-dev - Run the Phase 07 live Python contract smoke against the dev edge"
	@echo "  p07-contract-guard-live-prod - Run the Phase 07 live Python contract smoke against the prod edge"
	@echo "  p07-contract-guard-live-local - Run the Phase 07 live Python contract smoke against a local port-forward"
	@echo "  p07-e2e-install            - Create/update the local Phase 07 Playwright environment"
	@echo "  p07-e2e-smoke             - Run the Phase 07 Playwright browser smoke test against the configured base URL"
	@echo "  p07-e2e-smoke-dev          - Run the Phase 07 Playwright browser smoke test against the dev edge"
	@echo "  p07-e2e-smoke-prod         - Run the Phase 07 Playwright browser smoke test against the prod edge"
	@echo "  p07-e2e-report             - Open the latest Phase 07 Playwright HTML report"
	@echo "  p07-tests                  - Run all deterministic local Phase 07 Ruby, Bash, and Python checks"
	@echo "  p07-tests-live             - Run the explicit live Phase 07 smoke checks"
	@echo "  p07-tests-all              - Run all deterministic and live Phase 07 checks"
	@echo "  p07-trivy-repo-scan        - Run the Phase 07 Trivy filesystem scan on repo-owned paths"
	@echo "  p07-trivy-healthcheck-repo-scan - Run the focused Phase 07 Trivy filesystem scan on healthcheck"
	@echo "  p07-trivy-healthcheck-image-scan - Run the Phase 07 Trivy image scan on the repo-owned healthcheck image"
	@echo "  p07-trivy-scans            - Run the full Phase 07 Trivy security baseline"
	@echo "  p08-tf-init                - Initialize the Phase 08 Terraform Proxmox smoke-VM workspace"
	@echo "  p08-tf-validate            - Validate Terraform syntax and provider schema usage"
	@echo "  p08-tf-plan                - Create a saved Terraform plan for disposable VM 9300"
	@echo "  p08-tf-apply               - Apply the saved Terraform plan for disposable VM 9300"
	@echo "  p08-tf-destroy             - Destroy disposable Terraform smoke VM 9300"
	@echo "  p09-dr-script-syntax      - Validate Bash syntax of the Phase 09 DR backup script"
	@echo "  p09-dr-backup-dev         - Run the Phase 09 DR backup script against sock-shop-dev"
	@echo "  p09-dr-backup-prod        - Run the Phase 09 DR backup script against sock-shop-prod"
	@echo "  p09-dr-print-report-dev  - Print the database backup report from the latest dev backup"
	@echo "  p09-dr-print-report-prod - Print the database backup report from the latest prod backup"

# -----------------------------------------------------------------------------
# Upstream generation / verification helpers
# -----------------------------------------------------------------------------

gen-complete-demo:
	@# Run the upstream complete-demo generation helper.
	$(MAKE_CMD) -C deploy/kubernetes docker-gen-complete-demo

check-generated-files:
	@# Run the upstream generated-files verification helper.
	$(MAKE_CMD) -C deploy/kubernetes docker-check-complete-demo

# -------------------------------------------------------------------
# Phase 02 — Ingress baseline helpers
# Thin convenience targets only.
# Source of truth remains:
# - project-docs/02-ingress-baseline/IMPLEMENTATION.md
# - project-docs/02-ingress-baseline/RUNBOOK.md
# -------------------------------------------------------------------

p02-ingress-apply:
	@echo "Applying Phase 02 local ingress manifest..."
	kubectl apply -f $(P02_INGRESS_FILE)

p02-ingress-show:
	@echo "Showing Phase 02 ingress resource..."
	kubectl get ingress -n sock-shop -o wide
	@echo
	@echo "Describing Phase 02 ingress resource..."
	kubectl describe ingress -n sock-shop front-end

p02-ingress-test-host-header:
	@echo "Testing Traefik host-based routing before browser hostname resolution..."
	curl -I -H 'Host: sockshop.local' http://127.0.0.1
	@echo
	curl -s -H 'Host: sockshop.local' http://127.0.0.1 | head -n 10

p02-ingress-test-browser-url:
	@echo "Testing browser-style hostname URL (requires /etc/hosts entry first)..."
	getent hosts sockshop.local
	@echo
	curl -I http://sockshop.local/
	@echo
	curl -s http://sockshop.local/ | head -n 10

p02-ingress-delete:
	@echo "Deleting Phase 02 local ingress manifest..."
	kubectl delete -f $(P02_INGRESS_FILE)
	@echo
	@echo "Remaining ingress resources:"
	kubectl get ingress -A -o wide

p02-nodeport-test:
	@echo "Re-checking the Phase 01 NodePort fallback..."
	curl -I http://localhost:30001/
	@echo
	curl -s http://localhost:30001/ | head -n 5

# -------------------------------------------------------------------
# Phase 03 — CI/CD baseline helpers
# Thin convenience targets only for the local/manual side of Phase 03.
# Source of truth remains:
# - project-docs/03-ci-cd-baseline/SETUP.md
# - project-docs/03-ci-cd-baseline/IMPLEMENTATION.md
# - project-docs/03-ci-cd-baseline/RUNBOOK.md
# -------------------------------------------------------------------

p03-render-overlays:
	@echo "Rendering Phase 03 dev and prod overlays..."
	kubectl kustomize $(P03_DEV_OVERLAY) > /tmp/dev-rendered.yaml
	kubectl kustomize $(P03_PROD_OVERLAY) > /tmp/prod-rendered.yaml
	@echo
	@echo "Rendered overlays to:"
	@echo "  /tmp/dev-rendered.yaml"
	@echo "  /tmp/prod-rendered.yaml"

p03-render-dev:
	@echo "Rendering the Phase 03 dev overlay..."
	kubectl kustomize $(P03_DEV_OVERLAY)

p03-render-prod:
	@echo "Rendering the Phase 03 prod overlay..."
	kubectl kustomize $(P03_PROD_OVERLAY)

p03-dev-apply:
	@echo "Applying the Phase 03 dev overlay..."
	kubectl apply -k $(P03_DEV_OVERLAY)

p03-dev-status:
	@echo "Showing Phase 03 dev resources..."
	kubectl get deploy,pods,svc -n sock-shop-dev -o wide

p03-dev-rollouts:
	@echo "Checking key Phase 03 dev rollouts..."
	kubectl rollout status deployment/front-end -n sock-shop-dev --timeout=180s
	kubectl rollout status deployment/catalogue -n sock-shop-dev --timeout=180s
	kubectl rollout status deployment/payment -n sock-shop-dev --timeout=180s
	kubectl rollout status deployment/user -n sock-shop-dev --timeout=180s

p03-dev-recreate:
	@echo "Recreating the Phase 03 dev namespace from the overlay..."
	kubectl delete namespace sock-shop-dev
	@echo
	kubectl apply -k $(P03_DEV_OVERLAY)
	
# -------------------------------------------------------------------
# Phase 06 — Observability & Health helpers
# Thin convenience targets only.
# Source of truth remains:
# - project-docs/06-observability/IMPLEMENTATION.md
# - project-docs/06-observability/RUNBOOK.md
# -------------------------------------------------------------------
 
p06-monitoring-status:
	@# Show the current Phase 06 monitoring pods and services.
	KUBECONFIG=$(P06_KUBECONFIG) $(KUBECTL) get pods,svc -n monitoring -o wide

p06-grafana-port-forward:
	@# Open the private Grafana port-forward on localhost:3000.
	KUBECONFIG=$(P06_KUBECONFIG) $(KUBECTL) port-forward -n monitoring svc/observability-grafana 3000:80

p06-prometheus-port-forward:
	@# Open the private Prometheus port-forward on localhost:9090.
	KUBECONFIG=$(P06_KUBECONFIG) $(KUBECTL) port-forward -n monitoring svc/observability-kube-prometh-prometheus 9090:9090

p06-traffic-dev-preset:
	@# Run the observability traffic helper against dev with preset request data.
	$(P06_TRAFFIC_HELPER) dev preset

p06-traffic-dev-live:
	@# Run the observability traffic helper against dev with live-discovered request data.
	$(P06_TRAFFIC_HELPER) dev live

p06-traffic-prod-preset:
	@# Run the observability traffic helper against prod with preset request data.
	$(P06_TRAFFIC_HELPER) prod preset

p06-traffic-prod-live:
	@# Run the observability traffic helper against prod with live-discovered request data.
	$(P06_TRAFFIC_HELPER) prod live

# -------------------------------------------------------------------
# Phase 07 — Security & Testing helpers
# Thin convenience targets only.
# Source of truth remains:
# - project-docs/07-security-testing/IMPLEMENTATION.md
# - project-docs/07-security-testing/RUNBOOK.md
# -------------------------------------------------------------------

# Ruby Healthcheck

p07-healthcheck-syntax:
	@# Validate the Ruby syntax of the Phase 07 healthcheck helper.
	@if $(RUBY) -c $(P07_HEALTHCHECK_FILE) >/dev/null; then \
		echo "OK: Ruby syntax valid -> $(P07_HEALTHCHECK_FILE)" >&2; \
	else \
		echo "FAIL: Ruby syntax invalid -> $(P07_HEALTHCHECK_FILE)" >&2; \
		exit 1; \
	fi

p07-healthcheck-cli-test:
	@# Run the Phase 07 Ruby CLI characterization test.
	$(RUBY) $(P07_HEALTHCHECK_CLI_TEST)

p07-healthcheck-unit-test:
	@# Run the Phase 07 Ruby unit-test suite.
	$(RUBY) $(P07_HEALTHCHECK_UNIT_TEST)

p07-healthcheck-tests:
	@# Run all local Phase 07 Ruby healthcheck checks in one go.
	@$(MAKE_CMD) --no-print-directory p07-healthcheck-syntax
	@$(MAKE_CMD) --no-print-directory p07-healthcheck-cli-test
	@$(MAKE_CMD) --no-print-directory p07-healthcheck-unit-test

p07-healthcheck-target-env:
	@# Run the local Ruby healthcheck helper against the remote target cluster in sock-shop-dev.
	bash $(P07_HEALTHCHECK_TARGET_HELPER)

# Bash traffic generatort observability helper

p07-traffic-helper-syntax:
	@# Validate the Bash syntax of the Phase 07 observability helper.
	@if bash -n $(P07_TRAFFIC_HELPER_FILE); then \
		echo "OK: Bash syntax valid -> $(P07_TRAFFIC_HELPER_FILE)" >&2; \
	else \
		echo "FAIL: Bash syntax invalid -> $(P07_TRAFFIC_HELPER_FILE)" >&2; \
		exit 1; \
	fi

p07-traffic-helper-test-syntax:
	@# Validate the Bash syntax of the Phase 07 Bash test file.
	@if bash -n $(P07_TRAFFIC_HELPER_TEST); then \
		echo "OK: Bash syntax valid -> $(P07_TRAFFIC_HELPER_TEST)" >&2; \
	else \
		echo "FAIL: Bash syntax invalid -> $(P07_TRAFFIC_HELPER_TEST)" >&2; \
		exit 1; \
	fi

p07-traffic-helper-test:
	@# Run the Phase 07 Bash observability-helper tests.
	bash $(P07_TRAFFIC_HELPER_TEST)

p07-traffic-helper-tests:
	@# Run all local Phase 07 Bash observability-helper checks in one go.
	@$(MAKE_CMD) --no-print-directory p07-traffic-helper-syntax
	@$(MAKE_CMD) --no-print-directory p07-traffic-helper-test-syntax
	@$(MAKE_CMD) --no-print-directory p07-traffic-helper-test

# python qa utility (contract guard) - local

p07-python-venv:
	@# Create/update the local Phase 07 Python virtual environment and install its packages.
	@python3 -m venv tests/venv/p07-python
	@$(P07_PYTHON_BIN) -m pip install --upgrade pip >/dev/null
	@$(P07_PYTHON_BIN) -m pip install -r $(P07_PYTHON_REQUIREMENTS) >/dev/null
	@echo "OK: Phase 07 Python environment ready -> tests/venv/p07-python" >&2

p07-contract-guard-syntax:
	@# Validate Python syntax of the Phase 07 contract-guard module and test file.
	@if $(P07_PYTHON_BIN) -m py_compile $(P07_CONTRACT_GUARD_FILE) $(P07_CONTRACT_GUARD_TEST); then \
		echo "OK: Python syntax valid -> $(P07_CONTRACT_GUARD_FILE), $(P07_CONTRACT_GUARD_TEST)" >&2; \
	else \
		echo "FAIL: Python syntax invalid -> Phase 07 contract guard files" >&2; \
		exit 1; \
	fi

p07-contract-guard-test:
	@# Run the Phase 07 Python contract-guard tests.
	@echo "RUN: Phase 07 Python contract-guard tests -> $(P07_CONTRACT_GUARD_TEST)" >&2
	@$(P07_PYTHON_BIN) -m pytest -q $(P07_CONTRACT_GUARD_TEST)
	@echo "OK: Phase 07 Python contract-guard tests passed" >&2

p07-contract-guard-tests:
	@# Run all local Phase 07 Python contract-guard checks in one go.
	@$(MAKE_CMD) --no-print-directory p07-python-venv
	@$(MAKE_CMD) --no-print-directory p07-contract-guard-syntax
	@$(MAKE_CMD) --no-print-directory p07-contract-guard-test

# python - contract guard tests - live target

p07-contract-guard-live-test:
	@# Run the Phase 07 live Python contract smoke implementation target.
	@# If BASE_URL is provided by the caller (for example by GitHub Actions),
	@# use that value. Otherwise fall back to the shared dev default.
	@LIVE_URL=$${BASE_URL:-$(P07_DEV_BASE_URL)}; \
	echo "RUN: Phase 07 live Python contract smoke -> $$LIVE_URL/catalogue" >&2; \
	SOCKSHOP_CONTRACT_BASE_URL=$$LIVE_URL \
	$(P07_PYTHON_BIN) -m pytest -q $(P07_CONTRACT_GUARD_LIVE_TEST); \
	echo "OK: Phase 07 live Python contract smoke passed" >&2

p07-contract-guard-live-dev:
	@# Run the live Python contract smoke test against the dev edge.
	@BASE_URL=$(P07_DEV_BASE_URL) \
	$(MAKE_CMD) --no-print-directory p07-contract-guard-live-test

p07-contract-guard-live-prod:
	@# Run the live Python contract smoke test against the prod edge.
	@BASE_URL=$(P07_PROD_BASE_URL) \
	$(MAKE_CMD) --no-print-directory p07-contract-guard-live-test

p07-contract-guard-live-local:
	@# Run the live Python contract smoke test against a local port-forward.
	@BASE_URL=$(P07_LOCAL_BASE_URL) \
	$(MAKE_CMD) --no-print-directory p07-contract-guard-live-test

# Playwright browser smoke tests

p07-e2e-install:
	@# Verify Node.js tooling, then create/update the local Phase 07 Playwright environment.
	@if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then \
		echo "OK: Node.js tooling detected for Phase 07 Playwright smoke tests" >&2; \
	else \
		echo "FAIL: Node.js and npm are required for Phase 07 Playwright smoke tests" >&2; \
		exit 1; \
	fi
	@echo "RUN: Phase 07 Playwright setup -> $(E2E_DIR)" >&2
	@cd $(E2E_DIR) && npm install >/dev/null
	@cd $(E2E_DIR) && npx playwright install chromium >/dev/null
	@echo "OK: Phase 07 Playwright environment ready -> $(E2E_DIR)" >&2

# CI aware
p07-e2e-smoke:
	@# Run the Phase 07 Playwright browser smoke implementation target.
	@# If BASE_URL is provided by the caller (for example by GitHub Actions),
	@# use that value. Otherwise fall back to the shared dev default.
	@$(MAKE_CMD) --no-print-directory p07-e2e-install
	@# Forward the current CI state explicitly into the Playwright execution context.
	@CI_VAL=$${CI:-false}; \
	LIVE_URL=$${BASE_URL:-$(P07_DEV_BASE_URL)}; \
	echo "RUN: Phase 07 Playwright smoke -> $$LIVE_URL (CI: $$CI_VAL)" >&2; \
	cd $(E2E_DIR) && CI=$$CI_VAL BASE_URL=$$LIVE_URL npx playwright test $(P07_E2E_TEST) --project=chromium; \
	echo "OK: Phase 07 Playwright smoke passed" >&2

p07-e2e-smoke-dev:
	@# Pin the Phase 07 Playwright browser smoke test to the dev edge.
	@BASE_URL=$(P07_DEV_BASE_URL) \
	$(MAKE_CMD) --no-print-directory p07-e2e-smoke

p07-e2e-smoke-prod:
	@# Pin the Phase 07 Playwright browser smoke test to the prod edge.
	@BASE_URL=$(P07_PROD_BASE_URL) \
	$(MAKE_CMD) --no-print-directory p07-e2e-smoke

p07-e2e-report:
	@# Open the latest Playwright HTML report.
	@cd $(E2E_DIR) && npx playwright show-report
	
# aggregate targets

p07-tests:
	@# Run all deterministic local Phase 07 Ruby, Bash, and Python checks in one go.
	@$(MAKE_CMD) --no-print-directory p07-healthcheck-tests
	@$(MAKE_CMD) --no-print-directory p07-traffic-helper-tests
	@$(MAKE_CMD) --no-print-directory p07-contract-guard-tests

# CI aware
p07-tests-live:
	@# Run the explicit live Phase 07 smoke bundle.
	@# BASE_URL can be injected externally (for example by GitHub Actions).
	@# Without BASE_URL override, this bundle falls back to the shared dev default.
	@$(MAKE_CMD) --no-print-directory p07-contract-guard-live-test
	@$(MAKE_CMD) --no-print-directory p07-e2e-smoke

p07-tests-all:
	@# Run all deterministic and live Phase 07 checks in one go.
	@$(MAKE_CMD) --no-print-directory p07-tests
	@$(MAKE_CMD) --no-print-directory p07-tests-live

# Trivy security baseline
#	
# Documentation on the wrapped raw docker /trivy commands and flags 
# can be found in the Docs for Phase 07/Step08  

# Run the broad repo-owned Trivy filesystem baseline.
# (targets healthcheck/, scripts/, deploy/kubernetes/, .github/, tests/, infra/terraform/)
#
# - Iterate over the selected repo-owned paths one by one (`trivy fs` accepts only one path per run)
# - Scan each path for misconfigurations and leaked secrets
# - Fail fast on HIGH / CRITICAL findings via `--exit-code 1`
# - Reuse the persistent Trivy cache volume to avoid repeated DB/check downloads
p07-trivy-repo-scan:
	@# Run the broad Trivy filesystem baseline across repo-owned paths for misconfigurations and secrets.
	@set -e; \
	for target in healthcheck scripts deploy/kubernetes .github tests infra/terraform; do \
		echo "RUN: Phase 07 Trivy repo scan -> $$target" >&2; \
		docker run --rm \
			-v "$(CURDIR)":/repo:ro \
			-v "$(P07_TRIVY_CACHE_VOLUME)":/root/.cache/ \
			-w /repo \
			$(P07_TRIVY_IMAGE) fs \
			--scanners misconfig,secret \
			--severity $(P07_TRIVY_SEVERITY) \
			--exit-code 1 \
			--skip-dirs tests/e2e/node_modules \
			--skip-dirs tests/venv \
			--skip-dirs .git \
			"$$target"; \
	done
	@echo "OK: Phase 07 Trivy repo scan passed" >&2

# Run a focused repo-level Trivy scan for the owned 'healthcheck/' path only.
# 
# - Scan only `healthcheck/` 
# - Use the same misconfig + secret scan mode as the broad repo scan
# - Keep `--exit-code 1` so the target fails if the path still contains HIGH / CRITICAL findings
p07-trivy-healthcheck-repo-scan:
	@# Run a focused Trivy filesystem scan on the repo-owned healthcheck path only.
	@echo "RUN: Phase 07 Trivy repo scan -> healthcheck" >&2
	@docker run --rm \
		-v "$(CURDIR)":/repo:ro \
		-v "$(P07_TRIVY_CACHE_VOLUME)":/root/.cache/ \
		-w /repo \
		$(P07_TRIVY_IMAGE) fs \
		--scanners misconfig,secret \
		--severity $(P07_TRIVY_SEVERITY) \
		--exit-code 1 \
		--skip-dirs tests/e2e/node_modules \
		--skip-dirs tests/venv \
		--skip-dirs .git \
		healthcheck
	@echo "OK: Phase 07 Trivy healthcheck repo scan passed" >&2

# Build and scan the repo-owned 'healthcheck' container image.
# 
# - Rebuild the local `sockshop-healthcheck` image from `./healthcheck`
# - Export that image to a tar file
# - Scan that tar with Trivy in vulnerability-only mode
# - Avoid Docker-socket coupling by using `--input` on the exported tar
p07-trivy-healthcheck-image-scan:
	@# Build the repo-owned healthcheck image and scan it as an initial vulnerability baseline.
	@echo "RUN: Build repo-owned healthcheck image -> $(P07_HEALTHCHECK_IMAGE)" >&2
	@docker build -t $(P07_HEALTHCHECK_IMAGE) ./healthcheck >/dev/null
	@mkdir -p $(P07_TRIVY_TMP_DIR)
	@docker save -o $(P07_HEALTHCHECK_IMAGE_TAR) $(P07_HEALTHCHECK_IMAGE)
	@echo "RUN: Phase 07 Trivy image scan -> $(P07_HEALTHCHECK_IMAGE)" >&2
	@docker run --rm \
		-v "$(P07_TRIVY_TMP_DIR)":/scan:ro \
		-v "$(P07_TRIVY_CACHE_VOLUME)":/root/.cache/ \
		$(P07_TRIVY_IMAGE) image \
		--scanners vuln \
		--severity $(P07_TRIVY_SEVERITY) \
		--input /scan/sockshop-healthcheck.tar
	@rm -f $(P07_HEALTHCHECK_IMAGE_TAR)
	@echo "OK: Phase 07 Trivy image scan completed" >&2

# Run the full Step-08 Trivy baseline.
# 
# - Execute the broad repo-owned filesystem baseline first
# - Then execute the healthcheck image vulnerability baseline
p07-trivy-scans:
	@# Run the full local Phase 07 Trivy security baseline.
	@$(MAKE_CMD) --no-print-directory p07-trivy-repo-scan
	@$(MAKE_CMD) --no-print-directory p07-trivy-healthcheck-image-scan

# -----------------------------------------------------------------------------
# Phase 08 — Proxmox Infrastructure as Code helpers
#
# Details:
# - project-docs/08-proxmox-iac/IMPLEMENTATION.md
# -----------------------------------------------------------------------------

p08-tf-init:
	@# Initialize the Phase 08 Terraform working directory.
	@# This downloads the configured Proxmox provider and prepares `.terraform/`.
	cd $(P08_TF_DIR) && terraform init

p08-tf-validate:
	@# Validate the Terraform configuration syntax and provider schema usage.
	cd $(P08_TF_DIR) && terraform validate

p08-tf-plan:
	@# Create a Terraform plan for the disposable Proxmox smoke VM.
	@# `-out=tfplan` writes the reviewed plan to a local file for apply.
	cd $(P08_TF_DIR) && terraform plan -out=tfplan

p08-tf-apply:
	@# Apply the previously reviewed Terraform plan.
	@# This creates the disposable smoke VM from the workload-ready template.
	cd $(P08_TF_DIR) && terraform apply tfplan

p08-tf-destroy:
	@# Destroy the disposable Terraform smoke VM.
	@# This is expected at the end of the Phase 08 proof so the live target stays clean.
	cd $(P08_TF_DIR) && terraform destroy

# -----------------------------------------------------------------------------
# Phase 09 — Disaster Recovery & Rollback helpers
#
# Details:
# - project-docs/09-dr-rollback/IMPLEMENTATION.md
# - project-docs/09-dr-rollback/RUNBOOK.md
# -----------------------------------------------------------------------------

p09-dr-script-syntax:
	@# Validate Bash syntax of the Phase 09 DR backup script.
	@if bash -n $(P09_DR_BACKUP_SCRIPT); then \
		echo "OK: Bash syntax valid -> $(P09_DR_BACKUP_SCRIPT)" >&2; \
	else \
		echo "FAIL: Bash syntax invalid -> $(P09_DR_BACKUP_SCRIPT)" >&2; \
		exit 1; \
	fi

p09-dr-backup-dev:
	@# Run the Phase 09 DR backup script against the dev namespace.
	@KUBECONFIG=$(REMOTE_KUBECONFIG) $(P09_DR_BACKUP_SCRIPT) sock-shop-dev

p09-dr-backup-prod:
	@# Run the Phase 09 DR backup script against the prod namespace.
	@KUBECONFIG=$(REMOTE_KUBECONFIG) $(P09_DR_BACKUP_SCRIPT) sock-shop-prod	
 
p09-dr-print-report-dev:
	@# Print the database backup report from the latest dev backup.
	@latest_backup="$$(find backups -maxdepth 1 -type d -name 'sock-shop-dev_*' | sort | tail -n 1)"; \
	if [ -z "$$latest_backup" ]; then \
		echo "FAIL: No dev backup folder found under backups/" >&2; \
		echo "INFO: To create a dev backup, run 'make p09-dr-backup-dev'" >&2; \
		exit 1; \
 	fi; \
	echo "RUN: Print database backup report -> $$latest_backup/db/backup-report.txt" >&2; \
	cat "$$latest_backup/db/backup-report.txt"

p09-dr-print-report-prod:
	@# Print the database backup report from the latest prod backup.
	@latest_backup="$$(find backups -maxdepth 1 -type d -name 'sock-shop-prod_*' | sort | tail -n 1)"; \
	if [ -z "$$latest_backup" ]; then \
		echo "FAIL: No prod backup folder found under backups/" >&2; \
		echo "INFO: To create a prod backup, run 'make p09-dr-backup-prod'" >&2; \
		exit 1; \
 	fi; \
	echo "RUN: Print database backup report -> $$latest_backup/db/backup-report.txt" >&2; \
	cat "$$latest_backup/db/backup-report.txt"
