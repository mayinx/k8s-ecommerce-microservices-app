# 🛠️ Implementation Guide — Phase 05: Proxmox Target Delivery

> ## 👤 About
> This document is the **top-level implementation guide** for **Phase 05 (Proxmox Target Delivery)**.  
> It explains the overall implementation story, the architectural direction of this phase, the final outcome that was achieved, and how the detailed work is split across the Phase 05 subphases. 
>
> ## 🧭 Phase 05 reading paths
>
> **This top-level guide** is the best entry point for the **Phase 05 big picture**. For the full chronological hands-on build diary and implementation trail, continue with the **subphase guides listed below**:
>
> - **[Phase 05-A — Target VM bootstrap and first cluster setup](./implementation/PHASE-05-A.md)**
> - **[Phase 05-B — First Application Deployment, Runtime Compatibility Fix, and Initial Target-Side Proof](./implementation/PHASE-05-B.md)**
> - **[Phase 05-C — Environment Modeling, Ingress Routing & Private Tailnet Access](./implementation/PHASE-05-C.md)**
> - **[Phase 05-D — Public Edge Exposure via Cloudflare and CI/CD Workflow Retargeting to the Real Target Cluster](./implementation/PHASE-05-D.md)**
>
> ## 🔎 Companion documents
>
> - Setup-only preparation: [SETUP.md](./SETUP.md)   
> - Short operational rerun flow: [RUNBOOK.md](./RUNBOOK.md)  
> - Cross-phase incident and anomaly tracking: [DEBUG-LOG.md](../DEBUG-LOG.md)   
> - Top-level project navigation: [INDEX.md](../INDEX.md)  

---

## 📌 Index (top-level)

- [Phase 05 outcomes at a glance](#phase-05-outcomes-at-a-glance)
- [Implementation Roadmap & Phase 05 subphase quick navigation](#️-implementation-roadmap--phase-05-subphase-quick-navigation)
- [Purpose / Goal](#purpose--goal)
- [Definition of done](#definition-of-done)
- [Phase 05 subphase overview](#phase-05-subphase-overview)
  - [Phase 05-A — Target VM bootstrap and first cluster setup](#phase-05-a--target-vm-bootstrap-and-first-cluster-setup)
  - [Phase 05-B — First Application Deployment, Runtime Compatibility Fix, and Initial Target-Side Proof](#phase-05-b--first-application-deployment-runtime-compatibility-fix-and-initial-target-side-proof)
  - [Phase 05-C — Environment Modeling, Ingress Routing and Private Tailnet Access](#phase-05-c--environment-modeling-ingress-routing-and-private-tailnet-access)
  - [Phase 05-D — Public Edge Exposure via Cloudflare and CI/CD Workflow Retargeting to the Real Target Cluster](#phase-05-d--public-edge-exposure-via-cloudflare-and-cicd-workflow-retargeting-to-the-real-target-cluster)
- [Phase outcome summary](#phase-outcome-summary)
- [Foundation for later Phases](#foundation-for-later-phases)

---

## 🚀 Phase 05 outcomes at a glance
Phase 05 is the point where the project moves from earlier local and smoke-baseline work to a **live Proxmox-backed K3s target-delivery path** with:

- **Target Infrastructure:** A real **Proxmox target VM** for delivery validation
- **Cluster Control Plane:** A running **single-node K3s control plane** on that real target
- **Workload Deployment:** A successful first **application deployment** on the K3s cluster
- **Hardware Compatibility:** A **MongoDB compatibility triage and fix** for the target runtime
- **Environment Modeling:** Environment-aware **`dev` / `prod` namespaces** on the real cluster
- **Traffic Management:** Working **ingress routing through Traefik** for both environments
- **Secure Private Tailscale Access:** Private cluster reachability through Tailscale, allowing both the **local workstation** and ephemeral **GitHub Actions runners** to reach the target cluster over a **secure tailnet path** without exposing the Kubernetes API publicly
- **Public Edge Exposure:** Public HTTPS exposure through a **zero-trust Cloudflare Tunnel**, with outbound-only connectivity from the VM, no inbound port exposure, and all public traffic entering through the Cloudflare edge rather than directly against the origin VM
- **Stable live public environments:** Publicly reachable long-lived target URLs for both environments:
  - `https://dev-sockshop.cdco.dev/`
  - `https://prod-sockshop.cdco.dev/`
- **Automated CI/CD Pipeline:** A real and secure GitHub Actions delivery workflow reaching the private cluster through **Tailscale + kubeconfig**, including automated `dev` delivery and approval-gated `prod` delivery

## 🗺️ Implementation Roadmap & Phase 05 subphase quick navigation

To manage the complexity of moving from a local sandbox to a live Proxmox-backed environment, the implementation and its detailed documentation were executed in **four focused subphases**.

| Subphase&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Strategic Focus | Deliverables / Proof Points&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :--- | :--- | :--- |
| **[P05-A:<br>VM Bootstrap & Cluster Setup](./implementation/PHASE-05-A.md)** | **Infrastructure Foundation**<br>Covers the creation of the real target VM, guest baseline verification, helper package setup, K3s installation, and the first repository checkout on the Proxmox-backed target.| > Real target VM 9200 created & validated<br>> Target VM transformed into a ready K3s control-plane node |
| **[P05-B:<br>First Deployment & Proof](./implementation/PHASE-05-B.md)** | **Application Deployment & Validation**<br>Covers the first Sock Shop deployment on the real target cluster, the MongoDB AVX incompatibility triage, the live hotfix plus source-controlled fix, and the first successful storefront proof via NodePort and SSH tunnel. | > First successful target-side application deployment<br>> MongoDB compatibility fix<br>> First storefront rendering proof |
| **[P05-C:<br>Cluster Shape & Private Access](./implementation/PHASE-05-C.md)** | **Environment Modeling**<br>Covers the move from the first raw deployment to the dev / prod namespace model, Traefik ingress setup, Tailscale-based cluster reachability, and the completion of the real two-environment target layout. | > dev / prod environment separation<br>> Working Traefik ingress paths<br>> Private tailnet-based cluster access |
| **[P05-D:<br>Public Edge & Delivery](./implementation/PHASE-05-D.md)** | **Public Exposure, Delivery Pipeline & Completion**<br>Covers the Cloudflare Tunnel public edge, HTTPS exposure for both environments, GitHub-side deployment access preparation, and the final GitHub Actions workflow retargeting to the Proxmox-backed cluster with automated dev and approval-gated prod delivery. | > Public HTTPS reachability for both environments<br>> Real GitHub Actions delivery workflow against the private target cluster |

---

## 🎯 Purpose / Goal

The goal of Phase 05 is to turn the earlier baseline work into a **real target-delivery path**. This is the phase where the project stops being primarily a **local baseline / smoke setup** and becomes a **persistent, externally reachable, workflow-driven deployment platform** running on private Proxmox hardware.

This phase therefore has five major objectives:

- Create and validate a real target VM on Proxmox
- Bring up a working K3s control plane on that target
- Deploy the Sock Shop application successfully on the real cluster
- Evolve that deployment into a proper `dev` / `prod` environment model
- Prove both **public application access** and **private CI/CD delivery access** against the real target

Phase 05 became the largest implementation block in the project because it had to align four layers at the same time:

1. **Physical layer:** real VM provisioning and runtime compatibility on the target hardware  
2. **Orchestration layer:** transition from ephemeral `kind` usage to a persistent K3s control plane  
3. **Networking and security layer:** private tailnet access plus public Cloudflare-based exposure  
4. **Automation layer:** retargeting GitHub Actions from smoke-only behavior to the real cluster

The subphase structure reflects exactly that progression: hardware first, then application, then environment shape and access paths, and finally the public edge plus workflow-driven delivery.

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

## Phase 05 subphase overview

The detailed execution diary is split into four focused subphase guides. Each subphase advances the target-delivery path by one concrete layer.

### Phase 05-A — Target VM bootstrap and first cluster setup

**Detailed file:** [./implementation/PHASE-05-A.md](./implementation/PHASE-05-A.md)

**Focus:** Create the real Proxmox-backed target VM, validate the guest baseline, install K3s, and prove that the target becomes a working single-node control-plane host.

**Result achieved:** A real target VM (`9200`) was created, validated, and turned into a Ready K3s node.

**Bridge forward:** With the platform baseline proven, the next step was the first real application deployment on that target.

---

### Phase 05-B — First Application Deployment, Runtime Compatibility Fix, and Initial Target-Side Proof

**Detailed file:** [./implementation/PHASE-05-B.md](./implementation/PHASE-05-B.md)

**Focus:** Deploy the Sock Shop baseline, triage the MongoDB AVX/runtime issue, stabilize the stack, and prove the storefront on the real target through NodePort and SSH tunnel.

**Result achieved:** The first successful application deployment was achieved on the real target, including the MongoDB compatibility fix and the first rendered storefront proof.

**Bridge forward:** Once the first target-side deployment worked, the next step was to evolve it into a structured `dev` / `prod` environment model.

---

### Phase 05-C — Environment Modeling, Ingress Routing and Private Tailnet Access

**Detailed file:** [./implementation/PHASE-05-C.md](./implementation/PHASE-05-C.md)

**Focus:** Move from the first raw deployment into `dev` / `prod` namespaces, establish ingress routing through Traefik, bring the target onto Tailscale, and complete the two-environment target layout.

**Result achieved:** The cluster gained namespace-based environment separation, working ingress rules, and a private tailnet-based access path.

**Bridge forward:** With the real target now structured and privately reachable, the remaining task was public HTTPS exposure and workflow retargeting.

---

### Phase 05-D — Public Edge Exposure via Cloudflare and CI/CD Workflow Retargeting to the Real Target Cluster

**Detailed file:** [./implementation/PHASE-05-D.md](./implementation/PHASE-05-D.md)

**Focus:** Expose both environments publicly through Cloudflare Tunnel, prepare GitHub-side access material, and retarget GitHub Actions to the real Proxmox-backed target cluster.

**Result achieved:** Both environments became publicly reachable over HTTPS, and the real GitHub Actions delivery workflow was proven with automated `dev` and approval-gated `prod` deployment.

**Bridge beyond Phase 05:** Later phases can now build on a working delivery platform instead of still establishing the target path itself.

---

## Phase outcome summary

Phase 05 completed the transition from earlier baseline work to a **real target-delivery platform** on private Proxmox infrastructure.

By the end of this phase, the project had proven all major delivery foundations on the real target:

- VM `9200` exists and operates as a stable K3s control-plane node
- the Sock Shop application runs successfully on the real cluster
- the MongoDB compatibility blocker was resolved and persisted in source control
- `dev` and `prod` exist as separate application environments with working Traefik ingress paths
- both environments are publicly reachable through Cloudflare Tunnel and HTTPS
- GitHub Actions can deploy automatically to `dev` and approval-gated to `prod`

That makes Phase 05 the point where the project stops being only a build exercise and becomes a **working target-delivery system**.

---

## Foundation for later Phases

Phase 05 deliberately focuses on establishing the **real delivery foundation**.

That means later phases no longer need to re-solve:

- VM provisioning
- first-cluster bootstrap
- environment separation
- ingress architecture
- or real target-cluster workflow access

Those foundations are now already in place.

Later phases can therefore focus on the remaining capstone layers, especially:

- observability
- security hardening
- disaster recovery / rollback
- test-path expansion
- architecture visualization
- and final documentation polish

**In short:** Phase 05 establishes the delivery platform; the later phases now build on top of it.