# Project Debug Log & Incident Reports

This document tracks technical anomalies discovered during deployment, the investigation process, and the resulting architectural decisions.

---

## [Issue 01] Guest Session Persistence (Phase 05)

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