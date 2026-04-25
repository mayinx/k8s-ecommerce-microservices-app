# ADR-0002: Documentation system and locations

Status: Accepted  
Date: 2026-03-18

---

## Problem / Issue

Without clear documentation roles and a consistent structure
- (1) changes and decisions become hard to follow and review, 
- (2) runs become non-reproducible, 
- (3) implementation notes, rerun steps, decisions, and evidence become scattered  

Documentation must support various documentation needs - both project-wide and across implementation phases: 

- **(1) Reproducible execution:** it must be possible to understand *what was done, why it was done, what the outcome was, and how to rerun it.
- **(2) Defensible decisions:** it must be possible to explain why a standard/approach was chosen, including key trade-offs and decision points.
- **(3) long-term cross-phase standards/decisions**: it must be possibel to capture long-term standards that are not specific to a particular implementation phase (like git workflow + conventions, doc system, environments strategy, IaC approach).

This requires a **detailed implementation log (“build diary”)** that records the **full implementation path** — including **key decisions, corrections, verification/validation steps, and evidence pointers** — so the work remains auditable and repeatable.

Early attempts to keep the narrative in one place and rely on commit/terminal history for the rest proved fragile: corrections, validation outputs, and evidence references became hard to track, and reruns became slow.

There is also a structural constraint: Project documentation must remain easy to navigate and reviewer-friendly while avoiding accidental writes into `docs/` (a git submodule). 

---

## Context

The project uses phase-based delivery (baseline → ingress → CI/CD → IaC → observability → security → DR). Each phase produces changes and evidence that must remain reviewable, reproducible, and auditable.

This creates recurring documentation needs per phase:
- a detailed implementation + execution log (full path with rationales + corrections + validation + evidence pointers)
- a shorter command-first rerun guide (TL;DR)
- evidence pointers (screenshots/logs with stable filenames)
- a lightweight decision trail (phase-scoped)

Additionally, the project needs a place to capture durable cross-phase standards (workflow, documentation system, environments strategy, IaC approach).

---

## Options considered

### Documentation roles (why/what)
1. README-only + ad-hoc notes + terminal/commit history (rejected: not auditable/reproducible; decisions/evidence get lost)
2. One monolithic “everything” doc (rejected: reruns and reviews become slow; hard to separate durable standards vs phase execution)
3. Role-based docs: README + IMPLEMENTATION + RUNBOOK + DECISIONS + ADRs ✅

### Documentation locations (where)
1. Put project documentation under `docs/` (rejected: `docs/` is a git submodule as per upstream)
2. Scatter docs across repo root (rejected: low discoverability, hard to maintain)
3. Keep phase docs under `project-docs/`, scoped by implementation phases with an index, plus ADRs at repo root ✅

---

## Decision

The described issues drove the decision **to separate documentation** 
- **by role** (entry point vs build diary vs rerun guide vs decisions vs durable standards) 
- **and scope** (project-wide vs project-phase-specific).

### Chosen documentation roles and scopes

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
- `project-docs/00-compose-baseline/`
- `project-docs/01-local-k3s-baseline/`

### ADR structure and naming
- ADRs live in `adr/` at repo root (visible to reviewers)
- Filenames use date + incrementing ID for stable ordering:
  - Schema:   `adr/[YYYY-MM-DD] ADR-<ID> -- <Short-Title>.md`
  - Example:  `adr/[2026-03-17] ADR-0001 -- Git-Conventions.md` 

---

## Consequences / Outcome
- Reviewers can follow the project and its phase-based implementation via a single index without digging through commit history or unstructured scattered docs.
- Documentation remains phase-aligned and predictable.
- The git submodule `docs/` stays untouched, eliminating a common source of confusion.
- Durable standards (Git conventions, doc system) are captured once as ADRs, not repeated.

---

## References
- [Documenting architecture decisions ADR guidance (industry)](https://gds-way.digital.cabinet-office.gov.uk/standards/architecture-decisions.html)
- [Maintain an architecture decision record (ADR)](https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record)