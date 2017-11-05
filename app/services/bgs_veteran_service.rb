require "benchmark"

class BGSVeteranService < MonitorService
  attr_accessor :last_result, :name
  @@service_name = "BGS.VeteranService"

  def initialize

    @bgs_client = init_client

    @name = @@service_name
    @service = "Veteran"
    @env = ENV['BGS_ENVIRONMENT']
    @api = "findByFileNumber"
    super
  end

  def query_service
    filenum = Rails.application.secrets.target_file_num.split(",").sample.strip
    veteran = @bgs_client.veteran.find_by_file_number(filenum)
    if !veteran[:first_nm].blank?
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
