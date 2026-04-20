#!/usr/bin/env ruby

################################################################################
# FILE: test_healthcheck.rb
#
# DESCRIPTION:
#   Automated unit tests for the Ruby healthcheck helper. 
#   This suite verifies argument parsing, state management, and error handling 
#   without making actual network calls or executing long delays.
#
# USAGE:
#   Run this test suite directly from the command line:
#   $ ruby test_healthcheck.rb
#
# INSTRUCTIONAL NOTE:
#   As part of this capstone project's documentation, this file includes detailed 
#   inline explanations of Ruby's metaprogramming and Minitest's stubbing mechanics. 
#   This is to explicitly demonstrate the underlying concepts of global class 
#   interception and isolated unit testing.
################################################################################

require "minitest/autorun"
require "json"
require_relative "../../healthcheck/healthcheck"

# Unit tests for the HealthChecker class.
# Uses Minitest stubs to simulate network and timing behavior.
class HealthcheckUnitTest < Minitest::Test

  # Lightweight mock object to simulate Net::HTTP responses
  #
  # The real Net::HTTP call returns an HTTPResponse object with a `.body` method. 
  # We create a simple Struct here that also has a `.body` method to mimic the real thing. 
  # The test code can access our fake JSON payload without realizing it's fake.  
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

# TEST: Verify that a successful network response is parsed and 
  # aggregated correctly by intercepting (stubbing) the HTTP call 
  # to return fake JSON.
  #
  # HOW 'STUB' WORKS IN MINITEST (Global Interception):
  # Ruby is highly dynamic, so we do not need to use Dependency Injection to mock 
  # external dependencies like network calls - Minitest can do that at runtime.
  # Minitest temporarily overrides the global `Net::HTTP` class in memory (= Class Level Stub). 
  # When the implementation of `Healthcheck#run` attempts a network call via 
  # Net::HTTP.get_response(...), Minitest intercepts it and seamlessly returns 
  # our fake payload instead of hitting the real internet.
  def test_successful_health_response_is_aggregated
    checker = HealthChecker.new(["--services", "catalogue"])

    # Simulate a valid JSON payload returned by the target service
    fake_response_payload = {
      "health" => [
        { "service" => "catalogue", "status" => "OK" },
        { "service" => "catalogue-db", "status" => "OK" }
      ]
    }

    # STUB: Intercept a method call to substitute custom behavior.
    #
    # Syntax breakdown:
    #   object.stub(:intercepted_method, replacement_behavior) do
    #     ... code to test ...
    #   end
    # 
    # Here, we intercept `get_response` to prevent a real network call and perform our assertion. 
    # While the `do...end` block runs, any call to `get_response` instantly returns our Mock Object (FakeResponse). 
    # As soon as the code in the block is finished, the "stub is cleaned up" - i.e. the temporary override of 
    # `get_response` is ended and its default behavior restored. 
    Net::HTTP.stub(:get_response, FakeResponse.new(JSON.generate(fake_response_payload))) do
      assert_equal true, checker.run
    end

    assert_equal "OK", checker.health["catalogue"]
    assert_equal "OK", checker.health["catalogue-db"]
  end

  def test_failed_request_marks_service_as_err
    checker = HealthChecker.new(["--services", "catalogue"])

    # Simulate a network exception (e.g., timeout or connection refused) by stubbing/intercepting 
    # the network call (Healthcheck#get_response) and force it to simulate a crash/timeout.
    # Here, get_response raises an error that is instantly caught by the internal 
    # implementation of Healthcheck#run to set the expected "err" status.
    Net::HTTP.stub(:get_response, proc { raise StandardError, "Connection refused" }) do
      assert_equal false, checker.run
    end

    assert_equal "err", checker.health["catalogue"]
  end

  # TEST: Verify that the delay parameter is correctly parsed and executed.
  #
  # CONCEPT: NESTED STUBS (Instance-Level + Class-Level)
  # This test utilizes two stubs:
  # - Instance-Level Stub (`checker.stub`): Intercepts the `sleep` method (which is mixed in from Ruby's Kernel).
  # - Class-Level Stub (`Net::HTTP.stub`): Intercepts the external network call.  
  def test_delay_is_used_when_configured
    checker = HealthChecker.new(["--services", "catalogue", "--delay", "5"])

    fake_response_payload = {
      "health" => [
        { "service" => "catalogue", "status" => "OK" }
      ]
    }

    sleep_calls = []
 
    # STUB 1 (Instance-Level): Intercept the `sleep` command on this specific object.
    # Instead of literally freezing the test suite for 5 seconds, we intercept the call,
    # record the amount of time it *would* have slept into our array, and instantly
    # continue execution. This keeps the test suite fast:
    checker.stub(:sleep, proc { |seconds| sleep_calls << seconds }) do

      # STUB 2 (Class-Level): Intercept the global network call.
      # Because this Stub is nested inside the first block, *both* stubs are fully active
      # when `checker.run` is finally executed.      
      Net::HTTP.stub(:get_response, FakeResponse.new(JSON.generate(fake_response_payload))) do
        checker.run
      end
    end

    # VERIFY: Assert that the Healthcheck successfully calculated and triggered the  
    # exact 5-second delay (but without the test runner actually having to wait for it).
    assert_equal [5], sleep_calls
  end
end