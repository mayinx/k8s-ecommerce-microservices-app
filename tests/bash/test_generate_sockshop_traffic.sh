#!/usr/bin/env bash

################################################################################
# FILE: test_generate_sockshop_traffic.sh
#
# DESCRIPTION:
#   Lightweight dependecy free automated tests for the Bash observability helper
#   `generate-sockshop-traffic.sh`.
#
#   This test suite verifies:
#   - Characterization CLI behavior: Preserved CLI error behavior when the helper is executed directly
#   - Function-level behavior: Deterministic helper behavior and logic after the helper is sourced safely
#
# USAGE:
#   Run this test file directly from the repository root:
#   $ bash tests/bash/test_generate_sockshop_traffic.sh
#
# INSTRUCTIONAL NOTE:
#   This test file intentionally uses only plain Bash instead of an external
#   test framework. That keeps the first Bash test layer dependency-free,
#   transparent, and easy to run locally as well as later in CI.
################################################################################

SCRIPT_PATH="scripts/observability/generate-sockshop-traffic.sh"
PASS_COUNT=0
RUN_OUTPUT=""
RUN_STATUS=0

#######################################
# Prints a failure message to stderr and aborts the test run immediately.
#
# Arguments:
#   $1 - Human-readable failure message
#
# Exits:
#   1 - Exits the entire current script process 
#######################################
fail() {
  echo "FAIL: $1" >&2
  exit 1
}

#######################################
# Prints a success message and increments the internal pass counter.
#
# Arguments:
#   $1 - Human-readable success message
#######################################
pass() {
  local count=$((PASS_COUNT + 1)) 
  echo "PASS $count: $1"
  PASS_COUNT=$count
}

#######################################
# Asserts that one string contains another string.
#
# Arguments:
#   $1 - Full output / haystack
#   $2 - Expected substring / needle
#
# Exits:
#   1 (fail) if the substring is missing
#######################################
assert_contains() {
  local haystack="$1"
  local needle="$2"

  # Bash pattern matching (faster then grep) to check whether needle appears 
  # anywhere inside haystack
  # Uses glob wildcards (*) to perform a substring match.
  [[ "$haystack" == *"$needle"* ]] || fail "Expected output to contain: $needle"
}

#######################################
# Asserts that two values are exactly equal.
#
# Arguments:
#   $1 - Expected value
#   $2 - Actual value
#
# Exits:
#   1 if the two values differ
#######################################
assert_equals() {
  local expected="$1"
  local actual="$2"

  [[ "$expected" == "$actual" ]] || fail "Expected '$expected' but got '$actual'"
}

#######################################
# Executes a command, captures its combined stdout/stderr output, and stores both
# the output and exit status in shared variables for later assertions.
# Output/status is stored globals mainly because Bash function returns are limited to 
# numeric exit codes - it cannot naturally return multiple rich values like stdout + status...
#
# HOW THIS WORKS:
#   - The command is executed in a child Bash process.
#   - Output is redirected into a temporary file.
#   - The exit code is preserved separately in RUN_STATUS.
#   - The captured output is loaded into RUN_OUTPUT for later checks.
#
# Arguments:
#   $@ - Command plus arguments to execute
#
# Globals written:
#   RUN_STATUS = 0|$? (0 = success | any otehr code = fail)
#   RUN_OUTPUT 
#######################################
run_and_capture() {
  # Create a temp file and store its path in a variable
  # 'mktemp' creates a unique, empty file in /tmp and returns the path.
  # This prevents collisions if multiple scripts run simultaneously.
  local tmp_output
  tmp_output="$(mktemp)"

  # Execute the arguments passed to the function ($@) as a bash script.
  # bash "$@" ensures, that the command is executed including all provied parasm
  #   tests/bash/test_generate_sockshop_traffic.sh prod live
  # 
  # >"$tmp_output" redirects stdout to the temp file.
  # 2>&1 redirects stderr to the same temp file (capturing EVERYTHING).
  if bash "$@" >"$tmp_output" 2>&1; then
    # If the command succeeded (exit code 0), set the status var to 0.
    RUN_STATUS=0
  else
    # If it failed, capture the specific exit code ($?) for later logic.
    RUN_STATUS=$?
  fi

  # Read the contents of the temp file into the global variable RUN_OUTPUT.
  RUN_OUTPUT="$(cat "$tmp_output")"

  # Cleanup: Delete the temp file immediately to avoid cluttering /tmp.
  # -f ensures the command doesn't fail if the file was already moved.
  rm -f "$tmp_output"
}

#######################################
# TEST: Invalid environment input must be rejected with a non-zero exit code.
#
# This is a CLI-level black-box test:
# - the helper is executed directly as a script
# - the internal implementation is not touched
# - only observable behavior is checked
#######################################
test_invalid_environment_exits_nonzero() {
  run_and_capture "$SCRIPT_PATH" wrong preset

  [[ $RUN_STATUS -ne 0 ]] || fail "Expected non-zero exit status for invalid environment"
  assert_contains "$RUN_OUTPUT" "Unknown sock-shop environment"
  pass "invalid environment is rejected"
}

#######################################
# TEST: Invalid data-source mode must be rejected with a non-zero exit code.
#
# This is also a CLI-level black-box test that protects the runtime
# contract of the helper after the execution-guard refactor.
#######################################
test_invalid_data_mode_exits_nonzero() {
  run_and_capture "$SCRIPT_PATH" dev wrong

  [[ $RUN_STATUS -ne 0 ]] || fail "Expected non-zero exit status for invalid data mode"
  assert_contains "$RUN_OUTPUT" "Unknown data source mode"
  pass "invalid data mode is rejected"
}

# Run the black-box CLI checks before sourcing the helper.
# This preserves the directly executed behavior first.
test_invalid_environment_exits_nonzero
test_invalid_data_mode_exits_nonzero

# Source the helper 
# Because the runtime flow now sits behind main() plus a direct-execution guard,
# sourcing the file should expose helper functions without starting prompts or
# the long-running traffic loop.
source "$SCRIPT_PATH"

#######################################
# TEST: prepare_data_source() must call the correct loader function.
#
# TECHNIQUE:
#   The real loader functions are temporarily shadowed with small local test
#   doubles that only record which branch was taken.
#######################################
test_prepare_data_source_selects_expected_loader() {
  local called_loader=""

  # Both tenporarily overridden functions are called 
  # from within 'prepare_data_source' 
  load_live_data() {
    called_loader="live"
  }
  load_preset_data() {
    called_loader="preset"
  }

  prepare_data_source "live"
  assert_equals "live" "$called_loader"

  prepare_data_source "preset"
  assert_equals "preset" "$called_loader"

  pass "prepare_data_source selects the expected loader"
}

#######################################
# TEST: Non-parameterized endpoints must return the plain base path plus the
# placeholder dash used by the helper for display purposes.
#######################################
test_get_path_and_param_for_plain_endpoint() {
  local result

  result="$(get_path_and_param "/" "home")"
  assert_equals "/ -" "$result"

  pass "plain endpoint returns base path with dash placeholder"
}

#######################################
# TEST: The detail endpoint must append a deterministic product-id query
# parameter when the preset detail array is controlled by the test.
#
# TECHNIQUE:
#   The global detail_ids array is replaced temporarily with a single fixed
#   value so the helper output becomes deterministic and easy to assert.
#######################################
test_get_path_and_param_for_detail_endpoint() {
  local full_path
  local param

  detail_ids=("id=fixed-detail-id")

  read -r full_path param <<< "$(get_path_and_param "/detail.html" "detail")"

  assert_equals "/detail.html?id=fixed-detail-id" "$full_path"
  assert_equals "id=fixed-detail-id" "$param"

  pass "detail endpoint generates deterministic product-id query parameter"
}

#######################################
# TEST: The category endpoint must append a deterministic tag query parameter
# when the preset category array is controlled by the test.
#######################################
test_get_path_and_param_for_category_endpoint() {
  local full_path
  local param

  category_tags=("tags=fixed-tag")

  #  Get the full path and param
  #  
  #  - $(get_path_and_param ...) executes and echoes: "/path?id=123 id=123"
  #  - <<< (Here-String) feeds that string into the 'read' command's stdin.
  #  - 'read' splits the string at the first space (the default IFS delimiter).
  #  - The 1st word is assigned to $full_path, the 2nd word to $param.
  #  -r ensures backslashes in URLs are treated literally (raw mode).
  read -r full_path param <<< "$(get_path_and_param "/category.html" "category")"

  assert_equals "/category.html?tags=fixed-tag" "$full_path"
  assert_equals "tags=fixed-tag" "$param"

  pass "category endpoint generates deterministic tag query parameter"
}

# Run the function-level checks after safe sourcing.
test_prepare_data_source_selects_expected_loader
test_get_path_and_param_for_plain_endpoint
test_get_path_and_param_for_detail_endpoint
test_get_path_and_param_for_category_endpoint

# Final summary line for quick local and CI visibility.
echo "All Bash helper tests passed (${PASS_COUNT} checks)."