require "benchmark"

class VacolsService < MonitorService
  @@service_name = "VACOLS"

  def initialize
    @connection = nil

    @name = @@service_name
    @service = "VACOLS"
    @env = ENV['VACOLS_HOST']
    @api = "VACOLS.BRIEFF"
    super
  end

  def self.prevalidate
    return ENV.key?("VACOLS_DATABASE")
  end


  def self.service_name
    @@service_name
  end

  # A list of OCI error code that determines Oracle connectivity issues.
  # ORA-00028: your session has been killed
  # ORA-01012: not logged on
  # ORA-03113: end-of-file on communication channel
  # ORA-03114: not connected to ORACLE
  # ORA-03135: connection lost contact
  # See # From https://github.com/rsim/oracle-enhanced/blob/d990f945de4d972833487b1b3364a5d013549c7f/lib/active_record/connection_adapters/oracle_enhanced/oci_connection.rb#L420
  LOST_CONNECTION_ERROR_CODES = [ 28, 1012, 3113, 3114, 3135 ] #:nodoc:

  def query_service
    if @connection == nil
      ActiveRecord::Base.establish_connection(:production_vacols)
      @connection = ActiveRecord::Base.connection
    end

    begin
      array = @connection.exec_query(
        "SELECT * FROM VACOLS.BRIEFF WHERE BFKEY=TO_CHAR(#{Rails.application.secrets.target_file_num})")
    rescue => e
      # If this is a connectivity issue, reset the connection pointer and
      # force the connection to be re-established in the next query.
      if e.original_exception.is_a?(OCIError) && 
        LOST_CONNECTION_ERROR_CODES.include?(e.original_exception.code)
        puts "VACOLS connection dropped, reconnecting on next query"
        @connection = nil
      end
      raise
    end

    @pass = true
  end
end
