# Implementation Log — Phase 09 (Disaster Recovery & Rollback): Backup, recovery, nd rollback readiness on the Proxmox-based target cluster

> ## About
> This document is the implementation log and detailed build diary for **Phase 09 (Disaster Recovery & Rollback)**.
> It records the backup baseline, restore validation, recovery proof, rollback model, and platform-rebuild path so the work remains auditable and reproducible.
>
> For top-level project navigation, see: **[INDEX.md](../INDEX.md)**.
> For cross-phase incident and anomaly tracking, see: **[DEBUG-LOG.md](../DEBUG-LOG.md)**.
> For the broader project planning view, see: **[ROADMAP.md](../ROADMAP.md)**.
>
> Note: This phase deliberately does **not** attempt to convert the current single-node target into a full high-availability platform. The current target is a single-node K3s platform, so the recovery model is **backup + rebuild + redeploy**, not automatic failover.

---

## Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done (Phase 09)**](#definition-of-done-phase-09)
- [**Preconditions**](#preconditions)
- [**Step 1 — Add the DR project structure and implement the backup script**](#step-1--add-the-dr-project-structure-and-implement-the-backup-script)
- [**Step 2 — Run the backup proof against `sock-shop-dev` and `sock-shop-prod`, then validate one MongoDB dump**](#step-2--run-the-backup-proof-against-sock-shop-dev-and-sock-shop-prod-then-validate-one-mongodb-dump)
- [**Step 3 — Prove recovery and rollback paths safely**](#step-3--prove-recovery-and-rollback-paths-safely)
- [**Step 4 — Connect the DR model to the platform rebuild and delivery path**](#step-4--connect-the-dr-model-to-the-platform-rebuild-and-delivery-path)
- [**Phase 09 outcome summary**](#phase-09-outcome-summary)
- [**Sources**](#sources)

---

## Purpose / Goal

### Establish a practical disaster-recovery and rollback baseline

Phase 09 establishes the project’s first practical disaster-recovery and rollback baseline.

By the end of this phase, the project proves:

- **(1)** **Kubernetes namespace state** can be exported into a **local backup folder**
- **(2)** Sock Shop **database pods** can be targeted for **MongoDB dump** 
- **(3)** **Backup artifacts** are kept out of Git
- **(4)** **Container-level failure recovery** is safely demonstrated in the live traget `sock-shop-dev`
- **(5)** **Rollback paths are documented** for both **Git-based** and **Kubernetes-level rollback**
- **(6)** **Node/VM failure recovery** is **documented** for the current **single-node target** 

**Final recovery model:**

- **Container failure:** 
  - Kubernetes recreates failed pods through Deployment reconciliation
- **Application rollback:** 
  - Git-based revert + PR gate + redeploy
  - Kubernetes rollout undo is only used as an emergency runtime rollback
- **Node/VM failure:** 
  - Rebuild/redeploy from the documented Proxmox baseline, Phase 08 IaC proof, Kubernetes setup, GitHub Actions delivery path, and backup artifacts.
- **Database backup:** 
  - A namespace-level backup script is utilized that executed MongoDB dump attempts for sock-shop DB pods.

---

## Definition of done (Phase 09)

Phase 09 is considered done when the following conditions are met:

- A local DR backup helper exists under `scripts/dr/`
- Generated backup artifacts are written to `backups/` and excluded from Git
- Kubernetes namespace state can be exported for `sock-shop-dev` and `sock-shop-prod`
- MongoDB-compatible data-store pods are backed up through logical dump archives where `mongodump` is available
- At least one MongoDB dump artifact is restored and queried in a temporary local container
- Container-level recovery is proven safely in `sock-shop-dev`
- Kubernetes rollout inspection and emergency rollback commands are documented
- The node/VM recovery model is connected to the documented platform rebuild and delivery path
- Remaining hardening boundaries are documented as follow-up scope, not hidden as completed work

> [!NOTE] **Disaster recovery baseline**
>
> A **disaster recovery baseline** defines how the project can recover after something breaks. In this phase, the baseline **focuses on practical recovery readiness**: 
> - Creating backup artifacts 
> - Proving pod recovery 
> - Documenting backup, insepction and rollback commands 
> - Describing how the single-node target can be rebuilt and redeployed if needed

---

> [!NOTE] **Common failure modes covered in this phase**
>
> Phase 09 focuses on the failure modes that fit the current project architecture:
>
> - **Application pod/container failure:** Kubernetes can recreate failed pods through Deployments.
> - **Bad rollout or broken Deployment revision:** Kubernetes rollback commands provide an emergency revert path.
> - **Database/data-store state risk:** Backup artifacts preserve Kubernetes state and MongoDB-compatible data-store dumps where available.
> - **Single-node VM loss:** The current K3s target does not provide automatic node failover, so recovery is documented as rebuild, redeploy, and restore from available artifacts.

---

> [!NOTE] **Logical database dump**
>
> A **logical database dump** exports database contents through the database engine itself, for example with `mongodump` for MongoDB. The output is a portable archive that can later be restored into a compatible database.
>
> This is different from a **physical backup** or **storage snapshot**, which copies database files, volumes, or disks at the storage layer.
>
> For this project, a logical dump is the better first DR baseline because it is:
>
> - easy to run from the existing Kubernetes pods,
> - portable across environments,
> - small enough for a lightweight proof,
> - and independent from Proxmox or storage-level snapshot tooling.

---

> [!NOTE] **MongoDB and `mongodump`**
>
> **MongoDB** is a document database used by several Sock Shop data-store pods.  
> **`mongodump`** is MongoDB’s logical backup utility. It can export database contents into an archive file.
>
> In this phase, the backup helper checks each known data-store pod first. If `mongodump` is available, the script streams a compressed archive into the local backup folder. If `mongodump` is not available, the pod is skipped and the reason is written to `backup-report.txt`.
>
> The created archive is a real **restoreable MongoDB dump artifact**. 

---

## Preconditions

- The Proxmox-backed K3s target cluster from Phase 05 exists and is reachable
- The application environments `sock-shop-dev` and `sock-shop-prod` already exist on the target cluster
- The workstation has working `kubectl` access through the target kubeconfig
- Docker is available locally for the temporary MongoDB restore validation container
- The Phase 07 live validation targets are available for post-recovery smoke testing
- The Phase 04, Phase 05, and Phase 08 docs exist as the rebuild and IaC reference path for the node/VM recovery model

---

## Step 1 — Add the DR project structure and implement the backup script

### Rationale

Despite the already implemented DevOps capabilities, one central part is still missing: a **disaster-recovery baseline** that shows how the project can **preserve state and recover from common failure modes**.

This step creates the project’s DR-backup folder structure and implements a **backup script tailored to the current project state**:

- **Single-node Proxmox-based K3s cluster**
- **Namespace-separated Sock Shop environments** (`sock-shop-dev`, `sock-shop-prod`)
- **Kubernetes-managed application resources** such as Deployments, Services, Ingress, ConfigMaps, Pods, and PVC visibility
- **Sock Shop data-store pods**, including **MongoDB-compatible pods** that can be backed up through **logical `mongodump` archives**

The **backup script** needs to focus on capturing the recovery-relevant state layers of the application environment: The state of the Kubernetes cluster and the state of the Database: 

- **(1) Kubernetes state:** Export namespaced resources that describe the running application environment.
- **(2) Database state:** Create **logical database dumps** from the Sock Shop database pods that support **`mongodump`**.

The backup script must provide a **repeatable and auditable DR baseline** that can be executed safely against `sock-shop-dev` first and later against `sock-shop-prod` when needed.

### Action

#### Backup Script

The backup script is placed under `scripts/dr/backup-k8s-namespace.sh`. It's output in form of backup artifacts is written to the new `backups/` directory, which should be excluded from Git: 

~~~gitignore
# Phase 09 DR local backup artifacts
backups/
~~~

In this phase, the backup script functions as a **K8s State & Data Backup Helper**: It creates **one timestamped recovery package for a selected Sock Shop namespace** and combines Kubernetes resource exports with MongoDB dumps:

- **(1)** It collects the **application recovery state** for the selected **Kubernetes namespace**:
  - **Kubernetes namespace state**, so the deployed application shape can be inspected later
  - **MongoDB dump archives** from the Sock Shop database pods, where `mongodump` is available

- **(2)** Its output is **one timestamped local backup artifact per run**, written to the local `backups/` directory. The script exports **no Kubernetes Secret values**; it records **only Kubernetes Secret metadata**.
  - `backups/<namespace>_<timestamp>/k8s/` — holds Kubernetes resource exports and status snapshots
  - `backups/<namespace>_<timestamp>/db/` — contains MongoDB dump archives and the database backup report
    - Each database dump artifact is a portable MongoDB archive that can be restored to a compatible MongoDB instance.

**Avoiding the Dependency Trap:** The following backup script also avoids a common container-backup issue: Instead of writing database dumps inside a container first and then copying them out with `kubectl cp`, it **streams database dumps through `kubectl exec`**.
- **Minimal container-side dependency:** The database container only needs to run `mongodump`; the archive itself is written directly to the local backup folder on the workstation.
- **No `tar` dependency:** This keeps the backup script independent of extra tools such as `tar`, which may be missing in hardened or minimal container images.
- **No temporary pod disk footprint:** The script also avoids leaving temporary dump files inside running database pods.

~~~bash
#!/usr/bin/env bash
#
# scripts/dr/backup-k8s-namespace.sh
#
# =============================================================================
#  SOCK-SHOP DR: K8S NAMESPACE BACKUP HELPER
# =============================================================================
#
# PURPOSE:
#   Create a local disaster-recovery backup snapshot for a Sock Shop namespace.
#   Each run creates a unique, timestamped directory:
#   .
#   ├── backups
#   │   ├── sock-shop-dev_20260427T203209Z
#   │   │   ├── db
#   │   │   │   ├── backup-report.txt
#   │   │   │   ├── carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
#   │   │   │   ├── orders-db_orders-db-944d776bc-hwgqt.archive.gz
#   │   │   │   └── user-db_user-db-7bd86cdcd-xwm7b.archive.gz
#   │   │   ├── k8s
#   │   │   │   ├── all-resources-wide.txt
#   │   │   │   ├── configmaps.yaml
#   │   │   │   ├── deployments.yaml
#   │   │   │   ├── ingress.yaml
#   │   │   │   ├── namespace.yaml
#   │   │   │   ├── persistent-volumes-wide.txt
#   │   │   │   ├── pods.yaml
#   │   │   │   ├── pvc.yaml
#   │   │   │   ├── secrets-metadata.txt
#   │   │   │   └── services.yaml
#   │   │   └── README.txt
#
# BACKUP SCOPE:
# - Resource State: Full K8s namespace/resource state as YAML and text snapshots
# - Security: Metadata-only Secret inventory, without exporting secret values
# - Databases: Compressed MongoDB dumps from several Sock Shop DB pods that support 'mongodump'
#
# USAGE:
#   ./scripts/dr/backup-k8s-namespace.sh sock-shop-dev
#   ./scripts/dr/backup-k8s-namespace.sh sock-shop-prod
#
# MAKE TARGETS:
#   make p09-dr-backup-dev
#   make p09-dr-backup-prod
#  

# -----------------------------------------------------------------------------
# Shell safety
# -----------------------------------------------------------------------------

# Fail fast on errors, unset variables, and failed pipeline commands.
set -euo pipefail

# -----------------------------------------------------------------------------
# Input validation and kubeconfig selection
# -----------------------------------------------------------------------------


NAMESPACE="${1:-}"

# Accept only the known application namespaces.
# This prevents accidental execution against unrelated namespaces.
case "$NAMESPACE" in
  sock-shop-dev|sock-shop-prod)
    ;;
  *)
    echo "ERROR: Usage: $0 <sock-shop-dev|sock-shop-prod>" >&2
    exit 1
    ;;
esac

# Default to the Proxmox target kubeconfig unless the caller provides another one.
KUBECONFIG_PATH="${KUBECONFIG_PATH:-$HOME/.kube/config-proxmox-dev.yaml}" 
export KUBECONFIG

# Fail early if the selected kubeconfig file is missing.
if [ ! -f "$KUBECONFIG" ]; then
  echo "ERROR: Kubeconfig not found: ${KUBECONFIG}" >&2
  echo "INFO: Set KUBECONFIG=/path/to/kubeconfig to use another cluster." >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# Backup configuration
# -----------------------------------------------------------------------------


# Use a UTC timestamp so backup folders sort naturally and remain timezone-independent.
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
BACKUP_DIR="backups/${NAMESPACE}_${TIMESTAMP}"

# Known Sock Shop database pods:
# (not the generated db pod names - juts stable k8s workload prefixes 
# used to fetch the actual generated db names) 
DB_TARGETS=(
  "carts-db"
  "catalogue-db"
  "orders-db"
  "session-db"
  "user-db"
)

# Kubernetes resource types to export for inspection
RESOURCE_TYPES=(
  "deployments"
  "services"
  "ingress"
  "configmaps"
  "pvc"
  "pods"
)

# -----------------------------------------------------------------------------
# Script startup banner and local backup folders
# -----------------------------------------------------------------------------

echo "============================================================"
echo "Starting DR backup for namespace: ${NAMESPACE}"
echo "Kubeconfig: ${KUBECONFIG}"
echo "Destination: ${BACKUP_DIR}"
echo "============================================================"

# Verify that kubectl is available before starting.
if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERROR: kubectl is required but was not found in PATH." >&2
  exit 1
fi

# Display the active Kubernetes context 
echo "Kubernetes context: $(kubectl config current-context)"

# Verify that the namespace exists and is reachable.
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "ERROR: Namespace not found or not reachable: ${NAMESPACE}" >&2
  exit 1
fi

# Create local backup folders.
mkdir -p "${BACKUP_DIR}/k8s"
mkdir -p "${BACKUP_DIR}/db"

# Write a short local backup manifest.
cat > "${BACKUP_DIR}/README.txt" <<EOF
Sock Shop DR backup snapshot

Namespace: ${NAMESPACE}
Created UTC: ${TIMESTAMP}

Contents:
- k8s/: Kubernetes resource snapshots and metadata
- db/: MongoDB dump archives, if mongodump was available in the target DB pods
EOF

# -----------------------------------------------------------------------------
# Kubernetes namespace state export
# -----------------------------------------------------------------------------

echo
echo "[1/2] Exporting Kubernetes resource state..."

# Snapshot a broad status view first for quick inspection.
kubectl get all -n "$NAMESPACE" -o wide > "${BACKUP_DIR}/k8s/all-resources-wide.txt"

# Export the namespace object itself.
kubectl get namespace "$NAMESPACE" -o yaml > "${BACKUP_DIR}/k8s/namespace.yaml"

# Namespaced Resources
# Export resource definitions for the chosen namespace 
# Missing resource types must be tolerated to avoid crashing the script (see 'set -e') 
#   - '2>/dev/null' : Silences "not found" error messages to keep output clean.
#   - '|| true'     : Forces a success exit code to prevent script crash and to keep the loop going 
for resource in "${RESOURCE_TYPES[@]}"; do
  echo "  -> Exporting ${resource}"
  kubectl get "$resource" -n "$NAMESPACE" -o yaml > "${BACKUP_DIR}/k8s/${resource}.yaml" 2>/dev/null || true
done

# Cluster-Scoped Resources
# Export PersistentVolumes (PV)  
# PVs are exported separately because they are cluster-scoped.
kubectl get pv -o wide > "${BACKUP_DIR}/k8s/persistent-volumes-wide.txt" 2>/dev/null || true

# Export Secret metadata only.
# (not the full Secret YAML to avoid including encoded secret values)
kubectl get secrets -n "$NAMESPACE" \
  -o custom-columns=NAME:.metadata.name,TYPE:.type,CREATED:.metadata.creationTimestamp \
  > "${BACKUP_DIR}/k8s/secrets-metadata.txt" 2>/dev/null || true

# -----------------------------------------------------------------------------
# Logical database dump attempts
# -----------------------------------------------------------------------------

echo
echo "[2/2] Attempting MongoDB dumps for database pods..."

# Define the report path and truncate/clear the file to ensure a clean state for this run.
# The null command (:) ensures the file is empty before we begin appending results.
DB_REPORT="${BACKUP_DIR}/db/backup-report.txt"
: > "$DB_REPORT"


# Iterate through each database service to locate pods and stream 
# compressed logical backups directly to the local backup directory 
for db_target in "${DB_TARGETS[@]}"; do
  echo "  -> Checking database target: '${db_target}'"

  # Get the pod name on base of the 'name'-label  
  # (i.e. the generated name = base-name (service name prefix) + pod tempölate hash, e.g. 'carts-db-544c5bc9c8-bd67j'
  # - '-l "name=..."'   : Filters by the 'name' label 
  # - '-o jsonpath=...' : Extracts the 'metadata.name' 
  pod_name="$(kubectl get pods -n "$NAMESPACE" -l "name=${db_target}" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

  # Fallback: Find the pod by its name prefix, If the label search failed,  
  # Pod names change, but the service name prefix is persistent. So awk 
  # is used here to filter pods starting with that prefix.
  if [ -z "$pod_name" ]; then
    pod_name="$(kubectl get pods -n "$NAMESPACE" --no-headers \
      -o custom-columns=':metadata.name' 2>/dev/null \
      | awk -v prefix="${db_target}-" 'index($0, prefix) == 1 { print; exit }')"
  fi

  if [ -z "$pod_name" ]; then
    echo "     SKIP: No running pod found for ${db_target}"
    echo "${db_target}: SKIPPED - no pod found" >> "$DB_REPORT"
    continue
  fi

  echo "     Pod: ${pod_name}"

  # Check whether 'mongodump' exists inside the target container before trying to dump data
  # otherwise skip (and append teh skip to the db report) - and move to the next DB  
  #  - 'kubectl exec': Executes the check command directly inside the running Pod.
  #  - '--': Separates kubectl arguments from the command being run inside the container.
  #  - 'sh -c': Invokes a shell inside the container to run the 'command -v' check.
  #  - 'command -v mongodump': Returns success (0) if the binary is found in the PATH.
  if ! kubectl exec -n "$NAMESPACE" "$pod_name" -- sh -c 'command -v mongodump >/dev/null 2>&1' 2>/dev/null; then
    echo "     SKIP: mongodump not available in ${pod_name}"
    echo "${db_target}: SKIPPED - mongodump not available in ${pod_name}" >> "$DB_REPORT"
    continue
  fi

  # Construct a unique filename for the database dump 
  dump_file="${BACKUP_DIR}/db/${db_target}_${pod_name}.archive.gz"

  # Execute the dump and stream it directly to the local workstation.
  #
  # This way 'kubectl cp' can be avoided, which depends on 'tar' being installed 
  # on the target Pod's container - and might be not available there. 
  # In hardened or minimalist production images (like Distroless or Alpine), 'tar' 
  # is often removed to reduce the attack surface and image size.
  #
  # Streaming via STDOUT (>) allows us to:
  #   1. Backup data from ANY container, regardless of installed utilities.
  #   2. Avoid using temporary disk space inside the Pod (preventing 'Disk Full' crashes).
  #   3. Transfer data directly to the local host filesystem in one step.
  #
  # - mongodump: MongoDB utility that creates a logical export of the database 
  # - --archive: streams everything into one single output instead of a folder/files..
  # - --gzip: Compresses the data stream on-the-fly (reduces network traffic and local storage size).
  # - > "$dump_file": Redirects the container's stdout directly to the dump_file on the local machine. 
  if kubectl exec -n "$NAMESPACE" "$pod_name" -- sh -c 'mongodump --archive --gzip' > "$dump_file"; then
    if [ -s "$dump_file" ]; then
      echo "     OK: Dump saved to ${dump_file}"
      echo "${db_target}: OK - ${dump_file}" >> "$DB_REPORT"
    else
      echo "     WARN: Dump file was created but is empty for ${db_target}"
      echo "${db_target}: WARN - empty dump file" >> "$DB_REPORT"
      rm -f "$dump_file"
    fi
  else
    echo "     WARN: mongodump failed for ${db_target}"
    echo "${db_target}: WARN - mongodump failed" >> "$DB_REPORT"
    rm -f "$dump_file"
  fi
done

# -----------------------------------------------------------------------------
# Completion summary
# -----------------------------------------------------------------------------

echo
echo "============================================================"
echo "Backup completed."
echo "Backup folder: ${BACKUP_DIR}"
echo "Database report: ${DB_REPORT}"
echo "============================================================"
~~~

To ensure, the script is executable and syntactically correct:

~~~bash
# Make the backup script executable.
$ chmod +x scripts/dr/backup-k8s-namespace.sh

# Validate Bash syntax without running the script.
# -n = read commands and check syntax, but do not execute them.
$ bash -n scripts/dr/backup-k8s-namespace.sh
~~~

#### Make Targets

For easy reruns and consitency with the other implementation phases, Makefile helpers for the DR path are added as well. DR backup targets use the remote Proxmox target kubeconfig by default, while the small Kubernetes helper target provides a reusable way to inspect one live dev pod by its stable `name=<component>` label.

~~~make
# -----------------------------------------------------------------------------
# Phase 09 — Disaster Recovery & Rollback helpers
# -----------------------------------------------------------------------------

p09-dr-script-syntax:
  @# Validate Bash syntax of the Phase 09 DR backup script.
  @if bash -n $(P09_DR_BACKUP_SCRIPT); then \
    echo "OK: Bash syntax valid -> $(P09_DR_BACKUP_SCRIPT)" >&2; \
  else \
    echo "FAIL: Bash syntax invalid -> $(P09_DR_BACKUP_SCRIPT)" >&2; \
    exit 1; \
  fi

p09-dr-backup-dev:
  @# Run the Phase 09 DR backup script against the dev namespace.
  @KUBECONFIG=$(REMOTE_KUBECONFIG) $(P09_DR_BACKUP_SCRIPT) sock-shop-dev

p09-dr-backup-prod:
  @# Run the Phase 09 DR backup script against the prod namespace.
  @KUBECONFIG=$(REMOTE_KUBECONFIG) $(P09_DR_BACKUP_SCRIPT) sock-shop-prod	
 
p09-dr-print-report-dev:
  @# Print the database backup report, k8s artifact list, and archive details from the latest dev backup.
  @latest_backup="$$(find backups -maxdepth 1 -type d -name 'sock-shop-dev_*' | sort | tail -n 1)"; \
  if [ -z "$$latest_backup" ]; then \
    echo "FAIL: No dev backup folder found under backups/" >&2; \
    echo "INFO: To create a dev backup, run 'make p09-dr-backup-dev'" >&2; \
    exit 1; \
  fi; \
  echo "RUN: Print database backup report for dev -> $$latest_backup/db/backup-report.txt" >&2; \
  cat "$$latest_backup/db/backup-report.txt"; \
  echo; \
  echo "RUN: Show generated backup k8s artifact list for dev -> $$latest_backup" >&2; \
  find "$$latest_backup" -maxdepth 3 -type f | sort; \
  echo; \
  echo "RUN: Show MongoDB archive dump details for dev -> $$latest_backup/db" >&2; \
  find "$$latest_backup/db" -maxdepth 1 -type f -name '*.archive.gz' -ls

p09-dr-print-report-prod:
  @# Print the database backup report, k8s artifact list, and archive details from the latest prod backup.
  @latest_backup="$$(find backups -maxdepth 1 -type d -name 'sock-shop-prod_*' | sort | tail -n 1)"; \
  if [ -z "$$latest_backup" ]; then \
    echo "FAIL: No prod backup folder found under backups/" >&2; \
    echo "INFO: To create a prod backup, run 'make p09-dr-backup-prod'" >&2; \
    exit 1; \
  fi; \
  echo "RUN: Print database backup report for prod -> $$latest_backup/db/backup-report.txt" >&2; \
  cat "$$latest_backup/db/backup-report.txt"; \
  echo; \
  echo "RUN: Show generated backup k8s artifact list for prod -> $$latest_backup" >&2; \
  find "$$latest_backup" -maxdepth 3 -type f | sort; \
  echo; \
  echo "RUN: Show MongoDB archive dump details for prod -> $$latest_backup/db" >&2; \
  find "$$latest_backup/db" -maxdepth 1 -type f -name '*.archive.gz' -ls

k8s-show-live-dev-pod:
  @# Show one live dev pod selected by the stable Kubernetes name label.
  @if [ -z "$(COMPONENT)" ]; then \
    echo "FAIL: COMPONENT is required" >&2; \
    echo "INFO: Example: make k8s-show-live-dev-pod-by-label COMPONENT=front-end" >&2; \
    exit 1; \
  fi
  @pod_name="$$(KUBECONFIG=$(REMOTE_KUBECONFIG) kubectl get pods -n sock-shop-dev -l name=$(COMPONENT) -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"; \
  if [ -z "$$pod_name" ]; then \
    echo "FAIL: No pod found in sock-shop-dev with label name=$(COMPONENT)" >&2; \
    exit 1; \
  fi; \
  echo "RUN: Show live dev pod -> name=$(COMPONENT), pod=$$pod_name" >&2; \
  KUBECONFIG=$(REMOTE_KUBECONFIG) kubectl get pod -n sock-shop-dev "$$pod_name" -o wide	

~~~

**The Makefile targets above wrap the following raw commands:**
The Makefile targets above wrap the following raw commands:

~~~bash
# -----------------------------------------------------------------------------
# p09-dr-script-syntax
# DR backup helper syntax check
# -----------------------------------------------------------------------------

# Validate the DR backup helper syntax without executing it.
# -n = read commands and check Bash syntax only.
bash -n scripts/dr/backup-k8s-namespace.sh


# -----------------------------------------------------------------------------
# p09-dr-backup-dev
# Remote dev backup
# -----------------------------------------------------------------------------

# Run the DR backup helper against the dev namespace on the Proxmox target cluster.
# KUBECONFIG points kubectl to the remote target cluster instead of the local laptop cluster.
KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml" \
  scripts/dr/backup-k8s-namespace.sh sock-shop-dev


# -----------------------------------------------------------------------------
# p09-dr-backup-prod
# Remote prod backup
# -----------------------------------------------------------------------------

# Run the DR backup helper against the prod namespace on the Proxmox target cluster.
# This uses the same remote kubeconfig but switches the namespace argument.
KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml" \
  scripts/dr/backup-k8s-namespace.sh sock-shop-prod


# -----------------------------------------------------------------------------
# p09-dr-print-report-dev
# Latest dev backup report and artifacts
# -----------------------------------------------------------------------------

# Find the latest dev backup folder.
# $(...) runs the find/sort/tail pipeline and stores the resulting folder path.
latest_backup="$(find backups -maxdepth 1 -type d -name 'sock-shop-dev_*' | sort | tail -n 1)"

# Print the database backup report from the latest dev backup.
cat "$latest_backup/db/backup-report.txt"

# Show all generated backup artifacts from the latest dev backup.
find "$latest_backup" -maxdepth 3 -type f | sort

# Show MongoDB archive dump details from the latest dev backup.
find "$latest_backup/db" -maxdepth 1 -type f -name '*.archive.gz' -ls


# -----------------------------------------------------------------------------
# p09-dr-print-report-prod
# Latest prod backup report and artifacts
# -----------------------------------------------------------------------------

# Find the latest prod backup folder.
latest_backup="$(find backups -maxdepth 1 -type d -name 'sock-shop-prod_*' | sort | tail -n 1)"

# Print the database backup report from the latest prod backup.
cat "$latest_backup/db/backup-report.txt"

# Show all generated backup artifacts from the latest prod backup.
find "$latest_backup" -maxdepth 3 -type f | sort

# Show MongoDB archive dump details from the latest prod backup.
find "$latest_backup/db" -maxdepth 1 -type f -name '*.archive.gz' -ls


# -----------------------------------------------------------------------------
# k8s-show-live-dev-pod COMPONENT=front-end
# Live dev pod inspection by component label
# -----------------------------------------------------------------------------

# Select the current pod for one component in the dev namespace.
# The project uses the stable Kubernetes label shape name=<component>.
COMPONENT="front-end"
POD_NAME="$(KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml" \
  kubectl get pods -n sock-shop-dev -l name="$COMPONENT" \
  -o jsonpath='{.items[0].metadata.name}')"

# Show the selected live dev pod on the Proxmox target cluster.
KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml" \
  kubectl get pod -n sock-shop-dev "$POD_NAME" -o wide
~~~


### Result

Step 1 establishes the project’s first executable DR backup path:

- Dedicated local `backups/` and `scripts/dr/` folders
- The local `backups/` folder is excluded from Git
- Make targets were implemented for backup script syntax checks, execution and reports 
- The backup script:
  - exports Kubernetes namespace state for later inspection
  - creates MongoDB dump archives from database pods where `mongodump` is available
  - targets known database pods explicitly instead of relying on broad `grep` matches
  - uses a fallback pod-name lookup if label-based lookup is not sufficient
  - continues with the remaining database pods if one pod is missing, lacks `mongodump`, or fails to dump
  - avoids the `kubectl cp` / `tar` dependency trap by streaming dumps through `kubectl exec`
  - avoids exporting Kubernetes Secret values and records only Secret metadata
  - writes a database backup report so skipped or failed dump attempts remain visible
  - is wrapped by Makefile helpers for repeatable execution

---

## Step 2 — Run the backup proof against `sock-shop-dev` and `sock-shop-prod`, then validate one MongoDB dump

### Rationale

Before anchroing our **K8s State & Data Backup Helper** as a valid backup baseline, the script must be executed against the safe `dev` environment.

The goal of this step is a **non-destructive backup proof**: 
- verify that **recovery artifacts can be created and inspected** 
- **without deleting live resources** or **restoring data into a running environment**.

The `dev` namespace is used first because it is the safest environment for proof and evidence collection, leaving the production environment unaffected.

> [!NOTE] **Non-destructive backup proof**
>
> A **non-destructive backup proof** verifies that backup artifacts can be created w**ithout intentionally breaking or restoring the live environment**.
>
> In this phase, the goal is to proof:
>
> - The backup command runs successfully
> - The script exports Kubernetes namespace state
> - Logical Database dump attempts are made for the known DB pods - and captured successfully for those of them, who actually support `mongodump` 
> - Backup artifacts are produced locally in a local, gitignored `backup/` folder.
> - Secret values are not exported
> - The script does **not** delete pods, wipe databases, or restore data into the running cluster.
>
> A full restore drill can be added later as a separate exercise, ideally against a disposable namespace or disposable test cluster.

### Action 

The fopllowing make targets run from the repo root perform a **syntax check** followed by the actual **`dev` backup** against the corresponding live target cluster environment: 

#### Live Dev Backup

~~~bash
$ make p09-dr-script-syntax
OK: Bash syntax valid -> scripts/dr/backup-k8s-namespace.sh

$ make p09-dr-backup-dev
============================================================
Starting DR backup for namespace: sock-shop-dev
Kubeconfig: $HOME/.kube/config-proxmox-dev.yaml
Destination: backups/sock-shop-dev_20260427T203209Z
============================================================
Kubernetes context: default

[1/2] Exporting Kubernetes resource state...
  -> Exporting deployments
  -> Exporting services
  -> Exporting ingress
  -> Exporting configmaps
  -> Exporting pvc
  -> Exporting pods

[2/2] Attempting MongoDB dumps for database pods...
  -> Checking database target: 'carts-db'
     Pod: carts-db-6bb589dd85-sdgdh
2026-04-27T20:32:12.669+0000    writing admin.system.version to archive on stdout
2026-04-27T20:32:12.677+0000    done dumping admin.system.version (1 document)
2026-04-27T20:32:12.678+0000    writing data.cart to archive on stdout
2026-04-27T20:32:12.680+0000    writing data.item to archive on stdout
2026-04-27T20:32:12.726+0000    done dumping data.item (30 documents)
2026-04-27T20:32:12.729+0000    done dumping data.cart (130 documents)
     OK: Dump saved to backups/sock-shop-dev_20260427T203209Z/db/carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
  -> Checking database target: 'catalogue-db'
     Pod: catalogue-db-74885c6d4c-xtrxj
     SKIP: mongodump not available in catalogue-db-74885c6d4c-xtrxj
  -> Checking database target: 'orders-db'
     Pod: orders-db-944d776bc-hwgqt
2026-04-27T20:32:14.086+0000    writing admin.system.version to archive on stdout
2026-04-27T20:32:14.100+0000    done dumping admin.system.version (1 document)
     OK: Dump saved to backups/sock-shop-dev_20260427T203209Z/db/orders-db_orders-db-944d776bc-hwgqt.archive.gz
  -> Checking database target: 'session-db'
     Pod: session-db-5d89f4b5bb-9cwbx
     SKIP: mongodump not available in session-db-5d89f4b5bb-9cwbx
  -> Checking database target: 'user-db'
     Pod: user-db-7bd86cdcd-xwm7b
2026-04-27T20:32:15.354+0000    writing users.cards to archive on stdout
2026-04-27T20:32:15.390+0000    writing users.customers to archive on stdout
2026-04-27T20:32:15.393+0000    writing users.addresses to archive on stdout
2026-04-27T20:32:15.397+0000    done dumping users.cards (4 documents)
2026-04-27T20:32:15.399+0000    done dumping users.customers (3 documents)
2026-04-27T20:32:15.399+0000    done dumping users.addresses (4 documents)
     OK: Dump saved to backups/sock-shop-dev_20260427T203209Z/db/user-db_user-db-7bd86cdcd-xwm7b.archive.gz

============================================================
Backup completed.
Backup folder: backups/sock-shop-dev_20260427T203209Z
Database report: backups/sock-shop-dev_20260427T203209Z/db/backup-report.txt
============================================================
~~~

#### Live Prod Backup

A live prod backup can be created as easily using the corresponding make target:

~~~bash
$ make p09-dr-backup-prod
============================================================
Starting DR backup for namespace: sock-shop-prod
Kubeconfig: $HOME/.kube/config-proxmox-dev.yaml
Destination: backups/sock-shop-prod_20260427T204004Z
============================================================
Kubernetes context: default

[1/2] Exporting Kubernetes resource state...
  -> Exporting deployments
  -> Exporting services
  -> Exporting ingress
  -> Exporting configmaps
  -> Exporting pvc
  -> Exporting pods

[2/2] Attempting MongoDB dumps for database pods...
  -> Checking database target: 'carts-db'
     Pod: carts-db-6bb589dd85-vfcts
2026-04-27T20:40:09.213+0000    writing admin.system.version to archive on stdout
2026-04-27T20:40:09.262+0000    done dumping admin.system.version (1 document)
2026-04-27T20:40:09.262+0000    writing data.cart to archive on stdout
2026-04-27T20:40:09.295+0000    writing data.item to archive on stdout
2026-04-27T20:40:09.368+0000    done dumping data.cart (211 documents)
2026-04-27T20:40:09.371+0000    done dumping data.item (17 documents)
     OK: Dump saved to backups/sock-shop-prod_20260427T204004Z/db/carts-db_carts-db-6bb589dd85-vfcts.archive.gz
  -> Checking database target: 'catalogue-db'
     Pod: catalogue-db-74885c6d4c-g26tv
     SKIP: mongodump not available in catalogue-db-74885c6d4c-g26tv
  -> Checking database target: 'orders-db'
     Pod: orders-db-944d776bc-tj657
2026-04-27T20:40:10.610+0000    writing admin.system.version to archive on stdout
2026-04-27T20:40:10.656+0000    done dumping admin.system.version (1 document)
     OK: Dump saved to backups/sock-shop-prod_20260427T204004Z/db/orders-db_orders-db-944d776bc-tj657.archive.gz
  -> Checking database target: 'session-db'
     Pod: session-db-5d89f4b5bb-27wkl
     SKIP: mongodump not available in session-db-5d89f4b5bb-27wkl
  -> Checking database target: 'user-db'
     Pod: user-db-7bd86cdcd-tljg9
2026-04-27T20:40:12.350+0000    writing users.cards to archive on stdout
2026-04-27T20:40:12.351+0000    writing users.addresses to archive on stdout
2026-04-27T20:40:12.351+0000    writing users.customers to archive on stdout
2026-04-27T20:40:12.358+0000    done dumping users.cards (4 documents)
2026-04-27T20:40:12.362+0000    done dumping users.customers (3 documents)
2026-04-27T20:40:12.363+0000    done dumping users.addresses (4 documents)
     OK: Dump saved to backups/sock-shop-prod_20260427T204004Z/db/user-db_user-db-7bd86cdcd-tljg9.archive.gz

============================================================
Backup completed.
Backup folder: backups/sock-shop-prod_20260427T204004Z
Database report: backups/sock-shop-prod_20260427T204004Z/db/backup-report.txt
============================================================
~~~

#### Proof

---

**Dev backup script run with Kubernetes state export and database dump attempts**

![Dev backup script run with Kubernetes state export and database dump attempts](./evidence/01-DR-dev-backup-script-run-success.png)

*Figure 1: The Phase 09 backup helper runs successfully against `sock-shop-dev`. The output shows Kubernetes resource export starting first, followed by database dump attempts for the known Sock Shop database pods. Dumps succeed for `carts-db`, `orders-db`, and `user-db`, while `catalogue-db` and `session-db` are skipped because `mongodump` is not available in those containers. This proves the intended behavior: unavailable dump tooling in one pod does not stop the whole backup run.*

---

**Prod backup script run with Kubernetes state export and database dump attempts**

![Prod backup script run with Kubernetes state export and database dump attempts](./evidence/02-DR-prod-backup-script-run-success.png)

*Figure 2: The Phase 09 backup helper runs also successfully against `sock-shop-prod`.*

---

**Inspect the generated backup folder with backup artifacts for `dev` and `prod`:**

~~~bash
# Show the generated backup files
$ find backups -maxdepth 4 -type f | sort
backups/sock-shop-dev_20260427T203209Z/db/backup-report.txt
backups/sock-shop-dev_20260427T203209Z/db/carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
backups/sock-shop-dev_20260427T203209Z/db/orders-db_orders-db-944d776bc-hwgqt.archive.gz
backups/sock-shop-dev_20260427T203209Z/db/user-db_user-db-7bd86cdcd-xwm7b.archive.gz
backups/sock-shop-dev_20260427T203209Z/k8s/all-resources-wide.txt
backups/sock-shop-dev_20260427T203209Z/k8s/configmaps.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/deployments.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/ingress.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/namespace.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/persistent-volumes-wide.txt
backups/sock-shop-dev_20260427T203209Z/k8s/pods.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/pvc.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/secrets-metadata.txt
backups/sock-shop-dev_20260427T203209Z/k8s/services.yaml
backups/sock-shop-dev_20260427T203209Z/README.txt
backups/sock-shop-prod_20260427T204004Z/db/backup-report.txt
backups/sock-shop-prod_20260427T204004Z/db/carts-db_carts-db-6bb589dd85-vfcts.archive.gz
backups/sock-shop-prod_20260427T204004Z/db/orders-db_orders-db-944d776bc-tj657.archive.gz
backups/sock-shop-prod_20260427T204004Z/db/user-db_user-db-7bd86cdcd-tljg9.archive.gz
backups/sock-shop-prod_20260427T204004Z/k8s/all-resources-wide.txt
backups/sock-shop-prod_20260427T204004Z/k8s/configmaps.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/deployments.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/ingress.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/namespace.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/persistent-volumes-wide.txt
backups/sock-shop-prod_20260427T204004Z/k8s/pods.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/pvc.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/secrets-metadata.txt
backups/sock-shop-prod_20260427T204004Z/k8s/services.yaml
backups/sock-shop-prod_20260427T204004Z/README.txt
~~~

Inspect the database backup report for dev and prod:

~~~bash
# DEV REPORT
# Print the database backup report, k8s artifact list, and archive details from the latest dev backup
$ make p09-dr-print-report-dev

RUN: Print database backup report for dev -> backups/sock-shop-dev_20260427T203209Z/db/backup-report.txt
carts-db: OK - backups/sock-shop-dev_20260427T203209Z/db/carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
catalogue-db: SKIPPED - mongodump not available in catalogue-db-74885c6d4c-xtrxj
orders-db: OK - backups/sock-shop-dev_20260427T203209Z/db/orders-db_orders-db-944d776bc-hwgqt.archive.gz
session-db: SKIPPED - mongodump not available in session-db-5d89f4b5bb-9cwbx
user-db: OK - backups/sock-shop-dev_20260427T203209Z/db/user-db_user-db-7bd86cdcd-xwm7b.archive.gz

RUN: Show generated backup k8s artifact list for dev -> backups/sock-shop-dev_20260427T203209Z
backups/sock-shop-dev_20260427T203209Z/db/backup-report.txt
backups/sock-shop-dev_20260427T203209Z/db/carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
backups/sock-shop-dev_20260427T203209Z/db/orders-db_orders-db-944d776bc-hwgqt.archive.gz
backups/sock-shop-dev_20260427T203209Z/db/user-db_user-db-7bd86cdcd-xwm7b.archive.gz
backups/sock-shop-dev_20260427T203209Z/k8s/all-resources-wide.txt
backups/sock-shop-dev_20260427T203209Z/k8s/configmaps.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/deployments.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/ingress.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/namespace.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/persistent-volumes-wide.txt
backups/sock-shop-dev_20260427T203209Z/k8s/pods.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/pvc.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/secrets-metadata.txt
backups/sock-shop-dev_20260427T203209Z/k8s/services.yaml
backups/sock-shop-dev_20260427T203209Z/README.txt

RUN: Show MongoDB archive dump details for dev -> backups/sock-shop-dev_20260427T203209Z/db
  6428259      4 -rw-rw-r--   1    337 Apr 27 22:32 backups/sock-shop-dev_20260427T203209Z/db/orders-db_orders-db-944d776bc-hwgqt.archive.gz
  6428252      8 -rw-rw-r--   1   5773 Apr 27 22:32 backups/sock-shop-dev_20260427T203209Z/db/carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
  6428261      4 -rw-rw-r--   1   1038 Apr 27 22:32 backups/sock-shop-dev_20260427T203209Z/db/user-db_user-db-7bd86cdcd-xwm7b.archive.gz

# PROD REPORT
# Print the database backup report, k8s artifact list, and archive details from the latest prod backup
$ make p09-dr-print-report-prod

RUN: Print database backup report for prod -> backups/sock-shop-prod_20260427T204004Z/db/backup-report.txt
carts-db: OK - backups/sock-shop-prod_20260427T204004Z/db/carts-db_carts-db-6bb589dd85-vfcts.archive.gz
catalogue-db: SKIPPED - mongodump not available in catalogue-db-74885c6d4c-g26tv
orders-db: OK - backups/sock-shop-prod_20260427T204004Z/db/orders-db_orders-db-944d776bc-tj657.archive.gz
session-db: SKIPPED - mongodump not available in session-db-5d89f4b5bb-27wkl
user-db: OK - backups/sock-shop-prod_20260427T204004Z/db/user-db_user-db-7bd86cdcd-tljg9.archive.gz

RUN: Show generated backup k8s artifact list for prod -> backups/sock-shop-prod_20260427T204004Z
backups/sock-shop-prod_20260427T204004Z/db/backup-report.txt
backups/sock-shop-prod_20260427T204004Z/db/carts-db_carts-db-6bb589dd85-vfcts.archive.gz
backups/sock-shop-prod_20260427T204004Z/db/orders-db_orders-db-944d776bc-tj657.archive.gz
backups/sock-shop-prod_20260427T204004Z/db/user-db_user-db-7bd86cdcd-tljg9.archive.gz
backups/sock-shop-prod_20260427T204004Z/k8s/all-resources-wide.txt
backups/sock-shop-prod_20260427T204004Z/k8s/configmaps.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/deployments.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/ingress.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/namespace.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/persistent-volumes-wide.txt
backups/sock-shop-prod_20260427T204004Z/k8s/pods.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/pvc.yaml
backups/sock-shop-prod_20260427T204004Z/k8s/secrets-metadata.txt
backups/sock-shop-prod_20260427T204004Z/k8s/services.yaml
backups/sock-shop-prod_20260427T204004Z/README.txt

RUN: Show MongoDB archive dump details for prod -> backups/sock-shop-prod_20260427T204004Z/db
  6428372      4 -rw-rw-r--   1    337 Apr 27 22:40 backups/sock-shop-prod_20260427T204004Z/db/orders-db_orders-db-944d776bc-tj657.archive.gz
  6428373      4 -rw-rw-r--   1   1038 Apr 27 22:40 backups/sock-shop-prod_20260427T204004Z/db/user-db_user-db-7bd86cdcd-tljg9.archive.gz
  6428369     12 -rw-rw-r--   1   8263 Apr 27 22:40 backups/sock-shop-prod_20260427T204004Z/db/carts-db_carts-db-6bb589dd85-vfcts.archive.gz
~~~

---

**Generated DR backup folder with Kubernetes exports and database artifacts for dev and prod**

![Generated DR backup folder with Kubernetes exports and database artifacts for `dev` and `prod`](./evidence/03-DR-dev-and-prod-backup-artifact-tree.png)

*Figure 3: The generated timestamped `backup` folders contain the expected DR artifact structure for both live target cluster environments `dev` and `prod`, here shown here side by side: `db/`, `k8s/` plus `README.md`*

---

**Dev: Expanded DR backup folder with Kubernetes exports and database artifacts**

![Dev: Expanded DR backup folder with Kubernetes exports and database artifacts](./evidence/04-DR-dev-backup-artifact-tree-expanded.png)

*Figure 4: The expanded timestamped backup folder for teh dev-environment reveals the contents of the aritifact structure: The `db/` folder includes the database backup report plus MongoDB archive dumps for the database pods where `mongodump` was available. The `k8s/` folder contains Kubernetes resource exports and status snapshots, including Deployments, Services, Ingress, ConfigMaps, Pods, PVC visibility, PersistentVolume visibility, namespace metadata, and Secret metadata without Secret values. This proves that the backup helper creates a structured, target environment-specific local recovery package - while keeping generated backup artifacts outside the repository.*

---

**Prod: Expanded DR backup folder with Kubernetes exports and database artifacts**

![Prod: Expanded DR backup folder with Kubernetes exports and database artifacts](./evidence/05-DR-prod-backup-artifact-tree-expanded.png)

*Figure 5: The expanded timestamped backup folder for the prod-environment.*

---

#### Mongo DB dump restore validation

As a **final validation step**, one representative **MongoDB dump artifact is restored** into a **temporary local MongoDB container** and queried there. 

This does **not** restore data into `sock-shop-dev` or `sock-shop-prod`; it only proves that the selected dump archive is readable, restoreable, and contains concrete database records.

##### Validation flow

- (1) Inspect the live `user-db` state in the Proxmox target `dev` namespace and perform soem simple collection checks as validation baseline for a later comparison with the `user-db` restored from teh dump archive 
- (2) Select the latest local `user-db` dump archive from the backup folder and it into a disposable local MongoDB container.
- (3) Query the restored database with the same collection-checks used against the live database and compare the restored output with the live output.

##### Inspect the live `user-db` state first

Before validating the restored dump, the live `user-db` state is queried directly from the running Proxmox target dev pod:

~~~bash
# Find the live user-db pod in the Proxmox target dev namespace.
$ USER_DB_POD="$(KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml" \
  kubectl get pods -n sock-shop-dev -l name=user-db \
  -o jsonpath='{.items[0].metadata.name}')"
user-db-7bd86cdcd-xwm7b  

# Query live collection names, document counts, and document keys from the users database.
# - mongo users = open the MongoDB shell against the "users" database.
# --quiet       = keep output focused.
# --eval        = execute the MongoDB shell JavaScript expression and exit.
$ KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml" \
  kubectl exec -n sock-shop-dev "$USER_DB_POD" -- \
  mongo users --quiet --eval '
    print("LIVE USERS-DB-COLLECTIONS (NAMES, COUNT, SCHEMA):");
    db.getCollectionNames().sort().forEach(function(c) {
      print("----- " + c + " -----");
      var doc = db.getCollection(c).findOne();
      print(c + ".count=" + db.getCollection(c).count());
      print(c + ".keys=" + (doc ? Object.keys(doc).sort().join(",") : "<empty>"));
    })
  '
LIVE USERS-DB-COLLECTIONS (NAMES, COUNT, SCHEMA):  
----- addresses -----
addresses.count=4
addresses.keys=_id,city,country,number,postcode,street
----- cards -----
cards.count=4
cards.keys=_id,ccv,expires,longNum
----- customers -----
customers.count=3
customers.keys=_id,addresses,cards,firstName,lastName,password,salt,username  
~~~  
 
##### Restore the dump into a temporary MongoDB container

The following restore check verifies the selected backup artifact in two ways:

- The archived `user-db` dump can be restored into a queryable MongoDB instance.
- The restored `user-db` exposes the same collections, document counts, and document shape as the previously inspected live `user-db`.

For this verification a **disposable temporary local MongoDB container** is used, so the live `dev` and `prod` databases remain untouched. 

~~~bash
# Pick the latest local dev backup folder.
# - find backups            = search inside the local backups/ directory.
# - -maxdepth 1             = only inspect direct children of backups/, not nested files.
# - -type d                 = return directories only.
# - -name 'sock-shop-dev_*' = match timestamped dev backup folders.
# - sort                    = order matching folders 
# - tail -n 1               = keep the newest matching backup folder.
$ latest_backup="$(find backups -maxdepth 1 -type d -name 'sock-shop-dev_*' | sort | tail -n 1)"

$ echo "$latest_backup"
backups/sock-shop-dev_20260427T203209Z

# Find from inside the dev backup folder the user-db archive dump 
$ USER_DUMP="$(find "$latest_backup/db" -maxdepth 1 -type f -name 'user-db_*.archive.gz' | sort | tail -n 1)"

# Show the selected archive before the restore check.
$ echo "$USER_DUMP"
backups/sock-shop-dev_20260427T203209Z/db/user-db_user-db-7bd86cdcd-xwm7b.archive.gz

# Create and start a temporary local MongoDB container for the restore check 
# Uses the Docker image mongo:3.4 for compatibility with the legacy Sock Shop MongoDB dumps.
# --rm removes the container automatically after it is stopped.
# -d runs it in the background.
$ RESTORE_CHECK_CONTAINER="p09-mongo-restore-check"
$ docker run --rm -d --name "$RESTORE_CHECK_CONTAINER" mongo:3.4
39fa9be8bf0133289fde98848e5717f6b07debf3cb340691940093747456a583

# Wait until MongoDB is ready inside the temporary restore-check container.
# - docker exec                  = run a command inside the running container.
# - sh -c                        = run the quoted shell loop inside the container.
# - until ...; do sleep 1; done  = shell loop: retry once per second until the ping succeeds.
# - mongo --quiet --eval         = run a quiet MongoDB shell readiness check and exit.
# - >/dev/null 2>&1              = silence normal output and errors during the retry loop.
$ docker exec "$RESTORE_CHECK_CONTAINER" sh -c 'until mongo --quiet --eval "db.adminCommand({ ping: 1 })" >/dev/null 2>&1; do sleep 1; done'

# Copy the selected local dump archive from the workstation into the temporary container.
$ docker cp "$USER_DUMP" "$RESTORE_CHECK_CONTAINER:/tmp/user-db.archive.gz"
Successfully copied 1.04kB (transferred 3.07kB) to p09-mongo-restore-check:/tmp/user-db.archive.gz

# Restore the archive into the temporary MongoDB container.
# --archive = reads the specified archive file.
# --gzip    = decompress the gzip-compressed archive stream while restoring.
$ docker exec "$RESTORE_CHECK_CONTAINER" mongorestore --archive=/tmp/user-db.archive.gz --gzip
2026-04-28T08:36:03.706+0000    preparing collections to restore from
2026-04-28T08:36:03.720+0000    reading metadata for users.cards from archive '/tmp/user-db.archive.gz'
2026-04-28T08:36:03.731+0000    restoring users.cards from archive '/tmp/user-db.archive.gz'
2026-04-28T08:36:03.739+0000    no indexes to restore
2026-04-28T08:36:03.739+0000    finished restoring users.cards (4 documents)
2026-04-28T08:36:03.740+0000    reading metadata for users.customers from archive '/tmp/user-db.archive.gz'
2026-04-28T08:36:03.744+0000    restoring users.customers from archive '/tmp/user-db.archive.gz'
2026-04-28T08:36:03.745+0000    reading metadata for users.addresses from archive '/tmp/user-db.archive.gz'
2026-04-28T08:36:03.745+0000    restoring indexes for collection users.customers from metadata
2026-04-28T08:36:03.749+0000    restoring users.addresses from archive '/tmp/user-db.archive.gz'
2026-04-28T08:36:03.751+0000    finished restoring users.customers (3 documents)
2026-04-28T08:36:03.751+0000    no indexes to restore
2026-04-28T08:36:03.751+0000    finished restoring users.addresses (4 documents)
2026-04-28T08:36:03.751+0000    done

# Query restored collection counts from the temporary MongoDB container.
# - mongo users = open the MongoDB shell against the restored "users" database.
# - --quiet     = keep output focused on the printed counts.
# - --eval      = execute the JavaScript expression and exit.
$ docker exec "$RESTORE_CHECK_CONTAINER" mongo users --quiet --eval 'print("customers=" + db.customers.count()); print("cards=" + db.cards.count()); print("addresses=" + db.addresses.count())'
customers=3
cards=4
addresses=4

# Query restored collection names, document counts, and document keys from the temporary MongoDB container.
# This uses the same query shape as the live check above, so the restored dump can be compared directly.
docker exec "$RESTORE_CHECK_CONTAINER" mongo users --quiet --eval '
  db.getCollectionNames().sort().forEach(function(c) {
    print("RESTORED USERS-DB-COLLECTIONS (NAMES, COUNT, SCHEMA):");  
    print("----- " + c + " -----");
    var doc = db.getCollection(c).findOne();
    print(c + ".count=" + db.getCollection(c).count());
    print(c + ".keys=" + (doc ? Object.keys(doc).sort().join(",") : "<empty>"));
  })
'
RESTORED USERS-DB-COLLECTIONS (NAMES, COUNT, SCHEMA):  
----- addresses -----
addresses.count=4
addresses.keys=_id,city,country,number,postcode,street
----- cards -----
cards.count=4
cards.keys=_id,ccv,expires,longNum
----- customers -----
customers.count=3
customers.keys=_id,addresses,cards,firstName,lastName,password,salt,username  

# Remove the temporary restore-check container.
# -f = force removal; if the container is still running, Docker stops it first and then removes it.
$ docker rm -f "$RESTORE_CHECK_CONTAINER"
~~~

##### Validation result

- The selected `user-db` backup is present as an archive dump file. 
- The archive can be restored into a compatible MongoDB instance and queried successfully.
- The restored dump matches the previously inspected live `user-db` state from the target cluster's `dev`-namespace:
  - `addresses.count=4`
  - `cards.count=4`
  - `customers.count=3`
- The restored collection keys also match the live collection keys.:
  - `addresses.keys=_id,city,country,number,postcode,street`
  - `cards.keys=_id,ccv,expires,longNum`
  - `customers.keys=_id,addresses,cards,firstName,lastName,password,salt,username` 

This confirms that the backup contains concrete, restoreable database data without restoring anything into the live `dev` or `prod` environments.  

---

### Result

Step 2 proves that the project now has a working **DR backup baseline** for the `dev` environment.

The backup proof completed successfully:

- The backup script ran successfully against the remote target cluster environments `sock-shop-dev` + `sock-shop-prod`
- The backup helper defaults to the remote Proxmox target kubeconfig:
  - `~/.kube/config-proxmox-dev.yaml`
- A timestamped local backup folder was created under `backups/`
- Kubernetes namespace recovery state was exported locally
- Known database pods were targeted 
- MongoDB dump archives were created successfully for:
  - `carts-db`
  - `orders-db`
  - `user-db`
- The generated `.archive.gz` files are real MongoDB dump artifacts and were verified 
  - The live `user-db` collections, document counts, and document keys were queried as baseline for a restore check - and matched against the restored dump in a temporary MongoDB container 
- `catalogue-db` and `session-db` were skipped fcrom teh archive procedure:
  - `catalogue-db` uses the custom upstream `weaveworksdemos/catalogue-db:0.3.0` image and is not dumpable through `mongodump`
  - `session-db` uses `redis:alpine`, so MongoDB dump tooling is not applicable
- The script continued with the remaining data-store targets instead of failing early
- The result of every database target was recorded in `backup-report.txt`
- Generated backup artifacts remain local and gitignored

This confirms the **intended behavior** of the backup helper:

- The script creates a **structured local recovery package** from the live Proxmox target cluser
- It clearly **records which data-store dumps succeeded** and which ones were **skipped**
- It **does not abort the whole backup run** when one data-store container is not compatible with `mongodump`

**Scope boundary for the first DR baseline:** `catalogue-db` and `session-db` are recorded as skipped on purpose rather than treated as script failures:
- Phase 09 proves the backup path for Kubernetes namespace state and MongoDB-compatible data stores. 
- `session-db` uses Redis, and `catalogue-db` uses a custom upstream image without `mongodump`. 
- Redis-specific backup handling for `session-db` and image-specific backup handling for `catalogue-db` are important **follow-up hardening items** - but they are outside the scope this first DR backup baseline.

---

## Step 3 — Prove recovery and rollback paths safely

### Rationale

The project now provides the capability to capture database and k8s state in form of timestamped backup artifacts. But DR is about more than just backups: 

An application needs to be able to recover from failure and to rollback into a previous stable state after a bad release.

This step **proves a safe recovery path** directly on the **Proxmox target dev environment**:

- **Container-level failure recovery** through Kubernetes reconciliation

It also **documents further recovery paths** without performing risky destructive actions:

- **Node/VM recovery** for the current single-node target model
- **Git-based rollback**
- **Kubernetes emergency rollback**

The proof is executed against `sock-shop-dev` on the Proxmox target cluster, not against production.

### Preflight — Confirm backup artifacts before the recovery proof

Before testing recovery behavior, the latest `dev` backup package is inspected once. 

~~~bash
# Print the latest dev backup report, artifact list, and archive details.
# This confirms that Step 2 produced recovery artifacts before the recovery proof starts.
$ make p09-dr-print-report-dev
RUN: Print database backup report for dev -> backups/sock-shop-dev_20260427T203209Z/db/backup-report.txt
carts-db: OK - backups/sock-shop-dev_20260427T203209Z/db/carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
catalogue-db: SKIPPED - mongodump not available in catalogue-db-74885c6d4c-xtrxj
orders-db: OK - backups/sock-shop-dev_20260427T203209Z/db/orders-db_orders-db-944d776bc-hwgqt.archive.gz
session-db: SKIPPED - mongodump not available in session-db-5d89f4b5bb-9cwbx
user-db: OK - backups/sock-shop-dev_20260427T203209Z/db/user-db_user-db-7bd86cdcd-xwm7b.archive.gz

RUN: Show generated backup k8s artifact list for dev -> backups/sock-shop-dev_20260427T203209Z
backups/sock-shop-dev_20260427T203209Z/db/backup-report.txt
backups/sock-shop-dev_20260427T203209Z/db/carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
backups/sock-shop-dev_20260427T203209Z/db/orders-db_orders-db-944d776bc-hwgqt.archive.gz
backups/sock-shop-dev_20260427T203209Z/db/user-db_user-db-7bd86cdcd-xwm7b.archive.gz
backups/sock-shop-dev_20260427T203209Z/k8s/all-resources-wide.txt
backups/sock-shop-dev_20260427T203209Z/k8s/configmaps.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/deployments.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/ingress.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/namespace.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/persistent-volumes-wide.txt
backups/sock-shop-dev_20260427T203209Z/k8s/pods.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/pvc.yaml
backups/sock-shop-dev_20260427T203209Z/k8s/secrets-metadata.txt
backups/sock-shop-dev_20260427T203209Z/k8s/services.yaml
backups/sock-shop-dev_20260427T203209Z/README.txt

RUN: Show MongoDB archive dump details for dev -> backups/sock-shop-dev_20260427T203209Z/db
  6428259      4 -rw-rw-r--   1   337 Apr 27 22:32 backups/sock-shop-dev_20260427T203209Z/db/orders-db_orders-db-944d776bc-hwgqt.archive.gz
  6428252      8 -rw-rw-r--   1  5773 Apr 27 22:32 backups/sock-shop-dev_20260427T203209Z/db/carts-db_carts-db-6bb589dd85-sdgdh.archive.gz
  6428261      4 -rw-rw-r--   1  1038 Apr 27 22:32 backups/sock-shop-dev_20260427T203209Z/db/user-db_user-db-7bd86cdcd-xwm7b.archive.gz
~~~

This preflight confirms that recovery artifacts exist before the pod-recovery test starts. 

### Action A — Prove container-level recovery in dev

This action proves the recovery from one of the most common operational failure modes: pod/container failure:

- One application pod is deleted in `sock-shop-dev` on purpose 
- The Deployment definition remains unchanged 
- Kubernetes is expected to recreate that pod through the existing Deployment controller. 

This is safe executable recovery case because the pod is "disposable runtime state"; Kubernetes should be able to recreate it automatically from the existing Deployment controller.

If the replacement pod becomes healthy and the live smoke checks pass afterward, the project has demonstrated real self-healing behavior without touching production or persistent database state.

The proof stays limited to the Proxmox target `dev` namespace and does not touch production:

~~~bash
# Use the Proxmox target kubeconfig for this recovery proof.
$ export KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml"

# Show the active Kubernetes context for traceability.
$ kubectl config current-context
default

# Confirm that the dev namespace is running on the target K3s node.
$ kubectl get pods -n sock-shop-dev -o wide
NAME                            READY   STATUS      IP            NODE                        
carts-5f5859c84b-qbrjp          1/1     Running     10.42.0.92    ubuntu-2404-k3s-target-01              
carts-db-6bb589dd85-sdgdh       1/1     Running     10.42.0.73    ubuntu-2404-k3s-target-01              
catalogue-cd4ff8c9f-7mwmr       1/1     Running     10.42.0.94    ubuntu-2404-k3s-target-01              
catalogue-db-74885c6d4c-xtrxj   1/1     Running     10.42.0.97    ubuntu-2404-k3s-target-01              
front-end-7467866c7b-qwpvh      1/1     Running     10.42.0.93    ubuntu-2404-k3s-target-01              
orders-6b8dd47986-xx6wc         1/1     Running     10.42.0.98    ubuntu-2404-k3s-target-01              
orders-db-944d776bc-hwgqt       1/1     Running     10.42.0.95    ubuntu-2404-k3s-target-01              
payment-c5fbdbc6-822lj          1/1     Running     10.42.0.96    ubuntu-2404-k3s-target-01              
queue-master-7f965677fb-cppg8   1/1     Running     10.42.0.90    ubuntu-2404-k3s-target-01              
rabbitmq-59955f8bff-5j8gq       2/2     Running     10.42.0.99    ubuntu-2404-k3s-target-01              
session-db-5d89f4b5bb-9cwbx     1/1     Running     10.42.0.100   ubuntu-2404-k3s-target-01              
shipping-868cd6587d-r74f9       1/1     Running     10.42.0.101   ubuntu-2404-k3s-target-01              
user-67488ff854-x2wz7           1/1     Running     10.42.0.102   ubuntu-2404-k3s-target-01              
user-db-7bd86cdcd-xwm7b         1/1     Running     10.42.0.103   ubuntu-2404-k3s-target-01              
~~~

To record the current `front-end` pod before deletion.

~~~bash
# Verify the selected front-end pod before deletion.
$ make k8s-show-live-dev-pod COMPONENT=front-end
RUN: Show live dev pod -> name=front-end, pod=front-end-7467866c7b-qwpvh
NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE                        
front-end-7467866c7b-msxw6   1/1     Running   0          15m   <redacted-pod-ip>   ubuntu-2404-k3s-target-01   
~~~

Delete the selected pod and let the Kubernetes Deployment controller recreate it.

~~~bash
# Delete one front-end pod in dev.
# This is safe because the Deployment controller should create a replacement pod.
$ make k8s-delete-live-dev-pod COMPONENT=front-end 
RUN: Delete live dev pod -> name=front-end, pod=front-end-7467866c7b-msxw6
pod "front-end-7467866c7b-msxw6" deleted from sock-shop-dev namespace

# Use the Proxmox target kubeconfig.
$ export KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml"

# Wait until the front-end Deployment is available again.
$ kubectl rollout status deployment/front-end -n sock-shop-dev --timeout=180s
deployment "front-end" successfully rolled out

# Show the current front-end pod after recovery.
$ kubectl get pods -n sock-shop-dev -l name=front-end -o wide
NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE                        
front-end-7467866c7b-ttws7   1/1     Running   0          69s   10.42.0.148   ubuntu-2404-k3s-target-01              
~~~

Note: The names of the front-end pods differ:
- Original pod before deletion: `front-end-7467866c7b-msxw6` 
- New pod after recreation: `front-end-7467866c7b-ttws7` 

This is prove that the Kubernetes Deployment controller really detected the deleted `front-end` pod and recreate it.

To verify the new pods fucntionality we now run the already established live smoke validation tests:

~~~bash
# Run the Phase 07 live smoke checks after the recovery proof.
# This validates the live catalogue contract and browser smoke path.
$ make p07-tests-live
RUN: Phase 07 live Python contract smoke -> https://dev-sockshop.cdco.dev/catalogue
.                                                                            [100%]
1 passed in 0.44s
OK: Phase 07 live Python contract smoke passed
OK: Node.js tooling detected for Phase 07 Playwright smoke tests
RUN: Phase 07 Playwright setup -> tests/e2e
OK: Phase 07 Playwright environment ready -> tests/e2e
RUN: Phase 07 Playwright smoke -> https://dev-sockshop.cdco.dev (CI: false)
Running 2 tests using 1 worker
  ✓  1 [chromium] › smoke.spec.js:17:1 › storefront root loads and key landing content is visible (816ms)
  ✓  2 [chromium] › smoke.spec.js:32:1 › storefront renders at least one catalogue image (1.4s)
  2 passed (3.4s)
OK: Phase 07 Playwright smoke passed
~~~

**Result**: Pod recovery / self healing cluster is proven.

### Action B — Document Kubernetes rollback readiness 

This action documents the Kubernetes rollback path for a different failure mode than the pod recovery test above.

- Action A proved that Kubernetes can recover from a deleted runtime pod.  
- Action B focuses on a **bad Deployment revision** scenario: if a future rollout introduces a broken version, Kubernetes can revert the Deployment to a previous revision.

In the current project state, no rollback is executed because the `front-end` Deployment has only one recorded revision. The purpose here is therefore to inspect the rollout history and document the emergency rollback command without changing the working deployment.

~~~bash
# Use the Proxmox target kubeconfig.
$ export KUBECONFIG="$HOME/.kube/config-proxmox-dev.yaml"

# Show rollout history for the front-end Deployment.
# This checks whether previous Deployment revisions are available.
$ kubectl rollout history deployment/front-end -n sock-shop-dev
deployment.apps/front-end 
REVISION  CHANGE-CAUSE
1         <none>
~~~

The output shows one recorded Deployment revision. This means the current `front-end` Deployment has no older revision available for an actual rollback at this point.

The emergency rollback command is therefore documented as a reference command, but not executed in this phase:

~~~bash
# Emergency rollback command.
# Use this only if a bad Deployment revision must be reverted.
kubectl rollout undo deployment/front-end -n sock-shop-dev
~~~

After any real rollback, the validation path is:

~~~bash
# Verify the Deployment becomes healthy again after rollback.
kubectl rollout status deployment/front-end -n sock-shop-dev --timeout=180s

# Re-run live smoke checks after rollback.
make p07-tests-live
~~~

This records the rollback path **without forcing an artificial bad release**. 

The executable recovery proof for this phase remains the **pod deletion and successful recreation** from Action A.

### Action C — Document the node/VM recovery model

This action documents the recovery path for the larger failure case that Kubernetes cannot solve inside a single-node cluster: 
- loss of the node or VM itself. 

Instead of pretending that automatic high availability exists, the project documents the realistic rebuild, redeploy, and restore path for the current target architecture.

The current target platform is intentionally documented as a **single-node Proxmox-based K3s target**.

That means:

- Container/pod failure can recover automatically through Kubernetes reconciliation
- Full node/VM failure does **not** have automatic high-availability failover
- Node/VM recovery is based on rebuild and redeploy

The documented node/VM recovery path is:

1. Recreate the target VM baseline using the documented Proxmox template approach from Phase 04/05.
2. Use the Phase 08 Terraform smoke-VM proof as the IaC baseline that demonstrates reproducible Proxmox VM provisioning.
3. Reinstall or reconnect the required target-side access components:
   - K3s
   - Tailscale
   - Cloudflare Tunnel
4. Redeploy the application through the existing GitHub Actions/Kustomize target delivery path.
5. Recreate backup artifacts with the Phase 09 DR helper, or restore MongoDB-compatible data-store state from existing backup artifacts where available.
6. Re-run the validation paths:
   - `make p07-tests`
   - `make p07-tests-live`
   - relevant Trivy scan targets
   - relevant Terraform validation targets

> [!NOTE] **Single-node recovery scope**
>
> This project currently uses a single-node K3s target. Kubernetes can automatically replace failed pods on the running node, but it cannot fail over the whole cluster if the node or VM is gone.
>
> That limitation is documented intentionally. The recovery model for full node/VM loss is rebuild, redeploy, and restore where backup artifacts are available. A multi-node high-availability K3s setup would be a separate future hardening step.

### Result

Step 3 **proves the executable recovery path** that fits the current **single-node target architecture** and documents (but not forces) the recovery paths.

The successful end state is shown by these signals / verification points:

- The latest `sock-shop-dev` backup package was inspected before the recovery proof.
- The `front-end` pod in `sock-shop-dev` was deleted intentionally.
- Kubernetes recreated a new `front-end` pod through the existing Deployment controller.
- The replacement pod reached `Running` state with `READY` set to `1/1`.
- The pod name changed from the deleted runtime pod to a newly created replacement pod, proving that the workload was recreated rather than merely rechecked.
- The Phase 07 live validation bundle passed after the recovery proof:
  - Python live catalogue contract smoke test passed.
  - Playwright storefront smoke tests passed in Chromium.
- The Kubernetes rollout history was inspected for `front-end`.
- No artificial bad release was created because the current Deployment had only one recorded revision.
- The emergency `kubectl rollout undo` command path was documented without changing the healthy running deployment.
- Full node/VM recovery was documented as rebuild, redeploy, and restore where backup artifacts are available.

This confirms the Phase 09 recovery boundary:

- Kubernetes handles pod/container loss through Deployment reconciliation.
- Bad application releases should normally be handled through Git revert, protected PR validation, and redeployment.
- `kubectl rollout undo` remains an emergency runtime rollback command for Deployment revisions.
- Full node or VM loss is not automatically handled by the current single-node K3s target and requires rebuild/redeploy.

---

## Step 4 — Connect the DR model to the platform rebuild and delivery path

### Rationale

With backup creation, restore validation, pod recovery, and rollback commands now covered, the final Phase 09 documentation step is to connect those pieces to the rest of the platform path.

The current target platform is a single-node K3s platform on Proxmox VM `9200` - not a high-availability cluster. For this architecture, the correct recovery model is based on the already documented build and delivery chain:

- Phase 04 provides the reusable Proxmox VM-template baseline.
- Phase 05 provides the long-lived target VM, K3s runtime, private access path, public edge, and target-delivery workflow.
- Phase 08 provides the Terraform-backed Proxmox IaC proof with a disposable smoke VM.
- Phase 09 adds namespace backup artifacts, Mongo-compatible dump validation, pod recovery proof, and rollback guidance.

This step makes the DR story explicit: the project can recover common runtime failures automatically, and larger platform failures are handled through rebuild, redeploy, and restore from available artifacts.

### Action

The recovery model is documented as a layered recovery path:

| Failure mode | Recovery model | Proven or documented path |
| :--- | :--- | :--- |
| Application pod/container failure | Kubernetes Deployment reconciliation | Proven by deleting a `front-end` pod in `sock-shop-dev` and validating the replacement through live smoke checks |
| Bad application rollout | Git revert and redeploy as the normal path; `kubectl rollout undo` as emergency runtime rollback | Documented through rollout-history inspection and rollback command surface |
| Kubernetes namespace/application state loss | Reapply manifests and overlays, then inspect or restore available backup artifacts where applicable | Supported by Kustomize overlays, GitHub Actions delivery workflow, and Phase 09 namespace-state exports |
| MongoDB-compatible data-store loss | Restore from available `.archive.gz` dump artifacts into a compatible MongoDB target | Validated with the `user-db` dump restored into a temporary MongoDB container |
| Full target VM/node loss | Rebuild, redeploy, and restore where backup artifacts are available | Documented through the Phase 04 VM baseline, Phase 05 target-delivery model, Phase 08 Terraform proof, and Phase 09 backup artifacts |

The practical full-target recovery sequence is:

1. Recreate the Proxmox VM foundation from the documented Phase 04 baseline.
2. Recreate or replace the target runtime from the Phase 05 target-delivery model:
   - K3s
   - Tailscale private access
   - Cloudflare Tunnel public edge
   - Traefik ingress routing
3. Use the Phase 08 Terraform proof as the current IaC baseline for reproducible Proxmox VM provisioning.
4. Redeploy `sock-shop-dev` and `sock-shop-prod` through the GitHub Actions/Kustomize target-delivery path.
5. Use Phase 09 backup artifacts to inspect previous namespace state and restore Mongo-compatible data where applicable.
6. Validate the recovered platform through the established validation stack:
   - Deterministic tests
   - Live Python contract smoke checks
   - Playwright storefront smoke checks
   - Relevant security scan targets
   - Observability checks in Grafana and Prometheus

### Result

Step 4 completes the Phase 09 recovery story by connecting the DR baseline to the already documented platform build path.

The successful end state is shown by these signals / verification points:

- The recovery model is aligned with the actual single-node K3s target architecture.
- The documentation does not claim automatic node failover or full high availability.
- Container-level recovery is backed by an executable proof.
- Database recovery readiness is backed by a successful Mongo-compatible restore validation.
- Larger platform recovery is connected to the documented Phase 04, Phase 05, and Phase 08 implementation paths.
- The project now has teh following DR model:
  - backup
  - inspect
  - restore where available
  - redeploy
  - validate
  - document remaining hardening boundaries

This makes Phase 09 a practical disaster-recovery and rollback-readiness baseline.

---

## Phase 09 outcome summary

Phase 09 completes the project’s disaster-recovery and rollback readiness baseline.

The phase adds:

- A local DR backup script
- Kubernetes namespace-state export
- MongoDB dump attempts for known database pods
- Gitignored local backup artifacts
- Safe container-recovery proof in `sock-shop-dev`
- Rollback documentation
- Node/VM recovery documentation
- Final README and architecture-readiness notes

At the end of Phase 09, the project can be described as:

- deployed
- observable
- security-scanned
- dependency-aware
- IaC-backed
- tested
- merge-governed
- DR-documented
- rollback-ready

---

## Sources

### Step 1 — DR baseline, backup helper, and repository hygiene

- [Google SRE Book — Data Integrity](https://sre.google/sre-book/data-integrity/)  
  Backup integrity, recovery testing, and restoreability as part of operational reliability.

- [Google Cloud Architecture Framework — Perform testing for recovery from data loss](https://docs.cloud.google.com/architecture/framework/reliability/perform-testing-for-recovery-from-data-loss)  
  Backup validation through restore tests in a non-production environment.

- [Git documentation — `gitignore`](https://git-scm.com/docs/gitignore)  
  `.gitignore` patterns for generated local backup artifacts.

- [IBM Docs — Migrating DevOps Velocity from Docker Compose to Kubernetes or OpenShift](https://www.ibm.com/docs/en/devops-velocity/5.1.0?topic=mdv-migrating-devops-velocity-from-docker-compose-kubernetes-openshift)  
MongoDB export/restore (`mongodump --gzip --archive`, `docker cp`, `kubectl exec`, `mongorestore`).

- [OneUptime — How to Configure MongoDB Backups on Kubernetes](https://oneuptime.com/blog/post/2026-03-31-mongodb-configure-mongodb-backups-on-kubernetes/view)  
MongoDB backup script pattern (`mongodump`, timestamped backup output, backup storage).

- [CloudyTuts — How to Backup and Restore MongoDB Deployment on Kubernetes](https://www.cloudytuts.com/tutorials/kubernetes/how-to-backup-and-restore-mongodb-deployment-on-kubernetes/)  
    Kubernetes backup/restore (`kubectl exec`, `mongodump`, `mongorestore`).

- **Kubernetes documentation** — Resource export, Pod selection, in-Pod command execution, and Secret handling:
  - [Kubernetes Docs — `kubectl get`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/)
  - [Kubernetes Docs — JSONPath Support](https://kubernetes.io/docs/reference/kubectl/jsonpath/)
  - [Kubernetes Docs — `kubectl exec`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_exec/)
  - [Kubernetes Docs — `kubectl cp`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_cp/)
  - [Kubernetes Docs — Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
  - [Kubernetes Docs — Good practices for Kubernetes Secrets](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)

- **Shell scripting references** — Bash safety, arrays, redirection, Make recipes, and helper command patterns:
  - [GNU Bash Manual — The `set` builtin](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html)
  - [GNU Bash Manual — Redirections](https://www.gnu.org/software/bash/manual/html_node/Redirections.html)
  - [GNU Bash Manual — Arrays](https://www.gnu.org/software/bash/manual/html_node/Arrays.html)
  - [GNU Make Manual — Recipe Syntax](https://www.gnu.org/software/make/manual/html_node/Recipe-Syntax.html)
  - [GNU Findutils Manual — Directories / `-maxdepth`](https://www.gnu.org/software/findutils/manual/html_node/find_html/Directories.html)
  - [GNU Awk Manual — String Functions](https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html)

---

### Step 2 — MongoDB dump artifacts and restore validation

- [DEV Community — Backup and Restore MongoDB in a Docker Environment](https://dev.to/denisakp/backup-and-restore-mongodb-in-a-docker-environment-1ebb)  
  Docker-based restore flow, temporary MongoDB container creation incl. backup archive copy,  `mongorestore --gzip --archive`, validate restore behavior.

- **MongoDB documentation** — Logical dump and restore workflow:
  - [MongoDB Docs — `mongodump`](https://www.mongodb.com/docs/database-tools/mongodump/)
  - [MongoDB Docs — `mongodump` examples](https://www.mongodb.com/docs/database-tools/mongodump/mongodump-examples/)
  - [MongoDB Docs — `mongorestore`](https://www.mongodb.com/docs/database-tools/mongorestore/)
  - [MongoDB Docs — `mongorestore` examples](https://www.mongodb.com/docs/database-tools/mongorestore/mongorestore-examples/)

- **Docker documentation** — Temporary local restore-check container:
  - [Docker CLI Reference — `docker container run`](https://docs.docker.com/reference/cli/docker/container/run/)
  - [Docker CLI Reference — `docker container exec`](https://docs.docker.com/reference/cli/docker/container/exec/)
  - [Docker CLI Reference — `docker container cp`](https://docs.docker.com/reference/cli/docker/container/cp/)
  - [Docker CLI Reference — `docker container rm`](https://docs.docker.com/reference/cli/docker/container/rm/)

---

### Step 3 — Pod recovery, rollout inspection, and rollback command surface

- **Kubernetes documentation** — Deployment reconciliation and rollout operations:
  - [Kubernetes Docs — Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
  - [Kubernetes Docs — ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
  - [Kubernetes Docs — `kubectl delete`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_delete/)
  - [Kubernetes Docs — `kubectl rollout status`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_status/)
  - [Kubernetes Docs — `kubectl rollout history`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_history/)
  - [Kubernetes Docs — `kubectl rollout undo`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_undo/)

- [Git documentation — `git revert`](https://git-scm.com/docs/git-revert)  
  Git-based rollback through a new revert commit without rewriting shared history.

---

### Step 4 — Platform rebuild and redeploy path

- [K3s Docs — Architecture](https://docs.k3s.io/architecture)  
  K3s server/agent architecture and single-server baseline.

- [K3s Docs — High Availability Embedded etcd](https://docs.k3s.io/datastore/ha-embedded)  
  High-availability requirements and quorum behavior, used to define the current single-node recovery boundary.

- [Proxmox VE Wiki — Cloud-Init Support](https://pve.proxmox.com/wiki/Cloud-Init_Support)  
  Proxmox Cloud-Init support used by the VM-template baseline.

- [Proxmox VE Documentation — `qm` manual](https://pve.proxmox.com/pve-docs/qm.1.html)  
  Proxmox VM management commands for template, clone, and VM lifecycle operations.

- [Terraform documentation — Workflow for provisioning infrastructure](https://developer.hashicorp.com/terraform/cli/run)  
  Terraform workflow used as the Phase 08 IaC reference for reproducible Proxmox VM provisioning proof.

- **Kubernetes deployment references** — Declarative redeployment path:
  - [Kubernetes Docs — Declarative Management of Kubernetes Objects Using Configuration Files](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/)
  - [Kubernetes Docs — Declarative Management of Kubernetes Objects Using Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
  - [Kustomize — Kubernetes native configuration management](https://kustomize.io/)

- **GitHub Actions documentation** — Environment-based delivery and approval-gated promotion:
  - [GitHub Docs — Deploying with GitHub Actions](https://docs.github.com/actions/deployment/about-deployments/deploying-with-github-actions)
  - [GitHub Docs — Deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)
  - [GitHub Docs — Reviewing deployments](https://docs.github.com/actions/managing-workflow-runs/reviewing-deployments)