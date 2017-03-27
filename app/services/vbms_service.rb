require 'vbms'

class VBMSService < MonitorService
  @@service_name = "VBMS"

  def initialize
    @connection = nil

    @name = @@service_name
    @service = "VBMS"
    @api = "ListDocuments"

    @client = VBMS::Client.from_env_vars(
      env_name: ENV["CONNECT_VBMS_ENV"]
    )
    super
  end


  def self.service_name
    @@service_name
  end

  def self.prevalidate
    return ENV.key?("CONNECT_VBMS_URL")
  end

  def query_service

    request = VBMS::Requests::ListDocuments.new(Rails.application.secrets.target_file_num)
    doc = @client.send_request(request)
    if doc.length > 0
      @pass = true
    end
  end

end
