################################################################################
# FILE: test_catalogue_contract.py
#
# DESCRIPTION:
#   Automated unit tests for the Python contract-guard utility.
#   This suite verifies that the schema validation logic correctly enforces 
#   minimum compatibility requirements (id, name, price) using static mock 
#   payloads to ensure 100% determinism.
#
# USAGE:
#   Execute the test suite using the pytest runner:
#   $ pytest tests/python/test_catalogue_contract.py
#
# INSTRUCTIONAL NOTE:
#   This file demonstrates 'Consumer-Driven Contract' testing. By isolating 
#   the validation logic from live network state, we prove the "test engine" 
#   works perfectly before wiring it into a live cluster. The tests explicitly 
#   validate the 'Tolerant Reader' pattern—allowing extra upstream fields 
#   while guarding the 'Functional Core' of the data.
################################################################################

import pytest

from tests.python.sockshop_contract_guard import validate_catalogue_contract

def test_valid_catalogue_payload_passes_contract_guard():
    """
    Verifies the 'Tolerant Reader' pattern. 
    Ensures that non-critical upstream fields (e.g., description) do not 
    break the contract, preventing false-positive CI failures.
    """    
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
    """
    Critical Dependency Check:
    Verifies that the absence of a required field like 'name' correctly 
    triggers a ValueError to protect downstream UI rendering.
    """    
    payload = [
        {
            "id": "sock-001",
            "price": 9.99,
        }
    ]

    # Expect the following call to fail with a ValueError which contains "name"
    with pytest.raises(ValueError, match="name"):
        validate_catalogue_contract(payload)


def test_non_numeric_price_fails_contract_guard():
    """
    Type Safety Guard:
    Ensures that the 'price' field is a numerical type. This prevents 
    calculation errors in consuming services (e.g., totalizing an order).
    """    
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
    """
    Business Constraint Validation:
    Proves that the contract guard enforces value ranges, not just data types, 
    ensuring prices cannot be logically invalid (negative).
    """    
    payload = [
        {
            "id": "sock-001",
            "name": "Classic Blue Sock",
            "price": -1,
        }
    ]

    with pytest.raises(ValueError, match="price"):
        validate_catalogue_contract(payload)