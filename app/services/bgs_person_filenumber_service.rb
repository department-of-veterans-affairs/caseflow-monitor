require "benchmark"

class BGSPersonFilenumberService < MonitorService
  attr_accessor :last_result, :name
  @@service_name = "BGS.PersonFilenumberService"

  def initialize

    @bgs_client = init_client

    @name = @@service_name
    @service = "Person"
    @env = ENV['BGS_ENVIRONMENT']
    @api = "findPersonByFileNumber"
    super
  end

  def query_service
    filenum = Rails.application.secrets.target_file_num.split(",").sample.strip
    person = @bgs_client.people.find_by_file_number(filenum)
    if !person[:first_nm].blank?
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
      forward_proxy_url: ENV["RUBY_BGS_FORWARD_PROXY_BASE_URL"],
      log: true
    )
  end
end
