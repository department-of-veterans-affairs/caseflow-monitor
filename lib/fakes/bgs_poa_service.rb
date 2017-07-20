class Fakes::BGSPoaService < MonitorService
  attr_accessor :last_result
  @@service_name = "BGS.PoaService"

  def initialize
    @name = @@service_name
    @service = "Organization"
    @env = "beplinktest"
    @api = "findPOAsByFileNumbers"
    super
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
