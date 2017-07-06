class Fakes::VVAService < MonitorService
  attr_accessor :last_result
  @@service_name = "VVA"

  def initialize
    @name = @@service_name
    @service = "DocumentList"
    @env = "dev"
    @api = "GetDocumentList"
    super
  end

  def self.service_name
    @@service_name
  end

  def query_service
    @pass = true
  end

  def self.prevalidate
    true
  end
end
