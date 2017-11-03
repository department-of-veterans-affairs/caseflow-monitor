require "benchmark"

class BGSAwardsService < MonitorService
  attr_accessor :last_result, :name
  @@service_name = "BGS.AwardsService"

  def initialize

    @bgs_client = init_client

    @name = @@service_name
    @service = "Awards"
    @env = ENV['BGS_ENVIRONMENT']
    @api = "findByParticipantId"
    super
  end

  def query_service
    participant_id = Rails.configuration.participant_id #Rails.application.secrets.participant_id.split(",").sample.strip
    award = @bgs_client.awards.find_by_participant_id(participant_id)
    if !award[:ptcpntVetId].blank?
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
      log: true
    )
  end
end
