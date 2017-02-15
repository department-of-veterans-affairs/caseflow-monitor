class MonitorService

  attr_accessor :name, :polling_rate_sec, :time

  @@name = "Unamed"
  def initialize
    @time = 0
    @latency = 0
    @latency10 = 0
    @latency60 = 0
    @count = 0
    @service = "service"
    @api = "api"
    @pass = false
    @polling_rate_sec = 300

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

  def query
    @time = Time.now
    @pass = false
    latency = Benchmark.realtime do
      query_service
    end
    @count += 1

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

    save
  end

  def query_service
    # Implement the details of the query here.
    # Set @pass to true/false according to the query result.
    raise NotImplementedError.new("Implement the details of the query here")
  end
end
