require 'vbms'
require 'httpclient'
require 'httpi'
require 'nokogiri'
require 'xmlenc'
require 'mail'
require 'xmldsig'
require 'benchmark'

class VBMSService < MonitorService

  def initialize
    super
    @connection = nil

    @name = "VBMS"
    @service = "VBMS"
    @api = "ListDocuments"

    @client = VBMS::Client.from_env_vars(
      env_name: ENV["CONNECT_VBMS_ENV"]
    )
    save
  end

  def self.prevalidate
    return ENV["CONNECT_VBMS_URL"].present?
  end

  def query_service

    request = VBMS::Requests::ListDocuments.new(Rails.application.secrets.target_file_num)
    doc = @client.send_request(request)
    if doc.length > 0
      @pass = true
    end
  end

end