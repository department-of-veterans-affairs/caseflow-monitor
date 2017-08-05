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

  # def query_service
  #   if @connection == nil
  #     ActiveRecord::Base.establish_connection(:production_vacols)
  #     @connection = ActiveRecord::Base.connection
  #   end

  #   begin
  #     filenum = Rails.application.secrets.target_file_num.split(",").first.strip
  #     array = @connection.exec_query("SELECT * FROM VACOLS.BRIEFF where BFKEY='#{filenum}'")
  #   rescue => e
  #     # If this is a connectivity issue, reset the connection pointer and
  #     # force the connection to be re-established in the next query.
  #     if e.original_exception.is_a?(OCIError) &&
  #        LOST_CONNECTION_ERROR_CODES.include?(e.original_exception.code)
  #       puts "VACOLS connection dropped, reconnecting on next query"
  #       @connection = nil
  #     end

  #     # Propagate the exception up the stack to fail this query. This way, the
  #     # failure will be recorded in Prometheus / Grafana.
  #     raise
  #   end

  #   @pass = true
  # end

  def query_service
    if @connection == nil
      ActiveRecord::Base.establish_connection(:production_vacols)
      @connection = ActiveRecord::Base.connection
    end

    begin

      # # Wait time by Class
      query = <<-SQL
        select e.wait_class "wait_event", 
          sum(h.wait_time + h.time_waited) "total_wait_time"
        from v$active_session_history h, v$event_name e
        where h.event_id = e.event_id
          and e.wait_class <> 'idle'
        group by e.wait_class
        order by 2 desc
      SQL
      wait_time_by_class = @connection.exec_query(query)
      puts wait_time_by_class
    
      # # Overall DB Time
      query = <<-SQL
        select stat_name, value "Time (Sec)"
        from v$sys_time_model
      SQL
      sys_time_model = @connection.exec_query(query)
      puts sys_time_model

      # Overall DB Time
      query = <<-SQL
        select count(*) DBTime
        from v$active_session_history
        where sample_time > sysdate - 1
          and session_type <> 'BACKGROUND'
        order by count(*) desc
      SQL
      sum_all_db_time_24hrs = @connection.exec_query(query)
      puts sum_all_db_time_24hrs[0]

      # Caseflow DB Time
      query = <<-SQL
        select count(*) DBTime
        from v$active_session_history
        where sample_time > sysdate - 1
          and session_type <> 'BACKGROUND'
          and v$active_session_history.user_id = 1971
        order by count(*) desc
      SQL
      caseflow_db_time_24hrs = @connection.exec_query(query)
      puts caseflow_db_time_24hrs[0]

      ratio = caseflow_db_time_24hrs[0]['dbtime'].to_f / sum_all_db_time_24hrs[0]['dbtime']
      puts "Caseflow DB Time Ratio #{ratio*100}"

    rescue => e
      # If this is a connectivity issue, reset the connection pointer and
      # force the connection to be re-established in the next query.
      if e.original_exception.is_a?(OCIError) &&
         LOST_CONNECTION_ERROR_CODES.include?(e.original_exception.code)
        puts "VACOLS connection dropped, reconnecting on next query"
        @connection = nil
      end

      # Propagate the exception up the stack to fail this query. This way, the
      # failure will be recorded in Prometheus / Grafana.
      raise
    end

    @pass = true
  end
end
