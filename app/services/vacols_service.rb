require "benchmark"

class VacolsServiceAsh < MonitorService
  @@service_name = "VACOLS.ASH"

  def initialize
    @connection = nil

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

  def query_service
    Rails.logger.info("ActiveRecord Base Connection #{ActiveRecord::Base.connection}")
    @connection = ActiveRecord::Base.connection

    begin

      latency_gauge = Prometheus::Client.registry.get(:vacols_performance)

      query = <<-SQL
        select user_id from DBA_USERS where username = 'DSUSER'
      SQL
      user_id_result = @connection.exec_query(query)
      Rails.logger.info("USER ID RESULT IS #{user_id_result[0]}")
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
      wait_time_by_class = @connection.exec_query(query)
      wait_time_by_class.each do |wtc|
        latency_gauge.set({
          source: 'ash',
          name: wtc['wait_event']
        }, wtc['total_wait_time'])
      end
    
      # Overall system time that includes DB Time, DB CPU and various metrics
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


      # Summing DB Time from ASH table
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

      # Summing Caseflow DB Time from ASH table
      caseflow_db_time_24hrs = @connection.exec_query(<<-EOQ)
        select count(*) DBTime
        from v$active_session_history
        where sample_time > sysdate - 1
          and session_type <> 'BACKGROUND'
          and v$active_session_history.user_id = #{dsuser_id}
        order by count(*) desc
      EOQ
      latency_gauge.set({
        source: 'ash',
        name: 'caseflow_db_time_24hrs'
      }, caseflow_db_time_24hrs[0]['dbtime'])

    rescue => e
      Rails.logger.warn(e.message)

      # Propagate the exception up the stack to fail this query. This way, the
      # failure will be recorded in Prometheus / Grafana.
      raise
    end

    @pass = true
  end
end
