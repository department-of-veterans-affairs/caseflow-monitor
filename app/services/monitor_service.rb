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
    else
      @time = last_result[:time]
      @latency = last_result[:latency] || 0
      @latency10 = last_result[:latency10] || 0
      @latency60 = last_result[:latency60] || 0
      @count = last_result[:count] || 0
      @failed_rate_5 = last_result[:failed_rate_5] || 0
      @pass = last_result[:pass]
    end
    
    initialize_prometheus_metrics

    save
  end

  def save
    last_result = {
      name: @name,
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

    self.update_prometheus_metrics
    save
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

    @latency = latency

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

    self.update_prometheus_metrics

    save

    @pass
  end

  # Remark
  # This is a hack that initialize a Counter to 0. This workaround is needed
  # because the Ruby Prometheus client does not report a Counter series if
  # it has never been updated (even if it is registered). If the series
  # does not exist, Grafana gives out warning. To workaround this, just
  # initialize all metrics to its default value (or 0).
  def initialize_prometheus_metrics
    # Tag to be used to uniquely identify this series
    tag = { 
      name: @name, 
      api: @api 
    }
    successful_query_ctr = Prometheus::Client.registry.get(:successful_query_total)
    successful_query_ctr.increment(tag, successful_query_ctr.get(tag))
    
    failed_query_ctr = Prometheus::Client.registry.get(:failed_query_total)
    failed_query_ctr.increment(tag, failed_query_ctr.get(tag))
  end


  # Summarize the performance metrics into Prometheus counters and
  # summary. 
  # This method should only be called after query is completed.
  def update_prometheus_metrics
    successful_query_ctr = Prometheus::Client.registry.get(:successful_query_total)
    failed_query_ctr = Prometheus::Client.registry.get(:failed_query_total)
    latency_summary = Prometheus::Client.registry.get(:latency_summary)
    latency_gauge = Prometheus::Client.registry.get(:latency_gauge)

    # Tag to be used to uniquely identify this series
    tag = { 
      name: @name, 
      api: @api 
    }
    
    if @pass == true
      successful_query_ctr.increment(tag)
    else 
      failed_query_ctr.increment(tag)
    end

    latency_summary.observe(tag, @latency)
    latency_gauge.set(tag, @latency)
  end

  def query_service
    # Implement the details of the query here.
    # Set @pass to true/false according to the query result.
    raise NotImplementedError.new("Implement the details of the query here")
  end
end
