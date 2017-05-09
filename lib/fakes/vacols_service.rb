class Fakes::VacolsService < MonitorService
  attr_accessor :last_result
  @@service_name = "VACOLS"

  def initialize    
    @name = @@service_name
    @service = "VACOLS"
    @env = "dev"
    @api = "VACOLS.BRIEFF"
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
