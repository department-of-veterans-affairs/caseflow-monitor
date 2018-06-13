class SampleController < ApplicationController

  def index
    respond_to do |format|
      format.json { render(json: fetch_uptime_data.as_json ) }
    end
  end

  def availability_report
      availability_results = fetch_uptime_data.values.each_with_object([]) do |service, uptime_report|
        if service[:up_rate_5].to_i < 50
          uptime_report << { service[:name] => :false }
        else
          uptime_report << { service[:name] => :true }
        end
      end
    respond_to do |format|
      format.json { render(json: availability_results.as_json ) }
    end
  end

  def fetch_uptime_data
    results = {}

    Rails.application.config.monitor_services.each do |service|
      datapoint = Rails.cache.read(service.service_name)

      if datapoint != nil
        results[service.service_name.to_sym] = datapoint
      end
    end
    results
  end
end
