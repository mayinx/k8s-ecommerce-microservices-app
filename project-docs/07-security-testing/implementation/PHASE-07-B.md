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

~~~python
# tests/python/test_contract_guard.py

import pytest

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

Once the files are in place, the full local Python checks can be executed from repo root. To keep the local verification flow consistent with the Phase 07 Ruby ++ Bash work and to make things easier, the root `Makefile` was again extended with **several helper targets for the Python tests**: 

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

At this point, the Python layer remains intentionally local and deterministic. A later step can reuse the same contract-guard utility against a live catalogue response from a deployed environment.

### Expected result / success criteria

This step is successful when the following conditions are met:

- A small project-local Python environment exists under `tests/venv/p07-python` **and can be recreated through the dedicated Phase 07 Make target**
- The Python contract-guard module validates a **minimal, tolerant consumer-side compatibility schema** for catalogue responses
- The Python unit tests pass **locally and deterministically** without requiring live network or cluster access
- The schema is clearly framed as a **consumer-side compatibility guard**, not as a second canonical upstream API truth
- The Makefile exposes a **short, explicit, and repeatable** local verification flow for the Python layer, including:
  - **environment setup**
  - **syntax validation**
  - **contract-guard test execution**
- The full Phase 07 aggregate target `p07-tests` now includes Ruby, Bash, and Python
- The Python contract-guard utility is now in place as a **reusable QA building block** for later live API contract checks in a subsequent phase step

 