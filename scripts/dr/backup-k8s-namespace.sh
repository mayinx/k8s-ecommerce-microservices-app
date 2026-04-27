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
#   Each run creates a unique, timestamped directory. 
#
# BACKUP SCOPE:
# - Resource State: Full K8s namespace/resource state as YAML and text snapshots
# - Security: Metadata-only Secret inventory, without exporting secret values
# - Databases: Compressed MongoDB dumps from several Sock Shop DB pods that support 'mongodump'
#
# USAGE:
#   ./scripts/dr/backup-k8s-namespace.sh sock-shop-dev
#   ./scripts/dr/backup-k8s-namespace.sh sock-shop-prod

# Fail fast on errors, unset variables, and failed pipeline commands.
set -euo pipefail

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

echo "============================================================"
echo "Starting DR backup for namespace: ${NAMESPACE}"
echo "Destination: ${BACKUP_DIR}"
echo "============================================================"

# Verify that kubectl is available before starting.
if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERROR: kubectl is required but was not found in PATH." >&2
  exit 1
fi

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
  if ! kubectl exec -n "$NAMESPACE" "$pod_name" -- sh -c 'command -v mongodump >/dev/null 2>&1'; then
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

echo
echo "============================================================"
echo "Backup completed."
echo "Backup folder: ${BACKUP_DIR}"
echo "Database report: ${DB_REPORT}"
echo "============================================================"