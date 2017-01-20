class MonitorJob < ActiveJob::Base
  queue_as :default

  class ForceShutdown < RuntimeError
  end

  def perform()
    puts 'running job'
    # One thread for background poll

    # Register the servicein this array to enable periodic query.
    monitor_services = []
    worker = {}

    # Register all services into a global array. This array is expected to be
    # read only, and is thread-safe for updates.
    Rails.application.config.monitor_services = monitor_services

    if Rails.env.development?
      if Fakes::BGSService.prevalidate
        monitor_services.push(Fakes::BGSService)
      end

    else
      if BGSService.prevalidate
        monitor_services.push(BGSService)
      end

      if VacolsService.prevalidate
        monitor_services.push(VacolsService)
      end

      if VBMSService.prevalidate
        monitor_services.push(VBMSService)
      end
    end

    monitor_services.each do |serviceClass|
      run_query(serviceClass, worker)
    end

    Thread.new do
      while 1 do
        puts "checking"
        worker.each do |service_name, worker_data|
          duration = Time.now - worker_data[:service].time
          puts "duration is #{duration}"
          if duration > 3
            puts "Zombie detected, killing thread and restarting #{worker_data[:thread]}"
            worker_data[:thread].kill
            puts "zombie killed"
            worker_data[:thread].join 1
            puts "zombie joined, rerunning query"
            run_query(worker_data[:serviceClass], worker)
            puts "query started"
          end
        end
        sleep 1
      end
    end
  end

  def max_attempts
    1
  end

  rescue_from(StandardError) do |e|
    puts e.message
    puts exception.backtrace
  end

  def run_query(serviceClass, worker)
    th = Thread.new do
      while 1 do
        begin
          service = serviceClass.new
          worker[serviceClass.service_name.to_sym] = {
            :thread => th,
            :service => service,
            :serviceClass => serviceClass
          }
          service.query
        rescue Exception => e
          puts e.message
          puts exception.backtrace
        end
        sleep 1
      end
    end
  end
end
