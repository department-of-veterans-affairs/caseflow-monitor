class Fakes::AlwaysDownService < MonitorService
  attr_accessor :last_result
  @@service_name = "AlwaysDown"

  def initialize
    @name = @@service_name
    @service = "AlwaysDown"
    @api = "alwaysFail"
    super
  end

  def self.service_name
    @@service_name
  end

  def query_service
    @pass = false
  end

  def self.prevalidate
    true
  end

end
