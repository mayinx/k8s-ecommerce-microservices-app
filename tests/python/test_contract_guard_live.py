#!/usr/bin/env python3

################################################################################
# FILE: test_contract_guard_live.py
#
# DESCRIPTION:
#   Live Python smoke test for the catalogue API.
#   Fetches a live catalogue payload from a configurable base URL and reuses
#   the Pahse07/Step05 contract guard to validate structural compatibility.
#
# PURPOSE:
#   This test promotes the already proven Step 5 contract logic from local
#   in-memory validation into a live environment smoke check ready for CI integration
#
# CONFIGURATION:
#   The target base URL is injected through the environment variable:
#   - SOCKSHOP_CONTRACT_BASE_URL
#
#   Default:
#   - https://dev-sockshop.cdco.dev
#
# RESULT:
#   - Fails if the live endpoint is unreachable
#   - Fails if the live response is not valid JSON
#   - Fails if the live JSON violates the Step 5 compatibility schema
#   - Passes only if the live response remains structurally compatible
################################################################################

import json
import os
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

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
        # Build an explicit HTTP request instead of relying on urllib defaults.
        # Some public edges are stricter with default Python request profiles.
        request = Request(
            catalogue_url,
            headers={
                "User-Agent": "Mozilla/5.0",
                "Accept": "application/json",
            },
        )

        # timeout=10 prevents the test from hanging indefinitely on broken network paths.
        with urlopen(request, timeout=10) as response:
            # The request must succeed at the HTTP layer before contract validation begins.
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
        
    else:
        # Reuse the already proven Step 5 contract guard - now to evaluate a live payload instead
        # This block only runs if the try block succeeds/no exception was raised, guaranteeing 'payload' exists 
        # (to keep Pylance happy)     
        assert validate_catalogue_contract(payload) is True