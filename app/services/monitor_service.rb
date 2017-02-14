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
      @failed_count = 0
      @pass = false
    else
      @time = last_result[:time]
      @latency = last_result[:latency] || 0
      @latency10 = last_result[:latency10] || 0
      @latency60 = last_result[:latency60] || 0
      @count = last_result[:count] || 0
      @failed_count = last_result[:failed_count] || 0
      @pass = last_result[:pass]
    end

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
      failed_count: @failed_count
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
    @failed_count += 1
    save
  end

  def query
    @time = Time.now
    @pass = false
    latency = Benchmark.realtime do
      query_service
    end
    @count += 1

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

    save
  end

  def query_service
    # Implement the details of the query here.
    # Set @pass to true/false according to the query result.
    raise NotImplementedError.new("Implement the details of the query here")
  end
end
