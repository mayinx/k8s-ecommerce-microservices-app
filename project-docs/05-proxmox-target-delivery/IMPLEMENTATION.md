# 🛠️ Implementation Guide — Phase 05: Proxmox Target Delivery

> ## 👤 About
> This document is the **top-level implementation guide** for **Phase 05 (Proxmox Target Delivery)**.  
> It explains the overall implementation story, the architectural direction of this phase, the final outcome that was achieved, and how the detailed work is split across the Phase 05 subphases.
>
> Phase 05 is the point where the project moves from earlier local and smoke-baseline work to a **real Proxmox-backed K3s target path** with:
>
> - a real target VM
> - a running single-node K3s control plane
> - a successful application deployment on that target
> - environment-aware `dev` / `prod` namespaces
> - working ingress paths through Traefik
> - public HTTPS exposure through Cloudflare Tunnel
> - and a real GitHub Actions delivery workflow against the private target cluster
>
> ## 📚 Phase 05 subphase quick navigation
> The detailed implementation work is **split into four focused subphase documents**.
> Readers who want the actual hands-on build diary should jump directly into those guides:
>
> ### [Phase 05-A — Target VM bootstrap and first cluster bring-up](./implementation/PHASE-05-A.md) 
> Covers the creation of the real target VM, guest baseline verification, helper package setup, K3s installation, and the first repository checkout on the Proxmox-backed target.
>
> ### [Phase 05-B — First application deployment, MongoDB compatibility fix, and initial target-side proof](./implementation/PHASE-05-B.md)
>   Covers the first Sock Shop deployment on the real target cluster, the MongoDB AVX incompatibility triage, the live hotfix plus source-controlled fix, and the first successful storefront proof via NodePort and SSH tunnel.
>
> ### [Phase 05-C — Environment-aware redeploy, ingress routing, tailnet access, and two-environment cluster shape](./implementation/PHASE-05-C.md)
>   Covers the move from the first raw deployment to the `dev` / `prod` namespace model, Traefik ingress setup, Tailscale-based cluster reachability, and the completion of the real two-environment target layout.
>
> ### [Phase 05-D — Public Cloudflare exposure and workflow retargeting to the real target cluster](./implementation/PHASE-05-D.md)
>   Covers the Cloudflare Tunnel public edge, HTTPS exposure for both environments, GitHub-side deployment access preparation, and the final GitHub Actions workflow retargeting to the Proxmox-backed cluster with automated `dev` and approval-gated `prod` delivery.
>
> ---
>
> For setup-only topics, see: **[SETUP.md](./SETUP.md)**  
> For the short rerun flow, see: **[RUNBOOK.md](./RUNBOOK.md)**  
> For tracked anomalies and technical incident reports, see: **[DEBUG-LOG.md](../DEBUG-LOG.md)**  
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**

---

## 📌 Index (top-level)

- [Purpose / Goal](#purpose--goal)
- [Definition of done](#definition-of-done)
- [Why Phase 05 is split into subphases](#why-phase-05-is-split-into-subphases)
- [Phase 05 subphase overview](#phase-05-subphase-overview)
  - [Phase 05-A — Target VM bootstrap and first cluster bring-up](#phase-05-a--target-vm-bootstrap-and-first-cluster-bring-up)
  - [Phase 05-B — First application deployment, MongoDB recovery, and first rendered target proof](#phase-05-b--first-application-deployment-mongodb-recovery-and-first-rendered-target-proof)
  - [Phase 05-C — Environment-aware redeploy, private access path, and two-environment cluster shape](#phase-05-c--environment-aware-redeploy-private-access-path-and-two-environment-cluster-shape)
  - [Phase 05-D — Public edge and workflow retarget to the real cluster](#phase-05-d--public-edge-and-workflow-retarget-to-the-real-cluster)
- [Companion documents](#companion-documents)
- [Phase outcome summary](#phase-outcome-summary)
- [Bridge into the later phases](#bridge-into-the-later-phases)

---

## Purpose / Goal

The goal of Phase 05 is to turn the earlier baseline work into a **real target-delivery path**.

More concretely, this phase is where the project stops being only:

- a local Kubernetes exercise
- a smoke deployment baseline
- or a VM-preparation track

and becomes a **real, externally reachable, workflow-driven deployment platform** running on the Proxmox-backed target VM.

This phase therefore had five major objectives:

- create and validate the real target VM on Proxmox
- bring up a working K3s control plane on that target
- deploy the Sock Shop application successfully on the real cluster
- evolve that deployment into a proper `dev` / `prod` environment model
- prove both **public application access** and **private CI/CD delivery access** against the real target

---

## Definition of done

Phase 05 is considered done when the following conditions are met:

- a real Proxmox-backed target VM (`9200`) exists and is operational
- K3s is installed successfully and the target node is `Ready`
- the Sock Shop application runs successfully on the real target cluster
- the earlier MongoDB compatibility issue is resolved and persisted in source control
- the application is redeployed cleanly from the Phase 05 source state into:
  - `sock-shop-dev`
  - `sock-shop-prod`
- Traefik routes both environments successfully through Kubernetes Ingress
- both environments are publicly reachable through Cloudflare Tunnel and HTTPS:
  - `dev-sockshop.cdco.dev`
  - `prod-sockshop.cdco.dev`
- the target VM is reachable privately through Tailscale
- a tailnet-ready kubeconfig exists and works externally
- GitHub Actions can deploy automatically to `dev`
- GitHub Actions can deploy to `prod` through the approval-gated path
- the major evidence for the phase is captured in the phase evidence folder
- the known guest-session bug is documented explicitly in `DEBUG-LOG.md` as an upstream application issue rather than an infrastructure failure

---

## Why Phase 05 is split into subphases

Phase 05 grew into a large implementation block because it combines several different layers of work:

- VM provisioning and guest validation
- Kubernetes bootstrap
- first application deployment and recovery work
- environment modeling and ingress design
- private networking
- public exposure
- CI/CD retargeting

Keeping all of that in one giant diary would make the phase harder to navigate and much harder to skim later.

The split into subphases keeps the implementation story readable while still preserving the chronological build logic:

- **Phase 05-A** establishes the real target foundation
- **Phase 05-B** proves the first successful application deployment on that target
- **Phase 05-C** evolves that first deployment into a structured `dev` / `prod` target model
- **Phase 05-D** completes the real delivery path with public exposure and workflow-driven deployments

So the top-level `IMPLEMENTATION.md` stays the architectural and narrative entrypoint, while the subphase files remain the detailed execution diary.

---

## Phase 05 subphase overview

### Phase 05-A — Target VM bootstrap and first cluster bring-up

**Detailed file:** [./implementation/PHASE-05-A.md](./implementation/PHASE-05-A.md)

Phase 05 begins where Phase 04 ended.

Phase 04 already produced the reusable Proxmox-side workload-ready template. The first task in Phase 05 is therefore not redesign, but **instantiation**: create the first real target VM from that template and prove that the reusable baseline actually becomes a viable delivery node.

This subphase covers:

- cloning VM `9200` from the workload-ready template `9010`
- assigning the real runtime identity and network settings
- validating guest baseline behavior after first boot
- confirming DNS, routing, HTTPS reachability, CPU, memory, and disk
- installing the small helper package baseline
- installing K3s and proving that the target becomes a working single-node control-plane host
- cloning the project repository onto the target VM

**Why this subphase exists:**  
Before any application or delivery work can be trusted, the real target VM itself must prove that it is stable, correctly sized, correctly networked, and capable of running K3s.

**Result achieved in this subphase:**  
The project moved from a reusable Proxmox template to a **real running Proxmox-backed K3s target node** that was ready for application deployment.

**Bridge into the next subphase:**  
Once the VM, K3s node, and repository checkout were proven healthy, the platform itself was ready. The next logical move was to deploy the application and find out whether the real target behaves the same way as the earlier local baseline.

---

### Phase 05-B — First application deployment, MongoDB recovery, and first rendered target proof

**Detailed file:** [./implementation/PHASE-05-B.md](./implementation/PHASE-05-B.md)

With the target VM and K3s control plane operational, the next milestone was the **first real application deployment** onto the Proxmox-backed cluster.

This subphase covers:

- deploying the Sock Shop baseline into the real cluster
- validating the first cluster-side application state
- triaging the two failing MongoDB-backed services
- isolating the MongoDB AVX/runtime mismatch
- hotfixing the live cluster to `mongo:3.4`
- verifying full stack convergence
- proving the storefront response through NodePort on the target VM
- rendering the storefront in the local browser through an SSH tunnel

**Why this subphase exists:**  
A healthy platform without a healthy workload is still only half the story. This segment proves that the real target can actually run the application stack and that deployment blockers can be isolated and solved methodically.

**Result achieved in this subphase:**  
The first successful application deployment was achieved on the real target cluster, the MongoDB runtime blocker was understood and neutralized, and the storefront was proven both at terminal level and in the browser.

**Bridge into the next subphase:**  
At that point, the project had a working application on the real target, but still only in an initial deployment shape. The next task was to move from “first successful workload on the target” to a more structured **environment-aware deployment model**.

---

### Phase 05-C — Environment-aware redeploy, private access path, and two-environment cluster shape

**Detailed file:** [./implementation/PHASE-05-C.md](./implementation/PHASE-05-C.md)

Once the first successful target deployment existed, the work shifted from simple target validation to **environment modeling and controlled target access**.

This subphase covers:

- inspecting the `dev` overlay and the rendered target-side deployment input
- redeploying the application from the Phase 05 source state into `sock-shop-dev`
- confirming the target-side Traefik footprint
- creating and testing the first real `dev` ingress rule
- bringing the target VM onto the tailnet with Tailscale
- preparing the tailnet-ready kubeconfig
- verifying tailnet-based external cluster access from the workstation
- creating the missing `sock-shop-prod` namespace
- deploying the production workload from the source-controlled overlay
- creating and verifying the first `prod` ingress rule

**Why this subphase exists:**  
A one-off live target is useful, but not yet a clean delivery platform. This segment transforms the cluster into a **two-environment target** with:

- proper namespace separation
- ingress-based routing
- private operator reachability
- and a deployment model grounded in the repository state

**Result achieved in this subphase:**  
The project moved from a single successful target deployment to a **real `dev` / `prod` cluster shape** with working namespace separation, working ingress rules, and a private tailnet-based access path for later CI/CD integration.

**Bridge into the next subphase:**  
At this point, the real target cluster was structurally ready. What remained was to expose it publicly in a safe way and then retarget GitHub Actions so the real target becomes the actual delivery destination.

---

### Phase 05-D — Public edge and workflow retarget to the real cluster

**Detailed file:** [./implementation/PHASE-05-D.md](./implementation/PHASE-05-D.md)

With the real target cluster healthy, structured, and privately reachable, the final Phase 05 task was to complete the two remaining delivery layers:

- **public application reachability**
- **workflow-driven deployment reachability**

This subphase covers:

- aligning the Kubernetes Ingress objects to the final public hostname strategy
- installing and validating the Cloudflare Tunnel connector
- publishing both public HTTPS application endpoints
- verifying both public environments through Cloudflare
- preparing the GitHub-side deployment access path:
  - Tailscale OAuth client
  - GitHub Actions secrets
  - target kubeconfig secret
- preserving the Phase 03 workflow as a manual-only historical artifact
- creating a dedicated Phase 05 workflow for the real target path
- replacing the temporary `kind` smoke target with Tailscale + kubeconfig access
- proving the automated `dev` deployment against the real target
- proving the approval-gated `prod` deployment against the real target

**Why this subphase exists:**  
This is the completion layer of Phase 05. The cluster was already working before this point, but it was not yet the finished target-delivery platform. This segment turns it into a live, externally reachable, workflow-driven system.

**Result achieved in this subphase:**  
The project finished Phase 05 with:

- both environments publicly reachable over HTTPS
- both environments deployable through the real GitHub Actions path
- the old CI/CD baseline preserved historically
- and the new real target-delivery workflow proven successfully end-to-end

**Bridge beyond Phase 05:**  
With the target-delivery objective complete, the project can now move into the later platform-hardening and capstone-deliverable layers such as observability, security, disaster recovery, testing expansion, documentation consolidation, and final presentation polish.

---

## Companion documents

The following documents sit next to this top-level implementation index and support the Phase 05 story from different angles:

- **[SETUP.md](./SETUP.md)**  
  Setup-only guidance for Phase 05, especially where one-time preparation is better documented outside the main build diary.

- **[RUNBOOK.md](./RUNBOOK.md)**  
  Shorter rerun-oriented flow for repeat execution.

- **[DEBUG-LOG.md](../DEBUG-LOG.md)**  
  Cross-phase incident and anomaly tracking, including the known guest-session persistence issue identified during the Cloudflare / public verification stage.

- **[../INDEX.md](../INDEX.md)**  
  Top-level project documentation index.

---

## Phase outcome summary

Phase 05 completed the transition from baseline work to a **real target-delivery platform**.

By the end of this phase, the project had proven all of the following on the real Proxmox-backed target:

- VM `9200` exists and is stable
- K3s runs successfully as a real control-plane node
- the application runs successfully on the target cluster
- the MongoDB compatibility blocker is solved and persisted
- `dev` and `prod` exist as separate application environments
- Traefik routes both environments correctly
- both environments are reachable publicly over HTTPS through Cloudflare Tunnel
- the private tailnet-based deployment path works
- GitHub Actions can deploy automatically to `dev`
- GitHub Actions can deploy to `prod` after approval
- the remaining known application issue is documented explicitly as an upstream legacy behavior, not as a target-platform failure

That makes Phase 05 the point where the project stops being only a build exercise and becomes a **working target-delivery system**.

---

## Bridge into the later phases

Phase 05 deliberately focuses on establishing the real delivery path.

That means later phases do not need to re-solve:

- VM provisioning
- first-cluster bootstrap
- environment separation
- public ingress architecture
- or target-cluster workflow access

Those foundations are now already in place.

The later phases can therefore build on a much stronger base and focus on the remaining capstone layers, especially:

- observability
- security hardening
- disaster recovery / rollback story
- test-path expansion
- architecture visualization
- and final documentation polish

In other words:

**Phase 05 is the delivery foundation.**  
The later phases now build on top of that foundation instead of still trying to establish it.