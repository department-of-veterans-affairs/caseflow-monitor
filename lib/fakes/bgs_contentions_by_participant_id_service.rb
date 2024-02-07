class Fakes::BGSContentionsByParticipantIdService < MonitorService
    attr_accessor :last_result
    @@service_name = "BGS.ContentionsByParticipantIdService"
  
    def initialize
      @name = @@service_name
      @service = "Contention"
      @env = "beplinktest"
      @api = "findContentionByParticipantId"
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
  