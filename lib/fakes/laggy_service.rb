class Fakes::LaggyService < MonitorService
  attr_accessor :last_result
  @@service_name = "Laggy"

  def initialize
    @name = @@service_name
    @service = "Laggy"
    @api = "runVerySlowly"
    super
  end

  def self.service_name
    @@service_name
  end

  def query_service
    sleep Random.rand(120)
    @pass = true
  end

  def self.prevalidate
    true
  end

end
