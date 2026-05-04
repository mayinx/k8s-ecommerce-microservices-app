# Runbook — Phase 08 Proxmox IaC Baseline

> ## About
> This runbook provides the short rerun path for **Phase 08 (Proxmox Infrastructure as Code Baseline)**.
>
> It covers the Terraform smoke-VM workflow for provisioning one disposable Proxmox VM from the already proven workload-ready template.
>
> For the full implementation story, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.  
> For phase-local decisions, see: **[DECISIONS.md](./DECISIONS.md)**.  
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**.

---

## Index

- [Quick command map](#quick-command-map)
- [Safety model](#safety-model)
- [Preconditions](#preconditions)
- [Set local Terraform inputs](#set-local-terraform-inputs)
- [Terraform smoke-VM lifecycle](#terraform-smoke-vm-lifecycle)
- [Proxmox host verification](#proxmox-host-verification)
- [Cleanup](#cleanup)
- [Recommended usage](#recommended-usage)
- [Files added / modified in this phase](#files-added--modified-in-this-phase)

---

## Quick command map

| Command | What it does |
| :--- | :--- |
| `make p08-tf-init` | Initializes the Phase 08 Terraform workspace and downloads the Proxmox provider |
| `make p08-tf-validate` | Validates Terraform syntax and provider schema usage |
| `make p08-tf-plan` | Creates a saved Terraform plan for disposable VM `9300` |
| `make p08-tf-apply` | Applies the saved plan and creates disposable VM `9300` |
| `make p08-tf-destroy` | Destroys the Terraform-managed disposable VM `9300` |

---

## Safety model

Phase 08 intentionally manages only one disposable Proxmox smoke VM:

- Source template: `9010`
- Disposable Terraform VM: `9300`
- Live K3s target VM preserved: `9200`

Terraform does **not** import, manage, or modify the live target VM `9200`.

The intended lifecycle is:

1. Create disposable VM `9300`
2. Verify it from Terraform, Proxmox, and guest-network checks
3. Destroy VM `9300`
4. Confirm that template `9010` and live target VM `9200` remain unchanged

---

## Preconditions

The following must already be available:

- Proxmox workload-ready template `9010`
- Unused VM ID `9300`
- Available private IP `10.10.10.30/24`
- Proxmox API endpoint reachable from the workstation
- Temporary Proxmox API token
- Temporary Cloud-Init password for the smoke VM
- Terraform installed locally
- Phase 08 Terraform workspace:

~~~text
infra/terraform/proxmox-smoke-vm/
~~~

Generated local Terraform files such as `terraform.tfstate`, `terraform.tfstate.backup`, `tfplan`, `.terraform/`, and `.tfvars` files must remain outside Git.

---

## Set local Terraform inputs

Export the required local inputs before running the Terraform workflow.

~~~bash
export TF_VAR_proxmox_endpoint="https://<PROXMOX_HOST_OR_IP>:8006/"
export TF_VAR_proxmox_api_token='root@pam!terraform-smoke=<SECRET_VALUE>'
export TF_VAR_smoke_vm_ci_password='<TEMP_PASSWORD_FOR_SMOKE_VM>'
~~~

These values are used only locally. They must not be committed, pasted into tracked docs with real values, or stored in `.tfvars` files.

---

## Terraform smoke-VM lifecycle

Run the Terraform workflow from the repository root through the Makefile helpers.

### Initialize the workspace

~~~bash
make p08-tf-init
~~~

Successful result:

~~~text
Terraform has been successfully initialized!
~~~

### Validate the configuration

~~~bash
make p08-tf-validate
~~~

Successful result:

~~~text
Success! The configuration is valid.
~~~

### Create the plan

~~~bash
make p08-tf-plan
~~~

Expected result:

~~~text
Plan: 1 to add, 0 to change, 0 to destroy.
~~~

The plan should create only:

~~~text
proxmox_virtual_environment_vm.smoke_vm
~~~

The planned VM should match:

- VM ID: `9300`
- VM name: `ubuntu-2404-terraform-smoke-01`
- Source template: `9010`
- Storage: `vmdata`
- Static IP: `10.10.10.30/24`
- Gateway: `10.10.10.1`
- DNS: `1.1.1.1`

### Apply the plan

~~~bash
make p08-tf-apply
~~~

Successful result:

~~~text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

smoke_vm_id = 9300
smoke_vm_ip_cidr = "10.10.10.30/24"
smoke_vm_name = "ubuntu-2404-terraform-smoke-01"
~~~

---

## Proxmox host verification

Run the following checks on the Proxmox host after Terraform apply.

### Confirm VM inventory

~~~bash
qm list --full
~~~

Expected signals:

- Template `9010` still exists
- Live target VM `9200` still exists and remains running
- Disposable Terraform smoke VM `9300` exists
- VM `9300` is named `ubuntu-2404-terraform-smoke-01`

### Inspect the smoke VM configuration

~~~bash
qm config 9300
~~~

Expected signals:

- `ipconfig0` contains `ip=10.10.10.30/24,gw=10.10.10.1`
- `nameserver` is `1.1.1.1`
- Disk storage uses `vmdata`
- Cloud-Init drive is present
- Tags include `phase-08`, `terraform`, and `smoke-vm`

### Verify guest reachability

~~~bash
ping -c 3 10.10.10.30
~~~

Expected result:

~~~text
3 packets transmitted, 3 received, 0% packet loss
~~~

### Verify guest-side network data through QEMU Guest Agent

~~~bash
qm guest cmd 9300 network-get-interfaces
~~~

Expected signal:

~~~text
"ip-address": "10.10.10.30"
~~~

---

## Cleanup

Destroy the disposable smoke VM after verification.

~~~bash
make p08-tf-destroy
~~~

Expected result:

~~~text
Destroy complete! Resources: 1 destroyed.
~~~

After destroy, verify the Proxmox inventory again:

~~~bash
qm list --full
~~~

Expected final state:

- Template `9010` remains
- Live target VM `9200` remains
- Disposable VM `9300` is absent

---

## Recommended usage

### Normal Phase 08 rerun path

~~~bash
make p08-tf-init
make p08-tf-validate
make p08-tf-plan
make p08-tf-apply
~~~

Then verify from the Proxmox host:

~~~bash
qm list --full
qm config 9300
ping -c 3 10.10.10.30
qm guest cmd 9300 network-get-interfaces
~~~

Finally clean up:

~~~bash
make p08-tf-destroy
~~~

### Before committing Phase 08 changes

Check that generated Terraform files are not staged:

~~~bash
git status --short
~~~

Do not commit:

~~~text
infra/terraform/proxmox-smoke-vm/.terraform/
infra/terraform/proxmox-smoke-vm/terraform.tfstate
infra/terraform/proxmox-smoke-vm/terraform.tfstate.backup
infra/terraform/proxmox-smoke-vm/tfplan
infra/terraform/proxmox-smoke-vm/*.tfvars
~~~

Commit the Terraform configuration files and the provider lock file if present:

~~~text
infra/terraform/proxmox-smoke-vm/main.tf
infra/terraform/proxmox-smoke-vm/provider.tf
infra/terraform/proxmox-smoke-vm/variables.tf
infra/terraform/proxmox-smoke-vm/.terraform.lock.hcl
~~~

---

## Files added / modified in this phase

### Files added in this phase

- `infra/terraform/proxmox-smoke-vm/main.tf`
- `infra/terraform/proxmox-smoke-vm/provider.tf`
- `infra/terraform/proxmox-smoke-vm/variables.tf`
- `infra/terraform/proxmox-smoke-vm/.terraform.lock.hcl`
- `project-docs/08-proxmox-iac/IMPLEMENTATION.md`
- `project-docs/08-proxmox-iac/RUNBOOK.md`
- `project-docs/08-proxmox-iac/DECISIONS.md`

### Files modified in this phase

- `.gitignore`
- `.github/dependabot.yml`
- `Makefile`
- `README.md`
- `project-docs/INDEX.md`
- `project-docs/ROADMAP.md`
- `project-docs/DECISIONS.md`

### Local-only files used in this phase

- `infra/terraform/proxmox-smoke-vm/.terraform/`
- `infra/terraform/proxmox-smoke-vm/terraform.tfstate`
- `infra/terraform/proxmox-smoke-vm/terraform.tfstate.backup`
- `infra/terraform/proxmox-smoke-vm/tfplan`
- `infra/terraform/proxmox-smoke-vm/*.tfvars`