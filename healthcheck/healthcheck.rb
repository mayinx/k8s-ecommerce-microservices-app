#!/usr/bin/env ruby

# Check Health of each service
######################################

require "net/http"
require "optparse"
require "json"
require "awesome_print"

class HealthChecker
  attr_reader :options, :health

  def initialize(args)
    @options = {}
    @health = {}
    parse_options(args)
    @options[:retry] ||= 1
  end

  def parse_options(args)
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

  def services
    return [] unless @options.key?(:services)

    @options[:services].split(",")
  end

  def run
    return false unless @options.key?(:services)

    (1..@options[:retry]).each do |_i|
      if @options.key?(:delay)
        puts "\e[35mSleeping for #{@options[:delay]}s...\e[0m"
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

  def healthy?
    @health.all? { |_service, status| status == "OK" }
  end
end

if __FILE__ == $0
  $stdout.sync = true

  checker = HealthChecker.new(ARGV)

  unless checker.options.key?(:services)
    puts "\e[31mno services specified\e[0m"
    exit 1
  end

  success = checker.run
  ap checker.health

  exit(success ? 0 : 1)
end
