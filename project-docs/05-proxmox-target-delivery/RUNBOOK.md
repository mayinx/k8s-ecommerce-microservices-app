# ▶️ Runbook — Phase 05 (Proxmox Target Delivery): real Proxmox-backed K3s target, dev/prod ingress, Cloudflare public edge, and GitHub Actions delivery

> ## 👤 About
> This document is the short rerun guide for **Phase 05 (Proxmox Target Delivery)**.
> It is meant as a quick rerun reference without the long-form diary.
>
> For the top-level Phase 05 implementation story and subphase navigation, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.
> For setup-only prerequisites around Cloudflare onboarding, DNS delegation, tunnel creation, connector installation, and GitHub/Tailscale preparation, see: **[SETUP.md](./SETUP.md)**.
> For phase-scoped rationale and outcome notes, see: **[DECISIONS.md](./DECISIONS.md)**.
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**.

---

## Index (top-level)

- [**Goal**](#goal)
- [**Preconditions**](#preconditions)
- [**Phase 05-A — Target VM and cluster baseline**](#phase-05-a--target-vm-and-cluster-baseline)
  - [**Step 1 — Recreate the Proxmox target VM (`9200`) from the workload-ready template (`9010`)**](#step-1--recreate-the-proxmox-target-vm-9200-from-the-workload-ready-template-9010)
  - [**Step 2 — Confirm guest baseline and K3s control-plane readiness on the target VM**](#step-2--confirm-guest-baseline-and-k3s-control-plane-readiness-on-the-target-vm)
  - [**Step 3 — Refresh the target-side repository checkout and confirm the Phase 05 deployment inputs**](#step-3--refresh-the-target-side-repository-checkout-and-confirm-the-phase-05-deployment-inputs)
- [**Phase 05-B — Environment deployment baseline**](#phase-05-b--environment-deployment-baseline)
  - [**Step 4 — Apply the `dev` overlay on the real target cluster**](#step-4--apply-the-dev-overlay-on-the-real-target-cluster)
  - [**Step 5 — Apply the `prod` overlay on the real target cluster**](#step-5--apply-the-prod-overlay-on-the-real-target-cluster)
- [**Phase 05-C — Ingress and private operator access**](#phase-05-c--ingress-and-private-operator-access)
  - [**Step 6 — Verify local/private ingress routing for `dev` and `prod` through Traefik**](#step-6--verify-localprivate-ingress-routing-for-dev-and-prod-through-traefik)
  - [**Step 7 — Verify tailnet-based cluster access from the workstation**](#step-7--verify-tailnet-based-cluster-access-from-the-workstation)
- [**Phase 05-D — Public edge and workflow-driven delivery**](#phase-05-d--public-edge-and-workflow-driven-delivery)
  - [**Step 8 — Verify the public Cloudflare edge for both environments**](#step-8--verify-the-public-cloudflare-edge-for-both-environments)
  - [**Step 9 — Run the Phase 05 workflow on `master` and approve the `prod` deployment gate**](#step-9--run-the-phase-05-workflow-on-master-and-approve-the-prod-deployment-gate)
  - [**Step 10 — Verify the final target state after the workflow-driven deployments**](#step-10--verify-the-final-target-state-after-the-workflow-driven-deployments)
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
- the private tailnet-based operator path to the cluster works from the workstation
- the public Cloudflare hostnames resolve to working HTTPS application endpoints
- the GitHub Actions workflow reaches the private target cluster through Tailscale + kubeconfig
- the workflow deploys `dev` automatically and `prod` after approval on the real target cluster

---

## Preconditions

- the Phase 04 workload-ready template VM **`9010`** exists on Proxmox
- VMID **`9200`** is free, or an earlier Phase 05 target VM has already been removed
- Proxmox shell access works
- SSH access to the target VM works after first boot
- the local repository checkout contains the finalized Phase 05 source state
- the Cloudflare, DNS, Tunnel, connector, Tailscale, and GitHub secret/environment setup from **[SETUP.md](./SETUP.md)** is already complete
- the GitHub repository contains:
  - `.github/workflows/phase-05-target-delivery.yaml`
  - `deploy/kubernetes/manifests/03-carts-db-dep.yaml`
  - `deploy/kubernetes/manifests/13-orders-db-dep.yaml`
  - `deploy/kubernetes/kustomize/overlays/dev/front-end-ingress.yaml`
  - `deploy/kubernetes/kustomize/overlays/prod/front-end-ingress.yaml`
- the required GitHub secrets and environments already exist for the workflow path:
  - `TS_OAUTH_CLIENT_ID`
  - `TS_OAUTH_SECRET`
  - `KUBECONFIG_PROXMOX_TARGET`
  - `dev` environment
  - `prod` environment with approval gate
- the public hostnames already exist in Cloudflare and are routed through the healthy tunnel:
  - `dev-sockshop.cdco.dev`
  - `prod-sockshop.cdco.dev`

> [!NOTE] **🧩 Placeholder warning**
>
> The commands below contain environment-specific placeholders such as `REPLACE_WITH_TARGET_VM_IP_OR_TAILNET_IP`.
> Replace them before execution.
> Do not paste real tunnel tokens, kubeconfig content, or other secrets into repository-tracked files.

---

## Phase 05-A — Target VM and cluster baseline

### Step 1 — Recreate the Proxmox target VM (`9200`) from the workload-ready template (`9010`)

**Rationale:** Phase 05 is anchored to a real Proxmox-backed target rather than to a local-only smoke cluster. The clean rerun path therefore starts by cloning the proven workload-ready template into the dedicated target VM slot used by this phase.

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

### Step 2 — Confirm guest baseline and K3s control-plane readiness on the target VM

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

### Step 3 — Refresh the target-side repository checkout and confirm the Phase 05 deployment inputs

**Rationale:** The target cluster should deploy from the actual Phase 05 source state, not from an older checkout left on the VM. Refreshing the repository on the target ensures that the ingress resources, workflow-aligned overlays, and the MongoDB compatibility pin are the same ones that will later be exercised by GitHub Actions.

~~~bash
# Move into the target-side repository checkout and align it with the current mainline Phase 05 state.
$ cd ~/k8s-ecommerce-microservices-app
$ git fetch origin
$ git checkout master
$ git reset --hard origin/master
...

# Re-check the MongoDB image pin directly on the target checkout.
$ grep -n 'image: mongo:3.4' deploy/kubernetes/manifests/03-carts-db-dep.yaml
...
$ grep -n 'image: mongo:3.4' deploy/kubernetes/manifests/13-orders-db-dep.yaml
...

# Re-check that both overlays include their ingress resource.
$ grep -n 'front-end-ingress.yaml' deploy/kubernetes/kustomize/overlays/dev/kustomization.yml
...
$ grep -n 'front-end-ingress.yaml' deploy/kubernetes/kustomize/overlays/prod/kustomization.yml
...
~~~

**Success looks like:**

- the target checkout aligns cleanly with `origin/master`
- the target checkout shows the `mongo:3.4` pin in both MongoDB-backed Deployments
- both overlays reference `front-end-ingress.yaml`

---

## Phase 05-B — Environment deployment baseline

### Step 4 — Apply the `dev` overlay on the real target cluster

**Rationale:** With the target VM, the cluster, and the Phase 05 source state now aligned, the first environment can be applied directly from source control. This runbook intentionally uses the final source-controlled environment overlay rather than replaying the earlier raw-manifest troubleshooting detour from the implementation diary.

~~~bash
# Stay in the target-side repository checkout.
$ cd ~/k8s-ecommerce-microservices-app

# Ensure the dev namespace object from source control exists.
$ sudo kubectl apply -f deploy/kubernetes/kustomize/overlays/dev/namespace.yaml
...

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
~~~

**Success looks like:**

- the `sock-shop-dev` namespace exists
- the dev overlay applies without error
- all dev Deployments become `Available`
- `sock-shop-dev` contains running pods, services, and the `front-end` ingress

---

### Step 5 — Apply the `prod` overlay on the real target cluster

**Rationale:** The production environment should follow the same happy-path pattern as `dev` instead of inheriting the temporary asymmetry from the implementation trail. This keeps the rerun path cleaner and closer to how the environment pair would normally be established.

~~~bash
# Stay in the target-side repository checkout.
$ cd ~/k8s-ecommerce-microservices-app

# Ensure the prod namespace object from source control exists.
$ sudo kubectl apply -f deploy/kubernetes/kustomize/overlays/prod/namespace.yaml
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

- the `sock-shop-prod` namespace exists
- the prod overlay applies without error
- all prod Deployments become `Available`
- `sock-shop-prod` contains running pods, services, and the `front-end` ingress

---

## Phase 05-C — Ingress and private operator access

### Step 6 — Verify local/private ingress routing for `dev` and `prod` through Traefik

**Rationale:** Before checking the public Cloudflare edge, it is useful to prove that Traefik already routes both final public hostnames correctly on the target-side ingress path. That keeps cluster-side ingress verification separate from public-edge publication.

~~~bash
# Run these checks from a workstation that can already reach the VM directly.
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
- Traefik routes both final public hostnames correctly before Cloudflare is tested

---

### Step 7 — Verify tailnet-based cluster access from the workstation

**Rationale:** The workflow-driven deployment path later approaches the cluster as an external tailnet node, not from inside the VM itself. A workstation-side cluster check is therefore the most useful private-access proof before the GitHub Actions runner is allowed to do the same.

~~~bash
# Confirm the local workstation is on the tailnet.
$ tailscale status
...

# If needed, bring the workstation onto the tailnet.
$ sudo tailscale up
...

# Confirm the target VM is reachable over the tailnet.
$ ping -c 4 REPLACE_WITH_TARGET_TAILNET_IP
...

# If the kubeconfig is not present locally yet, copy it from the target VM.
$ mkdir -p ~/.kube
$ chmod 700 ~/.kube
$ scp ubuntu@REPLACE_WITH_TARGET_TAILNET_IP:/home/ubuntu/kubeconfig-proxmox-dev.yaml ~/.kube/config-proxmox-dev.yaml
$ chmod 600 ~/.kube/config-proxmox-dev.yaml

# Confirm that the local kubeconfig points at the tailnet-reachable API endpoint.
$ grep 'server:' ~/.kube/config-proxmox-dev.yaml
server: https://REPLACE_WITH_TARGET_TAILNET_IP:6443

# Query the real cluster through the tailnet path.
$ KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get nodes -o wide
...
$ KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get namespace sock-shop-dev sock-shop-prod
...
~~~

**Success looks like:**

- the target VM replies over the tailnet path
- the workstation-side kubeconfig points at the tailnet API endpoint
- the workstation can query the real target cluster
- both application namespaces are visible as `Active`

---

## Phase 05-D — Public edge and workflow-driven delivery

### Step 8 — Verify the public Cloudflare edge for both environments

**Rationale:** Once the target-side ingress path and the private operator path are both known-good, the public HTTPS checks can focus purely on the Cloudflare publication layer.

~~~bash
# Check the public dev hostname through the Cloudflare edge.
$ curl -I https://dev-sockshop.cdco.dev
HTTP/2 200
...

# Check the public prod hostname through the Cloudflare edge.
$ curl -I https://prod-sockshop.cdco.dev
HTTP/2 200
...
~~~

**Success looks like:**

- both HTTPS endpoints answer successfully
- both public hostnames resolve to working application paths
- browser rendering also works for both environments

---

### Step 9 — Run the Phase 05 workflow on `master` and approve the `prod` deployment gate

**Rationale:** In the finalized happy path, the real workflow proof no longer needs to be split across a feature-branch `dev` proof and a later `master` proof. The short rerun path can go straight to the final intended workflow shape on `master`, where `dev` deploys automatically and `prod` remains approval-gated.

Use one of these two paths.

### Manual GitHub UI path

- Go to: `Repository -> Actions -> phase-05-proxmox-target-delivery`
- Click: **Run workflow**
- Run it from:
  - `master`

### Push-driven path

~~~bash
# Push the current branch state to master to trigger the workflow.
$ git checkout master
$ git pull --ff-only origin master
$ git push origin master
~~~

Then in GitHub Actions:

- open the running `phase-05-proxmox-target-delivery` workflow on `master`
- confirm that `validate-overlays` runs
- confirm that `build-push-support-images` runs
- confirm that `deploy-dev-smoke` runs automatically
- wait until the workflow pauses at the `prod` environment gate
- select **Review deployments**
- select **Approve and deploy**

**Success looks like:**

- the Phase 05 workflow runs on `master`
- `validate-overlays` succeeds
- `build-push-support-images` succeeds
- `deploy-dev-smoke` succeeds against the real target cluster
- the workflow pauses at the `prod` deployment gate
- `deploy-prod-smoke` starts only after approval is accepted
- the workflow run ends successfully

---

### Step 10 — Verify the final target state after the workflow-driven deployments

**Rationale:** Once the workflow has completed, the final proof is the live target state itself: both namespaces should still be healthy, both ingress objects should still exist, and both public HTTPS endpoints should still answer successfully.

~~~bash
# Inspect the final dev resources on the real target cluster.
$ KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get deploy,pods,svc,ingress -n sock-shop-dev -o wide
...

# Inspect the final prod resources on the real target cluster.
$ KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get deploy,pods,svc,ingress -n sock-shop-prod -o wide
...

# Re-check the public endpoints after the workflow-driven deployments.
$ curl -I https://dev-sockshop.cdco.dev
HTTP/2 200
...
$ curl -I https://prod-sockshop.cdco.dev
HTTP/2 200
...
~~~

**Success looks like:**

- both namespaces remain healthy on the target cluster
- both `front-end` ingress objects are still present
- both public HTTPS endpoints still answer successfully after the workflow-driven deployment path

---

## Cleanup / rerun

- **Normal reuse path:** keep VM `9200`, K3s, the Cloudflare Tunnel, the Tailscale path, and the GitHub environment/secrets configuration in place
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
- `project-docs/05-proxmox-target-delivery/evidence/`
- `project-docs/DEBUG-LOG.md`

### Files modified in this phase

- `.github/workflows/phase-03-delivery.yaml`
- `deploy/kubernetes/manifests/03-carts-db-dep.yaml`
- `deploy/kubernetes/manifests/13-orders-db-dep.yaml`
- `deploy/kubernetes/kustomize/overlays/dev/kustomization.yml`
- `deploy/kubernetes/kustomize/overlays/prod/kustomization.yml`
- `project-docs/DECISIONS.md`
- `project-docs/INDEX.md`
- `project-docs/ROADMAP.md`

### Files removed in this phase

- none