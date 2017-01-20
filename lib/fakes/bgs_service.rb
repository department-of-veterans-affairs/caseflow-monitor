class Fakes::BGSService < MonitorService
  attr_accessor :last_result
  @@service_name = "Fake BGS"

  def initialize
    super
    @name = @@service_name
    @service = "Person"
    @api = "findPersonByFileNumber"
    save
  end

  def self.service_name
    @@service_name
  end

  def query_service
    sleep Random.rand(5)
    @pass = true
  end

  def self.prevalidate
    true
  end

end
