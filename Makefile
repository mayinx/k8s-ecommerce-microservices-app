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
P07_CONTRACT_BASE_URL ?= https://dev-sockshop.cdco.dev

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
	p07-tests \
	p07-tests-live \
	p07-tests-all

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
	@echo "  p07-tests                  - Run all deterministic local Phase 07 Ruby, Bash, and Python checks"
	@echo "  p07-tests-live             - Run the explicit live Phase 07 smoke checks"
	@echo "  p07-tests-all              - Run all deterministic and live Phase 07 checks"

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
	@# Run the Phase 07 live Python contract smoke against the configured base URL.
	@echo "RUN: Phase 07 live Python contract smoke -> $(P07_CONTRACT_BASE_URL)/catalogue" >&2
	@SOCKSHOP_CONTRACT_BASE_URL=$(P07_CONTRACT_BASE_URL) \
	$(P07_PYTHON_BIN) -m pytest -q $(P07_CONTRACT_GUARD_LIVE_TEST)
	@echo "OK: Phase 07 live Python contract smoke passed" >&2

p07-contract-guard-live-dev:
	@# Run the live Python contract smoke test against the dev edge.
	@$(MAKE_CMD) --no-print-directory p07-contract-guard-live-test

p07-contract-guard-live-prod:
	@# Run the live Python contract smoke test against the prod edge.
	@$(MAKE_CMD) --no-print-directory p07-contract-guard-live-test \
		P07_CONTRACT_BASE_URL=https://prod-sockshop.cdco.dev

p07-contract-guard-live-local:
	@# Run the live Python contract smoke test against a local port-forward.
	@$(MAKE_CMD) --no-print-directory p07-contract-guard-live-test \
		P07_CONTRACT_BASE_URL=http://127.0.0.1:18080

# aggregate

p07-tests:
	@# Run all deterministic local Phase 07 Ruby, Bash, and Python checks in one go.
	@$(MAKE_CMD) --no-print-directory p07-healthcheck-tests
	@$(MAKE_CMD) --no-print-directory p07-traffic-helper-tests
	@$(MAKE_CMD) --no-print-directory p07-contract-guard-tests

p07-tests-live:
	@# Run the explicit live Phase 07 smoke checks.
	@$(MAKE_CMD) --no-print-directory p07-contract-guard-live-dev

p07-tests-all:
	@# Run all deterministic and live Phase 07 checks in one go.
	@$(MAKE_CMD) --no-print-directory p07-tests
	@$(MAKE_CMD) --no-print-directory p07-tests-live