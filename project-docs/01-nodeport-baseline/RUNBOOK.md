# 🧭 Runbook (TL;DR) - Phase 01 (Local Cluster Baseline): Clean port-based Sock Shop deploy on k3s (NodePort, conflict-free)

> ## 👤 About
> This runbook is the short, command-first version of the Phase 01 local k3s baseline deploy of Sock Shop.  
> It’s meant as a quick reference for reruns without the long-form diary.  
> For the full narrative log, see: **[01-local-k3s-baseline/IMPLEMENTATION.md](IMPLEMENTATION.md)**.

---
---

## 📌 Index (top-level)
- [Preflight: NodePort collision check (30001)](#preflight-nodeport-collision-check-30001)
- [Namespace: create + reset](#namespace-create--reset)
- [Deploy: apply upstream manifests](#deploy-apply-upstream-manifests)
- [Verify: pods + storefront](#verify-pods--storefront)
- [Cleanup: remove Sock Shop only](#cleanup-remove-sock-shop-only)

---

## Preflight: NodePort collision check (30001)

~~~bash
# NodePort collisions are cluster-wide → check all namespaces (-A)
# -o wide shows the "80:30001/TCP" mapping in the output (needed to spot the conflict)
kubectl get svc -A -o wide | grep -E '(:30001/| 30001/|30001:)' || true
~~~

If a Service already occupies `30001` and it’s not needed anymore, delete it using:

~~~bash
# Schema:
# kubectl delete svc -n <NAMESPACE> <SERVICE_NAME>
# F.i.:
kubectl delete svc -n datascientest wordpress
~~~

Re-check that `30001` is free:

~~~bash
kubectl get svc -A -o wide | grep -E '(:30001/| 30001/|30001:)' || true
~~~

---

## Create `sock-shop`-Namespace + clean rerun procedure 

~~~bash
# Create namespace (safe if it already exists)
kubectl create namespace sock-shop || true

# For clean reruns: Remove prior attempts in this namespace  (safe to rerun; avoids touching unrelated workloads)
kubectl delete all --all -n sock-shop --wait=false || true
kubectl delete pvc,cm,secret,ingress,networkpolicy,serviceaccount,role,rolebinding --all -n sock-shop --wait=false || true

# Optional: confirm empty
kubectl get all -n sock-shop
~~~

---

## Deploy Sock Shop: Apply upstream manifests

~~~bash
# Apply upstream manifests into the namespace (-n)
kubectl apply -n sock-shop -f deploy/kubernetes/manifests
~~~

---

## Verify: pods + storefront

~~~bash
# Watch until pods settle into Running/Ready
kubectl get pods -n sock-shop -w

# Evidence snapshot after pods settle (proves readiness + NodePort assignment)
kubectl get pods -n sock-shop -o wide
kubectl get svc  -n sock-shop -o wide
~~~

Get node IP (needed for NodePort access):

~~~bash
kubectl get nodes -o wide
~~~

Open storefront:

- `http://<NODE_INTERNAL_IP>:30001/`
- On single-node local k3s, this also commonly works: `http://localhost:30001/`

---

## Cleanup: remove Sock Shop only

Use this when done poking around and a clean rerun is desired:

~~~bash
# Default stop (keeps namespace, removes workloads):
# Remove core workload resources in the namespace (safe for reruns)
kubectl delete all --all -n sock-shop --wait=false || true
 
# Full reset: 
# Also remove common namespace-scoped objects that "kubectl delete all" does not cover
kubectl delete pvc,cm,secret,ingress,networkpolicy,serviceaccount,role,rolebinding --all -n sock-shop --wait=false || true
 
# Optional: delete the namespace itself entirely (clean slate)
# Use this when the namespace should be fully removed and recreated later
kubectl delete namespace sock-shop || true
~~~

