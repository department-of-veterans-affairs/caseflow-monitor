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

      latency_gauge = Prometheus::Client.registry.get(:vacols_performance)


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
      wait_time_by_class.each do |wtc|
        latency_gauge.set({
          source: 'ash',
          name: wtc['wait_event']
        }, wtc['total_wait_time'])
      end
    
      # # Overall DB Time
      query = <<-SQL
        select stat_name, value "time"
        from v$sys_time_model
      SQL
      sys_time_model = @connection.exec_query(query)
      sys_time_model.each do |stm|
        latency_gauge.set({
          source: 'sys_time_model',
          name: stm['stat_name']
        }, stm['time'])
      end


      # Overall DB Time
      query = <<-SQL
        select count(*) DBTime
        from v$active_session_history
        where sample_time > sysdate - 1
          and session_type <> 'BACKGROUND'
        order by count(*) desc
      SQL
      sum_all_db_time_24hrs = @connection.exec_query(query)
      latency_gauge.set({
        source: 'ash',
        name: 'sum_all_db_time_24hrs'
      }, sum_all_db_time_24hrs[0]['dbtime'])

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
      latency_gauge.set({
        source: 'ash',
        name: 'caseflow_db_time_24hrs'
      }, caseflow_db_time_24hrs[0]['dbtime'])

      # ratio = caseflow_db_time_24hrs[0]['dbtime'].to_f / sum_all_db_time_24hrs[0]['dbtime']
      # puts "Caseflow DB Time Ratio #{ratio*100}"

    rescue => e
      Rails.logger.warn(e.message)

      # If this is a connectivity issue, reset the connection pointer and
      # force the connection to be re-established in the next query.
      if e.original_exception.is_a?(OCIError) &&
         LOST_CONNECTION_ERROR_CODES.include?(e.original_exception.code)
        Rails.logger.warn("VACOLS connection dropped, reconnecting on next query")
        @connection = nil
      end      

      # Propagate the exception up the stack to fail this query. This way, the
      # failure will be recorded in Prometheus / Grafana.
      raise
    end

    @pass = true
  end
end
