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
	p07-healthcheck-target-env

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

p07-healthcheck-syntax:
	@# Validate the Ruby syntax of the Phase 07 healthcheck helper.
	$(RUBY) -c $(P07_HEALTHCHECK_FILE)

p07-healthcheck-cli-test:
	@# Run the Phase 07 Ruby CLI characterization test.
	$(RUBY) $(P07_HEALTHCHECK_CLI_TEST)

p07-healthcheck-unit-test:
	@# Run the Phase 07 Ruby unit-test suite.
	$(RUBY) $(P07_HEALTHCHECK_UNIT_TEST)

p07-healthcheck-tests:
	@# Run all local Phase 07 Ruby healthcheck checks in one go.
	$(MAKE_CMD) p07-healthcheck-syntax
	$(MAKE_CMD) p07-healthcheck-cli-test
	$(MAKE_CMD) p07-healthcheck-unit-test

p07-healthcheck-target-env:
	@# Run the local Ruby healthcheck helper against the remote target cluster in sock-shop-dev.
	bash $(P07_HEALTHCHECK_TARGET_HELPER)