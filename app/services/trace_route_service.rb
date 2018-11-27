gem 'dogapi'

class TraceRouteService
  attr_accessor :name

  @@service_name = "TraceRouteService"

  # This RegEx pulls out the IP address as well as the subsequent latencies (up to 3)
  REG_EX = /\((\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)\)(?:\s*(\d*\.?\d*)\s*ms)?(?:\s*(\d*\.?\d*)\s*ms)?(?:\s*(\d*\.?\d*)\s*ms)?/
  IP_MAPPING = {
    "208" => "EWIS (CRRC)",
    "209" => "EWIS (CRRC)",
    "224" => "AITC",
    "244" => "Terremark",
    "245" => "Azure East",
    "234" => "GWE hosted services",
    "237" => "GWN (or remote access)",
    "238" => "GWE (or remote access)",
    "250" => "GW(N/S/W/E) Cisco ASR interface to WLAN",
    "205" => "Philadelphia",
    "204" => "Hines, IL",
    "206" => "PITC (Philadelphia)",
    "222" => "VACO MAN/Users",
    "240" => "AWS GovCloud West 1 Transit VPC",
    "241" => "AWS GovCloud West 1 tunneling to TIC GWN",
    "242" => "AWS GovCloud West 1 tunneling to TIC GWE",
    "247" => "AWS GovCloud West 1 Spoke tenants"
  }.freeze

  def initialize
    @data_dog = Dogapi::Client.new(ENV["DD_API_KEY"])
    @name = @@service_name
  end

  def self.service_name
    @@service_name
  end

  def query
    output = `sudo traceroute -T #{ENV["VACOLS_HOST"]}`

    lines = output.split("\n")
    endpoint_latencies = lines.map do |line|
      line.scan(REG_EX)
    end.flatten(1).reduce({}) do |object, groups|
      ip = groups.first
      match_data = ip.match(/10\.(\d{1,3})/)
      second_octet = match_data ? match_data[1] : nil
      latency_values = groups[1..-1].compact

      if (object[ip])
        object[ip][:latencies].concat(latency_values)
      else
        object[ip] = {
          ip: ip,
          tag: IP_MAPPING[second_octet] || "unknown",
          latencies: latency_values
        }
      end

      object
    end

    @data_dog.batch_metrics do
      endpoint_latencies.values.each do |latency|
        latency[:latencies].each do |value|
          
          @data_dog.emit_point(
            "traceroute.#{ENV['DEPLOY_ENV']}.latency_summary",
            value,
            :tags => ["va_network_endpoint:#{latency[:tag]}", "url:#{latency[:ip]}"].compact
          )
        end
      end
    end

    true
  end

  def failed
    # We need to define a failed method, since monitor_job can call it
  end
end
