# Project Roadmap

> ## 👤 About
> This document is the internal project-planning overview for the Sock Shop DevOps project.  
> It captures the bird’s-eye phase plan, major next steps, deferred follow-ups, and open planning questions.  
> It is meant as the working planning reference for future implementation discussions and prioritization.  
> For the navigable project documentation index, see: **[project-docs/INDEX.md](INDEX.md)**.  
> For the summarized project-wide decision record, see: **[project-docs/DECISIONS.md](DECISIONS.md)**.

---

## 📌 Index (top-level)

- [Current position](#current-position)
- [Phase roadmap](#phase-roadmap)
- [Cross-phase backlog](#cross-phase-backlog)
- [Deferred follow-ups already known](#deferred-follow-ups-already-known)
- [Open planning questions](#open-planning-questions)

---

## Current position

- Current proven phase:
- Current next target phase:
- Biggest current blocker(s):
- Most important near-term deliverable(s):

---

## Phase roadmap

### Phase 00 — Compose baseline
- status:
- purpose:
- already proven:
- done:

### Phase 01 — Port-based Kubernetes baseline
- status:
- purpose:
- already proven:
- done:

### Phase 02 — Ingress baseline
- status:
- purpose:
- already proven:
- done:

### Phase 03 — CI/CD baseline
- status:
- purpose:
- already proven:
- done:

### Phase 04 — Target deployment / IaC
- status:
- purpose:
- likely work:
- open questions:
  - Retarget the proven GitHub Actions smoke-delivery structure from `kind` to the real target-cluster access path
  - Decide how much of the current CI smoke flow can be reused unchanged
  - Revisit whether the current repo-owned image-build proof remains sufficient once the real target deployment exists
  - Consider the deprecated Kubernetes node selector cleanup if manifest-touching work already happens here    

### Phase 05 — Observability
- status:
- purpose:
- likely work:
- open questions:

### Phase 06 — Security hardening
- status:
- purpose:
- likely work:
- open questions:
  - Tighten repository allowed-actions settings
  - Pin third-party GitHub Actions to full commit SHAs
  - Add workflow protection such as `CODEOWNERS`
  - Re-check `GITHUB_TOKEN` permissions job-by-job

### Phase 07 — DR / rollback
- status:
- purpose:
- likely work:
- open questions:

---

## Cross-phase backlog

- item:
- item:
- item:

---

## Deferred follow-ups already known

- `openapi` remains excluded from the workflow because it still depends on legacy Node 6 / npm 3
- GitHub Actions runtime warnings around Node.js 20 deprecation still need a later cleanup pass
- Kubernetes manifests still contain the deprecated node selector label `beta.kubernetes.io/os`
- ...

---

## Open planning questions

- question:
- question:
- question: