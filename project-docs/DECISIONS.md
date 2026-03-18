# project-docs/DECISIONS.md

# Decision Log (ADR-lite)

Purpose: Capture **phase-scoped technical decisions** (with context + alternatives) so they remain quick to review  without re-reading the full implementation logs.

## Template (when adding new decisions)
- Date:
- Decision:
- Context / problem:
- Options considered:
- Chosen option + why:
- Verification / evidence:
- Consequences / follow-ups:

---

## Phase 00 — Compose + repo baseline — 2026-02-24 to 2026-02-27

**Quick recap (Phase 00)**  
- Phase 00 established a reliable starting point for the project by validating the fork setup, mapping the repo’s deployment assets, and running Sock Shop locally via Docker Compose. 
- The key practical obstacle was that **host port `:80` did not reach the Docker-published Traefik router** on this machine, because **local k3s/CNI hostport NAT rules intercepted traffic to `:80`**. 
- This was solved by introducing a **local-only Compose override** that exposes the storefront on **`http://localhost:8081/`**, while keeping upstream Compose files unchanged.

**Primary evidence (Phase 00)**  
- Storefront reachable via local override: `project-docs/00-compose-repo-baseline/evidence/[2026-02-27]-Port-8081_Storefront-reachable.png`  
- Traefik dashboard reachable: `project-docs/00-compose-repo-baseline/evidence/[2026-02-25]-Port-8080_Traefik-Dashboard-1.png` (and follow-ups)

**Further details**  
- Implementation log: `project-docs/00-compose-repo-baseline/IMPLEMENTATION.md`  
- Runbook: `project-docs/00-compose-repo-baseline/RUNBOOK.md`

---

### Decision (P00-D01): repository workflow = fork as `origin`, upstream as read-only reference
- **Decision:** Work is done on the fork (`origin`) while the source repository is kept as a fetch-only reference (`upstream`), with pushing to upstream disabled.
- **Context / problem:** Without an explicit `origin`/`upstream` setup, it is easy to lose track of where changes go or accidentally push to the upstream training repo.
- **Options considered:**
  - Use only one remote (simpler, but no clean upstream reference)
  - Use `origin` (fork) + `upstream` (source repo) and prevent upstream pushes ✅
- **Chosen option + why:** The fork remains the writable workspace, while upstream stays available for reference and optional comparison, without risk of accidental pushes.
- **Verification / evidence:** `git remote -v` shows `origin` pointing to the fork and `upstream` with `no_push` for pushes (recorded in Phase 00 implementation log).
- **Consequences / follow-ups:** This remote model stays in place for all later phases.

### Decision (P00-D02): baseline runtime = Docker Compose, minimal changes
- **Decision:** Use the existing Docker Compose stack in `deploy/docker-compose/` to validate a working baseline before introducing Kubernetes changes.
- **Context / problem:** A working local baseline is needed to confirm the application itself starts correctly and to establish evidence-grade entrypoints and service inventory.
- **Options considered:**
  - Go directly to Kubernetes (higher complexity, harder to triage)
  - Run the upstream Compose baseline first ✅
- **Chosen option + why:** Compose provides a fast, low-friction baseline that helps separate “application works” from “platform/routing issues”.
- **Verification / evidence:** Containers started successfully and internal storefront HTML could be retrieved from inside the router container (recorded in Phase 00).
- **Consequences / follow-ups:** Kubernetes work begins only after the baseline is proven.

### Decision (P00-D03): handle host `:80` conflict via local-only Compose override (not by changing upstream Compose or stopping k3s)
- **Decision:** Keep upstream Compose files unchanged and use a local override file (`docker-compose.local.yml`) to publish the router as `8081:80` on this machine.
- **Context / problem:** Requests to `http://localhost/` returned `Server: uvicorn` instead of reaching Traefik, proving that host `:80` traffic was intercepted by local k3s/CNI NAT rules.
- **Options considered:**
  - Stop/disable k3s to free host `:80` (intrusive; breaks local k3s workflows)
  - Modify upstream `docker-compose.yml` permanently (pollutes upstream baseline)
  - Use a local-only override Compose file to avoid host `:80` ✅
- **Chosen option + why:** The override preserves upstream configuration while providing a clean local entrypoint.
- **Verification / evidence:** Storefront became reachable at `http://localhost:8081/` and returned HTML (Phase 00 evidence screenshot).
- **Consequences / follow-ups:** The “local override” approach is reused later whenever local environment conflicts must be avoided without patching upstream defaults.

---

## Phase 01 — Local cluster baseline (k3s) — 2026-03-09

**Quick recap (Phase 01)**  
Phase 01 established a **clean, reproducible Sock Shop deployment on the local k3s cluster** using the repository’s upstream Kubernetes manifests. The main obstacle was a **NodePort collision**: the upstream `front-end` Service uses a fixed NodePort (`30001`), and NodePorts are allocated **cluster-wide**, so an unrelated lab Service can block creation even when Sock Shop is deployed into its own namespace.

In this environment, the collision was caused by a previous lab deployment: the `wordpress` Service in namespace `datascientest` was already using NodePort `30001` (`80:30001/TCP`). To keep Phase 01 fully aligned with upstream (no YAML patching), the chosen approach was to **free NodePort `30001` first**, then apply the manifests unchanged. After deployment, all Sock Shop workloads in the `sock-shop` namespace became **Running/Ready**, and the storefront UI loaded successfully via **`http://localhost:30001/`** (and also via `http://<node-ip>:30001/`).

**Primary evidence (Phase 01)**  
- Storefront screenshot: `project-docs/01-local-k3s-baseline/evidence/[2026-03-09]-Port-30001_Storefront.png`

**Further details**  
- Implementation log: `project-docs/01-local-k3s-baseline/IMPLEMENTATION.md`  
- Runbook: `project-docs/01-local-k3s-baseline/RUNBOOK.md`

---

### Decision (P01-D01): deploy path = upstream manifests (not Helm yet)
- **Decision:** Deploy Sock Shop using the upstream Kubernetes manifests in `deploy/kubernetes/manifests/`, and postpone Helm until later phases.
- **Context / problem:** Phase 01’s goal was to get a working Kubernetes baseline with the fewest moving parts and the clearest debugging surface.
- **Options considered:**
  - Apply upstream manifests (`deploy/kubernetes/manifests`) ✅
  - Install via Helm (`deploy/kubernetes/helm-chart`)
- **Chosen option + why:** Manifests keep the baseline closest to upstream and make it easier to understand what is created in the cluster without Helm indirection.
- **Verification / evidence:** After preflight checks, `kubectl apply -n sock-shop -f deploy/kubernetes/manifests` succeeded and the workloads became Ready (confirmed in Phase 01 docs + evidence screenshot).
- **Consequences / follow-ups:** Helm remains a strong candidate later, especially once dev/prod separation (values) becomes a priority.

### Decision (P01-D02): storefront access = NodePort 30001 (upstream default)
- **Decision:** Use NodePort `30001` as the storefront access path for Phase 01, without requiring Ingress.
- **Context / problem:** Phase 01 needed a working storefront entrypoint while keeping the scope minimal and avoiding Ingress complexity.
- **Options considered:**
  - Keep upstream NodePort `30001` ✅
  - Patch the NodePort via overlay/patch
  - Port-forward to a ClusterIP Service
- **Chosen option + why:** The upstream NodePort is explicit, simple to verify, and avoids introducing Ingress routing decisions too early.
- **Verification / evidence:** Storefront UI loaded via `http://localhost:30001/` (and `http://<node-ip>:30001/`) and is captured as Phase 01 evidence.
- **Consequences / follow-ups:** Phase 02 will add an Ingress entrypoint for a more production-like access path.

### Decision (P01-D03): NodePort collision handling = free 30001 (do not patch Sock Shop in Phase 01)
- **Decision:** When NodePort `30001` is already allocated, free the port by removing the conflicting Service (lab hygiene), rather than patching Sock Shop YAMLs.
- **Context / problem:** Sock Shop’s upstream manifests use a fixed NodePort. In this cluster, `datascientest/wordpress` was already consuming `30001`, which caused `front-end` Service creation to fail.
- **Options considered:**
  - Delete/change the conflicting lab Service owning `30001` ✅
  - Patch Sock Shop NodePort via local-only overlay
- **Chosen option + why:** Freeing the port preserves upstream Sock Shop manifests unchanged and keeps Phase 01 reproducible and easy to defend as “upstream baseline”.
- **Verification / evidence:** `kubectl get svc -A -o wide | grep 30001` identified the collision; after freeing it, the `front-end` NodePort Service could be created successfully (Phase 01 docs).
- **Consequences / follow-ups:** For multi-app clusters, Ingress + host rules is usually the better “primary access” pattern than fixed NodePorts.

### Decision (P01-D04): deployment boundary = dedicated namespace `sock-shop`
- **Decision:** Deploy Sock Shop into a dedicated namespace (`sock-shop`) rather than using `default`.
- **Context / problem:** Phase work must be re-runnable without risking unrelated lab workloads; a dedicated namespace provides a clean boundary for reset + reapply.
- **Options considered:**
  - Deploy into `default`
  - Deploy into dedicated namespace `sock-shop` ✅
- **Chosen option + why:** A dedicated namespace makes cleanup predictable and keeps the capstone deployment clearly separated from exercises.
- **Verification / evidence:** All Sock Shop objects are created in `sock-shop`, and reruns can remove only this namespace’s content without touching other namespaces (Phase 01 docs).
- **Consequences / follow-ups:** Namespaces do not isolate cluster-wide resources like NodePorts or Ingress host/path collisions, so preflight checks remain necessary in later phases.

---

## (Further entries will be added to record technical choices)
