require "benchmark"

class VacolsService
  attr_accessor :last_result

  def initialize
    @connection = nil
    @last_result = {
      name: "VACOLS",
      time: 0,
      latency: 0,
      service: "VACOLS",
      api: "VACOLS.BRIEFF",
      pass: false
    }
    save
  end

  def query
    puts "querying"
    @last_result[:pass] = false

    latency = Benchmark.realtime do
      if @connection == nil
        puts "connecting to VACOLS"
        ActiveRecord::Base.establish_connection(:production_vacols)
        @connection = ActiveRecord::Base.connection
      end
      array = @connection.exec_query('SELECT * FROM VACOLS.BRIEFF WHERE BFKEY=TO_CHAR(1302899)')
      @last_result[:pass] = true
    end

    @last_result[:time] = Time.now
    @last_result[:latency] = latency

    save
  end

  def save
    Rails.cache.write("vacols", @last_result)
  end
end
