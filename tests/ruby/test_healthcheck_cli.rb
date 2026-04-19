# run with ruby tests/ruby/test_healthcheck_cli.rb

require "minitest/autorun"
require "open3"

class HealthcheckCliTest < Minitest::Test
  def test_exits_with_error_when_no_services_are_provided
    stdout, stderr, status = Open3.capture3("ruby", "healthcheck/healthcheck.rb")

    combined_output = "#{stdout}#{stderr}"

    refute status.success?, "Expected non-zero exit status when no services are provided"
    assert_includes combined_output, "no services specified"
  end
end


