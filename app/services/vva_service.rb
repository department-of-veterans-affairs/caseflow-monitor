require "vva"

class VVAService < MonitorService
  @@service_name = "VVA"

  def initialize

    @client = init_client

    @name = @@service_name
    @service = "DocumentList"
    @env = ENV['VVA_ENV']
    @api = "GetDocumentList"
    super
  end

  def query_service
    # All failures in the call to get_by_claim_number (invalid login credentials, file number too short)
    # should raise a VVA::SOAPError. If the call to get_by_claim_number succeeds then @pass will be true,
    # even if there are no documents.

    # Use ENV variable directly here instead of Rails.application.secrets because ERB.new() is converting input numbers
    # with leading zeroes to integers and changing their value as a result. Our current production VVA_FILE_NUM starts
    # with a zero, so VVA status checks were failing.
    # 
    # Reference: https://github.com/rails/rails/blob/5-2-stable/railties/lib/rails/secrets.rb#L29
    # Example failure: YAML.load(ERB.new("example: 012345").result) # => {"example"=>5349}
    @client.document_list.get_by_claim_number(ENV["VVA_FILE_NUM"])
    @pass = true
  end


  def self.service_name
    @@service_name
  end

  def self.prevalidate
    return ENV.key?("VVA_WSDL")
  end

  private

  def init_client
    VVA::Services.new(
      wsdl: ENV['VVA_WSDL'],
      username: ENV["VVA_USERNAME"],
      password: ENV["VVA_PASSWORD"],
      forward_proxy_url: ENV["CONNECT_VVA_PROXY_BASE_URL"]
    )
  end
end
