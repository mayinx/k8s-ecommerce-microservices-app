# Project Documentation Index

Documentation is iterative and phase-aligned: baseline notes first, then milestone implementation notes, with a small decision log and runbooks added when needed.

## Phase 00: Compose + repo baseline (local poke-around + repo mapping)
- [Phase 00 — Implementation Log](./00-compose-repo-baseline/IMPLEMENTATION.md)
- [Phase 00 — Runbook (TL;DR)](./00-compose-repo-baseline/RUNBOOK.md)
- [Decision log (ADR-lite)](./DECISIONS.md)

## Phase 01: Local k3s cluster baseline (port-based Sock Shop deploy, conflict-free)
- [Phase 01 — Implementation Log](./01-nodeport-baseline/IMPLEMENTATION.md)
- [Phase 01 — Runbook (TL;DR)](./01-nodeport-baseline/RUNBOOK.md)

## Phase 02: Ingress baseline (host-based Traefik routing to storefront + rollback)
- [Phase 02 — Implementation Log](./02-ingress-baseline/IMPLEMENTATION.md)
- [Phase 02 — Runbook (TL;DR)](./02-ingress-baseline/RUNBOOK.md)

## Phase 03: CI/CD baseline (GitHub Actions delivery smoke path for dev/prod)
- [Phase 03 — Implementation Log](./03-ci-cd-baseline/IMPLEMENTATION.md)
- [Phase 03 — Runbook (TL;DR)](./03-ci-cd-baseline/RUNBOOK.md)

## Future phases (placeholders; added when we reach them)
- Phase 04: Target deployment on Proxmox (IaC)
- Phase 05: Observability (monitoring/logging/alerting)
- Phase 06: Security hardening (scanning, policies, secrets)
- Phase 07: DR / rollback runbooks


