# This job sets up all monitoring threads for all target services. It runs on 
# Rails startup, and all monitoring threads will persist through the lifetime 
# of the application.

class MonitorJob < ActiveJob::Base
  queue_as :default

  def initialize
    super
    @worker = {}
  end

  def perform()

    begin
      setup_prometheus_metrics
      
      # setup all the services that need to be monitored
      monitor_services = setup_services


      # Register all services into a global array. This array is expected to be
      # read only, and is thread-safe for updates.
      Rails.application.config.monitor_services = monitor_services

      # Spin up threads to monitor all the services
      monitor_services.each do |serviceClass|
        run_query(serviceClass)
      end

      setup_zombie_monitor

    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

  end

  def max_attempts
    1
  end

  def setup_prometheus_metrics
    prometheus = Prometheus::Client.registry
    prometheus.register(
      Prometheus::Client::Counter.new(:successful_query_total, 'Total number of successful queries')
    )
    prometheus.register(
      Prometheus::Client::Counter.new(:failed_query_total, 'Total number of failed queries')
    )
    prometheus.register(
      Prometheus::Client::Gauge.new(:latency_gauge, 'Samples of query latency')
    )
    prometheus.register(
      Prometheus::Client::Summary.new(:latency_summary, 'Summary of query latency')
    )
  end

  # Setup all target monitoring services. The target services will be 
  # determined by the RAILS_ENV.
  # All new services should be registered here.
  def setup_services
    monitor_services = []
    if Rails.env.development?
      puts "loading up fake services\n\n\n\n"
      if Fakes::BGSService.prevalidate
        monitor_services.push(Fakes::BGSService)
      end
      if Fakes::VacolsService.prevalidate
        monitor_services.push(Fakes::VacolsService)
      end
      if Fakes::VBMSService.prevalidate
        monitor_services.push(Fakes::VBMSService)
      end
      if Fakes::VBMSServiceFindDocumentReferenceSeries.prevalidate
        monitor_services.push(Fakes::VBMSServiceFindDocumentReferenceSeries)
      end
      if Fakes::LaggyService.prevalidate
        monitor_services.push(Fakes::LaggyService)
      end
      if Fakes::UnreliableService.prevalidate
        monitor_services.push(Fakes::UnreliableService)
      end
      if Fakes::AlwaysDownService.prevalidate
        monitor_services.push(Fakes::AlwaysDownService)
      end
      if Fakes::HungService.prevalidate
        monitor_services.push(Fakes::HungService)
      end

    else
      puts "loading up production services\n\n\n\n"
      if BGSService.prevalidate
        monitor_services.push(BGSService)
      end

      if VacolsService.prevalidate
        monitor_services.push(VacolsService)
      end

      if VBMSService.prevalidate
        monitor_services.push(VBMSService)
      end

      if VBMSServiceFindDocumentReferenceSeries.prevalidate
        monitor_services.push(VBMSServiceFindDocumentReferenceSeries)
      end
    end
    monitor_services
  end

  def run_query(serviceClass)
    th = Thread.new do
      service = serviceClass.new
      while 1 do
        begin
          puts "#{service.name} query started"
          @worker[serviceClass.service_name.to_sym] = {
            :thread => th,
            :service => service,
            :serviceClass => serviceClass
          }
          passed = service.query

          if passed == false
            service.failed
          end
          puts "#{service.name} query done"
        rescue Exception => e
          service.failed
          puts "run_query failed\n\n\n\n"
          puts e.message
          puts e.backtrace
        end
        sleep 30
      end
    end
  end

  # Sets up a monitor thread that monitors all zombies threads. In the normal
  # world, this is not needed. However, Monitor is designed to be more
  # robust than the application it is monitoring. Therefore, any thread hung
  # will be protected.
  def setup_zombie_monitor
    Thread.new do
      loop do
        sleep 60
        @worker.each do |service_name, worker_data|
          begin
            duration = Time.now - worker_data[:service].time
            if duration > 120
              puts "Zombie detected, killing thread and restarting #{worker_data[:thread]}"
              worker_data[:service].failed
              worker_data[:thread].kill
              worker_data[:thread].join 1
              run_query(worker_data[:serviceClass])
            end
          rescue Exception => e            
            puts e.message
            puts e.backtrace
          end
        end
      end
    end
  end
end
