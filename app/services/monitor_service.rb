gem 'dogapi'

class MonitorService

  attr_accessor :name, :polling_rate_sec, :time

  @@name = "Unamed"

  def initialize

    # Read from last result cache, and use that as base line if it exists.
    last_result = Rails.cache.read(@name)

    if last_result == nil
      @time = 0
      @latency = 0
      @latency10 = 0
      @latency60 = 0
      @count = 0
      @failed_rate_5 = 0
      @pass = false

      if @env == nil
        @env = ENV['DEPLOY_ENV']
      end
    else
      @time = last_result[:time]
      @latency = last_result[:latency] || 0
      @latency10 = last_result[:latency10] || 0
      @latency60 = last_result[:latency60] || 0
      @count = last_result[:count] || 0
      @failed_rate_5 = last_result[:failed_rate_5] || 0
      @pass = last_result[:pass]
    end

    save

    # Initialize dog so sub classes can use it as well as this parent abstract class
    dd_api_key = ENV["DD_API_KEY"]
    @dog = Dogapi::Client.new(dd_api_key)

  end

  def save
    last_result = {
      name: @name,
      env: @env,
      time: @time,
      latency: @latency,
      service: @service,
      api: @api,
      pass: @pass,
      count: @count,
      up_rate_5: (1 - @failed_rate_5) * 100,
      failed_rate_5: @failed_rate_5
    }

    if @count >= 10
      last_result[:latency10] = @latency10
    end

    if @count >= 60
      last_result[:latency60] = @latency60
    end
    Rails.cache.write(@name, last_result)
  end

  def failed
    @failed_rate_5 -= @failed_rate_5 / 5.0
    @failed_rate_5 += 1 / 5.0
    save
    self.update_datadog_metrics
  end

  def query
    @time = Time.now
    @pass = false
    @count += 1

    latency = Benchmark.realtime do
      query_service
    end

    if @pass == true
      @failed_rate_5 -= @failed_rate_5 / 5.0
      if @failed_rate_5 < 0
        @failed_rate_5 = 0
      end
    end

    if @pass == true
      @latency = latency
    else
      # force latency to be 0 so that it is obvious in prometheus where the errors were
      @latency = 0
    end

    if @count < 10
      @latency10 -= @latency10 / @count
      @latency10 += @latency / @count
    else
      @latency10 -= @latency10 / 10
      @latency10 += @latency / 10
    end

    if @count < 60
      @latency60 -= @latency60 / @count
      @latency60 += @latency / @count
    else
      @latency60 -= @latency60 / 60
      @latency60 += @latency / 60
    end

    @latency = latency

    self.update_datadog_metrics
    save
    @pass
  end

  def query_service
    # Implement the details of the query here.
    # Set @pass to true/false according to the query result.
    raise NotImplementedError.new("Implement the details of the query here")
  end

  ## Update Datadog metrics or creates them
  def update_datadog_metrics
    update_dd_metrics_exectime = Benchmark.realtime do
      @dog.batch_metrics do
        @dog.emit_point("#{@name}.#{@api}.#{@env}.latency_summary","#{@latency}",
          :tags => ["name:#{@name}", "api:#{@api}", "env:#{@env}"])
        @dog.emit_point("#{@name}.#{@api}.#{@env}.latency_gauge","#{@latency}",
          :tags => ["name:#{@name}", "api:#{@api}", "env:#{@env}"])
      end

      if @pass == true
        @dog.emit_point("#{@name}.#{@api}.#{@env}.successful_query_total","1",
          :tags => ["name:#{@name}", "api:#{@api}", "env:#{@env}"])
      else
        @dog.emit_point("#{@name}.#{@api}.#{@env}.failed_query_total","1",
          :tags => ["name:#{@name}", "api:#{@api}", "env:#{@env}"])
      end
    end
    Rails.logger.info("Latency DD Exec Time took: %p" % update_dd_metrics_exectime)
  end
end


