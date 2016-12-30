# One thread for background poll

Thread.new do
  service = BGSService.new
  while 1 do
    begin
      service.query
    rescue Exception => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
    end
    sleep 300
  end
end

Thread.new do
  service = VacolsService.new
  while 1 do
    begin
      service.query
    rescue Exception => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
    end
    sleep 300
  end
end

Thread.new do
  service = VBMSService.new
  while 1 do
    begin
      service.query
    rescue Exception => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
    end
    sleep 300
  end
end
