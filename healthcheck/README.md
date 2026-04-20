# Healthcheck Helper

## Purpose

This folder contains a repo-owned Ruby healthcheck utility designed for Kubernetes environments. It verifies service health across multiple endpoints, aggregates statuses, and provides machine-readable results.

The helper is structured as a **Modular Script**, allowing it to function both as a standalone CLI tool and as a testable library for automated unit testing.

---

## Features

- **Isolated Logic:** Encapsulated in the `HealthChecker` class for framework-driven testing.
- **UNIX Composable:** Separates human-readable logs (`stderr`) from machine-readable JSON (`stdout`).
- **Pipeline Ready:** Provides POSIX-compliant exit codes for direct use in CI/CD quality gates.
- **Hardened Validation:** Prevents "vacuous truth" errors by ensuring at least one service is successfully checked before reporting success.

---

## Usage (Local/Generic)

### Direct CLI Execution
~~~bash
ruby healthcheck.rb \
  --hostname http://localhost:8080 \
  --services catalogue,user,carts \
  --retry 3 \
  --delay 5
~~~

### Key Options
- `--services`: (Required) Comma-separated list of Kubernetes service names.
- `--hostname`: Base URL or hostname prefix for the services.
- `--retry`: Number of check attempts before giving up (Default: 1).
- `--delay`: Seconds to wait between retries.
- `--help`: View the auto-generated help menu and all available flags.

~~~bash
$ ruby healthcheck/healthcheck.rb --help
Usage healthcheck.rb -h [host] -t [timeout] -r [retry]
    -h, --hostname HOSTNAME          Specify hostname
    -t, --timeout SECONDS            Specify timeout in seconds
    -r, --retry N                    Specify number of retries
    -d, --delay SECONDS              Specify seconds to delay
    -s, --services X,Y               Specify services to check 
~~~

---

## Target Environment Proof (Real-Cluster Validation)

Because this script relies on Kubernetes internal DNS to resolve service names (like `catalogue`), a local workstation run outside any cluster is insufficient for a full functional proof. 

A **dedicated helper script** and a corresponding **Make target** are provided to validate the **current local working copy** of the script directly on the remote Proxmox-based target cluster.

### Run the Proof
~~~bash
# Option A: Via Make
make p07-healthcheck-target-env

# Option B: Via Direct Script
./scripts/testing/run-healthcheck-target-env.sh
~~~

**What this does:**
1. Connects to the remote target cluster.
2. Spins up a temporary Ruby Pod.
3. Copies the **local** `healthcheck.rb` into that Pod.
4. Executes the script against remote in-cluster services.
5. Displays the JSON results and cleans up the Pod.

~~~bash
$ make p07-healthcheck-target-env
./scripts/testing/run-healthcheck-target-env.sh
NAME                        STATUS   ROLES           AGE   VERSION        INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
ubuntu-2404-k3s-target-01   Ready    control-plane   14d   v1.34.6+k3s1   10.10.10.20   <none>        Ubuntu 24.04.4 LTS   6.8.0-107-generic   containerd://2.2.2-bd1.34
pod/tmp-ruby-healthcheck created
pod/tmp-ruby-healthcheck condition met
Syntax OK
Sleeping for 5s...
{
  "catalogue": "OK",
  "catalogue-db": "OK",
  "user": "OK",
  "user-db": "OK",
  "carts": "OK",
  "carts-db": "OK"
}
~~~

---

## Machine-Readable Output

To support automation and interoperability, the script follows standard stream conventions:

1. **Standard Error (`stderr`):** Receives all human-readable status messages/logs (e.g., "Sleeping...", "no services specified").
2. **Standard Out (`stdout`):** Receives only the final, pure JSON status map:

**Expected Production Output**
~~~json
{
  "catalogue": "OK",
  "catalogue-db": "OK",
  "user": "OK",
  "user-db": "OK",
  "carts": "OK",
  "carts-db": "OK"
}
~~~

### Example: Extracting a specific service status 
Because informational logs are sent to `stderr`, downstream tools can parse the output directly without interference:
~~~bash
# Running locally (where services are unreachable) the "err" output is expected
$ ruby healthcheck/healthcheck.rb --services catalogue,user | jq '.catalogue'
"err"
~~~

### Example: Advanced Pipeline Chaining
By using `make -s` (silent mode) and our stream-aware scripts, we can chain health data directly into tools like `jq` even when running against the remote cluster:

~~~bash
# Example: Filter the remote cluster results for Database statuses only
$ make -s p07-healthcheck-target-env | jq 'with_entries(select(.key | endswith("-db")))'

# We still get human readable progress logs via stderr:
NAME                       STATUS   ROLES   ...
pod/tmp-ruby-healthcheck created
...
Sleeping for 5s...

# The machine (jq) only sees the JSON via stdout:
{
  "catalogue-db": "OK",
  "user-db": "OK",
  "carts-db": "OK"
}
~~~

### Example: Pipeline Gate
Implementing Healthcheck-based pipeline gates is now trivial. The following returns a simple boolean to the calling shell:
~~~bash
# Running locally (where services are unreachable) the "false" output is expected
$ ruby healthcheck.rb --services catalogue | jq 'all(. == "OK")'
false
~~~

~~~bash
# Running locally (where services are unreachable) the "false" output is expected
$ make -s p07-healthcheck-target-env | jq 'all(. == "OK")'
# ... human readable logging ... 
true
~~~
---

## Containerization

The helper is packaged for use within Kubernetes clusters where internal service DNS resolution is available.

### Build the Image
~~~bash
docker build -t sockshop-healthcheck ./healthcheck
~~~

### Verify Packaging
~~~bash
# Syntax Check inside the container
docker run --rm --entrypoint ruby sockshop-healthcheck -c /healthcheck.rb

# Smoke Check (Expected to fail with "no services specified")
docker run --rm sockshop-healthcheck
~~~

---

## Development & Testing

This script uses an **Execution Guard** (`if __FILE__ == $0`), allowing the Ruby test runner to `require` the file and inspect its logic without triggering a live network run or an uncontrolled process exit.

### Testable Units:
- **Option Parsing:** Validates CLI argument-to-hash mapping.
- **Retry Logic:** Verifies timing and loop behavior.
- **Aggregation:** Ensures service and database statuses are correctly merged.

---

## Why this helper matters

This utility performs **essential service health checks against the cluster** and provides therefore a critical **quality gate** for the delivery pipeline. 

By **maintaining our own healthcheck logic** (instead of relying solely on infrastructure signals such as "Pod is running"), we ensure that the **CI/CD pipeline only promotes a deployment** when the **application services are actually ready** to handle traffic. This allows us to ensure **actual application health**.