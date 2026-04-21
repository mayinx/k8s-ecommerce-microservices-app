
# Phase 07 (Security & Testing): ... 

# Implementation Log — Phase 07 (Security & Testing): ...

> ## About
> This document is the implementation log and detailed build diary for **Phase 07 (Security & Testing):**.
> It records the full implementation path including rationales, key observations, verification steps, and evidence pointers so the work remains auditable and reproducible.
>
> For top-level project navigation, see: **[INDEX.md](../INDEX.md)**.
> For cross-phase incident and anomaly tracking, see: **[DEBUG-LOG.md](../DEBUG-LOG.md)**.
> For the broader project planning view, see: **[ROADMAP.md](../ROADMAP.md)**.

---

## Index (top-level)

- [**Purpose / Goal**](#purpose--goal)
- [**Definition of done (Phase 07)**](#definition-of-done-phase-07)
- [**Preconditions**](#preconditions)

Steps..
Steps..
Steps..

- [**Phase 07 Outcome Summary**](#phase-07-outcome-summary)
- [**Sources**](#sources)

---

## Purpose / Goal

### Intro / Overview

The prior project phases already provide a broad foundation for further implementation phases:

- Phase 05 established real-target delivery
- Phase 06 established observability

At this point, the project can deploy, expose, and observe `dev` and `prod` environments. But for a production ready application essential abilities are still missing to guarantee automated quality and reliability assurance:

- Testing quality gates   
- Security gates

Together those gates from a validation alyer that must now be implemented on top of our already working platform, to check code before deployment and verifies live application behavior after deployment. 

TODO: Note: When it comes to ensuring the quality of code, it is not possible to guarnatee the code quality of a huge number of ou of reach legacy Sock Shop microservices. Code quality checks must therfore focus on "repo owned code".

Phase 07 will extend the phase 05 workflow to integrate 
- pre deploy quality checks for repo owned code including security basics  
- post prod-deploy checks against the live dev environment (Smock Shop API Tests and Browser based tests) 

Like before, the promotion to `prod` will only made available after the lower dev environment has been exercised successfully without any quality or security issues. 

...
...
...

TODO: Note: The earlier Phase 05 target delivery workflow remains preserved and rerunnable and will be kept for historical reasons.  

> [!NOTE] **🧩 Owned test surface**
>
> An owned test surface is project code that is maintained directly in this repository and can therefore be tested and changed as part of the project’s own engineering scope. 


TODO: Info boxes for all relevant general topics and concepts:
- qa / testing - what is it, why does a project need that etc.   
- security 

### Testing Scope / What will be tested:

- selected repo owned ruby, bash + python code
  - Ruby Unit test
  - Python Unit test
  - Bash/helper test
- Sock Shop API after dev-deploy against dev
  - API Integration test
  - Browser E2E Smoke test
- Securtity   
- ...

### Repo-owended helper scripts need to be reafctored into a "testable state" 

TODO: .... (see steps + decisions)

### Security Scope

### Implemenbtation Order

TODO

...
...
...


### Result 

Phase 07 implements an initial quality gate set as base for <later pahses, that ...>:

- Pre-deploy checks for owned code and basic security posture
- Post-deploy checks against the live `dev` environment
- Gated promotion to `prod` only after the lower dev environment has been exercised successfully 



## Definition of done

Phase 07 is considered done when the following conditions are met:

- ...
- ...
- ...

---




## Step 1 — Define the repo-owned test surfaces and create the test scaffold

### Rationale

Before introducing any test framework or workflow changes, we need to identify **which repository-owned code is actually suitable for testing** in this project.

At this point, the strongest owned test surfaces are:

- Ruby Healthcheck 
    - `healthcheck/healthcheck.rb`
- Traffic Generatot as Oberservability Helper 
    - `scripts/observability/generate-sockshop-traffic.sh`

These two files are valuable test targets because they are **repo-owned**, **actively used in the project**, and **technically relevant** as part of a quality-gate:

- The Ruby healthcheck is already part of the repo-owned delivery workflow (see Phase 05 Proxmox Target Delivery)
- The Traffic Generator was intriduced in Phase 06 as custom Observability helper 
- Both files contain real control flow and logic that can be tested 

**Python QA utility module**

Phase 07 will also introduce a small **Python QA utility module**, that can be used as a repo-owned test surface. That gives the project both a valuable QA addition - and a Python unit-test path. 

**Basic Test Scaffold**

After the repo-owned test surface is decided, we need to create a corresponding basic testing scaffold - we will also include an e2e scaffold from teh beginning:   

### Action

We create a fodler structure that separates the testing concerns cleanly:

- `tests/bash` - for tests around the observability traffic helper
- `tests/e2e` - for browser-based smoke checks against the live `dev` edge
- `tests/python` - for the Python QA helper module and its unit/API checks
- `tests/ruby` - for unit tests around the repo-owned Ruby healthcheck
Once that structure exists, `.gitignore` must be extended to exlude the usual test dependencies and test results that we don't to leak into version control:

~~~gitignore
# Phase 07 test dependencies and generated artifacts
tests/node_modules/
tests/venv/
tests/test-results/
tests/playwright-report/
~~~

---

## Step 2 — Assess the repo-owned helper surfaces, prove their current behavior, and identify the testability gaps

### Rationale

With the owned test surfaces now defined, the next task is to assess whether the existing Ruby and Bash helpers are already **functionally valid** and also in a **testable state**.

- `healthcheck/healthcheck.rb`
- `scripts/observability/generate-sockshop-traffic.sh`

### Action

Goals:
- Functional check: Establish that **both scripts** currently work in their natural operational execution environment  
- Structural check: Review the **current file structure of the scripts** and identify potential blockers for clean unit-test integration

### Ruby `healthcheck`   

#### Functional Check I: Assess current state locally 

From the repo root, we first assess the script's current state, which already offers a Dockerfile: 

~~~bash
# Build the existing local Docker image for the Ruby healthcheck script.
#
# -t sockshop-healthcheck : Tags (names) the resulting image as 'sockshop-healthcheck' 
#                           so it can be easily referenced in later run commands.
# ./healthcheck           : Specifies the build context directory containing the 
#                           Dockerfile and the healthcheck.rb script.
$ docker build -t sockshop-healthcheck ./healthcheck 
[+] Building 46.1s (10/10 FINISHED docker:default  
...
=> => unpacking to docker.io/library/sockshop-healthcheck:latest sockshop-healthcheck:latest 0.3s

# Syntax check:
# Run a temporary container to perform a Ruby dry-run syntax check on the script 
# inside the image, without actually executing the healthcheck code.
#
# --rm                 : Automatically delete the container as soon as the check finishes.
# --entrypoint ruby    : Overrides the default ENTRYPOINT ["ruby", "healthcheck.rb"] 
#                        so we can pass native Ruby interpreter flags instead.
# sockshop-healthcheck : The local Docker image being executed.
# -c /healthcheck.rb   : The Ruby flag (-c) that checks the syntax of the file 
#                        without actually executing the code inside it.
$ docker run --rm --entrypoint ruby sockshop-healthcheck -c /healthcheck.rb
Syntax OK

# Direct execution check:
# Run a temporary container to perform a direct execution smoke check, 
# relying on its default ENTRYPOINT. Sicne no service related args are provided, 
# a graceful exit is expected
$ docker run --rm sockshop-healthcheck
no services specified
~~~

**Direct Ruby execution**

If Ruby is installed locally, the same baseline checks can also be performed **without Docker**. See **`SETUP.md`** for the Ruby installation and gem setup needed to run `healthcheck.rb` successfully:

~~~bash

# Validate the syntax of the owned healthcheck helper without normal execution.
# -c = syntax check only
$ ruby -c healthcheck/healthcheck.rb
Syntax OK

# Start the helper once locally to confirm that it loads successfully.
# In the current script state, running it without -s / --services is expected
# to stop with the message: "no services specified"
$ ruby healthcheck/healthcheck.rb
no services specified

## Example direct usage with services
# The exact runtime input depends on how the target health endpoints are exposed.
# General shape:
# - `--hostname` supplies the base URL or hostname prefix
# - `--services` selects the service names to check
# - `--retry` defines how many rounds should be attempted
# - `--delay` adds a delay before each round -
$ ruby healthcheck/healthcheck.rb \
  --hostname http://localhost:8080 \
  --services catalogue,user,carts \
  --retry 3 \
  --delay 5
Sleeping for 5s...
{
    "catalogue" => "err",
         "user" => "err",
        "carts" => "err"
}
Sleeping for 5s...
{
    "catalogue" => "err",
         "user" => "err",
        "carts" => "err"
}
Sleeping for 5s...
{
    "catalogue" => "err",
         "user" => "err",
        "carts" => "err"
} 
~~~

**Observations regarding the last direct ruby execution:**
- The helper was executed successfully 
- Argument parsing, retry handling, delay handling, and error aggregation behaved as expected
- But: Even though the helper does expose a `--hostname` option, the chosen **local target did not expose the expected /health responses**, so **all requested services ended in `err`**. The local workstation run with `--hostname http://localhost:8080` did **not** prove a working hostname-based target shape for this project. The issue remains when switching the local target with the url of the remote target. 

**Reason:** 
- The healthcheck helper uses **Kubernetes service names** such as `catalogue` and `user` rather than public hostnames.
- Those names are meant to be resolved through the cluster's **internal service DNS**
- In consequence, running the script directly on a local workstation (outside the target cluster) fails because those **hostnames do not resolve outside the cluster network**.

So **in-cluster execution is required here** (ideally against the remote target cluster) to prove the functionality of the Ruby `healthcheck` helper before we move into any refactoring and testing work.   

#### Functional Check II: Proof on the remote target cluster

The earlier local Ruby checks already show that the helper is syntactically intact and starts as expected - but the funcitonal proof is still incomplete.

To prove that the current helper is functionally valid before the refactor begins, it must be executed against the remote Proxmox-based target cluster in the runtime shape it was designed for: Inside the `sock-shop-dev` namespace, using internal Kubernetes service-name resolution for `catalogue`, `user`, and `carts`:

> [!NOTE] **🧩 Reusable target-environment proof helper**
>
> This command sequence is also available as a reusable Bash helper script:
>
> - `scripts/testing/run-healthcheck-target-env.sh`
>
> It is reused later to re-check the Ruby `healthcheck` helper against the remote target cluster after refactoring and test work.
>
> A matching Make target is available as well:
>
> - `make p07-healthcheck-target-env`

> [!NOTE] **🧩 Why no `--hostname` is used in this proof run**
>
> The helper does expose a `--hostname` option, but the earlier local workstation run did not prove a working alternative target shape for this project.
> 
> So no `--hostname` argument is used in the following proof run, because the helper is validated directly on the remote target - i.e. in the **service-DNS model of the cluster**, where service names such as `catalogue`, `user`, and `carts` resolve directly inside the Kubernetes namespace - and a explicit hostname option shoudl not be necessary.  

~~~bash
# Point kubectl explicitly to the real Proxmox-backed target cluster.
$ export KUBECONFIG=~/.kube/config-proxmox-dev.yaml

# Confirm that kubectl is targeting the remote target node rather than the laptop-side local cluster.
#
# -o wide = show extended node details such as internal IP, OS image, and container runtime
$ kubectl get nodes -o wide
NAME                        STATUS   ROLES           AGE   VERSION        INTERNAL-IP        EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
ubuntu-2404-k3s-target-01   Ready    control-plane   ...   v1.34.6+k3s1   [REDACTED_VM_IP]   <none>        Ubuntu 24.04.4 LTS   ...                 containerd://...

# Start a temporary Ruby Pod inside the remote dev namespace.
#
# kubectl run              = create a one-off Pod for ad-hoc execution
# tmp-ruby-healthcheck     = temporary Pod name used for this proof run
# -n sock-shop-dev         = run the Pod inside the real dev namespace
# --image=ruby:3.2-alpine  = use a lightweight Ruby base image
# --restart=Never          = create a plain Pod, not a Deployment/Job controller
# --command --             = treat the following words as the container command
# sleep 3600               = keep the Pod alive long enough for file copy and execution
$ kubectl run tmp-ruby-healthcheck -n sock-shop-dev \
  --image=ruby:3.2-alpine \
  --restart=Never \
  --command -- sleep 3600
pod/tmp-ruby-healthcheck created

# Wait until the temporary Pod is ready for execution.
#
# kubectl wait             = block until the requested condition is met
# --for=condition=Ready    = wait for the Pod to become Ready
# --timeout=120s           = fail if readiness does not happen within 120 seconds
$ kubectl wait --for=condition=Ready pod/tmp-ruby-healthcheck -n sock-shop-dev --timeout=120s
pod/tmp-ruby-healthcheck condition met

# Copy the current local healthcheck.rb file into the running Pod.
#
# kubectl cp = copy files between the workstation and a container
# /tmp/healthcheck.rb = temporary in-container path used for the proof run
$ kubectl cp healthcheck/healthcheck.rb \
  sock-shop-dev/tmp-ruby-healthcheck:/tmp/healthcheck.rb

# Install the Ruby gem required by the helper in this temporary runtime.
#
# kubectl exec = execute a command inside the running Pod
# gem install awesome_print = install the pretty-printing gem used by the script output
$ kubectl exec -n sock-shop-dev tmp-ruby-healthcheck -- gem install awesome_print
Successfully installed awesome_print-1.9.2
1 gem installed

# Execute the current helper against real in-cluster service names.
#
# --services catalogue,user,carts = check these three application services
# --retry 3 = allow up to 3 rounds if a service is not healthy immediately
# --delay 5 = wait 5 seconds before each round
$ kubectl exec -n sock-shop-dev tmp-ruby-healthcheck -- \
  ruby /tmp/healthcheck.rb \
    --services catalogue,user,carts \
    --retry 3 \
    --delay 5
Sleeping for 5s...
{
       "catalogue" => "OK",
    "catalogue-db" => "OK",
            "user" => "OK",
         "user-db" => "OK",
           "carts" => "OK",
        "carts-db" => "OK"
}

# Remove the temporary Pod after the proof run is complete.
#
# kubectl delete pod = clean up the short-lived validation Pod
$ kubectl delete pod -n sock-shop-dev tmp-ruby-healthcheck
pod "tmp-ruby-healthcheck" deleted
~~~

The successful end state is shown by these signals / verification points:

- The helper executed successfully on the remote target cluster
- The current repo-owned `healthcheck.rb` file resolved the internal Kubernetes service names:
  - `catalogue`
  - `user`
  - `carts`
- The helper returned `OK` for all requested services and their dependent database services
- The current script logic is therefore functionally valid before the testability refactor begins

**Hidden CI/CD Pipeline Integration Flaw: Output Formatting - `stdout` is polluted with informational logs and invalid JSON syntax**

While the script succeeded operationally (returning a `0` exit code), inspecting the terminal output reveals a critical flaw for future CI/CD pipeline integration:

- **Invalid JSON:** The output uses **Ruby's internal Hash Rocket syntax (`=>`) instead of standard JSON colons (`:`)**. Cause: A inspection of the Healthcheck implementation revelas, that the script uses the `awesome_print` Ruby gem, which formats objects for human readability, **not machine parsing**.
- **Polluted Standard Out (`stdout`):** The informational log (Sleeping for 5s...) is printed to the same output stream as the data.

**Core Issue: Stream Pollution & Data Integrity**
If a **dependent tool or following pipeline step** attempts to **parse this output** (f. i. using `jq` or similar), the **process will fail**. Because informational logs intended for human readers ("Sleeping...") and machine data are both sent to `stdout`, the output is not "Composable" - not chainable/machine-parsable.  Furthermore, the use of Ruby's Hash Rocket syntax makes the payload invalid JSON (EDIT: which was also shown in later implemented CLI integration tests that faied due to `JSON::ParserError`). 

**Solution: "Stream-Aware" Refactor**
To ensure "Automation-Readiness," a refactor must enforce a strict separation of concerns:
- **Standard Out (`stdout`):** Reserved exclusively for pure, machine-readable JSON payloads.
- **Standard Error (`stderr`):** Utilized for all human-readable logs, progress updates, and warnings.
- **Valid JSON:** Replace `awesome_print` with the standard `json` library to ensure compatibility with universal tools like `jq`.

#### Structural check 

Inspecting the current **top-level execution shape** of the Ruby script reveals that the helper in its current form is **not yet well suited as a unit-test target**:

~~~ruby
OptionParser.new do |opts|
  ...
end.parse!

unless options.key?(:services)
  puts "\e[31mno services specified\e[0m"
  exit!
end

services = options[:services].split(',')
(1..options[:retry]).each do |i|
  ...
end

unless health.all? {|service, status| status == "OK" }
  exit(1)
end
~~~

**Core Issue:** 

- Option parsing, runtime flow, and process exit all happen **directly from top-level execution**. 
- A **test runner cannot safely load this file** as a normal dependency **without risking immediate execution side effects**.

### Bash observability helper

#### Functional Check: Assess current state (from repo root)

Unlike the Ruby helper, the Bash observability helper had already been functionally proven earlier in the observability phase during real traffic generation against the live target. 

The purpose here is therefore not to re-prove the full observability workflow, but to **assess the helper's current execution shape** and determine whether it **can already serve as a clean automated test target**.

~~~bash
# Validate the Bash syntax of the owned observability helper without executing it
#
# bash -n   = parse the script only, without executing it
#             Expected: no output on success
$ bash -n scripts/observability/generate-sockshop-traffic.sh

# Trigger the script with an invalid environment argument.
# This proves that the script starts executing immediately when called as a file
# and that its current validation/error path is active at direct runtime entry.
$ bash scripts/observability/generate-sockshop-traffic.sh wrong preset
(1) DEFINE TARGET ENVIRONMENT (dev|prod)
- Preset target sock-shop environment from args: 'wrong'

ERROR: Unknown sock-shop environment 'wrong'. Available environments are 'dev' or 'prod'.

# Trigger the script with a valid environment but an invalid data mode.
# This proves that the script continues directly into its runtime configuration path
# rather than exposing callable units for isolated test execution.
$ bash scripts/observability/generate-sockshop-traffic.sh dev wrong
(1) DEFINE TARGET ENVIRONMENT (dev|prod)
- Preset target sock-shop environment from args: 'dev'

(2) DEFINE DATA SOURCE MODE (live|preset)
- Preset data source mode from args: 'wrong'

ERROR: Unknown data source mode 'wrong'. Available data source modes are 'live' or 'preset'.
~~~
 
These checks show that the helper currently behaves correctly as a directly executed operational script:

- It parses its CLI arguments and validates environment and data-mode input
- It exits cleanly through its own guarded error paths

**Core Issue:**

At the same time and prior to a structural check, they also show already the current **testability limitation** clearly:

- **Runtime setup begins immediately** when the file is executed
- There is obviously **no execution guard** present yet **separating file loading from runtime start**
- **Sourcing the file** from a test context would **risk triggering prompt logic, environment handling, and later the traffic loop itself**

#### Structural check 

Investigating the current top-level execution shape of the bash script reveals the same issue the ruby script already shwoed: The script in its original form is not well suited as test target of unit tests:   

~~~bash
sockshop_env=$1
data_mode=$2

echo "(1) DEFINE TARGET ENVIRONMENT (dev|prod)"
...

while true; do
  ...
done
~~~

**Core Issue:** 
- Like the Ruby script, the Bash script's **runtime flow begins immediately when the file is executed** - prompt logic and long-running loop are tied to direct file execution
- In that shape, a **test framework cannot safely source the file** to call individual functions - without triggering prompt handling, runtime setup, or the long-running traffic loop.

So, just like the Ruby helper, the Bash helper is functionally useful and operationally valid, but not yet structured cleanly for framework-driven automated tests in its current form.

### Result

Step 2 shows that both selected repo-owned helpers are **functionally valid in their intended operational execution model**, but are **not yet structured cleanly for framework-driven automated tests**:

- `healthcheck/healthcheck.rb`
- `scripts/observability/generate-sockshop-traffic.sh`

This is suitable for manual execution, but not yet for clean automatic execution during unit tests:

- The Ruby script exits directly from top-level execution:
    - This is problematic in tests because a test runner may need to load the file first 
    - If the file exits immediately during load, this can terminate or disrupt the test process before assertions even run
- The Ruby script also **pollutes stdout with informational logs and invalid JSON syntax** (`awesome_print`), making it impossible to safely assert against terminal output during CLI integration tests.
- The Bash helper enters its runtime flow as soon as the file is executed and prompts for user input:
    - Right now, a test framework could not safely source or call the bash script file without triggering prompts, network calls, or the long-running traffic loop itself.
- Neither of those helper files is yet structured cleanly for import, sourcing, or framework-driven invocation:
    - Automated tests need callable units with clear inputs and outputs so behavior can be checked in isolation instead of only through full manual execution.

A **structural refactor of those helper scripts** is therefore necessary to make both helpers usable as safe and controllable test targets inside CI/CD-driven unit tests. At the same time, **their original function as manually executed operational scripts must be preserved**.

----

## Step 3 — Refactor the Ruby `healthcheck` helper into a unit-testable structure and add automated tests

### Rationale

Step 2 already proved that the repo-owned Ruby helper is both relevant and functionally valid on the real target cluster. That makes it a strong first candidate for automated testing in this phase.

At the same time, the current file shape is still awkward for fast local tests and CI-triggered unit-test execution. The script behaves primarily as a directly executed top-level program: it parses options immediately, enters the runtime flow directly, and exits from top-level code. That makes it difficult to require the file safely from a Ruby test runner.

The next move is therefore a **characterization-first refactoring** sequence:

1. freeze the current CLI behavior with one small characterization test
2. introduce the smallest structural refactor needed for safe import and isolated testing
3. add focused unit tests around the refactored logic
4. keep the already proven runtime behavior intact

This creates a fast local Ruby edit-test loop without losing the helper’s real target-side contract.

### Action

### Create the first Ruby characterization test

Before changing the helper structure, create a small CLI-level test that captures the currently intended behavior of the unrefactored script.

Create the file:

- `tests/ruby/test_healthcheck_cli.rb`

with the following content:

~~~ruby
require "minitest/autorun"
require "open3"

class HealthcheckCliTest < Minitest::Test
  # Open3.capture3 runs the script as a separate OS process and captures the
  # stdout, stderr, and exit status that a terminal user would observe
  def test_exits_with_error_when_no_services_are_provided
    stdout, stderr, status = Open3.capture3("ruby", "healthcheck/healthcheck.rb")

    combined_output = "#{stdout}#{stderr}"

    refute status.success?, "Expected non-zero exit status when no services are provided"
    assert_includes combined_output, "no services specified"
  end
end
~~~

Run the characterization test:

~~~bash
# Run the first Ruby CLI-level characterization test against the current unrefactored script.
#
# ruby tests/ruby/test_healthcheck_cli.rb
# = execute the minitest file directly with the Ruby interpreter
$ ruby tests/ruby/test_healthcheck_cli.rb
~~~

The expected result at this point is:

- the test passes
- the current helper still exits non-zero when no services are provided
- the output still includes `no services specified`

### Refactor the helper into a testable class with an execution guard

Once the characterization test passes, replace the current `healthcheck/healthcheck.rb` with the following minimally refactored version.

This refactor goals are:

- **(1) Logic Isolation & Execution Guard:** Move the runtime logic behind a **`class` boundary** and a **`__FILE__ == $0` execution guard**. This ensures the code is not immediately present in the top-level execution context, allowing the file to be safely required by tests without triggering a "live" run or process exit. 
- **(2) Test Interfaces through parameterized entry & attribute access** The `initialize(args)` method allows tests to inject custom argument arrays, enabling the simulation of different CLI scenarios (retries, timeouts) within a single test run. The use of `attr_reader :health, :options` and custom getters like `services` allows unit tests to inspect state directly without parsing string output.
- **(3) Pipeline Readiness (Stream Separation) through `stdout` Pollution Fix:** Fix the CLI output formatting by strictly **separating human logs (`stderr`) from machine data (`stdout`)**. Occurrences of `puts` for logging are converted to `warn` (stderr). This ensures `stdout` remains a "Pure Stream" for machine consumption.
- **(4) Hardening against "Vacuous Truth":** The `healthy?` method is updated to ensure `@health` is not empty, preventing false positives if no services were actually checked.

Below an **excerpt of the refactored code** (for the full commented implementation and documentation see `healthcheck/healthcheck.rb` and `healthcheck/README.md`):

~~~ruby
#!/usr/bin/env ruby

require "net/http"
require "optparse"
require "json"

class HealthChecker
  # TESTABILITY: Internal state is exposed via attr_reader so that unit tests
  # can verify the final 'health' and 'options' hashes without parsing stdout.
  attr_reader :options, :health

  # TESTABILITY: Accepting 'args' as a parameter instead of reading ARGV directly 
  # allows tests to instantiate different scenarios (retries, delays, etc.) 
  # within the same test run.  
  def initialize(args)
    @options = {}
    @health = {}
    parse_options(args)
    @options[:retry] ||= 1
  end

  def parse_options(args)
      # ...
    end.parse!(args)
  end

  # Encapsulates service list logic; provides a clean array for iteration.
  # Also useful as test interface
  def services
    return [] unless @options.key?(:services)

    @options[:services].split(",")
  end

  def run
    # Changed occurences of 'puts' (stdout) into 'warn' (stderr) to avoid polluting stdout: 
        
    # ---
    warn "Sleeping for #{@options[:delay]}s..." 
    # ---

    healthy?
  end

  # HARDENING: We verify that @health is not empty to avoid a 'vacuous truth' 
  # (where .all? returns true even on an empty collection). This ensures the 
  # script only reports success if it actually checked at least one service.
  def healthy?    
    !@health.empty? && @health.all? { |_service, status| status == "OK" }
  end
end#class

# EXECUTION GUARD: This block only runs if the script is called directly ($0).
#
# Prevents the script from running when it is imported/`required` as a library 
# for testing, avoiding immediate execution and process exit. 
if __FILE__ == $0
  # Disable output buffering ($stdout.sync = true) to ensure logs are flushed 
  # immediately. This is critical for real-time observability in CI/CD pipelines.  
  $stdout.sync = true

  checker = HealthChecker.new(ARGV)

  unless checker.options.key?(:services)
    # Moved to 'warn' (stderr) to avoid polluting stdout 
    warn "no services specified"
    exit 1
  end

  success = checker.run

  # MACHINE READABILITY: Output valid JSON to stdout for pipeline consumption.
  # (instead of using awesome_print: `ap checker.health`)
  puts JSON.pretty_generate(checker.health)

  exit(success ? 0 : 1)
end
~~~

**Result:**
The refactor transitions from a procedural script to an **object-oriented `HealthChecker` class** with an **architecture optimized for Testability & Chainability**. This has several advantages:

- **Dependency Injection:** Injecting `args` into `initialize` decouples logic from the global environment, allowing tests to simulate various CLI flags in-memory.
- **State Inspection:** By exposing `attr_reader :health`, we allow unit tests to assert the internal Hash object directly, eliminating the need for parsing of terminal output.
- **Safe Require**: The execution guard and the `class`-encapsulation prevent immediate side effects upon import/require, allowing the class to be safely loaded as a library within test suites.
- **Chainability / Pipeline Readiness:** By separating human and machine readable output clearly into `stderr` (human) and `stdout` (machine) we ensured, that the script’s `stdout` remains a **Pure Stream** — containing only the JSON payload. This enables the script to be "Composable" (UNIX Composability), allowing it to be piped into tools like `jq`.
- **Zero-Dependency Footprint:** Since we now removed the `ap` command which required the `awesome_print` Ruby gem, the Healthcheck script now only uses standard Ruby libraries (`json`, `net/http`, `optparse`), so the Pod doesn't need any external dependencies installed at all. 

#### Remove dynamic Ruby gem installation step (`awesome_print`) from  `run-healthcheck-target-env.sh`

In consequence, our **"Healthcare Target Environment Proof"** bash script (`run-healthcheck-target-env.sh`) no longer requires the following step either: 

~~~bash 
# scripts/testing/run-healthcheck-target-env.sh

# ...

# Install the Ruby gem required by the helper in this temporary runtime.
#
# kubectl exec = execute a command inside the running Pod
# gem install awesome_print = install the pretty-printing gem used by the script output
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- gem install awesome_print
# Expected:
# Successfully installed awesome_print-1.9.2
# 1 gem installed
~~~

#### Remove the `awesome_print` gem from the Healtcheck `Dockerfile` 

... nor does the Healthcheck-`Dockerfile`

~~~Dockerfile
# healthcheck/Dockerfile
FROM alpine:3.12.0

RUN apk update && \
    apk add ruby ruby-json ruby-rdoc ruby-irb

# No longer needed:
# RUN gem install awesome_print

COPY healthcheck.rb healthcheck.rb
ENTRYPOINT ["ruby", "healthcheck.rb"]
~~~

### Refactor the Healtcheck Target Proof-Helper (`run-healthcheck-target-env.sh`)

To be able to prove the claimed "Pipeline-Readiness" of the Ruby refactor (prior to a CI/CD-worflow update and an actual pipeline run), the "Healthcare Target Environment Proof"-helper script needs also to be optimized in that regard.

Below an excerpt of the refactor - for details and commentary see `scripts/testing/run-healthcheck-target-env.sh`: 

~~~bash
#!/usr/bin/env bash

# run-healthcheck-target-env.sh

# Enable stricter Bash error handling for this proof helper (every command is required for success)
set -euo pipefail

#######################################
# Performs best-effort cleanup of the temporary Ruby proof Pod.
#######################################
cleanup() {
    # -n sock-shop-dev         = target the dev namespace on the target cluster
    # tmp-ruby-healthcheck     = the temporary Pod created for the Ruby healthcheck proof
    # --ignore-not-found       = do not fail if the Pod was already removed or never created
    # >/dev/null               = discard normal command output
    # 2>&1                     = redirect error output to the same discarded destination
    # || true                  = keep cleanup non-fatal even if kubectl still returns a non-zero exit code
    kubectl delete pod -n "$NAMESPACE" "$POD_NAME" --ignore-not-found >/dev/null 2>&1 || true
}

# Exit Trap
trap cleanup EXIT

# Confirm that kubectl is targeting the real target node rather than the laptop-side local cluster.
# >&2     = redirect output to stderr for script chainability/to keep stdout reserved for the final JSON result.   
kubectl get nodes -o wide >&2

# Start a temporary Ruby Pod inside the real dev namespace.
kubectl run "$POD_NAME" -n "$NAMESPACE" \
  --image="$RUBY_IMAGE" \
  --restart=Never \
  --command -- sleep 3600 >&2
#=> pod/tmp-ruby-healthcheck created  

# Wait until the temporary Pod is ready for execution 
kubectl wait --for=condition=Ready "pod/$POD_NAME" -n "$NAMESPACE" --timeout=120s >&2
#=> pod/tmp-ruby-healthcheck condition met 

# Copy the current local healthcheck.rb file into the running Pod.
kubectl cp healthcheck/healthcheck.rb "$NAMESPACE/$POD_NAME:/tmp/healthcheck.rb" >&2   

# Validate the syntax of the healthcheck helper without executing it 
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- ruby -c /tmp/healthcheck.rb >&2
#=> Syntax OK

# Execute the current helper against real in-cluster service names.
# FYI: This command doesn't require an active redirection command like >&2 
# for status messages (like "Sleeping for 5s ...") - this is handled by Ruby: 
# Status messages got to sdterr - and the json paylod to stdout. All that's 
# needed here is the -q option:   
# -q              = Quiet mode; suppresses kubectl setup warnings.
kubectl exec -q -n "$NAMESPACE" "$POD_NAME" -- \
  ruby /tmp/healthcheck.rb \
    --services catalogue,user,carts \
    --retry 3 \
    --delay 5
~~~

**Result:**
By refactoring the proof helper's execution logic and stream handling, we achieved the following goals:

- **Strict Error Handling (`set -euo pipefail`):** Ensures that the script exits immediately if any single command fails (e.g., a failed Pod creation or a network timeout), preventing "silent failures" in automation.
- **Resource Lifecycle Management (`trap cleanup EXIT`):** Guarantees "Best-Effort Teardown." Regardless of whether the healthcheck succeeds, fails, or is manually interrupted, the temporary Pod is automatically removed, preventing cluster resource leakage (zombie Pods).
- **Stream-Aware Separation & Chainability:** By explicitly redirecting all status/log messages (Kubectl status, Node lists, syntax checks) to `stderr` (`>&2`) and by surpessing noise via `kubectl exec -q`, the script protects the `stdout` stream. This ensures that only the pure JSON payload from the Ruby helper reaches the workstation’s primary output stream - which than can be chained directly into JSON processors like `jq`.

This all transforms the script into a **machine-parsable tool** and enables complex commands that envolve Make, Ruby, Bash, kubectl/cluster and tools like jq: 

  `make -s p07-healthcheck-target-env | jq`  

### Add Ruby characterization and unit tests

Now that `HealthChecker` is in a testable shape amd can therefore be imported safely, `HealthChecker` test suites can be implemented using Ruby's `Minitest` gem. 

To provide a strong test coverage, we will split the tests into **two separte test classes with different goals**:

- `HealthcheckCliTest`: For **CLI characterization tests** that verify CLI-behavior from the outside (from a user's or kubectl's point of view) and make sure, the original behavior (character) as CLI Tool stays intact. The CLI tests **protect the script's "external contract"** before and after refactorings.
- `HealthcheckUnitTest` A **unit-test suite** that verifies the refactored helper internals in isolation. The unit tests **protect the internal logic** before and after refactorings.

> [!NOTE] **🧩 Minitest**
>
> **Minitest** is Ruby’s lightweight built-in testing framework. It provides the basic building blocks needed to write automated tests, especially:
>
> - test classes
> - assertions
> - setup/teardown structure
> - stubbing  
> - direct command-line test execution
>
> In this phase, Minitest is used for both:
>
> - **CLI characterization test** (`test_healthcheck_cli.rb`)
> - **Unit-test suite** (`test_healthcheck.rb`)
>
> This keeps the Ruby test layer small and easy to run locally as well as later in CI.

> [!NOTE] **🧩 Characterization test**
>
> A **characterization test** is a software-testing concept: Its purpose is to **capture and preserve the current "character" - i.e. observable behavior - of existing code**, especially before refactoring code that already works but is not yet well structured internally.
>
> In practice, a characterization test answers the question:
>
> - **What does this code do right now, and can that behavior be kept stable while the internals change?**
>
> In this phase, `test_healthcheck_cli.rb` plays exactly that role: it locks down the current command-line behavior of the Ruby `healthcheck` helper so the later refactor can proceed safely without accidentally changing its "external contract".

> [!NOTE] **🧩 Unit test**
>
> A **unit test** is a software test that checks one **small, isolated piece of code** in a controlled way, for example:
>
> - one function
> - one method
> - or one small class behavior
>
> The goal is to verify that this small code unit behaves correctly **without depending on the full surrounding system**, such as real network calls, live databases, or external services.
>
> In this phase, `test_healthcheck.rb` is the unit-test suite for the Ruby `healthcheck` helper: it imports the refactored helper directly, replaces external network calls with controlled test doubles, and verifies the internal logic in isolation.

#### CLI characterization test

The CLI characterization test is placed in:

- `tests/ruby/test_healthcheck_cli.rb`

It executes the helper as a separate OS process via Ruby's `Open3` library and checks the observable CLI behavior through `stdout`, `stderr`, and the exit status.

Below is the excerpt (for the full commented implementation see `tests/ruby/test_healthcheck_cli.rb`):

~~~ruby
require "minitest/autorun"
require "open3"
require "json"

class HealthcheckCliTest < Minitest::Test
  # TEST: Verify that the script aborts gracefully with "no services specified" 
  # when missing required arguments ('--services')
  #
  # Open3.capture3 runs the script as a separate OS process and captures the stdout,
  # stderr, and exit status that a terminal user would observe.
  def test_exits_with_error_when_no_services_are_provided
    stdout, stderr, status = Open3.capture3("ruby", "healthcheck/healthcheck.rb")

    combined_output = "#{stdout}#{stderr}"

    # Assert that the command did not succeed - i.e. it should have exited with a non-zero exit code
    refute status.success?, "Expected non-zero exit status when no services are provided"
    assert_includes combined_output, "no services specified"
  end

  # TEST: Verify that valid arguments are parsed and a reachable/unreachable 
  # network state results in the correct JSON terminal output and exit code 
  # (i.e. a failed target still leads to non-zero exit)
  def test_outputs_json_and_fails_when_service_is_unreachable
    stdout, _stderr, status = Open3.capture3(
      "ruby",
      "healthcheck/healthcheck.rb",
      "--services", "localhost:9999",
      "--retry", "1",
      "--delay", "0"
    )

    # The script should exit with a failure code because the healthcheck failed
    refute status.success?, "Expected non-zero exit status for unreachable service"

    # The script should still output valid JSON to stdout so Kubernetes can read it
    parsed_output = JSON.parse(stdout)
    assert_equal "err", parsed_output["localhost:9999"]
  end
end
~~~

This test file proves that the helper still behaves correctly as a CLI executable after the refactor and that its "external command-line contract" remains intact:

- Missing required runtime input still leads to a non-zero exit
- failing service checks still lead to a non-zero exit
- Machine-readable JSON output is still emitted in the failing-service case

#### Ruby unit-test suite

The unit-test suite is placed in:

- `tests/ruby/test_healthcheck.rb`

It imports the refactored helper class directly and tests the internal logic without performing real network calls. Below is the most relevant excerpt (for the full commented implementation see `tests/ruby/test_healthcheck.rb`):

~~~ruby
require "minitest/autorun"
require "json"
require_relative "../../healthcheck/healthcheck"

class HealthcheckUnitTest < Minitest::Test
  # Lightweight mock object to simulate Net::HTTP responses
  FakeResponse = Struct.new(:body)

  # --- Test Argument Parsing & Initialization ---

  def test_default_retry_is_one
    checker = HealthChecker.new(["--services", "catalogue"])
    assert_equal 1, checker.options[:retry]
  end

  def test_services_are_split_into_an_array
    checker = HealthChecker.new(["--services", "catalogue,user,carts"])
    assert_equal ["catalogue", "user", "carts"], checker.services
  end

  def test_run_returns_false_when_services_option_is_missing
    checker = HealthChecker.new([])
    assert_equal false, checker.run
  end  

  # --- Execution & Network Mocking ---

  def test_successful_health_response_is_aggregated
    checker = HealthChecker.new(["--services", "catalogue"])

    # Simulate a valid JSON payload returned by the target service
    fake_payload = {
      "health" => [
        { "service" => "catalogue", "status" => "OK" },
        { "service" => "catalogue-db", "status" => "OK" }
      ]
    }

    # Stub / intercept `get_response` to prevent a real network call 
    # and perform our assertion.
    Net::HTTP.stub(:get_response, FakeResponse.new(JSON.generate(fake_payload))) do
      assert_equal true, checker.run
    end

    assert_equal "OK", checker.health["catalogue"]
    assert_equal "OK", checker.health["catalogue-db"]
  end

  def test_failed_request_marks_service_as_err
    checker = HealthChecker.new(["--services", "catalogue"])

    # Simulate a network exception by stubbing/intercepting the network call 
    # and force it to simulate a crash/timeout.
    Net::HTTP.stub(:get_response, proc { raise StandardError, "boom" }) do
      assert_equal false, checker.run
    end

    assert_equal "err", checker.health["catalogue"]
  end

  # TEST: Verify that the delay parameter is correctly parsed and executed.
  def test_delay_is_used_when_configured
    checker = HealthChecker.new(["--services", "catalogue", "--delay", "5"])

    fake_response_payload = {
      "health" => [
        { "service" => "catalogue", "status" => "OK" }
      ]
    }

    sleep_calls = []
 
    # STUB 1 (Instance-Level): Intercept the `sleep` command on this specific object
    # and instantly continue execution. This keeps the test suite fast:
    checker.stub(:sleep, proc { |seconds| sleep_calls << seconds }) do

      # STUB 2 (Class-Level): Intercept the global network call.
      Net::HTTP.stub(:get_response, FakeResponse.new(JSON.generate(fake_response_payload))) do
        checker.run
      end
    end

    # VERIFY: Assert that the Healthcheck successfully calculated and triggered the  
    # exact 5-second delay (but without the test runner actually having to wait for it).
    assert_equal 5, checker.options[:delay] # asserts correct options parsing
    assert_equal [5], sleep_calls # asserts correct runtime execution 
  end

  # Vacuous-truth test of HealthCheck#healthy? 
  # healthy? must deliver false if @health.empty? (i.e. if no services are provided 
  # in the response at all)  
  def test_empty_health_payload_does_not_report_success
    checker = HealthChecker.new(["--services", "catalogue"])

    # Faked empty health response
    fake_response_payload = {
      "health" => []
    }

    Net::HTTP.stub(:get_response, FakeResponse.new(JSON.generate(fake_response_payload))) do
      assert_equal false, checker.run
    end

    assert_equal false, checker.healthy?
    assert_equal({}, checker.health)
  end
end
~~~

**Result**:

These tests verify the most relevant internal behavior introduced by the refactor:

- Default option handling
- Service-list parsing
- Safe handling of missing required runtime input
- Aggregation of successful health payloads
- Controlled handling of failed network calls
- Hardening against empty health payloads that must not report success
- Correct execution of configured delay behavior without slowing down the test run

#### Run the Ruby characterization and unit-test suites

~~~bash
# (1) Validate the syntax of the refactored helper.
$ ruby -c healthcheck/healthcheck.rb
Syntax OK

# (2) Run the CLI characterization test to confirm that the external script behavior
# still matches the expected command-line contract after the refactor.
$ ruby tests/ruby/test_healthcheck_cli.rb
Run options: --seed 49424
# Running:
..
Finished in 0.193117s, 10.3564 runs/s, 25.8911 assertions/s.
2 runs, 5 assertions, 0 failures, 0 errors, 0 skips

# (3) Run the Ruby unit-test file against the refactored helper internals.
$ ruby tests/ruby/test_healthcheck.rb
Run options: --seed 3738
# Running:
...Sleeping for 5s...
....
Finished in 0.010148s, 689.7804 runs/s, 1281.0208 assertions/s.
7 runs, 13 assertions, 0 failures, 0 errors, 0 skips
~~~

### Local dev + test cycle

Once the first Ruby tests exist, the local loop for further refactoring becomes:

~~~bash
# Validate syntax after each edit 
$ ruby -c healthcheck/healthcheck.rb

# Re-run the Ruby CLI characterization check 
$ ruby tests/ruby/test_healthcheck_cli.rb

# Re-run the Ruby unit-test suite 
$ ruby tests/ruby/test_healthcheck.rb

# Every now and then - for "milestone" checks
$ make p07-healthcheck-target-env 

# When chaining i sneeded use the -s flag:  
make -s p07-healthcheck-target-env | jq 'with_entries(select(.key | endswith("-db")))'
~~~

Or using make targets only use this flow:

~~~bash
# Runs syntax check, CLI characterization check + unit-test suite in one go: 
make p07-healthcheck-tests  

make p07-healthcheck-target-env
~~~


### Validating "Pipeline-Readiness" 

To verify that the refactor successfully enabled not only testability but also tool-chainability, we utilize the also refactored **Healthcare Target Environment Proof** script. 

This helper allows us to prove (prior to any a workflow update and actual Pipeline runs), that the **Ruby script is now "Pipe-Ready"** even when executed through multiple layers (Make -> Bash -> Kubectl -> Ruby -> `jq`).

- **Chainability Proof:** 

The final output of the Healtchecker script ca be piped directly into `jq` from the workstation:

~~~bash
# Example: Chaining a remote cluster check into jq via the Make helper
# -s flag ensures 'make' does not echo the command to stdout
$ make -s p07-healthcheck-target-env | jq 'with_entries(select(.key | endswith("-db")))'
# This goes only to stderr, keeping stdout clean
pod/tmp-ruby-healthcheck created
pod/tmp-ruby-healthcheck condition met
Syntax OK
Sleeping for 5s...
# stdout now only contains the filtered JSON:
{
  "catalogue-db": "OK",
  "user-db": "OK",
  "carts-db": "OK"
}
~~~

### Result

The Ruby `healthcheck` helper was refactored from a directly executed top-level script into an importable `HealthChecker` class plus execution guard. As a result, it is now **Unit-Testable, CLI-Testable, and Machine-Chainable**.

The successful end state is shown by these signals / verification points:

- `healthcheck/healthcheck.rb` remained syntactically valid after the refactor
- The helper can now be imported safely through `require_relative` without triggering uncontrolled top-level execution
- The CLI characterization test passed and confirmed that the external command-line contract still behaves as expected
- The unit-test suite passed and verified the refactored helper internals in isolation
- Human-readable runtime messages and machine-readable JSON output are now separated cleanly across `stderr` and `stdout`
- The helper no longer depends on `awesome_print`, which reduces runtime setup friction and simplifies later automation
- The refactored target-environment proof helper can now forward the Ruby helper's JSON output cleanly into downstream tools such as `jq`
- The local Ruby edit-test cycle now supports repeated refactoring work without requiring a full in-cluster proof run after every small code change

At this point, the Ruby helper has moved from a manually executed operational script to a **Controlled, Repeatable, and Pipeline-Ready CLI Tool**. It preserves its original runtime purpose, can now be tested safely at both CLI and unit level, and exposes a clean machine-readable output stream for later automation steps.

--- 







## Phase 07 Outcome Summary 

Phase 07 implemnts an initial quality gate set as base for <later pahses, that ...>:

- Pre-deploy checks for owned code and basic security posture
- Post-deploy checks against the live `dev` environment
- Gated promotion to `prod` only after the lower dev environment has been exercised successfully 