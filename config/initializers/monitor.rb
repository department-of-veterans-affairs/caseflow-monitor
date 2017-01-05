# One thread for background poll

# Register the servicein this array to enable periodic query.
monitor_services = []
#
# if BGSService.prevalidate
#   monitor_services.push(BGSService.new)
# end
#
# if VacolsService.prevalidate
#   monitor_services.push(VacolsService.new)
# end

if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
end
if VBMSService.prevalidate
  monitor_services.push(VBMSService.new)
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
      sleep 1
    end
  end
end

Thread.new do
  while 1 do
    begin
      # puts "object size is #{ObjectSpace.memsize_of(doc)}"
      pp GC.stat
      GC.start(full_mark: true, immediate_sweep: true)
    rescue Exception => e
      puts e
    end
    sleep 1
  end
end

Rails.application.config.monitor_services = monitor_services
