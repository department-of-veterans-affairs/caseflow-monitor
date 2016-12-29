require "bgs"
require "benchmark"

class BGSService
  attr_accessor :last_result

  def initialize
    @bgs_client = init_client
    @last_result = { pass: false }
  end

  def query

    @last_result[:pass] = false

    latency = Benchmark.realtime do
      person = @bgs_client.people.find_by_file_number(796147498)
      if person[:first_nm] == "VERA"
        @last_result[:pass] = true
      end
    end

    @last_result[:time] = Time.now
    @last_result[:latency] = latency
    @last_result[:service] = "Person"
    @last_result[:api] = "findPersonByFileNumber"

    Rails.cache.write("bgs", @last_result)
  end

  private

  def init_client
    BGS::Services.new(
      env: Rails.application.config.bgs_environment,
      application: "CASEFLOW",
      client_ip: ENV["BGS_IP_ADDRESS"],
      client_station_id: ENV["BGS_STATION_ID"],
      client_username: ENV["BGS_USERNAME"],
      ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
      ssl_cert_file: ENV["BGS_CERT_LOCATION"],
      ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
      log: true
    )
  end
end
