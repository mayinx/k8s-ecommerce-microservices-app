# docs/DECISIONS.md

# Decision Log (ADR-lite)

Purpose: capture key decisions + alternatives so they are defensible.

## Template
- Date:
- Decision:
- Context:
- Options considered:
- Chosen option + why:
- Consequences / follow-ups:

---

## Phase 01 — Local cluster baseline (k3s) — 2026-03-09

### Decision: deploy path = upstream manifests (not Helm yet)
- Context: Phase 01 goal was a minimal, reproducible Kubernetes baseline with the fewest moving parts.
- Options considered:
  - Upstream manifests (`deploy/kubernetes/manifests`)
  - Helm chart (`deploy/kubernetes/helm-chart`)
- Chosen option + why:
  - Upstream manifests — simplest reproducibility/debugging; keeps baseline closest to upstream.
- Consequences / follow-ups / investigate:
  - Re-evaluate Helm later for dev/prod separation via values once ingress baseline is stable.

### Decision: storefront access = NodePort 30001 (upstream default)
- Context: Need a working storefront access path without requiring ingress in Phase 01.
- Options considered:
  - Keep upstream NodePort 30001
  - Patch NodePort via overlay/patch
  - Port-forward to ClusterIP
- Chosen option + why:
  - Keep NodePort 30001 — upstream-default, explicit, easy to verify.
- Consequences / follow-ups / investigate:
  - Add ingress-based entrypoint in Phase 02 for a more production-like access path.

### Decision: NodePort collision handling = free 30001 (do not patch Sock Shop in Phase 01)
- Context: Phase 01 explicitly avoids modifying upstream Sock Shop manifests.
- Options considered:
  - Delete/change the conflicting lab Service owning 30001
  - Patch Sock Shop NodePort via local-only overlay
- Chosen option + why:
  - Free 30001 — preserves upstream YAMLs unchanged; fastest path to a clean baseline.
- Consequences / follow-ups / investigate:
  - In multi-app clusters, prefer ingress + host rules and avoid fixed NodePorts as “primary” access.

### Decision: deployment boundary = dedicated namespace `sock-shop`
- Context: Need safe reruns (reset + reapply) without touching unrelated exercises.
- Options considered:
  - Deploy into `default`
  - Deploy into dedicated namespace `sock-shop`
- Chosen option + why:
  - Dedicated namespace — predictable cleanup; clearer separation of concerns.
- Consequences / follow-ups / investigate:
  - Still potential preflight cluster-wide shared resources possible (NodePorts, ingress host/path collisions) - namespaceing doesn't prevent that ... 

---

## (Add further entries here as soon as we make real technical choices)