# ▶️ Runbook — Phase 06 (Observability & Health): private Grafana/Prometheus baseline on the real target cluster

> ## About
> This document is the short rerun guide for **Phase 06 (Observability & Health)**.
> It is meant as a quick rerun reference without the long-form diary.
>
> For the full build story, rationale, and sources, see: **[IMPLEMENTATION.md](./IMPLEMENTATION.md)**.
> For the phase-local decision record, see: **[DECISIONS.md](./DECISIONS.md)**.
> For top-level project navigation, see: **[../INDEX.md](../INDEX.md)**.
> For the broader planning view, see: **[../ROADMAP.md](../ROADMAP.md)**.

---

## Index

- [**Goal**](#goal)
- [**Preconditions**](#preconditions)
- [**Step 0 — Re-check cluster reachability**](#step-0--re-check-cluster-reachability)
- [**Step 1 — Create the values file, prepare the local Grafana secret override, and install the monitoring baseline**](#step-1--create-the-values-file-prepare-the-local-grafana-secret-override-and-install-the-monitoring-baseline)

- [**Step 2 — Open Grafana privately and confirm login works**](#step-2--open-grafana-privately-and-confirm-login-works)
- [**Step 3 — Generate light storefront traffic and verify namespace-level Grafana visibility**](#step-3--generate-light-storefront-traffic-and-verify-namespace-level-grafana-visibility)
- [**Step 4 — Verify Prometheus scrape health privately**](#step-4--verify-prometheus-scrape-health-privately)
- [**Cleanup / reset**](#cleanup--reset)
- [**Files added / modified in this phase**](#files-added--modified-in-this-phase)

---

## Goal

Recreate the proven **Phase 06 observability baseline** so that:

- The `monitoring` namespace exists on the real Proxmox-backed target cluster
- The maintained Helm chart **`kube-prometheus-stack`** is installed successfully
- The core monitoring components are running
- Grafana is reachable privately through `kubectl port-forward`
- Prometheus is reachable privately through `kubectl port-forward`
- Namespace-level workload data for `sock-shop-prod` is visible in Grafana
- The Prometheus `/targets` page shows the core monitoring targets in the `UP` state

---

## Preconditions

- The real Proxmox-backed target cluster from Phase 05 exists and is reachable
- The local workstation already has working `kubectl` access through the Tailnet-based kubeconfig path
- Helm is available on the workstation
- The production Sock Shop environment is reachable at:
  - `https://prod-sockshop.cdco.dev`
- A writable local repository checkout is available

---

## Step 0 — Re-check cluster reachability

At this point, it is useful to confirm that the workstation still reaches the real target cluster through the existing Tailnet-based kubeconfig path.

From the repo checkout:

~~~bash
# Reuse the already working Tailnet-based kubeconfig path.
$ export KUBECONFIG=~/.kube/config-proxmox-dev.yaml

# Confirm that the workstation still reaches the real target cluster.
$ kubectl get nodes -o wide
NAME                        STATUS   ROLES           VERSION        INTERNAL-IP        EXTERNAL-IP   OS-IMAGE
ubuntu-2404-k3s-target-01   Ready    control-plane   v1.34.6+k3s1   <redacted-vm-ip>   <none>        Ubuntu 24.04.4 LTS

# Confirm that the application namespaces already exist.
$ kubectl get namespace sock-shop-dev sock-shop-prod
NAME             STATUS
sock-shop-dev    Active
sock-shop-prod   Active
~~~

## Step 1 — Create the values file, prepare the local Grafana secret override, and install the monitoring baseline

Before the monitoring stack can be installed reproducibly, the phase-specific chart input files need to exist locally under:

- `deploy/kubernetes/observability/`

### Create the Phase-06 values file

Create the directory `deploy/kubernetes/observability/` if it does not exist yet.

Then create the baseline values file below as:

- `deploy/kubernetes/observability/prometheus-values-minimal.yaml`

~~~yaml
defaultRules:
  create: false

alertmanager:
  enabled: false

grafana:
  enabled: true
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 300m
      memory: 256Mi

prometheus:
  prometheusSpec:
    retention: 2h
    storageSpec: {}
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
      limits:
        cpu: 500m
        memory: 1Gi
~~~

### Ensure the local secrets override stays gitignored

Add the following entry to `.gitignore` so the local Grafana password override remains untracked:

~~~gitignore
# Local Helm secrets override for Phase 06 observability
deploy/kubernetes/observability/prometheus-local.secrets.yaml
~~~

### Create the local Grafana secret override file

Create the local-only Helm override file below as:

- `deploy/kubernetes/observability/prometheus-local.secrets.yaml`

This file is used to pass the Grafana admin password locally without committing it into the tracked repository state.

~~~yaml
grafana:
  adminPassword: "REPLACE_WITH_LOCAL_GRAFANA_ADMIN_PASSWORD"
~~~

### Install or refresh the monitoring baseline

~~~bash
# Add and refresh the Prometheus Community Helm repository.
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
"prometheus-community" has been added to your repositories

$ helm repo update
Update Complete. ⎈Happy Helming!⎈

# Install or upgrade the monitoring stack.
# observability = chosen Helm release name for this deployed chart instance
# prometheus-community/kube-prometheus-stack = chart reference (repo/chart)
# --install runs an install if the release does not exist yet
# --create-namespace creates the namespace if missing
# --wait waits for resources to become ready
# --wait-for-jobs also waits for chart jobs to finish
$ helm upgrade --install observability prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f deploy/kubernetes/observability/prometheus-values-minimal.yaml \
  -f deploy/kubernetes/observability/prometheus-local.secrets.yaml \
  --wait \
  --wait-for-jobs \
  --timeout 10m
NAME: observability
...
STATUS: deployed
...

# Confirm the namespace and the core monitoring workloads.
$ kubectl get namespace monitoring
NAME         STATUS   AGE
monitoring   Active   ...

$ kubectl get pods -n monitoring
NAME                                                  READY   STATUS    RESTARTS
observability-grafana-...                             3/3     Running   0
observability-kube-prometh-operator-...               1/1     Running   0
observability-kube-state-metrics-...                  1/1     Running   0
observability-prometheus-node-exporter-...            1/1     Running   0
prometheus-observability-kube-prometh-prometheus-0    2/2     Running   0

# Confirm that the chart-managed Grafana Secret exists.
$ kubectl get secret observability-grafana -n monitoring
NAME                    TYPE     DATA   AGE
observability-grafana   Opaque   3      ...
~~~

## Step 2 — Open Grafana privately and confirm login works

With the monitoring stack now running, the next useful rerun step is to reopen Grafana through the private local tunnel path.

~~~bash
# Reuse the correct kubeconfig in this terminal.
$ export KUBECONFIG=~/.kube/config-proxmox-dev.yaml

# Open a private local tunnel to the Grafana service.
$ kubectl port-forward -n monitoring svc/observability-grafana 3000:80
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
...
~~~

Then open:

- `http://localhost:3000`

Sign in with:

- **Username:** `admin`
- **Password:** the value configured in:
  - `deploy/kubernetes/observability/prometheus-local.secrets.yaml`

If local port `3000` is already in use, the same command can be run with another local port, for example `3001:80`, and the browser can then use `http://localhost:3001`.

## Step 3 — Generate light storefront traffic and verify namespace-level Grafana visibility

To make current workload activity easier to see in Grafana, a small amount of repeated storefront traffic can be generated before opening the namespace dashboard.

### Optional helper: run the Phase-06 traffic generator

This phase also introduces a small repository helper script for repeatable recent storefront activity:

- `scripts/observability/generate-sockshop-traffic.sh`

Create that file with the following initial minimal Phase-06 contents:

~~~bash
#!/usr/bin/env bash

COOKIE_JAR=/tmp/sockshop-cookies.txt

while true; do
  echo "------------ $(date '+%H:%M:%S') ------------"

  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] home:    %{http_code}\n" \
    https://prod-sockshop.cdco.dev/

  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] category:%{http_code}\n" \
    https://prod-sockshop.cdco.dev/category.html

  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] basket:  %{http_code}\n" \
    https://prod-sockshop.cdco.dev/basket.html

  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] detail:  %{http_code}\n" \
    "https://prod-sockshop.cdco.dev/detail.html?id=3395a43e-2d88-40de-b95f-e00e1502085b"

  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] formal:  %{http_code}\n" \
    "https://prod-sockshop.cdco.dev/category.html?tags=formal"

  sleep 1
done
~~~

Then make the script executable and run it:

~~~bash
$ chmod +x scripts/observability/generate-sockshop-traffic.sh
$ ./scripts/observability/generate-sockshop-traffic.sh
~~~

### Verify namespace-level visibility in Grafana

Inside Grafana:

1. Open **Dashboards**
2. Search for:
   - **`Kubernetes / Compute Resources / Namespace (Pods)`**
3. Open that dashboard
4. Set the namespace filter to:
   - `sock-shop-prod`

The dashboard should show namespace-level workload data such as memory usage, pod-level resource information, and network activity for the production namespace.

## Step 4 — Verify Prometheus scrape health privately

The final rerun step is to confirm that Prometheus is reachable privately and that the monitoring targets are visible and healthy.

~~~bash
# Reuse the correct kubeconfig in a second terminal.
$ export KUBECONFIG=~/.kube/config-proxmox-dev.yaml

# Open a private local tunnel to Prometheus.
$ kubectl port-forward -n monitoring svc/observability-kube-prometh-prometheus 9090:9090
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090
...
~~~

Then open:

- `http://localhost:9090/targets`

The `/targets` page should show the core monitoring targets, with the relevant monitoring jobs mostly in the `UP` state.

If local port `9090` is already in use, the same command can be run with another local port, for example `9091:9090`, and the browser can then use `http://localhost:9091`.

---

## Cleanup / reset

To stop the private local tunnels, return to the corresponding `kubectl port-forward` terminals and press `Ctrl+C`.

If a clean reinstall is needed:

~~~bash
# Remove the Helm release.
$ helm uninstall observability -n monitoring

# Remove the monitoring namespace.
$ kubectl delete namespace monitoring
~~~

Then repeat the runbook from **Step 1**.

---

## Files added / modified in this phase

### Files added in this phase

- `deploy/kubernetes/observability/prometheus-values-minimal.yaml`
- `project-docs/06-observability/IMPLEMENTATION.md`
- `project-docs/06-observability/RUNBOOK.md`
- `project-docs/06-observability/DECISIONS.md`
- `scripts/observability/generate-sockshop-traffic.sh`

### Files modified in this phase

- `.gitignore`
- `README.md`
- `project-docs/INDEX.md`
- `project-docs/ROADMAP.md`
- `project-docs/DECISIONS.md`

### Local-only file used in this phase

- `deploy/kubernetes/observability/prometheus-local.secrets.yaml`