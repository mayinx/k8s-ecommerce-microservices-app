## Step 5 — Add a Python consumer-side contract guard and local unit tests

### Rationale

Step 3 already added a Ruby healthcheck layer that proves service reachability and basic health behavior. 

What the Ruby healthcheck does not prove is whether a reachable service delivers **data that is structurally intact** and in accordance with **"consumer expectations"**. 
- Currently, a service that responds with an HTTP `200 OK` but a structurally broken JSON payload is considered healthy by the Ruby healthchecker—even though it is a failure condition for the consuming downstream service. 
- Schema drift/inconsistency can break downstream consumers just as easily as a network failure: If the `catalogue` API unexpectedly renames its `price` field, the Ruby network check still passes, but the downstream `front-end` service will crash when trying to render the shop UI.

To ensure that **services return a response shape that remains compatible with downstream consumers**, we must **validate the application data layer** alongside the network layer. 

#### Goal 

The next useful addition is therefore a small **Python consumer-side contract guard** for a selected service and its response **to ensure schema consistency**. 

The goal of this phase is to establish a **small, reusable foundational Python QA surface** that initially **validates data structure locally** and focuses on pure contract logic. 

Once proven, this same test engine can be reused in later steps to be run against live API endpoints. This approach avoids a premature coupling of Step 5 to cluster access.

**The scope of this step is therefore deliberately focused:**

- The contract guard is implemented initially for the **`catalogue` service response**.
- The Python test layer is kept **local and deterministic** 
- The tests validate **response compatibility rules**, not live cluster connectivity.
- The schema is modeled as a **consumer-side guardrail** - and **not** as the canonical specification of the upstream provider's API schema.

> [!NOTE] **🧩 Consumer-side contract guard & schema authority**
>
> To clarify: The Python schema introduced in this step is not treated as the authoritative source for the specification of the upstream catalogue API.
>
> The Python schema acts as a **consumer-side contract & compatibility guard** that defines the **minimum response structure** this project expects to **remain stable**. If the upstream service changes in a way that violates that **minimum contract**, the test fails and **forces an explicit compatibility decision**.

> [!NOTE] **🧩 Deterministic vs. Flaky Tests**
>
> A **deterministic test** produces the exact same result every time it runs. 
> A **flaky test** fails randomly (e.g., due to network timeouts, pod restarts, or DNS blips). 
> By initially isolating this Python contract guard to **run locally against static data**, we guarantee it is **deterministic and serves as a working foundation** for later checks against the live API. 
> By reusing this exact same test engine in those later phases, we rule out buggy test code as the cause of failed tests: Any failures will definitively point to a broken cluster API.

### Action


TODO: Little goal is now intro or so ...


#### Create a small project-local Python test environment

Before adding the Python QA utility, a small project-local virtual environment needs to be created under the already ignored Phase 07 test area. Inside that evironment we install the minimum packages needed for this step.

**(1) Requirements file:**

~~~text
# tests/python/requirements-p07.txt
pytest
jsonschema
~~~

**(2) To create and populate the local virtual environment from the repo root:**

~~~bash
# Create a small project-local Python virtual environment for the Phase 07 QA tooling
$ python3 -m venv tests/venv/p07-python

# Upgrade pip inside the local environment
$ tests/venv/p07-python/bin/python -m pip install --upgrade pip

# Install the exact Python packages needed for this step
$ tests/venv/p07-python/bin/python -m pip install -r tests/python/requirements-p07.txt
~~~

This keeps the Python tooling local to the repository and avoids relying on global Python package state.

> [!NOTE] **🧩 Virtual Environment (`venv`)**
>
> The usage of `venv` brings several advantages:
> - **Dependency Isolation:** Project packages are never to be installed into the global workstation Python. **A `venv` acts as an isolated sandbox**, ensuring our QA tools do not conflict with system packages or other local projects.
> - **Reproducibility:** `pip` (the Python package manager) installs exactly what is declared in our requirements file directly into this sandbox. This ensures any developer or CI/CD runner operates in the exact same state.
> **Note: gitignore `venv`!** The generated `venv` folder contains hundreds of system-specific binaries and library files. It **must never be committed** to version control (which is why we already excluded `tests/venv/` in our `.gitignore` back in Step 1).

#### Adding stable Python package markers for the test module path

To **avoid import-path inconsistencies** between direct local execution and `pytest`, two minimal and empty **package marker files** are added on different levels of the test directory tree:

- `tests/__init__.py`
- `tests/python/__init__.py`

This keeps the import path stable for the contract guard module and the unit tests to be created:

- `tests.python.sockshop_contract_guard`
- `tests.python.test_contract_guard`

> [!NOTE] **🧩 `__init__.py` and path stability**
>
> - **`__init__.py`** is a special Python file that explicitly marks a standard directory as a "Python Package." The file can be completely empty. 
> - Without these markers, Python relies heavily on the Current Working Directory (`pwd`), which can cause isseus when running tests f.i.:     
>   - Running `pytest` from the repository root versus running it from inside the `tests/python/` folder can cause `ModuleNotFoundError` crashes. 
>   - The interpreter gets confused about whether `schemas/` is a top-level folder or a sub-module.
> - **The Fix:** Adding these files **"anchors" the directory structure**. It tells `pytest` and the Python interpreter to **treat `tests/python/` as a stable, predictable module hierarchy**. This ensures that **cross-file imports** work exactly the same way locally on a developer's laptop as they do inside a GitHub Actions runner.

#### Discovery: Inspecting the catalogue API response schema to identify essential properties 

Before defining a compatibility schema, we must "get the lay of the land" by inspecting the actual live response from the catalogue API:

~~~bash
# Inspect the first 3 items from the live catalogue endpoint
curl -s https://prod-sockshop.cdco.dev/catalogue | jq '.[0:3]'
~~~
~~~json
[
  {
    "id": "03fef6ac-1896-4ce8-bd69-b798f85c6e0b",
    "name": "Holy",
    "description": "Socks fit for a Messiah. You too can experience walking in water with these special edition beauties. Each hole is lovingly proggled to leave smooth edges. The only sock approved by a higher power.",
    "imageUrl": [
      "/catalogue/images/holy_1.jpeg",
      "/catalogue/images/holy_2.jpeg"
    ],
    "price": 99.99,
    "count": 1,
    "tag": [
      "magic",
      "action"
    ]
  },
  ... 
]
~~~

##### Choosing the reference consumer and defining the compatibility baseline

In this phase, the **`front-end` service is used as the reference consumer** because it is the most immediate downstream service consuming catalogue data in this project - without claiming verified knowledge of every internal fallback or rendering dependency inside that service. If the catalogue payload becomes structurally incompatible, the breakage is most likely to surface there first.

At the same time, this schema is **not** based on a verified field-by-field analysis of the `front-end` implementation, which is not part of this repository and not directly analyzed in this step. 

The compatibility schema in this phase is therefore an **informed and flexible baseline**: - Strict enough to catch likely breaking changes and avoid letting incompatible catalogue payloads pass unnoticed
- Tolerant enough to avoid failing on harmless additions or non-breaking metadata changes 
- While remaining open to later refinement if additional downstream field dependencies become clear.

So the goal is to establish a **minimum viable compatibility baseline** for our consumer-side schema contract:

- **Identify the smallest field subset** that should remain structurally stable for downstream use by the `front-end` service  
- **Maintain tolerance** toward non-breaking changes or inconsistencies in "nice-to-have" attributes. 

##### Essential Fields

For this compatibility baseline, the following fields are treated as the **functional core of the catalogue response**. This is an informed compatibility choice, not a claim that every internal dependency of the `front-end` service is fully known. The selection focuses on the **fields most likely to cause genuine technical breakage if they disappear or change**:

- **`id`:** Treated as essential for product identity, item correlation, and cart-related flow.
- **`name`:** Treated as the minimum field required to render a product entry meaningfully in the storefront.
- **`price`:** Treated as essential for price display and downstream total-calculation logic.

##### Non-Essential Data

The following fields are intentionally omitted from strict validation in this phase to reduce test fragility and avoid turning non-breaking content changes into pipeline failures:

- **`description`:** If it’s missing, the UI might look slightly empty, but it does not prevent the core shop flow from functioning.
- **`imageUrl`:** While important for aesthetics, images are prone to change. The contract test should not fail just because a fictional marketing team changed an image path.
- **`count` / `tag`:** These are metadata useful for filtering, but their absence does not represent a breaking dependency for basic display.


> [!NOTE] **🧭 Why this baseline stays intentionally narrow**
>
> Each of these choices remains debatable and may be refined later.
>
> Missing images or descriptions may still matter commercially, visually, or even legally in a real e-commerce setting. The focus in this phase, however, is structural downstream compatibility: guarding the fields most likely to represent genuine technical breakage if they disappear or change incompatibly.
>
> If later discovery shows that additional fields are true hard dependencies of the `front-end` service, this baseline can be tightened deliberately.

#### Implementing the Python contract-guard module for schema definition and validation

With the compatibility baseline now defined, it can be translated into a Python **contract-guard module** that centralizes schema definition and validation in one **reusable QA utility**. Later phases can reuse this utility against a live fetched catalogue response. But for now we stay local.

The contract-guard module is placed in `tests/python/sockshop_contract_guard.py` and contains:

- A **minimal compatibility schema** for `catalogue` items
- A small **validation function** that turns **schema violations** into readable **Python exceptions**

Like outlined in the previous section, the resulting compatibility schema intentionally remains **subset-based** and **tolerant**:

- **Subset-based**: It validates only the fields this project actually cares about
- **Tolerant**: It allows additional upstream fields to exist without failing the test

Below is the implementation of the contract guard:

~~~python
# tests/python/sockshop_contract_guard.py

from jsonschema import Draft202012Validator

# Consumer-side compatibility schema for catalogue responses.
#
# This is intentionally a minimum required response shape, not a full upstream API specification.
CATALOGUE_COMPAT_SCHEMA = {
    "type": "array",
    "minItems": 1,
    "items": {
        "type": "object",
        "required": ["id", "name", "price"],
        "properties": {
            "id": {"type": "string", "minLength": 1}, 
            "name": {"type": "string", "minLength": 1},
            "price": {"type": "number", "minimum": 0},
        },
        # Keep the contract tolerant: harmless extra fields should not break the test.
        "additionalProperties": True,
    },
}

_VALIDATOR = Draft202012Validator(CATALOGUE_COMPAT_SCHEMA)

# Validation Engine: Used by local unit tests 
# Will later act as shared validation engine used by both local unit tests and live smoke tests
def validate_catalogue_contract(payload: object) -> bool:
    """Validate a parsed catalogue payload against the minimum compatibility schema."""
    errors = sorted(_VALIDATOR.iter_errors(payload), key=lambda error: list(error.path))

    if errors:
        messages = []
        for error in errors:
            location = " -> ".join(str(part) for part in error.path) or "<root>"
            messages.append(f"{location}: {error.message}")

        raise ValueError("Catalogue contract violation:\n" + "\n".join(messages))

    return True
~~~


> [!NOTE] **🧩 The "Tolerant Reader" Pattern**

> By explicitly setting `"additionalProperties": True` and only requiring `id`, `name`, and `price`, this schema implements the "Tolerant Reader" pattern. 
> Example: If the fictional backend team adds add hoc a new field such as `stock_count`, this test will safely and deliberately ignore it. The CI/CD build should break only if an actual **breaking change** occurs that is **critical for the downstream consumer**, such as a required field going missing or changing data type.

> [!TIP] **🧩 `_VALIDATOR.iter_errors`**
>
> A standard `jsonschema.validate()` call crashes on the very first error it encounters. By using `_VALIDATOR.iter_errors(payload)`, our custom function collects *all* schema violations across the entire JSON array before failing. If both `name` and `price` are broken, the CI log will report both at once, saving developers from fixing one error just to trigger another in the next pipeline run.

#### Implementing the local Python unit tests

With the Python contract-guard module now in place, the next step is to **verify its behavior locally through unit tests** covering both valid and incompatible catalogue payloads.

The first Python test layer is implemented in `tests/python/test_contract_guard.py` and stays fully local and deterministic:

- No live HTTP calls
- No cluster access
- No dependency on a running environment

These Python tests are **unit tests** of the contract-guard utility: They validate the **contract logic** locally and deterministically against static sample payloads, without any live network or cluster dependency.

~~~python
# tests/python/test_contract_guard.py

import pytest

# Import the validation engine for local, isolated testing against static payloads.
from tests.python.sockshop_contract_guard import validate_catalogue_contract

def test_valid_catalogue_payload_passes_contract_guard():
    payload = [
        {
            "id": "sock-001",
            "name": "Classic Blue Sock",
            "price": 9.99,
            "description": "Extra upstream fields remain allowed.",
        }
    ]

    assert validate_catalogue_contract(payload) is True


def test_missing_required_field_fails_contract_guard():
    payload = [
        {
            "id": "sock-001",
            "price": 9.99,
        }
    ]

    with pytest.raises(ValueError, match="name"):
        validate_catalogue_contract(payload)


def test_non_numeric_price_fails_contract_guard():
    payload = [
        {
            "id": "sock-001",
            "name": "Classic Blue Sock",
            "price": "9.99",
        }
    ]

    with pytest.raises(ValueError, match="price"):
        validate_catalogue_contract(payload)


def test_negative_price_fails_contract_guard():
    payload = [
        {
            "id": "sock-001",
            "name": "Classic Blue Sock",
            "price": -1,
        }
    ]

    with pytest.raises(ValueError, match="price"):
        validate_catalogue_contract(payload)
~~~

These tests prove the core behavior of the contract guard:

- Valid payloads pass
- Mssing required fields fail
- Wrong data types fail
- Invalid numeric values fail

#### Run the local Python contract-guard checks

Once the files are in place, the full local Python checks can be executed from repo root. To keep the local verification flow consistent with the Phase 07 Ruby + Bash work and to make things easier, the root `Makefile` was again extended with **several helper targets for the Python tests**: 

~~~bash
# Run the full local Python contract-guard check via Make.
$ make p07-contract-guard-tests
OK: Phase 07 Python environment ready -> tests/venv/p07-python
OK: Python syntax valid -> tests/python/sockshop_contract_guard.py, tests/python/test_contract_guard.py
RUN: Phase 07 Python contract-guard tests -> tests/python/test_contract_guard.py
....                                                                                                                                                                                [100%]
4 passed in 0.04s
OK: Phase 07 Python contract-guard tests passed
~~~

The underlying raw commands executed by that Make target are:

~~~bash
# Create/update the local Python environment for Step 5.
$ python3 -m venv tests/venv/p07-python
$ tests/venv/p07-python/bin/python -m pip install --upgrade pip
$ tests/venv/p07-python/bin/python -m pip install -r tests/python/requirements-p07.txt

# Validate syntax of the Python module and test file.
$ tests/venv/p07-python/bin/python -m py_compile \
    tests/python/sockshop_contract_guard.py \
    tests/python/test_contract_guard.py

# Run the local deterministic Python tests.
$ tests/venv/p07-python/bin/python -m pytest tests/python/test_contract_guard.py
~~~

#### Local dev + test cycle

The local loop for further Python QA work is now:

~~~bash
# Run the Python contract-guard checks.
$ make p07-contract-guard-tests

# Run the current full Phase 07 local test set.
$ make p07-tests
~~~

At this point, the Python layer remains intentionally local and deterministic. 

The next step reuses the same contract-guard utility against a live `catalogue` response from the deployed `dev`-environment.

### Result

Step 5 established a first dedicated **Python QA layer** of Phase 07. 

This QA Layer functions now as a **local and reusable consumer-side contract guard** for catalogue responses.

The successful end state is shown by these signals / verification points:

- A small **project-local Python environment** now exists under `tests/venv/p07-python` and can be recreated through the dedicated Phase 07 Make target
- The new Python contract-guard module validates a **minimal, tolerant consumer-side compatibility schema** for `catalogue` responses
- The first **Python tests passed locally** as successfull **unit tests of the contract-guard utility** - without requiring any live network or cluster access
- The Python layer now follows the same operational pattern already established for Ruby and Bash:
  - **environment setup**
  - **syntax validation**
  - **dedicated test execution**
  - **Makefile-based local rerun flow**
- The **Phase 07 aggregated Make target `p07-tests**` now **includes Ruby, Bash, and Python**
- The Python contract-guard utility is now in place as a **reusable QA building block** for the later **live API contract smoke check in** the next step

At this point, the Phase 07 test layer validates 
- **Service health/reachability** (Ruby) 
- **Helper-script behavior** (Bash) 
- **Response-shape compatibility/expectations** (Python) 

---

## Step 6 — Reuse the Python contract guard against the live catalogue API

### Rationale

Step 5 established the Python **contract guard** as a **local and deterministic QA utility**. While this proves our validation logic is sound, it has only been tested within the safety of static, in-memory mock data.

The next progression is to reuse that exact same validation logic against the **live catalogue API**. This closes the gap between:

- **Local contract correctness** and
- **Live environment contract validity**

The key design principle from Step 5 remains unchanged: 
- The live check must **reuse the already proven Python contract guard** instead of introducing a second, separate validation path.

#### Separation of Concerns

At the same time, this live check is **not folded into the default deterministic local test set** from Step 5:

- The Step 5 local tests remain the stable foundation
- The live API contract check is added as a **separate smoke layer**
- The default local Phase 07 loop remains free from network or environment dependency

### Action

#### Implementing a dedicated live Python smoke test for the catalogue contract

To utilize the Step 5 catalogue contract guard against the live application, we create a second Python test file under `tests/python/test_contract_guard_live.py`.

This smoke test 
- fetches the live `/catalogue` response from a configurable base URL 
- and passes the parsed JSON payload into the already existing `validate_catalogue_contract(...)` function from Step 5 fro resposne schema validation.

Below an excerpt of the implementation (for the full commented script see `test/python/test_contract_guard_live.py`):

~~~python
# test_contract_guard_live.py
#!/usr/bin/env python3

# ...

import pytest

# Import the shared validation engine to evaluate the live payload.
from tests.python.sockshop_contract_guard import validate_catalogue_contract

# Default live target for the first contract smoke check.
DEFAULT_BASE_URL = "https://dev-sockshop.cdco.dev"

def test_live_catalogue_contract_guard():
    # Resolve the base URL from the environment if present.
    base_url = os.getenv("SOCKSHOP_CONTRACT_BASE_URL", DEFAULT_BASE_URL).rstrip("/")
    catalogue_url = f"{base_url}/catalogue"

    try:
        request = Request(
            catalogue_url,
            headers={
                "User-Agent": "Mozilla/5.0",
                "Accept": "application/json",
            },
        )

        with urlopen(catalogue_url, timeout=10) as response:
              if response.status != 200:
                pytest.fail(f"Live catalogue request returned HTTP {response.status}: {catalogue_url}")

            # Parse the live JSON payload directly from the response stream.
            payload = json.load(response)

    except HTTPError as exc:
        pytest.fail(f"Live catalogue request failed with HTTP status {exc.code}: {catalogue_url}")

    except URLError as exc:
        pytest.fail(f"Live catalogue request could not reach the target URL: {catalogue_url} ({exc})")

    except json.JSONDecodeError as exc:
        pytest.fail(f"Live catalogue response is not valid JSON: {catalogue_url} ({exc})")

    # Reuse the already proven Step 5 contract guard - now to evaluate a live payload instead
    assert validate_catalogue_contract(payload) is True
~~~

This is not a unit test anymore. It is a **live integration / smoke test** that reuses the already proven Step 5 contract guard against a real deployed endpoint.

The test intentionally defaults to the **public `dev` edge URL**:
- it remains easy to execute from the workstation
- it works naturally with later CI usage
- it avoids requiring cluster-internal DNS, `kubectl exec`, or an in-cluster test runner for the first live smoke step

This keeps the live smoke test intentionally small:

- 1 Live endpoint
- 1 Shared validation engine
- 1 Explicit contract decision point


> [!INFO] **Concept: The "Smoke Test"**
> In software engineering, a **Smoke Test** is a **rapid, preliminary check** designed to answer one simple question: *"Is the system stable enough to warrant further testing?"*
> 
> * **The Origin:** The term comes from hardware engineering. When a new circuit board is powered on for the first time: does smoke come out? If yes, it needs to be unpluged immediately. No one wastes more time checking if some LEDs blink.
> * **In CI/CD & DevOps:** A smoke test acts as the first line of defense. Instead of running a comprehensive, hour-long test suite, the pipeline runs a 5-second check (e.g., *"Is the API reachable? Is the database connected?"*). 
> * **The Goal:** **Fail fast**. If the smoke test fails, the deployment is rejected immediately, saving valuable compute resources and developer time.

> [!NOTE] **🧭 Why the public edge URL is used here**
>
> This first live contract smoke test validates the catalogue response through the deployed application path exposed at the public edge (htrtps://dev-smoke-shop.cdco.dev), not through a cluster-internal service-to-service route.
>
> That is a deliberate choice in favor of usability (for this phase): The smoke check becomes easy to run from the workstation and from CI, while still validating the live deployed path.
> 
> A later step can still add a more internal validation path if needed.

> [!NOTE] **🧩 Why `urllib` is used instead of `requests`**
>
> Only one simple HTTP GET request is needed in this step. Python’s standard library is sufficient for that purpose and avoids expanding the dependency surface of the Phase 07 Python tooling with an additional HTTP client package.

#### Keep the live smoke path separate from the deterministic Step 5 loop

The live contract smoke check is intentionally **not** added to the default `p07-tests` aggregate target in this step.

That separation is deliberate:

- `p07-tests` remains the fast and deterministic local baseline
- the live contract smoke path remains an explicit environment-facing validation step
- edge or network instability does not pollute the default local Phase 07 loop

This keeps the signal model clean:

- **default test path** = deterministic
- **live smoke path** = environment-dependent by design

#### Running the live Python contract smoke check

Once the live test file is in place, the live Python contract smoke test can be executed from repo root against the configured target path.

To keep the live verification flow consistent with the existing Phase 07 helper pattern, the root `Makefile` was extended with dedicated live Python smoke targets for:

- `dev`
- `prod`
- local port-forward execution
- aggregate live test execution

##### Live verification - Running the tests against the remote cluster

~~~bash
# Run the live Python contract smoke test against the dev edge.
$ make p07-contract-guard-live-dev
RUN: Phase 07 live Python contract smoke -> https://dev-sockshop.cdco.dev/catalogue
.                                                                           [100%]
1 passed in 0.17s
OK: Phase 07 live Python contract smoke passed
~~~

An optional `prod` check can also be run explicitly, while the default live path remains focused on `dev`:

~~~bash
$ make p07-contract-guard-live-prod
RUN: Phase 07 live Python contract smoke -> https://prod-sockshop.cdco.dev/catalogue
.                                                                           [100%]
1 passed in 0.16s
OK: Phase 07 live Python contract smoke passed
~~~

A manual raw-command equivalent for the dev edge is:

~~~bash
# Run the live contract smoke test directly without the Make helper.
$ SOCKSHOP_CONTRACT_BASE_URL=https://dev-sockshop.cdco.dev \
  tests/venv/p07-python/bin/python -m pytest -q tests/python/test_contract_guard_live.py
.                                                                                 [100%]
1 passed in 0.15s  
~~~

##### Local Debugging - Run the tests against the local cluster

For local debugging, the same live smoke logic can also be executed against a local port-forward instead of the public edge.

Example local port-forward scenario:

~~~bash
# Terminal 1: Expose the catalogue service locally from the dev namespace.
$ kubectl port-forward -n sock-shop-dev svc/catalogue 18080:80
Forwarding from 127.0.0.1:18080 -> 80
Forwarding from [::1]:18080 -> 80
Handling connection for 18080

# Terminal 2: Run the same live contract smoke test against localhost.
$ make p07-contract-guard-live-local
RUN: Phase 07 live Python contract smoke -> http://127.0.0.1:18080/catalogue
.                                                                      [100%]
1 passed in 0.09s
OK: Phase 07 live Python contract smoke passed
~~~

Note: The initial local port-forward path had two independent blockers: 
- Local port `8080` was already occupied by Docker, 
- A separate VPN-related networking issue disrupted the alternative `18080` forwarding path. 
After switching to `18080` and removing the VPN interference, the local live contract smoke test passed successfully.



#### Local dev + test cycle

The Python QA flow now has clearly separated deterministic and live execution paths:

~~~bash
# Deterministic local Python contract checks
$ make p07-contract-guard-tests

# Explicit live API contract smoke check against the public dev edge
$ make p07-contract-guard-live-dev

# Optional local debugging path through a port-forward
$ make p07-contract-guard-live-local

# Aggregate live Phase 07 smoke checks
$ make p07-tests-live

# Full deterministic + live Phase 07 check set
$ make p07-tests-all
~~~

The default aggregate live path is exposed separately through:

~~~bash
$ make p07-tests-live
~~~

This preserves the Step 5 local foundation while keeping the live smoke path explicit and separately runnable.

### Expected result / success criteria

This step is successful when the following conditions are met:

- The Step 5 Python contract guard is reused unchanged against a live fetched catalogue response
- The live smoke test passes against the public `dev` catalogue endpoint
- The live smoke path remains separate from the default deterministic `p07-tests` aggregate target
- The Makefile exposes a short and explicit live Python contract-smoke command for `dev`
- An optional local port-forward execution path exists for debugging without changing test logic
- An optional `prod` execution path exists but is not the default target


 
