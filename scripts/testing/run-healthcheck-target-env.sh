#!/usr/bin/env bash

################################################################################
# SCRIPT: run-healthcheck-target-env.sh
#
# RUBY TARGET HEALTHCHECK PROOF HELPER
#
# DESCRIPTION:
#   A small validation helper that executes the repo-owned Ruby
#   healthcheck script against the Proxmox-based target cluster.
#
# WHY THIS EXISTS:
#   1. Functional proof before + after refactor:
#      Confirms that the current Ruby healthcheck helper is not only
#      syntactically valid, but also functionally correct in the
#      runtime shape it was designed for. 
#   2. Target validation:
#      Runs the proof against the actual long-lived target cluster instead 
#      of relying only on local and insufficient workstation checks.
#      In-cluster execution is required here because the healtcheck sscript 
#      relies on Kubernetes internal DNS (CoreDNS) to resolve naked service 
#      names like 'catalogue' or 'user'.  
#   3. Current Working-Copy Execution:
#      Copies the current local healthcheck.rb file into a temporary
#      Pod so the proof run validates the file that is currently being
#      edited, not only a previously built image version.
#   4. Repeatable Smoke Check:
#      Packages the full real-target proof flow into one reusable
#      command sequence that can be re-run during refactoring and
#      before CI integration.
#
# FEATURES:
#   - Provisions a temporary isolated Ruby runtime on the target cluster.
#     - Points kubectl explicitly to the Proxmox-based target cluster
#     - Creates a temporary Ruby Pod in the target cluster's dev namespace
#     - Copies the current local healthcheck.rb into that Pod
#     - Installs the required Ruby gem inside the temporary runtime
#     - Executes the helper against real in-cluster service names
#     - Removes the temporary Pod automatically on exit
#   - Automated Stream Separation: Redirects all setup logs to stderr, 
#     keeping stdout reserved for the final Ruby JSON payload.
#   - POSIX-compliant exit signals for pipeline integration.  
#   - Performs best-effort cleanup of resources via EXIT trap.
#
# INTEROPERABILITY & PIPELINES:
#   This script is "Pipe-Ready". By separating informational logs (stderr) 
#   from data output (stdout), the results can be chained directly into 
#   JSON processors like 'jq'.
#
#   Examples (requires 'make -s' or direct script execution):
#     ./run-healthcheck-target-env.sh | jq '.catalogue'
#     make -s p07-healthcheck-target-env | jq 'all(. == "OK")' 
#
# SCRIPT USAGE:
#   Standard execution (uses default configuration):
#     ./scripts/testing/run-healthcheck-target-env.sh
#
#   Custom execution (via environment variables):
#     This script respects the following environment variables. If set, they 
#     will override the script's defaults:
#       - KUBECONFIG_PATH (default: $HOME/.kube/config-proxmox-dev.yaml)
#       - NAMESPACE       (default: sock-shop-dev)
#       - RUBY_IMAGE      (default: ruby:3.2-alpine)
#
#     Example (targeting the production namespace):
#       NAMESPACE="sock-shop-prod" ./scripts/testing/run-healthcheck-target-env.sh
#
#   Execution vi makefiel target:
#     make p07-healthcheck-target-env        
#
################################################################################

# -----------------------------------------------------------------------------
# 1) GLOBAL SETTINGS & TEARDOWN HOOKS
# -----------------------------------------------------------------------------

# Enable stricter Bash error handling for this proof helper (every command is required for success)
#
# -e          = exit immediately if a command fails
# -u          = treat use of an unset variable as an error
# -o pipefail = make a pipeline fail if any command in it fails,
#               not only the last command in the pipeline
set -euo pipefail

#######################################
# Performs best-effort cleanup of the temporary Ruby proof Pod.
# This prevents the validation Pod from being left behind if the
# script exits early or one of the proof commands fails midway.
#
# Outputs:
#   No visible output during normal cleanup.
#######################################
cleanup() {
    # -n sock-shop-dev         = target the dev namespace on the target cluster
    # tmp-ruby-healthcheck     = the temporary Pod created for the Ruby healthcheck proof
    # --ignore-not-found       = do not fail if the Pod was already removed or never created
    # >/dev/null               = discard normal command output
    # 2>&1                     = redirect error output to the same discarded destination
    # || true                  = keep cleanup non-fatal even if kubectl still returns a non-zero exit code
    kubectl delete pod -n "$NAMESPACE" "$POD_NAME" --ignore-not-found >/dev/null 2>&1 || true
    # expected: "tmp-ruby-healthcheck" deleted    
}

# Exit Trap
# Register a teardown hook to guarantee the script cleans up after itself.
# This ensures the 'cleanup' function runs automatically when the script terminates, 
# regardless of whether it finishes successfully or crashes due to an error.
#
# trap    = The bash built-in command used to catch system signals and execute code.
# cleanup = The name of the custom function to be executed (must be defined elsewhere in the script).
# EXIT    ? A special bash pseudo-signal that fires the moment the script process ends.
trap cleanup EXIT

# -----------------------------------------------------------------------------
# 2) SCRIPT VARIABLES & DEFAULTS
# -----------------------------------------------------------------------------

KUBECONFIG_PATH="${KUBECONFIG_PATH:-$HOME/.kube/config-proxmox-dev.yaml}" 
NAMESPACE="${NAMESPACE:-sock-shop-dev}" 
POD_NAME="tmp-ruby-healthcheck" 
RUBY_IMAGE="${RUBY_IMAGE:-ruby:3.2-alpine}" 

# -----------------------------------------------------------------------------
# 3) CLUSTER AUTHENTICATION & VERIFICATION
# -----------------------------------------------------------------------------

# Point kubectl explicitly to the real Proxmox-backed target cluster.
export KUBECONFIG="$KUBECONFIG_PATH"

# Confirm that kubectl is targeting the real target node rather than the laptop-side local cluster.
#
# -o wide = show extended node details such as internal IP, OS image, and container runtime
# >&2     = redirect output to stderr for script chainability/to keep stdout reserved for the final JSON result.   
kubectl get nodes -o wide >&2
# expected output:
# NAME                        STATUS   ROLES           AGE   VERSION        INTERNAL-IP        EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
# ubuntu-2404-k3s-target-01   Ready    control-plane   ...   v1.34.6+k3s1   [REDACTED_VM_IP]   <none>        Ubuntu 24.04.4 LTS   ...                 containerd://...

# -----------------------------------------------------------------------------
# 4) TEMPORARY RUNTIME PROVISIONING
# -----------------------------------------------------------------------------

# Start a temporary Ruby Pod inside the real dev namespace.
#
# kubectl run              = create a one-off Pod for ad-hoc execution
# tmp-ruby-healthcheck     = temporary Pod name used for this proof run
# -n sock-shop-dev         = run the Pod inside the real dev namespace
# --image=ruby:3.2-alpine  = use a lightweight Ruby base image
# --restart=Never          = create a plain Pod, not a Deployment/Job controller
# --command --             = treat the following words as the container command
# sleep 3600               = keep the Pod alive long enough for file copy and execution
kubectl run "$POD_NAME" -n "$NAMESPACE" \
  --image="$RUBY_IMAGE" \
  --restart=Never \
  --command -- sleep 3600 >&2
# Expected: 
# pod/tmp-ruby-healthcheck created

# Wait until the temporary Pod is ready for execution
#
# kubectl wait             = block until the requested condition is met
# --for=condition=Ready    = wait for the Pod to become Ready
# --timeout=120s           = fail if readiness does not happen within 120 seconds
kubectl wait --for=condition=Ready "pod/$POD_NAME" -n "$NAMESPACE" --timeout=120s >&2
# Ecpected: 
# pod/tmp-ruby-healthcheck condition met

# -----------------------------------------------------------------------------
# 5) TEST SCRIPT DEPLOYMENT & DEPENDENCIES
# -----------------------------------------------------------------------------

# Copy the current local healthcheck.rb file into the running Pod.
#
# kubectl cp = copy files between the workstation and a container
# /tmp/healthcheck.rb = temporary in-container path used for the proof run
kubectl cp healthcheck/healthcheck.rb "$NAMESPACE/$POD_NAME:/tmp/healthcheck.rb" >&2   

# -----------------------------------------------------------------------------
# 6) VALIDATION & EXECUTION
# -----------------------------------------------------------------------------

# Validate the syntax of the healthcheck helper without executing it 
# -c = syntax check only
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- ruby -c /tmp/healthcheck.rb >&2
# Expected: 
# Syntax OK

# Execute the current helper against real in-cluster service names.
#
# INTEROPERABILITY NOTE: 
# This command is not redirected to stderr (>&2). Because the Ruby script internally 
# separates its streams (JSON to stdout, logs to stderr), 'kubectl exec' acts as a 
# transparent tunnel. This allows the JSON payload to be captured by downstream tools 
# (like jq) while informational logs remain visible to the user via stderr.
#
# -q              = Quiet mode; suppresses kubectl setup warnings.
# --services ...  = check these three application services
# --retry 3       = allow up to 3 rounds if a service is not healthy immediately
# --delay 5       = wait 5 seconds before each round
kubectl exec -q -n "$NAMESPACE" "$POD_NAME" -- \
  ruby /tmp/healthcheck.rb \
    --services catalogue,user,carts \
    --retry 3 \
    --delay 5
# Expected:
# Sleeping for 5s...
# {
#   "catalogue": "OK",
#   "catalogue-db": "OK",
#   "user": "OK",
#   "user-db": "OK",
#   "carts": "OK",
#   "carts-db": "OK"
# }
