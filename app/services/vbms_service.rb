require 'vbms'
require 'httpclient'
require 'httpi'
require 'nokogiri'
require 'xmlenc'
require 'mail'
require 'xmldsig'
require 'benchmark'

class VBMSService

  def initialize
    @last_result = {
      name: "VBMS",
      time: 0,
      latency: 0,
      service: "VBMS",
      api: "ListDocuments",
      pass: false
    }
    @client = VBMS::Client.from_env_vars(
      env_name: ENV["CONNECT_VBMS_ENV"]
    )
    save
  end

  def query
    @last_result[:pass] = false

    latency = Benchmark.realtime do
      request = VBMS::Requests::ListDocuments.new(320102183)
      doc = @client.send_request(request)
      if doc.length > 0
        @last_result[:pass] = true
      end
    end

    @last_result[:time] = Time.now
    @last_result[:latency] = latency

    save

  end

  def save
    Rails.cache.write("vbms", @last_result)
  end

end
