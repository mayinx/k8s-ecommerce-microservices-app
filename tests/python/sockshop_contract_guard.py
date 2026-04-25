#!/usr/bin/env python3

################################################################################
# FILE: sockshop_contract_guard.py
#
# DESCRIPTION:
#   Small Python QA Utility for validating catalogue API payloads against a
#   minimal consumer-side compatibility schema.
#   (called from `tests/python/test_contract_guard.py`)
#
# PURPOSE:
#   This module acts as a focused compatibility guard and shared validation engine 
#   for the field subset currently treated as the functional core of the catalogue response.
#   A service can be reachable and still return structurally broken data. This guard 
#   adds a second layer beyond simple health checks:
#   - Ruby healthcheck answers: "Is the service up?"
#   - This guard answers:       "Is the returned payload still structurally usable?"
#
# USAGE:
#   Import and call:
#
#       validate_catalogue_contract(payload)
#
#   where "payload" is already parsed Python data, for example:
#
#       [
#           {"id": "sock-001", "name": "Classic Blue Sock", "price": 9.99}
#       ]
#
# RESULT:
#   - Returns True if the payload satisfies the compatibility schema
#   - Raises ValueError if one or more schema violations are found
################################################################################

from jsonschema import Draft202012Validator
from typing import Any

# Minimal consumer-side compatibility schema for catalogue responses.
# - This is not treated as the authoritative upstream API specification.
# - It is a local compatibility baseline for this project.
# - Additional upstream fields are allowed on purpose so harmless additions
#   do not break the test pipeline.
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
        "additionalProperties": True,
    },
}

# Reusable validator instance built from the schema above.
_VALIDATOR = Draft202012Validator(CATALOGUE_COMPAT_SCHEMA)

# Shared Validation Engine: Used by both local unit tests and live smoke tests.
def validate_catalogue_contract(payload: list[dict[str, Any]]) -> bool:
    """
    Validates a parsed catalogue payload against the minimum compatibility schema.
    
    Args:
        payload (object): The parsed JSON response (list of dicts).
        
    Returns:
        bool: True if the payload satisfies the Tolerant Reader contract.
        
    Raises:
        ValueError: If contract violations are found, aggregating all missing 
                    or malformed fields into a single error message.
    """
    
    # Collect all schema violations produced by the validator.
    #       
    # iter_errors yields every validation error it finds instead of stopping at the first one.
    # These errors are then sorted by their exact JSON path.  
    errors = sorted(_VALIDATOR.iter_errors(payload), key=lambda error: list(error.path))

    # If any schema violations were found, convert them into a readable Python exception.
    if errors:
        messages = []

        for error in errors:
            # Build a readable error location  
            # 
            # error.path points to the exact location of the schema violation
            # inside the payload, for example:
            #   [0, "price"]
            #
            # This is converted into a readable location string like:
            #   0 -> price            
            location = " -> ".join(str(part) for part in error.path) or "<root>"

            # Error explanation provided by jsonschema, e.g.:
            #   "'price' is a required property"
            messages.append(f"{location}: {error.message}")

        # Raise a ValueError with all collected schema problems.
        # The calling test catches this via pytest.raises(ValueError, ...).
        raise ValueError("Catalogue contract violation:\n" + "\n".join(messages))

    # No violations found
    return True