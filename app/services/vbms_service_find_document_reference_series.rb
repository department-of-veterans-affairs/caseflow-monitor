require 'vbms'

class VBMSServiceFindDocumentReferenceSeries < MonitorService
  @@service_name = "VBMS.FindDocumentSeriesReference"

  def initialize
    @connection = nil

    @name = @@service_name
    @service = "VBMS"
    @api = "FindDocumentSeriesReference"

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
    filenum = Rails.application.secrets.target_file_num.split(",").sample.strip
    request = VBMS::Requests::FindDocumentSeriesReference.new(filenum)
    doc = @client.send_request(request)
    if doc.length > 0
      @pass = true
    end
  end

end
