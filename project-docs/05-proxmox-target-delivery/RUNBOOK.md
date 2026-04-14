# ▶️ Runbook — Phase 05 (Proxmox Target Delivery): real Proxmox-backed K3s target, dev/prod ingress, Cloudflare public edge, and GitHub Actions delivery

> ## 👤 About
> This document is the short rerun guide for **Phase 05 (Proxmox Target Delivery)**.
> It is meant as a quick rerun reference without the long-form diary.
> 
> For the top-level Phase 05 implementation story and subphase navigation, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.
> For setup-only prerequisites around Cloudflare onboarding, DNS delegation, tunnel creation, and connector installation, see: **[SETUP.md](./SETUP.md)**.
> For phase-scoped rationale and outcome notes, see: **[DECISIONS.md](./DECISIONS.md)**.
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**.

---

## Index (top-level)

- [**Goal**](#goal)
- [**Preconditions**](#preconditions)
- [**Step 1 — Recreate the Proxmox target VM (`9200`) from the workload-ready template (`9010`)**](#step-1--recreate-the-proxmox-target-vm-9200-from-the-workload-ready-template-9010)
- [**Step 2 — Confirm guest baseline and K3s control-plane readiness on the target VM**](#step-2--confirm-guest-baseline-and-k3s-control-plane-readiness-on-the-target-vm)
- [**Step 3 — Refresh the target-side repository checkout and confirm the Phase 05 deployment inputs**](#step-3--refresh-the-target-side-repository-checkout-and-confirm-the-phase-05-deployment-inputs)
- [**Step 4 — Apply the `dev` and `prod` overlays on the real target cluster**](#step-4--apply-the-dev-and-prod-overlays-on-the-real-target-cluster)
- [**Step 5 — Verify private ingress routing on the target path before public edge checks**](#step-5--verify-private-ingress-routing-on-the-target-path-before-public-edge-checks)
- [**Step 6 — Verify the public Cloudflare edge for both environments**](#step-6--verify-the-public-cloudflare-edge-for-both-environments)
- [**Step 7 — Run the Phase 05 GitHub Actions delivery workflow**](#step-7--run-the-phase-05-github-actions-delivery-workflow)
- [**Step 8 — Approve the `prod` deployment and verify the final target state**](#step-8--approve-the-prod-deployment-and-verify-the-final-target-state)
- [**Cleanup / rerun**](#cleanup--rerun)
- [**Files added / modified in this phase**](#files-added--modified-in-this-phase)

---

## Goal

Re-run the verified **Phase 05 target-delivery baseline** so that:

- a real Proxmox-backed target VM (`9200`) is created from the Phase 04 workload-ready template (`9010`)
- that VM becomes a working single-node K3s control-plane host
- the Phase 05 source state is present on the target, including the MongoDB compatibility pin and the environment ingress resources
- the `sock-shop-dev` and `sock-shop-prod` overlays deploy successfully on the real cluster
- Traefik routes both environments correctly on the target side
- the public Cloudflare hostnames resolve to working HTTPS application endpoints
- the GitHub Actions workflow reaches the private target cluster through Tailscale + kubeconfig and completes the `dev` deployment automatically
- the `prod` deployment still requires approval and succeeds after that gate is approved

---

## Preconditions

- the Phase 04 workload-ready template VM **`9010`** exists on Proxmox
- VMID **`9200`** is free, or an earlier Phase 05 target VM has already been removed
- Proxmox shell access works
- SSH access to the target VM works after first boot
- the local repository checkout contains the Phase 05 source state
- the Cloudflare, DNS, Tunnel, connector, and public-hostname setup from **[SETUP.md](./SETUP.md)** is already complete
- the GitHub repository contains:
  - `.github/workflows/phase-05-target-delivery.yaml`
  - `deploy/kubernetes/manifests/03-carts-db-dep.yaml`
  - `deploy/kubernetes/manifests/13-orders-db-dep.yaml`
  - `deploy/kubernetes/kustomize/overlays/dev/front-end-ingress.yaml`
  - `deploy/kubernetes/kustomize/overlays/prod/front-end-ingress.yaml`
- the required GitHub secrets and environment settings already exist for the workflow path:
  - `TS_OAUTH_CLIENT_ID`
  - `TS_OAUTH_SECRET`
  - `KUBECONFIG_PROXMOX_TARGET`
  - `dev` environment
  - `prod` environment with approval gate

> [!NOTE] **🧩 Placeholder warning**
>
> The commands below contain environment-specific placeholders such as `REPLACE_WITH_TARGET_VM_IP_OR_TAILNET_IP`.
> Replace them before execution. Do not paste real tunnel tokens, kubeconfig content, or other secrets into repository-tracked files.

---

## Step 1 — Recreate the Proxmox target VM (`9200`) from the workload-ready template (`9010`)

**Rationale:** Phase 05 is anchored to a real target VM rather than to a local-only smoke cluster. The clean rerun path therefore starts by cloning the proven workload-ready template into the dedicated target VM slot used by this phase.

~~~bash
# Clone the workload-ready Phase 04 template into the dedicated Phase 05 target VM slot.
# `--full 1` creates a full clone instead of a linked clone.
$ qm clone 9010 9200 --full 1

# Keep the proven VirtIO NIC model for this VM.
$ qm set 9200 --net0 virtio

# Start the new target VM.
$ qm start 9200

# Show the current VM inventory and the new VM configuration.
$ qm list --full
...
$ qm config 9200
...
~~~

**Success looks like:**

- VM `9200` exists in `qm list --full`
- `qm config 9200` shows a valid root disk and Cloud-Init drive
- the VM reaches the `running` state

---

## Step 2 — Confirm guest baseline and K3s control-plane readiness on the target VM

**Rationale:** Once the VM exists, the next step is to confirm that the guest is usable as the real Kubernetes target. This means guest login must work, the storage layout must be healthy, and K3s must already expose a Ready node with the system workloads running.

~~~bash
# Connect to the target VM.
$ ssh ubuntu@REPLACE_WITH_TARGET_VM_IP_OR_TAILNET_IP

# Show the guest identity and basic storage layout.
$ hostnamectl
...
$ lsblk
...

# Confirm that the K3s service is active on the target node.
$ sudo systemctl status k3s --no-pager
...

# Show the node inventory.
# `-o wide` adds useful node details such as internal IP and OS image.
$ sudo kubectl get nodes -o wide
NAME     STATUS   ROLES                  AGE   VERSION   INTERNAL-IP   ...
...

# Show all pods across all namespaces.
# `-A` means "all namespaces".
$ sudo kubectl get pods -A
NAMESPACE     NAME                                     READY   STATUS    ...
...
~~~

**Success looks like:**

- guest login works
- the root disk layout looks plausible
- `k3s.service` is active
- the target node is `Ready`
- the cluster system pods are running

---

## Step 3 — Refresh the target-side repository checkout and confirm the Phase 05 deployment inputs

**Rationale:** The target cluster should deploy from the actual Phase 05 source state, not from an older checkout left on the VM. Refreshing the repository on the target ensures that the ingress resources, workflow-aligned overlays, and MongoDB pin are the same ones that will later be exercised by GitHub Actions.

~~~bash
# Move into the target-side repository checkout and refresh it from the main branch.
$ cd ~/k8s-ecommerce-microservices-app
$ git pull origin master
...

# Re-check the MongoDB image pin directly on the target checkout.
$ grep -n 'image: mongo:3.4' deploy/kubernetes/manifests/03-carts-db-dep.yaml
...
$ grep -n 'image: mongo:3.4' deploy/kubernetes/manifests/13-orders-db-dep.yaml
...

# Re-check that both overlays include the ingress resource.
$ grep -n 'front-end-ingress.yaml' deploy/kubernetes/kustomize/overlays/dev/kustomization.yml
...
$ grep -n 'front-end-ingress.yaml' deploy/kubernetes/kustomize/overlays/prod/kustomization.yml
...
~~~

**Success looks like:**

- the target checkout updates cleanly from `master`
- the target checkout still shows the `mongo:3.4` pin
- the target checkout still shows both `front-end-ingress.yaml` references

---

## Step 4 — Apply the `dev` and `prod` overlays on the real target cluster

**Rationale:** At this point the target VM, the cluster, and the Phase 05 source state are all aligned. The next useful step is to apply the final environment model directly on the real target cluster and wait until both namespaces converge successfully.

~~~bash
# Stay in the target-side repository checkout.
$ cd ~/k8s-ecommerce-microservices-app

# Apply the dev overlay.
# `-k` tells kubectl to render and apply the Kustomize overlay.
$ sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/dev
...

# Wait until all Deployments in the dev namespace become Available.
# `--for=condition=available` waits for the Kubernetes Deployment availability condition.
$ sudo kubectl wait --namespace sock-shop-dev --for=condition=available deployment --all --timeout=300s
...

# Show the resulting dev resources, including the ingress object.
$ sudo kubectl get deploy,pods,svc,ingress -n sock-shop-dev -o wide
...

# Apply the prod overlay.
$ sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/prod
...

# Wait until all Deployments in the prod namespace become Available.
$ sudo kubectl wait --namespace sock-shop-prod --for=condition=available deployment --all --timeout=300s
...

# Show the resulting prod resources, including the ingress object.
$ sudo kubectl get deploy,pods,svc,ingress -n sock-shop-prod -o wide
...
~~~

**Success looks like:**

- both overlays apply without error
- both namespaces contain running pods and services
- both namespaces contain a `front-end` ingress resource
- the Deployment wait commands finish successfully for both environments

---

## Step 5 — Verify private ingress routing on the target path before public edge checks

**Rationale:** Before checking the public Cloudflare edge, it is useful to prove that Traefik already routes both hostnames correctly on the private target path. That separates cluster-side ingress issues from edge-publication issues.

~~~bash
# Run these checks from a workstation that can already reach the VM over the private path.
# The `Host:` header forces Traefik to evaluate the same hostnames that the public edge will use later.
$ curl -I -H 'Host: dev-sockshop.cdco.dev' http://REPLACE_WITH_TARGET_VM_IP_OR_TAILNET_IP/
HTTP/1.1 200 OK
...

$ curl -I -H 'Host: prod-sockshop.cdco.dev' http://REPLACE_WITH_TARGET_VM_IP_OR_TAILNET_IP/
HTTP/1.1 200 OK
...
~~~

**Success looks like:**

- both requests return a healthy HTTP response from the storefront path
- the response differs only by environment hostname, not by routing behavior

---

## Step 6 — Verify the public Cloudflare edge for both environments

**Rationale:** Once the private ingress path is known-good, the public HTTPS checks can focus on the Cloudflare publication layer itself. This confirms that the domain, tunnel, published routes, and connector all align with the target cluster.

~~~bash
# Check the public dev hostname through the Cloudflare edge.
$ curl -I https://dev-sockshop.cdco.dev/
HTTP/2 200
...

# Check the public prod hostname through the Cloudflare edge.
$ curl -I https://prod-sockshop.cdco.dev/
HTTP/2 200
...
~~~

**Success looks like:**

- both HTTPS endpoints answer successfully
- both public hostnames resolve to working application paths
- browser rendering also works for both environments

---

## Step 7 — Run the Phase 05 GitHub Actions delivery workflow

**Rationale:** The final delivery proof for this phase is not only manual target-side deployment but also automated remote delivery. The verified Phase 05 workflow must therefore validate the overlays, build and push the repo-owned support image, join the private tailnet, load the target kubeconfig, and deploy the `dev` environment automatically.

Use one of these two paths.

### Manual GitHub UI path

- Go to: `Repository -> Actions -> phase-05-proxmox-target-delivery`
- Click: **Run workflow**
- Run it from:
  - `master`

### Push-driven path

~~~bash
# Push the current branch state to the default branch to trigger the workflow.
$ git push origin master
~~~

**Success looks like:**

- `validate-overlays` succeeds
- `build-push-support-images` succeeds
- `deploy-dev-smoke` succeeds
- the workflow pauses before the `prod` deployment gate

---

## Step 8 — Approve the `prod` deployment and verify the final target state

**Rationale:** Phase 05 is only fully proven once the approval-gated production path is exercised as well. After the gate is approved, both the GitHub workflow result and the live cluster state should show the final end state for `dev` and `prod`.

In GitHub Actions:

- open the waiting workflow run
- review the `prod` deployment gate
- approve the deployment

Then re-check the live target cluster.

~~~bash
# Inspect the final dev resources on the target cluster.
$ sudo kubectl get deploy,pods,svc,ingress -n sock-shop-dev -o wide
...

# Inspect the final prod resources on the target cluster.
$ sudo kubectl get deploy,pods,svc,ingress -n sock-shop-prod -o wide
...

# Re-check the public endpoints once the workflow has completed.
$ curl -I https://dev-sockshop.cdco.dev/
HTTP/2 200
...
$ curl -I https://prod-sockshop.cdco.dev/
HTTP/2 200
...
~~~

**Success looks like:**

- the workflow run ends successfully
- `prod` starts only after the approval gate is accepted
- both namespaces remain healthy on the target cluster
- both public HTTPS endpoints still answer successfully after the workflow-driven deployment path

---

## Cleanup / rerun

- **Normal reuse path:** keep VM `9200`, K3s, the Cloudflare Tunnel, and the GitHub environment/secrets configuration in place
- **Application-only reset on the target cluster:**

~~~bash
# Remove the two environment namespaces while keeping the VM and K3s baseline.
$ sudo kubectl delete namespace sock-shop-dev
$ sudo kubectl delete namespace sock-shop-prod
~~~

- **Full Phase 05 target reset on Proxmox:** remove VM `9200`, then rerun from Step 1

~~~bash
# Stop and remove the dedicated Phase 05 target VM.
$ qm stop 9200
$ qm destroy 9200 --destroy-unreferenced-disks 1 --purge 1
~~~

- **Workflow preservation rule:** keep `.github/workflows/phase-03-delivery.yaml` as the earlier historical milestone and `.github/workflows/phase-05-target-delivery.yaml` as the active real-target path

---

## Files added / modified in this phase

### Files added in this phase

- `.github/workflows/phase-05-target-delivery.yaml`
- `deploy/kubernetes/kustomize/overlays/dev/front-end-ingress.yaml`
- `deploy/kubernetes/kustomize/overlays/prod/front-end-ingress.yaml`
- `project-docs/05-proxmox-target-delivery/SETUP.md`
- `project-docs/05-proxmox-target-delivery/IMPLEMENTATION.md`
- `project-docs/05-proxmox-target-delivery/RUNBOOK.md`
- `project-docs/05-proxmox-target-delivery/DECISIONS.md`
- `project-docs/05-proxmox-target-delivery/implementation/PHASE-05-A.md`
- `project-docs/05-proxmox-target-delivery/implementation/PHASE-05-B.md`
- `project-docs/05-proxmox-target-delivery/implementation/PHASE-05-C.md`
- `project-docs/05-proxmox-target-delivery/implementation/PHASE-05-D.md`
- `project-docs/05-proxmox-target-delivery/evidence/...`

### Files modified in this phase

- `deploy/kubernetes/manifests/03-carts-db-dep.yaml`
- `deploy/kubernetes/manifests/13-orders-db-dep.yaml`
- `deploy/kubernetes/kustomize/overlays/dev/kustomization.yml`
- `deploy/kubernetes/kustomize/overlays/prod/kustomization.yml`
- `README.md`
- `project-docs/DECISIONS.md`
- `project-docs/INDEX.md`
- `project-docs/DEBUG-LOG.md`

### Files removed in this phase

- none