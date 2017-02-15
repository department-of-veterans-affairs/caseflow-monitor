class SampleController < ApplicationController
  def index

    results = {}

    Rails.application.config.monitor_services.each do |service|
      datapoint = Rails.cache.read(service.service_name)

      if datapoint != nil
        results[service.service_name.to_sym] = datapoint
      end
    end
    respond_to do |format|
      format.json { render(json: results.as_json ) }
    end
  end
end
