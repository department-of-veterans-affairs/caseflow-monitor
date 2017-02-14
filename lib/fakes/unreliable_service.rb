class Fakes::UnreliableService < MonitorService
  attr_accessor :last_result
  @@service_name = "Unreliable"

  def initialize
    @name = @@service_name
    @service = "Unreliable"
    @api = "mayFailAtAnyTime"
    super
  end

  def self.service_name
    @@service_name
  end

  def query_service
    # 1/3 chance of failure
    @pass = (Random.rand(3) == 1)
  end

  def self.prevalidate
    true
  end

end
