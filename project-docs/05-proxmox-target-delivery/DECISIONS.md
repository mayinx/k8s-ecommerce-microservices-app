# Decision Log — Phase 05 (Proxmox Target Delivery): real target VM, environment model, public edge, and workflow-driven delivery

> ## 👤 About
> This document is the **phase-local decision log** for **Phase 05 (Proxmox Target Delivery)**.  
> It captures the full decision story for this phase without overloading the shorter project-wide summary in **[project-docs/DECISIONS.md](../DECISIONS.md)**.  
> For the full chronological build diary and subphase trail, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.  
> For the short happy-path rerun flow, see: **[RUNBOOK.md](./RUNBOOK.md)**.  
> For setup-only preparation around Cloudflare, Tailscale, and GitHub-side access, see: **[SETUP.md](./SETUP.md)**.  
> For the recorded technical anomalies discovered during this phase, see: **[DEBUG-LOG.md](../DEBUG-LOG.md)**.

---

## 📌 Index

- [**Quick recap (Phase 05)**](#quick-recap-phase-05)
  - [**Starting point: the project needed a real delivery target beyond the reusable VM baseline**](#starting-point-the-project-needed-a-real-delivery-target-beyond-the-reusable-vm-baseline)
  - [**First obstacle: the first target-side application deployment surfaced a MongoDB runtime incompatibility**](#first-obstacle-the-first-target-side-application-deployment-surfaced-a-mongodb-runtime-incompatibility)
  - [**Chosen deployment model: keep the proven Kubernetes manifest path and evolve it into a real environment model**](#chosen-deployment-model-keep-the-proven-kubernetes-manifest-path-and-evolve-it-into-a-real-environment-model)
  - [**Access and exposure model: separate the private operator path from the public application path**](#access-and-exposure-model-separate-the-private-operator-path-from-the-public-application-path)
  - [**Workflow model: preserve the earlier CI/CD milestone, but introduce a dedicated real-target workflow**](#workflow-model-preserve-the-earlier-cicd-milestone-but-introduce-a-dedicated-real-target-workflow)
  - [**Verified result: real target VM, real cluster, real public edge, and real workflow-driven delivery**](#verified-result-real-target-vm-real-cluster-real-public-edge-and-real-workflow-driven-delivery)
  - [**Why this matters next**](#why-this-matters-next)
- [**Key Phase Decisions**](#key-phase-decisions)
  - [**P05-D01 — Real target artifact model = Proxmox-backed VM `9200` cloned from workload-ready template `9010`**](#p05-d01--real-target-artifact-model--proxmox-backed-vm-9200-cloned-from-workload-ready-template-9010)
  - [**P05-D02 — Target cluster shape = single-node K3s control plane on the real target VM**](#p05-d02--target-cluster-shape--single-node-k3s-control-plane-on-the-real-target-vm)
  - [**P05-D03 — Deployment model = keep the Kustomize-based Kubernetes path**](#p05-d03--deployment-model--keep-the-kustomize-based-kubernetes-path)
  - [**P05-D04 — MongoDB compatibility fix = pin `carts-db` and `orders-db` to `mongo:3.4`**](#p05-d04--mongodb-compatibility-fix--pin-carts-db-and-orders-db-to-mongo34)
  - [**P05-D05 — Environment model = explicit `sock-shop-dev` and `sock-shop-prod` namespaces**](#p05-d05--environment-model--explicit-sock-shop-dev-and-sock-shop-prod-namespaces)
  - [**P05-D06 — Ingress model = built-in K3s Traefik with host-based routing for both environments**](#p05-d06--ingress-model--built-in-k3s-traefik-with-host-based-routing-for-both-environments)
  - [**P05-D07 — Private access model = Tailscale for operator and CI/CD access to the cluster API**](#p05-d07--private-access-model--tailscale-for-operator-and-cicd-access-to-the-cluster-api)
  - [**P05-D08 — Public edge model = Cloudflare Tunnel with first-level environment hostnames**](#p05-d08--public-edge-model--cloudflare-tunnel-with-first-level-environment-hostnames)
  - [**P05-D09 — Workflow model = preserve Phase 03 as historical baseline and create a dedicated Phase 05 target-delivery workflow**](#p05-d09--workflow-model--preserve-phase-03-as-historical-baseline-and-create-a-dedicated-phase-05-target-delivery-workflow)
  - [**P05-D10 — Scope boundary = keep the guest-session storefront bug out of the Phase 05 infrastructure scope**](#p05-d10--scope-boundary--keep-the-guest-session-storefront-bug-out-of-the-phase-05-infrastructure-scope)
- [**Next-step implications**](#next-step-implications)

---

## Quick recap of Phase 05

Phase 05 moved the project from the local baseline (Pahses 00 - 03) and the reusable Proxmox VM baseline established in Phase 04 to a **real target-delivery platform** on private Proxmox infrastructure.

### Starting point: the project needed a real delivery target beyond the reusable VM baseline

Phase 04 ended with the **workload-ready Proxmox VM template `9010`**, but the project still did not have:

- a real target VM for application delivery
- a real Kubernetes control plane on that target
- a public edge for `dev` / `prod`
- or a CI/CD workflow reaching the long-lived environment

Phase 05 therefore needed to turn the reusable VM baseline into a **persistent, externally reachable, workflow-driven target platform**.

### First obstacle: the first target-side application deployment surfaced a MongoDB runtime incompatibility

The first application deployment on the real target cluster showed that the overall stack came up almost completely, but `carts-db` and `orders-db` failed with a **MongoDB AVX/runtime incompatibility**.

This revealed an important target-side difference between the local proof path and the real Proxmox-backed delivery target:

- the unpinned Kubernetes image reference `mongo`
- pulled a newer MongoDB image
- which required AVX support
- that was not available or not exposed on the target VM CPU path

The fix was first proven as a live-cluster hotfix and then persisted into source control by pinning both affected Deployments to:

- `mongo:3.4`

### Chosen deployment model: keep the proven Kubernetes manifest path and evolve it into a real environment model

Instead of changing the overall Kubernetes deployment model in the middle of the target move, Phase 05 kept the already proven Kubernetes/Kustomize path and built the real target-delivery story on top of it.

That meant:

- keep the Kustomize-based deployment path
- standardize on explicit environment namespaces:
  - `sock-shop-dev`
  - `sock-shop-prod`
- add host-based ingress rules for both environments
- reuse the built-in K3s Traefik ingress controller
- prove both environments on the real target cluster

This preserved continuity with the earlier phases while allowing the target environment to become properly environment-aware.

### Access and exposure model: separate the private operator path from the public application path

Phase 05 also had to solve two different access problems cleanly:

1. **private administrative / CI access to the Kubernetes API**
2. **public HTTPS access to the storefront environments**

Those were deliberately separated:

- **Tailscale** became the private path for:
  - workstation access
  - external `kubectl` verification
  - and later GitHub Actions runner access to the cluster API
- **Cloudflare Tunnel** became the public edge for:
  - `dev-sockshop.cdco.dev`
  - `prod-sockshop.cdco.dev`

This avoided direct public exposure of the Kubernetes API and avoided opening inbound application ports directly on the VM.

### Workflow model: preserve the earlier CI/CD milestone, but introduce a dedicated real-target workflow

Phase 03 had already proven a real CI/CD baseline, but only against the temporary smoke target.

Phase 05 therefore did **not** overwrite that earlier story. Instead, it:

- preserved the Phase 03 workflow as a historical baseline
- created a dedicated Phase 05 workflow for the real Proxmox-backed target
- proved automated `dev` deployment
- and completed the approval-gated `prod` deployment path on the real cluster

This keeps the chronology understandable:

- Phase 03 = delivery mechanics baseline
- Phase 05 = real target-delivery path

### Verified result: real target VM, real cluster, real public edge, and real workflow-driven delivery

By the end of Phase 05, the project now proves:

- real target VM `9200`, cloned from workload-ready template `9010`
- single-node K3s control plane running on that target
- source-controlled MongoDB compatibility fix
- environment-separated `dev` / `prod` deployment model
- working Traefik ingress for both environments
- public HTTPS access through Cloudflare Tunnel
- private tailnet-based cluster access from outside the VM
- a real GitHub Actions target-delivery workflow:
  - automated `dev`
  - approval-gated `prod`

### Why this matters next

Phase 05 no longer leaves the project in “target bootstrap mode”.

The real target-delivery foundation now exists, so the next phases can focus on the remaining higher-level DevOps layers, especially:

- observability
- security hardening
- DR / rollback
- and final documentation / presentation polish

---

## Key Phase Decisions

### P05-D01 — Real target artifact model = Proxmox-backed VM `9200` cloned from workload-ready template `9010`

- **Decision:** Instantiate a real target VM (`9200`) from the Phase 04 workload-ready Proxmox template (`9010`) and use that VM as the delivery target for this phase.
- **Why:** Phase 05 needed to move beyond reusable-baseline proof and prove the delivery path on a persistent Proxmox-backed target.
- **Proof:** VM `9200` is created from `9010`, booted successfully, and later becomes the live K3s target throughout the phase.
- **Next-step impact:** Later deployment, access, and workflow verification in this phase all anchor to the same persistent target instead of to a local-only or ad-hoc VM path.

### P05-D02 — Target cluster shape = single-node K3s control plane on the real target VM

- **Decision:** Install K3s as a single-node control-plane cluster on the real target VM.
- **Why:** This keeps the target platform simple enough for the project scope while still proving a real Kubernetes-based long-lived environment.
- **Proof:** K3s starts successfully on the target, the node reports `Ready`, and the core cluster services, including Traefik, come up correctly.
- **Next-step impact:** The project now has a real Kubernetes target that later phases can observe, harden, and recover rather than a temporary-only smoke cluster.

### P05-D03 — Deployment model = keep the Kustomize-based Kubernetes path

- **Decision:** Continue using the existing Kubernetes manifest base plus Kustomize overlays as the main deployment path on the real target cluster.
- **Why:** That path was already established earlier in the project and supports environment-aware overlays cleanly without introducing a second deployment model during the target transition.
- **Proof:** The target-side environment deployments are applied successfully through `kubectl apply -k` for both `dev` and `prod`.
- **Next-step impact:** The same deployment model now spans local proof, CI/CD proof, and real-target delivery, which reduces conceptual drift across phases.

### P05-D04 — MongoDB compatibility fix = pin `carts-db` and `orders-db` to `mongo:3.4`

- **Decision:** Pin the `carts-db` and `orders-db` Deployments to `mongo:3.4`.
- **Why:** The unpinned `mongo` image pulled a newer MongoDB version that failed on the target runtime because of the AVX requirement.
- **Proof:** The first target-side deployment isolates the failure to the two MongoDB-backed services; after pinning to `mongo:3.4`, both services roll out successfully and the fix is then persisted in source control.
- **Next-step impact:** The deployment path becomes reproducible on the real target instead of depending on a one-off live-cluster patch.

### P05-D05 — Environment model = explicit `sock-shop-dev` and `sock-shop-prod` namespaces

- **Decision:** Standardize on explicit namespace separation for the two target environments.
- **Why:** The target-delivery path needed a real environment model before ingress, public exposure, and workflow-driven delivery could be treated as `dev` / `prod` concerns instead of as one raw namespace.
- **Proof:** Both environment namespaces are created and both overlays are deployed successfully on the real target cluster.
- **Next-step impact:** Later verification, observability, security, and DR work can reason about environment boundaries explicitly.

### P05-D06 — Ingress model = built-in K3s Traefik with host-based routing for both environments

- **Decision:** Keep the built-in K3s Traefik controller and build the environment ingress path on top of it.
- **Why:** Traefik was already present and healthy after K3s installation, so it provided the fastest and cleanest ingress-controller path without introducing another ingress stack.
- **Proof:** Host-based routing is created and verified for both `dev` and `prod`, first locally through the target-side Traefik entrypoint and later through the public hostnames.
- **Next-step impact:** Both environments now share one consistent ingress model that later public-edge and monitoring work can build on.

### P05-D07 — Private access model = Tailscale for operator and CI/CD access to the cluster API

- **Decision:** Use Tailscale as the private reachability layer for the workstation and for later GitHub Actions runner access to the cluster API.
- **Why:** This avoids direct public exposure of the Kubernetes API and removes the need for brittle inbound access rules or public-IP based administrative access.
- **Proof:** The target VM joins the tailnet successfully, a tailnet-ready kubeconfig is prepared, and external `kubectl` access from the workstation succeeds.
- **Next-step impact:** The same private path can now be used both by human operators and by CI/CD runners.

### P05-D08 — Public edge model = Cloudflare Tunnel with first-level environment hostnames

- **Decision:** Use Cloudflare Tunnel as the public edge and standardize on first-level environment hostnames:
  - `dev-sockshop.cdco.dev`
  - `prod-sockshop.cdco.dev`
- **Why:** This provides a public HTTPS edge without opening inbound application ports directly on the VM and avoids the certificate friction of deeper nested hostname patterns.
- **Proof:** The ingress hosts are aligned to the final public hostnames, the Cloudflare Tunnel is healthy, and both public HTTPS endpoints return successful responses.
- **Next-step impact:** The project now has stable public environment URLs that can be used in docs, demos, and later operational dashboards.

### P05-D09 — Workflow model = preserve Phase 03 as historical baseline and create a dedicated Phase 05 target-delivery workflow

- **Decision:** Preserve the Phase 03 workflow as a manual-only historical baseline and create a dedicated Phase 05 workflow for the real target-delivery path.
- **Why:** This keeps the project chronology understandable while preventing the older smoke-target workflow from conflicting with the real-target behavior.
- **Proof:** The Phase 03 workflow is retained, the new Phase 05 workflow is introduced, and the real target-delivery path is proven through automated `dev` deployment and approval-gated `prod` deployment.
- **Next-step impact:** The repository now preserves both the historical CI/CD milestone and the active real-target delivery path cleanly.

### P05-D10 — Scope boundary = keep the guest-session storefront bug out of the Phase 05 infrastructure scope

- **Decision:** Document the guest-session persistence bug as an upstream application issue instead of trying to patch it inside Phase 05.
- **Why:** Phase 05 is focused on target delivery, ingress, access, and workflow retargeting rather than on application-code repair of a legacy demo behavior.
- **Proof:** The infrastructure path is otherwise healthy, the environments deploy and route correctly, and the known bug is isolated and recorded separately in `DEBUG-LOG.md`.
- **Next-step impact:** The infrastructure delivery path remains complete and defensible, while the legacy application bug stays visible but scoped appropriately.

---

## Next-step implications

- Phase 05 establishes the **real target-delivery platform** on Proxmox, not just another local or smoke-only proof path.
- The next major phase (Phase 06) can therefore focus solely on **observability** on top of an already working long-lived target path.
- Later hardening and DR work should build on the now-proven:
  - `dev` / `prod` namespace model
  - Traefik ingress layer
  - Tailscale operator / CI access path
  - Cloudflare public edge
  - Phase 05 workflow-driven delivery path