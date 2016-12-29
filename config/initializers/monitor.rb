# One thread for background poll
Thread.new do
  while 1 do
    bgs_service = BGSService.new
    bgs_service.query
    sleep 60
  end
end

#
# Thread.new do
#   while 1 do
#     sleep 1
#     puts 'testing timer 2'
#   end
# end
#
# Thread.new do
#   while 1 do
#     sleep 1
#     puts 'testing timer 3'
#   end
# end
