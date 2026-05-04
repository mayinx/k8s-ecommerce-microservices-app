# Implementation Log — Phase 08 (Proxmox IaC Baseline): Terraform smoke-VM provisioning proof on the Proxmox target platform

> ## About
> This document is the implementation log and detailed build diary for **Phase 08 (Proxmox Infrastructure as Code Baseline)**.
> It records the safe Infrastructure as Code proof for the project: a disposable Proxmox smoke VM provisioned through Terraform from the already proven workload-ready template.
>
> For top-level project navigation, see: **[INDEX.md](../INDEX.md)**.
> For cross-phase incident and anomaly tracking, see: **[DEBUG-LOG.md](../DEBUG-LOG.md)**.
> For the broader project planning view, see: **[ROADMAP.md](../ROADMAP.md)**.
>
> Note: This phase deliberately does **not** import, modify, or manage the already live K3s target VM `9200`. Terraform is limited to one disposable smoke VM so the live `dev` / `prod` platform remains safe.

---

## Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done (Phase 08)**](#definition-of-done-phase-08)
- [**Preconditions**](#preconditions)
- [**Step 1 — Audit the existing Terraform paths and choose a Phase 08 IaC scope**](#step-1--audit-the-existing-terraform-paths-and-choose-a-phase-08-iac-scope)
- [**Step 2 — Create an isolated Proxmox Terraform smoke-VM configuration**](#step-2--create-an-isolated-proxmox-terraform-smoke-vm-configuration)
- [**Step 3 — Provision and verify disposable VM `9300` from template `9010`**](#step-3--provision-and-verify-disposable-vm-9300-from-template-9010)
- [**Step 4 — Destroy the smoke VM and record the safety model**](#step-4--destroy-the-smoke-vm-and-record-the-safety-model)
- [**Phase 08 outcome summary**](#phase-08-outcome-summary)
- [**Sources**](#sources)

---

## Purpose / Goal

### Establish a safe Proxmox Infrastructure as Code baseline

Phase 08 adds a minimal but working **Infrastructure as Code (IaC)** baseline for the Proxmox target environment.

The goal is to prove that Terraform can manage Proxmox infrastructure safely without touching the live K3s target VM `9200`.

By the end of this phase, the project proves:

- **(1)** Terraform can authenticate against the Proxmox API
- **(2)** Terraform can clone a disposable VM from the existing workload-ready template `9010`
- **(3)** Terraform can inject Cloud-Init network settings
- **(4)** The Terraform-created smoke VM can boot, receive the expected private IP, and be verified from Proxmox
- **(5)** Terraform can destroy the managed smoke VM again
- **(6)** The live target VM `9200` remains untouched

### Terraform communication model

~~~text
          Terraform configuration
    (provider.tf, variables.tf, main.tf)
                    |
                    | Declares desired infrastructure state:
                    | Proxmox smoke VM 9300
                    v
               Terraform CLI
                    |
                    | bpg/proxmox Terraform provider
                    | HTTPS API request to Proxmox :8006
                    | Token-based Proxmox API authentication
                    v
              Proxmox VE API
                    |
                    | Clone / configure / start / destroy VM
                    v
          Disposable smoke VM 9300
                    |
                    | Cloud-Init guest initialization
                    v
              Ubuntu guest OS
~~~

Terraform does not SSH into the smoke VM in this baseline. It communicates with the **Proxmox VE API** through the `bpg/proxmox` provider. Proxmox then performs the VM lifecycle actions and passes guest initialization data through Cloud-Init.

- **Provider communication:** Terraform communicates with the Proxmox hypervisor through the Terraform Proxmox provider `bpg/proxmox`.
- **Proxmox execution:** Proxmox translates the requested state into VM lifecycle actions:
  - Clone VM `9300` from workload-ready template `9010`
  - Apply VM hardware and network configuration
  - Attach Cloud-Init initialization data
  - Start the VM
  - Later: destroy the VM again

### Target resource definition

| Attribute | Configuration value |
| :--- | :--- |
| Terraform resource | `proxmox_virtual_environment_vm.smoke_vm` |
| Target VM ID | `9300` |
| VM name | `ubuntu-2404-terraform-smoke-01` |
| Clone source | Workload-ready VM template `9010` |
| Storage pool | `vmdata` |
| Network bridge | `vmbr1` |
| IP address | `10.10.10.30/24` |
| Gateway | `10.10.10.1` |
| DNS server | `1.1.1.1` |
| Preserved live target | VM `9200`, intentionally bypassed and unaffected |

### Provisioning lifecycle

The Phase 08 IaC proof performs the following lifecycle:

1. Confirm the initial Proxmox state:
   - VM template `9010` exists as the workload-ready source template
   - VM `9200` is the healthy live target for `dev` and `prod`
   - VM ID `9300` is available for the Terraform smoke VM
2. Create an isolated Terraform workspace for disposable VM `9300`
3. Configure temporary Proxmox API access through local `TF_VAR_...` environment variables
4. Run the Terraform lifecycle:
   - `terraform init`
   - `terraform validate`
   - `terraform plan -out=tfplan`
   - `terraform apply tfplan`
5. Verify VM `9300` on the Proxmox host and through the guest agent
6. Destroy the smoke VM again
7. Confirm that:
   - Template `9010` still exists
   - Live VM `9200` remains untouched
   - Disposable VM `9300` is removed after the proof

This proves a complete and reproducible IaC lifecycle for Proxmox VM provisioning while keeping the live target platform safe.

---

## Definition of done (Phase 08)

Phase 08 is considered done when the following conditions are met:

- An isolated Terraform workspace exists under `infra/terraform/proxmox-smoke-vm/`
- Terraform configuration exists for one disposable Proxmox smoke VM
- Proxmox API credentials and temporary Cloud-Init password are provided through local environment variables, not committed files
- Terraform local state, plans, `.tfvars`, provider cache, and local secrets are excluded from Git
- `terraform init` succeeds
- `terraform validate` succeeds
- `terraform plan -out=tfplan` produces one planned VM creation
- `terraform apply tfplan` creates VM `9300`
- Proxmox host verification confirms VM `9300` exists with the expected configuration
- Guest reachability and QEMU Guest Agent verification confirm the intended guest network address
- `terraform destroy` removes VM `9300`
- VM template `9010` remains unchanged
- Live target VM `9200` remains untouched
- Phase 08 Makefile helpers exist for repeatable Terraform execution
- Terraform provider dependency scanning is included in the Dependabot scope

---

## Preconditions

- The Proxmox-backed VM baseline from Phase 04 exists
- Workload-ready template `9010` exists and is available as the clone source
- Live target VM `9200` exists and must not be imported, modified, or managed by Terraform in this phase
- VM ID `9300` is available for the disposable Terraform smoke VM
- Private IP `10.10.10.30/24` is available in the target VM subnet
- The workstation has Terraform available
- The Proxmox API endpoint is reachable from the workstation
- A temporary Proxmox API token is available for the proof
- A temporary Cloud-Init password is available for the disposable smoke VM
- Local Terraform state, plans, `.tfvars`, and secrets are excluded from Git

---

## Step 1 — Audit the existing Terraform paths and choose a Phase 08 IaC scope 

### Rationale

At this point, the project already has a live target environment:

- Proxmox host: `sd-178532`
- Workload-ready template: `9010`
- Live K3s target VM: `9200`
- Running application environments: `sock-shop-dev` and `sock-shop-prod`

The repository also already contains inherited Terraform material under deployment-related paths, including Kubernetes/AWS-oriented examples.

Those existing paths were reviewed and deliberately not reused for Phase 08 because they do not match the current Proxmox-first target platform.

The relevant existing Terraform material is inherited or legacy-oriented:

- `deploy/kubernetes/terraform/`
- `install/aws-minimesos/`
- `staging/`

Those paths are upstream reference material, but they are not the right implementation base for this project phase: They are **focused on a AWS/Kubernetes example infrastructure**, while the current project target is **Proxmox**. 

Phase 08 therefore uses a new focused Terraform root module for the actual target platform instead of adapting unrelated upstream examples.

At the same time, importing or managing the already live target VM `9200` through Terraform would be too risky this late in the project. The live VM hosts the working K3s target cluster, the `dev` and `prod` namespaces, the ingress path, observability, and the public live application URLs.

The chosen Phase 08 scope is therefore:

- Create a new isolated Terraform path under `infra/terraform/proxmox-smoke-vm/`
- Use Terraform to provision one disposable Proxmox smoke VM
- Clone from the already proven workload-ready template `9010`
- Use VMID `9300` for the disposable smoke VM
- Prove Proxmox API automation without touching live VM `9200`
- Destroy the smoke VM after verification

This directly continues the Phase 04 artifact model: 
- `9000` remains the generic Ubuntu Cloud-Init baseline
- `9100` remains the earlier smoke clone  
- `9010` is the workload-ready template variant deliberately prepared as the reusable base for later target and automation work

This satisfies the Infrastructure as Code requirement while keeping the live delivery platform safe.


### Phase 08 Terraform Smoke VM Config 

A **Proxmox host audit** (see also Phase 04/05) provides the following values that can be used for the Terraform Smoke VM to be created by Terraform:

| Setting | Value |
| :--- | :--- |
| Proxmox node name | `sd-178532` |
| Source template VM ID | `9010` |
| Smoke VM ID | `9300` |
| Smoke VM name | `ubuntu-2404-terraform-smoke-01` |
| Storage | `vmdata` |
| Network bridge | `vmbr1` |
| Smoke VM IP | `10.10.10.30/24` |
| Gateway | `10.10.10.1` |
| DNS | `1.1.1.1` |
| Live target VM to avoid/preserve | `9200` |

These values come from the already verified **Proxmox baseline** and **host-side inspection**: 
- The node name, storage pool, network bridge, gateway, DNS resolver, and Template VM ID are from the existing Phase 04/05 Proxmox setup. 
- The new VM ID `9300` and IP `10.10.10.30/24` are chosen as a clearly separated disposable slot that avoids the live target VM `9200`. 

---

> [!NOTE] **🧩 Why `9010` is the Terraform source template**
>
> Template `9010` is used because Phase 04 already qualified it as the workload-ready baseline:  
> - Private `vmbr1` network
> - Deterministic guest addressing, 
> - DNS 
> - Outbound bootstrap reachability 
> - QEMU Guest Agent support 
> - Cleaned Cloud-Init state before templating
>
> Terraform therefore does not need invent a new infrastructure baseline - it can automate a clone from the already proven VM. 

> [!NOTE] **🧭 Why the smoke VM will use `10.10.10.30/24`**
>
> The Phase 08 smoke VM uses a static IP because this phase proves a small, controlled Proxmox IaC workflow, not a full IP address management platform.
>
> The existing Proxmox private VM network already uses:
>
> - `10.10.10.1` as gateway
> - `10.10.10.10` for the workload-ready template baseline
> - `10.10.10.20` for the live K3s target VM
>
> The smoke VM therefore uses `10.10.10.30/24` as a clearly separated disposable IaC slot. This avoids the live target VM `9200`, keeps the test easy to recognize, and leaves room for later documented IaC smoke/prototype addresses.
>
> In a larger or long-lived VM fleet, this manual static selection should be replaced by DHCP reservations or an IPAM-backed workflow, for example Proxmox SDN IPAM, NetBox, or another source-of-truth system.
>
> Avoid using:
>
> - `10.10.10.1` — gateway
> - `10.10.10.10` — workload-ready template baseline
> - `10.10.10.20` — live K3s target VM
> - Any address already assigned to another VM, DHCP lease, or network service
> - Any address outside the `10.10.10.0/24` target VM subnet unless the Proxmox routing model is changed deliberately

### Action

In this action, we capture the current Proxmox baseline and create a clean Phase 08 workspace instead of extending inherited Terraform examples. This keeps the Proxmox proof isolated, readable, and safe for the existing live target.

Create the new Phase 08 implementation directory:

~~~bash
# Create the isolated Terraform path for the Phase 08 Proxmox smoke VM.
# -p = create parent directories as needed and do not fail if the directory already exists.
mkdir -p infra/terraform/proxmox-smoke-vm
~~~

Create the Phase 08 documentation folder:

~~~bash
# Create the Phase 08 documentation folder.
# The short folder name keeps navigation readable while still making the subject clear.
mkdir -p project-docs/08-proxmox-iac
~~~

Capture the current Proxmox VM baseline before Terraform work starts /from teh proxmox host):

~~~bash
# Current VM inventory 
# Show the current Proxmox VM inventory before Terraform creates the smoke VM:
# - 9010 exists as the stopped workload-ready template
# - 9200 exists as the running live K3s target
# - 9300 does not exist yet
$ qm list --full
VMID NAME                                               STATUS     MEM(MB)    BOOTDISK(GB)  PID       
9000 ubuntu-2404-cloudinit-template                     stopped    2048               3.50  0         
9010 ubuntu-2404-workload-ready-template-v1             stopped    4096              40.00  0         
9100 ubuntu-2404-smoke-01                               stopped    2048              16.00  0         
9200 ubuntu-2404-k3s-target-01                          running    16384             40.00  ...  
~~~

---

**Proxmox inventory before Terraform smoke VM creation**

![Proxmox inventory before Terraform smoke VM creation](../evidence/01-P08-proxmox-before-terraform-smoke-vm.png)

*Figure 1: Proxmox inventory before the Terraform smoke-VM proof starts. The existing baseline VMs and templates are visible: generic template `9000`, workload-ready template `9010`, smoke VM `9100`, and live K3s target VM `9200`. VM `9300` is not present yet, which confirms that the planned Terraform smoke-VM ID is still available before provisioning.*

---

Inspect the workload-ready template and the live target VM:

~~~bash
# Current source template configuration.
# Inspect the workload-ready template used as Terraform clone source:
# - template: 1 is present
# - Cloud-Init drive is on ide2
# - vmbr1 is the network bridge
# - vmdata is the disk/storage backend
$ qm config 9010
root@sd-178532:~# qm config 9010
agent: enabled=1
boot: order=scsi0
cipassword: **********
ciuser: ubuntu
cores: 4
ide2: vmdata:vm-9010-cloudinit,media=cdrom,size=4M
ipconfig0: ip=10.10.10.10/24,gw=10.10.10.1
memory: 4096
meta: creation-qemu=9.2.0,ctime=1775131165
name: ubuntu-2404-workload-ready-template-v1
nameserver: 1.1.1.1
net0: virtio=BC:24:11:EC:61:C3,bridge=vmbr1
ostype: l26
scsi0: vmdata:base-9010-disk-0,size=40G
scsihw: virtio-scsi-pci
serial0: socket
smbios1: uuid=cf4a3e54-8774-43ed-ac12-6dd8d7f05485
template: 1
vga: serial0
vmgenid: 0ba09bd4-c442-4b61-9431-a6c45db9d598
root@sd-178532:~# 

# Inspect the live target VM configuration.
# Inspect the live K3s target VM that Terraform must not manage or modify:
# - 9200 exists separately from the planned smoke VM
# - it remains the running live target for the current application platform
$ qm config 9200
agent: enabled=1
boot: order=scsi0
cipassword: **********
ciuser: ubuntu
cores: 4
ide2: vmdata:vm-9200-cloudinit,media=cdrom,size=4M
ipconfig0: ip=10.10.10.20/24,gw=10.10.10.1
memory: 16384
meta: creation-qemu=9.2.0,ctime=1775131165
name: ubuntu-2404-k3s-target-01
nameserver: 1.1.1.1
net0: virtio=BC:24:11:BC:F9:84,bridge=vmbr1
ostype: l26
scsi0: vmdata:vm-9200-disk-0,size=40G
scsihw: virtio-scsi-pci
serial0: socket
smbios1: uuid=5c57980d-c73d-4451-8b62-05c525b06d91
vga: serial0
vmgenid: 573e2a0a-2c6b-4ae7-a1e3-6e549999b291

~~~

Output shows:

- `9010` exists as a stopped template
- `9200` exists as the running live K3s target
- `9300` does not exist yet
- Template `9010` exposes the expected Cloud-Init and network shape:
  - `ide2`
  - `vmdata`
  - `vmbr1`
  - gateway `10.10.10.1`
  - DNS `1.1.1.1`

### Result

Phase 08 deliberately avoids the inherited Terraform examples and introduces a clean, Proxmox-specific Infrastructure as Code path.

The resulting safety model is:

- Existing live target VM `9200` remains unmanaged by Terraform
- Existing workload-ready template `9010` remains the source template
- New disposable smoke VM `9300` proves Terraform-based Proxmox provisioning
- Destroying the smoke VM proves cleanup and rollback safety

At this point, the Phase 08 scope is intentionally narrow: Terraform provisions a VM environment automatically from source-controlled infrastructure definitions - whiel keeping the curernt target vm 9200 untouched and safe  

---

## Step 2 — Create an isolated Proxmox Terraform smoke-VM configuration

### Rationale

The next step is to create the Terraform files for the disposable smoke VM.

The Terraform configuration uses the `bpg/proxmox` provider because it supports Proxmox VE automation through the Proxmox API, including virtual-machine cloning from existing templates.

The values for the Smoke VM to be created are locked from the already verified Proxmox state (Step 1):

- Proxmox node name: `sd-178532`
- Source template VMID: `9010`
- Smoke VMID: `9300`
- Smoke VM name: `ubuntu-2404-terraform-smoke-01`
- Datastore: `vmdata`
- Network bridge: inherited from the template (`vmbr1`)
- Smoke VM IP: `10.10.10.30/24`
- Gateway: `10.10.10.1`
- DNS: `1.1.1.1`
- Live target VM to avoid touching: `9200`

> [!NOTE] **🧭 Proxmox management endpoint vs. smoke VM guest IP**
>
> Phase 08 uses two different network addresses with different purposes:
>
> - **Proxmox management/API endpoint:** `https://<redacted-proxmox-api-host>:8006`
>   - This is the Proxmox VE host’s management endpoint: the same host/IP used to reach the Proxmox Web UI and API.
>   - Terraform uses this endpoint to authenticate against Proxmox and create the disposable smoke VM through the Proxmox API.
>   - Locally, this value is exported as `TF_VAR_proxmox_endpoint`.
>   - This address belongs to the Proxmox host itself, not to any guest VM running inside Proxmox.
>
> - **Smoke VM guest IP:** `10.10.10.30/24`
>   - This is the private IP address assigned to the disposable Terraform smoke VM `9300`.
>   - It belongs to the existing Proxmox private VM subnet `10.10.10.0/24`.
>   - The address follows the existing lab pattern:
>     - `10.10.10.1` = private VM network gateway
>     - `10.10.10.10` = workload-ready template baseline `9010`
>     - `10.10.10.20` = live K3s target VM `9200`
>     - `10.10.10.30` = disposable Terraform smoke VM `9300`
>   - This keeps the Terraform-created VM clearly separated from the live target while staying in the same private VM network.
>   - Terraform passes this guest IP into the VM through Cloud-Init network initialization.
>
> In short:
>
> - Terraform connects **to Proxmox** via `https://<redacted-proxmox-api-host>:8006`.
> - Terraform creates **the smoke VM** with guest IP `10.10.10.30/24`.
>
> For larger "VM fleets", this manual static IP choice should be replaced by DHCP reservations or an IPAM-backed workflow. For this phase, the documented static smoke slot is sufficient because the scope is exactly one disposable VM created for IaC proof and destroyed again afterward.

### Action

The goal is now to define  
- a disposable smoke VM in Terraform:
- that is reproducible from code alone 
- while credentials, local state, and secret input values are kept out of Git

This can be achieved by **creating a Terraform configuration for a disposable Proxmox Smoke VM**. Terraform configurations are written in HashiCorp Configuration Language (HCL) and usually split into one or more `.tf` files. 

The Terraform files for this project are organized under `infra/terraform/proxmox-smoke-vm/` so IaC has its own clearly separated workspace and does not reuse inherited Terraform examples from older deployment paths.

This configuration is intentionally kept as a **flat Terraform root module** instead of introducing a reusable `modules/vm` child module. The scope is only one disposable smoke VM, so the flat structure keeps the IaC proof easier to read, faster to review, and avoids premature abstraction.

Together, these files define 
- the **Proxmox provider used by Terraform to connect to Proxmox**, 
- the **required input variables**, 
- the **disposable smoke VM** as single **infrastructure object** to be created  

The configuration keeps the **smoke VM reproducible from code** while ensuring that credentials, local state, and secret input values stay out of Git.

The Terraform configuration is split into three main files:

- **(1) `provider.tf`** defines the Terraform provider setup. It pins the required `bpg/proxmox` provider and configures the Proxmox API connection through variables, so the endpoint and token can be passed from the shell instead of being committed to Git.

- **(2) `variables.tf`** defines the configurable inputs for the smoke-VM proof. This keeps the important Phase 08 values explicit, including the Proxmox endpoint, API token, source template VMID `9010`, smoke VMID `9300`, node name `sd-178532`, target storage `vmdata`, static smoke-VM IP, gateway, DNS resolver, and temporary Cloud-Init password.

- **(3) `main.tf`** defines the actual disposable Proxmox VM resource. It clones VM `9300` from the workload-ready template `9010`, applies the Cloud-Init initialization values, keeps the VM isolated from the live target `9200`, and gives Terraform one clearly owned infrastructure object to create, verify, and destroy again.

> [!NOTE] **🧩 `bpg/proxmox` Terraform provider**
>
> Terraform does not talk to Proxmox directly by itself. It needs a **provider plugin** - a Terroform Provider - that knows how to call the Proxmox API and translate Terraform resources into Proxmox operations.
>
> In this phase, the selected Terraform Provider is **`bpg/proxmox`**. It is used to manage Proxmox VE resources through Terraform / OpenTofu and is configured with:
>
> - the Proxmox API endpoint
> - an API token
> - the target node name
> - VM clone and Cloud-Init settings
>
> This fits the Phase 08 goal well: Terraform provisions a disposable VM clone from the already proven Proxmox template `9010`, without manually clicking through the Proxmox UI and without importing or touching the live target VM `9200`. 

~~~

#### `.gitignore` update

The follwoing lines in `.gitignore` ensure that the repo is not polluted with local state data from terrafrom and - most importantly - that no secrates leak into the public repo:

~~~gitignore
# Phase 08 Terraform local state and secret inputs
infra/terraform/**/.terraform/
infra/terraform/**/*.tfstate
infra/terraform/**/*.tfstate.*
infra/terraform/**/*.tfvars
infra/terraform/**/*.tfplan
~~~

### Result

Phase 08 now has an isolated Terraform configuration that can provision a disposable Proxmox VM from the existing workload-ready template.

The configuration is intentionally small and source-controlled, while secrets and local Terraform state remain excluded from Git.

The successful end state is shown by these signals / verification points:

- Terraform files exist under `infra/terraform/proxmox-smoke-vm/`
- The Terraform provider is pinned through `provider.tf`
- VM configuration is defined in `main.tf`
- Project-specific inputs and safe defaults are defined in `variables.tf`
- Secret values are expected through environment variables, not committed files
- `.gitignore` excludes local Terraform state, plans, provider cache, and secret variable files

---

## Step 3 — Provision and verify disposable VM `9300` from template `9010`

### Rationale 

This step proves the actual Infrastructure as Code capability.

Terraform should create a new disposable VM `9300` by cloning the already proven Proxmox template `9010`.

This proves:

- Terraform can talk to the Proxmox API
- Terraform can use the existing workload-ready template
- Terraform can define VM identity, Cloud-Init, network, and DNS configuration
- Terraform can create a reproducible VM environment automatically
- The live target VM `9200` remains untouched

### create Proxmox API token  

Create or verify a Proxmox API token in the Proxmox Web UI 

Proxmx API tokens are path based - i.e. they can be created on the top most level / path ("Datacenter") or on level of individual VMs. path-level permissions propagate downward teh tree. 

We choose the top level path, sicn ethat gives us the neceessary rights to operate on multiple VMs and tenplates to perform teh clone      

Suggested UI path:

1. navigate to Datacenter (left sidebar) -> Permissions -> API Tokens -> Add
2. Fill in the "Add: Token" form:
 - Note: For the quickest smoke test (and onyl for this) we use user root@pam and leave proivilege selction  uncehcked 
 ((so the token inherits root@pam permissions adn we donÄt need to create a separate ACL). The token wil be stroyed afte rthe smoek test imemdiately. 
- User: root@pam
- Token ID: terraform-smoke
- Privilege Separation: unchecked 
- Expire: optional / short 
- Comment: "Temporary Terraform Smoke VM Token"
3. select add  to create a create a temporary token for root@pam taht we will destroy imemdiately after our smoek test succeeded
4. Proxmox dispalys teh created token secret only once. It needs to be copied imemdiately.  
~~~text
Token ID: root@pam!terraform-smoke
Secret:   <redacted>
~~~

4. Then it can be exported later in a terminal as `TF_VAR_proxmox_api_token` for Terraform / bpg/proxmox - here's the "template" taht needs tro be fileld before issuing terrafrom commands:

~~~bash
# Use the Proxmox API endpoint reachable from your laptop.
export TF_VAR_proxmox_endpoint="https://<PROXMOX_HOST_OR_IP>:8006/"

# Combine user, token ID, and secret exactly like this.
export TF_VAR_proxmox_api_token='root@pam!terraform-smoke=<SECRET_VALUE>'

# Temporary Cloud-Init password for the disposable smoke VM.
export TF_VAR_smoke_vm_ci_password='<TEMP_PASSWORD_FOR_SMOKE_VM>'
~~~

> [!NOTE] **Secret handling**
>
> Liek shown above, the Phase 08 Terraform proof uses **local credential injection through environment variables**, not committed credential files. The reusable Terraform configuration and provider lock file are committed, while the real Proxmox API token, temporary Cloud-Init password, local Terraform state, plan files, `.tfvars` files, and provider cache stay outside Git.
>
> The **Proxmox API token is used only for the temporary smoke-VM proof** and is **revoked after the Terraform lifecycle has been completed** and VM `9300` has been destroyed.
>
> This is **safe local credential handling for a scoped IaC proof**, not a full secret-management solution. If Terraform is later expanded to manage long-lived target infrastructure, credentials should move to a stronger secret-management model such as GitHub Actions secrets, SOPS, Vault, or another dedicated secret store.

### Action

In this action, we run the Terraform lifecycle for the new Proxmox smoke VM. The goal is to prove that the source-controlled Infrastructure as Code files can initialize, validate, plan, and create VM `9300` through the Proxmox API.

**Run Terraform from the new Phase 08 Terraform directory**

Before executing the Terraform lifecycle, the locked Phase 08 values are kept nearby as a short reference and for illustration purposes: These are the values the Terraform config is expected to use, and the later `terraform plan`, Proxmox host verification, and guest-network checks are compared against them:

- Proxmox node name: `sd-178532`
- Source template VMID: `9010`
- Smoke VMID: `9300`
- Smoke VM name: `ubuntu-2404-terraform-smoke-01`
- Datastore: `vmdata`
- Network bridge: inherited from the template (`vmbr1`)
- Smoke VM IP: `10.10.10.30/24`
- Gateway: `10.10.10.1`
- DNS: `1.1.1.1`
- Live target VM to avoid touching: `9200`

~~~bash
# First ping the choosen Smopke Vm IP to ensure it is not taken by another VM 
$ ping -c 3 10.10.10.30
PING 10.10.10.30 (10.10.10.30) 56(84) bytes of data.
--- 10.10.10.30 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2043ms

# Move into the isolated Phase 08 Terraform configuration directory.
cd infra/terraform/proxmox-smoke-vm

# Provide the Proxmox API endpoint to Terraform through an environment variable.
# TF_VAR_<name> automatically maps to the Terraform variable `<name>`.
export TF_VAR_proxmox_endpoint="https://<PROXMOX_HOST_OR_IP>:8006/"

# Provide the Proxmox API token to Terraform through an environment variable.
# Do not commit this value and do not paste the real token into documentation.
export TF_VAR_proxmox_api_token='root@pam!<TOKEN_ID>=<TOKEN_VALUE>'

# Provide a temporary Cloud-Init password for the disposable smoke VM.
# Do not commit this value and do not reuse sensitive passwords.
export TF_VAR_smoke_vm_ci_password='<TEMP_PASSWORD_FOR_SMOKE_VM>'

# Initialize Terraform in this directory.
# This downloads the Proxmox provider and prepares the local `.terraform/` folder.
$ terraform init
nitializing the backend...
Initializing provider plugins...
- Finding bpg/proxmox versions matching "~> 0.70"...
- Installing bpg/proxmox v0.104.0...
- Installed bpg/proxmox v0.104.0 (self-signed, key ID ...)
...
Terraform has been successfully initialized!

# Validate the Terraform files before planning or applying changes.
# This checks syntax and provider-schema usage.
$ terraform validate
Success! The configuration is valid. 

# Build an execution plan for the disposable smoke VM.
# -out=tfplan writes the reviewed plan to a local plan file.
$ terraform plan -out=tfplan
Terraform will perform the following actions:
  # proxmox_virtual_environment_vm.smoke_vm will be created
  + resource "proxmox_virtual_environment_vm" "smoke_vm" {
      ....
      + name                                 = "ubuntu-2404-terraform-smoke-01"
      + node_name                            = "sd-178532"
      ...
      + scsi_hardware                        = "virtio-scsi-pci"
      ...
      + tags                                 = [
          + "phase-08",
          + "terraform",
          + "smoke-vm",
        ]
      + template                             = false
      ...
      + vm_id                                = 9300
      ...
      + clone {
          + full    = true
          + retries = 1
          + vm_id   = 9010
        }
      ...
      + cpu {
          + cores      = 2
          ...  
          + type       = "qemu64"
        }

      + initialization {
          + datastore_id         = "vmdata"
          ...
          + interface            = "ide2"
          ...

          + dns {
              + servers = [
                  + "1.1.1.1",
                ]
            }

          + ip_config {
              + ipv4 {
                  + address = "10.10.10.30/24"
                  + gateway = "10.10.10.1"
                }
            }

          + user_account {
              + password = (sensitive value)
              + username = "ubuntu"
            }
        }

      + memory {
          + dedicated      = 2048
          ...
        }
    }
Plan: 1 to add, 0 to change, 0 to destroy.
Changes to Outputs:
  + smoke_vm_id      = 9300
  + smoke_vm_ip_cidr = "10.10.10.30/24"
  + smoke_vm_name    = "ubuntu-2404-terraform-smoke-01"
Saved the plan to: tfplan
To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"

# Apply the reviewed plan.
# This creates VM 9300 from template 9010.
$ terraform apply tfplan
proxmox_virtual_environment_vm.smoke_vm: Creating...
proxmox_virtual_environment_vm.smoke_vm: Creation complete after 57s [id=9300]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
Outputs:
smoke_vm_id = 9300
smoke_vm_ip_cidr = "10.10.10.30/24"
smoke_vm_name = "ubuntu-2404-terraform-smoke-01"
~~~

---

**Terraform apply creates disposable smoke VM `9300`**

![Terraform apply creates disposable smoke VM 9300](../evidence/05-P08-terraform-apply-smoke-vm-9300-success.png)

*Figure 2: Terraform apply output for the disposable Proxmox smoke VM. The output shows `proxmox_virtual_environment_vm.smoke_vm` being created successfully after 57 seconds, with one resource added, zero changed, and zero destroyed. The Terraform outputs confirm VM ID `9300`, guest IP `10.10.10.30/24`, and VM name `ubuntu-2404-terraform-smoke-01`.*

---

For consitencxy with prior phases, corresponding **Makefiel targets** were created:

~~~bash
# Initialize the Terraform working directory.
make p08-tf-init

# Validate the Terraform configuration.
make p08-tf-validate

# Create a reviewed Terraform plan file.
make p08-tf-plan

# Apply the reviewed plan and create the disposable smoke VM.
make p08-tf-apply
~~~

### Verification on the Proxmox host

After Terraform apply succeeds, verify the smoke VM on the Proxmox host.

~~~bash
# Show the expected Phase 08 smoke VM in the Proxmox VM inventory:
# - 9010 remains as the source template
# - 9200 remains as the running live target
# - 9300 now exists as the Terraform-created smoke VM
qm list --full 
VMID NAME                                     STATUS     MEM(MB)    BOOTDISK(GB)  PID       
9000 ubuntu-2404-cloudinit-template           stopped    2048       3.50          0         
9010 ubuntu-2404-workload-ready-template-v1   stopped    4096       40.00         0         
9100 ubuntu-2404-smoke-01                     stopped    2048       16.00         0         
9200 ubuntu-2404-k3s-target-01                running    16384      40.00         ...   
9300 ubuntu-2404-terraform-smoke-01           running    2048       40.00         ...   

# Inspect the Terraform-created smoke VM configuration:
# - VMID and name match the Terraform values
# - Cloud-Init/network settings are visible
# - VM 9200 has not been changed
qm config 9300
agent: enabled=1,fstrim_cloned_disks=0,type=virtio
balloon: 0
boot: order=scsi0
cipassword: **********
ciuser: ubuntu
cores: 2
cpu: qemu64
ide2: vmdata:vm-9300-cloudinit,media=cdrom
ipconfig0: gw=10.10.10.1,ip=10.10.10.30/24
memory: 2048
meta: creation-qemu=9.2.0,ctime=1775131165
name: ubuntu-2404-terraform-smoke-01
nameserver: 1.1.1.1
net0: virtio=BC:24:11:18:BC:2D,bridge=vmbr1
numa: 0
onboot: 1
ostype: l26
scsi0: vmdata:vm-9300-disk-0,size=40G
scsihw: virtio-scsi-pci
serial0: socket
smbios1: uuid=f166863d-2f0b-4a5f-bd06-39f693b806be
sockets: 1
tags: phase-08;smoke-vm;terraform
vga: serial0
vmgenid: cd0d8786-d9a7-4615-9b92-44b06fbf87bf

~~~

---

**Proxmox inventory after Terraform created smoke VM `9300`**

![Proxmox inventory after Terraform created smoke VM 9300](../evidence/02-P08-proxmox-smoke-vm-9300-created-inventory.png)

*Figure 3: Proxmox inventory after Terraform apply. VM `9300` now appears next to the existing baseline VMs and templates, while the live target VM `9200` remains present and running. This proves that Terraform created a separate disposable VM instead of modifying the live target.*

**Proxmox summary for running smoke VM `9300`**

![Proxmox summary for running smoke VM 9300](../evidence/03-P08-proxmox-smoke-vm-9300-summary-running.png)

*Figure 4: Proxmox summary view for VM `9300`. The screenshot shows the Terraform-created smoke VM in `running` state on node `sd-178532`, with the expected private IP `10.10.10.30` and phase-specific tags. This provides UI-level proof that the VM booted and received the intended guest address.*

**Proxmox hardware view for smoke VM `9300`**

![Proxmox hardware view for smoke VM 9300](../evidence/04-P08-proxmox-smoke-vm-9300-hardware-cloudinit-network.png)

*Figure 5: Proxmox hardware view for VM `9300`. The screenshot shows the smoke VM hardware and initialization shape: 2 GiB memory, 2 CPU cores, Cloud-Init drive on `ide2`, hard disk on `vmdata`, and network device attached to bridge `vmbr1`. This supports the Terraform and `qm config 9300` verification that the VM was created with the intended baseline configuration.*

---

Expected signals:

- VM `9300` exists
- VM `9300` has the expected name:
  - `ubuntu-2404-terraform-smoke-01`
- VM `9300` is cloned from the workload-ready template path
- VM `9200` still exists and remains the live target
- Template `9010` remains unchanged


### Guest-side reachability verification from the Proxmox host

After Terraform created VM `9300`, the Proxmox host was used to verify that the VM answered on the intended Cloud-Init IP address.

~~~bash
# Verify that the Terraform-created smoke VM answers on its configured private IP.
$ ping -c 3 10.10.10.30
PING 10.10.10.30 (10.10.10.30) 56(84) bytes of data.
64 bytes from 10.10.10.30: icmp_seq=1 ttl=64 time=0.343 ms
64 bytes from 10.10.10.30: icmp_seq=2 ttl=64 time=0.299 ms
64 bytes from 10.10.10.30: icmp_seq=3 ttl=64 time=0.339 ms

--- 10.10.10.30 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss

# Ask the QEMU Guest Agent for the guest-side network interfaces.
$ qm guest cmd 9300 network-get-interfaces
[
  {
    "name": "eth0",
    "hardware-address": "<redacted>",
    "ip-addresses": [
      {
        "ip-address": "10.10.10.30",
        "ip-address-type": "ipv4",
        "prefix": 24
      },
      {
        "ip-address": "<redacted-ipv6-link-local>",
        "ip-address-type": "ipv6",
        "prefix": 64
      }
    ]
  }
]

~~~

The QEMU Guest Agent also confirmed that the VM’s guest network interface received the expected address.


Result: The Terraform-created smoke VM 9300 was reachable on 10.10.10.30/24, and the QEMU Guest Agent confirmed that the guest OS had the expected eth0 IPv4 address.

### Result

Terraform successfully provisions disposable Proxmox VM `9300` from workload-ready template `9010`.

The successful end state is shown by these signals / verification points:

- `terraform init` succeeds
- `terraform validate` succeeds
- `terraform plan -out=tfplan` produces a plan for VM `9300`
- `terraform apply tfplan` creates the smoke VM
- Proxmox inventory shows VM `9300`
- `qm config 9300` shows the expected VM identity and Cloud-Init/network configuration
- Live VM `9200` remains untouched

This proves the project can define and reproduce infrastructure through Terraform without putting the live target cluster at risk.

---

## Step 4 — Destroy the smoke VM and record the safety model

### Rationale

The smoke VM is intentionally disposable: Terraform must also be able to remove the infrastructure it created. Destroying VM `9300` without any side effects will confirm that the Infrastructure as Code scope is isolated and does not affect the live target VM `9200`.

This is the key safety model of Phase 08:

- Terraform manages only the disposable smoke `VM 9300`
- Terraform does not manage or modify the live target VM `9200`
- The live application platform remains stable

### Action

In this action, we destroy the Terraform-created smoke VM again. This proves the full IaC lifecycle and confirms that Phase 08 can clean up its own infrastructure without affecting the live target.

Destroy the smoke VM from the Terraform working directory.

~~~bash
# Move into the Phase 08 Terraform directory if not already there.
cd infra/terraform/proxmox-smoke-vm

# Destroy the Terraform-managed smoke VM.
# Terraform asks for confirmation before deleting managed infrastructure.
$ terraform destroy
proxmox_virtual_environment_vm.smoke_vm: Refreshing state... [id=9300]
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy
Terraform will perform the following actions:
  # proxmox_virtual_environment_vm.smoke_vm will be destroyed
  - resource "proxmox_virtual_environment_vm" "smoke_vm" {
      ...
      - id                                   = "9300" -> null
      - ipv4_addresses                       = [
          - [
              - "127.0.0.1",
            ],
          - [
              - "10.10.10.30",
            ],
        ] -> null
      ...
      - name                                 = "ubuntu-2404-terraform-smoke-01" -> null
lan: 0 to add, 0 to change, 1 to destroy.
Changes to Outputs:
  - smoke_vm_id      = 9300 -> null
  - smoke_vm_ip_cidr = "10.10.10.30/24" -> null
  - smoke_vm_name    = "ubuntu-2404-terraform-smoke-01" -> null
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.
  Enter a value: yes
proxmox_virtual_environment_vm.smoke_vm: Destroying... [id=9300]
proxmox_virtual_environment_vm.smoke_vm: Destruction complete after 8s
Destroy complete! Resources: 1 destroyed.
~~~

---

**Terraform destroy removes disposable smoke VM `9300`**

![Terraform destroy removes disposable smoke VM 9300](../evidence/06-P08-terraform-destroy-smoke-vm-9300-success.png)

*Figure 6: Terraform destroy output for the disposable smoke VM. Terraform plans one destroy action, receives explicit confirmation, destroys managed VM `9300`, and completes with one resource destroyed. This proves the cleanup side of the IaC lifecycle.*

---

If using the Makefile target:

~~~bash
# Destroy the Terraform-managed smoke VM through the Phase 08 helper target.
make p08-tf-destroy
~~~

### Verification on the Proxmox host

After destroy completes, verify that VM `9300` is gone while `9010` and `9200` remain.

~~~bash
# Show the relevant template, live target, and smoke VM IDs.
# Expected after destroy:
# - 9010 remains
# - 9200 remains
# - 9300 is absent
$ qm list --full
VMID NAME                                               STATUS     MEM(MB)    BOOTDISK(GB)  PID       
9000 ubuntu-2404-cloudinit-template                     stopped    2048               3.50  0         
9010 ubuntu-2404-workload-ready-template-v1             stopped    4096              40.00  0         
9100 ubuntu-2404-smoke-01                               stopped    2048              16.00  0         
9200 ubuntu-2404-k3s-target-01                          running    16384             40.00  ...  
~~~

---

**Proxmox inventory after Terraform destroy**

![Proxmox inventory after Terraform destroy](../evidence/07-P08-proxmox-after-destroy-smoke-vm-9300-removed.png)

*Figure 7: Proxmox inventory after Terraform destroy. VM `9300` is no longer present, while the workload-ready template `9010` and the live K3s target VM `9200` remain. This confirms that Terraform removed only the disposable smoke VM and did not affect the existing target platform.*

---

### Result

The Phase 08 Terraform smoke VM was destroyed successfully.

The successful end state is shown by these signals / verification points:

- Terraform destroy completed
- Disposable VM `9300` was removed
- Workload-ready template `9010` remained unchanged
- Live target VM `9200` remained unchanged and running

Phase 08 therefore proves a complete safe IaC lifecycle:

- Define infrastructure as code
- Provision a disposable VM from a proven template
- Verify it on Proxmox
- Destroy it cleanly
- Keep the live application target untouched

---

## Phase 08 outcome summary

Phase 08 establishes a safe Proxmox Infrastructure as Code baseline.

The phase adds:

- An isolated Terraform workspace for Proxmox VM provisioning
- A disposable smoke VM model based on workload-ready template `9010`
- Temporary Proxmox API token based automation
- Cloud-Init driven guest initialization
- Proxmox host-side verification
- Guest reachability and QEMU Guest Agent verification
- Terraform cleanup through `destroy`
- Terraform-related Makefile helpers for repeatable local execution
- Terraform provider dependency monitoring through Dependabot
- Trivy scan coverage extended to the Terraform infrastructure path

At the end of Phase 08, the project proves that Terraform can:

- authenticate against the Proxmox API
- clone a VM from the existing workload-ready template
- create and start a disposable Proxmox VM
- configure guest networking through Cloud-Init
- verify the created VM from the Proxmox host
- destroy the managed VM again
- keep the live K3s target VM `9200` untouched

This satisfies the Infrastructure as Code baseline at a safe scope and creates the foundation for later expanded Proxmox automation.

---

## Sources

### Step 1 — Proxmox baseline, IaC scope, and inherited Terraform paths

- **Project-internal Proxmox baseline documents** — Existing VM-template and target-platform context used as the source for the Phase 08 values:
  - [Phase 04 — Implementation Log](../04-proxmox-vm-baseline/IMPLEMENTATION.md)
  - [Phase 04 — Runbook](../04-proxmox-vm-baseline/RUNBOOK.md)
  - [Phase 05 — Main Implementation Log](../05-proxmox-target-delivery/IMPLEMENTATION.md)
  - [Phase 05 — Runbook](../05-proxmox-target-delivery/RUNBOOK.md)

- **Proxmox VE documentation** — VM lifecycle, Cloud-Init support, and host-side verification commands used for the Proxmox baseline and smoke-VM checks:
  - [Proxmox VE `qm` manual](https://pve.proxmox.com/pve-docs/qm.1.html)
  - [Proxmox VE Cloud-Init Support](https://pve.proxmox.com/wiki/Cloud-Init_Support)

- **Terraform documentation** — General Infrastructure as Code configuration model and root-module file structure:
  - [Terraform configuration language](https://developer.hashicorp.com/terraform/language)
  - [Terraform files and configuration structure](https://developer.hashicorp.com/terraform/language/files)

- **Practitioner Proxmox + Terraform references** — Real-world examples for choosing a Proxmox Terraform approach, using templates, and keeping Proxmox automation isolated from unrelated infrastructure examples:
  - [trfore — Provisioning Proxmox VMs with Terraform](https://www.trfore.com/posts/provisioning-proxmox-vms-with-terraform/)
  - [trfore — Provisioning Proxmox 8 VMs with Terraform and BPG](https://www.trfore.com/posts/provisioning-proxmox-8-vms-with-terraform-and-bpg/)
  - [OutaCloud — Proxmox with Terraform: The Ultimate Automation Guide](https://outacloud.com/blog/proxmox-terraform-provider-guide-hetzner-state)

---

### Step 2 — Terraform workspace, provider setup, variables, lock file, and repository hygiene

- **Terraform documentation** — Provider requirements, input variables, environment variable injection, sensitive values, local file structure, and dependency locking:
  - [Terraform providers within modules](https://developer.hashicorp.com/terraform/language/providers/requirements)
  - [Terraform input variables](https://developer.hashicorp.com/terraform/language/values/variables)
  - [Terraform CLI environment variables](https://developer.hashicorp.com/terraform/cli/config/environment-variables)
  - [Terraform sensitive data handling](https://developer.hashicorp.com/terraform/language/manage-sensitive-data)
  - [Terraform dependency lock file (`.terraform.lock.hcl`)](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

- **bpg/proxmox provider documentation** — Provider setup and Proxmox VM resource configuration:
  - [bpg/proxmox provider registry page](https://registry.terraform.io/providers/bpg/proxmox/latest)
  - [bpg/proxmox — `proxmox_virtual_environment_vm`](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm)
  - [bpg/proxmox virtual environment VM resource](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm)

- **bpg/proxmox provider guide and examples** — Practical provider usage examples for VM cloning and Cloud-Init configuration:
  - [bpg/proxmox — Clone a VM guide](https://library.tf/providers/bpg/proxmox/latest/docs/guides/clone-vm)
  - [bpg/proxmox — Configure a VM with Cloud-Init](https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/guides/cloud-init.md)
  - [bpg/terraform-provider-proxmox examples](https://github.com/bpg/terraform-provider-proxmox/tree/main/examples)

- **Git documentation** — `.gitignore` patterns for excluding generated local Terraform state, plans, `.tfvars`, provider cache, and local-only secret inputs:
  - [Git documentation — `gitignore`](https://git-scm.com/docs/gitignore)

- **GNU Make documentation** — Makefile helper targets, `.PHONY` targets, variables, and recipe syntax used for repeatable Phase 08 Terraform commands:
  - [GNU Make Manual — Recipe Syntax](https://www.gnu.org/software/make/manual/html_node/Recipe-Syntax.html)
  - [GNU Make Manual — Phony Targets](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html)
  - [GNU Make Manual — Variables Make Makefiles Simpler](https://www.gnu.org/software/make/manual/html_node/Variables-Simplify.html)

---

### Step 3 — Proxmox API token, Terraform lifecycle, VM creation, Cloud-Init, and guest verification

- **Proxmox VE documentation** — API token authentication and Proxmox user/token management:
  - [Proxmox VE User Management / API token documentation](https://pve.proxmox.com/pve-docs/pveum.1.html)

- **Terraform CLI documentation** — Initialization, validation, planning, applying a reviewed plan, and standard Terraform workflow:
  - [Terraform CLI — init](https://developer.hashicorp.com/terraform/cli/commands/init)
  - [Terraform CLI — validate](https://developer.hashicorp.com/terraform/cli/commands/validate)
  - [Terraform CLI — plan](https://developer.hashicorp.com/terraform/cli/commands/plan)
  - [Terraform CLI — apply](https://developer.hashicorp.com/terraform/cli/commands/apply)
  - [HashiCorp Learn — Terraform workflow / initialize configuration](https://developer.hashicorp.com/terraform/tutorials/cli/init)

- **bpg/proxmox provider documentation** — Proxmox VM cloning, VM resource configuration, Cloud-Init initialization, static IPv4 configuration, and QEMU Guest Agent-related behavior:
  - [bpg/proxmox — `proxmox_virtual_environment_vm`](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm)
  - [bpg/proxmox — Clone a VM guide](https://library.tf/providers/bpg/proxmox/latest/docs/guides/clone-vm)
  - [bpg/proxmox — Configure a VM with Cloud-Init](https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/guides/cloud-init.md)

- **Proxmox VE documentation** — Host-side VM inspection and Cloud-Init behavior used to verify VM `9300`:
  - [Proxmox VE `qm` manual](https://pve.proxmox.com/pve-docs/qm.1.html)
  - [Proxmox VE Cloud-Init Support](https://pve.proxmox.com/wiki/Cloud-Init_Support)

- **Practitioner Proxmox + Terraform references** — Example workflows for Proxmox API access, template-based VM provisioning, Cloud-Init network values, Terraform planning/applying, and later cleanup:
  - [trfore — Provisioning Proxmox VMs with Terraform](https://www.trfore.com/posts/provisioning-proxmox-vms-with-terraform/)
  - [trfore — Provisioning Proxmox 8 VMs with Terraform and BPG](https://www.trfore.com/posts/provisioning-proxmox-8-vms-with-terraform-and-bpg/)
  - [OutaCloud — Proxmox with Terraform: The Ultimate Automation Guide](https://outacloud.com/blog/proxmox-terraform-provider-guide-hetzner-state)

---

### Step 4 — Terraform destroy, cleanup proof, and safety model

- **Terraform CLI documentation** — Destroy lifecycle used to remove disposable VM `9300` after the proof:
  - [Terraform CLI — destroy](https://developer.hashicorp.com/terraform/cli/commands/destroy)
  - [Terraform CLI — apply](https://developer.hashicorp.com/terraform/cli/commands/apply)

- **Proxmox VE documentation** — Host-side VM inventory and configuration checks after cleanup:
  - [Proxmox VE `qm` manual](https://pve.proxmox.com/pve-docs/qm.1.html)

- **Practitioner Proxmox + Terraform references** — End-to-end create/test/remove patterns for Proxmox VMs managed through Terraform:
  - [trfore — Provisioning Proxmox VMs with Terraform](https://www.trfore.com/posts/provisioning-proxmox-vms-with-terraform/)
  - [trfore — Provisioning Proxmox 8 VMs with Terraform and BPG](https://www.trfore.com/posts/provisioning-proxmox-8-vms-with-terraform-and-bpg/)

---

### Phase 08 dependency monitoring and security-scan integration

- **GitHub Dependabot documentation** — Dependabot configuration and supported ecosystems, including Terraform provider dependency monitoring:
  - [GitHub Docs — Configuring Dependabot version updates](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuring-dependabot-version-updates)
  - [GitHub Docs — Dependabot options reference](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)
  - [GitHub Docs — Supported ecosystems and repositories](https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories)

- **Trivy documentation** — Terraform/IaC, filesystem, misconfiguration, and secret scanning coverage used when extending the existing security scan scope to `infra/terraform`:
  - [Trivy Docs — Scanning Terraform files with Trivy](https://trivy.dev/docs/latest/tutorials/misconfiguration/terraform/)
  - [Trivy Docs — Misconfiguration Scanning](https://trivy.dev/docs/latest/scanner/misconfiguration/)
  - [Trivy Docs — Filesystem scanning](https://trivy.dev/docs/latest/guide/target/filesystem/)

---

### Future hardening references — IP address management and broader Proxmox networking

- **Proxmox VE documentation** — Proxmox-native path for future automated IP address handling through Software-Defined Networking (SDN), IPAM plugins, and DHCP lease management:
  - [Proxmox VE — Software-Defined Networking](https://pve.proxmox.com/pve-docs/chapter-pvesdn.html)

- **NetBox documentation** — General IPAM source-of-truth model for larger environments, including prefixes, IP ranges, individual IP addresses, hierarchy, and utilization tracking:
  - [NetBox — IP Address Management](https://netboxlabs.com/docs/netbox/features/ipam/)