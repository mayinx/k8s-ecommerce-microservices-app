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


	
