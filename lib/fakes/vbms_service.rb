class Fakes::VBMSService < MonitorService
  attr_accessor :last_result
  @@service_name = "VBMS"

  def initialize
    super
    @name = @@service_name
    @service = "VBMS"
    @api = "ListDocuments"
    save
  end

  def self.service_name
    @@service_name
  end

  def query_service
    # sleep Random.rand(5)
    @pass = true
  end

  def self.prevalidate
    true
  end

end
