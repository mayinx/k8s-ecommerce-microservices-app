# 🧱 Implementation Log — # Phase 01 (Local Cluster Baseline): Clean Sock Shop deploy on k3s (conflict-free)

> ## 👤 About
> This document is the implementation log ("build diary") for **Phase 01 (Local k3s Cluster Baseline)**.  
> For a "TL;DR command checklist and quick setup guide", see: **[01-local-k3s-baseline/RUNBOOK.md](RUNBOOK.md)**.

---

## 📌 Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done (Phase 01)**](#definition-of-done-phase-01)
- [**Preconditions**](#preconditions)
- [**Step 0 — Preflight: NodePort collision check**](#step-0--preflight-nodeport-collision-check)
- [**Step 1 — Create the `sock-shop` namespace (deployment boundary)**](#step-1--create-the-sock-shop-namespace-deployment-boundary)
- [**Step 2 — Deploy Sock Shop (upstream manifests)**](#step-2--deploy-sock-shop-upstream-manifests)
- [**Step 3 — Verify storefront reachability (baseline: NodePort)**](#step-3--verify-storefront-reachability-baseline-nodeport)
- [**Step 4 — Cleanup**](#step-4--clean-shutdown--cleanup)
- [**Baseline observations and evidence (Phase 01)**](#baseline-observations-and-evidence-phase-01)
- [**Sources**](#sources)

---


## Purpose / Goal 

Establish a reproducible baseline deployment of Sock Shop on a local k3s cluster using the repo’s Kubernetes manifests (without modifying upstream manifest content).

## Definition of done (Phase 01)

- Sock Shop is deployed into a dedicated namespace (`sock-shop`)
- All workloads in that namespace are `Running` / `Ready`
- The storefront is reachable via the intended access method (**NodePort 30001**)

---

## Preconditions

- `kubectl` configured to talk to your local k3s cluster (`kubectl get nodes` works)
- Traefik is the default k3s ingress controller (typical k3s default) — here not required for NodePort access

### Port expectations (storefront vs monitoring) 

Based on `deploy/kubernetes/README.md`:

- **Storefront** (this Phase 01): **NodePort `30001`** → `front-end` UI  
- **So `:3000` is not the storefront here.** 
  - `:3000` becomes relevant only when deploying the monitoring stack (Grafana), as documented in `deploy/kubernetes/README.md`:
    - **Grafana NodePort: `31300`**
    - **Prometheus NodePort: `31090`**
  - Typical access pattern on “real” clusters is port-forwarding / SSH tunnel so Grafana appears on `http://localhost:3000` and Prometheus on `http://localhost:9090`:
  ~~~bash
  ssh -i $KEY -L 3000:$NODE_IN_CLUSTER:31300 -L 9090:$NODE_IN_CLUSTER:31090 ubuntu@$BASTION_IP
  ~~~

---

## Step 0 — Preflight: NodePort collision check 

**Rationale:** Avoid a cluster-wide NodePort collision before applying upstream manifests. The Sock Shop storefront Service pins NodePort `30001`, so an existing Service using `30001` will block the deploy at `Service/front-end`.

> **🧩 Info box — NodePort**  
> NodePort is a **Kubernetes Service type** that **opens a fixed TCP port on the node** and **forwards traffic to the Service inside the cluster**.  
It is used here because the upstream Sock Shop manifests expose the storefront via a fixed NodePort `30001`.  
A namespace isolates resources (Deployments/Services/etc.) but **does not isolate NodePort numbers**: NodePort allocation is **cluster-wide**.  
That is why a collision can happen even with a dedicated `sock-shop` namespace.

The upstream manifests define the Sock Shop storefront Service (`front-end`) with a fixed NodePort: 30001:

~~~yaml
# deploy/kubernetes/manifests/10-front-end-svc.yaml

apiVersion: v1
kind: Service
metadata:
  name: front-end                 # Service name (stable endpoint inside the cluster: http://front-end.sock-shop.svc:80)
  annotations:
    prometheus.io/scrape: 'true'  # Legacy Prometheus scrape hint (only used if your Prometheus setup honors these annotations)
  labels:
    name: front-end               # Label attached to the Service object (NOT the same as the selector below)
  namespace: sock-shop            # Deploys the Service into the sock-shop namespace

spec:
  type: NodePort                  # Exposes this Service on every node IP at a fixed TCP port (nodePort)
  ports:
  - port: 80                      # Service port inside the cluster (clients talk to front-end:80)
    targetPort: 8079              # Pod/container port on the selected front-end Pods (the app listens on 8079)
    nodePort: 30001               # Fixed NodePort on the node (http://<node-ip>:30001 -> Service:80 -> Pod:8079)
  selector:
    name: front-end               # Selects Pods with label "name=front-end" (must match the Deployment's pod labels)
~~~



If any existing Service already uses NodePort `30001`, the `front-end` Service creation will fail with:

~~~bash
The Service "front-end" is invalid: spec.ports[0].nodePort: Invalid value: 30001: provided port is already allocated
~~~

To prevent this, we check if Sock Shop’s default NodePort is already allocated:

~~~bash
# Show any Service anywhere that already occupies NodePort 30001
# -A = all namespaces (NodePort collisions are cluster-wide)
# -o wide = include the NodePort column (shows mappings like "80:30001/TCP")
kubectl get svc -A -o wide | grep -E '(:30001/| 30001/|30001:)'
datascientest   wordpress            NodePort       10.43.171.200   <none>           80:30001/TCP                 20d     app=wordpress
~~~

If there is a conflicting Service (like in the example above) and it is not needed, it can be removed to free the port; 
schema: 

`kubectl delete svc -n <NAMESPACE> <SERVICE_NAME>`

~~~bash
# Example: a previous exercise used NodePort 30001
kubectl delete svc -n datascientest wordpress
~~~

To verify 30001 is free now:

~~~bash
kubectl get svc -A -o wide | grep -E '(:30001/| 30001/|30001:)' || true
~~~

> Alternative approach (not used in Phase 01): change Sock Shop’s NodePort to a free port via a local-only override.  
> For Phase 01, the simplest reproducible baseline is: **free 30001** and deploy upstream manifests unchanged.


## Step 1 — Create the `sock-shop` namespace (deployment boundary)

**Rationale:** Deploying Sock Shop into its own dedicated namespace (`sock-shop`) keeps the capstone isolated from unrelated exercises and makes reset + reapply safe and predictable. 

> **Note:** namespaces don’t prevent cluster-wide collisions (e.g., NodePort numbers), so we still need that preflight (s. above).

Create the namespace (idempotent rerun safe - ok if it already exists):

~~~bash
$ kubectl create namespace sock-shop || true
namespace/sock-shop created
~~~

On reruns: Remove any prior Sock Shop attempt inside the namespace:

~~~bash
$ kubectl delete all --all -n sock-shop --wait=false || true
§ kubectl delete pvc,cm,secret,ingress,networkpolicy,serviceaccount,role,rolebinding --all -n sock-shop --wait=false || true
~~~

(Optional) Confirm it’s empty:

~~~bash
$ kubectl get all -n sock-shop
~~~

---

## Step 2 — Deploy Sock Shop (upstream manifests)

Apply the Kubernetes manifests shipped with the repo:

~~~bash
# Apply upstream manifests into the sock-shop namespace (-n), without modifying the repo’s YAMLs
$ kubectl apply -n sock-shop -f deploy/kubernetes/manifests
deployment.apps/carts created
service/carts created
deployment.apps/carts-db created
service/carts-db created
deployment.apps/catalogue created
service/catalogue created
---
~~~

Watch pods until up and stable:

~~~bash
# -w keeps watching until pods settle into Running/Ready
$ kubectl get pods -n sock-shop -w
NAME                            READY   STATUS    RESTARTS   AGE
carts-5f5859c84b-mbdhz          1/1     Running   ---        ---
carts-db-544c5bc9c8-lz844       1/1     Running   ---        ---
catalogue-cd4ff8c9f-flb9j       1/1     Running   ---        ---
catalogue-db-74885c6d4c-q9wsm   1/1     Running   ---        ---
front-end-7467866c7b-nz6fw      1/1     Running   ---        ---
orders-6b8dd47986-bltbc         1/1     Running   ---        ---
orders-db-5d7db99c6-z9l6g       1/1     Running   ---        ---
payment-c5fbdbc6-zf2gv          1/1     Running   ---        ---
queue-master-7f965677fb-jknv6   1/1     Running   ---        ---
rabbitmq-59955f8bff-dc6ks       2/2     Running   ---        ---
session-db-5d89f4b5bb-f5c98     1/1     Running   ---        ---
shipping-868cd6587d-vxtgs       1/1     Running   ---        ---
user-67488ff854-jlxdl           1/1     Running   ---        ---
user-db-7bd86cdcd-h8bql         1/1     Running   ---        ---
~~~

---

Evidence snapshot:

~~~bash
# Evidence snapshot after pods settle (proves readiness + NodePort assignment)
$ kubectl get pods -n sock-shop -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP           NODE            NOMINATED NODE   READINESS GATES
carts-5f5859c84b-mbdhz          1/1     Running   0          ---   10.42.0.17   ideapad-x-x-x   <none>           <none>
carts-db-544c5bc9c8-lz844       1/1     Running   0          ---   10.42.0.18   ideapad-x-x-x   <none>           <none>
catalogue-cd4ff8c9f-flb9j       1/1     Running   0          ---   10.42.0.19   ideapad-x-x-x   <none>           <none>
catalogue-db-74885c6d4c-q9wsm   1/1     Running   0          ---   10.42.0.20   ideapad-x-x-x   <none>           <none>
front-end-7467866c7b-nz6fw      1/1     Running   0          ---   10.42.0.21   ideapad-x-x-x   <none>           <none>
orders-6b8dd47986-bltbc         1/1     Running   0          ---   10.42.0.22   ideapad-x-x-x   <none>           <none>
orders-db-5d7db99c6-z9l6g       1/1     Running   0          ---   10.42.0.23   ideapad-x-x-x   <none>           <none>
payment-c5fbdbc6-zf2gv          1/1     Running   0          ---   10.42.0.24   ideapad-x-x-x   <none>           <none>
queue-master-7f965677fb-jknv6   1/1     Running   0          ---   10.42.0.25   ideapad-x-x-x   <none>           <none>
rabbitmq-59955f8bff-dc6ks       2/2     Running   0          ---   10.42.0.26   ideapad-x-x-x   <none>           <none>
session-db-5d89f4b5bb-f5c98     1/1     Running   0          ---   10.42.0.27   ideapad-x-x-x   <none>           <none>
shipping-868cd6587d-vxtgs       1/1     Running   0          ---   10.42.0.28   ideapad-x-x-x   <none>           <none>
user-67488ff854-jlxdl           1/1     Running   0          ---   10.42.0.29   ideapad-x-x-x   <none>           <none>
user-db-7bd86cdcd-h8bql         1/1     Running   0          ---   10.42.0.30   ideapad-x-x-x   <none>           <none>

$ kubectl get svc  -n sock-shop -o wide
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE   SELECTOR
carts          ClusterIP   10.43.244.32    <none>        80/TCP              ---   name=carts
carts-db       ClusterIP   10.43.157.55    <none>        27017/TCP           ---   name=carts-db
catalogue      ClusterIP   10.43.231.94    <none>        80/TCP              ---   name=catalogue
catalogue-db   ClusterIP   10.43.128.159   <none>        3306/TCP            ---   name=catalogue-db
front-end      NodePort    10.43.34.203    <none>        80:30001/TCP        ---   name=front-end
orders         ClusterIP   10.43.81.139    <none>        80/TCP              ---   name=orders
orders-db      ClusterIP   10.43.33.32     <none>        27017/TCP           ---   name=orders-db
payment        ClusterIP   10.43.188.175   <none>        80/TCP              ---   name=payment
queue-master   ClusterIP   10.43.201.36    <none>        80/TCP              ---   name=queue-master
rabbitmq       ClusterIP   10.43.97.166    <none>        5672/TCP,9090/TCP   ---   name=rabbitmq
session-db     ClusterIP   10.43.176.119   <none>        6379/TCP            ---   name=session-db
shipping       ClusterIP   10.43.239.228   <none>        80/TCP              ---   name=shipping
user           ClusterIP   10.43.194.177   <none>        80/TCP              ---   name=user
user-db        ClusterIP   10.43.144.36    <none>        27017/TCP           ---   name=user-db
~~~


## Step 3 — Verify storefront reachability (baseline: NodePort)

Determine node IP (needed for NodePort access):

~~~bash
kubectl get nodes -o wide
NAME                      STATUS   ROLES           AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
ideapad-x-x-x   Ready    control-plane   23d   v1.34.3+k3s3   192.168.178.57   <none>        Ubuntu 24.04.3 LTS   6.17.0-14-generic   containerd://2.1.5-k3s1
~~~

Open the storefront using that IP:

- `http://<NODE_INTERNAL_IP>:30001/`

Example:

- `http://192.168.178.57:30001/`

FYI: In this setup here (single-node local k3s cluster) the access via localhost:30001 works as well:

- `http://localhost:30001/`

> **Note:** Why can the storefront be reached via `http://localhost:30001/`?
> On a single-node local k3s cluster, the “node” is this machine. NodePort opens a port on the node itself (the machien running k3s), so the storefront is reachable via both the node IP _and_ `localhost`:
- `http://<NODE_INTERNAL_IP>:30001/` (LAN path)
- `http://localhost:30001/` (loopback path)
> On multi-node clusters or stricter networking, prefer `http://<NODE_INTERNAL_IP>:30001/`.

**Evidence:**

The browser loads the Sock Shop storefront UI:

![Screenshot of storefront reachable on port 30001](evidence/[2026-03-09]-Port-30001_Storefront.png)
*Figure 1: Storefront reachable via local port 30001 (http://192.168.178.57:30001/)*

---

## Step 4 — Clean shutdown / cleanup

**Rationale:** Leave the cluster in a known state. A scoped cleanup enables clean reruns without touching unrelated exercises.

### Default stop (keeps namespace, removes workloads)
~~~bash
# Remove core workload resources in the namespace (safe for reruns)
kubectl delete all --all -n sock-shop --wait=false || true
~~~

### Full reset (also removes typical namespace-scoped objects)
~~~bash
# Also remove common namespace-scoped objects that "kubectl delete all" does not cover
kubectl delete pvc,cm,secret,ingress,networkpolicy,serviceaccount,role,rolebinding --all -n sock-shop --wait=false || true
~~~

### Optional: delete the namespace itself entirely (clean slate)
~~~bash
# Use this when the namespace should be fully removed and recreated later
kubectl delete namespace sock-shop || true
~~~

---

## Baseline observations and evidence (Phase 01)

### What was deployed
Sock Shop was deployed from `deploy/kubernetes/manifests` into the namespace `sock-shop`, including the `front-end` Service exposed as NodePort `30001` (per `10-front-end-svc.yaml`).

**Decision (baseline):** Use **upstream manifests** for Phase 01 to stay conflict-free and reproducible; **evaluate Helm later** once the cluster baseline is stable.

### What was verified
- All Sock Shop pods in `sock-shop` reached `Running/Ready`.
- The storefront UI was reachable via `http://<node-ip>:30001/` (NodePort baseline).
- A known NodePort collision source (`30001`) was explicitly checked and resolved before apply.

### Evidence index
- E-01 — Storefront reachable (NodePort 30001): `evidence/[2026-03-09]-Port-30001_Storefront.png`

#### Artifacts captured:
  - Screenshots under `docs/01-baseline/evidence/`

---

## Sources

### Kubernetes deploy + monitoring ports
- Repo doc (k8s deploy + monitoring ports):
  `deploy/kubernetes/README.md`

### Kubernetes Services / NodePort
- Kubernetes Docs — Services (Service types incl. NodePort):  
  https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport

- Aqua Security — Kubernetes service types overview (includes NodePort explanation):  
  https://www.aquasec.com/cloud-native-academy/kubernetes-101/kubernetes-services/

### k3s defaults (context)
- k3s Docs — Packaged components / Helm add-ons (Traefik is managed as an add-on):  
  https://docs.k3s.io/helm
 