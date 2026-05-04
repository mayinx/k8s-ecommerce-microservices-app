# Decision Log — Phase 08 (Proxmox IaC Baseline): Terraform smoke-VM provisioning proof on the Proxmox target platform

> ## About
> This document is the **phase-local decision log** for **Phase 08 (Proxmox Infrastructure as Code Baseline)**.
> It captures the full decision story for this phase without overloading the shorter project-wide summary in **[project-docs/DECISIONS.md](../DECISIONS.md)**.
> For the full chronological build diary, see: **[IMPLEMENTATION.md](IMPLEMENTATION.md)**.
> For the short rerun flow, see: **[RUNBOOK.md](RUNBOOK.md)**.
> For cross-phase incident and anomaly tracking, see: **[../DEBUG-LOG.md](../DEBUG-LOG.md)**.

---

## Index

- [**Quick recap of Phase 08**](#quick-recap-of-phase-08)
  - [**Starting point: The project needed an Infrastructure as Code proof without risking the live target**](#starting-point-the-project-needed-an-infrastructure-as-code-proof-without-risking-the-live-target)
  - [**Obstacle: Existing Terraform material did not match the Proxmox-first target platform**](#obstacle-existing-terraform-material-did-not-match-the-proxmox-first-target-platform)
  - [**Chosen path: Create a focused Proxmox Terraform workspace for one disposable smoke VM**](#chosen-path-create-a-focused-proxmox-terraform-workspace-for-one-disposable-smoke-vm)
  - [**Safety boundary: Keep live K3s target VM `9200` outside Terraform management**](#safety-boundary-keep-live-k3s-target-vm-9200-outside-terraform-management)
  - [**Verification model: Prove the full Terraform lifecycle, including destroy**](#verification-model-prove-the-full-terraform-lifecycle-including-destroy)
  - [**Verified result of Phase 08**](#verified-result-of-phase-08)
- [**Key Phase Decisions**](#key-phase-decisions)
  - [**P08-D01 — IaC scope = isolated disposable Proxmox smoke VM, not live target VM `9200`**](#p08-d01--iac-scope--isolated-disposable-proxmox-smoke-vm-not-live-target-vm-9200)
  - [**P08-D02 — Terraform path = new Proxmox-specific root module instead of inherited upstream Terraform examples**](#p08-d02--terraform-path--new-proxmox-specific-root-module-instead-of-inherited-upstream-terraform-examples)
  - [**P08-D03 — Provider model = `bpg/proxmox` over the Proxmox API**](#p08-d03--provider-model--bpgproxmox-over-the-proxmox-api)
  - [**P08-D04 — Source template = workload-ready Proxmox template `9010`**](#p08-d04--source-template--workload-ready-proxmox-template-9010)
  - [**P08-D05 — Module structure = flat Terraform root module for the first proof**](#p08-d05--module-structure--flat-terraform-root-module-for-the-first-proof)
  - [**P08-D06 — Credential handling = local environment variables, not committed files**](#p08-d06--credential-handling--local-environment-variables-not-committed-files)
  - [**P08-D07 — Cleanup proof = successful `terraform destroy` is part of the definition of done**](#p08-d07--cleanup-proof--successful-terraform-destroy-is-part-of-the-definition-of-done)
  - [**P08-D08 — Repository integration = Makefile helpers, provider lock file, Dependabot, and Trivy scope**](#p08-d08--repository-integration--makefile-helpers-provider-lock-file-dependabot-and-trivy-scope)
- [**Next-step implications**](#next-step-implications)

---

## Quick recap of Phase 08

Phase 08 established the project’s first safe Infrastructure as Code baseline for the Proxmox-backed target platform.

### Starting point: The project needed an Infrastructure as Code proof without risking the live target

After Phase 05, the project already had a long-lived Proxmox-backed K3s target VM:

- VM `9200` as the live K3s target, cloned from a workload-ready VM Template `9010`
- `sock-shop-dev` and `sock-shop-prod` running on that target
- Cloudflare Tunnel public exposure
- Tailscale-based private operator and CI/CD access
- Later observability, security testing, and DR/rollback layers built on top of the same target

Phase 08 needed to satisfy the Infrastructure as Code requirement, but it also needed to avoid destabilizing this already working platform.

### Obstacle: Existing Terraform material did not match the Proxmox-first target platform

The repository already contained inherited Terraform-related material under paths such as:

- `deploy/kubernetes/terraform/`
- `install/aws-minimesos/`
- `staging/`

Those paths were not reused as the Phase 08 baseline because they are AWS focused. The current project target is Proxmox-first, and the phase needed to prove automation against the actual Proxmox environment rather than adapting unrelated upstream examples.

### Chosen path: Create a focused Proxmox Terraform workspace for one disposable smoke VM

Phase 08 introduced a new Terraform root module under:

- `infra/terraform/proxmox-smoke-vm/`

This workspace defines exactly one Terraform-owned infrastructure object:

- Terraform resource: `proxmox_virtual_environment_vm.smoke_vm`
- Disposable VM ID: `9300`
- VM name: `ubuntu-2404-terraform-smoke-01`
- Clone source: Workload-ready VM Template `9010`
- Private IP: `10.10.10.30/24`
- Gateway: `10.10.10.1`
- DNS: `1.1.1.1`
- Storage: `vmdata`
- Network bridge: `vmbr1`

### Safety boundary: Keep live K3s target VM `9200` outside Terraform management

The live VM `9200` was deliberately not imported, modified, or managed by Terraform in Phase 08.

This keeps the live target platform stable while still proving that Terraform can communicate with Proxmox, clone from the existing workload-ready template, inject Cloud-Init values, create a VM, verify it, and remove it again.

### Verification model: Prove the full Terraform lifecycle, including destroy

Phase 08 used a complete create-and-destroy lifecycle as proof:

- `terraform init`
- `terraform validate`
- `terraform plan -out=tfplan`
- `terraform apply tfplan`
- Proxmox host-side verification with `qm list --full` and `qm config 9300`
- Guest reachability check through `ping`
- QEMU Guest Agent network verification
- `terraform destroy`
- Final Proxmox inventory check proving VM `9300` was removed while `9010` and `9200` remained

### Verified result of Phase 08

By the end of the phase, the project had proven:

- Terraform can authenticate against the Proxmox API
- Terraform can use the `bpg/proxmox` provider to create Proxmox infrastructure
- Terraform can clone a disposable VM from template `9010`
- Cloud-Init can inject guest network configuration for the smoke VM
- VM `9300` can boot and become reachable on `10.10.10.30/24`
- QEMU Guest Agent can report the expected guest-side network interface
- Terraform can destroy the managed VM again
- Live target VM `9200` remains untouched

---

## Key Phase Decisions

### P08-D01 — IaC scope = isolated disposable Proxmox smoke VM, not live target VM `9200`

- **Decision:** Prove Infrastructure as Code with one isolated disposable Proxmox smoke VM `9300`, while keeping the already live K3s target VM `9200` outside Terraform management.
- **Why:** VM `9200` already hosts the working K3s target platform, including `dev` and `prod` namespaces, ingress, public edge, observability, security validation, and DR/rollback proof. Importing or managing it with Terraform late in the project would introduce unnecessary risk.
- **Proof:** Terraform created and destroyed only VM `9300`. Proxmox inventory screenshots and `qm` verification show that VM `9200` remained present and running before, during, and after the proof.
- **Next-step impact:** Later Terraform expansion can build from a proven safe pattern without retroactively risking the currently working platform.

### P08-D02 — Terraform path = new Proxmox-specific root module instead of inherited upstream Terraform examples

- **Decision:** Create a new focused Terraform workspace under `infra/terraform/proxmox-smoke-vm/` instead of adapting inherited Terraform paths such as `deploy/kubernetes/terraform/`, `install/aws-minimesos/`, or `staging/`.
- **Why:** The inherited paths are upstream reference material and do not match the current Proxmox-first target architecture. Phase 08 needed a clean proof against the actual Proxmox environment, not a repurposed AWS/Kubernetes example path.
- **Proof:** The implemented Terraform files live under `infra/terraform/proxmox-smoke-vm/` and define one Proxmox VM resource for VM `9300`.
- **Next-step impact:** Infrastructure code now has a clean project-owned starting point that can later be expanded toward additional Proxmox automation.

### P08-D03 — Provider model = `bpg/proxmox` over the Proxmox API

- **Decision:** Use the `bpg/proxmox` Terraform provider to communicate with Proxmox through the Proxmox VE API.
- **Why:** Terraform needs a provider plugin that translates Terraform configuration into Proxmox API operations. The `bpg/proxmox` provider supports Proxmox VM resources, cloning, initialization, and static network configuration needed for this proof.
- **Proof:** `terraform init` installed `bpg/proxmox` version `0.104.0`; `terraform apply` created `proxmox_virtual_environment_vm.smoke_vm` successfully through the Proxmox API.
- **Next-step impact:** The project now has a provider choice and provider lock baseline for future Proxmox IaC work.

### P08-D04 — Source template = workload-ready Proxmox template `9010`

- **Decision:** Clone VM `9300` from the already qualified workload-ready Proxmox template `9010`.
- **Why:** Template `9010` already carries the target-ready baseline from earlier Proxmox work: private `vmbr1` networking, deterministic DNS/gateway model, Cloud-Init support, QEMU Guest Agent capability, and workload-ready sizing/layout. Terraform does not need to invent a new VM baseline for this phase.
- **Proof:** `terraform plan` and `terraform apply` show clone source VM ID `9010`; Proxmox verification confirms VM `9300` was created with the expected Cloud-Init, storage, network, and guest-agent shape.
- **Next-step impact:** Future VM automation can reuse the same template lineage or deliberately replace it with a newer documented template version.

### P08-D05 — Module structure = flat Terraform root module for the first proof

- **Decision:** Keep Phase 08 as a flat Terraform root module with `provider.tf`, `variables.tf`, and `main.tf`, instead of introducing a reusable child module such as `modules/vm`.
- **Why:** The phase scope is exactly one disposable smoke VM. A child module would add abstraction before there are multiple reusable VM cases to generalize.
- **Proof:** The committed Terraform workspace contains a small direct root module that is easy to read, review, and rerun.
- **Next-step impact:** A reusable module can be introduced later if the project expands from one smoke VM to multiple long-lived VM roles.

### P08-D06 — Credential handling = local environment variables, not committed files

- **Decision:** Pass the Proxmox API endpoint, Proxmox API token, and temporary Cloud-Init password through local `TF_VAR_...` environment variables instead of committing `.tfvars` or credential files.
- **Why:** The Terraform configuration should be reproducible from Git, but real Proxmox credentials and temporary VM passwords must stay outside the repository. This is sufficient safe local credential handling for a scoped proof, while avoiding premature setup of a full secret-management platform.
- **Proof:** `variables.tf` marks credential inputs as sensitive; `.gitignore` excludes local Terraform state, plan files, `.tfvars`, and provider cache; the Proxmox API token is documented as temporary and revoked after the proof.
- **Next-step impact:** If Terraform later manages long-lived infrastructure through CI/CD, credentials should move to a stronger secret-management model such as GitHub Actions secrets, SOPS, Vault, or another dedicated secret store.

### P08-D07 — Cleanup proof = successful `terraform destroy` is part of the definition of done

- **Decision:** Treat successful destruction of VM `9300` as part of the Phase 08 proof, not as optional cleanup.
- **Why:** The smoke VM is intentionally disposable. A complete IaC proof should show both creation and removal of the managed infrastructure, while proving that unmanaged resources remain unaffected.
- **Proof:** `terraform destroy` completed with one resource destroyed; the final Proxmox inventory shows VM `9300` removed while template `9010` and live VM `9200` remain.
- **Next-step impact:** Future disposable IaC proofs should include cleanup verification as a standard safety check.

### P08-D08 — Repository integration = Makefile helpers, provider lock file, Dependabot, and Trivy scope

- **Decision:** Integrate the Terraform proof into the repository’s existing operational patterns:
  - Add Makefile helpers for repeatable local Terraform execution
  - Commit `.terraform.lock.hcl` for provider dependency reproducibility
  - Keep local state, plans, `.tfvars`, and provider cache out of Git
  - Add Terraform provider monitoring to Dependabot scope
  - Extend Trivy scan coverage to the Terraform infrastructure path
- **Why:** Phase 08 should not exist as a one-off local experiment. It should fit the project’s existing repeatability, dependency visibility, and security-scanning model.
- **Proof:** Phase 08 added Terraform Makefile targets, provider lock metadata, `.gitignore` coverage, Dependabot Terraform scope, and Trivy scan coverage for `infra/terraform`.
- **Next-step impact:** The IaC baseline is now integrated with the same maintenance and validation story as the rest of the project.

---

## Next-step implications

- Phase 08 proves a safe Proxmox IaC baseline without destabilizing the live target platform.
- The next Terraform expansion should not import VM `9200` casually. A future long-lived infrastructure track should first define ownership boundaries, state handling, secret management, and rollback expectations.
- The current Terraform workspace is intentionally small and can remain as a smoke/proof workspace, while a later production-oriented IaC layer can be designed separately.
- If the project expands Proxmox automation, likely next candidates are:
  - A reusable VM module after at least two VM roles exist
  - Codified VM clone parameters for future dev/prod or recovery targets
  - Stronger secret handling for CI-based Terraform execution
  - IP address management through DHCP reservations or an IPAM-backed workflow
  - More complete rebuild automation for the target platform