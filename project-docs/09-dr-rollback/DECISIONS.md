# Decision Log — Phase 09 (Disaster Recovery & Rollback): Backup, recovery, and rollback readiness on the Proxmox-based target cluster

> ## About
> This document is the **phase-local decision log** for **Phase 09 (Disaster Recovery & Rollback)**.
> It captures the key recovery and rollback decisions for this phase without overloading the shorter project-wide summary in **[project-docs/DECISIONS.md](../DECISIONS.md)**.
> For the full chronological build diary, see: **[IMPLEMENTATION.md](IMPLEMENTATION.md)**.
> For the short rerun flow, see: **[RUNBOOK.md](RUNBOOK.md)**.
> For cross-phase incident and anomaly tracking, see: **[../DEBUG-LOG.md](../DEBUG-LOG.md)**.

---

## Index

- [**Quick recap of Phase 09**](#quick-recap-of-phase-09)
  - [**Starting point: The project needed a practical recovery baseline**](#starting-point-the-project-needed-a-practical-recovery-baseline)
  - [**Constraint: The target is single-node, not highly available**](#constraint-the-target-is-single-node-not-highly-available)
  - [**Chosen path: Backup, inspect, rebuild, redeploy, and restore where available**](#chosen-path-backup-inspect-rebuild-redeploy-and-restore-where-available)
  - [**Verified result of Phase 09**](#verified-result-of-phase-09)
- [**Key Phase Decisions**](#key-phase-decisions)
  - [**P09-D01 — DR scope = backup + rebuild + redeploy, not full HA**](#p09-d01--dr-scope--backup--rebuild--redeploy-not-full-ha)
  - [**P09-D02 — Backup model = Kubernetes state export plus MongoDB dump attempts**](#p09-d02--backup-model--kubernetes-state-export-plus-mongodb-dump-attempts)
  - [**P09-D03 — Restore validation = representative MongoDB dump restored into a temporary local container**](#p09-d03--restore-validation--representative-mongodb-dump-restored-into-a-temporary-local-container)
  - [**P09-D04 — Recovery proof = safe pod deletion in dev**](#p09-d04--recovery-proof--safe-pod-deletion-in-dev)
  - [**P09-D05 — Rollback model = Git revert first, Kubernetes rollout undo for emergency runtime rollback**](#p09-d05--rollback-model--git-revert-first-kubernetes-rollout-undo-for-emergency-runtime-rollback)
- [**Next-step implications**](#next-step-implications)

---

## Quick recap of Phase 09

Phase 09 established the project’s first practical disaster-recovery and rollback baseline.

### Starting point: The project needed a practical recovery baseline

After the earlier delivery, observability, security, and IaC phases, the project already had:

- A Proxmox-based target VM
- A single-node K3s cluster
- Namespace-separated `dev` and `prod` application environments
- GitHub Actions based delivery
- Observability and security validation paths
- A first Terraform-based Proxmox IaC proof

The missing capability was a documented and executable recovery baseline: a way to preserve useful recovery artifacts, prove safe recovery behavior, and document rollback and rebuild paths.

Phase 09 therefore focused on:

- Kubernetes namespace-state export
- MongoDB-compatible logical dump attempts
- Local backup artifacts outside Git
- Restore validation for one representative dump artifact
- Safe pod-recovery proof in `sock-shop-dev`
- Git-based and Kubernetes-level rollback guidance
- Node/VM recovery boundaries for the current single-node target

### Constraint: The target is single-node, not highly available

The current target architecture is a single-node K3s cluster on a Proxmox VM.

This means:

- Kubernetes can recreate failed Pods on the running node through controller reconciliation.
- Kubernetes cannot fail over the whole cluster if the only node or VM is lost.
- Full node/VM recovery must be handled through rebuild, redeploy, and restore where backup artifacts are available.

Phase 09 documents this boundary directly instead of implying automatic high availability.

### Chosen path: Backup, inspect, rebuild, redeploy, and restore where available

The chosen recovery model is aligned with the existing project architecture:

- Export Kubernetes namespace state into timestamped local backup folders.
- Attempt MongoDB logical dumps for known database Pods where `mongodump` is available.
- Keep generated backup artifacts local and gitignored.
- Validate at least one MongoDB dump by restoring it into a temporary local MongoDB container.
- Prove container-level recovery by deleting one `front-end` Pod in `sock-shop-dev` and validating that Kubernetes recreates it.
- Use Git revert plus protected validation and redeploy as the normal rollback model.
- Keep `kubectl rollout undo` as an emergency runtime rollback command for Deployment revisions.
- Document full node/VM recovery as rebuild, redeploy, and restore where artifacts exist.

### Verified result of Phase 09

By the end of the phase, the project had proven:

- The DR backup helper runs against both application namespaces.
- Kubernetes namespace-state exports are created locally.
- MongoDB archive dumps are created for compatible database Pods.
- Unsupported data-store Pods are recorded as skipped instead of causing the whole backup run to fail.
- One representative MongoDB dump is restored into a temporary local MongoDB container and queried successfully.
- A deleted `front-end` Pod in `sock-shop-dev` is recreated by Kubernetes.
- Live smoke validation passes after the recovery proof.
- The rollback and node/VM recovery boundaries are documented.

---

## Key Phase Decisions

### P09-D01 — DR scope = Backup + rebuild + redeploy, not full HA

- **Decision:** Treat Phase 09 as a practical disaster-recovery baseline, not a high-availability redesign.
- **Why:** The current platform is a single-node K3s target. It can recover application Pods while the node is healthy, but it does not provide automatic node or cluster failover.
- **Scope boundary:** Full node/VM loss is handled through the documented rebuild, redeploy, and restore path rather than through automatic failover.
- **Proof:** The implementation documents the current recovery model and connects it to the Phase 04 VM baseline, Phase 05 target delivery path, Phase 08 Terraform proof, and Phase 09 backup artifacts.
- **Next-step impact:** A multi-node K3s setup, external datastore, or storage-level backup strategy remains a future hardening topic, not a hidden claim of this phase.

### P09-D02 — Backup model = Kubernetes state export plus MongoDB dump attempts

- **Decision:** Implement a local backup helper that exports namespace-level Kubernetes state and attempts MongoDB logical dumps from known Sock Shop database Pods.
- **Why:** This provides a lightweight, auditable first recovery package without introducing a larger backup platform or storage system.
- **Backup scope:** The helper captures:
  - Kubernetes resource snapshots for the selected namespace
  - Secret metadata only, without exporting Secret values
  - MongoDB archive dumps where `mongodump` is available
  - A database backup report that records success, skip, and warning states
- **Artifact handling:** Generated backup folders are written under `backups/` and excluded from Git.
- **Next-step impact:** Redis-specific backup handling for `session-db` and image-specific handling for `catalogue-db` remain follow-up hardening items.

### P09-D03 — Restore validation = Representative MongoDB dump restored into a temporary local container

- **Decision:** Validate one representative MongoDB dump by restoring it into a disposable local MongoDB container and querying the restored data.
- **Why:** Backup files alone are not strong recovery evidence. At least one dump must be proven readable, restoreable, and queryable.
- **Why local container:** The restore validation must not write back into `sock-shop-dev` or `sock-shop-prod`.
- **Proof:** The selected `user-db` dump is restored into a temporary MongoDB container and queried successfully. The restored collections, document counts, and document keys match the live baseline that was inspected before the restore check.
- **Next-step impact:** Future restore drills can extend this from representative validation to a disposable namespace or disposable cluster restore exercise.

### P09-D04 — Recovery proof = Safe pod deletion in dev

- **Decision:** Prove executable recovery behavior by deleting one `front-end` Pod in `sock-shop-dev`.
- **Why:** Pod deletion is a safe, realistic container-level failure scenario because the Deployment controller is expected to recreate the Pod from desired state.
- **Why dev:** The proof should not intentionally disrupt production.
- **Proof:** Kubernetes recreates a replacement `front-end` Pod, the replacement reaches `Running` and `READY`, and the live validation bundle passes afterward.
- **Next-step impact:** The project has a clear recovery proof for application Pod failure while keeping more destructive restore and node-failure drills out of the first DR baseline.

### P09-D05 — Rollback model = Git revert first, Kubernetes rollout undo for emergency runtime rollback

- **Decision:** Use Git-based rollback as the normal rollback path and document Kubernetes rollout undo as an emergency runtime rollback command.
- **Why:** The project already uses a protected delivery model. Normal rollback should therefore follow the same auditable path: revert in Git, pass validation, and redeploy.
- **Emergency path:** `kubectl rollout undo` remains documented for urgent Deployment-level rollback when a previous revision exists and a runtime revert is required.
- **Proof:** Rollout history is inspected, and the emergency rollback command surface is documented without forcing an artificial bad release.
- **Next-step impact:** The rollback model stays aligned with merge governance and CI/CD instead of encouraging unmanaged manual cluster drift.

---

## Next-step implications

- Phase 09 completes the first practical recovery baseline for the current platform shape.
- The project can now describe recovery as:
  - backup
  - inspect
  - restore where available
  - redeploy
  - validate
  - rebuild for full node/VM loss
- Future DR hardening can build on this baseline instead of starting from scratch.
- The main future hardening candidates are:
  - Redis-specific backup handling for `session-db`
  - image-specific backup handling for `catalogue-db`
  - disposable namespace or disposable cluster restore drills
  - storage-level or VM-level backup strategy
  - multi-node K3s or another high-availability target architecture