class Fakes::VBMSServiceFindDocumentReferenceSeries < MonitorService
  attr_accessor :last_result
  @@service_name = "VBMS.FindDocumentReferenceSeries"

  def initialize    
    @name = @@service_name
    @service = "VBMS"
    @api = "FindDocumentReferenceSeries"
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
