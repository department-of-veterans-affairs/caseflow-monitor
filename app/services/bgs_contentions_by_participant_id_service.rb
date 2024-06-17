require "benchmark"

class BGSContentionsByParticipantIdService < MonitorService
  attr_accessor :last_result, :name
  @@service_name = "BGS.ContentionsByParticipantIdService"

  def initialize

    @bgs_client = init_client

    @name = @@service_name
    @service = "Contention"
    @env = ENV['BGS_ENVIRONMENT']
    @api = "findContentionByParticipantId"
    super
  end

  def query_service
    participant_id = Rails.application.secrets.participant_ids.split(",").sample.strip
    contentions = @bgs_client.contention.find_contention_by_participant_id(participant_id)
    if !contention.nil?
      @pass = true
    end
  end


  def self.service_name
    @@service_name
  end

  def self.prevalidate
    return ENV.key?("BGS_ENVIRONMENT")
  end

  private

  def init_client
    BGS::Services.new(
      env: ENV["BGS_ENVIRONMENT"],
      application: "CASEFLOW",
      client_ip: ENV["BGS_IP_ADDRESS"],
      client_station_id: ENV["BGS_STATION_ID"],
      client_username: ENV["BGS_USERNAME"],
      ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
      ssl_cert_file: ENV["BGS_CERT_LOCATION"],
      ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
      forward_proxy_url: ENV["RUBY_BGS_PROXY_BASE_URL"],
      log: true
    )
  end
end
