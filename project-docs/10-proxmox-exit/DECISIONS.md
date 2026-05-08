# Decision Log — Phase 10: Proxmox Exit Evidence and Migration Readiness

> ## About
> This document records the phase-local decisions for **Phase 10 (Proxmox Exit Evidence and Migration Readiness)**.
>
> For the Phase 10 implementation log, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.  
> For the Phase 10 rerun guide, see: **[RUNBOOK.md](./RUNBOOK.md)**.  
> For top-level project navigation, see: **[INDEX.md](../INDEX.md)**.  
> For the archived Proxmox-era README snapshot, see: **[archive/[2026-05-06]-README-proxmox-phases-00-09.md](./archive/%5B2026-05-06%5D-README-proxmox-phases-00-09.md)**.

---

## Quick recap

- **Starting point:** Phases 00-09 proved the full delivery path on the Proxmox-backed K3s target platform.
- **Constraint:** The original Proxmox environment has a fixed remaining lifetime and will no longer be available as a long-lived target.
- **Chosen path:** Capture final public, platform, observability, CI/CD, validation, and backup evidence before AWS migration work begins.
- **Verified result:** The completed Proxmox platform remains reviewable through committed documentation, screenshots, terminal evidence, archived README content, and local backup artifacts.
- **Next-step impact:** Phase 11 can move to AWS from a clearly documented boundary instead of silently replacing the completed Proxmox story.

---

## Key decisions

### P10-D01 — Treat Phase 10 as an evidence and migration-readiness phase, not a new feature phase

- **Decision:** Keep Phase 10 focused on final evidence capture, backup readiness, and documentation preservation.
- **Why:** The immediate priority is preserving the proven platform state before the original Proxmox environment becomes unavailable, not adding new runtime features.
- **Proof:** Final public endpoint evidence, Proxmox/K3s state evidence, observability screenshots, workflow screenshots, archived README snapshot, and local DR backup artifacts.
- **Next-step impact:** AWS migration can start from a clean documented boundary.

### P10-D02 — Archive the Proxmox-era README as a historical snapshot

- **Decision:** Preserve the current root README under `project-docs/10-proxmox-exit-evidence/archive/`.
- **Why:** The root README will likely evolve toward the AWS migration path later, while the completed Proxmox Phase 00-09 project story should remain reviewable as its own milestone.
- **Proof:** Archived README snapshot under the Phase 10 archive folder.
- **Next-step impact:** The root README can change later without losing the original Proxmox/K3s evidence narrative.

### P10-D03 — Keep DR backup artifacts local and out of Git

- **Decision:** Create final DR backup artifacts for migration readiness, but do not commit raw backup archives to the repository.
- **Why:** Backup artifacts can include runtime data, metadata, and environment-specific details. The repository should preserve proof and structure, not raw live backup payloads.
- **Proof:** Backup folder listings, terminal screenshots, and documentation evidence are committed instead of raw backup archives.
- **Next-step impact:** Migration work can use local backup artifacts while the public repository remains safe.

### P10-D04 — Preserve the Proxmox platform story before starting AWS migration

- **Decision:** Document Phase 10 as the transition boundary from Proxmox-backed delivery to AWS-backed target migration.
- **Why:** This keeps the project story clear: the platform was first proven on Proxmox, then migrated because the original target environment became time-limited.
- **Proof:** Phase 10 implementation log, archived README snapshot, evidence folder, and final presentation link.
- **Next-step impact:** Phase 11 can be framed as a cloud migration from a proven platform, not as an unrelated rebuild.