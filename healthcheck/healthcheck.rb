#!/usr/bin/env ruby

# TODO:
# - we make optiosn and health publicly available via attr_reader and services as getetr methgoid so that the unit trest scripts can access those 
# - we provide class based object initialization that accepts passed along args - whcih is gerat fo runit tests as well because ... we can cerate difefrent test scenarios with difefrent preconfiitons based on differnt args 

# Check Health of each service
######################################

#!/usr/bin/env ruby

################################################################################
# FILE: healthcheck.rb
#
# DESCRIPTION:
#   A modular healthcheck utility for Kubernetes services. 
#   Refactored to support both operational CLI execution and automated 
#   framework-driven unit testing.
#
# USAGE:
#   Direct CLI usage:
#     $ ruby healthcheck.rb --services catalogue,user --retry 3 --delay 5
#
#   View all available options:
#     $ ruby healthcheck.rb --help
#
# INSTRUCTIONAL NOTE:
#   This script demonstrates the "Testable Tool" pattern. By encapsulating logic 
#   within a class and protecting top-level execution with a '$0' guard, the 
#   code becomes importable for unit testing without triggering side effects. 
#   Additionally, it follows UNIX best practices by separating machine-readable 
#   data (stdout) from human-readable logs (stderr).

# INSTRUCTIONAL NOTE:
#   This script follows two core engineering principles:
#   1. Modular Structure: Uses an Execution Guard (__FILE__ == $0) to separate 
#      logic from execution, enabling isolated unit testing.
#   2. Standard Streams: Separates data (stdout) from logs (stderr) to ensure 
#      the output is "composable" and can be parsed by automation tools (like jq).

 
#   2. Observability: Informational logs are sent to 'stderr' to keep 'stdout' 
#      reserved for pure, machine-readable JSON payloads.
#   3. Pipeline Readiness: This separation allows tools like 'jq' or GitHub 
#      Actions steps to parse the health data directly from stdout without 
#      crashing on human-readable status messages.

# This script was refactored to ensure reliability, testability and automation-readiness:
#
#   1. Modular Structure & Testability: Logic is encapsulated in a class accompanied 
#      by an Execution Guard ('__FILE__ == $0'), allowing safe import into unit test suites
#      without triggering a live run or uncontrolled process exit.
#
#   2. Observability & Standard Streams: Data (stdout) is separated from logs (stderr) 
#      to ensure stdout remains a pure, machine-readable JSON payload that can be parsed 
#      by automation tools (like jq).
#
#   3. Pipeline Readiness: This separation ensures that downstream automation 
#      tools (like 'jq' or GitHub Actions steps) can parse the health data 
#      directly from stdout without crashing on human-readable status messages.
#      This enables data-driven conditional step execution and seamless communication 
#      between different pipeline stages.
################################################################################

require "net/http"
require "optparse"
require "json"

class HealthChecker  
  # TESTABILITY: Internal state is exposed via attr_reader so that unit tests
  # can verify the final 'health' and 'options' hashes without parsing stdout.
  attr_reader :options, :health

  # TESTABILITY: Accepting 'args' as a parameter instead of reading ARGV directly 
  # allows tests to instantiate different scenarios (retries, delays, etc.) 
  # within the same test run.  
  def initialize(args)
    @options = {}
    @health = {}
    parse_options(args)
    @options[:retry] ||= 1
  end

  def parse_options(args)
    # OptionParser acts as a 'translator', converting raw CLI strings (like -r 3) 
    # into a clean Ruby Hash. It also automatically generates the --help menu.
    OptionParser.new do |opts|
      opts.banner = "Usage healthcheck.rb -h [host] -t [timeout] -r [retry]"

      opts.on("-h", "--hostname HOSTNAME", "Specify hostname") do |v|
        @options[:hostname] = v
      end

      opts.on("-t", "--timeout SECONDS", OptionParser::DecimalInteger, "Specify timeout in seconds") do |v|
        @options[:timeout] = v
      end

      opts.on("-r", "--retry N", OptionParser::DecimalInteger, "Specify number of retries") do |v|
        @options[:retry] = v
      end

      opts.on("-d", "--delay SECONDS", OptionParser::DecimalInteger, "Specify seconds to delay") do |v|
        @options[:delay] = v
      end

      opts.on("-s", "--services X,Y", "Specify services to check") do |v|
        @options[:services] = v
      end
    end.parse!(args)
  end

  # Encapsulates service list logic; provides a clean array for iteration.
  # Also useful as test interface
  def services
    return [] unless @options.key?(:services)

    @options[:services].split(",")
  end

  def run
    return false unless @options.key?(:services)

    (1..@options[:retry]).each do |_i|
      if @options.key?(:delay)
        # Informational logs are sent to 'warn' (stderr) so they don't pollute 
        # the machine-readable JSON data in stdout.
        # (instead of using `puts` like in the original implementation)
        warn "Sleeping for #{@options[:delay]}s..."
        sleep @options[:delay]
      end

      services.each do |service|
        begin
          url = service
          if @options.key?(:hostname)
            url = "#{@options[:hostname]}/#{url}"
          end

          resp = Net::HTTP.get_response(url, "/health")
          json = JSON.parse(resp.body)["health"]

          json.each do |item|
            @health[item["service"]] = item["status"]
          end
        rescue
          @health[service] = "err"
        end
      end

      break if healthy?
    end

    healthy?
  end

  # HARDENING: We verify that @health is not empty to avoid a 'vacuous truth' 
  # (where .all? returns true even on an empty collection). This ensures the 
  # script only reports success if it actually checked at least one service.
  def healthy?    
    !@health.empty? && @health.all? { |_service, status| status == "OK" }
  end
end

# EXECUTION GUARD: This block only runs if the script is called directly ($0).
#
# Prevents the script from running when it is imported/`required` as a library 
# for testing, avoiding immediate execution and process exit. 
if __FILE__ == $0
  # Disable output buffering ($stdout.sync = true) to ensure logs are flushed 
  # immediately. This is critical for real-time observability in CI/CD pipelines.  
  $stdout.sync = true

  checker = HealthChecker.new(ARGV)

  unless checker.options.key?(:services)
    # Moved to 'warn' (stderr) to avoid polluting stdout 
    warn "no services specified"
    exit 1
  end

  success = checker.run

  # MACHINE READABILITY: Output valid JSON to stdout for pipeline consumption.
  # (instead of using awesome_print: `ap checker.health`)
  puts JSON.pretty_generate(checker.health)

  exit(success ? 0 : 1)
end
