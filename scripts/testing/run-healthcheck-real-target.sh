#!/usr/bin/env bash
set -euo pipefail



# Point kubectl explicitly to the real Proxmox-backed target cluster.
export KUBECONFIG=~/.kube/config-proxmox-dev.yaml

# Confirm that kubectl is targeting the real target node rather than the laptop-side local cluster.
#
# -o wide = show extended node details such as internal IP, OS image, and container runtime
kubectl get nodes -o wide
# expected output:
# NAME                        STATUS   ROLES           AGE   VERSION        INTERNAL-IP        EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
# ubuntu-2404-k3s-target-01   Ready    control-plane   ...   v1.34.6+k3s1   [REDACTED_VM_IP]   <none>        Ubuntu 24.04.4 LTS   ...                 containerd://...

# Start a temporary Ruby Pod inside the real dev namespace.
#
# kubectl run              = create a one-off Pod for ad-hoc execution
# tmp-ruby-healthcheck     = temporary Pod name used for this proof run
# -n sock-shop-dev         = run the Pod inside the real dev namespace
# --image=ruby:3.2-alpine  = use a lightweight Ruby base image
# --restart=Never          = create a plain Pod, not a Deployment/Job controller
# --command --             = treat the following words as the container command
# sleep 3600               = keep the Pod alive long enough for file copy and execution
kubectl run tmp-ruby-healthcheck -n sock-shop-dev \
  --image=ruby:3.2-alpine \
  --restart=Never \
  --command -- sleep 3600
# expecetd: pod/tmp-ruby-healthcheck created

# Wait until the temporary Pod is ready for execution.
#
# kubectl wait             = block until the requested condition is met
# --for=condition=Ready    = wait for the Pod to become Ready
# --timeout=120s           = fail if readiness does not happen within 120 seconds
kubectl wait --for=condition=Ready pod/tmp-ruby-healthcheck -n sock-shop-dev --timeout=120s
# ecpected: pod/tmp-ruby-healthcheck condition met

# Copy the current local healthcheck.rb file into the running Pod.
#
# kubectl cp = copy files between the workstation and a container
# /tmp/healthcheck.rb = temporary in-container path used for the proof run
kubectl cp healthcheck/healthcheck.rb \
  sock-shop-dev/tmp-ruby-healthcheck:/tmp/healthcheck.rb

# Install the Ruby gem required by the helper in this temporary runtime.
#
# kubectl exec = execute a command inside the running Pod
# gem install awesome_print = install the pretty-printing gem used by the script output
kubectl exec -n sock-shop-dev tmp-ruby-healthcheck -- gem install awesome_print
# expected Successfully installed awesome_print-1.9.2
# 1 gem installed

# Execute the current helper against real in-cluster service names.
#
# --services catalogue,user,carts = check these three application services
# --retry 3 = allow up to 3 rounds if a service is not healthy immediately
# --delay 5 = wait 5 seconds before each round
kubectl exec -n sock-shop-dev tmp-ruby-healthcheck -- \
  ruby /tmp/healthcheck.rb \
    --services catalogue,user,carts \
    --retry 3 \
    --delay 5
# expetcetd:
# Sleeping for 5s...
# {
#        "catalogue" => "OK",
#     "catalogue-db" => "OK",
#             "user" => "OK",
#          "user-db" => "OK",
#            "carts" => "OK",
#         "carts-db" => "OK"
# }

# Remove the temporary Pod after the proof run is complete.
#
# kubectl delete pod = clean up the short-lived validation Pod
kubectl delete pod -n sock-shop-dev tmp-ruby-healthcheck
# expected: "tmp-ruby-healthcheck" deleted