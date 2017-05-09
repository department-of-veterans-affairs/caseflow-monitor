require "benchmark"

class VacolsService < MonitorService
  @@service_name = "VACOLS"

  def initialize
    @connection = nil

    @name = @@service_name
    @service = "VACOLS"
    @env = ENV['VACOLS_HOST=']
    @api = "VACOLS.BRIEFF"
    super
  end

  def self.prevalidate
    return ENV.key?("VACOLS_DATABASE")
  end


  def self.service_name
    @@service_name
  end

  def query_service
    if @connection == nil
      ActiveRecord::Base.establish_connection(:production_vacols)
      @connection = ActiveRecord::Base.connection
    end
    array = @connection.exec_query("SELECT * FROM VACOLS.BRIEFF WHERE BFKEY=TO_CHAR(#{Rails.application.secrets.target_file_num})")
    @pass = true
  end
end
