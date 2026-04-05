# Decision Log — Phase 04 (Proxmox VM Baseline): Proxmox VM template and smoke VM

> ## 👤 About
> This document is the **phase-local decision log** for **Phase 04 (Proxmox VM Baseline)**.  
> It captures the full decision story for this phase without overloading the shorter project-wide summary in **[project-docs/DECISIONS.md](../DECISIONS.md)**.  
> For the discovery work that established the starting point for this phase, see: **[DISCOVERY.md](DISCOVERY.md)**.  
> For the full chronological build diary, see: **[IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For the short rerun flow, see: **[RUNBOOK.md](RUNBOOK.md)**.

---

## 📌 Index (top-level)

- [**Quick recap (Phase 04)**](#quick-recap-phase-04)
- [**P04-D01 — Baseline artifact model = Cloud-Init VM template + smoke VM clone**](#p04-d01--baseline-artifact-model--cloud-init-vm-template--smoke-vm-clone)
- [**P04-D02 — Standardized creation path = CLI-driven `qm` template workflow**](#p04-d02--standardized-creation-path--cli-driven-qm-template-workflow)
- [**P04-D03 — Smoke VM network model = unbridged `virtio` NIC**](#p04-d03--smoke-vm-network-model--unbridged-virtio-nic)
- [**P04-D04 — Verification model = host-side proof + guest-side proof**](#p04-d04--verification-model--host-side-proof--guest-side-proof)
- [**Next-step implications recorded by this phase**](#next-step-implications-recorded-by-this-phase)

---

## Quick recap (Phase 04)

Phase 04 established the first reusable Proxmox-backed VM baseline for the project.

### Starting point: the project needed a real Proxmox VM baseline before target deployment

Before moving the application path toward a long-lived target environment, the project first needed a proven VM baseline on the provided Proxmox host.

That baseline had to prove:

- the target host is usable
- the required storage targets are available
- a reusable Ubuntu VM template can be created
- a smoke VM can be cloned from that template
- the resulting guest works from both the Proxmox host side and inside the guest operating system itself

### Chosen platform workflow: use the Proxmox Cloud-Init template path

The phase standardized on the Proxmox Cloud-Init template workflow:

1. stage a Cloud-Init-capable Ubuntu image on the host
2. convert that image into a reusable VM template
3. clone a smoke VM from that template
4. verify the result on the host and inside the guest

This follows the workflow Proxmox itself recommends for fast rollout of reusable VM instances.

### Chosen execution model: document the baseline through the CLI-driven Proxmox CloudInit template workflow path - via Proxmox’s command-line VM manager `qm`

The Proxmox GUI was inspected during discovery and remains a valid operational surface for VM work.

For this phase, however, the baseline was documented through the CLI-driven template workflow path (utilizing via Proxmox’s command-line VM manager `qm`) - because that makes the sequence:

- more explicit
- easier to reproduce exactly
- easier to verify at the host level
- and easier to align later with automation work

### Chosen smoke-VM profile: minimal reusable guest with working outbound access

The smoke VM for this phase was defined as:

- clone source: template `9000`
- guest VM: `9100`
- Ubuntu Cloud-Init user bootstrap
- `virtio` guest NIC without bridge attachment
- enlarged root disk before first boot

That produces a small but meaningful baseline guest that is sufficient for verification without overloading the phase.

### Verified result: reusable template + working smoke VM

The phase successfully proved:

- reusable Proxmox VM template `9000`
- smoke VM `9100` cloned from that template
- successful guest login
- successful Cloud-Init completion
- visible enlarged guest root filesystem
- working outbound connectivity from inside the guest

This gives the project a real Proxmox VM baseline that later phases can build on.

---

## Key Phase Decisions

### P04-D01 — Baseline artifact model = Cloud-Init VM template + smoke VM clone

- **Decision:** Use a reusable Ubuntu 24.04 **Cloud-Init VM template** as the baseline artifact and create the validation guest as a clone from that template.
- **Why:** The phase needs a repeatable VM baseline on the provided Proxmox host, not just a one-off manually created machine.
- **Proof:** `qm config 9000` shows `template: 1`, the root disk is shown as `vmdata:base-9000-disk-0,...`, and the clone to `9100` succeeds.
- **Why it matters next:** Later VM work can build from the same reusable template path instead of repeating guest creation from scratch.

### P04-D02 — Standardized creation path = CLI-driven `qm` template workflow

- **Decision:** Standardize the documented Phase 04 baseline on the CLI-driven **`qm`** template workflow.
- **Why:** This makes the full sequence from cloud image to template to smoke VM explicit, reproducible, and easy to verify from the host side.
- **Proof:** The baseline is created and verified through `qm create`, `qm set`, `qm template`, `qm clone`, `qm config`, and `qm list --full`.
- **Why it matters next:** The command-level baseline is easier to carry forward into later automation and Infrastructure-as-Code work.

### P04-D03 — Smoke VM network model = unbridged `virtio` NIC

- **Decision:** Use an unbridged `virtio` NIC for the smoke VM (`net0: virtio`, no `bridge=vmbr0`).
- **Why:** The smoke VM needs a simple and reliable guest network path for DHCP, DNS, and outbound access.
- **Proof:** `qm config 9100` shows `net0: virtio=...` without a bridge, and inside the guest the VM receives `10.0.2.15/24`, uses `10.0.2.2` as default route, and reaches the outside successfully.
- **Why it matters next:** The phase ends with a working guest baseline instead of only a host-side inventory object.

## P04-D04 — Verification model = host-side proof + guest-side proof

- **Decision:** Count Phase 04 as successful only when the VM baseline is proven on the Proxmox host and inside the guest operating system.
- **Why:** A visible VM entry in Proxmox alone is not strong enough proof of a working baseline.
- **Proof:** Host-side checks (`pvesm status`, `qm config`, `qm list --full`, `pvesm list vmdata`) and guest-side checks (`whoami`, `cloud-init status --wait`, `ip route`, `df -h /`, `ping`, `curl`) all succeed.
- **Why it matters next:** Later phases build on a baseline that is already operationally proven at both layers.

---

## Next-step implications recorded by this phase

- Phase 04 establishes the first reusable Proxmox VM baseline, but not yet the application deployment path on the target.
- The next major step is to move from:
  - reusable VM template + smoke VM proof  
  to:
  - real application deployment on the Proxmox-backed target
- Terraform or other automation work should build on the now-proven baseline instead of replacing it conceptually.