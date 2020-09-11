require "benchmark"

class VacolsService < MonitorService
  @@service_name = "VACOLS"


  def initialize
    @connection = nil
    @wait_time_by_class = nil
    @sys_time_model = nil
    @sum_all_db_time_24hrs = nil
    @caseflow_db_time_24hrs = nil
    @name = @@service_name
    @service = "VACOLS"
    @env = ENV['VACOLS_HOST']
    @api = "ASH"
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
      query = <<-SQL
        select user_id from DBA_USERS where username = 'DSUSER'
      SQL
      user_id_result = @connection.exec_query(query)
      dsuser_id = user_id_result[0]['user_id']

      # In the Oracle performance metric, we focus on DB Time, where
      # DB Time = DB CPU + non_idle_wait_time
      #
      # DB Time captures the total amount of time the DB is consuming, and it
      # breaks down to CPU time, and non-idle wait such as latch and lock.
      # See also: http://blog.orapub.com/20140805/what-is-oracle-db-time-db-cpu-wall-time-and-non-idle-wait-time.html


      # A continuous increment of total non-idle wait time by class. The wait class
      # provides a breakdown of where they are occurring.
      #
      query = <<-SQL
        select e.wait_class "wait_event",
          sum(h.wait_time + h.time_waited) "total_wait_time"
        from v$active_session_history h, v$event_name e
        where h.event_id = e.event_id
          and e.wait_class <> 'idle'
        group by e.wait_class
        order by 2 desc
      SQL
      @wait_time_by_class = @connection.exec_query(query)

      # Overall system time that includes DB Time, DB CPU and various metrics
      query = <<-SQL
        select stat_name, value "time"
        from v$sys_time_model
      SQL
      @sys_time_model = @connection.exec_query(query)

      # Summing DB Time from ASH table
      query = <<-SQL
        select count(*) DBTime
        from v$active_session_history
        where sample_time > sysdate - 1
          and session_type <> 'BACKGROUND'
        order by count(*) desc
      SQL
      @sum_all_db_time_24hrs = @connection.exec_query(query)

      # Summing Caseflow DB Time from ASH table
      @caseflow_db_time_24hrs = @connection.exec_query(<<-EQL)
        select count(*) DBTime
        from v$active_session_history
        where sample_time > sysdate - 1
          and session_type <> 'BACKGROUND'
          and v$active_session_history.user_id = #{dsuser_id}
        order by count(*) desc
      EQL

    rescue => e
      Rails.logger.warn(e.message)

      # If this is a connectivity issue, reset the connection pointer and
      # force the connection to be re-established in the next query.
      if should_reconnect_exception?(e)
        Rails.logger.warn("VACOLS connection dropped, reconnecting on next query")
        @connection = nil
      end

      # Propagate the exception up the stack to fail this query. This way, the
      # failure will be recorded in Prometheus / Grafana.
      raise
    end

    @pass = true
  end

  def update_datadog_metrics
    # call the parent function
    super
    # then execute the bottom for vacols specific
    update_vacols_dd_metrics_exectime = Benchmark.realtime do
      @dog.batch_metrics do
        # wait time by class
        (@wait_time_by_class || []).each do |wtceach|
          @dog.emit_point("vacols_performance", "#{wtceach['total_wait_time']}",
            :tags => ["name:#{wtceach['wait_event']}", "env:#{@env}", "source:ash"])
        end
        # sys time model
        (@sys_time_model || []).each do |stmeach|
          @dog.emit_point("vacols_performance", "#{stmeach['time']}",
            :tags => ["name:#{stmeach['stat_name']}", "env:#{@env}", "source:sys_time_model"])
        end
        # sum all db time 24 hrs
        unless @sum_all_db_time_24hrs.nil? || @sum_all_db_time_24hrs.empty?
          @dog.emit_point("vacols_performance", "#{@sum_all_db_time_24hrs.first['dbtime']}",
            :tags => ["name:sum_all_db_time_24hrs", "env:#{@env}", "source:ash"])
        end
        # caseflow db time 24 hrs (ash)
        unless @caseflow_db_time_24hrs.nil? || @caseflow_db_time_24hrs.empty?
          @dog.emit_point("vacols_performance", "#{@caseflow_db_time_24hrs.first['dbtime']}",
            :tags => ["name:caseflow_db_time_24hrs", "env:#{@env}", "source:ash"])
        end
      end
    end
    Rails.logger.info("Vacols Service DD Exec Time took: %p" % update_vacols_dd_metrics_exectime)
  end

  private

  def should_reconnect_exception?(e)
    e.cause.is_a?(OCIException) &&
      (LOST_CONNECTION_ERROR_CODES.include?(e.cause&.code) || e.message.include?("OCI8 was already closed."))
  end
end
