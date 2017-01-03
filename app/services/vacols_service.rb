require "benchmark"

class VacolsService < MonitorService
  def initialize
    super
    @connection = nil

    @name = "VACOLS"
    @service = "VACOLS"
    @api = "VACOLS.BRIEFF"
    save
  end

  def self.prevalidate
    return ENV.key?("VACOLS_DATABASE")
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
