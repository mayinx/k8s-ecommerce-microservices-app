require "minitest/autorun"
require "json"
require "stringio"
require_relative "../../healthcheck/healthcheck"

class HealthcheckUnitTest < Minitest::Test
  FakeResponse = Struct.new(:body)

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

  def test_successful_health_response_is_aggregated
    checker = HealthChecker.new(["--services", "catalogue"])

    fake_payload = {
      "health" => [
        { "service" => "catalogue", "status" => "OK" },
        { "service" => "catalogue-db", "status" => "OK" }
      ]
    }

    Net::HTTP.stub(:get_response, FakeResponse.new(JSON.generate(fake_payload))) do
      assert_equal true, checker.run
    end

    assert_equal "OK", checker.health["catalogue"]
    assert_equal "OK", checker.health["catalogue-db"]
  end

  def test_failed_request_marks_service_as_err
    checker = HealthChecker.new(["--services", "catalogue"])

    Net::HTTP.stub(:get_response, proc { raise StandardError, "boom" }) do
      assert_equal false, checker.run
    end

    assert_equal "err", checker.health["catalogue"]
  end

  def test_delay_is_used_when_configured
    checker = HealthChecker.new(["--services", "catalogue", "--delay", "5"])

    fake_payload = {
      "health" => [
        { "service" => "catalogue", "status" => "OK" }
      ]
    }

    sleep_calls = []

    checker.stub(:sleep, proc { |seconds| sleep_calls << seconds }) do
      Net::HTTP.stub(:get_response, FakeResponse.new(JSON.generate(fake_payload))) do
        checker.run
      end
    end

    assert_equal [5], sleep_calls
  end
end
