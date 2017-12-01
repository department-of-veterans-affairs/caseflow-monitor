class Fakes::VBMSServiceFindDocumentVersionReference < MonitorService
  attr_accessor :last_result
  @@service_name = "VBMS.FindDocumentVersionReference"

  def initialize
    @name = @@service_name
    @service = "VBMS"
    @api = "FindDocumentVersionReference"
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
