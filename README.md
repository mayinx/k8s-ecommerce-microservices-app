# Sock Shop DevOps Project (DataScientest)

This repository is a DevOps project built around the Sock Shop microservices demo (forked from DataScientest’s `microservices-app`).  
Goal: a production-like, reproducible delivery path (local → Proxmox) with evidence-grade documentation.

## What this project will cover (capstone deliverables)
- Kubernetes deployment (k3s locally → Proxmox target)
- CI/CD (build/test/push/deploy with gated prod later)
- IaC (Terraform planned for Proxmox)
- Observability (Prometheus/Grafana planned)
- DevSecOps controls (>= 3 measures planned)
- DR / rollback approach (planned)
- Documentation: phase logs + runbooks + decisions + ADRs

## Documentation (start here)
- **Phase navigation index:** `project-docs/INDEX.md`
- Phase docs are stored under `project-docs/<phase>/` and include:
  - `IMPLEMENTATION.md` (full build diary: rationales, corrections, validation, evidence pointers)
  - `RUNBOOK.md` (TL;DR rerun commands)
  - `evidence/` (screenshots/logs when used)

> Note: `docs/` is a git submodule (upstream site). Capstone docs live in `project-docs/`.

## Architecture Decision Records (ADRs)

Project-wide standards and long-lived decisions will be documented as ADRs in: `./adr/`. 

**Current ADRs (source of truth):**
- ADR-0001 — Git conventions (workflow, branching, commit messages): `adr/[2026-03-17] ADR-0001 -- Git-Conventions.md`
- ADR-0002 — Documentation system and locations: `adr/[2026-03-18] ADR-0002 -- Docs-System.md`

## Current project state (high level)
- **Phase 00:** Compose + repo baseline (local poke-around, host :80 conflict diagnosis + workaround)
- **Phase 01:** Local k3s baseline (clean Sock Shop deploy in `sock-shop` namspace, NodePort access)

See `project-docs/INDEX.md` for the authoritative phase list and links.

## Quick access (pointers, not a full guide)
- Local k3s storefront baseline (Phase 01) is exposed via NodePort `30001`.
- Detailed steps + verification commands are in:
  - `project-docs/01-local-k3s-baseline/IMPLEMENTATION.md`
  - `project-docs/01-local-k3s-baseline/RUNBOOK.md`

## Repo structure (high level)
- `adr/` — Architecture Decision Records (durable, cross-phase standards)
- `project-docs/` — Phase documentation (implementation logs, runbooks, evidence, decisions)
- `deploy/` — Upstream deployment assets (compose, k8s manifests, monitoring/policies, terraform)

## License / upstream
This is a fork-based project built for training/capstone purposes. Upstream origins and licenses apply where relevant.

-----------------

# upstream readme

[![Build Status](https://travis-ci.org/microservices-demo/microservices-demo.svg?branch=master)](https://travis-ci.org/microservices-demo/microservices-demo)

Sock Shop : A Microservice Demo Application

The application is the user-facing part of an online shop that sells socks. It is intended to aid the demonstration and testing of microservice and cloud native technologies.

It is built using [Spring Boot](http://projects.spring.io/spring-boot/), [Go kit](http://gokit.io) and [Node.js](https://nodejs.org/) and is packaged in Docker containers.

You can read more about the [application design](./internal-docs/design.md).

## Deployment Platforms

The [deploy folder](./deploy/) contains scripts and instructions to provision the application onto your favourite platform. 

Please let us know if there is a platform that you would like to see supported.

## Bugs, Feature Requests and Contributing

We'd love to see community contributions. We like to keep it simple and use Github issues to track bugs and feature requests and pull requests to manage contributions. See the [contribution information](.github/CONTRIBUTING.md) for more information.

## Screenshot

![Sock Shop frontend](https://github.com/microservices-demo/microservices-demo.github.io/raw/master/assets/sockshop-frontend.png)

## Visualizing the application

Use [Weave Scope](http://weave.works/products/weave-scope/) or [Weave Cloud](http://cloud.weave.works/) to visualize the application once it's running in the selected [target platform](./deploy/).

![Sock Shop in Weave Scope](https://github.com/microservices-demo/microservices-demo.github.io/raw/master/assets/sockshop-scope.png)

## 
