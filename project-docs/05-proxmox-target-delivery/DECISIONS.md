
## `DECISIONS.md` for Phase 05

```markdown
# 🧠 Decisions — Phase 05: Proxmox Target Delivery

## Purpose

This document captures the **phase-specific implementation decisions** that shaped Phase 05.

For the full execution story, see **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.  
For the short rerun path, see **[RUNBOOK.md](./RUNBOOK.md)**.

## Index

- [P05-01 — Use a real Proxmox-backed target VM for delivery validation](#p05-01--use-a-real-proxmox-backed-target-vm-for-delivery-validation)
- [P05-02 — Use a single-node K3s control plane on the target VM](#p05-02--use-a-single-node-k3s-control-plane-on-the-target-vm)
- [P05-03 — Keep the Kubernetes deployment path Kustomize-based](#p05-03--keep-the-kubernetes-deployment-path-kustomize-based)
- [P05-04 — Pin MongoDB to `mongo:3.4` on Kubernetes](#p05-04--pin-mongodb-to-mongo34-on-kubernetes)
- [P05-05 — Standardize on `sock-shop-dev` and `sock-shop-prod` namespaces](#p05-05--standardize-on-sock-shop-dev-and-sock-shop-prod-namespaces)
- [P05-06 — Use built-in K3s Traefik as the ingress controller](#p05-06--use-built-in-k3s-traefik-as-the-ingress-controller)
- [P05-07 — Use Tailscale for private operator and CI/CD cluster access](#p05-07--use-tailscale-for-private-operator-and-cicd-cluster-access)
- [P05-08 — Use Cloudflare Tunnel for public edge exposure](#p05-08--use-cloudflare-tunnel-for-public-edge-exposure)
- [P05-09 — Split the delivery workflows into a preserved Phase 03 baseline and an active Phase 05 target workflow](#p05-09--split-the-delivery-workflows-into-a-preserved-phase-03-baseline-and-an-active-phase-05-target-workflow)
- [P05-10 — Keep the guest-session storefront bug out of scope for this phase](#p05-10--keep-the-guest-session-storefront-bug-out-of-scope-for-this-phase)

---

## P05-01 — Use a real Proxmox-backed target VM for delivery validation

**Decision**  
Instantiate a real target VM from the Phase 04 workload-ready template and use that VM as the Phase 05 delivery target.

**Why**  
Phase 05 needed to move beyond smoke-style local validation and prove the delivery path on real Proxmox-backed infrastructure.

**Consequence**  
All later verification in this phase is tied to a persistent target rather than to an ephemeral local-only path.

---

## P05-02 — Use a single-node K3s control plane on the target VM

**Decision**  
Install K3s as a single-node control-plane cluster on the real target VM.

**Why**  
This keeps the platform simple enough for the capstone scope while still proving a real Kubernetes-based target environment.

**Consequence**  
The phase proves real cluster behavior without introducing multi-node complexity too early.

---

## P05-03 — Keep the Kubernetes deployment path Kustomize-based

**Decision**  
Continue using Kustomize overlays and `kubectl apply -k` as the main deployment path.

**Why**  
That path was already established earlier in the project and supports environment-aware overlays cleanly.

**Consequence**  
Phase 05 reuses a consistent deployment model for both `dev` and `prod`.

---

## P05-04 — Pin MongoDB to `mongo:3.4` on Kubernetes

**Decision**  
Pin the `carts-db` and `orders-db` Deployments to `mongo:3.4`.

**Why**  
The unpinned `mongo` image introduced a runtime compatibility problem on the target VM because newer MongoDB versions require AVX support.

**Consequence**  
The application converges on the target runtime, and the fix is preserved in source control to avoid future drift.

---

## P05-05 — Standardize on `sock-shop-dev` and `sock-shop-prod` namespaces

**Decision**  
Use explicit namespace separation for the two target environments.

**Why**  
The target-delivery path needed a proper environment model before workflow retargeting and public exposure made sense.

**Consequence**  
The cluster now supports environment-aware deployment, verification, ingress, and later CI/CD behavior.

---

## P05-06 — Use built-in K3s Traefik as the ingress controller

**Decision**  
Keep the built-in K3s Traefik controller and build the ingress path on top of it.

**Why**  
Traefik was already present and healthy on the target after K3s installation, so it provided the fastest and cleanest ingress controller path.

**Consequence**  
Both `dev` and `prod` ingress rules were implemented without introducing a second ingress stack.

---

## P05-07 — Use Tailscale for private operator and CI/CD cluster access

**Decision**  
Use Tailscale as the private reachability layer for the workstation and later for ephemeral GitHub Actions runners.

**Why**  
This avoids direct public exposure of the Kubernetes API and removes the need for brittle inbound access rules.

**Consequence**  
The target cluster is reachable privately through a tailnet-based access path, and a tailnet-ready kubeconfig becomes part of the workflow design.

---

## P05-08 — Use Cloudflare Tunnel for public edge exposure

**Decision**  
Use Cloudflare Tunnel to publish the public `dev` and `prod` hostnames.

**Why**  
This provides a public edge without opening inbound application ports directly on the VM.

**Consequence**  
Public application access is separated from private operator / CI access, and the origin exposure is reduced significantly for this path.

---

## P05-09 — Split the delivery workflows into a preserved Phase 03 baseline and an active Phase 05 target workflow

**Decision**  
Preserve the Phase 03 workflow as a manual-only historical artifact and create a dedicated Phase 05 workflow for the real target-delivery path.

**Why**  
This keeps the project chronology understandable while preventing the old workflow from conflicting with the new target behavior.

**Consequence**  
The project retains its earlier CI/CD milestone while clearly promoting the real target-delivery workflow as the active path.

---

## P05-10 — Keep the guest-session storefront bug out of scope for this phase

**Decision**  
Document the guest-session persistence bug as an upstream legacy application issue instead of trying to patch it inside Phase 05.

**Why**  
Phase 05 is focused on target delivery, ingress, access, and workflow retargeting rather than application-code repair of legacy demo behavior.

**Consequence**  
The infrastructure delivery path remains complete and defensible, while the known application bug is tracked separately in `DEBUG-LOG.md`.