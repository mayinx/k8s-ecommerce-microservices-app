# Project Debug Log & Incident Reports

This document tracks technical anomalies discovered during deployment, the investigation process, and the resulting architectural decisions.

---

## [Issue 01] MongoDB AVX Compatibility / CrashLoop (Phase 05)

During the initial deployment of the Sock Shop baseline to the Proxmox K3s cluster, two specific backend services failed to initialize.

### Observed Behavior
While the majority of the stack entered a `Running` state immediately, the database pods for the Carts and Orders services remained trapped in a restart cycle.

~~~bash
$ sudo kubectl get pods -n sock-shop
NAME                            READY   STATUS             RESTARTS
carts-db-544c5bc9c8-2jtgs       0/1     CrashLoopBackOff   10 (57s ago)
orders-db-5d7db99c6-7bmtb       0/1     CrashLoopBackOff   10 (70s ago)
~~~

### Investigation & Triage
Logs were pulled from the failing containers to determine if the issue was related to K8s networking or the application runtime.

~~~bash
$ sudo kubectl logs -n sock-shop deployment/carts-db
...
[image-entrypoint] Initializing MongoDB v7.0...
FATAL: MongoDB 5.0+ requires a CPU with AVX support.
~~~

**Diagnosis:** The unpinned `mongo` image reference in the raw manifests pulled the latest version (7.0+). Issue: Modern MongoDB versions require the **AVX (Advanced Vector Extensions)** CPU instruction set. The Proxmox VM, depending on its CPU host type or physical hardware, **did not expose these required instruction set to the guest OS**.

### Resolution (Hotfix)
The **deployments were patched live to explicitly use a legacy MongoDB version (`3.4`)** that does not require AVX, restoring parity with the original Sock Shop design baseline.

~~~bash
# Patch the carts-db + orders-db deployments to a specific MongoDB version 
$ sudo kubectl set image deployment/carts-db -n sock-shop carts-db=mongo:3.4
$ sudo kubectl set image deployment/orders-db -n sock-shop orders-db=mongo:3.4
~~~

**Result:** Both pods successfully transitioned to `Running` on `MongoDB v3.4.24`. This confirmed that the issue was a specific instruction-set incompatibility rather than a cluster resource or networking failure.

### Permanent Fix & Prevention
To prevent "Configuration Drift" (where the live cluster differs from the code in Git), the fix was codified back into the repository. 

**Changes applied to `deploy/kubernetes/manifests/`:**
- `03-carts-db-dep.yaml`: Updated image from `mongo` to `mongo:3.4`
- `13-orders-db-dep.yaml`: Updated image from `mongo` to `mongo:3.4`

**Result:** Subsequent deployments via the CI/CD pipeline or `kubectl apply -k` now default to the compatible image, ensuring the fix survives cluster recreations or redeployments.


---

## [Issue 02] Guest Session Persistence (Phase 05)

During final verification of the `dev` and `prod` environments, a **legacy application bug** was identified regarding **anonymous (guest) session handling**.

### Observed Behavior
While navigating the shop as a guest, clicking **"Add to Cart"** triggers a successful `201 Created` response in the browser's Network tab. However, t**he UI fails to update the cart counter**, and the **cart remains empty upon manual refresh**.

### Checking Cluster Health & Pod Triage
The first step was to ensure all microservices were operational and that no backend crashes were occurring.

~~~bash
# Verifying the status of the sock-shop-dev namespace
$ sudo kubectl get pods -n sock-shop-dev
carts-5f5859c84b-qbrjp          1/1     Running   2 (2d1h ago)   3d3h
carts-db-6bb589dd85-sdgdh       1/1     Running   2 (2d1h ago)   3d3h
...
front-end-7467866c7b-qwpvh      1/1     Running   2 (2d1h ago)   3d3h
...
user-db-7bd86cdcd-xwm7b         1/1     Running   2 (2d1h ago)   3d3h
~~~

Results showed all pods (carts, front-end, etc.) in a 'Running' state with no  recent restarts during the testing window.

### Investigate Application Logs
Internal logs for the `front-end` microservice were analyzed to trace the request lifecycle. 

~~~bash
# Tailing the logs for the front-end deployment
$ sudo kubectl logs -f -n sock-shop-dev deployment/front-end
...
Request received: /cart, undefined
Customer ID: k8LRAS9bQVc_Z8WRs-TXwpHj5Bq32JpK
POST to carts: http://carts/carts/sMaLJ7.../items
POST /cart 201 217.807 ms - -
Error: Can't set headers after they are sent.
    at ServerResponse.OutgoingMessage.setHeader (_http_outgoing.js:356:11)
    at helpers.errorHandler (/usr/src/app/helpers/index.js:22:7)
~~~    
 
The logs confirmed that the frontend is receiving the request but **crashing during the response phase**.

**Diagnosis:** This is a **Double Reverse Proxy** conflict. The legacy Node.js code tries to negotiate session cookies while **behind both Cloudflare and Traefik**. It attempts to send a "Set-Cookie" header and an error response simultaneously, causing the response to fail.

### Verify Database Persistence
To verify if the "lost" items were actually reaching the data layer, a direct query was performed on the `carts-db` MongoDB instance within the `sock-shop-dev` namespace:

~~~bash
# Accessing the MongoDB shell inside the carts-db pod
$ sudo kubectl exec -it -n sock-shop-dev deployment/carts-db -- mongo

# Inside the Mongo Shell:
> show dbs
> use data
> db.item.find().limit(3).pretty()
{
    "_class" : "works.weave.socks.cart.entities.Item",
    "itemId" : "510a0d7e-8e83-4193-b483-e27e09ddc34d",
    "quantity" : 1,
    "unitPrice" : 15
}

> show dbs
admin  0.000GB
data   0.000GB
local  0.000GB
> use data
switched to db data
> db.item.find().pretty()
{
	"_id" : ObjectId("69da7f2a0feec800070d4f8e"),
	"_class" : "works.weave.socks.cart.entities.Item",
	"itemId" : "510a0d7e-8e83-4193-b483-e27e09ddc34d",
	"quantity" : 1,
	"unitPrice" : 15
}
...
~~~

**Result** The presence of multiple records confirms that the entire **Ingress -> Front-end -> Carts -> MongoDB pipeline is 100 % functional**. The data successfully traverses Cloudflare, Traefik, the Front-end, and the Carts service to reach the Database.

### Conclusion 
System integrity was further validated using a **persistent user account**. By logging in, the application bypasses the buggy anonymous session logic. In this state, the cart functions perfectly. 

As the core infrastructure (K8s, Ingress, Tunnel, and Persistence) is confirmed healthy, patching the upstream Node.js source code for this legacy demo was deemed **Out of Scope** for this deployment phase.

---

---

## [Issue 03] Public Edge Rejects Default `urllib` Request Profile (Phase 07, Step 07)

During the first implementation of the **live Python catalogue contract-guard smoke test**, the request reached the public `dev` edge but failed with **`HTTP 403 Forbidden`**.

### Observed Behavior

The live smoke test failed even though the catalogue endpoint itself was reachable via `curl`.

~~~bash
$ make p07-contract-guard-live-dev
RUN: Phase 07 live Python contract smoke -> https://dev-sockshop.cdco.dev/catalogue
...
E   Failed: Live catalogue request failed with HTTP status 403: https://dev-sockshop.cdco.dev/catalogue
~~~

At the same time, direct manual checks against the same edge returned `200 OK`:

~~~bash
$ curl -I https://dev-sockshop.cdco.dev/catalogue
HTTP/2 200
...
~~~

### Investigation & Triage

The proven reachability via `curl` and browser checks ruled out a basic outage of the `dev` edge itself. 

The problem was narrowed down to the **request profile** used by the Python live smoke test:

**Diagnosis:** 
- The **default Python `urllib` request profile was rejected by the public edge**, while **browser-like requests were accepted**. 
- This was therefore **not an authentication problem**, but a request-profile / edge-filtering problem.

### Resolution

To mimic browser-like requests, the live **Python smoke test** was updated **to build an explicit `Request(...)` with browser-like headers**:

**Original implementation (default  `urllib` request profile):**

~~~python
    # ...
    catalogue_url = f"{base_url}/catalogue"

    try:        
        with urlopen(catalogue_url, timeout=10) as response:
           if response.status != 200:
                pytest.fail(f"Live catalogue request returned HTTP {response.status}: {catalogue_url}")
            # ...
~~~

**Updated implementation (explicit `Request(...)` with browser-like headers):**

~~~python
    # ... 
    catalogue_url = f"{base_url}/catalogue"

        # Build an explicit HTTP request with browser-like headers insetad of using the 
        # urllib from Python’s standard library. Reason: The public edge returned 
        # 'HTTP 403 Forbidden' when the default urllib request profile was used.
        request = Request(
            catalogue_url,
            headers={
                "User-Agent": "Mozilla/5.0",
                "Accept": "application/json",
            },
        )

        with urlopen(request, timeout=10) as response:
           if response.status != 200:
                pytest.fail(f"Live catalogue request returned HTTP {response.status}: {catalogue_url}")
            # ...
~~~

### Result

After switching from the default `urllib` request profile to an explicit request with browser-like headers, the **live Python contract smoke test passed successfully against the public `dev` edge**.

### Permanent Fix & Prevention

The header-based request shape is now part of `tests/python/test_contract_guard_live.py`, so future local runs and later CI runs use the same compatible request profile by default.