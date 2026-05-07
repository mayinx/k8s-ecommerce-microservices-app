# Runbook — Phase 10: Proxmox Exit Evidence and Migration Readiness

> ## About
> This runbook provides the short rerun path for the Phase 10 evidence and migration-readiness pass.
>
> For the detailed implementation log, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.  
> For the phase-local decisions, see: **[DECISIONS.md](./DECISIONS.md)**.  
> For top-level project navigation, see: **[INDEX.md](../INDEX.md)**.

---

## Goal

Capture the final Proxmox-backed platform state before migration and decommissioning.

---

## Steps

### 1. Create Phase 10 folders

~~~bash
mkdir -p project-docs/10-proxmox-exit-evidence/evidence
mkdir -p project-docs/10-proxmox-exit-evidence/archive
~~~

### 2. Archive the current Proxmox-era README

~~~bash
cp README.md project-docs/10-proxmox-exit-evidence/archive/[2026-05-06]-README-proxmox-phases-00-09.md
~~~

The final presentation PDF is kept separately under:

~~~text
project-docs/final-presentation/[2026-05-05]-Sock-Shop-Production-Grade-DevOps-Delivery-Path.pdf
~~~

### 3. Capture public environment evidence

Capture browser screenshots of:

- `https://dev-sockshop.cdco.dev/`
- `https://prod-sockshop.cdco.dev/`

Capture terminal endpoint verification:

~~~bash
curl -I -sS https://dev-sockshop.cdco.dev \
  | grep -Ei '^(HTTP/|date:|content-type:|server:|cf-cache-status:|x-powered-by:)'

curl -I -sS https://prod-sockshop.cdco.dev \
  | grep -Ei '^(HTTP/|date:|content-type:|server:|cf-cache-status:|x-powered-by:)'
~~~

### 4. Capture target platform state

Run the existing read-only target snapshot:

~~~bash
make k8s-demo-defense-snapshot
~~~

Capture Proxmox UI screenshots for VM `9200`:

- VM `9200` summary view
- VM `9200` hardware view
- Optional: Proxmox VM inventory showing templates and target VM

### 5. Capture observability state

Capture screenshots of:

- Grafana dashboard for `sock-shop-prod`
- Prometheus `/targets` page

### 6. Capture CI/CD state

Capture latest successful GitHub Actions evidence for:

- Deterministic PR gate
- Target delivery workflow, including approval gate
- Target delivery workflow after approved production deployment
- Live smoke workflow

### 7. Create final local DR backups

~~~bash
make p09-dr-backup-dev
make p09-dr-backup-prod
~~~

Verify generated local artifacts:

~~~bash
tree -L 3 backups | tail -n 80
~~~

Do not commit raw backup artifacts.

---

## Result

Phase 10 is complete when the final Proxmox public entrypoints, platform state, observability layer, CI/CD validation, DR backup readiness, and historical README snapshot are preserved.