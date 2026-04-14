# 🛠️ Setup Guide — Phase 05 (Proxmox Target Delivery): Cloudflare domain onboarding, DNS delegation, and Tunnel connector setup

> ## 👤 About
> This document is the **setup guide** for **Phase 05 (Proxmox Target Delivery)**.  
> It covers the **Cloudflare-side infrastructure setup** needed before the public `dev` and `prod` application URLs can work through a Cloudflare Tunnel.  
> It is intentionally focused on setup-only topics: Cloudflare account creation, domain onboarding, DNS review, nameserver delegation at the registrar, tunnel creation in the Zero Trust dashboard, VM-side `cloudflared` connector installation, and published hostname routing.
>
> For the detailed Phase-05 implementation flow and public verification steps, see: **[IMPLEMENTATION.md](IMPLEMENTATION.md)**.  
> For the short rerun flow, see: **[RUNBOOK.md](RUNBOOK.md)**.  
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**.

---

## 📌 Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done**](#definition-of-done)
- [**Preconditions**](#preconditions)
- [**Step 01 - Create a Cloudflare account and enter the dashboard**](#step-01---create-a-cloudflare-account-and-enter-the-dashboard)
- [**Step 02 - Onboard the existing domain into Cloudflare**](#step-02---onboard-the-existing-domain-into-cloudflare)
- [**Step 03 - Review the imported DNS records carefully before delegation**](#step-03---review-the-imported-dns-records-carefully-before-delegation)
- [**Step 04 - Delegate the domain to Cloudflare nameservers at the registrar**](#step-04---delegate-the-domain-to-cloudflare-nameservers-at-the-registrar)
- [**Step 05 - Wait until the Cloudflare zone becomes active**](#step-05---wait-until-the-cloudflare-zone-becomes-active)
- [**Step 06 - Decide the public hostname shape for the free-tier tunnel setup**](#step-06---decide-the-public-hostname-shape-for-the-free-tier-tunnel-setup)
- [**Step 07 - Create a remotely managed Cloudflare Tunnel in Zero Trust**](#step-07---create-a-remotely-managed-cloudflare-tunnel-in-zero-trust)
- [**Step 08 - Install the `cloudflared` connector on the target VM**](#step-08---install-the-cloudflared-connector-on-the-target-vm)
- [**Step 09 - Add the published application routes for `dev` and `prod`**](#step-09---add-the-published-application-routes-for-dev-and-prod)
- [**Step 10 - Confirm the tunnel and routing health in the dashboard**](#step-10---confirm-the-tunnel-and-routing-health-in-the-dashboard)
- [**Sources**](#sources)

---

## Purpose / Goal

- Prepare a **Cloudflare-managed public edge** for the Phase-05 target VM without exposing inbound ports directly to the VM.
- Bring the existing domain **`cdco.dev`** under Cloudflare DNS control so Cloudflare can publish the required public hostnames.
- Create one **remotely managed Cloudflare Tunnel** for the target VM.
- Publish two public application hostnames:
  - `dev-sockshop.cdco.dev`
  - `prod-sockshop.cdco.dev`
- Route both hostnames to the existing Traefik entrypoint on the target VM:
  - `10.10.10.20:80`

---

## Definition of done

The setup is considered done when the following conditions are met:

- a working Cloudflare account exists
- the domain `cdco.dev` has been onboarded into Cloudflare
- the registrar now points the domain to the Cloudflare nameservers
- the Cloudflare zone for `cdco.dev` is active
- a remotely managed Cloudflare Tunnel exists for the target VM
- the VM-side `cloudflared` connector is installed and runs as a service
- the Zero Trust dashboard shows the tunnel connector as healthy
- the following published application routes exist:
  - `dev-sockshop.cdco.dev` -> `http://10.10.10.20:80`
  - `prod-sockshop.cdco.dev` -> `http://10.10.10.20:80`

---

## Preconditions

- an existing registered domain is available:
  - `cdco.dev`
- the domain registrar allows manual nameserver changes
- access to the domain registrar dashboard is available
- the target VM is already running and reachable
- the target VM already has a working Traefik ingress entrypoint on:
  - `10.10.10.20:80`
- the Phase-05 local ingress checks for `dev` and `prod` already work before public exposure

---

## Step 01 - Create a Cloudflare account and enter the dashboard

### Rationale

Before the domain can be onboarded or a tunnel can be created, a working Cloudflare account must exist and the relevant dashboard areas must be reachable.

### Procedure

1. Open `cloudflare.com`.
2. Create a Cloudflare account if none exists yet.
3. Sign in to the Cloudflare dashboard.
4. If prompted for plan selection during onboarding, stay on the **Free** tier unless a paid feature is intentionally needed.

### Result

This step is successful if:

- a working Cloudflare account exists
- the main Cloudflare dashboard is reachable
- the account can access both:
  - the domain-management area
  - the Zero Trust dashboard

---

## Step 02 - Onboard the existing domain into Cloudflare

### Rationale

The target domain (here `cdco.dev`) must first be added to Cloudflare before DNS can be delegated and before Cloudflare can publish tunnel-based public hostnames under that domain.

### Procedure

In the Cloudflare dashboard:

1. Go to **Domains**.
2. Select **Onboard a domain**.
3. Enter the apex domain:
   - `cdco.dev`
4. Leave **DNS import enabled** so Cloudflare can scan for existing DNS records.
5. Continue through the onboarding flow.

### Result

This step is successful if:

- `cdco.dev` appears as a Cloudflare-managed zone candidate
- Cloudflare imported or discovered the existing DNS records for review

---

## Step 03 - Review the imported DNS records carefully before delegation

### Rationale

Cloudflare scans existing DNS records during onboarding, **but those imported results should not be accepted blindly**. The imported record set may include entries that still matter, entries that are outdated, or entries that require later cleanup.

This review matters especially here because the domain already had an existing portfolio/app setup and previous DNS state.

### Procedure

Inspect the imported records in the Cloudflare DNS view and verify, at minimum:

- whether the existing (here Vercel-related) records are present and still needed
- whether any old or duplicate records can be removed later
- the **Proxy Status (Cloud Icon Color)**: This determines if traffic is routed through Cloudflare's security filters or sent directly to the destination.
- whether the imported record set is at least sufficient to keep the current domain functional after nameserver delegation

Do **not** rush this screen. A short review here can prevent unnecessary downtime later.

**Decision Guide for Portfolio Persistence:**

In our case the domain cdco.dev (registered via GoDaddy) is home to a dev portfolio page deplyoed on Vercel. At the same time, the two subdomains `dev|prod-sockshop.cdco.dev` shall serve the sockshop frontend environments. Both the portfolio page under `cdco.dev` and the subdomains for sockshop shall work side by side - without any downtime for the reachability of the profolio page during the process:     

- **Existing Portfolio (Vercel)**: Keep the A record (e.g., 76.76.21.21) and CNAME (www).
    - **Action:** Set these to **Gray Cloud (DNS Only)** initially. This ensures that Vercel’s own SSL certificates don't conflict with Cloudflare during the nameserver migration.

- **Obsolete Records:** Look for records pointing to "parked" GoDaddy pages or old mail servers you no longer use.
    - Action: **Delete** these to keep the zone clean and prevent "ghost" routing.

Do not rush this screen. A short review here can prevent unnecessary downtime later.

### Result

This step is successful if:

- the imported DNS records have been reviewed consciously
- obviously required existing records are preserved - in our case: Vercel A/CNAME records are preserved and set to Gray Cloud to maintain the portfolio site.
- obviously stale or irrelevant records (f.i. obsolete registrar-default records) are removed or at least identified for later cleanup  

---

## Step 04 - Delegate the domain to Cloudflare nameservers at the registrar

### Rationale

Cloudflare cannot serve as the public DNS control plane for the domain until the registrar points the domain at the Cloudflare nameservers.

### Procedure

In the Cloudflare onboarding flow:

1. Copy the two Cloudflare nameservers shown for `cdco.dev`.

Then in the registrar dashboard (for example GoDaddy):

2. Open the nameserver management page for `cdco.dev`.
3. Replace the current nameserver configuration with the two Cloudflare nameservers.
4. Save the change.

### Result

This step is successful if:

- the registrar now shows the two Cloudflare nameservers for `cdco.dev`
- the old nameserver configuration is no longer active at the registrar

---

## Step 05 - Wait until the Cloudflare zone becomes active

### Rationale

The domain will not be fully usable in Cloudflare until nameserver delegation has propagated and the zone changes from pending state to active state.

### Procedure

Return to the Cloudflare dashboard and monitor the zone status for `cdco.dev` until it becomes active.

### Result

This step is successful if:

- the `cdco.dev` zone shows as **Active** in Cloudflare

---

## Step 06 - Decide the public hostname shape for the free-tier tunnel setup

### Rationale

The hostname shape should be decided before the tunnel routes and Kubernetes Ingress hosts are aligned. This matters because Cloudflare’s default Universal SSL coverage works for the apex domain and one level of subdomain, but not for deeper multi-level subdomains in the default setup.

That is why the following hostnames are used here:

- `dev-sockshop.cdco.dev`
- `prod-sockshop.cdco.dev`

and **not** deeper nested variants such as:

- `dev.sockshop.cdco.dev`
- `prod.sockshop.cdco.dev`

### Decision

Use these public hostnames:

- `dev-sockshop.cdco.dev`
- `prod-sockshop.cdco.dev`

### Result

This step is successful if:

- the public hostname strategy is fixed
- the chosen hostnames are compatible with the intended free-tier-friendly setup

---

## Step 07 - Create a remotely managed Cloudflare Tunnel in Zero Trust

### Rationale

The tunnel itself is created in the Cloudflare Zero Trust dashboard. This setup guide uses the **remotely managed** tunnel flow, so routing is handled centrally in the dashboard and no local `cloudflared` config file is required.

### Procedure

In the Cloudflare Zero Trust dashboard:

1. Go to **Networks -> Connectors"**.
2. In the **Cloudflare Tunnels** section, select **Add a tunnel**.
3. Choose **Cloudflared** as the tunnel type.
4. Enter a **tunnel name**, for example:
   - `sockshop-proxmox-9200`
5. Save the tunnel.
6. Under the connector installation area (**"Install and run the connectors"**), specify the target VM's platform:
   - Debian / 64-bit
7. **Copy the generated connector command** for later execution on the target VM.

### Result

This step is successful if:

- a new remotely managed Cloudflare Tunnel exists in the dashboard
- the generated VM-side connector command is available

---

## Step 08 - Install the `cloudflared` connector on the target VM

### Rationale

The tunnel will not become usable until the VM-side connector is installed and connected back to Cloudflare.

### Commands

Run the generated connector command on the **target VM**.

~~~bash
# Paste and run the generated Cloudflare connector command from the dashboard.
<PASTE_CLOUDFLARED_CONNECTOR_COMMAND>

# Install the Cloudflare Tunnel as a persistent system service.
# This hands control of the tunnel over to systemd. It ensures the tunnel 
# runs silently in the background, survives VM reboots, and automatically 
# restarts if it crashes, keeping the public URLs permanently online.
# Once done, there's no nee to run the tunnel manually via `cloudfare trunnel run ...
$ sudo cloudflared service install <YOUR_TOKEN_HERE>
2026-04-10T18:40:08Z INF Using Systemd
2026-04-10T18:40:13Z INF Linux service for cloudflared installed successfully

# Show the Cloudflare connector service state on the VM.
$ sudo systemctl status cloudflared --no-pager
● cloudflared.service - cloudflared
     Loaded: loaded (/etc/systemd/system/cloudflared.service; enabled; preset: enabled)
     Active: active (running) ...
   Main PID: ... (cloudflared)
      Tasks: ...
     Memory: 14.9M (peak: 18.8M)
        CPU: 1.955s
     CGroup: /system.slice/cloudflared.service

# Show the installed cloudflared version.
$ cloudflared --version
cloudflared version 2026.3.0 (built 2026-03-09-14:08 UTC)
~~~

### Result

This step is successful if:

- the connector command completes without error
- `cloudflared` is installed on the VM
- the `cloudflared` system service is active

---

## Step 09 - Add the published application routes for `dev` and `prod`

### Rationale

The tunnel connector alone is not enough. The Cloudflare dashboard must also know which public hostnames should be routed to which internal service on the target VM.

### Procedure

In the Cloudflare Tunnel wizard or the later tunnel edit screen:

1. Go to the **Published application routes** tab.
2. Add the **dev** route:

   - Subdomain: `dev-sockshop`
   - Domain: `cdco.dev`
   - Path: leave blank
   - Service type: `HTTP`
   - URL: `10.10.10.20:80`

3. Add the **prod** route:

   - Subdomain: `prod-sockshop`
   - Domain: `cdco.dev`
   - Path: leave blank
   - Service type: `HTTP`
   - URL: `10.10.10.20:80`

4. Save both routes.

### Result

This step is successful if:

- both published routes are present
- both public hostnames point at `10.10.10.20:80`

---

## Step 10 - Confirm the tunnel and routing health in the dashboard

### Rationale

Before the application-side public verification begins, the tunnel connector and the published routes should already look healthy in the Cloudflare dashboard.

### Procedure

Confirm in the dashboard that:

- the tunnel connector status is healthy / connected
- both published hostnames are present
- both published hostnames point to the intended internal origin service

### Result

This step is successful if:

- the tunnel status is healthy
- the published route list contains both:
  - `dev-sockshop.cdco.dev`
  - `prod-sockshop.cdco.dev`

---

## Sources

- Cloudflare domain onboarding:
  - https://developers.cloudflare.com/fundamentals/manage-domains/add-site/

- Cloudflare full nameserver setup:
  - https://developers.cloudflare.com/dns/zone-setups/full-setup/setup/

- Cloudflare remote tunnel creation:
  - https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/

- Cloudflare tunnel routing / published application routes:
  - https://developers.cloudflare.com/tunnel/routing/
  - https://developers.cloudflare.com/cloudflare-one/networks/routes/add-routes/

- Cloudflare Universal SSL multi-level subdomain limitation:
  - https://developers.cloudflare.com/ssl/troubleshooting/version-cipher-mismatch/