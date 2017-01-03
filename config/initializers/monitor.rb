# One thread for background poll

# Register the servicein this array to enable periodic query.
monitor_services = []

if BGSService.prevalidate
  monitor_services.insert(BGSService.new)
end

if VacolsService.prevalidate
  monitor_services.insert(VacolsService.new)
end

if VBMSService.prevalidate
  monitor_services.insert(VBMSService.new)
end

monitor_services.each do |service|
  Thread.new do
    while 1 do
      begin
        service.query
      rescue Exception => e
        puts e.message
        puts exception.backtrace
      end
      sleep service.polling_rate_sec
    end
  end
end

Rails.application.config.monitor_services = monitor_services
