# 🧭 Runbook (TL;DR) - Phase 02 (Ingress Baseline): Host-based Traefik route for Sock Shop

> ## 👤 About
> This runbook is the short, command-first version of the Phase 02 Ingress baseline work.  
> It’s meant as a quick reference for reruns without the long-form diary.  
> For the full narrative log (incl. reasoning, observations, and evidence context), see: **[02-ingress-baseline/IMPLEMENTATION.md](IMPLEMENTATION.md)**.

---

## 📌 Index (top-level)

**- [Goal](#goal)**  
**- [Preconditions](#preconditions)**  
**- [Step 0 — Re-check the existing baseline](#step-0--re-check-the-existing-baseline)**  
**- [Step 1 — Triage the ingress surface](#step-1--triage-the-ingress-surface)**  
**- [Step 2 — Create the ingress manifest](#step-2--create-the-ingress-manifest)**  
**- [Step 3 — Apply and inspect](#step-3--apply-and-inspect)**  
**- [Step 4 — Verify the route before editing `/etc/hosts`](#step-4--verify-the-route-before-editing-etchosts)**  
**- [Step 5 — Add local name resolution for browser use](#step-5--add-local-name-resolution-for-browser-use)**  
**- [Cleanup / rollback](#cleanup--rollback)**  
**- [Useful proof commands (reduced set)](#useful-proof-commands-reduced-set)**  
**- [Sources](#sources)**

---

## Goal

Expose the Sock Shop storefront through the local k3s Traefik ingress controller via:

- `http://sockshop.local/`

while keeping the existing Phase 01 NodePort fallback on:

- `http://localhost:30001/`

---

## Preconditions

- local k3s cluster is running
- `kubectl` is configured
- Sock Shop is already deployed in namespace `sock-shop`
- Phase 01 baseline still works on `http://localhost:30001/`

---

## Step 0 — Re-check the existing baseline

**Rationale:** Confirm the storefront already works before adding a new routing layer.

~~~bash
# Show cluster nodes and their reachable addresses
kubectl get nodes -o wide

# Show Sock Shop Pods in the target namespace
kubectl get pods -n sock-shop

# Show the existing front-end Service and confirm the fixed NodePort
kubectl get svc -n sock-shop front-end -o wide

# Verify that the known Phase 01 fallback entrypoint still works
curl -I http://localhost:30001/
~~~

Expected result:

- node is `Ready`
- Sock Shop pods are `Running`
- `front-end` is still `80:30001/TCP`
- `curl` returns `HTTP/1.1 200 OK`

---

## Step 1 — Triage the ingress surface

**Rationale:** Confirm Traefik is present and no existing Ingress rules already occupy the intended host.

~~~bash
# Show available IngressClass resources
kubectl get ingressclass

# Show Traefik-related Pods across all namespaces
kubectl get pods -A | grep -i traefik

# Show the Traefik Service and its exposed ports
kubectl get svc -A | grep -i traefik

# Show all current Ingress resources cluster-wide
kubectl get ingress -A -o wide

# Send a request with an unknown Host header to confirm Traefik is answering on port 80
curl -I -H 'Host: does-not-exist.local' http://127.0.0.1/
~~~

Expected result:

- ingress class `traefik` exists
- Traefik pod and Service exist in `kube-system`
- no existing Ingress resources use `sockshop.local`
- the unknown Host request returns Traefik `404 Not Found`

---

## Step 2 — Create the ingress manifest

**Rationale:** Add one minimal Ingress object only. Do not change the existing `front-end` Service.

~~~bash
# Create a folder for local-only helper manifests used in this phase
mkdir -p deploy/kubernetes/manifests-local

# Create or edit the local-only storefront Ingress manifest
nano deploy/kubernetes/manifests-local/phase-02-front-end-ingress.yaml
~~~

File content:

~~~yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: front-end
  namespace: sock-shop
spec:
  ingressClassName: traefik
  rules:
    - host: sockshop.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: front-end
                port:
                  number: 80
~~~

---

## Step 3 — Apply and inspect

**Rationale:** Confirm the created Ingress points to the intended backend before testing browser-style access.

~~~bash
# Apply the new local-only storefront Ingress manifest
kubectl apply -f deploy/kubernetes/manifests-local/phase-02-front-end-ingress.yaml

# Show the created Ingress resource and its assigned address
kubectl get ingress -n sock-shop -o wide

# Inspect the Ingress in detail: class, host, path, and backend Service
kubectl describe ingress -n sock-shop front-end
~~~

Expected result:

- Ingress is created successfully
- class = `traefik`
- host = `sockshop.local`
- backend = `front-end:80`

---

## Step 4 — Verify the route before editing `/etc/hosts`

**Rationale:** Test the ingress rule itself before adding local name resolution.

~~~bash
# Simulate a browser request by sending the correct Host header to localhost:80
curl -I -H 'Host: sockshop.local' http://127.0.0.1

# Fetch the first lines of the returned HTML to confirm the storefront is served
curl -s -H 'Host: sockshop.local' http://127.0.0.1 | head -n 10
~~~

Expected result:

- `HTTP/1.1 200 OK`
- `X-Powered-By: Express`
- storefront HTML is returned

**Why this works before the browser works:**  
**These `curl` commands manually provide both parts Traefik needs for routing:**
**(1) the target IP (`127.0.0.1`) and**
**(2) the HTTP `Host` header (`sockshop.local`).**
**The browser can only do the same after the operating system can resolve `sockshop.local` locally.**

---

## Step 5 — Add local name resolution for browser use

**Rationale:** The browser needs the operating system to resolve `sockshop.local` to an IP address.

Open the hosts file:

~~~bash
# Open the local hosts file for manual hostname mapping
sudo nano /etc/hosts
~~~

Add:

~~~text
# --- K8S CAPSTONE PROJECT: SOCK SHOP ---
# Routes local traffic to the Traefik Ingress Controller
127.0.0.1   sockshop.local
# ----------------------------------------
~~~

Then verify:

~~~bash
# Confirm that the local hostname now resolves to 127.0.0.1
getent hosts sockshop.local

# Verify that the hostname-based browser URL now returns HTTP 200
curl -I http://sockshop.local/

# Fetch the first lines of the storefront HTML via the hostname-based URL
curl -s http://sockshop.local/ | head -n 10
~~~

Expected result:

- `sockshop.local` resolves to `127.0.0.1`
- `curl` returns `HTTP/1.1 200 OK`
- storefront HTML is returned

Now open the browser:

~~~text
http://sockshop.local/
~~~

Evidence to capture:

- browser screenshot before hosts edit: `not found`
- browser screenshot after hosts edit: storefront loaded

**Captured evidence files:**
- **`[2026-03-19]-sockshop.local-Storefront-1_before-hosts-edit_not-found.png`**
- **`[2026-03-19]-sockshop.local-Storefront-2_after-hosts-edit_found.png`**

---

## Cleanup / rollback

**Rationale:** Remove the Ingress and local host mapping while preserving the Phase 01 fallback path.

Delete the ingress:

~~~bash
# Delete the local-only storefront Ingress manifest
kubectl delete -f deploy/kubernetes/manifests-local/phase-02-front-end-ingress.yaml

# Confirm that no Ingress resources remain for this phase
kubectl get ingress -A -o wide
~~~

Remove the `sockshop.local` line from `/etc/hosts` manually:

~~~bash
# Open the hosts file and remove the local Sock Shop mapping manually
sudo nano /etc/hosts
~~~

Re-check the fallback path:

~~~bash
# Confirm that the original Phase 01 NodePort fallback still works
curl -I http://localhost:30001/

# Fetch the first lines of the storefront HTML via the fallback NodePort URL
curl -s http://localhost:30001/ | head -n 5
~~~

---

## Useful proof commands (reduced set)

~~~bash
# Show the created Ingress and its bound address
kubectl get ingress -n sock-shop -o wide

# Inspect the Ingress host rule and backend mapping
kubectl describe ingress -n sock-shop front-end

# Prove host-based routing works before editing /etc/hosts
curl -I -H 'Host: sockshop.local' http://127.0.0.1

# Prove local hostname resolution works after editing /etc/hosts
getent hosts sockshop.local

# Prove the browser-style hostname URL returns the storefront
curl -I http://sockshop.local/
~~~

---
 