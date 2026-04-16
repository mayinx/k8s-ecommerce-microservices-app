# Decision Log — Phase 04 (Proxmox VM Baseline): Generic Ubuntu VM Template, smoke VM, and workload-ready VM template

> ## 👤 About
> This document is the **phase-local decision log** for **Phase 04 (Proxmox VM Baseline)**.  
> It captures the full decision story for this phase without overloading the shorter project-wide summary in **[project-docs/DECISIONS.md](../DECISIONS.md)**.  
> For the discovery work that established the starting point for this phase, see: **[DISCOVERY.md](DISCOVERY.md)**.  
> For the full chronological build diary, see: **[IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For the short rerun flow, see: **[RUNBOOK.md](RUNBOOK.md)**.
> For local/workstation preparation and SSH access to the Proxmox host, see: **[SETUP.md](SETUP.md)**.  

---

## 📌 Index

- [**Quick recap (Phase 04)**](#quick-recap-phase-04)
  - [**Starting point: the project needed a real Proxmox VM baseline before target deployment**](#starting-point-the-project-needed-a-real-proxmox-vm-baseline-before-target-deployment)
  - [**First qualification layer: generic VM baseline via the Proxmox Cloud-Init template workflow (VM Template `9000` + Smoke VM `9100`)**](#first-qualification-layer-generic-vm-baseline-via-the-proxmox-cloud-init-template-workflow-vm-template-9000--smoke-vm-9100)
  - [**Second qualification layer: finalize a workload-ready baseline VM template before Phase 05 (VM Template `9010`)**](#second-qualification-layer-finalize-a-workload-ready-baseline-vm-template-before-phase-05-vm-template-9010)
  - [**Final artifact roles at the end of Phase 04**](#final-artifact-roles-at-the-end-of-phase-04)
- [**Key Phase Decisions**](#key-phase-decisions)
  - [**P04-D01 — Baseline artifact model = Cloud-Init VM template + smoke VM clone**](#p04-d01--baseline-artifact-model--cloud-init-vm-template--smoke-vm-clone)
  - [**P04-D02 — Standardized creation path = CLI-driven `qm` template workflow**](#p04-d02--standardized-creation-path--cli-driven-qm-template-workflow)
  - [**P04-D03 — Initial smoke-validation network model (unbridged `virtio` NIC)**](#p04-d03--initial-smoke-validation-network-model-unbridged-virtio-nic)
  - [**P04-D04 — Verification model = host-side proof + guest-side proof**](#p04-d04--verification-model--host-side-proof--guest-side-proof)
  - [**P04-D05 — Workload-ready baseline network model (private guest bridge `vmbr1` + host-side NAT) as base for a deployment target VM template**](#p04-d05--workload-ready-baseline-network-model-private-guest-bridge-vmbr1--host-side-nat-as-base-for-a-deployment-target-vm-template)
  - [**P04-D06 — Final Phase-04 artifact model = generic baseline + smoke clone + workload-ready template variant**](#p04-d06--final-phase-04-artifact-model--generic-baseline--smoke-clone--workload-ready-template-variant)
- [**Next-step implications**](#next-step-implications)

---

## Quick recap (Phase 04)

Phase 04 established and then qualified the first reusable Proxmox-backed VM baseline for the project.

### Starting point: the project needed a real Proxmox VM baseline before target deployment

Before moving the application path toward a long-lived target environment, the project first needed a proven VM baseline on the provided Proxmox host.

That baseline had to prove:

- the target host is usable
- the required storage targets are available
- a reusable Ubuntu VM template can be created
- a smoke VM can be cloned from that template
- the resulting guest works from both the Proxmox host side and inside the guest operating system itself

### First qualification layer: generic VM baseline via the Proxmox Cloud-Init template workflow (VM Template `9000` + Smoke VM `9100`)

Phase 04 first standardized on the Proxmox Cloud-Init template workflow:

1. stage a Cloud-Init-capable Ubuntu image on the host
2. convert that image into a reusable Proxmox VM template (**VM template `9000`**)
3. clone a smoke VM from that template (**Smoke VM `9100`**)
4. verify the result on the host and inside the guest
    - successful guest login
    - successful Cloud-Init completion
    - visible enlarged guest root filesystem
    - working outbound connectivity from inside the guest

This established the generic reusable VM baseline cleanly - following the base workflow Proxmox itself recommends for fast rollout of reusable VM instances.

### Second qualification layer: finalize a workload-ready baseline VM template before Phase 05 (VM Template `9010`)  

Phase 04 then qualified that VM baseline for actual target-side use (i.e. "sock shop deployment readiness") in form of a **VM template `9010`**.

Instead of starting Phase 05 from a fresh ad-hoc VM build, Phase 04 concluded by finalizing a workload-ready template variant `9010`, cloned from the previously established generic VM template `9000`:

Notable features of VM template `9010`:

- private host-bridged guest network via `vmbr1`
- host-side NAT, with forwarding and masquerading out through `vmbr0`
- stable private guest addressing (`<redacted-gateway-ip>0/24`) and deterministic routing via default gateway `<redacted-gateway-ip>`
- deterministic DNS via resolver `1.1.1.1`
- working outbound HTTPS reachability for later bootstrap, package-retrieval and target-side setup tasks
- guest-agent capability
- more practical disk / CPU / memory baseline
- cleaned Cloud-Init state before template conversion
- persisted host-side `vmbr1` network configuration and NAT rules

This gives the project a real workload-ready Proxmox VM baseline that later phases can build on.

### Final artifact roles at the end of Phase 04

- `9000` = generic Ubuntu cloud-image baseline template
- `9100` = initial smoke-validation clone from the generic baseline
- `9010` = workload-ready baseline template variant finalized during Phase 04 - as base for Phase 05

---

## Key Phase Decisions

### P04-D01 — Baseline artifact model = Cloud-Init VM template + smoke VM clone

- **Decision:** Use a reusable Ubuntu 24.04 **Cloud-Init VM template** as the baseline artifact and create the validation guest as a clone from that template.
- **Why:** The phase needs a repeatable VM baseline on the provided Proxmox host, not just a one-off manually created machine.
- **Proof:** `qm config 9000` shows `template: 1`, the root disk is shown as `vmdata:base-9000-disk-0,...`, and the clone to `9100` succeeds.
- **Next-step impact:** Later VM work can build from the same reusable template path instead of repeating guest creation from scratch.

### P04-D02 — Standardized creation path = CLI-driven `qm` template workflow

- **Decision:** Standardize the documented Phase 04 baseline on the CLI-driven **`qm`** template workflow.
- **Why:** This makes the full sequence from cloud image to template to smoke VM explicit, reproducible, and easy to verify from the host side.
- **Proof:** The baseline is created and verified through `qm create`, `qm set`, `qm template`, `qm clone`, `qm config`, and `qm list --full`.
- **Next-step impact:** The command-level baseline is easier to carry forward into later automation and Infrastructure-as-Code work.

### P04-D03 — Initial smoke-validation network model (unbridged `virtio` NIC)

- **Decision:** Use an unbridged `virtio` NIC for the first smoke-validation clone (`9100`).
- **Why:** The first qualification layer needed a simple and reliable guest network path to prove the generic template/clone mechanics, Cloud-Init bootstrap, and basic outbound reachability.
- **Proof:** `qm config 9100` shows `net0: virtio=...` without a bridge, and inside the guest the VM receives `10.0.2.15/24`, uses `10.0.2.2` as default route, and reaches the outside successfully.
- **Next-step impact:** This establishes the generic smoke-valid state, but not yet the final workload-ready target baseline.

### P04-D04 — Verification model = host-side proof + guest-side proof
- **Decision:** Count Phase 04 as successful only when the VM baseline is proven on the Proxmox host and inside the guest operating system.
- **Why:** A visible VM entry in Proxmox alone is not strong enough proof of a working baseline.
- **Proof:** Host-side checks (`pvesm status`, `qm config`, `qm list --full`, `pvesm list vmdata`) and guest-side checks (`whoami`, `cloud-init status --wait`, `ip route`, `df -h /`, `ping`, `curl`) all succeed.
- **Next-step impact:** Later phases build on a baseline that is already operationally proven at both layers.

### P04-D05 — Workload-ready baseline network model (private guest bridge `vmbr1` + host-side NAT) as base for a deployment target VM template 

- **Decision:** Finalize a workload-ready baseline variant (VM Template `9010`) on a private host-bridged guest network (`vmbr1`) with host-side forwarding and masquerading out through `vmbr0`.
- **Why:** The later deployment needs stable private addressing, deterministic routing, and reliable outbound bootstrap reachability; the earlier smoke-validation path is not sufficient as a final target VM baseline for production use.
- **Proof:** `9010` uses `<redacted-gateway-ip>0/24`, default route `<redacted-gateway-ip>`, resolver `1.1.1.1`, working outbound HTTPS reachability, and the host-side `vmbr1` config plus NAT rules are persisted.
- **Next-step impact:** Phase 05 can start from a workload-ready template baseline instead of rebuilding target-side guest networking from scratch.

### P04-D06 — Final Phase-04 artifact model = generic baseline + smoke clone + workload-ready template variant

- **Decision:** End Phase 04 with three explicit artifact roles instead of only the generic template plus smoke VM.
- **Why:** The phase now proves both the generic template workflow and the later target-side baseline qualification inside the same phase.
- **Proof:** `9000` remains the generic template, `9100` remains the smoke-validation clone, and `9010` is converted successfully into a workload-ready template.
- **Next-step impact:** Phase 05 begins from `9010`, while `9000` and `9100` still preserve the generic-baseline story and earlier validation path.

---

## Next-step implications

- Phase 04 establishes a first **reusable command level Proxmox VM baseline** and **qualifies it for real target-side use**.
- Phase 05 can therefore start from a
  - **workload-ready template `9010`**
  instead of from:
  - a fresh manual VM build
- **Terraform or other automation work** should build on the now-proven baseline and its final artifact roles rather than replacing them conceptually.