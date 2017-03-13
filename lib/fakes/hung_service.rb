class Fakes::HungService < MonitorService
  attr_accessor :last_result
  @@service_name = "Hung"

  def initialize
    @name = @@service_name
    @service = "Hung"
    @api = "blockForever"
    super
  end

  def self.service_name
    @@service_name
  end

  def query_service
    sleep 999999
    @pass = false
  end

  def self.prevalidate
    true
  end

end
