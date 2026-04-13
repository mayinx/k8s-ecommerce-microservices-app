
# Phjase 05-C - Environment-aware redeploy, ingress path, and private cluster access preparation


# Step 12 — Inspect the dev overlay and render the target-side deployment input before the first environment-aware redeploy

## Rationale

Now the repository state on the target VM is aligned with the new Phase-05 branch and already contains the source-controlled MongoDB image pin. 

Before the first environment-aware redeploy begins, it is useful to inspect the current `dev` overlay and render its final Kubernetes output once on the real target.

This keeps the next deployment step grounded in the actual repository state and answers three practical questions early:

- which namespace model the current `dev` overlay expects
- whether the front-end service is still patched the way the CI/CD baseline intended
- and which image references the rendered target-side deployment input actually contains

## Action

The following inspection is done in the repository checkout on the target VM. The goal is not to change anything yet, but to confirm exactly what the current `dev` overlay would deploy before the first namespace-based Phase-05 redeploy is attempted.

> [!NOTE] **🧩 Rendered overlay**
>
> `kubectl kustomize <path>` renders the final Kubernetes YAML that an overlay would apply.
> This makes it possible to inspect the effective deployment input before anything is sent to the cluster.

### Target VM

First, inspect the current `dev` overlay files in the editor and note:

- the overlay `kustomization` file
- the namespace manifest used by the overlay
- any service patch that changes the front-end exposure model

After that file-level check, render the overlay once from the target checkout and keep a small excerpt for later documentation.

~~~bash
# Render the dev overlay into a temporary file.
# This creates the exact Kubernetes YAML the overlay would apply.
kubectl kustomize deploy/kubernetes/kustomize/overlays/dev > /tmp/dev-rendered.yaml

# Inspect the beginning of the rendered overlay for a quick structural check.
head -n 80 /tmp/dev-rendered.yaml

# Show the first image references that appear in the rendered overlay to confirm 
# that the deploy path still relies mainly on upstream runtime images.
grep 'image:' /tmp/dev-rendered.yaml | head -n 20

# If the rendered overlay contains namespace lines, show the first few of them 
# to confirm the current environment naming model before redeploying.
grep 'namespace:' /tmp/dev-rendered.yaml | head -n 20
~~~

## Expected result / success criteria

This step is successful if:

- the target checkout is still clean and on `feat/proxmox-target-delivery`
- `kubectl kustomize deploy/kubernetes/kustomize/overlays/dev` renders without error
- the rendered output clearly shows the current namespace model used by the `dev` overlay
- the rendered output confirms how the front-end service is currently represented
- the rendered image list confirms which images come from upstream/runtime manifests and which, if any, are overridden from repository-controlled paths

 ---

# Step 13 — Redeploy the application into the `sock-shop-dev` namespace from the Phase-05 source state

## Rationale

At this point, 
- the target VM checkout is aligned with the new Phase-05 branch, 
- the `dev` overlay renders cleanly, 
- the namespace model is confirmed as `sock-shop-dev`, 
- and the source-controlled MongoDB pin is visible in the rendered deployment input.

Before the target-delivery work continues with Tailscale, Cloudflare Tunnel, or workflow retargeting, it is useful to perform one clean redeploy from source into the `sock-shop-dev` namespace. This will confirm 
- if the Phase-05 repository state is already sufficient to stand up the application in the new environment model 
- and if the MongoDB fix now survives a normal `kustomize`-based deployment path.

## Action

The goal now is (on the target VM)
- to apply the `dev` overlay into `sock-shop-dev` from source control, 
- and then verify that the main application workloads and services come up cleanly in that namespace.

> [!NOTE] **🧩 Environment-aware redeploy**
>
> This redeploy is the first target-side proof that the application can be brought up from the Phase-05 (current feature branch) source state in the new namespace-based environment model.
>
> This differs from the earlier live-cluster patching work because now the deployment comes from the repository manifests and overlay structure rather than from one-off manual changes in the running cluster.

### Target VM

It is useful to begin with a quick look at the current namespace state before applying the overlay. That gives a clean before/after view of what the `dev` deployment actually creates.

~~~bash
# Show the current workload state in the dev namespace before applying the overlay 
# to get a clean baseline for the first environment-aware redeploy.
sudo kubectl get deploy,pods,svc -n sock-shop-dev

# Apply the dev overlay from source control into the target cluster.
# -k = build and apply the kustomize overlay directly
sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/dev

# Show the resulting deployment objects in the dev namespace.
# This confirms which workloads and services were created from the overlay.
sudo kubectl get deploy,svc -n sock-shop-dev

# Show the pod state in the dev namespace after the apply.
# The goal here is to see the new namespace fill with the expected application pods.
sudo kubectl get pods -n sock-shop-dev

# Check the rollout status of the key frontend and MongoDB-backed deployments.
# These checks give a quick early signal that the application and the previously failing DB services now come up from source.
sudo kubectl rollout status deployment/catalogue -n sock-shop-dev
sudo kubectl rollout status deployment/payment -n sock-shop-dev
sudo kubectl rollout status deployment/front-end -n sock-shop-dev
sudo kubectl rollout status deployment/carts-db -n sock-shop-dev
sudo kubectl rollout status deployment/orders-db -n sock-shop-dev

# Show the pod state again after the rollout checks.
# This final snapshot should show the namespace in a stable Running state.
sudo kubectl get pods -n sock-shop-dev
~~~

## Result

We have successfully deployed a 14-component microservice architecture to a bare-metal hypervisor.

Success criertia:

- `sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/dev` completes without manifest or namespace errors
- the `sock-shop-dev` namespace contains the expected deployments and services after the apply
- the `front-end`, `carts-db`, and `orders-db` rollout checks complete successfully
- the final pod list in `sock-shop-dev` shows a stable application state without the earlier MongoDB crash-loop behavior

---

# Step 14 — Confirm the current target-side ingress controller path before introducing the first public `dev` entry

## Rationale
 
Status: The app is now running cleanly in the `sock-shop-dev` namespace from the Phase-05 source state, and the `front-end` service is intentionally exposed only as `ClusterIP`. 

In consequence, the `front-end` service is completely locked inside the internal K8s network - and only reachable from inside the cluster via its CluserIP - and no longer directly from the outside via a "NodePort hole". This ensures the application is securely isolated within the internal network, forcing all external traffic to route strictly through our controlled public edge.

Before Cloudflare Tunnel is introduced, we need to confirm **which target-side ingress controller path already exists on the K3s VM** and how traffic can be handed to it locally.

This avoids guessing whether Cloudflare Tunnel should point at a pod, a service, or the ingress controller entrypoint itself.

> [!NOTE] **🧩 ClusterIP vs NodePort**
>
> `ClusterIP` **(The Internal Intercom)**: This is the default in Kubernetes. It assigns an IP address that is only reachable from inside the cluster. It is like an internal phone extension. The orders pod can call the front-end pod, but nobody from the outside internet can reach it.
>
> `NodePort` **(The Direct Outside Line)**: This punches a hole in the Kubernetes firewall. It opens a specific port (like 30001) on your physical Proxmox VM. Anyone who knows the VM's IP and that port can bypass the front desk and access the app directly.

## Action

The goal now is (on the target VM)
- to identify the currently running ingress controller (here Traefik) footprint, 
- confirm how it is exposed inside the cluster, 
- and capture the local target that the first `dev` ingress proof should use.

> [!NOTE] **🧩 Ingress Controller vs Ingress Object**
>
> * **Ingress Controller (The Bouncer):** The active component at the "front door" that receives and routes all incoming HTTP(S) traffic. In this K3s setup, the controller is **Traefik**.
> * **Ingress Object (The Guest List):** The passive Kubernetes configuration that tells the controller what to do, i.e. which hostname/path should be routed to which Service (e.g., "If they ask for *dev.domain.com*, send them to the dev Service").
>
> **In short:**
> * **Traefik** = The bouncer doing the actual work / the active traffic-handling component
> * **Ingress manifest** = The guest list providing the routing rules / the routing rule given to Traefik

### Target VM 9200 (repository checkout)

~~~bash
# Show the Traefik controller pods in the kube-system namespace to confirms 
# whether the built-in K3s ingress controller is present and running 
sudo kubectl get pods -n kube-system | grep traefik

# Show the Traefik service in the kube-system namespace to reveal 
# how the ingress controller is currently exposed inside the cluster 
sudo kubectl get svc -n kube-system | grep traefik

# Show the full Traefik service definition for a clearer port view.
# (especially HTTP/HTTPS port exposure)
sudo kubectl get svc traefik -n kube-system -o wide

# Show any currently existing Ingress objects across all namespaces 
# to confirms whether the target already has routing rules or whether 
# the Phase-05 dev ingress will be the first one 
sudo kubectl get ingress -A
~~~

## Result

- Traefik is already present and running on the target
- the Traefik Service already exposes HTTP/HTTPS on the VM IP 10.10.10.20
- but there are currently **no Ingress objects**, so the next step is **to create the first real dev ingress rule** and test it locally before Cloudflare is introduced

This step is successful if:

- one or more Traefik pods are visible in `kube-system`
- the Traefik service is visible in `kube-system`
- the Traefik service output makes clear which HTTP/HTTPS entry ports are available
- the cluster-wide Ingress listing confirms whether any routing rules already exist

---

# Step 15 — Create the `dev` ingress rule for the front end and verify it locally through Traefik

## Rationale

The earlier ingress-controller check already showed that 
- **Traefik is running on the target VM** 
- **HTTP/HTTPS traffic** is already exposed on **`10.10.10.20` (Proxmox VM `9200` IP)**. 
- the **cluster currently contains no Ingress objects** at all.

That makes the next step clear: before Cloudflare Tunnel is introduced, **the cluster first needs a real `dev` routing rule** that **tells Traefik how to forward a hostname to the `front-end` service** in `sock-shop-dev`. A local verification through Traefik then will prove that the in-cluster routing path works before any public edge is added on top.

## Action

**The goal now is (from local)**
- to let the first `dev` ingress rule become part of the Phase-05 source state
- to update  the target VM checkout from GitHub again 
- and to applied and test the ingress locally against Traefik.

> [!NOTE] **🧩 Local ingress verification before public exposure**
>
> An Ingress rule can be tested locally before DNS or a public tunnel exists by sending an HTTP request to the Traefik entrypoint and adding the intended hostname through the `Host:` header.
>
> In practice, that means:
>
> - traffic goes to the local Traefik entrypoint on the target VM
> - the `Host:` header simulates the later public hostname
> - Traefik matches that hostname against the new Ingress rule
> - the request is forwarded to the `front-end` service in `sock-shop-dev`

### Local workstation (repo)

The `dev` overlay currently has no ingress resource. A small ingress manifest for the front end therefore needs to be added to the `dev` overlay and referenced from its `kustomization.yml`. 

For host-based routing a hostname is needed obviously - until the final public hostname will be fixed (later via public DNS / Cloudflare), a temporary one such as `dev.sockshop.local` is enough for this local verification step. 

**Create a new overlay manifest file for the front-end-ingress:**

~~~yaml
# `deploy/kubernetes/kustomize/overlays/dev/front-end-ingress.yaml`

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: front-end
  namespace: sock-shop-dev
spec:
  # Route this ingress object / routing rule through the built-in K3s Traefik controller:  
  # (explicitly tells Kubernetes to use Traefik to execute this routing rule 
  # to prevent conflicts if multiple ingress controllers exist on the cluster)
  ingressClassName: traefik

  # Forward requests that match that hostname 'dev.sockshop.local'  
  # to the internal 'front-end' Kubernetes Service on port '80'
  rules:
    # The external hostname that Traefik listens for. 
    # Traffic hitting the VM with this 'Host' header will trigger this rule.
    - host: dev.sockshop.local
      http:
        paths:
          # Match all traffic (Prefix '/') under this hostname.
          - path: /
            pathType: Prefix
            # The internal destination: route the matched traffic to 
            # port 80 of the 'front-end' ClusterIP service.
            backend:
              service:
                name: front-end
                port:
                  number: 80
~~~

Then we need to add that new file to the `resources:` section of `/overlays/dev/kustomization.yml`, because the `dev` overlay will only include and apply that new ingress resource + routing rule if it is listed under `resources:` in the overlay `/dev/kustomization.yml`:

~~~yaml
# deploy/kubernetes/kustomize/overlays/dev/kustomization.yml

# Overlay input:
# - a namespace object for sock-shop-dev
# - the shared reusable manifest base
# - the environment-specific ingress rule to route external traffic to the storefront
resources:
  - namespace.yaml
  - ../../../manifests
  - front-end-ingress.yaml

~~~ 

After saving those file changes, we continue with the normal Git flow:

~~~bash
# Stage the new ingress file and the updated dev overlay kustomization.
git add deploy/kubernetes/kustomize/overlays/dev/kustomization.yml deploy/kubernetes/kustomize/overlays/dev/front-end-ingress.yaml

# Commit the first dev ingress rule.
git commit -m "feat(target-delivery): add dev ingress for sock-shop front-end"

# Push the updated Phase-05 branch so the target VM can sync to it.
git push
~~~

### Target-VM `9200` checkout alignment and apply

After the branch is pushed, the repository checkout on the K3s target VM needs to be updated again so the new ingress rule can be applied from source.

~~~bash
# Fetch the newest branch state from GitHub.
git fetch origin

# Align the target checkout to the latest remote Phase-05 branch state.
git reset --hard origin/feat/proxmox-target-delivery

# Apply the dev overlay again so the new ingress resource is created.
sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/dev

# Show the ingress object in the dev namespace.
sudo kubectl get ingress -n sock-shop-dev

# Show the detailed ingress definition as stored in the cluster.
sudo kubectl describe ingress front-end -n sock-shop-dev
~~~

### Local ingress verification on the target VM

Once the ingress object exists, it can be testd directly through Traefik on the target VM by sending the intended hostname in the request header.

~~~bash
# Send a request to Traefik on the VM IP while simulating the intended dev hostname.
# -H 'Host: ...' sets the host header used by Traefik for routing.
curl -I -H 'Host: dev.sockshop.local' http://10.10.10.20/

# Fetch the first lines of the returned HTML through the ingress path.
# This proves that Traefik routes the hostname to the front-end service correctly.
curl -s -H 'Host: dev.sockshop.local' http://10.10.10.20/ | head -n 10
~~~

## Result

The **first `dev` ingress rule for the Sock Shop front end was created successfully** and already routes traffic locally through the Traefik ingress controller on the target VM.

The successful end state is shown by these signals / verification points:

- `git status -sb` still showed the target checkout on `feat/proxmox-target-delivery`
- `git reset --hard origin/feat/proxmox-target-delivery` aligned the VM checkout to commit `ed360f6`, which contains the new `dev` ingress rule
- `sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/dev` completed successfully and created:
  - `ingress.networking.k8s.io/front-end`
- `sudo kubectl get ingress -n sock-shop-dev` showed:
  - ingress name `front-end`
  - ingress class `traefik`
  - host `dev.sockshop.local`
  - address `10.10.10.20`
- `sudo kubectl describe ingress front-end -n sock-shop-dev` confirmed the intended routing:
  - host `dev.sockshop.local`
  - path `/`
  - backend service `front-end:80`
- `curl -I -H 'Host: dev.sockshop.local' http://10.10.10.20/` returned:
  - `HTTP/1.1 200 OK`
- `curl -s -H 'Host: dev.sockshop.local' http://10.10.10.20/ | head -n 10` returned the Sock Shop storefront HTML

These signals show that:

- the `dev` overlay now contains a working ingress rule
- Traefik is already routing the intended `dev` hostname correctly
- the in-cluster front-end exposure path is ready for the later public-edge step

---

# Step 16 — Bring the target VM onto the tailnet and verify private network reachability for the later CI/CD deploy path

## Rationale

With the local ingress path already working through Traefik, the next useful move is to **establish the private network path via Tailscale** that later allows **GitHub-hosted runners to reach the target cluster** safely. 

> [!NOTE] **🧩 Why is Tailscale needed? (The Zero-Trust Bridge)**
> 
> Tailscale is a zero-trust VPN that securely connects devices across the internet into a single, private network called a "tailnet".
>
> For the intended CI/CD setup GitHub Actions must be able to deploy code to our VM `9200` safely. But exposing the Kubernetes management API (kube-apiserver) one hacky way or another to the public internet so GitHub can reach it would be a massive security risk. 
>
> Tailscale solves this natively:
> - It creates a secure, flat virtual network (the tailnet) that effortlessly pierces through NAT and firewalls. 
> - It allows ephemeral GitHub-hosted runners to deploy code to a Proxmox VM sitting deep inside your home network—without opening a single router port.
> By using Tailscale, we completely bypass the dangerous anti-patterns often found in bad tutorials:
> 
> * **No Hypervisor Pollution:** Using Tailscale, it is not necessary to use the bare-metal Proxmox host as a network router or an SSH jump-box. Proxmox remains a pure, untouched Type-1 hypervisor.
> * **Zero "Hypervisor Escape" Risk:** No ports are opened on the router. By not exposing SSH or the Kubernetes API (`kube-apiserver`) to the internet, the risk of hackers is eliminated, so they can't breach the setup and taking over the physical hardware.
> * **No Brittle CI/CD:** GitHub Actions runners change IP addresses constantly. Instead of maintaining a nightmare firewall allowlist, the ephemeral runner simply joins the private Tailnet, deploys the code, and disappears.

The cluster does not need workflow retargeting yet, but the target VM itself now needs to become a reachable node inside the tailnet before kubeconfig preparation and pipeline changes make sense.

This keeps the delivery path layered in a sensible order:

- **local ingress routing** => already proven
- **private deployment reachability (Tailscale)** => to be added next
- **workflow retargeting** => only after that network bridge exists

## Action

**The goal now is (on the target VM)**
- to install Tailscale, 
- start the Tailscale daemon, 
- join the VM to the tailnet, 
- and verify that the node receives a stable tailnet address. 

The VM-side tailnet presence is the foundation for the later GitHub Actions deployment hop.

> [!NOTE] **🧩 The Networking Story: Cloudflare, Tailscale & The Tailnet**
>
> **Tailscale (The Secure Employee Entrance):** A zero-trust mesh VPN built on WireGuard. 
It **connects any authorized machine (like the local workstation or a GitHub Actions runner) directly to the remote Proxmox VM** as if they were plugged into the exact same physical network switch, regardless of where they are in the world.
> **Benefits:** No port forwarding, no public static IPs, and no messy firewall rules. The  cluster remains completely invisible to hackers on the internet, yet perfectly accessible to authorized CI/CD runners.
>
> **The Architecture Boundary:**
> * **Cloudflare + Traefik** = The public front door (handles incoming customer web traffic).
> * **Tailscale** = The private employee entrance (handles secure SSH and `kubectl` admin traffic, without opening any public ports on the firewall).

> [!NOTE] **🧩 VM-side Tailscale node vs GitHub Actions Tailscale node**
>
> In this step, we are only connecting the **target VM** to the tailnet - so Tailscale is installed only on the target VM. That makes the deploy target reachable inside the private tailnet.
>
> The later CI/CD workflow step is separate:
>
> - The GitHub-hosted runner will temporarily join this exact same tailnet using the official Tailscale GitHub Action.
> - Once both are on the tailnet, the GitHub Action can securely run `kubectl apply` against your VM's private IP, crossing the internet completely safely and undetected.

### Target VM `9200`

If Tailscale is not yet installed on the target VM, install and start it first:

~~~bash
# Install Tailscale from the official install script.
# This adds the Tailscale packages needed for the node agent and CLI.
curl -fsSL https://tailscale.com/install.sh | sh

# Ensure the Tailscale daemon is enabled and started now.
sudo systemctl enable --now tailscaled

# Show the daemon state after startup.
sudo systemctl status tailscaled --no-pager
~~~

Once the daemon is running, bring the VM onto the tailnet:

~~~bash
# Start the interactive tailnet join flow for this VM.
# If no auth key is supplied here, Tailscale prints a browser URL that can be opened to authorize the node.
sudo tailscale up

# Show the assigned IPv4 tailnet address after the node has joined successfully.
tailscale ip -4

# Show the current node status from the VM side.
tailscale status
~~~

If the browser-based authorization flow is used, complete that authorization first and only then continue with the final verification commands.

## Result

The **target VM was brought onto the tailnet successfully**, and the **private network path for the later CI/CD deployment** is now in place.

The successful end state is shown by these signals / verification points:

- `curl -fsSL https://tailscale.com/install.sh | sh` installed the Tailscale packages successfully
- `sudo systemctl enable --now tailscaled` started and enabled the Tailscale daemon
- `sudo systemctl status tailscaled --no-pager` showed:
  - service `tailscaled.service`
  - state `active (running)`
  - status `Needs login:` before authentication
- `sudo tailscale up` completed successfully after the browser-based authorization flow
- `tailscale ip -4` returned the VM tailnet address:
  - `100.72.5.85`
- `tailscale status` showed the target VM as an active node:
  - `ubuntu-2404-k3s-target-01`
  - `100.72.5.85`

These signals show that:

- the target VM is now part of the tailnet
- the private network bridge required for the later GitHub Actions deploy path is in place
- the next step can focus on preparing the K3s kubeconfig for tailnet-based cluster access
 

---

# Step 17 — Prepare the tailnet-based K3s kubeconfig and verify cluster access material for the later workflow integration

## Rationale

 With the target VM now present on the tailnet, the next task is to **prepare the Kubeconfig (i.e. the cluster credentials)** that later **allows GitHub Actions to talk to the target cluster**. The default K3s kubeconfig is still expected to point at the local loopback endpoint (127.0.0.1), so **a tailnet-reachable variant** is now needed before workflow retargeting can begin.

That keeps the sequence clean:

- target VM joined to the tailnet
- cluster access material adapted to the tailnet endpoint
- workflow integration only after the real remote-access path is prepared

## Action

The following work is done on the target VM first to inspect the default K3s kubeconfig, create a tailnet-ready copy, and verify that the API server endpoint now points at the VM's Tailscale address. After that, the prepared kubeconfig can be moved into the later GitHub secret workflow.

The goal now is (on the target VM)
- to inspect the default K3s kubeconfig, 
- create a tailnet-ready copy, 
- **extend the K3s server certificate configuration** to include the **VM's Tailnet IP**, 
- and verify that the API server endpoint now points at the VM's Tailscale address. 

After that, the prepared kubeconfig can be moved into the later GitHub secret workflow.

> [!NOTE] **🧩 Default K3s kubeconfig vs. Tailnet-ready Kubeconfig (The Remote Control)**
>
> The default K3s kubeconfig acts as a local remote control. It usually points to:
>
> - `https://127.0.0.1:6443`
>
> This works only locally on the VM itself.
>
> For the later GitHub Actions deployment hop, a second kubeconfig variant is needed that points to the VM's tailnet-reachable API endpoint instead.

### Target VM `9200`

The current tailnet IPv4 for the target VM is already known from the previous step:

- **Tailscale IP: `100.72.5.85`**

The kubeconfig preparation therefore focuses on **replacing the default loopback API endpoint** with that **tailnet address** in a dedicated copy.

~~~bash
# --- (1) Network Discovery + Initial Audit ---

# Capture and display the VM's Tailnet identity (IPv4-address).
# This 100.x.y.z address is the unique IP that GitHub Actions 
# will use to address the VM
$ tailscale ip -4
100.72.5.85

# Inspect the server line in the default K3s kubeconfig to verify the starting state:
# This confirms whether it still points to the local loopback endpoint.
# K3s defaults to '127.0.0.1' (the loopback). This acts as a 'Local-Only' lock 
# that prevents any remote access by default.
$ sudo grep 'server:' /etc/rancher/k3s/k3s.yaml
server: https://127.0.0.1:6443

# --- (2) Data Preservation + Working Copy Preparation ---

# Copy the original kubeconfig to the user's home directory and gain ownership
# This avoids editing the root-owned original directly - /etc/rancher/k3s/k3s.yaml 
# is root-protected and should remain untouched as a 'gold' backup for local-only 
# cluster operations.
$ sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/kubeconfig-proxmox-dev.yaml
$ sudo chown ubuntu:ubuntu /home/ubuntu/kubeconfig-proxmox-dev.yaml

# --- (3) API Endpoint Reconfiguration & TLS Certificate Update ---

# Capture the IP dynamically so the script remains portable across any VM.
TAILNET_IP=$(tailscale ip -4)

# 1. Update the server endpoint in the copy
# Replace the local loopback with the VM's actual Tailscale IP  
# Without this change, GitHub would try to talk to itself (127.0.0.1) and fail.
# - -i      = in-place edit + immediate file save
# - s|A|B|  = substitute A with B     
$ sed -i "s|https://127.0.0.1:6443|https://${TAILNET_IP}:6443|" /home/ubuntu/kubeconfig-proxmox-dev.yaml

# 2. Authorize the Tailnet IP in the K3s TLS Certificate.
# K3s rejects external IPs by default. We append the Tailnet IP to the 
# Subject Alternative Names (SAN) list so the API accepts our external connection.
# (Note: '| sudo tee -a' is used to bypass permission blocks on system files, 
# appending the new line securely as root without overwriting the whole file).
$ echo "tls-san: ${TAILNET_IP}" | sudo tee -a /etc/rancher/k3s/config.yaml

# 3. Restart K3s to apply the new certificate rules.
# This takes about 10-15 seconds to spin back up.
$ sudo systemctl restart k3s

# Confirm that the Tailnet IP is now present in the K3s server configuration.
$ grep 'tls-san:' /etc/rancher/k3s/config.yaml
tls-san: 100.72.5.85

# --- (4) Final Verification ---

# Confirm the 'server' line now reflects the remote-reachable endpoint.
$ grep 'server:' /home/ubuntu/kubeconfig-proxmox-dev.yaml
server: https://100.72.5.85:6443

# Preview the metadata and certificate structure to ensure the YAML integrity 
# is intact before this is moved  eventually into a GitHub Secret.
$ head -n 20 /home/ubuntu/kubeconfig-proxmox-dev.yaml
~~~

## Result

The tailnet-ready K3s kubeconfig was prepared successfully on the target VM.

The successful end state is shown by these signals / verification points:

- `tailscale ip -4` returned the target VM tailnet address:
  - `100.72.5.85`
- `sudo grep 'server:' /etc/rancher/k3s/k3s.yaml` showed the default local API endpoint:
  - `server: https://127.0.0.1:6443`
- a writable working copy of the kubeconfig was created at:
  - `/home/ubuntu/kubeconfig-proxmox-dev.yaml`
- the copied kubeconfig was updated to the tailnet-reachable API endpoint:
  - `server: https://100.72.5.85:6443`
- the resulting file header remained structurally valid after the server replacement
- the K3s server configuration was extended with:
  - `tls-san: 100.72.5.85`
- `sudo systemctl restart k3s` completed successfully so the updated certificate rules could take effect

These signals show that:

- the default local-only K3s access path has been converted into a tailnet-reachable kubeconfig variant
- the cluster access material needed for the later GitHub Actions deployment hop now exists
- the next useful check is to verify that this kubeconfig works from outside the target VM
- the K3s API is now prepared not only logically, but also certificate-wise, for tailnet-based external access

---

# Step 18 — Verify tailnet-based cluster access from the local workstation before wiring the workflow to the real target

## Rationale

Now that **the target VM has a tailnet-ready kubeconfig**, we want to prove that **the cluster can actually be reached from outside the VM over the tailnet**. That external check matters before any GitHub Actions wiring begins, because **the CI/CD-workflow will later approach the cluster as an external node** as well.

The earlier Tailscale status on the target VM already showed the local workstation node as present in the tailnet but currently offline. This makes a short workstation-side reachability check the most direct way to confirm that the private deploy path is really usable and not just theoretically prepared.

## Action

The goal now is 
- to bring the workstation back onto the tailnet if necessary, 
- copy the prepared kubeconfig securely from the target VM, 
- and verify that `kubectl` can reach the real cluster through the tailnet endpoint.

> [!NOTE] **🧩 External kubeconfig validation before workflow integration**
>
> A kubeconfig that only exists on the target VM is not yet enough to justify workflow retargeting.
> The more useful proof is an external `kubectl` request from another tailnet node, because that mirrors the later deployment shape much more closely than a purely local check on the VM itself.

[!WARNING] 🔐 Precondition: VM-Level SSH Access
> To copy files from the VM to your workstation, the local workstation's public SSH key must be authorized on the Ubuntu VM itself (the ubuntu user), not just the Proxmox bare-metal host (root).
> - If a custom SSH key was configured specifically for this, the "secure copy" command below (see `scp`) must be explicitly instructed to use that specific key.  
> - If the VM lacks the workstation's SSH key entirely, it will reject the connection with a `Permission denied (publickey)` error.
> - **To set up SSH-access both to the bare metal Proxmox Host and the VM 9200**, consult the setup guide in Phase 04 (Proxmox VM Baseline): [Local/workstation preparation and SSH access](../../04-proxmox-vm-baseline/SETUP.md).  

### Local workstation

The target VM already reports the tailnet IPv4 address `100.72.5.85`. This address is used below as the SSH and Kubernetes API target:

~~~bash

# --- (1) Tailnet Connection & Verification

# Check the local workstation Tailscale state first.
# Check status. If disconnected, it will prompt you to log in.
tailscale status

# If the laptop is not currently connected, bring it (back) onto the tailnet.
# (opens a browser-based authorization flow depending on the local Tailscale state)
sudo tailscale up

# Confirm the laptop-side tailnet state again after login.
$ tailscale status
100.90.87.121  <Tailscale-Machine-Name_Workstation>  ...  ...  -  
100.72.5.85    <Tailscale-Machine-Name_Proxmox-VM>   ...  ...  -  

# Try to ping the VM's secure Telnet IP to verify that workstation 
# and remote VM 9200 are really connected via Tailnet 
$ ping -c 4 100.72.5.85
PING 100.72.5.85 (100.72.5.85) 56(84) bytes of data.
64 bytes from 100.72.5.85: icmp_seq=1 ttl=64 time=89.0 ms
...
--- 100.72.5.85 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms

# --- (2) Securely Retrieve the Kubeconfig ---

# Prepare a dedicated local kubeconfig directory if it does not exist yet.
mkdir -p ~/.kube
chmod 700 ~/.kube

# Use SCP (Secure Copy Protocol) to download the file over the encrypted Tailnet via an SSH connection
#
# Copy the prepared tailnet-ready kubeconfig securely from the target VM to the laptop.
# This keeps the source file unchanged on the VM and gives the laptop its own working copy.
#
# -> Standard Command (If using the system's default SSH keys):
scp ubuntu@100.72.5.85:/home/ubuntu/kubeconfig-proxmox-dev.yaml ~/.kube/config-proxmox-dev.yaml
kubeconfig-proxmox-dev.yaml  100% 2939    96.3KB/s   00:00  

# -> Custom key Command (If the VM requires a specific project key, use the -i flag):
# scp -i ~/.ssh/id_ed25519_proxmox_capstone ubuntu@100.72.5.85:/home/ubuntu/kubeconfig-proxmox-dev.yaml ~/.kube/config-proxmox-dev.yaml

# Restrict the local kubeconfig permissions so Kubernetes accepts it.
$ chmod 600 ~/.kube/config-proxmox-dev.yaml

# Confirm the server line in the copied kubeconfig.
# This should still point to the VM's Tailscale address.
$ grep 'server:' ~/.kube/config-proxmox-dev.yaml
server: https://100.72.5.85:6443

# --- (3) Test External Cluster Access ---

# Use the copied kubeconfig to query the real cluster from the workstation.
# This is the first true external proof that the target cluster is reachable over the tailnet.

# Check if the cluster nodes respond to our external query.
$ KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get nodes -o wide
NAME                        STATUS   ROLES           INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             
ubuntu-2404-k3s-target-01   Ready    control-plane   10.10.10.20   <none>        Ubuntu 24.04.4 LTS   

# Confirm that the expected namespaces are visible through the same kubeconfig.
$ KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get namespace sock-shop-dev
NAME            STATUS   
sock-shop-dev   Active   

~~~

## Result

**Zero Trust networking:** 

The **local workstation is now successfully and securely querying the private Kubernetes cluster sitting behind the VPN `9200`** and the Proxmox hypervisor, with zero port-forwarding or public IP exposure: The output above (`EXTERNAL-IP <none>`) proves, that the Kubernetes node does not have a public-facing IP address on the internet.  

The successful end state is shown by these signals / verification points:

- `ping -c 4 100.72.5.85` returned successful replies from the target VM over the tailnet
- `scp -i ~/.ssh/id_ed25519_proxmox_capstone ubuntu@100.72.5.85:/home/ubuntu/kubeconfig-proxmox-dev.yaml ~/.kube/config-proxmox-dev.yaml` copied the prepared kubeconfig successfully to the workstation
- `grep 'server:' ~/.kube/config-proxmox-dev.yaml` confirmed that the copied kubeconfig points to:
  - `server: https://100.72.5.85:6443`
- `KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get nodes -o wide` returned the real target cluster state from the workstation
- the returned node output showed:
  - node `ubuntu-2404-k3s-target-01`
  - status `Ready`
  - role `control-plane`
  - internal IP `10.10.10.20`
- `KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get namespace sock-shop-dev sock-shop-prod` confirmed:
  - `sock-shop-dev` exists and is `Active`
  - `sock-shop-prod` is not yet present

These signals show that:

- the tailnet-based external cluster access path already works
- the copied kubeconfig is valid for workstation-side access to the target cluster

---

# Step 19 — Create the missing `sock-shop-prod` namespace from source control and complete the planned two-environment cluster shape

## Rationale

The workstation-side cluster access check already proved that the target cluster can be reached externally over the tailnet. Now it's time to create the planned `sock-shop-prod` namespace and then bring up the corresponding production workload from the same source-controlled manifests. Before the CI/CD workflow is retargeted toward real dev/prod behavior, the intended two-environment cluster must be completed. 

## Action

The goal now is 
- to **create the missing production namespace** from the existing source-controlled manifest and verify externally (through the already working tailnet kubeconfig) that both planned application namespaces now exist. 
- to **apply and verify the production overlay on the target VM**.

> [!NOTE] **🧩 Production namespace baseline vs production workload**
>
> Creating the `sock-shop-prod` namespace only establishes the structural environment boundary.
>
> Applying the `prod` overlay goes one step further and brings up the actual production-side workload from the existing overlay and manifest state.

### Local workstation

The production namespace manifest already exists in the repository under the `prod` overlay (see  `deploy/kubernetes/kustomize/overlays/prod/namespace.yaml`), so the missing namespace can be created directly from source control, utilizing `kubectl` - and the existing kubeconfig that points it to the remote K3s API server on the VM (`server: https://100.72.5.85:6443`):

> [!NOTE] **🧩 Local workstation `kubectl` vs. the remote cluster**
>
> **Even though the following `kubectl` commands are run on the local workstation, they do not change anything "on the laptop itself".**
>
> The decisive part is the environment variable:
>
> `KUBECONFIG=~/.kube/config-proxmox-dev.yaml`
>
> `kubectl` uses this kubeconfig, which specifies **which Kubernetes API server to talk to**. In this case, the copied kubeconfig points to:
>
> `server: https://100.72.5.85:6443`
>
> `100.72.5.85` is the **Tailscale IP of the K3s VM (`9200`)**.  
>
> So the command flow is:
>
> - the `kubectl` client runs on the **local workstation**
> - the kubeconfig points that client to the **remote K3s API server on the VM**
> - the Kubernetes API server on the VM applies the requested change to the **real cluster state**
>
> In consequence, a namespace created from the laptop is immediately visible from inside the VM as well:
>
> - Local Workstation: `KUBECONFIG=... kubectl ...`
> - VM-side: `sudo kubectl ...`
>
> **Both commands talk to the same cluster.**  
> Only the client location is different.

~~~bash
# Create the production namespace from the existing source-controlled manifest.
# `kubectl` runs on the local workstation here, but the kubeconfig points it to
# the remote K3s API server on the VM (`server: https://100.72.5.85:6443`).
# So this command creates the namespace in the real remote cluster, not locally on the laptop.
$ KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl apply -f deploy/kubernetes/kustomize/overlays/prod/namespace.yaml
namespace/sock-shop-prod created

# Verify that both environment namespaces now exist in that same remote cluster.
# The same kubeconfig is used again, so this check also talks to the K3s API server on the VM.
$ KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get namespace sock-shop-dev sock-shop-prod
NAME             STATUS
sock-shop-dev    Active
sock-shop-prod   Active
~~~

### Target VM `9200`

Once the production namespace exists, the `prod` overlay can be applied directly from the Phase-05 repository checkout on the target VM.

~~~bash
# Show the current workload state in the prod namespace before the apply.
# The namespace is expected to exist already because it was just created earlier from the workstation
# against the same remote K3s cluster via the tailnet-ready kubeconfig.
# At this point the expected result is therefore an existing but still empty namespace:
# "No resources found in sock-shop-prod namespace."
$ sudo kubectl get deploy,pods,svc -n sock-shop-prod
No resources found in sock-shop-prod namespace.

# Apply the production overlay from source control into the target cluster
$ sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/prod

# Show the resulting deployment and service objects in the prod namespace
$ sudo kubectl get deploy,svc -n sock-shop-prod

# Show the pod state in the prod namespace after the apply.
$ sudo kubectl get pods -n sock-shop-prod

# Check rollout completion for the front end and the MongoDB-backed deployments.
$ sudo kubectl rollout status deployment/front-end -n sock-shop-prod
deployment "front-end" successfully rolled out

$ sudo kubectl rollout status deployment/carts-db -n sock-shop-prod
deployment "carts-db" successfully rolled out

$ sudo kubectl rollout status deployment/orders-db -n sock-shop-prod
deployment "orders-db" successfully rolled out


# Display the final pod state after the rollout checks.
$ sudo kubectl get pods -n sock-shop-prod
NAME                            READY   STATUS    RESTARTS    
carts-5f5859c84b-zhvcj          1/1     Running   0          
carts-db-6bb589dd85-vfcts       1/1     Running   0          
catalogue-cd4ff8c9f-jlkvv       1/1     Running   0          
catalogue-db-74885c6d4c-g26tv   1/1     Running   0          
front-end-7467866c7b-fcshd      1/1     Running   0          
orders-6b8dd47986-m8rp6         1/1     Running   0          
orders-db-944d776bc-tj657       1/1     Running   0          
payment-c5fbdbc6-ptwpj          1/1     Running   0          
queue-master-7f965677fb-c9988   1/1     Running   0          
rabbitmq-59955f8bff-nvggq       2/2     Running   0          
session-db-5d89f4b5bb-27wkl     1/1     Running   0          
shipping-868cd6587d-8rskk       1/1     Running   0          
user-67488ff854-l4m9b           1/1     Running   0          
user-db-7bd86cdcd-tljg9         1/1     Running   0          

~~~

## Result

The planned **two-environment application deployment model is now fully present on the real target cluster**: the missing `sock-shop-prod` namespace was created successfully, and the production workload was then deployed from the source state into that namespace.

The successful end state is shown by these signals / verification points:

- `KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl apply -f deploy/kubernetes/kustomize/overlays/prod/namespace.yaml` completed successfully and returned:
  - `namespace/sock-shop-prod created`
- `KUBECONFIG=~/.kube/config-proxmox-dev.yaml kubectl get namespace sock-shop-dev sock-shop-prod` returned both expected application namespaces:
  - `sock-shop-dev   Active`
  - `sock-shop-prod  Active`
- `sudo kubectl get deploy,pods,svc -n sock-shop-prod` returned:
  - `No resources found in sock-shop-prod namespace.`
  which is the expected pre-apply state for an existing but still empty namespace
- `sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/prod` completed successfully and created:
  - all expected Sock Shop Services in `sock-shop-prod`
  - all expected Sock Shop Deployments in `sock-shop-prod`
- the transient early state with some `0/1` deployments resolved normally during startup
- `sudo kubectl wait --namespace sock-shop-prod --for=condition=available deployment --all --timeout=300s` completed successfully for all deployments
- `sudo kubectl get deploy,svc -n sock-shop-prod` finally showed:
  - all Deployments at `1/1`
  - all expected Services present
- `sudo kubectl get pods -n sock-shop-prod` finally showed:
  - all application Pods in `Running`
  - no MongoDB crash-loop behavior
- the selected rollout checks completed successfully:
  - `deployment "front-end" successfully rolled out`
  - `deployment "carts-db" successfully rolled out`
  - `deployment "orders-db" successfully rolled out`

These signals show that:

- the agreed dev/prod namespace baseline now exists on the real cluster
- both application environments are now structurally and operationally present
- the production workload can be created cleanly from the Phase-05 source state
- the earlier MongoDB issue is no longer blocking either environment in the normal deployment path

---

----

# Step 20 — Create the `prod` ingress rule for the front end and verify it locally through Traefik

## Rationale

The cluster now contains both application environments as real running workloads, not just planned namespaces. The development side already has a proven ingress path through Traefik, while the production side still exposes the front end only as an internal `ClusterIP` service.

Before Cloudflare Tunnel is introduced, the same local Traefik-based ingress proof should now be completed for the production environment as well. That keeps the public-entry work symmetrical and ensures that both environments already have a valid in-cluster routing path before any external hostname mapping is added on top.

## Action

The following work is done first in the local workstation repository checkout so the first `prod` ingress rule becomes part of the source state. After that, the target VM checkout is updated from GitHub again, the ingress is applied, and the local Traefik path is verified with a production-side hostname.

> [!NOTE] **🧩 Parallel ingress shape for dev and prod**
>
> The `dev` ingress path has already been proven successfully with:
>
> - a dedicated Ingress manifest
> - Traefik as ingress controller
> - a local hostname routed through the VM IP and `Host:` header
>
> The production ingress should now follow the same pattern so both environments share the same routing model before the external public edge is added.

### Local workstation

A production-side ingress manifest for the front end now needs to be added to the `prod` overlay and referenced from its `kustomization.yml`.

Create a new file:

`deploy/kubernetes/kustomize/overlays/prod/front-end-ingress.yaml`

with content like this:

~~~yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: front-end
  namespace: sock-shop-prod
spec:
  # Use the built-in K3s Traefik controller for this routing rule.
  ingressClassName: traefik
  rules:
    # Local prod hostname used first for Traefik-based verification.
    - host: prod.sockshop.local
      http:
        paths:
          # Forward all requests for this host to the front-end service.
          - path: /
            pathType: Prefix
            backend:
              service:
                name: front-end
                port:
                  number: 80
~~~

Then add this new `front-end-ingress.yaml`-file to the `resources:` section of `.../overlays/prod/kustomization.ym`:

~~~yaml
# deploy/kubernetes/kustomize/overlays/prod/kustomization.yml

# Overlay input:
# - prod namespace object
# - shared Sock Shop base manifests
# - prod-specific storefront ingress rule
resources:
  - namespace.yaml
  - ../../../manifests
  - front-end-ingress.yaml
~~~

After saving those file changes, continue with the normal Git flow:

~~~bash
# Stage the new ingress file and the updated prod overlay kustomization.
git add deploy/kubernetes/kustomize/overlays/prod/kustomization.yml deploy/kubernetes/kustomize/overlays/prod/front-end-ingress.yaml

# Commit the first prod ingress rule.
git commit -m "feat(target-delivery): add prod ingress for sock-shop front-end"

# Push the updated Phase-05 branch so the target VM can sync to it.
git push
~~~

### Target VM

Once the branch is pushed, the repository checkout on the target VM needs to be updated again so the new ingress rule can be applied from source.

~~~bash
# Show the current branch / dirty state before syncing.
$ git status -sb

# Fetch the newest branch state from GitHub.
$ git fetch origin

# Align the target checkout to the latest remote Phase-05 branch state.
$ git reset --hard origin/feat/proxmox-target-delivery

# Apply the prod overlay again so the new ingress resource is created.
$ sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/prod
...
deployment.apps/user unchanged
deployment.apps/user-db unchanged
ingress.networking.k8s.io/front-end created

# Show the ingress object in the prod namespace.
$ sudo kubectl get ingress -n sock-shop-prod
NAME        CLASS     HOSTS                 ADDRESS       PORTS   
front-end   traefik   prod.sockshop.local   10.10.10.20   80      

# Show the detailed ingress definition as stored in the cluster.
$ sudo kubectl describe ingress front-end -n sock-shop-prod
Name:             front-end
Namespace:        sock-shop-prod
Address:          10.10.10.20
Ingress Class:    traefik
Default backend:  <default>
Rules:
  Host                 Path  Backends
  ----                 ----  --------
  prod.sockshop.local  
                       /   front-end:80 (10.42.0.109:8079)
~~~

### Local ingress verification on the target VM

Once the ingress object exists, it can be tested directly through Traefik on the target VM by sending the intended production hostname in the request header.

~~~bash
# Send a request to Traefik on the VM IP while simulating the intended prod hostname.
$ curl -I -H 'Host: prod.sockshop.local' http://10.10.10.20/
HTTP/1.1 200 OK
...

# Fetch the first lines of the returned HTML through the production ingress path.
$ curl -s -H 'Host: prod.sockshop.local' http://10.10.10.20/ | head -n 10
<!DOCTYPE html>
<html lang="en">

<head>
~~~

## Result

The **`prod` ingress rule for the Sock Shop front end was created successfully**, and the **production-side routing path** now works **locally through Traefik** in the same way the development-side ingress path already did.

The successful end state is shown by these signals / verification points:

- the local repository stayed clean after the commit and push
- the new production ingress commit was pushed successfully:
  - `feat(target-delivery): add prod ingress for sock-shop front-end`
- the target VM checkout was updated successfully to:
  - `69697f6 feat(target-delivery): add prod ingress for sock-shop front-end`
- `sudo kubectl apply -k deploy/kubernetes/kustomize/overlays/prod` completed successfully and created:
  - `ingress.networking.k8s.io/front-end`
- `kubectl get ingress -n sock-shop-prod` showed:
  - ingress name `front-end`
  - ingress class `traefik`
  - host `prod.sockshop.local`
  - address `10.10.10.20`
- `kubectl describe ingress front-end -n sock-shop-prod` confirmed the intended routing:
  - host `prod.sockshop.local`
  - path `/`
  - backend service `front-end:80`
- `curl -I -H 'Host: prod.sockshop.local' http://10.10.10.20/` returned:
  - `HTTP/1.1 200 OK`
- `curl -s -H 'Host: prod.sockshop.local' http://10.10.10.20/ | head -n 10` returned the Sock Shop storefront HTML

These signals show that:

- the `prod` overlay now contains a working ingress rule
- Traefik now routes both application environments locally by hostname
- both in-cluster ingress paths are in place before the public Cloudflare edge is added

---
