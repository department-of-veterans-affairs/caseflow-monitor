class Fakes::BGSBenefitsService < MonitorService
  attr_accessor :last_result
  @@service_name = "BGS.BenefitsService"

  def initialize
    @name = @@service_name
    @service = "Benefits"
    @env = "beplinktest"
    @api = "findBenefitClaim"
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
