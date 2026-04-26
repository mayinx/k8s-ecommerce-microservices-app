# 🛠️ Implementation Guide — Phase 08: Proxmox Infrastructure as Code Baseline

> ## 👤 About
> This is the **temporary implementation summary** for **Phase 08 (Proxmox Infrastructure as Code Baseline)**.  
> The full polished implementation guide, detailed rationale, decisions, and source trail **will be completed after hand-in**.
>
> Current status: **Implementation complete, evidence captured, documentation polish pending.**

---

## 📌 Temporary index

- [Goal](#goal)
- [What was implemented](#what-was-implemented)
- [Verification result](#verification-result)
- [Evidence captured](#evidence-captured)
- [Repository updates](#repository-updates)
- [Final Phase 08 status](#final-phase-08-status)

---

## Goal

Phase 08 adds a minimal but working **Infrastructure as Code (IaC)** baseline for the Proxmox target environment.

The goal was to prove that Terraform can manage Proxmox infrastructure safely without touching the live K3s target VM `9200`.

---

## What was implemented

A dedicated Terraform workspace was created under:

~~~text
infra/terraform/proxmox-smoke-vm/
~~~

The Terraform configuration defines one disposable Proxmox smoke VM:

- Source template: `9010` (`ubuntu-2404-workload-ready-template-v1`)
- Terraform-created smoke VM: `9300`
- Smoke VM name: `ubuntu-2404-terraform-smoke-01`
- Proxmox node: `sd-178532`
- Storage: `vmdata`
- Network bridge: `vmbr1`
- Cloud-Init guest IP: `10.10.10.30/24`
- Gateway: `10.10.10.1`
- DNS: `1.1.1.1`
- Live target VM deliberately avoided: `9200`

The implementation proves the IaC flow:

1. Initialize Terraform
2. Validate the configuration
3. Plan one Proxmox VM creation
4. Apply the plan
5. Verify the VM in Proxmox
6. Verify guest networking through ping and QEMU Guest Agent
7. Destroy the disposable VM again

---

## Verification result

Terraform initialization succeeded:

~~~bash
# Initialize the Phase 08 Terraform workspace.
$ make p08-tf-init
Terraform has been successfully initialized!
~~~

Terraform validation succeeded:

~~~bash
# Validate the Terraform configuration.
$ make p08-tf-validate
Success! The configuration is valid.
~~~

Terraform planned exactly one new VM:

~~~bash
# Create a reviewed Terraform plan.
$ make p08-tf-plan
Plan: 1 to add, 0 to change, 0 to destroy.
~~~

Terraform created the disposable smoke VM successfully:

~~~bash
# Apply the reviewed Terraform plan.
$ make p08-tf-apply
proxmox_virtual_environment_vm.smoke_vm: Creation complete after 57s [id=9300]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

smoke_vm_id = 9300
smoke_vm_ip_cidr = "10.10.10.30/24"
smoke_vm_name = "ubuntu-2404-terraform-smoke-01"
~~~

The Proxmox host confirmed that VM `9300` existed and was running:

~~~bash
# Verify the Terraform-created VM on the Proxmox host.
$ qm list --full
9300 ubuntu-2404-terraform-smoke-01 running 2048 40.00
~~~

The VM configuration confirmed the intended Cloud-Init, network, storage, and tag settings:

~~~bash
# Inspect the Terraform-created Proxmox VM.
$ qm config 9300
name: ubuntu-2404-terraform-smoke-01
ipconfig0: gw=10.10.10.1,ip=10.10.10.30/24
nameserver: 1.1.1.1
net0: virtio=<redacted>,bridge=vmbr1
scsi0: vmdata:vm-9300-disk-0,size=40G
tags: phase-08;smoke-vm;terraform
~~~

The smoke VM answered on the intended private IP:

~~~bash
# Verify guest reachability from the Proxmox host.
$ ping -c 3 10.10.10.30
3 packets transmitted, 3 received, 0% packet loss
~~~

The QEMU Guest Agent confirmed the expected guest network address:

~~~bash
# Confirm the guest-side network address through the QEMU Guest Agent.
$ qm guest cmd 9300 network-get-interfaces
[
  {
    "name": "eth0",
    "ip-addresses": [
      {
        "ip-address": "10.10.10.30",
        "ip-address-type": "ipv4",
        "prefix": 24
      }
    ]
  }
]
~~~

After verification, the disposable VM was destroyed again:

~~~bash
# Destroy the disposable Terraform smoke VM.
$ make p08-tf-destroy
Plan: 0 to add, 0 to change, 1 to destroy.

proxmox_virtual_environment_vm.smoke_vm: Destruction complete after 8s

Destroy complete! Resources: 1 destroyed.
~~~

---

## Evidence captured

Evidence was captured for the complete IaC lifecycle:

- Terraform init / validate / plan output
- Terraform apply output showing VM `9300` creation
- Proxmox UI screenshots showing the new tagged VM `9300`
- Proxmox host terminal output showing `qm list --full`
- Proxmox host terminal output showing `qm config 9300`
- Guest reachability proof through ping to `10.10.10.30`
- QEMU Guest Agent network proof for `eth0` and `10.10.10.30/24`
- Terraform destroy output showing `1 destroyed`

---

## Repository updates

The following repository updates were completed as part of Phase 08:

- Added isolated Terraform workspace:
  - `infra/terraform/proxmox-smoke-vm/`
- Added Terraform configuration for the disposable Proxmox smoke VM
- Added `.terraform.lock.hcl` for provider-version reproducibility
- Added/updated `.gitignore` rules for Terraform local state, plan files, and local secrets
- Added Phase 08 Terraform Make targets:
  - `make p08-tf-init`
  - `make p08-tf-validate`
  - `make p08-tf-plan`
  - `make p08-tf-apply`
  - `make p08-tf-destroy`
- Updated broad Trivy repo scan coverage to include:
  - `infra/terraform`
- Updated Dependabot configuration to include Terraform provider dependency scanning for:
  - `/infra/terraform/proxmox-smoke-vm`

---

## Final Phase 08 status

Phase 08 is functionally complete.

The project now has a working Proxmox IaC baseline:

- Terraform can authenticate against the Proxmox API
- Terraform can clone a VM from the existing workload-ready template `9010`
- Terraform can inject Cloud-Init network settings
- Terraform can create and start a disposable smoke VM
- The VM can be verified from Proxmox and through the guest agent
- Terraform can destroy the managed VM again
- The live target VM `9200` remained untouched

This satisfies the IaC requirement at a safe scope and creates a clean foundation for later expanded Proxmox automation.