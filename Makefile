# Project Makefile
# Purpose:
# - keep repeated local verification and rerun commands short and consistent
# - provide thin phase-scoped helper targets on top of the documented raw commands

.PHONY: help

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


.PHONY: gen-complete-demo
gen-complete-demo:
	make -C deploy/kubernetes docker-gen-complete-demo

.PHONY: check-generated-files
check-generated-files:
	make -C deploy/kubernetes docker-check-complete-demo

# -------------------------------------------------------------------
# Phase 02 — Ingress baseline helpers
# Thin convenience targets only.
# Source of truth remains:
# - project-docs/02-ingress-baseline/IMPLEMENTATION.md
# - project-docs/02-ingress-baseline/RUNBOOK.md
# -------------------------------------------------------------------

P02_INGRESS_FILE := deploy/kubernetes/manifests-local/phase-02-front-end-ingress.yaml

.PHONY: \
	p02-ingress-apply \
	p02-ingress-show \
	p02-ingress-test-host-header \
	p02-ingress-test-browser-url \
	p02-ingress-delete \
	p02-nodeport-test

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

P03_DEV_OVERLAY  := deploy/kubernetes/kustomize/overlays/dev
P03_PROD_OVERLAY := deploy/kubernetes/kustomize/overlays/prod

.PHONY: \
	p03-render-overlays \
	p03-render-dev \
	p03-render-prod \
	p03-dev-apply \
	p03-dev-status \
	p03-dev-rollouts \
	p03-dev-recreate

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
	
