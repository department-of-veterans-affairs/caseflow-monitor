require 'vbms'
require 'httpclient'
require 'httpi'
require 'nokogiri'
require 'xmlenc'
require 'mail'
require 'xmldsig'

# NOT READY YET

client = VBMS::Client.from_env_vars(
  env_name: ENV["CONNECT_VBMS_ENV"]
)

request = VBMS::Requests::ListDocuments.new(587498157)
res = client.send_request(request)

#puts res
