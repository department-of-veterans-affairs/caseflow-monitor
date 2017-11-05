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
      Rails.logger.warn(e.message)
      Rails.logger.warn(e.backtrace)
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
    prometheus.register(
      Prometheus::Client::Gauge.new(:vacols_performance, 'Samples of VACOLS performance metrics')
    )
  end

  # Setup all target monitoring services. The target services will be
  # determined by the RAILS_ENV.
  # All new services should be registered here.
  def setup_services
    monitor_services = []
    if Rails.env.development?
      Rails.logger.info("loading up fake services\n\n\n\n")
      services = [
        Fakes::BGSAddressService,
        Fakes::BGSBenefitsService,
        Fakes::BGSClaimantService,
        Fakes::BGSOrganizationPoaService,
        Fakes::BGSPersonFilenumberService,
        Fakes::BGSVeteranService,
        Fakes::VacolsService,
        Fakes::VBMSService,
        Fakes::VBMSServiceFindDocumentReferenceSeries,
        Fakes::VVAService,
        Fakes::LaggyService,
        Fakes::UnreliableService,
        Fakes::AlwaysDownService,
        Fakes::HungService
      ]
    else
      Rails.logger.info("loading up production services\n\n\n\n")
      services = [
        BGSAddressService,
        BGSBenefitsService,
        BGSClaimantService,
        BGSOrganizationPoaService,
        BGSPersonFilenumberService,
        BGSVeteranService,
        VacolsService,
        VBMSService,
        VBMSServiceFindDocumentReferenceSeries,
        VVAService
      ]
    end
    services.each do |service|
      monitor_services.push(service) if service.prevalidate
    end
    monitor_services
  end

  def run_query(serviceClass)
    th = Thread.new do
      service = serviceClass.new
      while 1 do
        begin
          Rails.logger.info("#{service.name} query started")
          @worker[serviceClass.service_name.to_sym] = {
            :thread => th,
            :service => service,
            :serviceClass => serviceClass
          }
          passed = service.query

          if passed == false
            service.failed
          end
          Rails.logger.info("#{service.name} query done")
        rescue Exception => e
          service.failed
          Rails.logger.warn("#{service.name} query failed\n\n\n\n")
          Rails.logger.warn(e.message)
          Rails.logger.warn(e.backtrace)
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
              Rails.logger.warn("Zombie detected, killing thread and restarting #{worker_data[:thread]}")
              worker_data[:service].failed
              worker_data[:thread].kill
              worker_data[:thread].join 1
              run_query(worker_data[:serviceClass])
            end
          rescue Exception => e
            Rails.logger.warn(e.message)
            Rails.logger.warn(e.backtrace)
          end
        end
      end
    end
  end
end
