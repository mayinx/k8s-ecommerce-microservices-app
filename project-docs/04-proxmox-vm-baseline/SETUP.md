# 🛠️ Setup Guide — Phase 04 (Proxmox VM Baseline): local SSH access to the Proxmox host and later target VM `9200`

> ## 👤 About
> This document is the **setup guide** for **Phase 04 (Proxmox VM Baseline)**.  
> It covers the **local workstation preparation** and the **SSH access setup** needed to reach the provided Proxmox host and, later, the Ubuntu target VMs `9200` created from that baseline from the local workstation.  
> It is intentionally focused on setup-only topics: local SSH tooling, SSH key choice, host-side `authorized_keys` preparation, VM-side `authorized_keys` preparation, optional local SSH config, and connectivity verification.

> For the detailed build diary and broader phase context, see: **[IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For the short rerun flow, see: **[RUNBOOK.md](RUNBOOK.md)**.  
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**.

---

## 📌 Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done**](#definition-of-done)
- [**Preconditions**](#preconditions)
- [**Step 01 - Check local SSH client and existing SSH keys**](#step-01---check-local-ssh-client-and-existing-ssh-keys)
- [**Step 02 - Decide whether to reuse an existing key or create a dedicated Proxmox key**](#step-02---decide-whether-to-reuse-an-existing-key-or-create-a-dedicated-proxmox-key)
- [**Step 03 - Generate a dedicated SSH key for the Proxmox host**](#step-03---generate-a-dedicated-ssh-key-for-the-proxmox-host)
- [**Step 04 - Add the public key to the Proxmox host**](#step-04---add-the-public-key-to-the-proxmox-host)
- [**Step 05 - Optional: add a local SSH config entry**](#step-05---optional-add-a-local-ssh-config-entry)
- [**Step 06 - Verify SSH access from the laptop to the Proxmox host**](#step-06---verify-ssh-access-from-the-laptop-to-the-proxmox-host)
- [**Step 07 - Verify that Proxmox host-shell work can now be launched from the laptop**](#step-07---verify-that-proxmox-host-shell-work-can-now-be-launched-from-the-laptop)
- [**Sources**](#sources)
- [**Step 08 - Implement VM-level SSH access**](#step-08---implement-vm-level-ssh-access)
- [**Step 09 - Add the public key to the Ubuntu target VM**](#step-09---add-the-public-key-to-the-ubuntu-target-vm)
- [**Step 10 - Optional: add a local SSH config entry for the Ubuntu target VM**](#step-10---optional-add-a-local-ssh-config-entry-for-the-ubuntu-target-vm)
- [**Step 11 - Verify SSH and `scp` access to the Ubuntu target VM**](#step-11---verify-ssh-and-scp-access-to-the-ubuntu-target-vm)

---

## Purpose / Goal

- Prepare the local workstation so it can reach the provided **Proxmox host** reliably over SSH, using a dedicated SSH key for this project.
- Store the required trust material on the Proxmox host so future logins can use **key-based authentication**.
- Add an optional local SSH config entry so repeated host access and `qm` work stay simple.
- Prove that the local workstation can log in to the Proxmox host and launch later host-side Proxmox commands from a normal terminal session.
- Prepare the local workstation so it can later reach Ubuntu target VMs created from the Proxmox baseline over SSH as well.
- Reuse the same dedicated project SSH key for both the Proxmox host and the later Ubuntu target VM access path.
- Prove that later file-transfer steps such as `scp` can be performed directly against the Ubuntu target VM.

---

## Definition of done

The setup is considered done when the following conditions are met:

- the laptop has a working SSH client
- a dedicated SSH key pair for the Proxmox host exists locally:
  - `~/.ssh/id_ed25519_proxmox_capstone`
  - `~/.ssh/id_ed25519_proxmox_capstone.pub`
- the public key is present in `/root/.ssh/authorized_keys` on the Proxmox host
- optional local SSH config alias `proxmox-capstone` exists and has safe file permissions
- the laptop can log in to the Proxmox host via:
  - `ssh proxmox-capstone`
  - or the equivalent direct `ssh -i ... root@<HOST>`
- after login, normal Proxmox host-shell commands such as `pwd` or `qm terminal <vmid>` can be launched from the laptop session successfully
- the same public key is present in `/home/ubuntu/.ssh/authorized_keys` on the Ubuntu target VM
- optional local SSH config alias for the Ubuntu target VM exists and has safe file permissions
- the laptop can log in to the Ubuntu target VM via SSH
- a simple `scp` transfer to or from the Ubuntu target VM works

---

## Preconditions

- Local Workstation/Laptop (OS Ubuntu / Linux)
- terminal access on the laptop
- working access to the Proxmox web UI
- temporary access to the Proxmox host shell through the web UI
- the Proxmox host address or IP is known
- temporary shell access to the Ubuntu target VM once it exists (for example via `qm terminal <vmid>`)

---

## Step 01 - Check local SSH client and existing SSH keys

### Rationale

Before creating new SSH material, first confirm that:

- the laptop already has an SSH client
- the local `~/.ssh` directory exists
- existing keys can be reviewed

This avoids unnecessary key sprawl and makes the later decision cleaner.

### Commands

~~~bash
# Confirm that the local SSH client is installed and returns a version string.
ssh -V

# Show the contents of the local SSH directory.
# This gives a quick overview of existing keys, config files, and known_hosts files.
ls -la ~/.ssh

# List existing public keys only.
# Public keys are safe to inspect; private keys are not.
find ~/.ssh -maxdepth 1 -type f -name "*.pub" -print
~~~

### Result

This step is successful if:

- `ssh -V` prints a version string
- `~/.ssh` exists
- existing public keys can be listed

---

## Step 02 - Decide whether to reuse an existing key or create a dedicated Proxmox key

### Rationale

A personal key could be reused, but for this project a dedicated SSH key keeps the access path clearer and avoids confusion with unrelated GitHub, GitLab, or cloud-hosting keys.

### Recommendation

Use a **dedicated key** for this Proxmox host:

`~/.ssh/id_ed25519_proxmox_capstone`

That keeps the access path:

- separate
- easy to document
- easy to rotate or remove later

> [!NOTE] **🧩 Why `ed25519`**
>
> `ed25519` is a modern SSH key type with a strong security profile and small key size.  
> It is a very good default choice for a dedicated SSH key.

---

## Step 03 - Generate a dedicated SSH key for the Proxmox host

### Rationale

This creates a clean, project-specific SSH identity for the laptop-to-Proxmox access path.

### Commands

~~~bash
# Generate a dedicated SSH key pair for Proxmox access.
# -t ed25519 = key type
# -a 100     = stronger KDF hardening for the private key
# -f         = output file path
# -C         = key comment for later recognition
$ ssh-keygen -t ed25519 -a 100 \
  -f ~/.ssh/id_ed25519_proxmox_capstone \
  -C "proxmox-capstone"

# Show the public key so it can be copied to the Proxmox host.
# Only the .pub file is safe to display.
$ cat ~/.ssh/id_ed25519_proxmox_capstone.pub
~~~

### Result

This step is successful if:

- `~/.ssh/id_ed25519_proxmox_capstone` exists
- `~/.ssh/id_ed25519_proxmox_capstone.pub` exists
- the public key prints as a single `ssh-ed25519 ... proxmox-capstone` line

---

## Step 04 - Add the public key to the Proxmox host

### Rationale

The Proxmox host must know the laptop's public key so future logins can authenticate with the private key stored on the laptop.

Because the Proxmox web UI shell is already available, the simplest and most robust path here is:

- show the public key on the laptop
- copy it
- append it to `/root/.ssh/authorized_keys` on the Proxmox host

### Commands

First on the **laptop**:

~~~bash
# Show the public key again to copy it 
cat ~/.ssh/id_ed25519_proxmox_capstone.pub
~~~

Then on the **Proxmox host** via the web UI shell:

~~~bash
# Create the root SSH directory if it does not exist yet.
mkdir -p /root/.ssh

# Set safe permissions on the directory.
chmod 700 /root/.ssh

# Append the copied public key to authorized_keys.
# Replace the placeholder with the copied public key 
echo 'COPIED_PUBKEY' >> /root/.ssh/authorized_keys

# Set safe permissions on the authorized_keys file
chmod 600 /root/.ssh/authorized_keys

# Confirm that the expected key comment is now present in authorized_keys.
# grep -n = show matching line number and line content
grep -n 'proxmox-capstone' /root/.ssh/authorized_keys
~~~

### Result

This step is successful if:

- `/root/.ssh/authorized_keys` exists
- a matching `proxmox-capstone` entry is present in `/root/.ssh/authorized_keys`
- directory/file permissions were applied without error

---

## Step 05 - Optional: add a local SSH config entry

### Rationale

A local SSH config entry avoids repeating:

- host/IP
- remote user
- identity file

That is especially useful for repeated Proxmox host access and later `qm` work.

### Commands

~~~bash
# Open or create the local SSH config file.
# nano is fine as well; use the editor you normally prefer.
vim ~/.ssh/config
~~~

Add this block:

~~~sshconfig
Host proxmox-capstone
    HostName <PROXMOX_HOST_OR_IP>
    User root
    IdentityFile ~/.ssh/id_ed25519_proxmox_capstone
    IdentitiesOnly yes
~~~

Then apply safe permissions:

~~~bash
# Restrict access to the local SSH config file.
chmod 600 ~/.ssh/config
~~~

### Result

This step is successful if:

- `~/.ssh/config` contains the new `Host proxmox-capstone` block
- `chmod 600 ~/.ssh/config` completes without error

---

## Step 06 - Verify SSH access from the laptop to the Proxmox host

### Rationale

Now test the actual laptop-to-Proxmox login path.

### Commands

If the SSH config alias was created:

~~~bash
# Connect through the local SSH host alias.
ssh proxmox-capstone
~~~

If the alias was not created:

~~~bash
# Connect directly with host/IP, remote user, and explicit key file.
ssh -i ~/.ssh/id_ed25519_proxmox_capstone root@<PROXMOX_HOST_OR_IP>
~~~

> [!NOTE] **🧩 First host-key prompt**
>
> On the first connection, SSH usually asks whether the remote host key should be trusted and added to `known_hosts`.  
> That is normal for a first successful connection to a previously unknown host.

### Result

This step is successful if:

- the laptop can log in to the Proxmox host
- a root shell prompt appears on the Proxmox host
- no password is needed after key-based access is working correctly

---

## Step 07 - Verify that Proxmox host-shell work can now be launched from the laptop

### Rationale

The last check proves that the new SSH access is not only a login convenience, but also a usable entrypoint for the actual Phase-04 host-side work.

### Commands

~~~bash
# Confirm the current working directory on the Proxmox host.
pwd

# Launch a later host-side Proxmox command from the SSH session.
# This proves that qm-based host work can now start directly from the laptop terminal.
qm terminal 9010
~~~

### Result

This step is successful if:

- `pwd` runs normally on the Proxmox host
- `qm terminal 9010` can be launched from the SSH session
- the laptop terminal now serves as a practical entrypoint for later Proxmox host-shell work

---

## Step 08 - Implement VM-level SSH access

### Rationale

Phase 04 first established SSH access to the Proxmox host itself. That host-level access is enough for `qm`, storage, and hypervisor-side work, but it is not enough for later file-copy or direct shell access against Ubuntu target VMs.

Once target VMs such as `9200` are introduced, a second SSH trust path is therefore needed as well: the workstation's public key must also be authorized for the Ubuntu VM user itself. Otherwise, later commands such as `ssh ubuntu@<VM>` or `scp ubuntu@<VM>:... ...` will fail even though Proxmox-host SSH already works.

### Result

This setup extension is complete once the workstation can authenticate not only to the Proxmox host, but also to the Ubuntu target VM directly with the same dedicated project key.

---

## Step 09 - Add the public key to the Ubuntu target VM

### Rationale

The Ubuntu target VM must know the workstation's public key so later logins and file-copy commands can authenticate with the existing dedicated project key.

This mirrors the earlier Proxmox-host SSH setup, but the trust material now needs to be placed in the Ubuntu user's own `authorized_keys` file inside the target VM.

### Commands

First on the **laptop**:

~~~bash
# Show the public key again so it can be copied to the Ubuntu target VM.
cat ~/.ssh/id_ed25519_proxmox_capstone.pub
~~~

Then inside the **Ubuntu target VM** shell (for example through `qm terminal <vmid>`):

~~~bash
# Create the Ubuntu user's SSH directory if it does not exist yet.
mkdir -p ~/.ssh

# Set safe permissions on the directory.
chmod 700 ~/.ssh

# Append the copied workstation public key to authorized_keys.
# Replace the placeholder with the copied public key.
echo 'COPIED_PUBKEY' >> ~/.ssh/authorized_keys

# Set safe permissions on the authorized_keys file.
chmod 600 ~/.ssh/authorized_keys
~~~

### Result

This step is successful if:

- `~/.ssh/authorized_keys` exists in the Ubuntu target VM user account
- a matching `proxmox-capstone` entry is present
- directory/file permissions were applied without error

---

## Step 10 - Optional: add a local SSH config entry for the Ubuntu target VM

### Rationale

A second SSH config alias is helpful once direct workstation-to-VM access becomes part of the workflow. It avoids repeating the VM address, remote user, and identity file for every later SSH or `scp` command.

### Commands

Open the local SSH config again:

~~~bash
nano ~/.ssh/config
~~~

Add a second block like this:

~~~sshconfig
Host proxmox-k3s-target-01
    HostName <VM_IP_OR_TAILSCALE_IP>
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519_proxmox_capstone
    IdentitiesOnly yes
~~~

Then apply safe permissions again if needed:

~~~bash
chmod 600 ~/.ssh/config
~~~

### Result

This step is successful if:

- `~/.ssh/config` contains the new `Host proxmox-k3s-target-01` block
- the block points to the Ubuntu target VM and the same project SSH key
- `chmod 600 ~/.ssh/config` completes without error

---

## Step 11 - Verify SSH and `scp` access to the Ubuntu target VM

### Rationale

The final check proves that the workstation can now reach the Ubuntu target VM directly, not only the Proxmox host. That direct VM access is needed later for secure copy operations such as retrieving kubeconfig material.

### Commands

If the SSH config alias was created:

~~~bash
# Confirm direct SSH login to the Ubuntu target VM.
ssh proxmox-k3s-target-01 "pwd"

# Create a small harmless proof file on the target VM.
ssh proxmox-k3s-target-01 "printf 'vm-ssh-proof\n' > /tmp/vm-ssh-proof.txt"

# Copy that file back to the workstation via scp.
scp proxmox-k3s-target-01:/tmp/vm-ssh-proof.txt /tmp/vm-ssh-proof.txt

# Confirm the copied content locally.
cat /tmp/vm-ssh-proof.txt
~~~

If the alias was not created, the same flow can be executed with the explicit key and VM address:

~~~bash
ssh -i ~/.ssh/id_ed25519_proxmox_capstone ubuntu@<VM_IP_OR_TAILSCALE_IP> "pwd"
ssh -i ~/.ssh/id_ed25519_proxmox_capstone ubuntu@<VM_IP_OR_TAILSCALE_IP> "printf 'vm-ssh-proof\n' > /tmp/vm-ssh-proof.txt"
scp -i ~/.ssh/id_ed25519_proxmox_capstone ubuntu@<VM_IP_OR_TAILSCALE_IP>:/tmp/vm-ssh-proof.txt /tmp/vm-ssh-proof.txt
cat /tmp/vm-ssh-proof.txt
~~~

### Result

This step is successful if:

- the workstation can log in to the Ubuntu target VM directly
- a simple remote file can be created on the VM
- `scp` can copy that file back to the workstation successfully
- the copied file content can be read locally

---

## Sources

- [OpenSSH `ssh` manual page](https://man.openbsd.org/ssh)  
  Official reference for SSH client usage, login syntax, first connection behavior, and `-i`.

- [OpenSSH `ssh-keygen` manual page](https://man.openbsd.org/ssh-keygen)  
  Official reference for SSH key generation and `ed25519` key creation options.

- [OpenSSH `ssh_config` manual page](https://man.openbsd.org/ssh_config)  
  Official reference for per-host SSH config options such as `Host`, `HostName`, `User`, `IdentityFile`, and `IdentitiesOnly`.

- [Proxmox `qm(1)` command reference](https://pve.proxmox.com/pve-docs/qm.1.html)  
  Official reference for Proxmox host-side VM commands such as `qm terminal`.

- [OpenSSH `scp` manual page](https://man.openbsd.org/scp)  
  Official reference for secure copy usage and `-i` with explicit SSH identity files.

   


