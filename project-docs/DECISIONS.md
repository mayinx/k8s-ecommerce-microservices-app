# Decision Log ("ADR Lite")

Purpose: Capture **phase-scoped technical decisions** (with context + alternatives) so they remain quick to review without re-reading the full implementation logs. 

> **Hint:** This log contains consolidated project-phase related decision summaries only (“ADR-lite”); durable cross-phase standards live in `adr/` as full ADRs.

Decisions in this project are made along an explicit, **phase-based delivery path (baseline → next capability)**; therefore this log also records that delivery path and its guiding principles as the reference frame and foundation for later decisions.

## Template (when adding new decisions)
- Date:
- Decision:
- Context / problem:
- Options considered:
- Chosen option + why:
- Verification / evidence:
- Consequences / follow-ups:

---

## Foundation decision: Phase-based DevOps delivery approach 

**Base Decision (P00-D00): delivery approach = phase-based baselines**
- **Decision:** Deliver in phases: prove a minimal baseline first, keep it working as fallback, then add one capability per phase with explicit verification + rollback.
- **Why:** Reduces complexity, keeps changes reviewable, and eases debugging. 
- **Evidence:** Phase 00 + Phase 01 baselines are alreadey proven and kept as fallbacks (Compose storefront on `:8081`, k3s storefront on NodePort `:30001`).

---

This project is delivered incrementally in phases to keep every step small, verifiable, and rollbackable. 

### Guiding principles used for the phased approach 

This phase-based implementation follows a DevOps delivery approach:

- Prove a minimal baseline first and keep it working (as a fallback)
  - --> new work (added in later phases) should not break the last proven entrypoint
- Each phase proves one path end-to-end first, then implements the next capability on top of the already proven baseline
- Add one new capability per phase with explicit verification and a rollback path

This keeps changes small + failures diagnosable.

### Prerequisite: Multiple valid deploy paths exist - phased implementation reduces complexity and risks 

Inspecting the repo structure shows multiple alternative deploy paths already present:

- Baseline app deploy (used in Phase 01): `deploy/kubernetes/manifests/`
- Helm deploy (later for values-based env separation): `deploy/kubernetes/helm-chart/`
- Ingress exists as a Helm template too: `deploy/kubernetes/helm-chart/templates/ingress.yaml` (not used yet)
- Operations add-ons (future phases): `deploy/kubernetes/manifests-monitoring/`, `deploy/kubernetes/manifests-logging/`, `deploy/kubernetes/manifests-policy/`, `deploy/kubernetes/manifests-alerting/`
- Infrastructure (future phases): `deploy/kubernetes/terraform/` and `staging/`

These paths are all valid, but they introduce different moving parts, complexity and potential risks. 

With this in mind (and to keep changes reviewable + failures diagnosable), the project implements one minimal deploy path per phase:

**-> Compose -> Kubernetes manifests -> Ingress -> CI/CD -> IaC -> Ops add-ons (observability/security/DR)**

### Local first

The initial phases use Docker Compose and a local k3s cluster to establish a stable local baseline before moving to the long-lived target environment (Proxmox). THsi way, compelxity is isolated to later phases:

- Proxmox will add extra moving parts (VM networking, firewall rules, DNS, storage, TLS) that make failures slower to debug. This complexity should not be introduced early. 
- A local k3s baseline proves the the deployment path (app deploy -> service exposure -> routing) quickly and repeatedly on the same machine, with clear evidence and fast rollback. 
- Only once a path is proven it makes sense to apply the same approach to Proxmox - and debug the Proxmox-Phase separately if necessary.
- Local baselines also help to surface and remove potential environment hazards early:  
  - Even if deployment assets already exist in the repository, they are not guaranteed to run conflict-free on a given cluster. 
  - In a local k3s lab, cluster-wide resources (NodePorts, Ingress host/path rules, Traefik routing) can collide with leftovers from other exercises 

### Phase progression (so far):

- Phase 00 proved a working application baseline via Compose (fastest triage surface).
- Phase 01 proved a clean local (k3s) Kubernetes baseline via upstream manifests (minimal moving parts).
- Phase 02 adds Ingress as the next capability, without removing the already proven NodePort fallback.

### Sources (delivery approach)

- **Small, verifiable changes + rollbackability (Continuous Delivery):**  
  Google — *Software Engineering at Google*, Ch. 24 “Continuous Delivery” (small batches, safer changes, rollbacks):  
  https://abseil.io/resources/swe-book/html/ch24.html

- **Local-first fast feedback loops + small batches:**  
  Gradle/Develocity — “Achieve Continuous Delivery and DORA goals…” (small batches + accelerating local dev loops):  
  https://gradle.com/blog/achieve-continuous-delivery-dora-goals-develocity/

- **Keeping the trunk releasable (“keep baseline working” rule):**  
  Atlassian — “Git and Continuous Delivery” (short-lived branches, keep main clean/releasable):  
  https://www.atlassian.com/continuous-delivery/principles/git-and-continuous-delivery

---

## Phase 00 — Compose + repo baseline

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

**Conclusion + Net steps**
- Phase 00 confirmed that Sock Shop itself starts correctly via Docker Compose and that the internal routing works inside the Compose network.
- Phase 01 will now implement as a next step a local Kubernetes baseline to prove the same application can run on the target platform (k3s)

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

## Phase 01 — Local cluster baseline (k3s) => Deploy baseline app on local k3s cluster (NodePort) and prove it runs.

**Quick recap (Phase 01)**  
- Phase 01 established a **clean, reproducible port-based Sock Shop baseline on the local k3s cluster** using the repository’s upstream Kubernetes manifests located in `deploy/kubernetes/manifests/`.
- The main obstacle was a **NodePort collision**: the upstream `front-end` Service uses a fixed NodePort (`30001`), and NodePorts are allocated **cluster-wide**, so an unrelated lab Service can block creation even when Sock Shop is deployed into its own namespace.
  - In this environment, the collision was caused by a previous lab deployment: the `wordpress` Service in namespace `datascientest` was already using NodePort `30001` (`80:30001/TCP`). 
  - To keep Phase 01 fully aligned with upstream (no YAML patching), the chosen approach was to **free NodePort `30001` first**, then apply the manifests unchanged. 
- After deployment, all Sock Shop workloads in the `sock-shop` namespace became **Running/Ready**
  - the storefront UI loaded successfully via **`http://localhost:30001/`** (and also via `http://<node-ip>:30001/`).

**Primary evidence (Phase 01)**  
- Storefront screenshot: `project-docs/01-local-k3s-baseline/evidence/[2026-03-09]-Port-30001_Storefront.png`

**Further details**  
- Implementation log: `project-docs/01-local-k3s-baseline/IMPLEMENTATION.md`  
- Runbook: `project-docs/01-local-k3s-baseline/RUNBOOK.md`

**Conclusion + Net steps**
- Phase 01 proved the app is deployable and healthy on a local k3s cluster:
  - Deployed in namespace `sock-shop`, pods reached Running/Ready, storefront loaded via NodePort 30001.
  - But: NodePort is a functional baseline, not a production-like entrypoint:
    - no hostname on :80 
    - no domain-style routing 
    - and: NodePort allocation is cluster-wide → collisions can happen in a shared lab cluster.
- Phase 02 will add a more production-like, host-based entrypoint via Traefik Ingress while keeping port-based/NodePort `30001` as a proven fallback:
  - Host-based routing (e.g. `sockshop.local` / `sockshop.test`) will provide a stable, domain-like access path on `:80` and reduce “port juggling”.
  - Keeping NodePort as fallback will make the change low-risk and rollback-friendly (Ingress can be removed without breaking the already working baseline).
---

### Decision (P01-D01): deploy path = upstream manifests (not Helm yet)
- **Decision:** Deploy Sock Shop using the upstream Kubernetes manifests in `deploy/kubernetes/manifests/`, and postpone Helm until later phases.
- **Context / problem:** Phase 01’s goal was to get a working Kubernetes baseline with the fewest moving parts and the clearest debugging surface.
- **Options considered:**
  - Apply upstream manifests (`deploy/kubernetes/manifests`) ✅
  - Install via Helm (`deploy/kubernetes/helm-chart`)
- **Chosen option + why:** Manifests keep the baseline closest to upstream and make it easier to understand what is created in the cluster without Helm indirection.
- **Verification / evidence:** After preflight checks, `kubectl apply -n sock-shop -f deploy/kubernetes/manifests` succeeded and the workloads became "Ready" (confirmed in Phase 01 docs + evidence screenshot).
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

## Phase 02 — Ingress baseline: host-based Traefik routing to the Sock Shop storefront

**Quick recap (Phase 02)**  
- Phase 02 added a more **production-like, host-based storefront entrypoint** on the local k3s cluster by introducing a **Traefik Ingress** for `http://sockshop.local/`, while keeping the already proven **port-based NodePort `30001`** path intact as fallback.  
- This was done by adding **one dedicated local-only ingress manifest** at `deploy/kubernetes/manifests-local/phase-02-front-end-ingress.yaml` (instead of patching the upstream Sock Shop Service manifests).  
- The purpose of this new manifest was **to create a Kubernetes Ingress resource** that tells Traefik: 
  -**Requests for host `sockshop.local` on path `/`** should be routed to the Sock Shop **`front-end` Service on port `80`**.  
- Keeping this routing rule in a separate local-only manifest preserved the upstream defaults, avoided unnecessary changes to the existing `front-end` Service, and left the Phase 01 NodePort fallback fully intact.

**Proof Steps**  
- The first proof step was a **manual Host-header `curl` test**:
  - `curl -I -H 'Host: sockshop.local' http://127.0.0.1`
  - This showed that **Traefik already routed requests correctly to the `front-end` Service** before any browser-side hostname resolution existed.
- A browser test with the same hostname (`http://sockshop.local/`) still failed at that point with `DNS_PROBE_FINISHED_NXDOMAIN`, which showed that the routing rule itself worked, but local hostname resolution was still missing.
- The second proof step was **adding a local `/etc/hosts` mapping**:
  - `127.0.0.1 sockshop.local`
  - After that, the same hostname worked in the browser via `http://sockshop.local/`.

**Primary evidence (Phase 02)**  
- Browser screenshot before local hostname mapping: `project-docs/02-ingress-baseline/evidence/[2026-03-19]-sockshop.local-Storefront-1_before-hosts-edit_not-found.png`  
- Browser screenshot after local hostname mapping: `project-docs/02-ingress-baseline/evidence/[2026-03-19]-sockshop.local-Storefront-2_after-hosts-edit_loaded.png`

**Further details**  
- Implementation log: `project-docs/02-ingress-baseline/IMPLEMENTATION.md`  
- Runbook: `project-docs/02-ingress-baseline/RUNBOOK.md`

**Conclusion + Next steps**  
- Phase 02 proved that the storefront can be reached through a **host-based ingress route on port `80`**, while the **port-based NodePort `30001`** path remains available as a known-good fallback.
- This gives the project a more production-like local entrypoint and prepares the path for later environment work (CI/CD, production exposure, and eventual service-type hardening).
- **Note (security):** In a later production-style target environment, the **`front-end` Service should move from `NodePort` to `ClusterIP`**, so traffic is governed only through the ingress layer.

---

### Decision (P02-D01): primary local storefront entrypoint = host-based Traefik Ingress, with NodePort retained as fallback
- **Decision:** Use a host-based Traefik Ingress (`sockshop.local`) as the primary local storefront entrypoint for Phase 02, while keeping NodePort `30001` unchanged as a proven fallback / rollback path.
- **Context / problem:** Phase 01’s NodePort baseline worked, but it remained port-based, less production-like, and less suitable as a long-term “front door” for a storefront. The next capability needed to add a domain-style entrypoint on standard HTTP port `80` without breaking the already working baseline.
- **Options considered:**
  - Keep NodePort `30001` as the only storefront entrypoint
  - Use host-based Traefik Ingress for the storefront ✅
  - Use port-forward / temporary-only access
- **Chosen option + why:** Host-based Traefik Ingress provides a domain-like entrypoint on standard HTTP port `80`, matches real deployment patterns better, and still preserves the known NodePort fallback for low-risk rollback and troubleshooting.
- **Verification / evidence:**  
  - Showing the created Ingress resource and its bound address via `kubectl get ingress -n sock-shop -o wide` produced
    - `front-end`, class `traefik`, host `sockshop.local`, and address `192.168.178.57`  
  - A detailed inspection of the Ingress via `kubectl describe ingress -n sock-shop front-end` proved backend routing to `front-end:80`  
  - `curl -I -H 'Host: sockshop.local' http://127.0.0.1` returned `HTTP/1.1 200 OK`  
  - Opening a browser and trying to request the storefront via `http://sockshop.local/` initially produced a Non-Existent Domain Error (`DNS_PROBE_FINISHED_NXDOMAIN`)
  - After adding a local `/etc/hosts` mapping (`127.0.0.1 sockshop.local`), `curl -I http://sockshop.local/` returned `HTTP/1.1 200 OK` and the browser loaded the storefront successfully
  - Browser evidence screenshots are recorded in the Phase 02 evidence folder
- **Consequences / follow-ups:**  
  - NodePort `30001` remains the known-good fallback entrypoint for local troubleshooting and rollback  
  - for a later production-style environment, the `front-end` Service should move from `NodePort` to `ClusterIP` so the ingress layer becomes the only external entrypoint



## (Further entries will be added to record technical choices)
