require 'vbms'

class VBMSServiceFindDocumentVersionReference < MonitorService
  @@service_name = "VBMS.FindDocumentVersionReference"

  def initialize
    @connection = nil

    @name = @@service_name
    @service = "VBMS"
    @api = "FindDocumentVersionReference"

    @client = VBMS::Client.from_env_vars(
      env_name: ENV["CONNECT_VBMS_ENV"],
      use_forward_proxy: ENV["CONNECT_VBMS_PROXY_BASE_URL"].present?
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
    if !@datadog_emit
      filenum = Rails.application.secrets.target_file_num.split(",").sample.strip
      request = VBMS::Requests::FindDocumentVersionReference.new(filenum)
      doc = @client.send_request(request)
      if doc.length > 0
        @pass = true
      end
    end
  end

end
