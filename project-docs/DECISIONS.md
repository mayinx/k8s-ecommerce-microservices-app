# Decision Log ("ADR Lite")

Purpose: Capture **phase-scoped technical decisions** (with context + alternatives) so they remain quick to review without re-reading the full implementation logs. 

> **Hint:** This log contains consolidated project-phase related decision summaries only (“ADR-lite”); durable cross-phase standards live in `adr/` as full ADRs.

Decisions in this project are made along an explicit, **phase-based delivery path**; therefore this log also records that delivery path and its guiding principles as the reference frame and foundation for later decisions.

## Index

- [**Foundation decision: Phase-based DevOps delivery approach**](#foundation-decision-phase-based-devops-delivery-approach)
- [**Phase 00 — Compose + Repo Baseline**](#phase-00--compose--repo-baseline)
- [**Phase 01 — Port-based local cluster baseline (k3s): Deploy Sock Shop via NodePort and prove the baseline works**](#phase-01--port-based-local-cluster-baseline-k3s-deploy-sock-shop-via-nodeport-and-prove-the-baseline-works)
- [**Phase 02 — Ingress baseline: Host-based Traefik routing to the Sock Shop storefront**](#phase-02--ingress-baseline-host-based-traefik-routing-to-the-sock-shop-storefront)
- [**Phase 03 — CI/CD baseline: GitHub Actions delivery smoke path for dev/prod**](#phase-03--cicd-baseline-github-actions-delivery-smoke-path-for-devprod)
- [**Phase 04 — Proxmox VM Baseline**](#phase-04-proxmox-vm-baseline-generic-ubuntu-vm-template-smoke-vm-and-workload-ready-vm-template)
- [**Phase 05 — Proxmox Target Delivery: Real target VM, public edge, and workflow-driven delivery**](#phase-05-proxmox-target-delivery-real-target-vm-public-edge-and-workflow-driven-delivery)
- [**Phase 06 — Observability & Health**](#phase-06--observability--health)

---


## Template (when adding a new phase to this global decisions log)

### Quick recap
- Starting point:
- Obstacle / constraint: *(only if relevant)*
- Chosen path:
- Verified result:
- Why this matters next: *(short, if useful)*

### Key decisions
- `Pxx-Dyy` — <short decision title>
  - Decision:
  - Why:
  - Proof:
  - Next-step impact:

### Notes
- Keep the global phase entry condensed and scan-friendly.
- Detailed rationale, fuller trade-offs, and stronger evidence stay in the phase-local `DECISIONS.md`.

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

The initial phases use Docker Compose and a local k3s cluster to establish a stable local baseline before moving to the long-lived target environment (Proxmox). This way, compelxity is isolated to later phases:

- Proxmox will add extra moving parts (VM networking, firewall rules, DNS, storage, TLS) that make failures slower to debug. This complexity should not be introduced early. 
- A local k3s baseline proves the the deployment path (app deploy -> service exposure -> routing) quickly and repeatedly on the same machine, with clear evidence and fast rollback. 
- Only once a path is proven it makes sense to apply the same approach to Proxmox - and debug the Proxmox-Phase separately if necessary.
- Local baselines also help to surface and remove potential environment hazards early:  
  - Even if deployment assets already exist in the repository, they are not guaranteed to run conflict-free on a given cluster. 
  - In a local k3s lab, cluster-wide resources (NodePorts, Ingress host/path rules, Traefik routing) can collide with leftovers from other exercises 

### Phase progression (so far):

- Phase 00 proved a working application baseline via Compose (fastest triage surface).
- Phase 01 proved a clean local k3s Kubernetes baseline via upstream manifests (minimal moving parts).
- Phase 02 added host-based Ingress without removing the already proven NodePort fallback.
- Phase 03 proved a real CI/CD smoke-delivery path for `dev` / `prod`.
- Phase 04 established the first reusable Proxmox-backed VM baseline through a reusable template plus a verified smoke VM.

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

## Phase 00 — Compose + Repo Baseline

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

## Phase 01 — Port-based local cluster baseline (k3s): Deploy Sock Shop via NodePort and prove the baseline works

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

## Phase 02 — Ingress baseline: Host-based Traefik routing to the Sock Shop storefront

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

## Phase 03 — CI/CD baseline: GitHub Actions delivery smoke path for dev/prod

### Quick recap (Phase 03)

####  Starting point: Phase 03 needed a real delivery baseline

Phase 03 needed a real CI/CD baseline for the project’s `dev` / `prod` delivery path.

#### Obstacle 1: Helm was not a viable baseline at this point

The repository’s Helm chart was evaluated first, but even after fetching the missing dependency, the install path still failed because the pulled `nginx-ingress` subchart relied on deprecated Kubernetes API versions.

### Solution / Chosen path: Reuse the proven raw manifests and add a thin Kustomize environment layer - along with GitHub Actions + hosted runners + kind

The chosen path was therefore:

- reuse the already proven raw manifests
- add a thin Kustomize layer for `dev` and `prod`
- use GitHub Actions with GitHub-hosted runners
- use `kind` as the temporary Kubernetes smoke target
- use GitHub Environments with a required-reviewer gate for `prod`

This made it possible to introduce environment separation **without rewriting or duplicating the full manifest set**.

### Obstacle 2: The repo-owned `openapi` image target failed and had to be deferred / excluded from workflow  

The first workflow run surfaced a legacy `openapi` build problem. That auxiliary target was excluded for now, while `healthcheck` remained in scope as the repo-owned support image for the baseline.

### Verified result: Successful dev + prod smoke delivery through GitHub Actions Pipeline

The phase successfully proved:

- automated `dev` smoke deployment
- approval-gated `prod` smoke deployment
- a delivery path that remains easy to retarget later to Proxmox

The successfulyl implemented CI/CD smoke path works like this:

1. validate the `dev` / `prod` overlays
2. build and push the repo-owned `healthcheck` image to GHCR
3. deploy the `dev` smoke environment automatically
4. pause before `prod`
5. require approval through the GitHub `prod` environment
6. deploy the `prod` smoke environment after approval

This gives the repository a real delivery baseline before moving to the final infrastructure target.

## Conclusion + Next steps  
- Phase 03 proved the delivery mechanics cleanly without depending on the final target environment yet.
- The next major step is to retarget the proven delivery path toward the real long-lived environment and continue with the remaining requirements:
  - IaC / target infrastructure
  - monitoring
  - security hardening
  - DR / rollback

---

## Phase 04 (Proxmox VM Baseline): Generic Ubuntu VM Template, smoke VM, and workload-ready VM template

### Quick recap (Phase 04)

#### Starting point: Phase 04 needed a real Proxmox-backed VM baseline

Before moving the application path toward the long-lived target environment, the project first needed a proven VM baseline on the provided Proxmox host.

#### Chosen path: first prove a generic Proxmox Cloud-Init template workflow (VM Template `9000` + Smoke VM `9100`), then qualify it for as sock-shop deployment target (VM Template `9010`)  

#### Phase 04 first standardized on the Proxmox Cloud-Init template workflow teh VM Template `9000` and the Smoke VM `9100`:

1. stage a Cloud-Init-capable Ubuntu image on the host
2. convert that image into a reusable Proxmox VM template (**VM template `9000`**)
3. clone a smoke VM from that template (**Smoke VM `9100`**)
4. verify the result on the host and inside the guest
    - successful guest login
    - successful Cloud-Init completion
    - visible enlarged guest root filesystem
    - working outbound connectivity from inside the guest

This established the generic reusable VM baseline cleanly - following the base workflow Proxmox itself recommends for fast rollout of reusable VM instances.

#### The phase then finalized a workload-ready baseline VM template before Phase 05 (VM Template `9010`) as base for Phase 05 

Notable features of VM template `9010`:

- private host-bridged guest network via `vmbr1`
- host-side NAT, with forwarding and masquerading out through `vmbr0`
- stable private guest addressing (`<redacted-gateway-ip>0/24`) and deterministic routing via default gateway `<redacted-gateway-ip>`
- deterministic DNS via resolver `1.1.1.1`
- working outbound HTTPS reachability for later bootstrap, package-retrieval and target-side setup tasks
- guest-agent capability
- more practical disk / CPU / memory baseline
- cleaned Cloud-Init state before template conversion
- persisted host-side `vmbr1` network configuration and NAT rules

This gives the project a real workload-ready Proxmox VM baseline that later phases can build on.

#### Final artifact roles

- `9000` = generic Ubuntu cloud-image baseline template
- `9100` = initial smoke-validation clone from the generic baseline
- `9010` = workload-ready baseline template variant finalized during Phase 04 - as base for Phase 05

#### Verified result

Phase 04 now proves:

- reusable Proxmox VM template `9000`
- smoke VM `9100` cloned from that template
- successful generic smoke validation
- workload-ready baseline template `9010` finalized before Phase 05

## Conclusion + Next steps
- Phase 04 proved the generic Proxmox baseline and then finalized a workload-ready template variant inside the same phase.
- The next major step is to start target-side application deployment from `9010`.

---

## Phase 05 (Proxmox Target Delivery): Real target VM, public edge, and workflow-driven delivery

### Quick recap (Phase 05)

#### Starting point: Phase 05 needed to turn the proven Proxmox VM baseline into a real delivery target

Phase 04 ended with the **workload-ready Proxmox template `9010`**, but the project still needed a persistent target VM, a real Kubernetes control plane on that target, a public edge for the two environments, and a CI/CD path that reached the long-lived platform instead of a temporary smoke target.

#### First obstacle: the first target-side deployment surfaced a MongoDB AVX/runtime incompatibility

The first application deployment on the real target cluster showed that the overall stack almost converged, but `carts-db` and `orders-db` failed because the unpinned Kubernetes image reference `mongo` pulled a newer MongoDB version that required AVX support.

That issue was resolved by pinning both affected Deployments to:

- `mongo:3.4`

and then persisting that fix in source control.

#### Chosen path: keep the proven Kubernetes/Kustomize deployment model and evolve it into a real `dev` / `prod` target layout

Instead of changing the deployment model during the target move, Phase 05 kept the proven Kubernetes/Kustomize path and built the real target-delivery story on top of it:

- real target VM `9200`, cloned from workload-ready template `9010`
- K3s as single-node control plane on that target
- explicit environment namespaces:
  - `sock-shop-dev`
  - `sock-shop-prod`
- built-in K3s Traefik as ingress controller
- host-based routing for both environments

#### Private access and public exposure were deliberately separated

Phase 05 also standardized on two distinct traffic models:

- **Tailscale** for private operator and CI/CD access to the cluster API
- **Cloudflare Tunnel** for public HTTPS exposure of:
  - `dev-sockshop.cdco.dev`
  - `prod-sockshop.cdco.dev`

This avoided public exposure of the Kubernetes API and avoided opening inbound application ports directly on the VM.

#### Workflow model: preserve the earlier CI/CD milestone, but create a dedicated real-target workflow

Instead of overwriting the Phase 03 baseline workflow, Phase 05 preserved that earlier CI/CD milestone and added a dedicated Phase 05 workflow for the real target-delivery path.

This keeps the chronology understandable:

- Phase 03 = CI/CD mechanics baseline
- Phase 05 = real target-delivery workflow

#### Verified result

Phase 05 now proves:

- real target VM `9200`
- single-node K3s control plane on that target
- source-controlled MongoDB compatibility fix
- `dev` / `prod` namespace separation on the real target
- working Traefik ingress for both environments
- public HTTPS exposure through Cloudflare Tunnel
- private tailnet-based external cluster access
- automated `dev` deployment and approval-gated `prod` deployment on the real target cluster

The phase also **establishes the first stable public environment URLs** on the long-lived target platform:

- **Development:** `https://dev-sockshop.cdco.dev/`
- **Production:** `https://prod-sockshop.cdco.dev/`

## Conclusion + Next steps

- Phase 05 completed the move from the reusable Proxmox VM baseline to a **real target-delivery platform**.
- The next major step is no longer target bootstrap, but **observability** on top of the now-proven long-lived environment.
- Later security and DR work should build on the already established:
  - environment model
  - ingress layer
  - private access path
  - public edge
  - and workflow-driven delivery path

---

## Phase 06 — Observability & Health

Phase 06 established the first real observability baseline on top of the Proxmox-based target cluster.

### Quick recap (Phase 06)

#### Starting point: The project needed the first useful monitoring layer on the real target

After Phase 05, the project already had:

- A proxmox-based target VM
- A working single-Nnode K3s nontrol plane
- Namespace-based `dev` / `prod` application delivery via a Github Actions CI/CD-Pipeline
- Private operator access and public application exposure

At that point, the project could already deploy and expose the application, but it still lacked the operational visibility needed to inspect cluster health, workload behavior, and monitoring health on the live target.

#### Obstacle: The existing repository monitoring material was not the right baseline for this phase

The repository already contained older monitoring-related material under:

- `deploy/kubernetes/manifests-monitoring/`
- `deploy/kubernetes/manifests-alerting/`

That path was a weaker fit for the first observability baseline because it was more fragmented, more manual, and more NodePort-oriented than needed here. It also aligned less well with the project’s later direction away from NodePort as a primary access model.

#### Chosen path: Use maintained `kube-prometheus-stack` in a dedicated `monitoring` namespace

Phase 06 therefore standardized on the maintained Helm chart **`kube-prometheus-stack`** and installed it into a dedicated `monitoring` namespace

This provided a faster and cleaner route to the first working observability baseline by bundling the core monitoring components into one integrated install path.

#### Constraint: Monitoring access should remain private-only in Phase 06

Phase 06 needed operator access to Grafana and Prometheus to prove the monitoring baseline, but it did not need a public monitoring surface yet.

A public monitoring route would have introduced additional ingress, DNS, TLS, and hardening scope that was not required for the first baseline.

#### Chosen path: Keep Grafana and Prometheus private via `kubectl port-forward`

Grafana and Prometheus were therefore accessed privately through **`kubectl port-forward`** over the already working Tailnet-based kubeconfig path.

This reused the proven operator-access path from earlier phases and kept the monitoring surface private.

#### Verified result: The first observability baseline is proven on the live target

By the end of Phase 06, the project had proven:

- A running monitoring namespace on the real target
- A successful `kube-prometheus-stack` deployment
- Private Grafana access through `kubectl port-forward`
- Private Prometheus access through `kubectl port-forward`
- Namespace-level workload visibility for `sock-shop-prod`
- Healthy core monitoring targets on the Prometheus `/targets` page

#### Why this matters next

The project is no longer only deployable and reachable on the real target. It is now also observable and inspectable, which gives later phases a stronger basis for security work, Infrastructure as Code, and DR / rollback planning.

### Key decisions

#### P06-D01 — Observability baseline = maintained `kube-prometheus-stack` in dedicated `monitoring` namespace

Use the maintained Helm chart **`kube-prometheus-stack`** as the Phase-06 observability baseline and install it into the dedicated namespace `monitoring`.

#### P06-D02 — First rollout scope = intentionally small and private-only

Keep the first monitoring rollout intentionally narrow:

- Alertmanager disabled
- Default alert rules disabled
- Short prometheus retention
- Ephemeral storage
- Conservative resource requests and limits
- No public monitoring ingress

#### P06-D03 — Grafana credential handling = tracked non-secret values + gitignored local Helm override + chart-managed Kubernetes Secret

Keep non-secret Helm values in the tracked baseline file, inject the Grafana admin password through a gitignored local Helm override, and let the chart create the resulting Kubernetes Secret inside the cluster.

#### P06-D04 — Access model = private `kubectl port-forward` over the existing Tailnet path

Access Grafana and Prometheus privately through **`kubectl port-forward`** over the already working Tailnet-based kubeconfig path instead of creating a public monitoring ingress route in Phase 06.

#### P06-D05 — Verification model = dashboard proof + scrape-target proof + light recent traffic

Count Phase 06 as successful only when the monitoring baseline is proven through successful stack deployment, private Grafana access, dashboard-based workload visibility, Prometheus scrape-target health, and recent storefront traffic that makes current activity visible.

---


## (Further entries will be added to record technical choices)
