# ADR-0002: Documentation system and locations

Status: Accepted  
Date: 2026-03-18

---

## Problem / Issue

Documentation must support two needs across phases: **(1) reproducible execution** (what was done, why was it done, with what outcome + how to rerun) and **(2) defensible decisions** (why a standard/approach/implementation was chosen). This requires a **detailed implementation log (“build diary”)** that records the **full implementation path** — including **key decisions, corrections, verification/validation steps, and evidence pointers** — so the work remains auditable and repeatable.

Early attempts to keep the full narrative in a single document and rely on commit history for the rest proved fragile: corrections, validation outputs, and evidence references became hard to track, and reruns became slow.  

In addition, project documentation must remain easy to navigate, reviewer-friendly, and avoid accidental writes into `docs/` (a git submodule). Without clear documentation roles and a consistent structure, changes become hard to review, runs become non-reproducible, and implementation notes, rerun steps, decisions, and evidence become scattered instead of being auditable by a reviewer.

The described issues drove the decision to separate documentation 
- by role (entry point vs build diary vs rerun guide vs decisions vs durable standards) 
- and scope (project-wide vs project-phase-specific).

---

## Context

The project uses phase-based delivery (baseline → ingress → CI/CD → IaC → observability → security → DR). Each phase produces changes and evidence that must remain reviewable, reproducible, and auditable.

This creates recurring documentation needs per phase:
- a detailed implementation + execution log (full path with rationales + corrections + validation + evidence pointers)
- a shorter command-first rerun guide (TL;DR)
- evidence pointers (screenshots/logs with stable filenames)
- a lightweight decision trail (phase-scoped)

Furthermore, documentation must capture long-term cross-phase standards (workflow, doc system, environments strategy, IaC approach).

---

## Options considered

### Documentation roles (why/what)
1. README-only + ad-hoc notes + terminal/commit history (rejected: not auditable/reproducible; decisions/evidence get lost)
2. One monolithic “everything” doc (rejected: reruns and reviews become slow; hard to separate durable standards vs phase execution)
3. Role-based docs: README + IMPLEMENTATION + RUNBOOK + DECISIONS + ADRs ✅

### Documentation locations (where)
1. Put project documentation under `docs/` (rejected: `docs/` is a git submodule as per upstream)
2. Scatter docs across repo root (rejected: low discoverability, hard to maintain)
3. Keep phase docs under `project-docs/` with an index, plus ADRs at repo root ✅

---

## Decision

### Chosen documentation roles

Different documentation types with clearly defined roles are used to solve different problems:

- **Project-wide (global entry point + durable standards)**
  - `README.md`: project entry point (what it is, how to start, where the docs live)
  - `adr/…`: full ADRs for durable, cross-phase standards (workflow, doc system, environments strategy, IaC approach)

- **Phase-specific (execution + rerun)**
  - `IMPLEMENTATION.md`: narrative execution log (rationales + key observations + corrections + validation + evidence pointers)
  - `RUNBOOK.md`: command-first rerun guide (TL;DR)

- **Phase-scoped (lightweight decision trail)**
  - `DECISIONS.md`: lightweight decision log (ADR-lite, scoped to the phase timeline)

This split avoids losing the implementation narrative in terminal + commit history and keeps reruns and reviews fast without sacrificing auditability.

### Project documentation location

- Store **phase documentation** under `project-docs/` in phase-specific subfolders
- Keep **`project-docs/INDEX.md`** as the **single navigation entry point for phase-specific docs** 
- Keep **`project-docs/DECISIONS.md`** as the lightweight + **phase-scoped “ADR-lite” log** 
- Store **full ADRs** under **`adr/`** at repo root 

### Phase folder structure

**Phase folder naming schema:**

`project-docs/<2-digit-phase-no>-<phase-specific-folder>/...`

Example:

`project-docs/01-local-k3s-baseline/...` 

**Each phase folder contains at minimum:**
- `IMPLEMENTATION.md` (narrative log with rationales + evidence)
- `RUNBOOK.md` (TL;DR rerun commands)
- `evidence/` (screenshots/log artifacts when used)

**Current phases:**
- `project-docs/00-compose-repo-baseline/`
- `project-docs/01-local-k3s-baseline/`

### ADR structure and naming
- ADRs live in `adr/` at repo root (visible to reviewers)
- Filenames use date + incrementing ID for stable ordering:
  - Schema:   `adr/[YYYY-MM-DD] ADR-<ID> -- <Short-Title>.md`
  - Example:  `adr/[2026-03-17] ADR-0001 -- Git-Conventions.md` 

---

## Consequences / Outcome
- Reviewers can follow the project via a single index without digging through commit history.
- Documentation remains phase-aligned and predictable.
- The git submodule `docs/` stays untouched, eliminating a common source of confusion.
- Durable standards (Git conventions, doc system) are captured once as ADRs, not repeated.

---

## References
- ADR guidance (industry): https://gds-way.digital.cabinet-office.gov.uk/standards/architecture-decisions.html