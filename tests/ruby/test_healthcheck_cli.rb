#!/usr/bin/env ruby

################################################################################
# FILE: test_healthcheck_cli.rb
#
# DESCRIPTION:
#   Characterization tests for the Healthcheck CLI executable.
#   Unlike the unit tests (which mock the network), this suite tests the script 
#   from the outside-in, exactly as a user or Kubernetes probe would execute it.
#
# USAGE:
#   Run this test suite directly from the command line:
#   $ ruby tests/ruby/test_healthcheck_cli.rb
#
# INSTRUCTIONAL NOTE:
#   This file demonstrates Sub-process Testing using Ruby's `Open3` library. 
#   It verifies that the application correctly interacts with the operating 
#   system by returning appropriate POSIX exit codes and standard streams.
################################################################################

require "minitest/autorun"
require "open3"
require "json"

class HealthcheckCliTest < Minitest::Test


  # TEST: Verify that the script aborts gracefully with "no services specified" 
  # when missing required arguments ('--services')
  #
  # CONCEPT: SUB-PROCESS TESTING (Open3)
  # Instead of instantiating a Ruby class, we use `Open3.capture3` to spawn a 
  # completely separate operating system process to test Healtcheck as an 
  # actual executable CLI program. 
  # This allows us to capture exactly what users would see in their terminal 
  # (stdout/stderr) and how the script reports its success/failure to the OS 
  # (exit status).
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
    # We pass a dummy port (9999) that we know is dead.
    # We use --retry 1 to ensure the network loop actually executes once, 
    # and --delay 0 to ensure the test doesn't freeze.
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