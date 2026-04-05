# ▶️ Runbook — Phase 04 (Proxmox VM Baseline): Proxmox VM template and smoke VM

> ## 👤 About
> This document is the short rerun guide for **Phase 04 (Proxmox VM Baseline)**.  
> It is meant as a quick rerun reference without the long-form diary. 
>
> For the detailed build diary and rationale, see: **[IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For the earlier discovery and target-host audit, see: **[DISCOVERY.md](DISCOVERY.md)**.  
> For phase-scoped rationale and outcome notes, see: **[DECISIONS.md](DECISIONS.md)**.  
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**.

---

## 📌 Index (top-level)

- [**Goal**](#goal)
- [**Preconditions**](#preconditions)
- [**Step 0 — Confirm Proxmox storage targets**](#step-0--confirm-proxmox-storage-targets)
- [**Step 1 — Stage the Ubuntu 24.04 cloud image**](#step-1--stage-the-ubuntu-2404-cloud-image)
- [**Step 2 — Create the reusable Cloud-Init VM template (`9000`)**](#step-2--create-the-reusable-cloud-init-vm-template-9000)
- [**Step 3 — Create the reference smoke VM (`9100`)**](#step-3--create-the-reference-smoke-vm-9100)
- [**Step 4 — Verify the reference smoke VM from inside the guest**](#step-4--verify-the-reference-smoke-vm-from-inside-the-guest)
- [**Cleanup / rerun**](#cleanup--rerun)
- [**Files added in this phase**](#files-added-in-this-phase)

---

## Goal

Create and verify the first reusable **Proxmox-backed VM baseline** for the project:

- Reusable Ubuntu 24.04 **Cloud-Init VM template** as `9000`
- Reference **smoke VM** as `9100`
- Proven guest login, Cloud-Init completion, usable root disk, and outbound connectivity

---

## Preconditions

- Proxmox web UI access works
- Proxmox host-shell access works
- Proxmox node is online
- storage targets are available
- outbound download from the Proxmox host to the Ubuntu cloud-image index works

> [!NOTE] **🧩 Placeholder warning**
>
> The smoke-VM password in the commands below is a placeholder.
> Replace it before execution.

---

## Step 0 — Confirm Proxmox storage targets

~~~bash
# pvesm = Proxmox VE Storage Manager CLI
# Confirm that the expected storage targets are active before creating VM artifacts
$ pvesm status
Name     Type     Status           Total            Used       Available        %
local     dir     active        53733704         6215284        44756488   11.57%
vmdata zfspool     active      5653921792             468      5653921324    0.00%
~~~

**Success looks like:**
- `local` is `active`
- `vmdata` is `active`

---

## Step 1 — Stage the Ubuntu 24.04 cloud image

~~~bash
# Create a dedicated working directory for the host-side cloud-image staging
mkdir -p /root/pve-images
cd /root/pve-images

# Download the Ubuntu 24.04 released cloud image into a temporary file first
wget -c \
  -O ubuntu-24.04-server-cloudimg-amd64.img.part \
  https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img

# Confirm that the temporary file exists and has a plausible non-zero size
ls -lh ubuntu-24.04-server-cloudimg-amd64.img.part

# Move the verified download into place as the real import source
mv ubuntu-24.04-server-cloudimg-amd64.img.part \
   ubuntu-24.04-server-cloudimg-amd64.img
~~~

**Success looks like:**
- the `.part` file exists
- the file size is plausible
- the final `.img` file is present in `/root/pve-images`

---

## Step 2 — Create the reusable Cloud-Init VM template (`9000`)

~~~bash
# --- (1) Create the base VM shell ---
$ qm create 9000 \
  --name ubuntu-2404-cloudinit-template \
  --memory 2048 \
  --cores 2 \
  --ostype l26 \
  --scsihw virtio-scsi-pci

# --- (2) Import the cloud image and add the Cloud-Init drive ---
$ qm set 9000 \
  --scsi0 vmdata:0,import-from=/root/pve-images/ubuntu-24.04-server-cloudimg-amd64.img

$ qm set 9000 --ide2 vmdata:cloudinit
$ qm set 9000 --boot order=scsi0
$ qm set 9000 --serial0 socket --vga serial0

# --- (3) Verify the VM object before templating ---
$ qm config 9000
$ qm list --full
$ pvesm list vmdata

# --- (4) Convert to template ---
$ qm template 9000

# --- (5) Verify the final template result ---
$ qm config 9000
$ qm list --full
$ pvesm list vmdata
~~~

**Success looks like:**
- `qm config 9000` includes:
  - `boot: order=scsi0`
  - `ide2: ...cloudinit...`
  - `scsi0: ...`
  - `template: 1` after templating
- `qm list --full` shows a non-zero boot disk
- `pvesm list vmdata` shows:
  - `vmdata:base-9000-disk-0`
  - `vmdata:vm-9000-cloudinit`

---

## Step 3 — Create the reference smoke VM (`9100`)

~~~bash
# --- (1) Clone the reference smoke VM from the reusable template ---
$ qm clone 9000 9100 --name ubuntu-2404-smoke-01

# --- (2) Configure guest networking and Cloud-Init values ---
$ qm set 9100 --net0 virtio
$ qm set 9100 --ciuser ubuntu
$ qm set 9100 --cipassword 'CHANGE_TO_A_FRESH_TEMP_PASSWORD'
$ qm set 9100 --ipconfig0 ip=dhcp

# --- (3) Enlarge the root disk before first boot ---
$ qm resize 9100 scsi0 16G

# --- (4) Verify the VM object before boot ---
$ qm config 9100
$ qm cloudinit pending 9100
$ qm list --full

# --- (5) Start the smoke VM ---
$ qm start 9100
$ qm list --full
~~~

**Success looks like:**
- `qm config 9100` includes:
  - `net0: virtio=...` with no bridge parameter
  - `ipconfig0: ip=dhcp`
  - `ide2: ...cloudinit...`
  - `scsi0: ... size=16G`
- `qm cloudinit pending 9100` shows the queued Cloud-Init values for the guest
- `qm list --full` shows the VM in `running` state after start
- the warning about no bridge attachment during `qm start 9100` is expected in this phase

> [!NOTE] **🧩 Guest NIC without bridge attachment**
>
> In this phase, the smoke VM intentionally uses `net0: virtio` without `bridge=vmbr0`.
> That makes Proxmox/QEMU use the default unbridged **user-mode NAT** guest path on this host.

---

## Step 4 — Verify the reference smoke VM from inside the guest

~~~bash
# Open the serial console from the Proxmox host
qm terminal 9100
~~~

After logging in as `ubuntu`, run:

~~~bash
# Confirm guest identity and Cloud-Init completion
whoami
hostname
cloud-init status --wait

# Confirm addressing and routing
ip -brief address
ip route

# Confirm enlarged root filesystem
df -h /

# Confirm outbound connectivity
ping -c 2 1.1.1.1
curl -I --max-time 10 https://example.com
~~~

**Success looks like:**
- `whoami` returns `ubuntu`
- `hostname` returns `ubuntu-2404-smoke-01`
- `cloud-init status --wait` returns `status: done`
- `ip route` shows default route via `10.0.2.2`
- `df -h /` shows roughly `15G`
- outbound IP and HTTPS access work

---

## Cleanup / rerun

### Stop the smoke VM cleanly

~~~bash
qm stop 9100
qm wait 9100
~~~

### Recreate the smoke VM from the template

~~~bash
qm stop 9100
qm wait 9100
qm destroy 9100

qm clone 9000 9100 --name ubuntu-2404-smoke-01
qm set 9100 --net0 virtio
qm set 9100 --ciuser ubuntu
qm set 9100 --cipassword 'CHANGE_TO_A_FRESH_TEMP_PASSWORD'
qm set 9100 --ipconfig0 ip=dhcp
qm resize 9100 scsi0 16G
qm start 9100
~~~

---

## Files added in this phase

- `project-docs/04-proxmox-vm-baseline/IMPLEMENTATION.md`
- `project-docs/04-proxmox-vm-baseline/RUNBOOK.md`
- `project-docs/04-proxmox-vm-baseline/DECISIONS.md`
- `project-docs/04-proxmox-vm-baseline/DISCOVERY.md`

### Files modified in this phase

- `project-docs/INDEX.md`

---