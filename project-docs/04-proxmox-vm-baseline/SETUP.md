# 🛠️ Setup Guide — Phase 04 (Proxmox VM Baseline): local SSH access to the Proxmox host

> ## 👤 About
> This document is the **setup guide** for **Phase 04 (Proxmox VM Baseline)**.  
> It covers the **local workstation preparation** and the **SSH access setup** needed to reach the provided Proxmox host from the laptop.  
> It is intentionally focused on setup-only topics: local SSH tooling, SSH key choice, host-side `authorized_keys` preparation, optional local SSH config, and connectivity verification.  
>
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

---

## Purpose / Goal

- Prepare the local workstation so it can reach the provided **Proxmox host** reliably over SSH.
- Keep the Proxmox access path **separate and easy to understand** by using a dedicated SSH key for this project.
- Store the required trust material on the Proxmox host so future logins can use **key-based authentication**.
- Add an optional local SSH config entry so repeated host access and `qm` work stay simple.
- Prove that the local workstation can log in to the Proxmox host and launch later host-side Proxmox commands from a normal terminal session.

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

---

## Preconditions

- Local Workstation/Laptop (OS Ubuntu / Linux)
- terminal access on the laptop
- working access to the Proxmox web UI
- temporary access to the Proxmox host shell through the web UI
- the Proxmox host address or IP is known

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

## Sources

- [OpenSSH `ssh` manual page](https://man.openbsd.org/ssh)  
  Official reference for SSH client usage, login syntax, first connection behavior, and `-i`.

- [OpenSSH `ssh-keygen` manual page](https://man.openbsd.org/ssh-keygen)  
  Official reference for SSH key generation and `ed25519` key creation options.

- [OpenSSH `ssh_config` manual page](https://man.openbsd.org/ssh_config)  
  Official reference for per-host SSH config options such as `Host`, `HostName`, `User`, `IdentityFile`, and `IdentitiesOnly`.

- [Proxmox `qm(1)` command reference](https://pve.proxmox.com/pve-docs/qm.1.html)  
  Official reference for Proxmox host-side VM commands such as `qm terminal`.



   


