# Implementation — Subphase 02: Python API contract guard, live API smoke tests, and browser smoke tests with Playwright (Steps 5–7)

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

The goal of this step is to establish the **local foundation** for the Python API contract guard: 

- (1) Create a Python test environment and import structure  
- (2) Inspecting the `/catalogue`-API response schema and defining a compatibility schema  
- (3) Implementing the Python API contract-guard module
- (4) Implementing and running the local unit tests for this validation logic 

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

#### Implementing the Python API contract-guard module for schema definition and validation

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

With the API contract guard module now in place, the next step is to **verify its behavior locally through unit tests** covering both valid and incompatible catalogue payloads.

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

#### Running the local API contract-guard tests

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

At this point, the **Phase 07 test layer** validates: 
- **(1) Service health/reachability** (Ruby) 
- **(2) Helper-script behavior (Traffic Generator)** (Bash) 
- **(3) API Response-shape compatibility** (Python) 

---

## Step 6 — Live Python API contract-guard smoke test: Reuse the Python contract-guard against the live `catalogue` API

### Rationale

Step 5 established the Python **contract guard** as a **local and deterministic QA utility**. While this proves our validation logic is sound, it has only been tested locally within the safety of static, in-memory mock data.

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

#### Implementing a dedicated live Python smoke test for the `catalogue` contract

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
        # Build an explicit HTTP request with browser-like headers insetad of using the 
        # urllib from Python’s standard library. Reason: The public edge returned 
        # 'HTTP 403 Forbidden' when the default urllib request profile was used.
        request = Request(
            catalogue_url,
            headers={
                "User-Agent": "Mozilla/5.0",
                "Accept": "application/json",
            },
        )

        with urlopen(request, timeout=10) as response:
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

#### Running the live contract-guard smoke test

Once the live test file is in place, the live Python contract smoke test can be executed from repo root against the configured target path. To keep the live verification flow consistent with the existing Phase 07 helper pattern, the root `Makefile` was extended with several helper targets for the Python catalogue contract tests: 

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

For local debugging, the same contract smoke test can also be executed against the local cluster using port-forward:

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

> [!NOTE] **🧭 Local port-forward debugging**
>
> The initial local live smoke path (via port `8080`) had two independent blockers and required practical adjustments:
>
> - local port `8080` was already occupied by Docker and therefore replaced with `18080`
> - A separate VPN-related networking issue interfered with the alternative `18080` forwarding path  
>
> After switching to `18080` and removing the VPN interference, the local live contract smoke test passed successfully.

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

### Result

Step 6 successfully moved the Python contract guard from a **local deterministic validation utility** into a **live contract smoke check** against deployed `/catalogue` endpoints.

The successful end state is shown by these signals / verification points:

- The Step 5 Python contract guard is now reused unchanged against a **live fetched catalogue response**
- The live Python contract smoke test passed **against the public `dev` and `prod` `/catalogue` endpoints**
- The Makefile now exposes short and explicit live helper targets for:
  - **`dev` edge execution**
  - **`prod` edge execution**
  - **local port-forward execution**
- The live Python smoke check now uses an **explicit HTTP request with browser-like headers**, after the public edge returned **`403 Forbidden`** for the default `urllib` request profile
- The optional local port-forward path also passed successfully once the two practical blockers were removed:
  - local port `8080` was already occupied by Docker and therefore replaced with `18080`
  - a separate VPN-related networking issue interfered with `kubectl port-forward` until that path was removed
- The **Python test layer** now spans **two clearly separated scopes**:
  - **Step 5:** local deterministic unit tests of the contract-guard logic
  - **Step 6:** live integration / smoke validation of that same logic against a deployed endpoint

At this point, the Python contract guard is no longer limited to local contract checks. It is now also used for **live catalogue-response validation**, while the separation between deterministic local tests and environment-dependent smoke checks remains intact.
---

## Step 7 — Establishing a minimal Playwright browser smoke test layer for the live storefront

### Rationale

Phase 07 now already covers several important validation layers:

- **Service health / reachability** through the Ruby healthcheck
- **Observability-helper behavior** through the Bash observability-helper tests
- **API response-shape compatibility** through the Python API contract guard

What is still missing is a **real browser-based smoke test proof** for the deployed storefront.

The next useful addition is therefore a **minimal Playwright smoke layer** against the live `dev` edge.

The scope remains intentionally narrow:

- **One browser only** (`chromium`)
- **One very small browser suite**
- **One deployed target path**
- **No full purchase journey**
- **No broad UI regression coverage**

This keeps the E2E layer realistic for the remaining time while still adding an important missing proof:

- The storefront can be opened in a real browser
- Key landing-page content renders
- At least one catalogue image is visible on the page

At the same time, this browser smoke layer remains **environment-dependent** and therefore belongs to the explicit **live** Phase 07 path.

> [!NOTE] 🎭 **Playwright**
>
> **Playwright** is a modern, cross-browser automation framework. Unlike simple API tests that only check data, Playwright spins up a real instance of a browser (like Chromium) to interact with the website exactly as a human would.
>
> In this step, it is used as a browser-level smoke validator for the live storefront: confirming that the deployed page opens and renders key visible content for the user.

> [!NOTE] 🧪 **E2E Tests**
>
> **End-to-End (E2E) testing** validates the entire software system from start to finish, including its integration with external interfaces. 
> 
> While **Unit Tests** check a single function and **Contract Tests** check the API data, **E2E Tests** verify the "Last Mile": confirming that the user can actually interact with the deployed application in a real browser. In this step, only a small initial Brwoser smoke test is implemented that functions as baseline for more complex E2E tests.

### Action

#### Extending `.gitignore` for Playwright artifacts

The earlier Phase 07 `.gitignore` additions covered generic test folders under `tests/`, but the Playwright setup in this step introduces nested Node.js and browser-test artifacts under `tests/e2e/`.

To avoid committing generated files, `.gitignore` needs tro be extended with:

~~~gitignore
# Phase 07 E2E / Playwright artifacts
tests/e2e/node_modules/
tests/e2e/playwright-report/
tests/e2e/test-results/
~~~

#### Implementing a local Playwright environment

To keep the browser smoke test tooling isolated from the repository root, a small Node/Playwright setup is placed under:

- `tests/e2e/` 

This keeps Phase-07-specific Node/Playwright files and generated dependencies (`node_modules`) out of the repository root.

##### Defining the local Playwright project

The local package definition is placed in:

- `tests/e2e/package.json`

~~~json
{
  "name": "p07-e2e-smoke",
  "private": true,
  "devDependencies": {
    "@playwright/test": "^1.55.0"
  },
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:report": "playwright show-report"
  }
}
~~~

##### Installing the local Playwright toolchain

The corresponding local setup commands below use the standard Node.js toolchain required by Playwright: 
- **`npm`** (Node Package Manager) installs the Playwright test runner and its dependencies into the local `tests/e2e/node_modules` folder, 
- **`npx`** (Node Package eXecute) is the command runner that executes the local `playwright` binary directly from this project-local installation without requiring a global Playwright install or changes to the system `PATH`.

~~~bash
# Install the local Playwright test runner inside tests/e2e.
$ cd tests/e2e
$ npm install

# Install only Chromium to keep the first browser smoke layer lean.
$ npx playwright install chromium
~~~

#### Implementing the Playwright configuration

The Playwright configuration is placed in `tests/e2e/playwright.config.js` and defines the execution defaults for the browser tests, including target URL handling, reporting, failure artifacts, and CI-aware runtime behavior:

- 1 browser project (`chromium`)
- Configurable base URL through `BASE_URL`
- HTML report generation
- Screenshot capture only on failure
- Trace capture on the first retry
- Extended assertion timeout for live-environment rendering delays
- CI-aware execution defaults for `forbidOnly`, `workers`, and `retries`

~~~js
// tests/e2e/playwright.config.js

const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: '.',

  // A larger assertion timeout helps with live environment rendering delays
  expect: {
    timeout: 10000,
  },

  use: {
    // Base URL to use in actions like `await page.goto('/')`.
    baseURL: process.env.BASE_URL || 'https://dev-sockshop.cdco.dev',

    // Run headless (without browser gui, mandatory for CI) 
    headless: true,

    // Minimize storage overhead by only saving artifacts on failure
    //
    // Save a screenshot only when a test fails.
    screenshot: 'only-on-failure',
    //
    // Capture a trace (recorded debug package/artifact) on the first retry 
    // to aid debugging when retries are enabled.
    trace: 'on-first-retry',
  },

  // Fail the build on CI if you accidentally left 'test.only' in the source code.
  // (to prevent committing debug code (test.only) to the main branch)
  forbidOnly: !!process.env.CI,

  // Keep execution serial (1 worker) to ensure stability in resource-constrained CI runners
  //
  // Do not run tests in parallel.
  fullyParallel: false,
  //
  // Opt out of parallel tests on CI.
  workers: process.env.CI ? 1 : undefined,

  // Retry on CI only (to filter out temporary network errors/blibs). 
  retries: process.env.CI ? 1 : 0,

  // Show readable live console output and also generate an HTML report artifact for later inspection
  reporter: [     
    ['list'], // show live console output 
    ['html', { open: 'never' }], // HTML report is saved as an artifact, but not auto-opened (CI-friendly)
  ],

  // Browser config.
  projects: [
    {
      name: 'chromium',
      use: {
        // For now (smoke check): Limit to one browser for speed and consistency.
        browserName: 'chromium',
      },
    },
  ],
});
~~~

> [!NOTE] **🧩 CI-aware Playwright execution**
>
> The Playwright config reads the `CI` environment variable (see `process.env.CI`) to switch specific execution defaults automatically.
>
> In GitHub Actions, `CI` is set automatically by the runner. In the local Phase 07 Make targets, this variable is also forwarded explicitly into the Playwright execution context, so the same config can adapt cleanly between local runs and CI runs without changing the test file itself.

#### Implementing the Playwright smoke test

The first Playwright test file is placed in `tests/e2e/smoke.spec.js` and keeps the browser assertions deliberately small and focused on meaningful smoke checks:

- The storefront root loads successfully
- Key landing-page content is visible
- At least one catalogue image is rendered on the page

The goal of this step is a **browser smoke proof**, not a full end-to-end business-flow suite. The chosen assertions therefore focus on quick and stable checks instead of testing longer, more fragile click paths:

~~~js
// tests/e2e/smoke.spec.js

const { test, expect } = require('@playwright/test');

test('storefront root loads and key landing content is visible', async ({ page }) => {
  // Navigate to the configured base URL 
  // 'domcontentloaded' is used for speed, as we only need the initial 
  // HTML/DOM structure to begin our smoke checks.
  const response = await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Ensure the server actually responded with a success code (200-299).
  expect(response && response.ok()).toBeTruthy();

  // Verify key landing-page content that should remain visible on a healthy storefront.
  await expect(page).toHaveTitle(/WeaveSocks/i);
  await expect(page.getByText('We love socks!')).toBeVisible();
  await expect(page.getByText('Hot this week')).toBeVisible();
});

test('storefront renders at least one catalogue image', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Verify that at least one catalogue image is rendered in the storefront.
  // This keeps the smoke check stable without depending on one exact product entry.
  const productImages = page.locator('img[src*="/catalogue/images/"]');

  await expect(productImages.first()).toBeVisible();
});
~~~

This provides a small browser-smoke baseline that can later be extended into fuller end-to-end tests with longer user flows, deeper interaction checks, and additional browser coverage.

#### Running the Playwright browser smoke test

Once the files (and additional Make targets for the E2E tests) are in place, the browser smoke tests can be executed from repo root:

~~~bash
# Run the Playwright smoke test against the dev edge.
$ make p07-e2e-smoke-dev
OK: Node.js tooling detected for Phase 07 Playwright smoke tests
RUN: Phase 07 Playwright setup -> tests/e2e
OK: Phase 07 Playwright environment ready -> tests/e2e
RUN: Phase 07 Playwright smoke -> https://dev-sockshop.cdco.dev (CI: false)
Running 2 tests using 1 worker
  ✓  1 [chromium] › smoke.spec.js:5:1 › storefront root loads and key landing content is visible (1.0s)
  ✓  2 [chromium] › smoke.spec.js:18:1 › storefront renders at least one catalogue image (1.6s)
  2 passed (3.9s)
To open last HTML report run:
  npx playwright show-report
OK: Phase 07 Playwright smoke passed
~~~

The underlying raw commands executed by that target are:

~~~bash
# Install the local Playwright dependencies.
$ cd tests/e2e
$ npm install

# Install only the Chromium browser.
$ npx playwright install chromium

# Run the smoke test against the dev edge.
$ BASE_URL=https://dev-sockshop.cdco.dev npx playwright test smoke.spec.js --project=chromium
~~~

For interactive local debugging, the same smoke test can also be executed in a visible browser window:

~~~bash
# Run the same smoke file in headed mode for debugging.
$ cd tests/e2e
$ BASE_URL=https://dev-sockshop.cdco.dev npx playwright test smoke.spec.js --project=chromium --headed
~~~

If the smoke test fails, the HTML report can be opened through:

~~~bash
$ make p07-e2e-report
Serving HTML report at http://localhost:9323. Press Ctrl+C to quit.
~~~

#### Local dev + test cycle

The live/browser-side Phase 07 loop now becomes (here shown with full output as Phase 07 Testing Evidence):

~~~bash
# Explicit Playwright browser smoke check
$ make p07-e2e-smoke-dev

# Explicit live Phase 07 smoke path
$ make p07-tests-live
RUN: Phase 07 live Python contract smoke -> https://dev-sockshop.cdco.dev/catalogue
.                                                               [100%]
1 passed in 0.19s
OK: Phase 07 live Python contract smoke passed
OK: Node.js tooling detected for Phase 07 Playwright smoke tests
RUN: Phase 07 Playwright setup -> tests/e2e
OK: Phase 07 Playwright environment ready -> tests/e2e
RUN: Phase 07 Playwright smoke -> https://dev-sockshop.cdco.dev  (CI: false)
Running 2 tests using 1 worker
  ✓  1 [chromium] › smoke.spec.js:5:1 › storefront root loads and key landing content is visible (578ms)
  ✓  2 [chromium] › smoke.spec.js:18:1 › storefront renders at least one catalogue image (954ms)
  2 passed (2.5s)
To open last HTML report run:
  npx playwright show-report
OK: Phase 07 Playwright smoke passed

# Full deterministic + live Phase 07 path
$ make p07-tests-all
OK: Ruby syntax valid -> healthcheck/healthcheck.rb
ruby tests/ruby/test_healthcheck_cli.rb
Run options: --seed 15026
# Running:
..
Finished in 0.195218s, 10.2449 runs/s, 25.6124 assertions/s.
2 runs, 5 assertions, 0 failures, 0 errors, 0 skips
ruby tests/ruby/test_healthcheck.rb
Run options: --seed 10388
# Running:
....Sleeping for 5s...
...
Finished in 0.009026s, 775.4963 runs/s, 1440.2074 assertions/s.
7 runs, 13 assertions, 0 failures, 0 errors, 0 skips
OK: Bash syntax valid -> scripts/observability/generate-sockshop-traffic.sh
OK: Bash syntax valid -> tests/bash/test_generate_sockshop_traffic.sh
bash tests/bash/test_generate_sockshop_traffic.sh
PASS 1: invalid environment is rejected
PASS 2: invalid data mode is rejected
PASS 3: prepare_data_source selects the expected loader
PASS 4: plain endpoint returns base path with dash placeholder
PASS 5: detail endpoint generates deterministic product-id query parameter
PASS 6: category endpoint generates deterministic tag query parameter
All Bash helper tests passed (6 checks).
OK: Phase 07 Python environment ready -> tests/venv/p07-python
OK: Python syntax valid -> tests/python/sockshop_contract_guard.py, tests/python/test_contract_guard.py
RUN: Phase 07 Python contract-guard tests -> tests/python/test_contract_guard.py
....                                                                         [100%]
4 passed in 0.05s
OK: Phase 07 Python contract-guard tests passed
RUN: Phase 07 live Python contract smoke -> https://dev-sockshop.cdco.dev/catalogue
.                                                                            [100%]
1 passed in 0.14s
OK: Phase 07 live Python contract smoke passed
OK: Node.js tooling detected for Phase 07 Playwright smoke tests
RUN: Phase 07 Playwright setup -> tests/e2e
OK: Phase 07 Playwright environment ready -> tests/e2e
RUN: Phase 07 Playwright smoke -> https://dev-sockshop.cdco.dev  (CI: false)
Running 2 tests using 1 worker
  ✓  1 [chromium] › smoke.spec.js:5:1 › storefront root loads and key landing content is visible (519ms)
  ✓  2 [chromium] › smoke.spec.js:18:1 › storefront renders at least one catalogue image (948ms)
  2 passed (2.4s)
To open last HTML report run:
  npx playwright show-report
OK: Phase 07 Playwright smoke passed
~~~

#### CI readiness of the Playwright Make targets

The Playwright Make targets are structured so they can later be reused in CI execution:

- **Controlled output:** The targets print short `RUN` / `OK` / `FAIL` status lines instead of noisy recursive Make output
- **Proper failure behavior:** The Make targets propagate non-zero exit codes from failed setup, validation, or test commands instead of hiding those failures
- **CI-aware execution context:** The current `CI` state is passed into the Playwright run so the same config can adapt automatically between local execution and CI runners

This makes the Playwright smoke path suitable both for local reruns and for later workflow integration.

### Result

Step 7 established the first **browser-based smoke test layer** of Phase 07 through **Playwright** against the live `dev` storefront.

The successful end state is shown by these signals / verification points:

- A baseline **Playwright environment** now exists under `tests/e2e`
- The **E2E tooling** in `tests/e2e` (`package.json`, `playwright.config.js`, `node_modules`) is isolated from the repository root  
- The first Playwright suite remains intentionally **small (smoke)** and **Chromium-only**
- The automated browser smoke test verifies verfies **against the live `dev` storefront**: 
    - Successfull storefront loading in a real browser session
    - Successfull rendering of key landing-page content 
    - Visibility of at least one catalogue image
- The **Makefile** now exposes short helper targets for:
  - Playwright setup
  - Dev-edge smoke test execution
  - Optional prod-edge smoke test execution
  - HTML report viewing
- The **Playwright smoke test layer** is integrated into the Make helper target **`p07-tests-live`** (the deterministic **default `p07-tests` loop** remains unchanged)
- The Playwright config and Make targets are now **CI-ready**, including:
  - **CI-aware execution configs** in `playwright.config.js`
  - **Explicit `CI` forwarding** in the Make targets
  - **Controlled status output** and **proper exit-code behavior** for later workflow reuse  

This provides a **browser smoke test baseline** that can later be extended into fuller end-to-end tests with longer user flows, deeper interaction checks, additional browser coverage, and direct CI execution.

At this point, the **Phase 07 test layer** validates: 
- **(1) Service health/reachability** (Ruby) 
- **(2) Helper-script behavior (Traffic Generator)** (Bash) 
- **(3) API Response-shape compatibility** (Python) 
- **(4) Storefront rendering in a real browser** (Playwright / JavaScript)

---





