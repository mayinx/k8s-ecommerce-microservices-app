# 🧱 Implementation Log — Phase 04 (Proxmox VM Baseline): Proxmox VM template and smoke VM

> ## 👤 About
> This document is the implementation log and detailed project build diary for **Phase 04 (Proxmox VM Baseline)**.  
> It records the **final proven implementation path** for the first reusable Proxmox-backed VM baseline in this project.  
>
> For the earlier **discovery and environment audit** that informed this implementation path, see: **[DISCOVERY.md](DISCOVERY.md)**.  
> For the shorter, reproducible TL;DR **command checklist / rerun guide**, see: **[RUNBOOK.md](RUNBOOK.md)**.  
> For phase-scoped **rationale and outcome notes**, see: **[DECISIONS.md](DECISIONS.md)**.  
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**.

---

## 📌 Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done (Phase 04)**](#definition-of-done-phase-04)
- [**Preconditions**](#preconditions)
- [**Step 0 — Confirm the Proxmox target host and storage layout**](#step-0--confirm-the-proxmox-target-host-and-storage-layout)
- [**Step 1 — Stage the Ubuntu 24.04 cloud image on the Proxmox host**](#step-1--stage-the-ubuntu-2404-cloud-image-on-the-proxmox-host)
- [**Step 2 — Create the reusable base VM template (`9000`) from the host-staged cloud image**](#step-2--create-the-reusable-base-vm-template-9000-from-the-host-staged-cloud-image)
- [**Step 3 — Create the reference smoke VM (`9100`) from the template**](#step-3--create-the-reference-smoke-vm-9100-from-the-template)
- [**Step 4 — Verify the reference smoke VM from inside the guest**](#step-4--verify-the-reference-smoke-vm-from-inside-the-guest)
- [**Cleanup / rerun notes**](#cleanup--rerun-notes)
- [**Baseline observations and evidence (Phase 04)**](#baseline-observations-and-evidence-phase-04)
- [**Sources**](#sources)

---

## Purpose / Goal

### Establish the first reusable Proxmox-backed VM baseline

- The goal of Phase 04 is to prove the first **reusable VM baseline** on the provided Proxmox host.
- This phase focuses on a **template + smoke VM path** that is stable, repeatable, and easy to verify.
- The concrete deliverables are:
  - a reusable Ubuntu 24.04 **Cloud-Init VM template**
  - a **reference smoke VM** cloned from that template
  - explicit verification at both layers:
    - **hypervisor-side verification** on the Proxmox host itself
    - **guest-side verification** inside the guest VM operating system on that host

### Establish a CLI-driven template workflow (instead of GUI-based VM creation)

This phase follows the official Proxmox **[Cloud-Init](https://pve.proxmox.com/wiki/Cloud-Init_Support) template workflow**:

- (1) Use a **Cloud-Init-capable Ubuntu image** 
- (2) Turn this image into a **reusable VM template** on the Proxmox host
- (3) Clone guest VMs from that template 

That is the workflow Proxmox itself recommends for rolling out new VM instances efficiently. The Proxmox documentation explicitly recommends converting a prepared **Cloud-Init image** into a **VM template** and then using that template to create **linked clones** quickly.

The Proxmox GUI wizard is a valid operational surface for VM creation and was inspected during discovery. For this phase, however, the baseline is documented via the **CLI-driven template path** because it makes the chosen workflow ...

- easier to reproduce exactly
- easier to verify from the host and from inside the guest
- and easier to align later with automation and Infrastructure as Code work

The implementation therefore standardizes on one clear documented path:

- create a reusable **Cloud-Init VM template**
- clone a **reference smoke VM**
- verify the result from both the **Proxmox host** and **inside the guest**

### Prove the VM at both verification layers (host + guest)

- A new Proxmox sidebar entry for a new VM/VM-Template is not enough to count as success.
- This phase therefore verifies the VM at two distinct levels:
  - on the **Proxmox host** (`qm`, `pvesm`, inventory, disk objects, runtime state)
  - and inside the **guest operating system** itself
- The guest must boot, accept login, finish Cloud-Init initialization, expose a usable root filesystem, and prove outbound connectivity.

---

## Definition of done (Phase 04)

- The provided **Proxmox host** is confirmed as a usable guest VM target.
- A reusable Ubuntu 24.04 **Cloud-Init VM template** exists as **VM/template `9000`**.
- A **reference smoke VM `9100`** can be cloned from that template.
  - The smoke VM boots successfully.
  - Guest login works.
  - `cloud-init status --wait` returns `status: done`.
  - The guest root filesystem is confirmed at a usable size after hypervisor-side disk enlargement.
  - Outbound connectivity works from inside the guest.

---

## Preconditions

- Valid access to the provided Proxmox web UI and host shell
- The Proxmox node is online
- The relevant storage targets are available for template and clone work
- The Ubuntu 24.04 released cloud image is reachable from the Proxmox host

---

## Step 0 — Confirm the Proxmox target host and storage layout

### Rationale

Before creating the reusable template and the first smoke VM, a confirmation is needed 
- that the provided **Proxmox host** is actually usable for this phase 
- and that the required **storage targets** are present.

This step is the hypervisor-side starting point for the whole phase:
- the **host** is the physical machine running Proxmox
- the later **VM** will run on that host as a **guest**
- the **storage targets** must already exist before a cloud image can be imported and turned into a reusable template

This implementation step builds on the broader **target-host reconnaissance** captured separately in **[DISCOVERY.md](DISCOVERY.md)**.

### Action

**Node summary on the target Proxmox host**

![Node summary on the target Proxmox host](./evidence/px/03-PX-Node_Summary-dash.png)

***Figure 1.*** *Node summary view showing the provided Proxmox host online and ready for VM work. This establishes the real execution target for the phase.*

**Datacenter storage view**

![Datacenter storage view](./evidence/px/06-PX-Datacenter_Storage.png)

***Figure 2.*** *Datacenter storage view showing the available storage targets used for the template and smoke VM workflow.*

**Investigate Proxmox storage targets via host shell**

Using the Proxmox Storage Manager `pvesm` in the host shell shows, that **both expected Proxmox storage targets are present and active**, so the host is ready for the template-and-clone workflow used in this phase:

~~~bash
# pvesm = Proxmox VE Storage Manager CLI
# Show configured Proxmox storage targets and confirm that usable VM disk storage is available
$ pvesm status
Name     Type     Status           Total            Used       Available        %
local     dir     active        53733704         6215284        44756488   11.57%
vmdata zfspool     active      5653921792             468      5653921324    0.00%
~~~

> [!NOTE] **🧩 `local` vs `vmdata`**  
> In this phase, `local` is the **host-side file storage** typically used for helper assets such as templates, ISOs, snippets, and backups.  
> `vmdata` is the **Proxmox storage target backed by the host ZFS pool `zpve`**. In this phase it is used for the imported root disk, the reusable template base disk, the Cloud-Init drive, and the smoke clone disk.  
> So `vmdata` is not a vague “virtual reserve area”; it is the real storage location where the VM disk artifacts for this phase live.

---

## Step 1 — Stage the Ubuntu 24.04 cloud image on the Proxmox host

### Rationale

Now that the Proxmox host and storage targets are confirmed, the next step is to **stage a Ubuntu 24.04 cloud image** on the Proxmox host.

- This **cloud image** is the **raw operating-system base** from which the reusable **CloudInit VM template** will be built. In the case of Ubuntu, that cloud image is provided at https://cloud-images.ubuntu.com.
- So instead of installing Ubuntu interactively from scratch, this phase uses a **prebuilt cloud image** and **converts it into a Proxmox template**. This is much faster and fits the later **template -> clone** workflow.
- A **temporary `.part` file** is used first so the download can be verified before it is moved into place as the real import source.

### Action

~~~bash
# Create a dedicated working directory for staging the cloud image
mkdir -p /root/pve-images
cd /root/pve-images

# Download the Ubuntu 24.04 released cloud image into a temporary file first
wget -c \
  -O ubuntu-24.04-server-cloudimg-amd64.img.part \
  https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img

# Verify that the temporary download exists and has a plausible non-zero size
$ ls -lh ubuntu-24.04-server-cloudimg-amd64.img.part
-rw-r--r-- 1 root root 601M Mar 23 19:31 ubuntu-24.04-server-cloudimg-amd64.img.part

# Move the validated download into place as the real import source
$ mv ubuntu-24.04-server-cloudimg-amd64.img.part \
   ubuntu-24.04-server-cloudimg-amd64.img
~~~

### Result

The cloud image was downloaded and successfully staged on the Proxmox host.

> [!NOTE] **🧩 Cloud Image**  
> A cloud image is a prebuilt operating-system image designed for automated first boot, typically with Cloud-Init support already present.  
> That makes it a good fit for a Proxmox **template -> clone -> configure** workflow.

---

## Step 2 — Create the reusable base VM template (`9000`) from the host-staged cloud image

### Rationale

With the Ubuntu 24.04 cloud image staged on the Proxmox host, the next step is to turn that image into a reusable **Proxmox CloudInit VM template**.

- This is done via Proxmox’s command-line VM manager (`qm`).  
- The result of this step is **a VM template as reusable base artifact** from which later smoke or application VMs can be cloned quickly and consistently.

### Action

> [!NOTE] **🧩 Template vs Clone**  
> The template is the reusable base artifact.  
> Real guest VMs are created as clones from that base.  
> This corresponds with the standard Proxmox Cloud-Init **template -> clone** workflow.

The template uses the following settings:

- VM ID `9000` (following a suggested Cloud-Init convention from the Proxmox docs, to use high numbered VM IDs for reusable VM base templates) 
- `virtio-scsi-pci` as the SCSI controller (Proxmox recommends VirtIO-based storage controllers for modern Linux guests when performance and maintainability matter)
- `l26` as the Proxmox guest operating-system type for a modern Linux guest (a Proxmox-specific selector for Linux Kernel from 2.6 through 6.x)
- Guest Shell access (`serial0: socket` + `vga: serial0`) for straightforward guest verification: This configuration redirects the VM’s primary console output to the first virtual serial port, allowing the guest to be accessed and verified directly from the host via `qm terminal <vmid>` instead of relying on a graphical GUI console.

> [!NOTE] **🧩 `qm`, QEMU, and KVM**  
> In short: `qm` is the Proxmox VM manager, QEMU provides the virtual machine, and KVM provides the hardware-assisted virtualization underneath it:
>
> Proxmox manages virtual machines through the `qm` command - Proxmox’s command-line manager for QEMU/KVM virtual machines:
> - **QEMU** (**Quick Emulator**) provides the virtual machine itself, meaning the emulated virtual hardware seen by the guest.
> - **KVM** (**Kernel-based Virtual Machine**) is the Linux kernel virtualization layer that accelerates those virtual machines using the host CPU’s hardware-virtualization features.
> - **`qm`** is the Proxmox tool that creates, configures, starts, stops, clones, and templates those VMs.

> [!NOTE] **🧩 Cloud-Init drive**  
> A **Cloud-Init drive** is a small virtual CD-ROM-like disk that Proxmox attaches to the VM on `ide2`.  
> It does not hold the Ubuntu operating system itself. Proxmox uses it instead to write the VM’s first-boot configuration on it, f.i.:
> - the initial user name (`ciuser`)
> - the initial password (`cipassword`) or SSH keys 
> - network settings (`ipconfig0`)
> - other Cloud-Init metadata
>
> The real operating system lives on the root disk (`scsi0`).  
> The Cloud-Init drive only provides the configuration data that the guest reads during its first boot.

~~~bash
# --- (1) Create the base VM shell ---
# Create the base VM object that will become the reusable template
# qm = Proxmox QEMU/KVM virtual-machine manager CLI
$ qm create 9000 \
  --name ubuntu-2404-cloudinit-template \
  --memory 2048 \
  --cores 2 \
  --ostype l26 \
  --scsihw virtio-scsi-pci

# --- (2) Import the Ubuntu cloud image and add the Cloud-Init drive ---

# Import the Ubuntu cloud image as the real root disk on vmdata
$ qm set 9000 \
  --scsi0 vmdata:0,import-from=/root/pve-images/ubuntu-24.04-server-cloudimg-amd64.img
update VM 9000: -scsi0 vmdata:0,import-from=/root/pve-images/ubuntu-24.04-server-cloudimg-amd64.img
transferred 3.5 GiB of 3.5 GiB (100.00%)
scsi0: successfully created disk 'vmdata:vm-9000-disk-0,size=3584M'

# Attach the Cloud-Init drive
$ qm set 9000 --ide2 vmdata:cloudinit
update VM 9000: -ide2 vmdata:cloudinit
ide2: successfully created disk 'vmdata:vm-9000-cloudinit,media=cdrom'
generating cloud-init ISO

# Restrict boot to the imported root disk
$ qm set 9000 --boot order=scsi0

# Redirect the primary guest console to the first serial interface
$ qm set 9000 --serial0 socket --vga serial0

# --- (3) Verify the VM object before converting it into a template ---
$ qm config 9000
boot: order=scsi0
cores: 2
ide2: vmdata:vm-9000-cloudinit,media=cdrom
memory: 2048
meta: creation-qemu=9.2.0,ctime=<redacted>
name: ubuntu-2404-cloudinit-template
ostype: l26
scsi0: vmdata:vm-9000-disk-0,size=3584M
scsihw: virtio-scsi-pci
serial0: socket
smbios1: uuid=<redacted>
vga: serial0
vmgenid: <redacted>

$ qm list --full
VMID NAME                            STATUS   MEM(MB) BOOTDISK(GB) PID
9000 ubuntu-2404-cloudinit-template  stopped     2048         3.50 0

$ pvesm list vmdata
Volid                    Format  Type            Size VMID
vmdata:vm-9000-cloudinit raw     images       4194304 9000
vmdata:vm-9000-disk-0    raw     images    3758096384 9000

# --- (4) Convert the VM into a reusable VM template ---
$ qm template 9000

# --- (5) Verify the final template result ---
$ qm config 9000
boot: order=scsi0
cores: 2
ide2: vmdata:vm-9000-cloudinit,media=cdrom
memory: 2048
meta: creation-qemu=9.2.0,ctime=<redacted>
name: ubuntu-2404-cloudinit-template
ostype: l26
scsi0: vmdata:base-9000-disk-0,size=3584M
scsihw: virtio-scsi-pci
serial0: socket
smbios1: uuid=<redacted>
template: 1
vga: serial0
vmgenid: <redacted>

$ qm list --full
VMID NAME                            STATUS   MEM(MB) BOOTDISK(GB) PID
9000 ubuntu-2404-cloudinit-template  stopped     2048         3.50 0

$ pvesm list vmdata
Volid                    Format  Type            Size VMID
vmdata:base-9000-disk-0  raw     images    3758096384 9000
vmdata:vm-9000-cloudinit raw     images       4194304 9000
~~~

### Result

The Ubuntu 24.04 cloud image was successfully converted into a **reusable Proxmox CloudInit VM template**.

The successful end state is shown by these concrete post-conversion signals:

- `qm config 9000` now  
  - shows a Cloud-Init drive `vmdata` on `ide2` 
  - includes `template: 1` 
  - shows `boot: order=scsi0`
  - shows a real `scsi0` root disk - as `vmdata:base-9000-disk-0,...` (instead of `vmdata:vm-9000-disk-0,...`)
- `qm list --full` still shows a non-zero boot disk
- `pvesm list vmdata` shows the expected template-side storage objects:
  - `vmdata:base-9000-disk-0`
  - `vmdata:vm-9000-cloudinit`
 
**Reusable base template created**

![Reusable base template created](./evidence/px/09-PX-Base-VM-Template-Image-9000-created.png)

***Figure 3.*** *Proxmox inventory view showing the reusable Ubuntu 24.04 base VM template after successful creation. This proves that the imported cloud image and attached Cloud-Init drive were turned into a reusable template artifact.*

---

## Step 3 — Create the reference smoke VM (`9100`) from the template

### Rationale

Once the reusable template exists, the next step is to create the **minimal verification VM** from it - and prove that the template can be turned into a working guest with the intended first-boot settings.

This step establishes the first working VM baseline that later phases can build on for deployment and automation work.

### Action

> [!NOTE] **🧩 "Smoke VM"**  
> A **minimal validation VM** created from a reusable template used to prove that the baseline works before heavier deployment steps are added on top.  
> In this phase, `9100` is the **smoke VM** used to validate the reusable template path

The smoke VM uses:

- the reusable template `9000` as its source
- `9100` as its own VM ID
- a Cloud-Init user and password
- a virtio NIC (`net0: virtio`) without bridge attachment - to use the documented default guest VM network path for DHCP, DNS, and outbound access (unbridged QEMU user-mode NAT - reasoning see below "Guest NIC without bridge attachment") 
- a larger root disk before first boot

> [!NOTE] **🧩 NIC (Network Interface Card)**
> A **NIC** is the **network adapter** a system uses to connect to a network.
>
> In this phase, the smoke VM does **not** use a physical NIC directly.  
> Instead, Proxmox presents the guest VM with a **virtual NIC**, configured here as:
>
> - `net0: virtio`
>
> `net0` = the VM’s first network interface.  
> `virtio` = a paravirtualized virtual NIC designed for virtualization, with lower overhead and better performance than older emulated adapter types such as `e1000`.
>
> Inside the Ubuntu guest, that virtual NIC appears as `eth0`.  
> In this phase, the NIC is intentionally configured **without a bridge** (i.e. without `bridge=vmbr0`), so the guest uses for outbound connectivity QEMU user-mode NAT (a built-in VM networking mode provided by QEMU on the host side).

To proceed, we again utilize Proxmox' QEMU/KVM virtual-machine manager CLI tool `qm`: 

~~~bash
# --- (1) Clone the smoke VM from the reusable base template ---
$ qm clone 9000 9100 --name ubuntu-2404-smoke-01
create full clone of drive ide2 (vmdata:vm-9000-cloudinit)
create linked clone of drive scsi0 (vmdata:base-9000-disk-0)

# --- (2) Configure guest networking and Cloud-Init login values ---
# Use the documented guest NIC path: virtio NIC without bridge attachment
$ qm set 9100 --net0 virtio
update VM 9100: -net0 virtio

$ qm set 9100 --ciuser ubuntu
update VM 9100: -ciuser ubuntu

$ qm set 9100 --cipassword 'SECURE_TEMP_PASSWORD'
update VM 9100: -cipassword <hidden>

$ qm set 9100 --ipconfig0 ip=dhcp
update VM 9100: -ipconfig0 ip=dhcp

# --- (3) Enlarge the guest root disk before first boot ---
$ qm resize 9100 scsi0 16G

# --- (4) Verify the smoke VM object before booting ---
$ qm config 9100
boot: order=scsi0
cipassword: **********
ciuser: ubuntu
cores: 2
ide2: vmdata:vm-9100-cloudinit,media=cdrom,size=4M
ipconfig0: ip=dhcp
memory: 2048
meta: creation-qemu=9.2.0,ctime=<redacted>
name: ubuntu-2404-smoke-01
net0: virtio=<redacted-mac>
ostype: l26
scsi0: vmdata:base-9000-disk-0/vm-9100-disk-0,size=16G
scsihw: virtio-scsi-pci
serial0: socket
smbios1: uuid=<redacted>
vga: serial0
vmgenid: <redacted>

$ qm cloudinit pending 9100
cur cipassword: **********
cur ciuser: ubuntu

$ qm list --full
      VMID NAME                 STATUS   MEM(MB) BOOTDISK(GB) PID
      9000 ubuntu-2404-cloudinit-template stopped    2048          3.50 0
      9100 ubuntu-2404-smoke-01          stopped    2048         16.00 0

# --- (5) Start the smoke VM and confirm runtime state ---
$ qm start 9100
Use of uninitialized value in split at /usr/share/perl5/PVE/QemuServer/Cloudinit.pm line 115.
generating cloud-init ISO
WARN: Interface 'tap9100i0' not attached to any bridge.
Task finished with 1 warning(s)!

$ qm list --full
VMID NAME                 STATUS   MEM(MB) BOOTDISK(GB) PID
9000 ubuntu-2404-cloudinit-template stopped    2048          3.50 0
9100 ubuntu-2404-smoke-01          running    2048         16.00 <redacted-pid>
~~~

### Result

The **smoke VM (`9100`) was successfully created** from the reusable Proxmox VM template. The template can be turned into a working guest with the intended first-boot settings.

**Hypervisor-side verification points:**

The successful end state is shown by these concrete post-conversion signals:

- `qm config 9100` shows:
  - `net0: virtio=...` with **no** bridge parameter
  - `ipconfig0: ip=dhcp`
  - `ide2: ...cloudinit...`
  - `scsi0: ... size=16G`
- `qm cloudinit pending 9100` shows the configured Cloud-Init values queued for the guest
- `qm list --full` first shows the VM in `stopped` state with `BOOTDISK(GB)` at `16.00`, and then in `running` state after boot
- the warning `Interface 'tap9100i0' not attached to any bridge.` appears during start and is expected here, because the guest NIC is intentionally configured without bridge attachment to trigger default settings

> [!NOTE] **🧩 Guest NIC without host bridge attachment**
>
> In this phase, the smoke VM NIC is intentionally configured as virtio NIC (`net0: virtio`) **without** bridge attachment (no `bridge=vmbr0`) - to use the documented default unbridged QEMU user-mode NAT path for guest VMs.
>
> Details: The official Proxmox `qm` VM networking documentation states that **if no bridge is specified for a guest NIC**, Proxmox/QEMU uses the default unbridged **user-mode NAT** network path for that guest VM. In that mode, the guest receives built-in network services and a private guest-side network, typically with:
> - guest addresses in the `10.0.2.0/24` range
> - default gateway `10.0.2.2`
> - DNS server `10.0.2.3`
>
> That documented behavior matches the final successful smoke-VM verification in this phase:
> - the guest received `10.0.2.15/24`
> - the guest used `10.0.2.2` as its default route
> - outbound access worked successfully from inside the VM

**Smoke VM created**

![Smoke VM created](./evidence/px/10-PX-Smoke-Test-VM-Clone-9100-created.png)

***Figure 4.*** *Proxmox inventory view showing the reference smoke VM cloned from the base template and running. This proves that the template is reusable and that the final reference guest path was established successfully.*

---

## Step 4 — Verify the reference smoke VM from inside the guest

### Rationale

At this point the **VM exists and is running in Proxmox**, but the hypervisor-side inventory alone is still not enough.

To complete the verification, we now log into the guest VM itself and prove that the machine is not only present in Proxmox but also usable from inside the operating system.

The goal is to verify that the guest:

- accepts login
- finishes Cloud-Init initialization
- exposes the enlarged root filesystem
- provides outbound connectivity

### Action

The guest OS is accessed through the configured serial console from the host:

~~~bash
# Open the VM's serial console from the Proxmox host to log into the guest operating system
qm terminal 9100
~~~

Inside the guest, we perform the following checks:

~~~bash
# Confirm the guest login identity and Cloud-Init completion
$ whoami
ubuntu

$ hostname
ubuntu-2404-smoke-01

$ cloud-init status --wait
status: done

# Confirm the guest addressing and routing
$ ip -brief address
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             10.0.2.15/24 metric 100 fec0::be24:11ff:fe4d:da17/64 fe80::be24:11ff:fe4d:da17/64

$ ip route
default via 10.0.2.2 dev eth0 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100
10.0.2.2 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100
10.0.2.3 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100

# Confirm that the enlarged root filesystem is visible inside the guest
$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        15G  2.2G   13G  16% /

# Confirm outbound connectivity
$ ping -c 2 1.1.1.1
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=255 time=1.84 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=255 time=1.94 ms

--- 1.1.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 1.840/1.889/1.938/0.049 ms

$ curl -I --max-time 10 https://example.com
HTTP/2 200
date: Thu, 02 Apr 2026 20:10:18 GMT
content-type: text/html
server: cloudflare
last-modified: Tue, 24 Mar 2026 22:07:32 GMT
allow: GET, HEAD
accept-ranges: bytes
age: 4589
cf-cache-status: HIT
cf-ray: 9e6279e8d9136d1d-AMS
~~~

### Result

**The final successful results are:**

- `whoami` -> `ubuntu`
- `hostname` -> `ubuntu-2404-smoke-01`
- `cloud-init status --wait` -> `status: done`
- `ip -brief address` -> `eth0` with `10.0.2.15/24`
- `ip route` -> default route via `10.0.2.2`
- `df -h /` -> `/dev/sda1` visible at roughly `15G`
- `ping -c 2 1.1.1.1` -> successful outbound IP connectivity
- `curl -I --max-time 10 https://example.com` -> successful DNS resolution plus outbound HTTPS connectivity

**Guest login, Cloud-Init, and disk verification success**

![Guest login, Cloud-Init, and disk verification success](./evidence/px/11-PX-Smoke-VM-9100_guest-login-and-cloud-init-success.png)

***Figure 5.*** *Guest-side verification inside the reference smoke VM. This proves successful login, successful Cloud-Init completion, and a healthy enlarged root filesystem inside the guest.*

---

## Cleanup / rerun notes

### Stop the reference smoke VM cleanly

~~~bash
# Stop the smoke VM cleanly
qm stop 9100
qm wait 9100
~~~

### Recreate the smoke VM from the template

If the smoke VM needs to be recreated, the final proven path is:

~~~bash
# Remove the existing smoke VM first if it already exists
qm stop 9100
qm wait 9100
qm destroy 9100

# Recreate the smoke VM from the reusable template
qm clone 9000 9100 --name ubuntu-2404-smoke-01
qm set 9100 --net0 virtio
qm set 9100 --ciuser ubuntu
qm set 9100 --cipassword 'CHANGE_TO_A_FRESH_TEMP_PASSWORD'
qm set 9100 --ipconfig0 ip=dhcp
qm resize 9100 scsi0 16G
qm start 9100
~~~

---

## Baseline observations and evidence (Phase 04)

### What was established

- A reusable Ubuntu 24.04 Proxmox template exists as `9000`
- A reference smoke VM exists as `9100`
- The reference smoke VM uses the final proven no-bridge guest NIC path
- The smoke VM boots successfully
- Guest login works
- Cloud-Init finishes successfully
- The guest root filesystem reflects the enlarged hypervisor-side disk
- Outbound connectivity works from inside the guest

### Evidence index

- `evidence/px/03-PX-Node_Summary-dash.png`
- `evidence/px/06-PX-Datacenter_Storage.png`
- `evidence/px/09-PX-Base-VM-Template-Image-9000-created.png`
- `evidence/px/10-PX-Smoke-Test-VM-Clone-9100-created.png`
- `evidence/px/11-PX-Smoke-VM-9100_guest-login-and-cloud-init-success.png`

More evidence can be found in the `evidence` folder of this phase.

### What this phase proves

This phase proves the first stable **Proxmox-backed VM baseline** for the target environment.

The phase proves:

- template creation on the provided Proxmox host
- clone-based guest creation from that template
- successful Cloud-Init guest bootstrap
- successful guest login
- successful guest-side root filesystem verification
- successful guest outbound connectivity

---

## Sources

- Proxmox Cloud-Init support:
  - https://pve.proxmox.com/wiki/Cloud-Init_Support

- Proxmox `qm(1)` command reference:
  - https://pve.proxmox.com/pve-docs/qm.1.html

- Proxmox `qm.conf(5)` configuration reference:
  - https://pve.proxmox.com/pve-docs/qm.conf.5.html

- Proxmox VE Storage / `pvesm`:
  - https://pve.proxmox.com/pve-docs/chapter-pvesm.html

- Proxmox Resize disks reference:
  - https://pve.proxmox.com/wiki/Resize_disks

- Ubuntu 24.04 LTS released cloud image index:
  - https://cloud-images.ubuntu.com/releases/noble/release/